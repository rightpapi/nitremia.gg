-- Nitremia UI · Hub (System Info + Mobile)
-- Creator: rightpapi
-- Wait for game to fully initialize before running
repeat task.wait() until game:IsLoaded() and Color3


local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local LocalPlayer      = Players.LocalPlayer

-- CoreGui fallback for executors that block CoreGui access (e.g. Delta mobile)
local _CoreGui = game:GetService("CoreGui")
local _guiParent
if pcall(function() Instance.new("Frame", _CoreGui):Destroy() end) then
    _guiParent = _CoreGui
else
    _guiParent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ============================================================
-- MOBILE DETECTION
-- ============================================================
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================================
-- TOKENS
-- ============================================================
local T = {
    bg           = Color3.fromRGB(6,   6,   6),
    surface      = Color3.fromRGB(14,  14,  14),
    surfaceRaise = Color3.fromRGB(22,  22,  22),
    surfaceHover = Color3.fromRGB(30,  30,  30),
    border       = Color3.fromRGB(255, 255, 255),
    borderDim    = Color3.fromRGB(55,  55,  55),
    borderGhost  = Color3.fromRGB(30,  30,  30),
    text         = Color3.fromRGB(255, 255, 255),
    textMuted    = Color3.fromRGB(100, 100, 100),
    textDim      = Color3.fromRGB(50,  50,  50),
    success      = Color3.fromRGB(68,  255, 136),
    warn         = Color3.fromRGB(255, 204, 0),
    danger       = Color3.fromRGB(255, 68,  68),
}

local MONO = Enum.Font.Code
local UI   = Enum.Font.Gotham
local BOLD = Enum.Font.GothamBold

local function getViewport()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1024, 768)
end

local function getUIScale()
    if not IS_MOBILE then return 1.0 end
    local v = getViewport()
    -- Keep the UI compact enough for iPad portrait and landscape.
    -- 768x1024 -> ~0.92, 1024x768 -> 1.00
    return math.clamp(math.min(v.X / 830, v.Y / 760), 0.88, 1.0)
end

local SCALE = getUIScale()
local function sc(n) return math.max(1, math.floor(n * SCALE)) end

-- ============================================================
-- HELPERS
-- ============================================================
local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p; return c
end

local function stroke(p, col, thick)
    local s = Instance.new("UIStroke")
    s.Color = col or T.border; s.Thickness = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p; return s
end

local function pad(p, t, r, b, l)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, t or 8)
    u.PaddingRight  = UDim.new(0, r or 12)
    u.PaddingBottom = UDim.new(0, b or 8)
    u.PaddingLeft   = UDim.new(0, l or 12)
    u.Parent = p; return u
end

local function vlist(p, spacing)
    local l = Instance.new("UIListLayout")
    l.FillDirection = Enum.FillDirection.Vertical
    l.SortOrder     = Enum.SortOrder.LayoutOrder
    l.Padding       = UDim.new(0, spacing or 0)
    l.Parent = p; return l
end

local function hlist(p, spacing)
    local l = Instance.new("UIListLayout")
    l.FillDirection = Enum.FillDirection.Horizontal
    l.SortOrder     = Enum.SortOrder.LayoutOrder
    l.Padding       = UDim.new(0, spacing or 0)
    l.Parent = p; return l
end

local function fr(p, size, pos, bg, trans)
    local f = Instance.new("Frame")
    f.Size                   = size
    f.Position               = pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3       = bg or T.surface
    f.BackgroundTransparency = trans or 0
    f.BorderSizePixel        = 0
    f.Parent                 = p; return f
end

local function tw(obj, props, t)
    if not obj or not obj.Parent then return end
    TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), props):Play()
end

local function divLine(p, order)
    local f = fr(p, UDim2.new(1,0,0,1), nil, T.borderGhost)
    f.LayoutOrder = order or 99; return f
end

local function secLabel(p, txt, order)
    local l = Instance.new("TextLabel")
    l.Text = string.upper(txt); l.TextSize = sc(9); l.Font = MONO
    l.TextColor3 = T.textDim; l.BackgroundTransparency = 1
    l.Size = UDim2.new(1,0,0,sc(14))
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = order or 0; l.Parent = p; return l
end

local function mkScroll(p, size, pos)
    local s = Instance.new("ScrollingFrame")
    s.Size = size; s.Position = pos or UDim2.new(0,0,0,0)
    s.BackgroundTransparency = 1; s.BorderSizePixel = 0
    s.ScrollBarThickness = IS_MOBILE and 3 or 2
    s.ScrollBarImageColor3 = T.borderDim
    s.CanvasSize = UDim2.new(0,0,0,0)
    s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    s.ScrollingDirection = Enum.ScrollingDirection.Y
    s.Parent = p; return s
end

-- ============================================================
-- DRAG — mouse + touch
-- ============================================================
local function makeDraggable(win, handle)
    local drag, ds, sp = false, nil, nil
    local function onStart(pos) drag=true; ds=pos; sp=win.Position end
    local function onMove(pos)
        if not drag then return end
        local d=pos-ds
        win.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
    end
    local function onEnd() drag=false end
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then onStart(i.Position) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch then onMove(i.Position) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then onEnd() end
    end)
end

-- ============================================================
-- TOAST
-- ============================================================
local _toast
local function initToast(gui)
    local stack=fr(gui,UDim2.new(0,sc(260),1,-40),UDim2.new(1,-sc(272),0,0),nil,1)
    local layout=vlist(stack,6)
    layout.VerticalAlignment=Enum.VerticalAlignment.Bottom
    pad(stack,0,0,sc(20),0)
    local icons={default="◈",success="◉",warn="◎",danger="◌"}
    local cols={default=T.border,success=T.success,warn=T.warn,danger=T.danger}
    _toast=function(msg,kind)
        kind=kind or "default"
        local t=fr(stack,UDim2.new(1,0,0,sc(36)),nil,T.surface)
        corner(t,4); stroke(t,cols[kind] or T.border,1); t.BackgroundTransparency=1
        local row=fr(t,UDim2.new(1,0,1,0),nil,nil,1)
        hlist(row,sc(8)); pad(row,0,sc(12),0,sc(12))
        local ic=Instance.new("TextLabel")
        ic.Text=icons[kind] or "◈"; ic.TextSize=sc(12); ic.Font=MONO
        ic.TextColor3=cols[kind] or T.border; ic.BackgroundTransparency=1
        ic.Size=UDim2.new(0,sc(12),1,0); ic.TextYAlignment=Enum.TextYAlignment.Center; ic.Parent=row
        local ml=Instance.new("TextLabel")
        ml.Text=msg; ml.TextSize=sc(11); ml.Font=MONO
        ml.TextColor3=cols[kind] or T.border; ml.BackgroundTransparency=1
        ml.Size=UDim2.new(1,-sc(20),1,0)
        ml.TextXAlignment=Enum.TextXAlignment.Left; ml.TextYAlignment=Enum.TextYAlignment.Center; ml.Parent=row
        tw(t,{BackgroundTransparency=0},0.2)
        task.delay(3.2,function()
            tw(t,{BackgroundTransparency=1},0.2)
            task.delay(0.25,function() t:Destroy() end)
        end)
    end
end

-- ============================================================
-- TOGGLE
-- ============================================================
local function mkToggle(p, name, sub, default, order, cb)
    local rowH=sub and sc(42) or sc(30)
    local row=fr(p,UDim2.new(1,0,0,rowH),nil,nil,1); row.LayoutOrder=order or 0
    local texts=fr(row,UDim2.new(1,-sc(52),1,0),nil,nil,1)
    vlist(texts,2); pad(texts,sub and sc(6) or sc(8),0,sub and sc(6) or sc(8),0)
    local ml=Instance.new("TextLabel")
    ml.Text=name; ml.TextSize=sc(12); ml.Font=UI; ml.TextColor3=T.text
    ml.BackgroundTransparency=1; ml.Size=UDim2.new(1,0,0,sc(15))
    ml.TextXAlignment=Enum.TextXAlignment.Left; ml.Parent=texts
    if sub then
        local sl=Instance.new("TextLabel")
        sl.Text=sub; sl.TextSize=sc(10); sl.Font=UI; sl.TextColor3=T.textMuted
        sl.BackgroundTransparency=1; sl.Size=UDim2.new(1,0,0,sc(13))
        sl.TextXAlignment=Enum.TextXAlignment.Left; sl.Parent=texts
    end
    local track=fr(row,UDim2.new(0,sc(38),0,sc(20)),UDim2.new(1,-sc(38),0.5,-sc(10)),T.bg)
    corner(track,sc(10))
    local ts=stroke(track,default and T.border or T.borderDim,1)
    local thumb=fr(track,UDim2.new(0,sc(12),0,sc(12)),
        default and UDim2.new(1,-sc(15),0.5,-sc(6)) or UDim2.new(0,sc(3),0.5,-sc(6)),
        default and T.text or T.textMuted)
    corner(thumb,sc(6))
    local state=default or false
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.Parent=row
    btn.MouseButton1Click:Connect(function()
        state=not state
        tw(thumb,{Position=state and UDim2.new(1,-sc(15),0.5,-sc(6)) or UDim2.new(0,sc(3),0.5,-sc(6)),
            BackgroundColor3=state and T.text or T.textMuted},0.15)
        tw(ts,{Color=state and T.border or T.borderDim},0.15)
        if cb then cb(state) end
    end)
    return row
