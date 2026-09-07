-- ============================================================
-- Nitre MM2
-- Creator: rightpapi
-- Hub: Nitremia.gg
-- ============================================================

repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

local VALID_PLACE_IDS = { [142823291] = true }
if not VALID_PLACE_IDS[game.PlaceId] then
    warn("[Nitre MM2] Invalid PlaceId: " .. tostring(game.PlaceId))
    return
end

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local SoundService      = game:GetService("SoundService")
local TeleportService   = game:GetService("TeleportService")
local Stats             = game:GetService("Stats")
local HttpService       = game:GetService("HttpService")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

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
    sheriff      = Color3.fromRGB(255, 204, 0),
    murderer     = Color3.fromRGB(255, 68,  68),
    innocent     = Color3.fromRGB(68,  255, 136),
}

local MONO = Enum.Font.Code
local UI   = Enum.Font.Gotham
local BOLD = Enum.Font.GothamBold

local function getViewport()
    return Camera and Camera.ViewportSize or Vector2.new(1024, 768)
end
local function getUIScale()
    if not IS_MOBILE then return 1.0 end
    local v = getViewport()
    return math.clamp(math.min(v.X / 830, v.Y / 760), 0.88, 1.0)
end
local SCALE = getUIScale()
local function sc(n) return math.max(1, math.floor(n * SCALE)) end

local function corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = p; return c
end
local function stroke(p, col, thick)
    local s = Instance.new("UIStroke"); s.Color = col or T.border; s.Thickness = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end
local function pad(p, t, r, b, l)
    local u = Instance.new("UIPadding")
    u.PaddingTop = UDim.new(0, t or 8); u.PaddingRight = UDim.new(0, r or 12)
    u.PaddingBottom = UDim.new(0, b or 8); u.PaddingLeft = UDim.new(0, l or 12)
    u.Parent = p; return u
end
local function vlist(p, spacing)
    local l = Instance.new("UIListLayout"); l.FillDirection = Enum.FillDirection.Vertical
    l.SortOrder = Enum.SortOrder.LayoutOrder; l.Padding = UDim.new(0, spacing or 0); l.Parent = p; return l
end
local function hlist(p, spacing)
    local l = Instance.new("UIListLayout"); l.FillDirection = Enum.FillDirection.Horizontal
    l.SortOrder = Enum.SortOrder.LayoutOrder; l.Padding = UDim.new(0, spacing or 0); l.Parent = p; return l
end
local function fr(p, size, pos, bg, trans)
    local f = Instance.new("Frame"); f.Size = size; f.Position = pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3 = bg or T.surface; f.BackgroundTransparency = trans or 0
    f.BorderSizePixel = 0; f.Parent = p; return f
end
local function tw(obj, props, t)
    if not obj or not obj.Parent then return end
    TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), props):Play()
end
local function divLine(p, order)
    local f = fr(p, UDim2.new(1,0,0,1), nil, T.borderGhost); f.LayoutOrder = order or 99; return f
end
local function secLabel(p, txt, order)
    local l = Instance.new("TextLabel"); l.Text = string.upper(txt); l.TextSize = sc(9); l.Font = MONO
    l.TextColor3 = T.textDim; l.BackgroundTransparency = 1; l.Size = UDim2.new(1,0,0,sc(14))
    l.TextXAlignment = Enum.TextXAlignment.Left; l.LayoutOrder = order or 0; l.Parent = p; return l
end
local function mkScroll(p, size, pos)
    local s = Instance.new("ScrollingFrame"); s.Size = size; s.Position = pos or UDim2.new(0,0,0,0)
    s.BackgroundTransparency = 1; s.BorderSizePixel = 0
    s.ScrollBarThickness = IS_MOBILE and 3 or 2; s.ScrollBarImageColor3 = T.borderDim
    s.CanvasSize = UDim2.new(0,0,0,0); s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    s.ScrollingDirection = Enum.ScrollingDirection.Y; s.Parent = p; return s
end

local function makeDraggable(win, handle)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local d = i.Position - ds
            win.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

local _toast
local function initToast(gui)
    local stack = fr(gui, UDim2.new(0,sc(260),1,-40), UDim2.new(1,-sc(272),0,0), nil, 1)
    local layout = vlist(stack, 6); layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    pad(stack, 0, 0, sc(20), 0)
    local icons = { default="◈", success="◉", warn="◎", danger="◌" }
    local cols  = { default=T.border, success=T.success, warn=T.warn, danger=T.danger }
    _toast = function(msg, kind)
        kind = kind or "default"
        local t = fr(stack, UDim2.new(1,0,0,sc(36)), nil, T.surface)
        corner(t, 4); stroke(t, cols[kind] or T.border, 1); t.BackgroundTransparency = 1
        local row = fr(t, UDim2.new(1,0,1,0), nil, nil, 1); hlist(row, sc(8)); pad(row,0,sc(12),0,sc(12))
        local ic = Instance.new("TextLabel"); ic.Text = icons[kind] or "◈"; ic.TextSize = sc(12); ic.Font = MONO
        ic.TextColor3 = cols[kind] or T.border; ic.BackgroundTransparency = 1
        ic.Size = UDim2.new(0,sc(12),1,0); ic.TextYAlignment = Enum.TextYAlignment.Center; ic.Parent = row
        local ml = Instance.new("TextLabel"); ml.Text = msg; ml.TextSize = sc(11); ml.Font = MONO
        ml.TextColor3 = cols[kind] or T.border; ml.BackgroundTransparency = 1
        ml.Size = UDim2.new(1,-sc(20),1,0)
        ml.TextXAlignment = Enum.TextXAlignment.Left; ml.TextYAlignment = Enum.TextYAlignment.Center; ml.Parent = row
        tw(t, {BackgroundTransparency=0}, 0.2)
        task.delay(3.2, function() tw(t, {BackgroundTransparency=1}, 0.2); task.delay(0.25, function() t:Destroy() end) end)
    end
end

local function mkToggle(p, name, default, order, cb)
    local row = fr(p, UDim2.new(1,0,0,sc(30)), nil, nil, 1); row.LayoutOrder = order or 0
    local texts = fr(row, UDim2.new(1,-sc(52),1,0), nil, nil, 1)
    pad(texts, sc(8), 0, sc(8), 0)
    local ml = Instance.new("TextLabel"); ml.Text = name; ml.TextSize = sc(12); ml.Font = UI; ml.TextColor3 = T.text
    ml.BackgroundTransparency = 1; ml.Size = UDim2.new(1,0,1,0); ml.TextXAlignment = Enum.TextXAlignment.Left
    ml.TextYAlignment = Enum.TextYAlignment.Center; ml.Parent = texts
    local track = fr(row, UDim2.new(0,sc(38),0,sc(20)), UDim2.new(1,-sc(38),0.5,-sc(10)), T.bg); corner(track, sc(10))
    local ts = stroke(track, default and T.border or T.borderDim, 1)
    local thumb = fr(track, UDim2.new(0,sc(12),0,sc(12)),
        default and UDim2.new(1,-sc(15),0.5,-sc(6)) or UDim2.new(0,sc(3),0.5,-sc(6)),
        default and T.text or T.textMuted)
    corner(thumb, sc(6))
    local state = default or false
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""; btn.Parent = row
    local function setState(v)
        state = v
        tw(thumb, {
            Position = state and UDim2.new(1,-sc(15),0.5,-sc(6)) or UDim2.new(0,sc(3),0.5,-sc(6)),
            BackgroundColor3 = state and T.text or T.textMuted
        }, 0.15)
        tw(ts, {Color = state and T.border or T.borderDim}, 0.15)
    end
    btn.MouseButton1Click:Connect(function()
        setState(not state)
        if cb then cb(state) end
    end)
    return row, function() return state end, setState
end

local function mkSlider(p, name, min, max, default, order, cb)
    local c = fr(p, UDim2.new(1,0,0,sc(44)), nil, nil, 1); c.LayoutOrder = order or 0
    local hdr = fr(c, UDim2.new(1,0,0,sc(16)), nil, nil, 1)
    local nl = Instance.new("TextLabel"); nl.Text = name; nl.TextSize = sc(12); nl.Font = UI; nl.TextColor3 = T.text
    nl.BackgroundTransparency = 1; nl.Size = UDim2.new(0.7,0,1,0); nl.TextXAlignment = Enum.TextXAlignment.Left; nl.Parent = hdr
    local vl = Instance.new("TextLabel"); vl.Text = tostring(default); vl.TextSize = sc(10); vl.Font = MONO; vl.TextColor3 = T.textMuted
    vl.BackgroundTransparency = 1; vl.Size = UDim2.new(0.3,0,1,0); vl.Position = UDim2.new(0.7,0,0,0)
    vl.TextXAlignment = Enum.TextXAlignment.Right; vl.Parent = hdr
    local track = fr(c, UDim2.new(1,0,0,2), UDim2.new(0,0,0,sc(28)), T.borderGhost); corner(track, 1)
    local p0 = (default-min)/(max-min)
    local fill = fr(track, UDim2.new(p0,0,1,0), nil, T.text); corner(fill, 1)
    local th = fr(track, UDim2.new(0,sc(14),0,sc(14)), UDim2.new(p0,0,0.5,0), T.text)
    th.AnchorPoint = Vector2.new(0.5,0.5); th.ZIndex = 3; corner(th, sc(7)); stroke(th, T.bg, 2)
    local dragging = false; local currentVal = default
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1,0,0,IS_MOBILE and sc(32) or sc(20)); hit.Position = UDim2.new(0,0,0,sc(16))
    hit.BackgroundTransparency = 1; hit.Text = ""; hit.ZIndex = 5; hit.Parent = c
    local function upd(x)
        local sz = track.AbsoluteSize.X; if sz == 0 then return end
        local pct = math.clamp((x-track.AbsolutePosition.X)/sz, 0, 1)
        local v = math.floor(min + pct*(max-min))
        currentVal = v; vl.Text = tostring(v)
        tw(fill, {Size=UDim2.new(pct,0,1,0)}, 0.05); tw(th, {Position=UDim2.new(pct,0,0.5,0)}, 0.05)
        if cb then cb(v) end
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true; upd(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            upd(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=false end
    end)
    return c, function() return currentVal end
end

local function mkButton(p, name, order, cb)
    local row = fr(p, UDim2.new(1,0,0,sc(30)), nil, nil, 1); row.LayoutOrder = order or 0
    local ml = Instance.new("TextLabel"); ml.Text = name; ml.TextSize = sc(12); ml.Font = UI; ml.TextColor3 = T.text
    ml.BackgroundTransparency = 1; ml.Size = UDim2.new(1,-sc(80),1,0)
    ml.TextXAlignment = Enum.TextXAlignment.Left; ml.TextYAlignment = Enum.TextYAlignment.Center; ml.Parent = row
    pad(ml, 0, 0, 0, 0)
    local btnFrame = fr(row, UDim2.new(0,sc(64),0,sc(22)), UDim2.new(1,-sc(64),0.5,-sc(11)), T.surfaceRaise)
    corner(btnFrame, 4); stroke(btnFrame, T.borderDim, 1)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1
    btn.Text = "RUN"; btn.TextSize = sc(10); btn.Font = MONO; btn.TextColor3 = T.textMuted; btn.Parent = btnFrame
    btn.MouseEnter:Connect(function() tw(btn, {TextColor3=T.text}, 0.1) end)
    btn.MouseLeave:Connect(function() tw(btn, {TextColor3=T.textMuted}, 0.1) end)
    btn.MouseButton1Click:Connect(function() if cb then cb() end end)
    return row
end

local function mkKeybind(p, name, keys, order)
    local row = fr(p, UDim2.new(1,0,0,sc(26)), nil, nil, 1); row.LayoutOrder = order or 0
    local nl = Instance.new("TextLabel"); nl.Text = name; nl.TextSize = sc(12); nl.Font = UI; nl.TextColor3 = T.text
    nl.BackgroundTransparency = 1; nl.Size = UDim2.new(0.5,0,1,0)
    nl.TextXAlignment = Enum.TextXAlignment.Left; nl.TextYAlignment = Enum.TextYAlignment.Center; nl.Parent = row
    local kr = fr(row, UDim2.new(0.5,0,1,0), UDim2.new(0.5,0,0,0), nil, 1)
    local kl = hlist(kr, 3); kl.HorizontalAlignment = Enum.HorizontalAlignment.Right; kl.VerticalAlignment = Enum.VerticalAlignment.Center
    for i, k in ipairs(keys) do
        local pill = fr(kr, UDim2.new(0,0,0,sc(20)), nil, T.surfaceRaise)
        pill.AutomaticSize = Enum.AutomaticSize.X; pill.LayoutOrder = i*2-1; corner(pill,3); stroke(pill,T.borderDim,1)
        local kt = Instance.new("TextLabel"); kt.Text = k; kt.TextSize = sc(9); kt.Font = MONO; kt.TextColor3 = T.textMuted
        kt.BackgroundTransparency = 1; kt.Size = UDim2.new(0,0,1,0); kt.AutomaticSize = Enum.AutomaticSize.X
        kt.TextXAlignment = Enum.TextXAlignment.Center; kt.Parent = pill; pad(kt,0,6,0,6)
        if i < #keys then
            local sep = Instance.new("TextLabel"); sep.Text = "+"; sep.TextSize = sc(9); sep.Font = MONO; sep.TextColor3 = T.textDim
            sep.BackgroundTransparency = 1; sep.Size = UDim2.new(0,sc(8),0,sc(20)); sep.LayoutOrder = i*2
            sep.TextXAlignment = Enum.TextXAlignment.Center; sep.TextYAlignment = Enum.TextYAlignment.Center; sep.Parent = kr
        end
    end
end

local function detectExecutor()
    if syn then return "Synapse X" end
    if KRNL_LOADED then return "KRNL" end
    if rconsole_clear then return "Script-Ware" end
    if fluxus then return "Fluxus" end
    if typeof(identifyexecutor) == "function" then local ok,n=pcall(identifyexecutor); if ok and n then return tostring(n) end end
    if typeof(getexecutorname) == "function"  then local ok,n=pcall(getexecutorname);  if ok and n then return tostring(n) end end
    if DELTA_KEY then return "Delta" end
    if getgenv and getgenv().madium then return "Madium" end
    if getgenv then local ok,n=pcall(function() return getgenv().__EXECUTOR__ or getgenv().EXECUTOR_NAME end); if ok and n then return tostring(n) end end
    return "Unknown"
end
local function detectHWID()
    local ok,id=pcall(function()
        if typeof(get_hwid)=="function" then return get_hwid() end
        if typeof(gethwid)=="function"  then return gethwid()  end
        if getgenv and getgenv().HWID   then return getgenv().HWID end
    end)
    if ok and id then local s=tostring(id); return #s>14 and s:sub(1,8).."···"..s:sub(-4) or s end
    return "Unavailable"
end
local function getPlatform()
    if IS_MOBILE then return "Mobile" end
    if UserInputService.GamepadEnabled then return "Console" end
    return "Desktop"
end
local SYS = {
    executor = detectExecutor(),
    hwid     = detectHWID(),
    premium  = (getgenv and getgenv().LITHIUM_PREMIUM) and true or false,
    platform = getPlatform(),
}

local function mkPlayerRow(p, username, dist, order)
    local row = fr(p, UDim2.new(1,0,0,sc(28)), nil, nil, 1); row.LayoutOrder = order or 0
    local hover = fr(row, UDim2.new(1,0,1,0), nil, T.surfaceHover, 1); corner(hover, 4)
    local btn = Instance.new("TextButton"); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""; btn.Parent=row
    btn.MouseEnter:Connect(function() tw(hover,{BackgroundTransparency=0},0.1) end)
    btn.MouseLeave:Connect(function() tw(hover,{BackgroundTransparency=1},0.1) end)
    local nl=Instance.new("TextLabel"); nl.Text=username; nl.TextSize=sc(12); nl.Font=UI; nl.TextColor3=T.text
    nl.BackgroundTransparency=1; nl.Size=UDim2.new(0.65,0,1,0); nl.Position=UDim2.new(0,sc(8),0,0)
    nl.TextXAlignment=Enum.TextXAlignment.Left; nl.TextYAlignment=Enum.TextYAlignment.Center; nl.ZIndex=2; nl.Parent=row
    local dl=Instance.new("TextLabel"); dl.Text=dist; dl.TextSize=sc(11); dl.Font=MONO; dl.TextColor3=T.textMuted
    dl.BackgroundTransparency=1; dl.Size=UDim2.new(0.35,-sc(8),1,0); dl.Position=UDim2.new(0.65,0,0,0)
    dl.TextXAlignment=Enum.TextXAlignment.Right; dl.TextYAlignment=Enum.TextYAlignment.Center; dl.ZIndex=2; dl.Parent=row
end

local WIN_W = 860
local WIN_H = 520
local NAV_H = sc(IS_MOBILE and 42 or 44)

local gui = Instance.new("ScreenGui")
gui.Name="Nitremia_MM2"; gui.ResetOnSpawn=false; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.DisplayOrder=999; gui.IgnoreGuiInset=true; gui.Parent=CoreGui

initToast(gui)

local win
if IS_MOBILE then
    local vp=getViewport(); local mW=math.min(vp.X-24,860); local mH=math.min(vp.Y-32,620)
    win=fr(gui,UDim2.new(0,mW,0,mH),UDim2.new(0.5,-mW/2,0.5,-mH/2),T.bg)
else
    win=fr(gui,UDim2.new(0,WIN_W,0,WIN_H),UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),T.bg)
end
corner(win,8); stroke(win,T.borderDim,1); win.ClipsDescendants=true

local PILL_W=sc(IS_MOBILE and 70 or 62); local PILL_H=sc(28)
local pill=fr(gui,UDim2.new(0,PILL_W,0,PILL_H),
    IS_MOBILE and UDim2.new(1,-PILL_W-12,1,-PILL_H-60) or UDim2.new(0,12,0.5,-PILL_H/2),T.surface)