end

-- ============================================================
-- SLIDER
-- ============================================================
local function mkSlider(p, name, min, max, default, order, cb)
    local c=fr(p,UDim2.new(1,0,0,sc(44)),nil,nil,1); c.LayoutOrder=order or 0
    local hdr=fr(c,UDim2.new(1,0,0,sc(16)),nil,nil,1)
    local nl=Instance.new("TextLabel")
    nl.Text=name; nl.TextSize=sc(12); nl.Font=UI; nl.TextColor3=T.text
    nl.BackgroundTransparency=1; nl.Size=UDim2.new(0.7,0,1,0)
    nl.TextXAlignment=Enum.TextXAlignment.Left; nl.Parent=hdr
    local vl=Instance.new("TextLabel")
    vl.Text=tostring(default); vl.TextSize=sc(10); vl.Font=MONO; vl.TextColor3=T.textMuted
    vl.BackgroundTransparency=1; vl.Size=UDim2.new(0.3,0,1,0)
    vl.Position=UDim2.new(0.7,0,0,0); vl.TextXAlignment=Enum.TextXAlignment.Right; vl.Parent=hdr
    local track=fr(c,UDim2.new(1,0,0,2),UDim2.new(0,0,0,sc(28)),T.borderGhost); corner(track,1)
    local p0=(default-min)/(max-min)
    local fill=fr(track,UDim2.new(p0,0,1,0),nil,T.text); corner(fill,1)
    local th=fr(track,UDim2.new(0,sc(14),0,sc(14)),UDim2.new(p0,0,0.5,0),T.text)
    th.AnchorPoint=Vector2.new(0.5,0.5); th.ZIndex=3; corner(th,sc(7)); stroke(th,T.bg,2)
    local dragging=false
    local hit=Instance.new("TextButton")
    hit.Size=UDim2.new(1,0,0,IS_MOBILE and sc(32) or sc(20))
    hit.Position=UDim2.new(0,0,0,sc(16))
    hit.BackgroundTransparency=1; hit.Text=""; hit.ZIndex=5; hit.Parent=c
    local function upd(x)
        local sz=track.AbsoluteSize.X; if sz==0 then return end
        local pct=math.clamp((x-track.AbsolutePosition.X)/sz,0,1)
        local v=math.floor(min+pct*(max-min))
        vl.Text=tostring(v)
        tw(fill,{Size=UDim2.new(pct,0,1,0)},0.05)
        tw(th,{Position=UDim2.new(pct,0,0.5,0)},0.05)
        if cb then cb(v) end
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then dragging=true; upd(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch) then upd(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    return c
end

-- ============================================================
-- KEYBIND ROW
-- ============================================================
local function mkKeybind(p, name, keys, order)
    local row=fr(p,UDim2.new(1,0,0,sc(26)),nil,nil,1); row.LayoutOrder=order or 0
    local nl=Instance.new("TextLabel")
    nl.Text=name; nl.TextSize=sc(12); nl.Font=UI; nl.TextColor3=T.text
    nl.BackgroundTransparency=1; nl.Size=UDim2.new(0.5,0,1,0)
    nl.TextXAlignment=Enum.TextXAlignment.Left; nl.TextYAlignment=Enum.TextYAlignment.Center; nl.Parent=row
    local kr=fr(row,UDim2.new(0.5,0,1,0),UDim2.new(0.5,0,0,0),nil,1)
    local kl=hlist(kr,3)
    kl.HorizontalAlignment=Enum.HorizontalAlignment.Right
    kl.VerticalAlignment=Enum.VerticalAlignment.Center
    for i,k in ipairs(keys) do
        local pill=fr(kr,UDim2.new(0,0,0,sc(20)),nil,T.surfaceRaise)
        pill.AutomaticSize=Enum.AutomaticSize.X; pill.LayoutOrder=i*2-1
        corner(pill,3); stroke(pill,T.borderDim,1)
        local kt=Instance.new("TextLabel")
        kt.Text=k; kt.TextSize=sc(9); kt.Font=MONO; kt.TextColor3=T.textMuted
        kt.BackgroundTransparency=1; kt.Size=UDim2.new(0,0,1,0)
        kt.AutomaticSize=Enum.AutomaticSize.X; kt.TextXAlignment=Enum.TextXAlignment.Center
        kt.Parent=pill; pad(kt,0,6,0,6)
        if i<#keys then
            local sep=Instance.new("TextLabel")
            sep.Text="+"; sep.TextSize=sc(9); sep.Font=MONO; sep.TextColor3=T.textDim
            sep.BackgroundTransparency=1; sep.Size=UDim2.new(0,sc(8),0,sc(20))
            sep.LayoutOrder=i*2; sep.TextXAlignment=Enum.TextXAlignment.Center
            sep.TextYAlignment=Enum.TextYAlignment.Center; sep.Parent=kr
        end
    end
    return row
end

-- ============================================================
-- FIX 1: SYSTEM DETECTION — Delta + broader fallback chain
-- ============================================================
local function detectExecutor()
    if syn                                        then return "Synapse X"   end
    if KRNL_LOADED                                then return "KRNL"        end
    if rconsole_clear                             then return "Script-Ware" end
    if fluxus                                     then return "Fluxus"      end
    -- Delta exposes identifyexecutor() or a DELTA global
    if typeof(identifyexecutor)=="function" then
        local ok,name=pcall(identifyexecutor)
        if ok and name then return tostring(name) end
    end
    if typeof(getexecutorname)=="function" then
        local ok,name=pcall(getexecutorname)
        if ok and name then return tostring(name) end
    end
    if DELTA_KEY                                  then return "Delta"       end
    if getgenv and getgenv().madium               then return "Madium"      end
    if getgenv then
        local ok,name=pcall(function()
            return getgenv().__EXECUTOR__ or getgenv().EXECUTOR_NAME
        end)
        if ok and name then return tostring(name) end
    end
    return "Unknown"
end

local function detectHWID()
    local ok,id=pcall(function()
        if typeof(get_hwid)=="function"  then return get_hwid()       end
        if typeof(gethwid)=="function"   then return gethwid()        end
        if getgenv and getgenv().HWID    then return getgenv().HWID   end
    end)
    if ok and id then
        local s=tostring(id)
        return #s>14 and s:sub(1,8).."···"..s:sub(-4) or s
    end
    return "Unavailable"
end

local function detectPremium()
    local ok,result=pcall(function()
        if getgenv and getgenv().LITHIUM_PREMIUM then return true end
        return false
    end)
    return (ok and result) and true or false
end

local function getPlatform()
    if IS_MOBILE                         then return "Mobile"  end
    if UserInputService.GamepadEnabled   then return "Console" end
    return "Desktop"
end

local SYS={
    executor = detectExecutor(),
    hwid     = detectHWID(),
    premium  = detectPremium(),
    platform = getPlatform(),
}

-- ============================================================
-- PLAYER ROW (nearby)
-- ============================================================
local function mkPlayerRow(p, username, dist, order)
    local row=fr(p,UDim2.new(1,0,0,sc(28)),nil,nil,1); row.LayoutOrder=order or 0
    local hover=fr(row,UDim2.new(1,0,1,0),nil,T.surfaceHover,1); corner(hover,4)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.Parent=row
    btn.MouseEnter:Connect(function() tw(hover,{BackgroundTransparency=0},0.1) end)
    btn.MouseLeave:Connect(function() tw(hover,{BackgroundTransparency=1},0.1) end)
    local nl=Instance.new("TextLabel")
    nl.Text=username; nl.TextSize=sc(12); nl.Font=UI; nl.TextColor3=T.text
    nl.BackgroundTransparency=1; nl.Size=UDim2.new(0.65,0,1,0); nl.Position=UDim2.new(0,sc(8),0,0)
    nl.TextXAlignment=Enum.TextXAlignment.Left; nl.TextYAlignment=Enum.TextYAlignment.Center
    nl.ZIndex=2; nl.Parent=row
    local dl=Instance.new("TextLabel")
    dl.Text=dist; dl.TextSize=sc(11); dl.Font=MONO; dl.TextColor3=T.textMuted
    dl.BackgroundTransparency=1; dl.Size=UDim2.new(0.35,-sc(8),1,0); dl.Position=UDim2.new(0.65,0,0,0)
    dl.TextXAlignment=Enum.TextXAlignment.Right; dl.TextYAlignment=Enum.TextYAlignment.Center
    dl.ZIndex=2; dl.Parent=row
    return row
end

-- ============================================================
-- ROOT GUI
-- ============================================================
local WIN_W = 860
local WIN_H = 520
local NAV_H = sc(IS_MOBILE and 42 or 44)

local gui=Instance.new("ScreenGui")
gui.Name="Nitremia_Hub"; gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.DisplayOrder=999; gui.IgnoreGuiInset=true
gui.Parent=_guiParent

initToast(gui)

local win
if IS_MOBILE then
    local vp = getViewport()
    -- iPad-friendly: leave a small margin around the menu and never
    -- exceed the available viewport in either orientation.
    local mobileW = math.min(vp.X - 24, 860)
    local mobileH = math.min(vp.Y - 32, 620)
    win=fr(
        gui,
        UDim2.new(0, mobileW, 0, mobileH),
        UDim2.new(0.5, -mobileW/2, 0.5, -mobileH/2),
        T.bg
    )
    corner(win,8); stroke(win,T.borderDim,1)
else
    win=fr(gui,UDim2.new(0,WIN_W,0,WIN_H),UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),T.bg)
    corner(win,8); stroke(win,T.borderDim,1)