pill.ZIndex=200; corner(pill,PILL_H/2); stroke(pill,T.borderDim,1)
local pillRow=fr(pill,UDim2.new(1,0,1,0),nil,nil,1); hlist(pillRow,sc(5))
local prl=pillRow:FindFirstChildOfClass("UIListLayout")
prl.HorizontalAlignment=Enum.HorizontalAlignment.Center; prl.VerticalAlignment=Enum.VerticalAlignment.Center
local pillDot=fr(pillRow,UDim2.new(0,sc(6),0,sc(6)),nil,T.success)
pillDot.LayoutOrder=1; corner(pillDot,sc(3)); pillDot.AnchorPoint=Vector2.new(0,0.5)
local pillLbl=Instance.new("TextLabel"); pillLbl.Text="Ni"; pillLbl.TextSize=sc(11); pillLbl.Font=MONO
pillLbl.TextColor3=T.text; pillLbl.BackgroundTransparency=1; pillLbl.Size=UDim2.new(0,sc(20),1,0)
pillLbl.TextXAlignment=Enum.TextXAlignment.Center; pillLbl.TextYAlignment=Enum.TextYAlignment.Center
pillLbl.LayoutOrder=2; pillLbl.Parent=pillRow
local pillDrag,pillDs,pillSp=false,nil,nil
pill.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        pillDrag=true; pillDs=i.Position; pillSp=pill.Position end end)
UserInputService.InputChanged:Connect(function(i)
    if not pillDrag then return end
    if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
        local d=i.Position-pillDs; pill.Position=UDim2.new(pillSp.X.Scale,pillSp.X.Offset+d.X,pillSp.Y.Scale,pillSp.Y.Offset+d.Y) end end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then pillDrag=false end end)
local uiOpen=true
local pillBtn=Instance.new("TextButton")
pillBtn.Size=UDim2.new(1,0,1,0); pillBtn.BackgroundTransparency=1; pillBtn.Text=""
pillBtn.ZIndex=201; pillBtn.Parent=pill
pillBtn.MouseButton1Click:Connect(function()
    if pillDrag then return end
    uiOpen=not uiOpen
    if uiOpen then win.Visible=true; tw(win,{BackgroundTransparency=0},0.18); tw(pillDot,{BackgroundColor3=T.success},0.15)
    else tw(win,{BackgroundTransparency=1},0.18); task.delay(0.2,function() if not uiOpen then win.Visible=false end end); tw(pillDot,{BackgroundColor3=T.textDim},0.15) end
end)
if not IS_MOBILE then
    UserInputService.InputBegan:Connect(function(i,p) if not p and i.KeyCode==Enum.KeyCode.Insert then pillBtn.MouseButton1Click:Fire() end end)
end

local nav=fr(win,UDim2.new(1,0,0,NAV_H),nil,T.surface); nav.ZIndex=10
fr(nav,UDim2.new(1,0,0,1),UDim2.new(0,0,1,-1),T.borderGhost)
local logoBox=fr(nav,UDim2.new(0,sc(22),0,sc(22)),UDim2.new(0,sc(14),0.5,-sc(11)),T.bg)
corner(logoBox,4); stroke(logoBox,T.border,1)
local lt=Instance.new("TextLabel"); lt.Text="Ni"; lt.TextSize=sc(9); lt.Font=MONO; lt.TextColor3=T.text
lt.BackgroundTransparency=1; lt.Size=UDim2.new(1,0,1,0); lt.TextXAlignment=Enum.TextXAlignment.Center; lt.TextYAlignment=Enum.TextYAlignment.Center; lt.Parent=logoBox
local brandLbl=Instance.new("TextLabel"); brandLbl.Text="NITREMIA"; brandLbl.TextSize=sc(11); brandLbl.Font=MONO
brandLbl.TextColor3=T.text; brandLbl.BackgroundTransparency=1; brandLbl.Size=UDim2.new(0,sc(80),1,0)
brandLbl.Position=UDim2.new(0,sc(42),0,0); brandLbl.TextXAlignment=Enum.TextXAlignment.Left
brandLbl.TextYAlignment=Enum.TextYAlignment.Center; brandLbl.Parent=nav
if IS_MOBILE then
    local mob=fr(nav,UDim2.new(0,0,0,sc(18)),UDim2.new(0,sc(130),0.5,-sc(9)),T.surfaceRaise)
    mob.AutomaticSize=Enum.AutomaticSize.X; corner(mob,3); stroke(mob,T.borderGhost,1)
    local ml=Instance.new("TextLabel"); ml.Text="MOBILE"; ml.TextSize=sc(8); ml.Font=MONO; ml.TextColor3=T.textMuted
    ml.BackgroundTransparency=1; ml.Size=UDim2.new(0,0,1,0); ml.AutomaticSize=Enum.AutomaticSize.X
    ml.TextXAlignment=Enum.TextXAlignment.Center; ml.TextYAlignment=Enum.TextYAlignment.Center; ml.Parent=mob; pad(ml,0,8,0,8)
end
local navTabsX=IS_MOBILE and sc(118) or sc(140)
local navTabs
if IS_MOBILE then
    navTabs=Instance.new("ScrollingFrame"); navTabs.Size=UDim2.new(1,-(navTabsX+sc(46)),1,0)
    navTabs.Position=UDim2.new(0,navTabsX,0,0); navTabs.BackgroundTransparency=1; navTabs.BorderSizePixel=0
    navTabs.ScrollBarThickness=0; navTabs.ScrollingDirection=Enum.ScrollingDirection.X
    navTabs.AutomaticCanvasSize=Enum.AutomaticSize.X; navTabs.CanvasSize=UDim2.new(0,0,0,0); navTabs.Parent=nav
else
    navTabs=fr(nav,UDim2.new(1,-(navTabsX+sc(60)),1,0),UDim2.new(0,navTabsX,0,0),nil,1)
end
hlist(navTabs,2)
local closeBtn=Instance.new("TextButton")
closeBtn.Size=UDim2.new(0,sc(IS_MOBILE and 24 or 26),0,sc(IS_MOBILE and 24 or 26))
closeBtn.Position=UDim2.new(1,-sc(IS_MOBILE and 32 or 36),0.5,-sc(IS_MOBILE and 12 or 13))
closeBtn.BackgroundColor3=T.surface; closeBtn.BorderSizePixel=0; closeBtn.Text="✕"; closeBtn.TextSize=sc(11)
closeBtn.TextColor3=T.textMuted; closeBtn.Font=MONO; closeBtn.ZIndex=20; closeBtn.Parent=nav
corner(closeBtn,4); stroke(closeBtn,T.borderDim,1)
closeBtn.MouseEnter:Connect(function() tw(closeBtn,{TextColor3=T.danger},0.1) end)
closeBtn.MouseLeave:Connect(function() tw(closeBtn,{TextColor3=T.textMuted},0.1) end)
closeBtn.MouseButton1Click:Connect(function() uiOpen=false; win.Visible=false; tw(pillDot,{BackgroundColor3=T.textDim},0.15) end)
makeDraggable(win,nav)

local pages={}; local activePage=nil; local pageCount=0
local function showPage(id)
    for pid,pg in pairs(pages) do
        pg.frame.Visible=(pid==id)
        if pg.navBtn then
            tw(pg.navBtn,{TextColor3=(pid==id) and T.text or T.textMuted},0.12)
            if pg.pill then tw(pg.pill,{BackgroundTransparency=(pid==id) and 0 or 1},0.12) end
        end
    end; activePage=id
end
local function addPage(id,labelTxt)
    pageCount=pageCount+1; local isFirst=(pageCount==1)
    local btnWrap=fr(navTabs,UDim2.new(0,0,1,-sc(10)),nil,nil,1)
    btnWrap.AutomaticSize=Enum.AutomaticSize.X; btnWrap.LayoutOrder=pageCount
    local navPill=fr(btnWrap,UDim2.new(1,0,1,0),nil,T.surfaceRaise,isFirst and 0 or 1)
    corner(navPill,5); stroke(navPill,isFirst and T.borderDim or T.borderGhost,1)
    local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1
    btn.Text=labelTxt; btn.TextSize=sc(12); btn.Font=isFirst and BOLD or UI
    btn.TextColor3=isFirst and T.text or T.textMuted; btn.AutomaticSize=Enum.AutomaticSize.X; btn.Parent=btnWrap
    pad(btn,0,sc(14),0,sc(14))
    local pg=fr(win,UDim2.new(1,0,1,-NAV_H),UDim2.new(0,0,0,NAV_H),nil,1)
    pg.Visible=isFirst; pg.ClipsDescendants=true
    pages[id]={frame=pg,navBtn=btn,pill=navPill}
    btn.MouseButton1Click:Connect(function()
        for pid2,pg2 in pairs(pages) do if pg2.navBtn then pg2.navBtn.Font=(pid2==id) and BOLD or UI end end
        showPage(id) end)
    btn.MouseEnter:Connect(function() if activePage~=id then tw(btn,{TextColor3=Color3.fromRGB(180,180,180)},0.1) end end)
    btn.MouseLeave:Connect(function() if activePage~=id then tw(btn,{TextColor3=T.textMuted},0.1) end end)
    if isFirst then activePage=id end; return pg
end

local function mkPageBody(page)
    local scroll=mkScroll(page,UDim2.new(1,-sc(IS_MOBILE and 24 or 48),1,0),UDim2.new(0,sc(IS_MOBILE and 12 or 24),0,0))
    local inner=fr(scroll,UDim2.new(1,0,0,0),nil,nil,1)
    inner.AutomaticSize=Enum.AutomaticSize.Y; vlist(inner,sc(8)); pad(inner,sc(16),0,sc(16),0)
    return inner
end