end
win.ClipsDescendants=true

-- ============================================================
-- FIX 2: LINORA-STYLE FLOATING TOGGLE PILL
-- Sits outside `win` so it persists when win is hidden.
-- Draggable on both mobile and desktop.
-- ============================================================
local PILL_W = sc(IS_MOBILE and 70 or 62)
local PILL_H = sc(28)

local pill=fr(gui,UDim2.new(0,PILL_W,0,PILL_H),
    IS_MOBILE
        and UDim2.new(1,-PILL_W-12, 1,-PILL_H-60)  -- bottom-right on mobile
        or  UDim2.new(0,12, 0.5,-PILL_H/2),          -- left-center on desktop
    T.surface)
pill.ZIndex=200; corner(pill,PILL_H/2); stroke(pill,T.borderDim,1)

-- Inner layout: dot + label
local pillRow=fr(pill,UDim2.new(1,0,1,0),nil,nil,1)
hlist(pillRow,sc(5))
local pillLayout=pillRow:FindFirstChildOfClass("UIListLayout")
pillLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
pillLayout.VerticalAlignment=Enum.VerticalAlignment.Center

local pillDot=fr(pillRow,UDim2.new(0,sc(6),0,sc(6)),nil,T.success)
pillDot.LayoutOrder=1; corner(pillDot,sc(3))
pillDot.AnchorPoint=Vector2.new(0,0.5)

local pillLbl=Instance.new("TextLabel")
pillLbl.Text="Ni"; pillLbl.TextSize=sc(11); pillLbl.Font=MONO
pillLbl.TextColor3=T.text; pillLbl.BackgroundTransparency=1
pillLbl.Size=UDim2.new(0,sc(20),1,0)
pillLbl.TextXAlignment=Enum.TextXAlignment.Center
pillLbl.TextYAlignment=Enum.TextYAlignment.Center
pillLbl.LayoutOrder=2; pillLbl.Parent=pillRow

-- Pill is draggable
local pillDrag,pillDs,pillSp=false,nil,nil
pill.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1
    or i.UserInputType==Enum.UserInputType.Touch then
        pillDrag=true; pillDs=i.Position; pillSp=pill.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not pillDrag then return end
    if i.UserInputType==Enum.UserInputType.MouseMovement
    or i.UserInputType==Enum.UserInputType.Touch then
        local d=i.Position-pillDs
        pill.Position=UDim2.new(pillSp.X.Scale,pillSp.X.Offset+d.X,pillSp.Y.Scale,pillSp.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1
    or i.UserInputType==Enum.UserInputType.Touch then
        pillDrag=false
    end
end)

-- Toggle logic
local uiOpen=true
local pillBtn=Instance.new("TextButton")
pillBtn.Size=UDim2.new(1,0,1,0); pillBtn.BackgroundTransparency=1; pillBtn.Text=""
pillBtn.ZIndex=201; pillBtn.Parent=pill

pillBtn.MouseButton1Click:Connect(function()
    -- Ignore click if we were dragging
    if pillDrag then return end
    uiOpen=not uiOpen
    if uiOpen then
        win.Visible=true
        tw(win,{BackgroundTransparency=0},0.18)
        tw(pillDot,{BackgroundColor3=T.success},0.15)
        pillLbl.Text="Ni"
    else
        tw(win,{BackgroundTransparency=1},0.18)
        task.delay(0.2,function() if not uiOpen then win.Visible=false end end)
        tw(pillDot,{BackgroundColor3=T.textDim},0.15)
        pillLbl.Text="Ni"
    end
end)

-- INSERT key toggle on desktop
if not IS_MOBILE then
    UserInputService.InputBegan:Connect(function(i, processed)
        if processed then return end
        if i.KeyCode==Enum.KeyCode.Insert then
            pillBtn.MouseButton1Click:Fire()
        end
    end)
end

-- ============================================================
-- NAV BAR
-- ============================================================
local nav=fr(win,UDim2.new(1,0,0,NAV_H),nil,T.surface); nav.ZIndex=10
fr(nav,UDim2.new(1,0,0,1),UDim2.new(0,0,1,-1),T.borderGhost)

local logoBox=fr(nav,UDim2.new(0,sc(22),0,sc(22)),UDim2.new(0,sc(14),0.5,-sc(11)),T.bg)
corner(logoBox,4); stroke(logoBox,T.border,1)
local lt=Instance.new("TextLabel")
lt.Text="Ni"; lt.TextSize=sc(9); lt.Font=MONO; lt.TextColor3=T.text
lt.BackgroundTransparency=1; lt.Size=UDim2.new(1,0,1,0)
lt.TextXAlignment=Enum.TextXAlignment.Center; lt.TextYAlignment=Enum.TextYAlignment.Center
lt.Parent=logoBox

local brandLbl=Instance.new("TextLabel")
brandLbl.Text="NITREMIA"; brandLbl.TextSize=sc(11); brandLbl.Font=MONO
brandLbl.TextColor3=T.text; brandLbl.BackgroundTransparency=1
brandLbl.Size=UDim2.new(0,sc(80),1,0); brandLbl.Position=UDim2.new(0,sc(42),0,0)
brandLbl.TextXAlignment=Enum.TextXAlignment.Left
brandLbl.TextYAlignment=Enum.TextYAlignment.Center; brandLbl.Parent=nav

if IS_MOBILE then
    local mob=fr(nav,UDim2.new(0,0,0,sc(18)),UDim2.new(0,sc(130),0.5,-sc(9)),T.surfaceRaise)
    mob.AutomaticSize=Enum.AutomaticSize.X; corner(mob,3); stroke(mob,T.borderGhost,1)
    local ml=Instance.new("TextLabel")
    ml.Text="MOBILE"; ml.TextSize=sc(8); ml.Font=MONO; ml.TextColor3=T.textMuted
    ml.BackgroundTransparency=1; ml.Size=UDim2.new(0,0,1,0); ml.AutomaticSize=Enum.AutomaticSize.X
    ml.TextXAlignment=Enum.TextXAlignment.Center; ml.TextYAlignment=Enum.TextYAlignment.Center
    ml.Parent=mob; pad(ml,0,8,0,8)
end