-- ── STATE ────────────────────────────────────────────────────
local S = {
    roleEsp=false, sheriffChams=false, trapEsp=false, coinTracker=false,
    silentAimGun=false, silentAimKnife=false,
    hitboxExtender=false, hitboxSize=4,
    noclip=false,
    speedHack=false, walkSpeed=16,
    coinVacuum=false,
    proxAlarm=false, proxDist=15,
    autoParry=false,
    clickTeleport=false,
    ghostChar=false,
    weaponHider=false,
    scaleTweaker=false, playerScale=1.0,
    fullbright=false, noFog=false, noShadows=false,
    customFov=false, fovValue=70,
    customCrosshair=false,
    fpsUnlock=false,
    antiAfk=false,
    serverHopDead=false,
    killNotifs=true,
    toastEnabled=true,
    autoGG=false,
}

-- ── MM2 HELPERS ───────────────────────────────────────────────
local ROLE_COLORS = { Murderer=T.murderer, Sheriff=T.sheriff, Innocent=T.innocent }

local function getPlayerRole(player)
    local char = player.Character; if not char then return "Innocent" end
    -- Check backpack too — role tools can sit there between rounds
    local function hasTool(name)
        return char:FindFirstChild(name) or (player.Backpack and player.Backpack:FindFirstChild(name))
    end
    if hasTool("Knife") then return "Murderer" end
    if hasTool("Gun")   then return "Sheriff"  end
    return "Innocent"
end

local function getLocalRoot()
    local c=LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart")
end
local function getLocalHum()
    local c=LocalPlayer.Character; return c and c:FindFirstChildOfClass("Humanoid")
end

local function getNearestTarget(fovRadius, skipSheriff)
    local best, bestDist = nil, fovRadius
    local centre = Camera.ViewportSize / 2
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local role = getPlayerRole(p)
            if not (skipSheriff and role == "Sheriff") then
                local char = p.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local sp, vis = Camera:WorldToViewportPoint(hrp.Position)
                    if vis then
                        local d = (Vector2.new(sp.X,sp.Y) - centre).Magnitude
                        if d < bestDist then bestDist=d; best=p end
                    end
                end
            end
        end
    end
    return best
end

-- ── ESP ───────────────────────────────────────────────────────
local espGui = Instance.new("ScreenGui")
espGui.Name="Nitremia_ESP"; espGui.ResetOnSpawn=false
espGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
espGui.DisplayOrder=998; espGui.IgnoreGuiInset=true; espGui.Parent=CoreGui

local espObjects    = {}  -- [Player] = { bb, lbl, box }
local charHookConns = {}  -- [Player] = { Connection, ... }

local function clearESP(player)
    local obj = espObjects[player]
    if obj then
        if obj.bb  and obj.bb.Parent  then obj.bb:Destroy()  end
        if obj.box and obj.box.Parent then obj.box:Destroy() end
        espObjects[player] = nil
    end
end

local function buildESP(player)
    clearESP(player)
    if player == LocalPlayer then return end
    if not S.roleEsp and not S.sheriffChams then return end

    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local role     = getPlayerRole(player)
    local wantLabel = S.roleEsp
    local wantBox   = S.sheriffChams and role == "Sheriff"
    if not wantLabel and not wantBox then return end

    local obj = {}; espObjects[player] = obj

    if wantLabel then
        local bb = Instance.new("BillboardGui")
        bb.Name="NitreMM2_ESP"; bb.Size=UDim2.new(0,130,0,36)
        bb.StudsOffset=Vector3.new(0,3.5,0); bb.AlwaysOnTop=true
        bb.Adornee=hrp; bb.Parent=espGui
        local lbl=Instance.new("TextLabel",bb)
        lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
        lbl.Font=BOLD; lbl.TextSize=14
        lbl.TextStrokeTransparency=0; lbl.TextStrokeColor3=Color3.new(0,0,0)
        lbl.Text=string.format("[%s] %s", role, player.Name)
        lbl.TextColor3=ROLE_COLORS[role] or T.text
        obj.bb=bb; obj.lbl=lbl
    end

    if wantBox then
        local box=Instance.new("SelectionBox")
        box.Adornee=hrp; box.Color3=T.sheriff; box.LineThickness=0.05
        box.SurfaceColor3=T.sheriff; box.SurfaceTransparency=0.6
        box.Parent=espGui; obj.box=box
    end
end

local function refreshESP(player)
    local obj = espObjects[player]
    if not obj then buildESP(player); return end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local role = getPlayerRole(player)
    if obj.lbl then
        obj.lbl.Text = string.format("[%s] %s", role, player.Name)
        obj.lbl.TextColor3 = ROLE_COLORS[role] or T.text
        if obj.bb then obj.bb.Adornee = hrp end
    end
    if obj.box then
        obj.box.Adornee = (S.sheriffChams and role=="Sheriff") and hrp or nil
    end
end

local function hookPlayerESP(player)
    if player == LocalPlayer then return end
    if charHookConns[player] then
        for _, c in ipairs(charHookConns[player]) do c:Disconnect() end
    end
    charHookConns[player] = {}

    local function onChar(char)
        task.wait()  -- let tools replicate
        buildESP(player)
        local function onChange() refreshESP(player) end
        table.insert(charHookConns[player], char.ChildAdded:Connect(onChange))
        table.insert(charHookConns[player], char.ChildRemoved:Connect(onChange))
        -- also watch backpack
        local bp = player.Backpack
        if bp then
            table.insert(charHookConns[player], bp.ChildAdded:Connect(onChange))
            table.insert(charHookConns[player], bp.ChildRemoved:Connect(onChange))
        end
    end

    if player.Character then onChar(player.Character) end
    table.insert(charHookConns[player], player.CharacterAdded:Connect(onChar))
end

for _, p in ipairs(Players:GetPlayers()) do hookPlayerESP(p) end
Players.PlayerAdded:Connect(hookPlayerESP)
Players.PlayerRemoving:Connect(function(p)
    clearESP(p)
    if charHookConns[p] then
        for _, c in ipairs(charHookConns[p]) do c:Disconnect() end
        charHookConns[p] = nil
    end
end)

local trapBoxes = {}
local function updateTrapESP()
    for _, b in ipairs(trapBoxes) do if b.Parent then b:Destroy() end end; trapBoxes={}
    if not S.trapEsp then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("trap") or n:find("mine") or n:find("bear") then
                local b=Instance.new("SelectionBox")
                b.Adornee=obj; b.Color3=T.danger; b.LineThickness=0.05
                b.SurfaceColor3=T.danger; b.SurfaceTransparency=0.7; b.Parent=espGui
                table.insert(trapBoxes,b)
            end
        end
    end
end

-- ── SILENT AIM ────────────────────────────────────────────────
-- Hooks __namecall once. Intercepts FireServer calls and replaces the
-- position argument with the nearest target's HRP position.
-- Works for both gun (Sheriff) and knife throw (Murderer) since MM2
-- passes a Vector3 target position as the first argument in both cases.
local saHooked = false
local function connectSilentAim()
    if saHooked then return end
    saHooked = true
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" then
            local args = {...}
            -- Only redirect when the first arg is a Vector3 (position-based fire call)
            if typeof(args[1]) == "Vector3" then
                local role = getPlayerRole(LocalPlayer)
                local shouldRedirect = (S.silentAimGun and role == "Sheriff")
                                    or (S.silentAimKnife and role == "Murderer")
                if shouldRedirect then
                    local target = getNearestTarget(300, false)
                    local hrp = target and target.Character
                               and target.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        args[1] = hrp.Position
                        return old(self, table.unpack(args))
                    end
                end
            end
        end
        return old(self, ...)
    end)
end

-- ── HITBOX EXTENDER ───────────────────────────────────────────
-- Expands HumanoidRootPart size client-side. Server doesn't replicate
-- this back so it only affects local hit detection (raycasts, etc.).
local hitboxConns = {}
local originalSizes = {} -- [hrp] = Vector3

local function applyHitboxExtender()
    for _, c in ipairs(hitboxConns) do c:Disconnect() end
    hitboxConns = {}

    -- Restore original sizes when disabled
    if not S.hitboxExtender then
        for hrp, size in pairs(originalSizes) do
            if hrp and hrp.Parent then hrp.Size = size end
        end
        originalSizes = {}
        return
    end

    local function extendHRP(hrp)
        if not hrp then return end
        if not originalSizes[hrp] then originalSizes[hrp] = hrp.Size end
        hrp.Size = Vector3.new(S.hitboxSize, S.hitboxSize, S.hitboxSize)
    end

    local function onChar(char)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        extendHRP(hrp)
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if p.Character then onChar(p.Character) end
            table.insert(hitboxConns, p.CharacterAdded:Connect(onChar))
        end
    end
    table.insert(hitboxConns, Players.PlayerAdded:Connect(function(p)
        if p == LocalPlayer then return end
        if p.Character then onChar(p.Character) end
        table.insert(hitboxConns, p.CharacterAdded:Connect(onChar))
    end))
end

-- ── NOCLIP ────────────────────────────────────────────────────
-- Runs every physics step. CanCollide=false must be reapplied each step
-- because the engine resets it. Only touches the local character.
RunService.Stepped:Connect(function()
    if not S.noclip then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)

-- ── SPEED ─────────────────────────────────────────────────────
local function applySpeed()
    local hum = getLocalHum()
    if not hum then return end
    hum.WalkSpeed = S.speedHack and S.walkSpeed or 16
end

-- ── COIN VACUUM + TRACKER ─────────────────────────────────────
-- MM2 coins live under the active map folder. We search Workspace
-- descendants for BaseParts named "Coin" or "Coin1".
local coinBoxes = {}