local navTabsX=IS_MOBILE and sc(118) or sc(140)
local navTabs
if IS_MOBILE then
    navTabs=Instance.new("ScrollingFrame")
    navTabs.Size=UDim2.new(1,-(navTabsX+sc(46)),1,0)
    navTabs.Position=UDim2.new(0,navTabsX,0,0)
    navTabs.BackgroundTransparency=1
    navTabs.BorderSizePixel=0
    navTabs.ScrollBarThickness=0
    navTabs.ScrollingDirection=Enum.ScrollingDirection.X
    navTabs.AutomaticCanvasSize=Enum.AutomaticSize.X
    navTabs.CanvasSize=UDim2.new(0,0,0,0)
    navTabs.Parent=nav
else
    navTabs=fr(nav,UDim2.new(1,-(navTabsX+sc(60)),1,0),UDim2.new(0,navTabsX,0,0),nil,1)
end
hlist(navTabs,2)

local closeBtn=Instance.new("TextButton")
closeBtn.Size=UDim2.new(0,sc(IS_MOBILE and 24 or 26),0,sc(IS_MOBILE and 24 or 26)); closeBtn.Position=UDim2.new(1,-sc(IS_MOBILE and 32 or 36),0.5,-sc(IS_MOBILE and 12 or 13))
closeBtn.BackgroundColor3=T.surface; closeBtn.BorderSizePixel=0
closeBtn.Text="✕"; closeBtn.TextSize=sc(11); closeBtn.TextColor3=T.textMuted
closeBtn.Font=MONO; closeBtn.ZIndex=20; closeBtn.Parent=nav
corner(closeBtn,4); stroke(closeBtn,T.borderDim,1)
closeBtn.MouseEnter:Connect(function() tw(closeBtn,{TextColor3=T.danger},0.1) end)
closeBtn.MouseLeave:Connect(function() tw(closeBtn,{TextColor3=T.textMuted},0.1) end)
closeBtn.MouseButton1Click:Connect(function()
    uiOpen=false; win.Visible=false
    tw(pillDot,{BackgroundColor3=T.textDim},0.15)
end)

makeDraggable(win,nav)

-- ============================================================
-- PAGE SYSTEM
-- ============================================================
local pages={}; local activePage=nil; local pageCount=0

local function showPage(id)
    for pid,pg in pairs(pages) do
        pg.frame.Visible=(pid==id)
        if pg.navBtn then
            local active=(pid==id)
            tw(pg.navBtn,{TextColor3=active and T.text or T.textMuted},0.12)
            if pg.pill then tw(pg.pill,{BackgroundTransparency=active and 0 or 1},0.12) end
        end
    end
    activePage=id
end

local function addPage(id,labelTxt)
    pageCount=pageCount+1
    local isFirst=(pageCount==1)
    local btnWrap=fr(navTabs,UDim2.new(0,0,1,-sc(10)),nil,nil,1)
    btnWrap.AutomaticSize=Enum.AutomaticSize.X; btnWrap.LayoutOrder=pageCount
    local navPill=fr(btnWrap,UDim2.new(1,0,1,0),nil,T.surfaceRaise,isFirst and 0 or 1)
    corner(navPill,5); stroke(navPill,isFirst and T.borderDim or T.borderGhost,1)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1
    btn.Text=labelTxt; btn.TextSize=sc(12); btn.Font=isFirst and BOLD or UI
    btn.TextColor3=isFirst and T.text or T.textMuted
    btn.AutomaticSize=Enum.AutomaticSize.X; btn.Parent=btnWrap
    pad(btn,0,sc(14),0,sc(14))
    local pg=fr(win,UDim2.new(1,0,1,-NAV_H),UDim2.new(0,0,0,NAV_H),nil,1)
    pg.Visible=isFirst; pg.ClipsDescendants=true
    pages[id]={frame=pg,navBtn=btn,pill=navPill}
    btn.MouseButton1Click:Connect(function()
        for pid2,pg2 in pairs(pages) do
            if pg2.navBtn then pg2.navBtn.Font=(pid2==id) and BOLD or UI end
        end
        showPage(id)
    end)
    btn.MouseEnter:Connect(function()
        if activePage~=id then tw(btn,{TextColor3=Color3.fromRGB(180,180,180)},0.1) end
    end)
    btn.MouseLeave:Connect(function()
        if activePage~=id then tw(btn,{TextColor3=T.textMuted},0.1) end
    end)
    if isFirst then activePage=id end
    return pg
end

-- ============================================================
-- FIX 3: HOME PAGE — mobile-safe layout
-- Stat cards: 2×2 grid on mobile, 1×4 on desktop
-- Bottom row: stacked vertically on mobile, side-by-side on desktop
-- ============================================================
local homePage=addPage("home","Home")

-- Use a scroll on mobile so nothing gets clipped off screen
local homeScroll=mkScroll(homePage,UDim2.new(1,0,1,0))
local homeInner=fr(homeScroll,UDim2.new(1,0,0,0),nil,nil,1)
homeInner.AutomaticSize=Enum.AutomaticSize.Y
vlist(homeInner,sc(IS_MOBILE and 10 or 14)); pad(homeInner,sc(IS_MOBILE and 14 or 22),sc(IS_MOBILE and 16 or 24),sc(IS_MOBILE and 14 or 22),sc(IS_MOBILE and 16 or 24))

-- Greeting
local greetWrap=fr(homeInner,UDim2.new(1,0,0,0),nil,nil,1)
greetWrap.AutomaticSize=Enum.AutomaticSize.Y; greetWrap.LayoutOrder=1; vlist(greetWrap,3)

local hour=tonumber(os.date("%H")) or 12
local greetWord=hour<12 and "Good morning" or hour<18 and "Good afternoon" or "Good evening"
local displayName=LocalPlayer.DisplayName or LocalPlayer.Name

local gl=Instance.new("TextLabel")
gl.Text=greetWord..", "..displayName; gl.TextSize=sc(22); gl.Font=BOLD
gl.TextColor3=T.text; gl.BackgroundTransparency=1
gl.Size=UDim2.new(1,0,0,sc(28)); gl.TextXAlignment=Enum.TextXAlignment.Left; gl.Parent=greetWrap

local sl=Instance.new("TextLabel")
sl.Text="Systems successfully saturated."; sl.TextSize=sc(11); sl.Font=UI
sl.TextColor3=T.textMuted; sl.BackgroundTransparency=1
sl.Size=UDim2.new(1,0,0,sc(16)); sl.TextXAlignment=Enum.TextXAlignment.Left; sl.Parent=greetWrap

-- Stat cards
-- Desktop: one row of 4. Mobile: two rows of 2.
local function mkStatCard(p, topLbl, valTxt, subTxt, order, valCol)
    local card=fr(p,UDim2.new(IS_MOBILE and 0.5 or 0.25,-sc(IS_MOBILE and 6 or 9),1,0),nil,T.surface)
    card.LayoutOrder=order; corner(card,6); stroke(card,T.borderGhost,1)
    pad(card,sc(12),sc(14),sc(12),sc(14))
    local col=fr(card,UDim2.new(1,0,1,0),nil,nil,1); vlist(col,sc(4))
    local tl=Instance.new("TextLabel")
    tl.Text=string.upper(topLbl); tl.TextSize=sc(9); tl.Font=MONO
    tl.TextColor3=T.textMuted; tl.BackgroundTransparency=1
    tl.Size=UDim2.new(1,0,0,sc(12)); tl.TextXAlignment=Enum.TextXAlignment.Left; tl.Parent=col
    local vl=Instance.new("TextLabel")
    vl.Text=tostring(valTxt); vl.TextSize=sc(18); vl.Font=BOLD
    vl.TextColor3=valCol or T.text; vl.BackgroundTransparency=1
    vl.Size=UDim2.new(1,0,0,sc(24)); vl.TextXAlignment=Enum.TextXAlignment.Left; vl.Parent=col
    local sub=Instance.new("TextLabel")
    sub.Text=tostring(subTxt or ""); sub.TextSize=sc(10); sub.Font=UI
    sub.TextColor3=T.textMuted; sub.BackgroundTransparency=1
    sub.Size=UDim2.new(1,0,0,sc(14)); sub.TextXAlignment=Enum.TextXAlignment.Left; sub.Parent=col
    return card,vl,sub
end

-- Row 1: Uptime + Connection (+ Place ID + Players on desktop)
local cardsRow1=fr(homeInner,UDim2.new(1,0,0,sc(IS_MOBILE and 72 or 84)),nil,nil,1)
cardsRow1.LayoutOrder=2; hlist(cardsRow1,sc(12))

local _,uptVal  =mkStatCard(cardsRow1,"Uptime",     "00:00:00",                  "Since attach",1)
local _,connVal =mkStatCard(cardsRow1,"Connection", "Active",                    "Injected",    2,T.success)