local function findCoins()
    local out = {}
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("BasePart") and (o.Name == "Coin" or o.Name == "Coin1") and o.Parent then
            table.insert(out, o)
        end
    end
    return out
end

local function updateCoinTracker()
    for _, b in ipairs(coinBoxes) do
        if b.Parent then b:Destroy() end
    end
    coinBoxes = {}
    if not S.coinTracker then return end
    for _, coin in ipairs(findCoins()) do
        local b = Instance.new("SelectionBox")
        b.Adornee = coin; b.Color3 = T.warn; b.LineThickness = 0.04
        b.SurfaceColor3 = T.warn; b.SurfaceTransparency = 0.8; b.Parent = espGui
        table.insert(coinBoxes, b)
    end
end

-- Coin vacuum: teleports local character to the nearest coin every frame.
-- Throttled to avoid physics engine conflicts.
local lastVacuumTick = 0
RunService.Heartbeat:Connect(function()
    if not S.coinVacuum then return end
    local now = tick()
    if now - lastVacuumTick < 0.1 then return end
    lastVacuumTick = now
    local root = getLocalRoot()
    if not root then return end
    local coins = findCoins()
    if #coins == 0 then return end
    local nearest, nd = nil, math.huge
    for _, coin in ipairs(coins) do
        local d = (root.Position - coin.Position).Magnitude
        if d < nd then nd = d; nearest = coin end
    end
    if nearest and nearest.Parent then
        root.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 3, 0))
    end
end)

-- ── PROXIMITY ALARM ───────────────────────────────────────────
-- Persistent ScreenGui parented to CoreGui so it survives respawn.
-- Label visibility toggled each Heartbeat based on murderer distance.
local alarmGui = Instance.new("ScreenGui")
alarmGui.Name = "NitreMM2_Alarm"; alarmGui.ResetOnSpawn = false
alarmGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
alarmGui.DisplayOrder = 997; alarmGui.IgnoreGuiInset = true
alarmGui.Parent = CoreGui

local alarmLbl = Instance.new("TextLabel")
alarmLbl.Text = "⚠ MURDERER NEARBY"; alarmLbl.TextSize = sc(20); alarmLbl.Font = BOLD
alarmLbl.TextColor3 = T.danger; alarmLbl.BackgroundTransparency = 1
alarmLbl.Size = UDim2.new(1, 0, 0, sc(32)); alarmLbl.Position = UDim2.new(0, 0, 0, sc(60))
alarmLbl.TextXAlignment = Enum.TextXAlignment.Center; alarmLbl.Visible = false
alarmLbl.Parent = alarmGui

RunService.Heartbeat:Connect(function()
    if not S.proxAlarm then alarmLbl.Visible = false; return end
    local root = getLocalRoot()
    if not root then alarmLbl.Visible = false; return end
    local visible = false
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and getPlayerRole(p) == "Murderer" then
            local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (root.Position - hrp.Position).Magnitude <= S.proxDist then
                visible = true; break
            end
        end
    end
    alarmLbl.Visible = visible
end)

-- ── AUTO-PARRY ────────────────────────────────────────────────
-- Detects unanchored BaseParts named "Knife" with velocity heading toward
-- the local character and steps perpendicular to the incoming vector.
-- Runs on RenderStepped for lowest latency.
RunService.RenderStepped:Connect(function()
    if not S.autoParry then return end
    local root = getLocalRoot()
    if not root then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Knife" and not obj.Anchored then
            local vel = obj.Velocity
            if vel.Magnitude > 15 then
                local toUs = root.Position - obj.Position
                if toUs.Magnitude < 40 and toUs.Unit:Dot(vel.Unit) > 0.75 then
                    local perp = vel.Unit:Cross(Vector3.new(0, 1, 0)).Unit
                    root.CFrame = root.CFrame + perp * 6
                end
            end
        end
    end
end)

-- ── CLICK TELEPORT ────────────────────────────────────────────
local ctConn = nil
local function toggleClickTeleport(on)
    if ctConn then ctConn:Disconnect(); ctConn = nil end
    if not on then return end
    ctConn = UserInputService.InputBegan:Connect(function(i, processed)
        if processed then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            local root = getLocalRoot(); if not root then return end
            local ray = Camera:ScreenPointToRay(i.Position.X, i.Position.Y)
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = { LocalPlayer.Character }
            params.FilterType = Enum.RaycastFilterType.Exclude
            local res = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
            if res then root.CFrame = CFrame.new(res.Position + Vector3.new(0, 3, 0)) end
        end
    end)
end

-- ── GHOST CHAR ────────────────────────────────────────────────
local function applyGhostChar(on)
    local char = LocalPlayer.Character; if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = on and 0.75 or 0
        end
    end
end

-- ── WEAPON HIDER ─────────────────────────────────────────────
-- Hides all equipped tools from local view using LocalTransparencyModifier.
-- Server still sees the weapon; only local rendering is suppressed.
local function applyWeaponHider(on)
    local char = LocalPlayer.Character; if not char then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            for _, part in ipairs(tool:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("MeshPart") then
                    part.LocalTransparencyModifier = on and 1 or 0
                end
            end
        end
    end
end

-- ── SCALE ─────────────────────────────────────────────────────
local function applyScale(v)
    local char = LocalPlayer.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    pcall(function()
        local desc = hum:GetAppliedDescription()
        desc.HeadScale = v; desc.BodyHeightScale = v
        desc.BodyWidthScale = v; desc.BodyDepthScale = v
        hum:ApplyDescription(desc)
    end)
end

-- ── LIGHTING ─────────────────────────────────────────────────
local origFogEnd     = Lighting.FogEnd
local origBrightness = Lighting.Brightness
local origClockTime  = Lighting.ClockTime
local origShadows    = Lighting.GlobalShadows
local function applyLighting()
    Lighting.Brightness    = S.fullbright and 2 or origBrightness
    Lighting.ClockTime     = S.fullbright and 14 or origClockTime
    Lighting.FogEnd        = S.noFog      and 1e6 or origFogEnd
    Lighting.GlobalShadows = not S.noShadows
end

-- ── FOV ──────────────────────────────────────────────────────
local origFov = Camera.FieldOfView
local function applyFov()
    Camera.FieldOfView = S.customFov and S.fovValue or origFov
end

-- ── CROSSHAIR ────────────────────────────────────────────────
local crosshairGui = nil
local function setupCrosshair(on)
    if crosshairGui then crosshairGui:Destroy(); crosshairGui = nil end
    if not on then return end
    crosshairGui = Instance.new("ScreenGui"); crosshairGui.Name = "NitreMM2_Crosshair"
    crosshairGui.ResetOnSpawn = false; crosshairGui.IgnoreGuiInset = true
    crosshairGui.DisplayOrder = 996; crosshairGui.Parent = CoreGui
    local sz = sc(16)
    local h = fr(crosshairGui, UDim2.new(0,sz,0,1), UDim2.new(0.5,-sz/2,0.5,0), T.text); h.BackgroundTransparency=0.3
    local v = fr(crosshairGui, UDim2.new(0,1,0,sz), UDim2.new(0.5,0,0.5,-sz/2), T.text); v.BackgroundTransparency=0.3
end

-- ── FPS UNLOCK ───────────────────────────────────────────────
local function applyFpsUnlock(on)
    pcall(function()
        if typeof(setfpscap) == "function" then setfpscap(on and 0 or 60)
        elseif typeof(fps_unlock) == "function" then fps_unlock(on) end
    end)
end

-- ── ANTI-AFK ─────────────────────────────────────────────────
-- Uses VirtualUser to simulate input every 55 seconds, well under
-- the Roblox 20-minute idle threshold.
local antiAfkThread = nil
local function toggleAntiAfk(on)
    if antiAfkThread then task.cancel(antiAfkThread); antiAfkThread = nil end
    if not on then return end
    antiAfkThread = task.spawn(function()
        while S.antiAfk do
            task.wait(55)
            pcall(function()
                local vu = Instance.new("VirtualUser"); vu.Parent = game
                vu:CaptureController(); vu:ClickButton2(Vector2.new()); vu:Destroy()
            end)
        end
    end)
end

-- ── SERVER HOP ───────────────────────────────────────────────
local function hopServer(preferEmpty)
    local ok, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.UniverseId .. "/servers/Public?limit=100"
        return HttpService:JSONDecode(game:HttpGet(url)).data
    end)
    if not ok or not result then _toast("Server hop failed", "danger"); return end
    table.sort(result, function(a, b)
        return preferEmpty and a.playing < b.playing or a.playing > b.playing
    end)
    for _, s in ipairs(result) do
        if s.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
            return
        end
    end
    _toast("No suitable server found", "warn")
end

-- ── CONFIG ───────────────────────────────────────────────────
local function saveConfig()
    local ok, err = pcall(function()
        local data = {}; for k, v in pairs(S) do data[k] = v end
        writefile("NitreMM2_Config.json", HttpService:JSONEncode(data))
    end)
    if ok then _toast("Config saved", "success") else _toast("Save failed: " .. tostring(err), "danger") end
end

local function loadConfig()
    local ok, err = pcall(function()
        if not isfile("NitreMM2_Config.json") then _toast("No config found", "warn"); return end
        local data = HttpService:JSONDecode(readfile("NitreMM2_Config.json"))
        for k, v in pairs(data) do if S[k] ~= nil then S[k] = v end end
        _toast("Config loaded", "success")
    end)
    if not ok then _toast("Load failed: " .. tostring(err), "danger") end
end

-- ── KILL NOTIFICATIONS ───────────────────────────────────────
local function watchDeaths(player)
    local function onChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        hum.Died:Connect(function()
            if not S.killNotifs then return end
            _toast(player.Name .. " (" .. getPlayerRole(player) .. ") eliminated", "warn")
        end)
    end
    if player.Character then onChar(player.Character) end
    player.CharacterAdded:Connect(onChar)
end
for _, p in ipairs(Players:GetPlayers()) do watchDeaths(p) end
Players.PlayerAdded:Connect(watchDeaths)

-- ── HOME PAGE ────────────────────────────────────────────────
local homePage=addPage("home","Home")
local homeScroll=mkScroll(homePage,UDim2.new(1,0,1,0))
local homeInner=fr(homeScroll,UDim2.new(1,0,0,0),nil,nil,1)
homeInner.AutomaticSize=Enum.AutomaticSize.Y; vlist(homeInner,sc(IS_MOBILE and 10 or 14))
pad(homeInner,sc(IS_MOBILE and 14 or 22),sc(IS_MOBILE and 16 or 24),sc(IS_MOBILE and 14 or 22),sc(IS_MOBILE and 16 or 24))
local greetWrap=fr(homeInner,UDim2.new(1,0,0,0),nil,nil,1)
greetWrap.AutomaticSize=Enum.AutomaticSize.Y; greetWrap.LayoutOrder=1; vlist(greetWrap,3)
local hour=tonumber(os.date("%H")) or 12
local greetWord=hour<12 and "Good morning" or hour<18 and "Good afternoon" or "Good evening"
local gl=Instance.new("TextLabel"); gl.Text=greetWord..", "..(LocalPlayer.DisplayName or LocalPlayer.Name)
gl.TextSize=sc(22); gl.Font=BOLD; gl.TextColor3=T.text; gl.BackgroundTransparency=1
gl.Size=UDim2.new(1,0,0,sc(28)); gl.TextXAlignment=Enum.TextXAlignment.Left; gl.Parent=greetWrap
local saturatedLbl=Instance.new("TextLabel"); saturatedLbl.Text="Systems successfully saturated."
saturatedLbl.TextSize=sc(11); saturatedLbl.Font=UI; saturatedLbl.TextColor3=T.textMuted
saturatedLbl.BackgroundTransparency=1; saturatedLbl.Size=UDim2.new(1,0,0,sc(16))
saturatedLbl.TextXAlignment=Enum.TextXAlignment.Left; saturatedLbl.Visible=false; saturatedLbl.Parent=greetWrap

local function mkStatCard(p,topLbl,valTxt,subTxt,order,valCol)
    local card=fr(p,UDim2.new(IS_MOBILE and 0.5 or 0.25,-sc(IS_MOBILE and 6 or 9),1,0),nil,T.surface)
    card.LayoutOrder=order; corner(card,6); stroke(card,T.borderGhost,1); pad(card,sc(12),sc(14),sc(12),sc(14))
    local col=fr(card,UDim2.new(1,0,1,0),nil,nil,1); vlist(col,sc(4))
    local tl=Instance.new("TextLabel"); tl.Text=string.upper(topLbl); tl.TextSize=sc(9); tl.Font=MONO
    tl.TextColor3=T.textMuted; tl.BackgroundTransparency=1; tl.Size=UDim2.new(1,0,0,sc(12)); tl.TextXAlignment=Enum.TextXAlignment.Left; tl.Parent=col
    local vl=Instance.new("TextLabel"); vl.Text=tostring(valTxt); vl.TextSize=sc(18); vl.Font=BOLD
    vl.TextColor3=valCol or T.text; vl.BackgroundTransparency=1; vl.Size=UDim2.new(1,0,0,sc(24)); vl.TextXAlignment=Enum.TextXAlignment.Left; vl.Parent=col
    local sub=Instance.new("TextLabel"); sub.Text=tostring(subTxt or ""); sub.TextSize=sc(10); sub.Font=UI
    sub.TextColor3=T.textMuted; sub.BackgroundTransparency=1; sub.Size=UDim2.new(1,0,0,sc(14)); sub.TextXAlignment=Enum.TextXAlignment.Left; sub.Parent=col
    return card,vl,sub