local cardsRow2
if IS_MOBILE then
    -- Row 2 mobile: Place ID + Players
    cardsRow2=fr(homeInner,UDim2.new(1,0,0,sc(IS_MOBILE and 72 or 84)),nil,nil,1)
    cardsRow2.LayoutOrder=3; hlist(cardsRow2,sc(12))
    mkStatCard(cardsRow2,"Place ID",tostring(game.PlaceId),"N/A",           1)
    local _,pv=mkStatCard(cardsRow2,"Players", tostring(#Players:GetPlayers()),"In server",2)
    -- wire live player count
    RunService.Heartbeat:Connect(function()
        local e=math.floor(tick()-tick())
        if pv and pv.Parent then pv.Text=tostring(#Players:GetPlayers()) end
    end)
else
    mkStatCard(cardsRow1,"Place ID",tostring(game.PlaceId),"N/A",           3)
    local _,pv=mkStatCard(cardsRow1,"Players", tostring(#Players:GetPlayers()),"In server",4)
    RunService.Heartbeat:Connect(function()
        if pv and pv.Parent then pv.Text=tostring(#Players:GetPlayers()) end
    end)
end

local startTime=tick()
RunService.Heartbeat:Connect(function()
    if uptVal and uptVal.Parent then
        local e=math.floor(tick()-startTime)
        uptVal.Text=string.format("%02d:%02d:%02d",math.floor(e/3600),math.floor((e%3600)/60),e%60)
    end
end)

-- Bottom row: system info + nearby
-- Desktop: side by side. Mobile: stacked.
local bottomRow=fr(homeInner,UDim2.new(1,0,0,0),nil,nil,1)
bottomRow.AutomaticSize=Enum.AutomaticSize.Y
bottomRow.LayoutOrder=IS_MOBILE and 4 or 3

if IS_MOBILE then
    vlist(bottomRow,sc(12))
else
    hlist(bottomRow,sc(12))
    bottomRow.Size=UDim2.new(1,0,0,sc(200))
end

-- System info card
local sysW=IS_MOBILE and 0 or math.floor((860-sc(48))*0.56)
local sysCard=fr(bottomRow,IS_MOBILE and UDim2.new(1,0,0,0) or UDim2.new(0,sysW,1,0),nil,T.surface)
if IS_MOBILE then sysCard.AutomaticSize=Enum.AutomaticSize.Y end
sysCard.LayoutOrder=1; corner(sysCard,6); stroke(sysCard,T.borderGhost,1)

local sysHdr=fr(sysCard,UDim2.new(1,0,0,sc(36)),nil,nil,1); pad(sysHdr,0,sc(16),0,sc(16))
local shl=Instance.new("TextLabel")
shl.Text="SYSTEM INFO"; shl.TextSize=sc(9); shl.Font=MONO; shl.TextColor3=T.textMuted
shl.BackgroundTransparency=1; shl.Size=UDim2.new(1,0,1,0)
shl.TextXAlignment=Enum.TextXAlignment.Left; shl.TextYAlignment=Enum.TextYAlignment.Center; shl.Parent=sysHdr
fr(sysCard,UDim2.new(1,0,0,1),UDim2.new(0,0,0,sc(36)),T.borderGhost)

local sysBody=fr(sysCard,UDim2.new(1,0,0,0),UDim2.new(0,0,0,sc(37)),nil,1)
sysBody.AutomaticSize=Enum.AutomaticSize.Y; vlist(sysBody,0); pad(sysBody,sc(10),sc(16),sc(10),sc(16))

local function sysRow(k,v,vc,order)
    local row=fr(sysBody,UDim2.new(1,0,0,sc(32)),nil,nil,1); row.LayoutOrder=order or 0
    if order and order>1 then
        local sep=fr(row,UDim2.new(1,0,0,1),UDim2.new(0,0,0,0),T.borderGhost); sep.ZIndex=0
    end
    local kl=Instance.new("TextLabel")
    kl.Text=k; kl.TextSize=sc(10); kl.Font=UI; kl.TextColor3=T.textMuted
    kl.BackgroundTransparency=1; kl.Size=UDim2.new(0.4,0,1,0)
    kl.TextXAlignment=Enum.TextXAlignment.Left; kl.TextYAlignment=Enum.TextYAlignment.Center; kl.Parent=row
    local vl=Instance.new("TextLabel")
    vl.Text=v; vl.TextSize=sc(11); vl.Font=MONO; vl.TextColor3=vc or T.text
    vl.BackgroundTransparency=1; vl.Size=UDim2.new(0.6,0,1,0); vl.Position=UDim2.new(0.4,0,0,0)
    vl.TextXAlignment=Enum.TextXAlignment.Left; vl.TextYAlignment=Enum.TextYAlignment.Center; vl.Parent=row
end

sysRow("Executor", SYS.executor, T.text,     1)
sysRow("Platform", SYS.platform, T.text,     2)
sysRow("HWID",     SYS.hwid,     T.textMuted,3)
divLine(sysBody,4)

local premRow=fr(sysBody,UDim2.new(1,0,0,sc(36)),nil,nil,1); premRow.LayoutOrder=5
local premLbl=Instance.new("TextLabel")
premLbl.Text="Tier"; premLbl.TextSize=sc(10); premLbl.Font=UI; premLbl.TextColor3=T.textMuted
premLbl.BackgroundTransparency=1; premLbl.Size=UDim2.new(0.4,0,1,0)
premLbl.TextXAlignment=Enum.TextXAlignment.Left; premLbl.TextYAlignment=Enum.TextYAlignment.Center
premLbl.Parent=premRow
local bc=SYS.premium and T.success or T.borderDim
local bt=SYS.premium and "✦ PREMIUM" or "FREE"
local badge=fr(premRow,UDim2.new(0,0,0,sc(20)),UDim2.new(0.4,0,0.5,-sc(10)),T.surface)
badge.AutomaticSize=Enum.AutomaticSize.X; corner(badge,3); stroke(badge,bc,1)
local bl=Instance.new("TextLabel")
bl.Text=bt; bl.TextSize=sc(9); bl.Font=MONO; bl.TextColor3=bc
bl.BackgroundTransparency=1; bl.Size=UDim2.new(0,0,1,0); bl.AutomaticSize=Enum.AutomaticSize.X
bl.TextXAlignment=Enum.TextXAlignment.Center; bl.TextYAlignment=Enum.TextYAlignment.Center
bl.Parent=badge; pad(bl,0,sc(8),0,sc(8))

-- Nearby card
local nearbyW=IS_MOBILE and 0 or (860-sc(48)-sysW-sc(12))
local nearbyCard=fr(bottomRow,IS_MOBILE and UDim2.new(1,0,0,sc(170)) or UDim2.new(0,nearbyW,1,0),nil,T.surface)
nearbyCard.LayoutOrder=2; corner(nearbyCard,6); stroke(nearbyCard,T.borderGhost,1)
local nearbyHdr=fr(nearbyCard,UDim2.new(1,0,0,sc(36)),nil,nil,1); pad(nearbyHdr,0,sc(16),0,sc(16))
local nlbl=Instance.new("TextLabel")
nlbl.Text="NEARBY"; nlbl.TextSize=sc(9); nlbl.Font=MONO; nlbl.TextColor3=T.textMuted
nlbl.BackgroundTransparency=1; nlbl.Size=UDim2.new(1,0,1,0)
nlbl.TextXAlignment=Enum.TextXAlignment.Left; nlbl.TextYAlignment=Enum.TextYAlignment.Center; nlbl.Parent=nearbyHdr
fr(nearbyCard,UDim2.new(1,0,0,1),UDim2.new(0,0,0,sc(36)),T.borderGhost)
local nearbyScroll=mkScroll(nearbyCard,UDim2.new(1,0,1,-sc(37)),UDim2.new(0,0,0,sc(37)))
local nearbyList=fr(nearbyScroll,UDim2.new(1,0,0,0),nil,nil,1)
nearbyList.AutomaticSize=Enum.AutomaticSize.Y; vlist(nearbyList,0); pad(nearbyList,sc(4),sc(12),sc(4),sc(12))

local function refreshNearby()
    for _,c in ipairs(nearbyList:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
    end
    local lc=LocalPlayer.Character; local lr=lc and lc:FindFirstChild("HumanoidRootPart")
    local entries={}
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            local ch=p.Character; local rt=ch and ch:FindFirstChild("HumanoidRootPart")
            local d=(lr and rt) and math.floor((lr.Position-rt.Position).Magnitude) or 0
            table.insert(entries,{name=p.Name,dist=d})
        end
    end
    table.sort(entries,function(a,b) return a.dist<b.dist end)
    for i,e in ipairs(entries) do mkPlayerRow(nearbyList,e.name,e.dist.."m",i) end
    if #entries==0 then
        local el=Instance.new("TextLabel")
        el.Text="No other players"; el.TextSize=sc(11); el.Font=UI; el.TextColor3=T.textDim
        el.BackgroundTransparency=1; el.Size=UDim2.new(1,0,0,sc(28))
        el.TextXAlignment=Enum.TextXAlignment.Left; el.TextYAlignment=Enum.TextYAlignment.Center; el.Parent=nearbyList
    end
end
refreshNearby()
task.spawn(function() while gui.Parent do task.wait(3); refreshNearby() end end)

-- ============================================================
-- PLAYERS PAGE
-- ============================================================
local playersPage=addPage("players","Players")
local plTitle=Instance.new("TextLabel")
plTitle.Text="Players in Server"; plTitle.TextSize=sc(15); plTitle.Font=BOLD
plTitle.TextColor3=T.text; plTitle.BackgroundTransparency=1
plTitle.Size=UDim2.new(1,-sc(IS_MOBILE and 24 or 48),0,sc(24)); plTitle.Position=UDim2.new(0,sc(IS_MOBILE and 12 or 24),0,sc(10))
plTitle.TextXAlignment=Enum.TextXAlignment.Left; plTitle.Parent=playersPage
local plScroll=mkScroll(playersPage,UDim2.new(1,-sc(IS_MOBILE and 24 or 48),1,-sc(IS_MOBILE and 42 or 44)),UDim2.new(0,sc(IS_MOBILE and 12 or 24),0,sc(IS_MOBILE and 42 or 44)))
local plList=fr(plScroll,UDim2.new(1,0,0,0),nil,nil,1)
plList.AutomaticSize=Enum.AutomaticSize.Y; vlist(plList,sc(6))
local function refreshPlayerList()
    for _,c in ipairs(plList:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
    local lc=LocalPlayer.Character; local lr=lc and lc:FindFirstChild("HumanoidRootPart")
    for i,p in ipairs(Players:GetPlayers()) do
        local card=fr(plList,UDim2.new(1,0,0,sc(46)),nil,T.surface)
        card.LayoutOrder=i; corner(card,5); stroke(card,T.borderGhost,1); pad(card,0,sc(14),0,sc(14))
        local dot=fr(card,UDim2.new(0,sc(6),0,sc(6)),UDim2.new(0,0,0.5,-sc(3)),p==LocalPlayer and T.success or T.textDim); corner(dot,3)
        local nameCol=fr(card,UDim2.new(0,sc(200),1,0),UDim2.new(0,sc(14),0,0),nil,1)
        vlist(nameCol,2); pad(nameCol,sc(10),0,sc(10),0)
        local dn=Instance.new("TextLabel"); dn.Text=p.DisplayName; dn.TextSize=sc(12); dn.Font=BOLD; dn.TextColor3=T.text
        dn.BackgroundTransparency=1; dn.Size=UDim2.new(1,0,0,sc(15)); dn.TextXAlignment=Enum.TextXAlignment.Left; dn.Parent=nameCol
        local un=Instance.new("TextLabel"); un.Text="@"..p.Name; un.TextSize=sc(10); un.Font=UI; un.TextColor3=T.textMuted
        un.BackgroundTransparency=1; un.Size=UDim2.new(1,0,0,sc(13)); un.TextXAlignment=Enum.TextXAlignment.Left; un.Parent=nameCol
        local ch=p.Character; local rt=ch and ch:FindFirstChild("HumanoidRootPart")
        local d=(lr and rt) and math.floor((lr.Position-rt.Position).Magnitude) or 0
        local dl=Instance.new("TextLabel"); dl.Text=p==LocalPlayer and "You" or d.."m"
        dl.TextSize=sc(11); dl.Font=MONO; dl.TextColor3=p==LocalPlayer and T.success or T.textMuted
        dl.BackgroundTransparency=1; dl.Size=UDim2.new(1,-sc(214),1,0); dl.Position=UDim2.new(0,sc(214),0,0)
        dl.TextXAlignment=Enum.TextXAlignment.Right; dl.TextYAlignment=Enum.TextYAlignment.Center; dl.Parent=card
    end
end
refreshPlayerList()
task.spawn(function() while gui.Parent do task.wait(4); refreshPlayerList() end end)

-- ============================================================
-- ============================================================
-- COMBAT WARRIORS — GAME SYSTEMS
-- ============================================================

local Camera = workspace.CurrentCamera

local function getChar()  return LocalPlayer.Character end
local function getHum()   local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

local function getEnemies(teamCheck)
    local out={}
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            if not (teamCheck and p.Team==LocalPlayer.Team) then
                out[#out+1]=p
            end
        end
    end
    return out
end

local function getNearestEnemy(range, teamCheck)
    local root=getRoot(); if not root then return nil end
    local best,bestDist=nil,range or math.huge
    for _,p in ipairs(getEnemies(teamCheck)) do
        local c=p.Character
        local r=c and c:FindFirstChild("HumanoidRootPart")
        if r then
            local d=(root.Position-r.Position).Magnitude
            if d<bestDist then bestDist=d; best=p end
        end
    end
    return best,bestDist
end

-- Config
local CFG={
    parryEnabled=false, parryDelay=8, parryRange=20, parryVisualize=false,
    auraEnabled=false,  auraRange=12, auraDelay=10,  auraTeamCheck=false,
    staminaEnabled=false,
    autoBlockEnabled=false, antiStunEnabled=false, antiRagEnabled=false,
    espEnabled=false, espBox=true, espName=true, espHealth=true, espDist=true, espTeamCheck=false, espMaxDist=500,
    speedEnabled=false, speedValue=30,
    flyEnabled=false,   flySpeed=50,
    noclipEnabled=false, infJump=false,
    fullbright=false, noFog=false, fakeLag=false,
}

local CWState={parryDebounce=false,auraDebounce=false,flyBV=nil,flyBG=nil,espObjects={}}

-- [1] Infinite Stamina
RunService.Heartbeat:Connect(function()
    if not CFG.staminaEnabled then return end
    local c=getChar(); if not c then return end
    local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
    pcall(function() if hum:GetAttribute("Stamina")~=nil then hum:SetAttribute("Stamina",100) end end)
    local sv=c:FindFirstChild("Stamina") or hum:FindFirstChild("Stamina")
    if sv and sv:IsA("NumberValue") and sv.Value<100 then sv.Value=100 end
end)

-- [2] Auto Parry
local ATTACK_KW={"swing","attack","slash","stab","combo","punch","hit"}
local function isAttack(name)
    name=name:lower()
    for _,k in ipairs(ATTACK_KW) do if name:find(k) then return true end end
    return false
end
local function fireParry()
    if CWState.parryDebounce then return end
    CWState.parryDebounce=true
    task.delay(CFG.parryDelay/100,function()
        pcall(function()
            local vim=game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true,Enum.KeyCode.Q,false,game)
            task.delay(0.05,function() vim:SendKeyEvent(false,Enum.KeyCode.Q,false,game) end)
        end)
        task.delay(0.3,function() CWState.parryDebounce=false end)
    end)
end
local function watchForAttacks(p)
    local char=p.Character or p.CharacterAdded:Wait()
    local hum=char:WaitForChild("Humanoid",5); if not hum then return end
    local anim=hum:FindFirstChildOfClass("Animator"); if not anim then return end
    anim.AnimationPlayed:Connect(function(track)
        if not CFG.parryEnabled then return end
        local root=getRoot(); if not root then return end
        local pr=char:FindFirstChild("HumanoidRootPart"); if not pr then return end
        if (root.Position-pr.Position).Magnitude>CFG.parryRange then return end
        if isAttack(track.Name) then fireParry() end
    end)
end
for _,p in ipairs(Players:GetPlayers()) do
    if p~=LocalPlayer then task.spawn(watchForAttacks,p) end
end
Players.PlayerAdded:Connect(function(p) task.spawn(watchForAttacks,p) end)

-- [3] ESP
local CoreGui=_CoreGui
local function clearESP(player)
    local obj=CWState.espObjects[player]
    if obj then for _,v in pairs(obj) do pcall(function() v:Destroy() end) end end
    CWState.espObjects[player]=nil
end
local function buildESP(player)
    clearESP(player)
    local hl=Instance.new("Highlight",CoreGui)
    hl.Name="NitreHL_"..player.Name
    hl.FillTransparency=0.85; hl.OutlineTransparency=0
    hl.FillColor=Color3.fromRGB(255,60,60); hl.OutlineColor=Color3.fromRGB(255,60,60)
    local bb=Instance.new("BillboardGui",CoreGui)
    bb.Name="NitreBB_"..player.Name
    bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,200,0,50); bb.StudsOffset=Vector3.new(0,3,0)
    local nl=Instance.new("TextLabel",bb)
    nl.Name="NL"; nl.BackgroundTransparency=1; nl.Size=UDim2.new(1,0,0.5,0)
    nl.Font=Enum.Font.GothamBold; nl.TextSize=13; nl.TextColor3=Color3.new(1,1,1)
    nl.TextStrokeTransparency=0; nl.TextXAlignment=Enum.TextXAlignment.Center
    local il=Instance.new("TextLabel",bb)
    il.Name="IL"; il.BackgroundTransparency=1; il.Size=UDim2.new(1,0,0.5,0); il.Position=UDim2.new(0,0,0.5,0)
    il.Font=Enum.Font.Code; il.TextSize=11; il.TextColor3=Color3.fromRGB(80,220,120)
    il.TextStrokeTransparency=0; il.TextXAlignment=Enum.TextXAlignment.Center
    CWState.espObjects[player]={hl=hl,bb=bb}
end
Players.PlayerRemoving:Connect(clearESP)
RunService.RenderStepped:Connect(function()
    if not CFG.espEnabled then
        for p in pairs(CWState.espObjects) do clearESP(p) end
        return
    end
    local myRoot=getRoot()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
        if CFG.espTeamCheck and p.Team==LocalPlayer.Team then clearESP(p)
        else
        local char=p.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not char or not root or not hum or not myRoot then clearESP(p)
        else
        local dist=(myRoot.Position-root.Position).Magnitude
        if dist>CFG.espMaxDist then clearESP(p)
        else
        if not CWState.espObjects[p] then buildESP(p) end
        local obj=CWState.espObjects[p]
        obj.hl.Adornee=char; obj.hl.Enabled=CFG.espBox
        obj.bb.Adornee=root
        local nl=obj.bb:FindFirstChild("NL"); local il=obj.bb:FindFirstChild("IL")
        if nl then nl.Visible=CFG.espName; nl.Text=p.Name end
        if il then
            local parts={}
            if CFG.espHealth then parts[#parts+1]=string.format("HP %d/%d",math.floor(hum.Health),math.floor(hum.MaxHealth)) end
            if CFG.espDist   then parts[#parts+1]=string.format("%dm",math.floor(dist)) end
            il.Text=table.concat(parts,"  "); il.Visible=#parts>0
        end
        end end end end -- close: dist, char/root/hum, teamCheck, LocalPlayer
    end
    for p in pairs(CWState.espObjects) do if not p.Parent then clearESP(p) end end
end)

-- [4] Kill Aura
RunService.Heartbeat:Connect(function()
    if not CFG.auraEnabled or CWState.auraDebounce then return end
    local target=getNearestEnemy(CFG.auraRange,CFG.auraTeamCheck); if not target then return end
    local char=target.Character
    local tRoot=char and char:FindFirstChild("HumanoidRootPart")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    local myRoot=getRoot()
    if not tRoot or not hum or not myRoot or hum.Health<=0 then return end
    CWState.auraDebounce=true
    myRoot.CFrame=CFrame.lookAt(myRoot.Position,tRoot.Position)
    pcall(function()
        local tool=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then local re=tool:FindFirstChildOfClass("RemoteEvent"); if re then re:FireServer(tRoot.Position) end end
    end)
    pcall(function()
        local vim=game:GetService("VirtualInputManager")
        local sp=Camera:WorldToViewportPoint(tRoot.Position)
        vim:SendMouseButtonEvent(sp.X,sp.Y,0,true,game,0)
        task.delay(0.05,function() vim:SendMouseButtonEvent(sp.X,sp.Y,0,false,game,0) end)
    end)
    task.delay(CFG.auraDelay/100,function() CWState.auraDebounce=false end)
end)

-- [5] Movement
RunService.Heartbeat:Connect(function()
    local hum=getHum(); if not hum then return end
    if CFG.speedEnabled then hum.WalkSpeed=CFG.speedValue end
    if CFG.noclipEnabled then
        local c=getChar(); if not c then return end
        for _,v in ipairs(c:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end
    end
end)
UserInputService.JumpRequest:Connect(function()
    if not CFG.infJump then return end
    local hum=getHum(); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)
local function startFly()
    local root=getRoot(); if not root then return end
    local bv=Instance.new("BodyVelocity",root)
    bv.Velocity=Vector3.zero; bv.MaxForce=Vector3.new(1e5,1e5,1e5); CWState.flyBV=bv
    local bg=Instance.new("BodyGyro",root)
    bg.MaxTorque=Vector3.new(1e5,1e5,1e5); bg.D=100; CWState.flyBG=bg
    local c; c=RunService.RenderStepped:Connect(function()
        if not CFG.flyEnabled then
            pcall(function() bv:Destroy() end); pcall(function() bg:Destroy() end)
            CWState.flyBV=nil; CWState.flyBG=nil; c:Disconnect(); return
        end
        local dir=Vector3.zero; local cf=Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir=dir+cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir=dir-cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir=dir-cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir=dir+cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir=dir-Vector3.new(0,1,0) end
        if dir.Magnitude>0 then dir=dir.Unit end
        bv.Velocity=dir*CFG.flySpeed; bg.CFrame=Camera.CFrame
    end)
end
local function stopFly()
    if CWState.flyBV then pcall(function() CWState.flyBV:Destroy() end); CWState.flyBV=nil end
    if CWState.flyBG then pcall(function() CWState.flyBG:Destroy() end); CWState.flyBG=nil end
end

-- [6] Misc
RunService.Heartbeat:Connect(function()
    local hum=getHum()
    if hum then
        if CFG.antiRagEnabled then
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
        end
        if CFG.antiStunEnabled then
            pcall(function()
                if hum:GetAttribute("Stun")~=nil    then hum:SetAttribute("Stun",0)       end
                if hum:GetAttribute("Stunned")~=nil then hum:SetAttribute("Stunned",false) end
            end)
        end
    end
    if CFG.fullbright then
        game:GetService("Lighting").Brightness=2
        game:GetService("Lighting").ClockTime=14
    end
    if CFG.noFog or CFG.fullbright then
        game:GetService("Lighting").FogEnd=1e6
        game:GetService("Lighting").FogStart=9e5
    end
end)

-- ============================================================
-- COMBAT PAGE
-- ============================================================
local combatPage=addPage("combat","Combat")
local combatScroll=mkScroll(combatPage,UDim2.new(1,-sc(IS_MOBILE and 24 or 48),1,0),UDim2.new(0,sc(IS_MOBILE and 12 or 24),0,0))
local combatInner=fr(combatScroll,UDim2.new(1,0,0,0),nil,nil,1)
combatInner.AutomaticSize=Enum.AutomaticSize.Y; vlist(combatInner,sc(8)); pad(combatInner,sc(16),0,sc(16),0)

secLabel(combatInner,"Auto Parry",1)
mkToggle(combatInner,"Auto Parry","Fire Q on detected incoming swings",CFG.parryEnabled,2,function(v) CFG.parryEnabled=v end)
mkSlider(combatInner,"Parry Delay (ms)",1,50,CFG.parryDelay,3,function(v) CFG.parryDelay=v end)
mkSlider(combatInner,"Parry Range (studs)",5,60,CFG.parryRange,4,function(v) CFG.parryRange=v end)
mkToggle(combatInner,"Visualize Trigger","Highlight parry window",CFG.parryVisualize,5,function(v) CFG.parryVisualize=v end)
divLine(combatInner,6)

secLabel(combatInner,"Kill Aura",7)
mkToggle(combatInner,"Kill Aura","Auto-attack nearest enemy",CFG.auraEnabled,8,function(v) CFG.auraEnabled=v end)
mkSlider(combatInner,"Range (studs)",4,40,CFG.auraRange,9,function(v) CFG.auraRange=v end)
mkSlider(combatInner,"Attack Delay (ms)",5,100,CFG.auraDelay,10,function(v) CFG.auraDelay=v end)
mkToggle(combatInner,"Team Check","Skip teammates",CFG.auraTeamCheck,11,function(v) CFG.auraTeamCheck=v end)
divLine(combatInner,12)

secLabel(combatInner,"Stamina",13)
mkToggle(combatInner,"Infinite Stamina","Lock stamina at max",CFG.staminaEnabled,14,function(v) CFG.staminaEnabled=v end)
divLine(combatInner,15)

secLabel(combatInner,"Defense",16)
mkToggle(combatInner,"Auto Block","Hold block passively",CFG.autoBlockEnabled,17,function(v) CFG.autoBlockEnabled=v end)
mkToggle(combatInner,"Anti-Stun","Clear stun attribute each frame",CFG.antiStunEnabled,18,function(v) CFG.antiStunEnabled=v end)
mkToggle(combatInner,"Anti-Ragdoll","Disable ragdoll states",CFG.antiRagEnabled,19,function(v) CFG.antiRagEnabled=v end)

-- ============================================================
-- VISUALS PAGE (replaces placeholder — real ESP callbacks)
-- ============================================================
local visualsPage=addPage("visuals","Visuals")
local visScroll=mkScroll(visualsPage,UDim2.new(1,-sc(IS_MOBILE and 24 or 48),1,0),UDim2.new(0,sc(IS_MOBILE and 12 or 24),0,0))
local visInner=fr(visScroll,UDim2.new(1,0,0,0),nil,nil,1)
visInner.AutomaticSize=Enum.AutomaticSize.Y; vlist(visInner,sc(8)); pad(visInner,sc(16),0,sc(16),0)

secLabel(visInner,"ESP",1)
mkToggle(visInner,"Player ESP",  "Box outlines + info on all players",CFG.espEnabled, 2,function(v) CFG.espEnabled=v end)
mkToggle(visInner,"Show Box",    "Highlight outline around character", CFG.espBox,     3,function(v) CFG.espBox=v end)
mkToggle(visInner,"Show Name",   "Username above head",                CFG.espName,    4,function(v) CFG.espName=v end)
mkToggle(visInner,"Show Health", "HP values below name",               CFG.espHealth,  5,function(v) CFG.espHealth=v end)
mkToggle(visInner,"Show Distance","Distance in studs",                 CFG.espDist,    6,function(v) CFG.espDist=v end)
mkToggle(visInner,"Team Check",  "Skip players on your team",          CFG.espTeamCheck,7,function(v) CFG.espTeamCheck=v end)
divLine(visInner,8)
secLabel(visInner,"World",9)
mkToggle(visInner,"Fullbright",  "Maximum ambient lighting",           CFG.fullbright, 10,function(v) CFG.fullbright=v end)
mkToggle(visInner,"No Fog",      "Remove atmospheric fog",             CFG.noFog,      11,function(v) CFG.noFog=v end)
divLine(visInner,12)
secLabel(visInner,"Distances",13)
mkSlider(visInner,"ESP Max Distance",50,1000,CFG.espMaxDist,14,function(v) CFG.espMaxDist=v end)

-- ============================================================
-- MOVEMENT PAGE (replaces Aimbot placeholder)
-- ============================================================
local movePage=addPage("movement","Movement")
local moveScroll=mkScroll(movePage,UDim2.new(1,-sc(IS_MOBILE and 24 or 48),1,0),UDim2.new(0,sc(IS_MOBILE and 12 or 24),0,0))
local moveInner=fr(moveScroll,UDim2.new(1,0,0,0),nil,nil,1)
moveInner.AutomaticSize=Enum.AutomaticSize.Y; vlist(moveInner,sc(8)); pad(moveInner,sc(16),0,sc(16),0)

secLabel(moveInner,"Speed",1)
mkToggle(moveInner,"Speed Hack","Override walk speed",CFG.speedEnabled,2,function(v)
    CFG.speedEnabled=v
    if not v then local h=getHum(); if h then h.WalkSpeed=16 end end
end)
mkSlider(moveInner,"Walk Speed",16,150,CFG.speedValue,3,function(v) CFG.speedValue=v end)
divLine(moveInner,4)
secLabel(moveInner,"Fly",5)
mkToggle(moveInner,"Fly","Camera-relative WASD flight",CFG.flyEnabled,6,function(v)
    CFG.flyEnabled=v
    if v then startFly() else stopFly() end
end)
mkSlider(moveInner,"Fly Speed",10,200,CFG.flySpeed,7,function(v) CFG.flySpeed=v end)
divLine(moveInner,8)
secLabel(moveInner,"Other",9)
mkToggle(moveInner,"Noclip","Disable character collisions",CFG.noclipEnabled,10,function(v) CFG.noclipEnabled=v end)
mkToggle(moveInner,"Infinite Jump","Jump again mid-air",CFG.infJump,11,function(v) CFG.infJump=v end)

-- SETTINGS PAGE
-- ============================================================
local settingsPage=addPage("settings","Settings")
local setScroll=mkScroll(settingsPage,UDim2.new(1,-sc(IS_MOBILE and 24 or 48),1,0),UDim2.new(0,sc(IS_MOBILE and 12 or 24),0,0))
local setInner=fr(setScroll,UDim2.new(1,0,0,0),nil,nil,1)
setInner.AutomaticSize=Enum.AutomaticSize.Y; vlist(setInner,sc(8)); pad(setInner,sc(16),0,sc(16),0)
secLabel(setInner,"Interface",1)
mkToggle(setInner,"Toast Notifications","Load & error messages",true,2)
mkToggle(setInner,"Auto-Open on Join",  "Open menu on game load",true,3)
divLine(setInner,4)
secLabel(setInner,"Keybinds",5)
mkKeybind(setInner,"Toggle Menu",   {"INSERT"},            6)
mkKeybind(setInner,"Silent Aim",    {"RMB"},               7)
mkKeybind(setInner,"Panic / Close", {"LCTRL","ALT","END"}, 8)
divLine(setInner,9)
secLabel(setInner,"About",10)
local aboutCard=fr(setInner,UDim2.new(1,0,0,0),nil,T.surface)
aboutCard.AutomaticSize=Enum.AutomaticSize.Y; aboutCard.LayoutOrder=11
corner(aboutCard,6); stroke(aboutCard,T.borderGhost,1); pad(aboutCard,sc(14),sc(16),sc(14),sc(16))
local aboutCol=fr(aboutCard,UDim2.new(1,0,0,0),nil,nil,1)
aboutCol.AutomaticSize=Enum.AutomaticSize.Y; vlist(aboutCol,sc(6))
local function infoRow(p,k,v,order)
    local r=fr(p,UDim2.new(1,0,0,sc(18)),nil,nil,1); r.LayoutOrder=order or 0
    local kl=Instance.new("TextLabel"); kl.Text=k; kl.TextSize=sc(11); kl.Font=UI; kl.TextColor3=T.textMuted
    kl.BackgroundTransparency=1; kl.Size=UDim2.new(0.45,0,1,0); kl.TextXAlignment=Enum.TextXAlignment.Left; kl.Parent=r
    local vl2=Instance.new("TextLabel"); vl2.Text=v; vl2.TextSize=sc(11); vl2.Font=MONO; vl2.TextColor3=T.text
    vl2.BackgroundTransparency=1; vl2.Size=UDim2.new(0.55,0,1,0); vl2.Position=UDim2.new(0.45,0,0,0)
    vl2.TextXAlignment=Enum.TextXAlignment.Right; vl2.Parent=r
end
infoRow(aboutCol,"Creator",  "rightpapi",       1)
infoRow(aboutCol,"Hub",      "Nitremia.gg",     2)
infoRow(aboutCol,"Executor", SYS.executor,      3)
infoRow(aboutCol,"Platform", SYS.platform,      4)
infoRow(aboutCol,"Build",    os.date("%Y-%m-%d"),5)


-- ============================================================
-- MOBILE VIEWPORT FIT
-- ============================================================
if IS_MOBILE then
    local function fitMobileWindow()
        local vp = getViewport()
        local mobileW = math.min(vp.X - 24, 860)
        local mobileH = math.min(vp.Y - 32, 620)
        win.Size = UDim2.new(0, mobileW, 0, mobileH)
        win.Position = UDim2.new(0.5, -mobileW/2, 0.5, -mobileH/2)
    end

    local cam = workspace.CurrentCamera
    if cam then
        cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitMobileWindow)
    end
end

-- ============================================================
-- INIT
-- ============================================================
showPage("home")
task.delay(0.9,function()
    _toast("Systems successfully saturated.")
end)