end
local cardsRow1=fr(homeInner,UDim2.new(1,0,0,sc(IS_MOBILE and 72 or 84)),nil,nil,1)
cardsRow1.LayoutOrder=2; hlist(cardsRow1,sc(12))
local _,uptVal=mkStatCard(cardsRow1,"Uptime","00:00:00","Since attach",1)
mkStatCard(cardsRow1,"Connection","Active","Injected",2,T.success)
if IS_MOBILE then
    local cr2=fr(homeInner,UDim2.new(1,0,0,sc(72)),nil,nil,1); cr2.LayoutOrder=3; hlist(cr2,sc(12))
    mkStatCard(cr2,"Place ID",tostring(game.PlaceId),"MM2",1)
    local _,pv=mkStatCard(cr2,"Players",tostring(#Players:GetPlayers()),"In server",2)
    RunService.Heartbeat:Connect(function() if pv and pv.Parent then pv.Text=tostring(#Players:GetPlayers()) end end)
else
    mkStatCard(cardsRow1,"Place ID",tostring(game.PlaceId),"MM2",3)
    local _,pv=mkStatCard(cardsRow1,"Players",tostring(#Players:GetPlayers()),"In server",4)
    RunService.Heartbeat:Connect(function() if pv and pv.Parent then pv.Text=tostring(#Players:GetPlayers()) end end)
end
local startTime=tick()
RunService.Heartbeat:Connect(function()
    if uptVal and uptVal.Parent then
        local e=math.floor(tick()-startTime)
        uptVal.Text=string.format("%02d:%02d:%02d",math.floor(e/3600),math.floor((e%3600)/60),e%60)
    end
end)
local bottomRow=fr(homeInner,UDim2.new(1,0,0,0),nil,nil,1)
bottomRow.AutomaticSize=Enum.AutomaticSize.Y; bottomRow.LayoutOrder=IS_MOBILE and 4 or 3
if IS_MOBILE then vlist(bottomRow,sc(12)) else hlist(bottomRow,sc(12)); bottomRow.Size=UDim2.new(1,0,0,sc(200)) end
local sysW=IS_MOBILE and 0 or math.floor((860-sc(48))*0.56)
local sysCard=fr(bottomRow,IS_MOBILE and UDim2.new(1,0,0,0) or UDim2.new(0,sysW,1,0),nil,T.surface)
if IS_MOBILE then sysCard.AutomaticSize=Enum.AutomaticSize.Y end
sysCard.LayoutOrder=1; corner(sysCard,6); stroke(sysCard,T.borderGhost,1)
local sysHdr=fr(sysCard,UDim2.new(1,0,0,sc(36)),nil,nil,1); pad(sysHdr,0,sc(16),0,sc(16))
local shl=Instance.new("TextLabel"); shl.Text="SYSTEM INFO"; shl.TextSize=sc(9); shl.Font=MONO; shl.TextColor3=T.textMuted
shl.BackgroundTransparency=1; shl.Size=UDim2.new(1,0,1,0); shl.TextXAlignment=Enum.TextXAlignment.Left; shl.TextYAlignment=Enum.TextYAlignment.Center; shl.Parent=sysHdr
fr(sysCard,UDim2.new(1,0,0,1),UDim2.new(0,0,0,sc(36)),T.borderGhost)
local sysBody=fr(sysCard,UDim2.new(1,0,0,0),UDim2.new(0,0,0,sc(37)),nil,1)
sysBody.AutomaticSize=Enum.AutomaticSize.Y; vlist(sysBody,0); pad(sysBody,sc(10),sc(16),sc(10),sc(16))
local function sysRow(k,v,vc,order)
    local row=fr(sysBody,UDim2.new(1,0,0,sc(32)),nil,nil,1); row.LayoutOrder=order or 0
    if order and order>1 then fr(row,UDim2.new(1,0,0,1),UDim2.new(0,0,0,0),T.borderGhost).ZIndex=0 end
    local kl=Instance.new("TextLabel"); kl.Text=k; kl.TextSize=sc(10); kl.Font=UI; kl.TextColor3=T.textMuted
    kl.BackgroundTransparency=1; kl.Size=UDim2.new(0.4,0,1,0); kl.TextXAlignment=Enum.TextXAlignment.Left; kl.TextYAlignment=Enum.TextYAlignment.Center; kl.Parent=row
    local vl2=Instance.new("TextLabel"); vl2.Text=v; vl2.TextSize=sc(11); vl2.Font=MONO; vl2.TextColor3=vc or T.text
    vl2.BackgroundTransparency=1; vl2.Size=UDim2.new(0.6,0,1,0); vl2.Position=UDim2.new(0.4,0,0,0)
    vl2.TextXAlignment=Enum.TextXAlignment.Left; vl2.TextYAlignment=Enum.TextYAlignment.Center; vl2.Parent=row
end
sysRow("Executor",SYS.executor,T.text,1); sysRow("Platform",SYS.platform,T.text,2); sysRow("HWID",SYS.hwid,T.textMuted,3)
divLine(sysBody,4)
local premRow=fr(sysBody,UDim2.new(1,0,0,sc(36)),nil,nil,1); premRow.LayoutOrder=5
local premLbl=Instance.new("TextLabel"); premLbl.Text="Tier"; premLbl.TextSize=sc(10); premLbl.Font=UI; premLbl.TextColor3=T.textMuted
premLbl.BackgroundTransparency=1; premLbl.Size=UDim2.new(0.4,0,1,0); premLbl.TextXAlignment=Enum.TextXAlignment.Left; premLbl.TextYAlignment=Enum.TextYAlignment.Center; premLbl.Parent=premRow
local bc=SYS.premium and T.success or T.borderDim
local badge=fr(premRow,UDim2.new(0,0,0,sc(20)),UDim2.new(0.4,0,0.5,-sc(10)),T.surface)
badge.AutomaticSize=Enum.AutomaticSize.X; corner(badge,3); stroke(badge,bc,1)
local bl=Instance.new("TextLabel"); bl.Text=SYS.premium and "✦ PREMIUM" or "FREE"; bl.TextSize=sc(9); bl.Font=MONO; bl.TextColor3=bc
bl.BackgroundTransparency=1; bl.Size=UDim2.new(0,0,1,0); bl.AutomaticSize=Enum.AutomaticSize.X
bl.TextXAlignment=Enum.TextXAlignment.Center; bl.TextYAlignment=Enum.TextYAlignment.Center; bl.Parent=badge; pad(bl,0,sc(8),0,sc(8))
local nearbyW=IS_MOBILE and 0 or (860-sc(48)-sysW-sc(12))
local nearbyCard=fr(bottomRow,IS_MOBILE and UDim2.new(1,0,0,sc(170)) or UDim2.new(0,nearbyW,1,0),nil,T.surface)
nearbyCard.LayoutOrder=2; corner(nearbyCard,6); stroke(nearbyCard,T.borderGhost,1)
local nearbyHdr=fr(nearbyCard,UDim2.new(1,0,0,sc(36)),nil,nil,1); pad(nearbyHdr,0,sc(16),0,sc(16))
local nlbl2=Instance.new("TextLabel"); nlbl2.Text="NEARBY"; nlbl2.TextSize=sc(9); nlbl2.Font=MONO; nlbl2.TextColor3=T.textMuted
nlbl2.BackgroundTransparency=1; nlbl2.Size=UDim2.new(1,0,1,0); nlbl2.TextXAlignment=Enum.TextXAlignment.Left; nlbl2.TextYAlignment=Enum.TextYAlignment.Center; nlbl2.Parent=nearbyHdr
fr(nearbyCard,UDim2.new(1,0,0,1),UDim2.new(0,0,0,sc(36)),T.borderGhost)
local nearbyScroll=mkScroll(nearbyCard,UDim2.new(1,0,1,-sc(37)),UDim2.new(0,0,0,sc(37)))
local nearbyList=fr(nearbyScroll,UDim2.new(1,0,0,0),nil,nil,1)
nearbyList.AutomaticSize=Enum.AutomaticSize.Y; vlist(nearbyList,0); pad(nearbyList,sc(4),sc(12),sc(4),sc(12))
local function refreshNearby()
    for _,c in ipairs(nearbyList:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
    end
    local lc=LocalPlayer.Character; local lr=lc and lc:FindFirstChild("HumanoidRootPart"); local entries={}
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            local ch=p.Character; local rt=ch and ch:FindFirstChild("HumanoidRootPart")
            local d=(lr and rt) and math.floor((lr.Position-rt.Position).Magnitude) or 0
            table.insert(entries,{name=p.Name,dist=d,role=getPlayerRole(p)})
        end
    end
    table.sort(entries,function(a,b) return a.dist<b.dist end)
    for i,e in ipairs(entries) do
        mkPlayerRow(nearbyList,e.name.." ["..e.role.."]",e.dist.."m",i)
    end
    if #entries==0 then
        local el=Instance.new("TextLabel"); el.Text="No other players"; el.TextSize=sc(11); el.Font=UI; el.TextColor3=T.textDim
        el.BackgroundTransparency=1; el.Size=UDim2.new(1,0,0,sc(28)); el.TextXAlignment=Enum.TextXAlignment.Left; el.TextYAlignment=Enum.TextYAlignment.Center; el.Parent=nearbyList
    end
end
refreshNearby()
task.spawn(function() while gui.Parent do task.wait(3); refreshNearby() end end)

-- ── PLAYERS PAGE ─────────────────────────────────────────────
local playersPage=addPage("players","Players")
local plTitle=Instance.new("TextLabel"); plTitle.Text="Players in Server"; plTitle.TextSize=sc(15); plTitle.Font=BOLD
plTitle.TextColor3=T.text; plTitle.BackgroundTransparency=1
plTitle.Size=UDim2.new(1,-sc(IS_MOBILE and 24 or 48),0,sc(24)); plTitle.Position=UDim2.new(0,sc(IS_MOBILE and 12 or 24),0,sc(10))
plTitle.TextXAlignment=Enum.TextXAlignment.Left; plTitle.Parent=playersPage
local plScroll=mkScroll(playersPage,UDim2.new(1,-sc(IS_MOBILE and 24 or 48),1,-sc(IS_MOBILE and 42 or 44)),UDim2.new(0,sc(IS_MOBILE and 12 or 24),0,sc(IS_MOBILE and 42 or 44)))
local plList=fr(plScroll,UDim2.new(1,0,0,0),nil,nil,1); plList.AutomaticSize=Enum.AutomaticSize.Y; vlist(plList,sc(6))
local function refreshPlayerList()
    for _,c in ipairs(plList:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
    local lc=LocalPlayer.Character; local lr=lc and lc:FindFirstChild("HumanoidRootPart")
    for i,p in ipairs(Players:GetPlayers()) do
        local card=fr(plList,UDim2.new(1,0,0,sc(46)),nil,T.surface); card.LayoutOrder=i; corner(card,5); stroke(card,T.borderGhost,1); pad(card,0,sc(14),0,sc(14))
        local role=getPlayerRole(p); local roleCol=ROLE_COLORS[role] or T.textDim
        local dot=fr(card,UDim2.new(0,sc(6),0,sc(6)),UDim2.new(0,0,0.5,-sc(3)),p==LocalPlayer and T.success or roleCol); corner(dot,3)
        local nameCol=fr(card,UDim2.new(0,sc(200),1,0),UDim2.new(0,sc(14),0,0),nil,1); vlist(nameCol,2); pad(nameCol,sc(10),0,sc(10),0)
        local dn=Instance.new("TextLabel"); dn.Text=p.DisplayName; dn.TextSize=sc(12); dn.Font=BOLD; dn.TextColor3=T.text
        dn.BackgroundTransparency=1; dn.Size=UDim2.new(1,0,0,sc(15)); dn.TextXAlignment=Enum.TextXAlignment.Left; dn.Parent=nameCol
        local un=Instance.new("TextLabel"); un.Text="@"..p.Name.." · "..role; un.TextSize=sc(10); un.Font=UI; un.TextColor3=roleCol
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

-- ── COMBAT PAGE ───────────────────────────────────────────────
local combatPage=addPage("combat","Combat")
local combatInner=mkPageBody(combatPage)
secLabel(combatInner,"Sheriff",1)
mkToggle(combatInner,"Sheriff Chams & ESP",false,2,function(s) S.sheriffChams=s end)
mkToggle(combatInner,"Silent Aim — Gun",false,3,function(s) S.silentAimGun=s; if s then connectSilentAim() end end)
divLine(combatInner,4)
secLabel(combatInner,"Murderer",5)
mkToggle(combatInner,"Silent Aim — Knife",false,6,function(s) S.silentAimKnife=s; if s then connectSilentAim() end end)
mkToggle(combatInner,"Hitbox Extender",false,7,function(s) S.hitboxExtender=s; applyHitboxExtender() end)
mkSlider(combatInner,"Hitbox Size",1,10,4,8,function(v) S.hitboxSize=v; applyHitboxExtender() end)
divLine(combatInner,9)
secLabel(combatInner,"Defense",10)
mkToggle(combatInner,"Proximity Alarm",false,11,function(s) S.proxAlarm=s end)
mkSlider(combatInner,"Alarm Distance",5,50,15,12,function(v) S.proxDist=v end)
mkToggle(combatInner,"Auto-Parry",false,13,function(s) S.autoParry=s end)
divLine(combatInner,14)
secLabel(combatInner,"Parameters",15)
mkSlider(combatInner,"Aimbot FOV",10,300,200,16,function(v) S.aimbotFov=v end)

-- ── CHARACTER PAGE ────────────────────────────────────────────
local charPage=addPage("character","Character")
local charInner=mkPageBody(charPage)
secLabel(charInner,"Movement",1)
mkToggle(charInner,"Noclip",false,2,function(s) S.noclip=s end)
mkToggle(charInner,"Speed Hack",false,3,function(s) S.speedHack=s; applySpeed() end)
mkSlider(charInner,"Walk Speed",16,100,16,4,function(v) S.walkSpeed=v; applySpeed() end)
mkToggle(charInner,"Click-to-Teleport",false,5,function(s) S.clickTeleport=s; toggleClickTeleport(s) end)
mkButton(charInner,"Teleport to Murderer",6,function()
    local root=getLocalRoot(); if not root then return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and getPlayerRole(p)=="Murderer" then
            local hrp=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then root.CFrame=hrp.CFrame*CFrame.new(0,0,-4); return end
        end
    end
    _toast("No murderer found","warn")
end)
divLine(charInner,7)
secLabel(charInner,"Character",8)
mkToggle(charInner,"Ghost Mode",false,9,function(s) S.ghostChar=s; applyGhostChar(s) end)
mkToggle(charInner,"Weapon Hider",false,10,function(s) S.weaponHider=s; applyWeaponHider(s) end)
mkToggle(charInner,"Scale Tweaker",false,11,function(s) S.scaleTweaker=s; if not s then applyScale(1.0) end end)
mkSlider(charInner,"Player Scale",50,200,100,12,function(v) S.playerScale=v/100; if S.scaleTweaker then applyScale(S.playerScale) end end)
divLine(charInner,13)
secLabel(charInner,"Farming",14)
mkToggle(charInner,"Coin Vacuum",false,15,function(s) S.coinVacuum=s end)
mkToggle(charInner,"Anti-AFK",false,16,function(s) S.antiAfk=s; toggleAntiAfk(s) end)

-- ── VISUALS PAGE ──────────────────────────────────────────────
local visualsPage=addPage("visuals","Visuals")
local visInner=mkPageBody(visualsPage)
secLabel(visInner,"ESP",1)
mkToggle(visInner,"Role ESP",false,2,function(s)
    S.roleEsp=s
    if s then for _,p in ipairs(Players:GetPlayers()) do hookPlayerESP(p) end
    else for _,p in ipairs(Players:GetPlayers()) do clearESP(p) end end
end)
mkToggle(visInner,"Trap Detector",false,3,function(s) S.trapEsp=s end)
mkToggle(visInner,"Coin Tracker",false,4,function(s) S.coinTracker=s end)
divLine(visInner,5)
secLabel(visInner,"Camera",6)
mkToggle(visInner,"Custom FOV",false,7,function(s) S.customFov=s; applyFov() end)
mkSlider(visInner,"FOV Value",50,120,70,8,function(v) S.fovValue=v; applyFov() end)
mkToggle(visInner,"Custom Crosshair",false,9,function(s) S.customCrosshair=s; setupCrosshair(s) end)
divLine(visInner,10)
secLabel(visInner,"World",11)
mkToggle(visInner,"Fullbright",false,12,function(s) S.fullbright=s; applyLighting() end)
mkToggle(visInner,"No Fog",false,13,function(s) S.noFog=s; applyLighting() end)
mkToggle(visInner,"No Shadows",false,14,function(s) S.noShadows=s; applyLighting() end)

-- ── MISC PAGE ────────────────────────────────────────────────
local miscPage=addPage("misc","Misc")
local miscInner=mkPageBody(miscPage)
secLabel(miscInner,"Server",1)
mkButton(miscInner,"Server Hop — Low Pop",2,function() hopServer(true) end)
mkButton(miscInner,"Server Hop — High Pop",3,function() hopServer(false) end)
mkButton(miscInner,"Rejoin",4,function() TeleportService:Teleport(game.PlaceId,LocalPlayer) end)
divLine(miscInner,5)
secLabel(miscInner,"Audio",6)
mkToggle(miscInner,"Mute Radios",false,7,function(s)
    for _,o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("Sound") and o.Name:lower():find("radio") then o.Volume=s and 0 or 0.5 end
    end
end)
mkToggle(miscInner,"Amplify Footsteps",false,8,function(s)
    for _,o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("Sound") and o.Name:lower():find("foot") then o.Volume=s and 2 or 0.5 end
    end
end)
divLine(miscInner,9)
secLabel(miscInner,"Notifications",10)
mkToggle(miscInner,"Kill Notifications",true,11,function(s) S.killNotifs=s end)

-- ── SETTINGS PAGE ────────────────────────────────────────────
local settingsPage=addPage("settings","Settings")
local setInner=mkPageBody(settingsPage)
secLabel(setInner,"Interface",1)
mkToggle(setInner,"Toast Notifications",true,2,function(s) S.toastEnabled=s end)
mkToggle(setInner,"FPS Unlocker",false,3,function(s) S.fpsUnlock=s; applyFpsUnlock(s) end)
mkButton(setInner,"Memory Cleanup",4,function()
    pcall(function() if typeof(clearmemory)=="function" then clearmemory() end end)
    collectgarbage("collect"); _toast("Memory cleared","success")
end)
divLine(setInner,5)
secLabel(setInner,"Keybinds",6)
mkKeybind(setInner,"Toggle Menu",{"INSERT"},7)
mkKeybind(setInner,"Panic Close",{"LCTRL","ALT","END"},8)
divLine(setInner,9)
secLabel(setInner,"Configuration",10)
mkButton(setInner,"Save Config",11,saveConfig)
mkButton(setInner,"Load Config",12,loadConfig)
mkButton(setInner,"Reset to Default",13,function()
    S.roleEsp=false; S.sheriffChams=false; S.silentAimGun=false; S.silentAimKnife=false
    S.hitboxExtender=false; S.noclip=false; S.speedHack=false; S.coinVacuum=false
    S.proxAlarm=false; S.autoParry=false; S.ghostChar=false; S.weaponHider=false
    S.fullbright=false; S.noFog=false; S.noShadows=false; S.customFov=false; S.customCrosshair=false
    applyLighting(); applySpeed(); applyGhostChar(false); applyWeaponHider(false)
    Camera.FieldOfView=origFov; setupCrosshair(false)
    for _,p in ipairs(Players:GetPlayers()) do clearESP(p) end
    _toast("Settings reset","default")
end)
divLine(setInner,14)
secLabel(setInner,"About",15)
local aboutCard=fr(setInner,UDim2.new(1,0,0,0),nil,T.surface)
aboutCard.AutomaticSize=Enum.AutomaticSize.Y; aboutCard.LayoutOrder=16
corner(aboutCard,6); stroke(aboutCard,T.borderGhost,1); pad(aboutCard,sc(14),sc(16),sc(14),sc(16))
local aboutCol=fr(aboutCard,UDim2.new(1,0,0,0),nil,nil,1); aboutCol.AutomaticSize=Enum.AutomaticSize.Y; vlist(aboutCol,sc(6))
local function infoRow(p,k,v,order)
    local r=fr(p,UDim2.new(1,0,0,sc(18)),nil,nil,1); r.LayoutOrder=order or 0
    local kl=Instance.new("TextLabel"); kl.Text=k; kl.TextSize=sc(11); kl.Font=UI; kl.TextColor3=T.textMuted
    kl.BackgroundTransparency=1; kl.Size=UDim2.new(0.45,0,1,0); kl.TextXAlignment=Enum.TextXAlignment.Left; kl.Parent=r
    local vl2=Instance.new("TextLabel"); vl2.Text=v; vl2.TextSize=sc(11); vl2.Font=MONO; vl2.TextColor3=T.text
    vl2.BackgroundTransparency=1; vl2.Size=UDim2.new(0.55,0,1,0); vl2.Position=UDim2.new(0.45,0,0,0)
    vl2.TextXAlignment=Enum.TextXAlignment.Right; vl2.Parent=r
end
infoRow(aboutCol,"Script",  "Nitre MM2",        1)
infoRow(aboutCol,"Creator", "rightpapi",        2)
infoRow(aboutCol,"Hub",     "Nitremia.gg",      3)
infoRow(aboutCol,"Executor",SYS.executor,       4)
infoRow(aboutCol,"Platform",SYS.platform,       5)
infoRow(aboutCol,"Build",   os.date("%Y-%m-%d"),6)

-- ── MOBILE FIT ───────────────────────────────────────────────
if IS_MOBILE then
    local function fitMobileWindow()
        local vp=getViewport(); local mW=math.min(vp.X-24,860); local mH=math.min(vp.Y-32,620)
        win.Size=UDim2.new(0,mW,0,mH); win.Position=UDim2.new(0.5,-mW/2,0.5,-mH/2)
    end
    local cam=Workspace.CurrentCamera
    if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitMobileWindow) end
end

-- ── CHARACTER RESPAWN HOOKS ───────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function(char)
    task.delay(0.5,function()
        if S.speedHack   then applySpeed()               end
        if S.ghostChar   then applyGhostChar(true)       end
        if S.weaponHider then applyWeaponHider(true)     end
        if S.scaleTweaker then applyScale(S.playerScale) end
    end)
end)

-- ── PANIC KEYBIND ────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(i,processed)
    if processed then return end
    if i.KeyCode==Enum.KeyCode.End
    and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
    and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then
        gui:Destroy(); espGui:Destroy()
        if crosshairGui then crosshairGui:Destroy() end
    end
end)

-- ── MAIN LOOP ────────────────────────────────────────────────
task.spawn(function()
    while gui.Parent do
        task.wait(0.5)
        if S.roleEsp or S.sheriffChams then
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer then refreshESP(p) end
            end
        end
        updateTrapESP()
        updateCoinTracker()
    end
end)

-- ── INIT ─────────────────────────────────────────────────────
showPage("home")

local initErrors={}

local ok1,e1=pcall(connectSilentAim)
if not ok1 then table.insert(initErrors,"Silent aim: "..tostring(e1)) end

task.delay(0.9,function()
    if #initErrors==0 then
        saturatedLbl.Visible=true
        _toast("Systems successfully saturated.")
    else
        for _,e in ipairs(initErrors) do
            warn("[Nitre MM2] "..e)
            _toast("Init error: "..e,"danger")
        end
    end
end)
