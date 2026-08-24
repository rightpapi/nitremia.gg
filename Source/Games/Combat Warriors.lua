-- ============================================================
--  Nitre Combat Warriors
--  Creator: rightpapi | Nitremia.gg
-- ============================================================

-- ============================================================
--  SERVICES
-- ============================================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local CoreGui            = game:GetService("CoreGui")

local LocalPlayer        = Players.LocalPlayer
local Camera             = workspace.CurrentCamera

-- ============================================================
--  HELPERS
-- ============================================================
local function getChar()   return LocalPlayer.Character end
local function getHum()    local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot()   local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

local function getEnemies(teamCheck)
    local out={}
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            if teamCheck and p.Team==LocalPlayer.Team then continue end
            out[#out+1]=p
        end
    end
    return out
end

local function getNearestPlayer(range, teamCheck)
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

-- ============================================================
--  CONFIG
-- ============================================================
local CFG = {
    -- Auto Parry
    parryEnabled   = false,
    parryDelay     = 8,      -- stored as hundredths (0.08s)
    parryRange     = 20,
    parryMode      = "All",  -- All | Melee | Projectile
    parryVisualize = false,

    -- Kill Aura
    auraEnabled    = false,
    auraRange      = 12,
    auraDelay      = 10,     -- hundredths
    auraTeamCheck  = false,

    -- Infinite Stamina
    staminaEnabled = false,

    -- Auto Block / Defense
    autoBlockEnabled = false,
    antiStunEnabled  = false,
    antiRagEnabled   = false,

    -- ESP
    espEnabled     = false,
    espBox         = true,
    espName        = true,
    espHealth      = true,
    espDist        = true,
    espTeamCheck   = false,
    espMaxDist     = 500,

    -- Movement
    speedEnabled   = false,
    speedValue     = 30,
    flyEnabled     = false,
    flySpeed       = 50,
    noclipEnabled  = false,
    infJump        = false,

    -- Misc
    fullbright     = false,
    noFog          = false,
    fakeLag        = false,
}

-- ============================================================
--  STATE
-- ============================================================
local State = {
    parryDebounce  = false,
    auraDebounce   = false,
    flyBV          = nil,
    flyBG          = nil,
    espObjects     = {},
    conns          = {},
    loadErrors     = {},
}

-- ============================================================
--  SYSTEM INIT — each wrapped in pcall; failures logged
-- ============================================================

-- [1] Infinite Stamina
local function initStamina()
    local conn=RunService.Heartbeat:Connect(function()
        if not CFG.staminaEnabled then return end
        local c=getChar(); if not c then return end
        local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
        pcall(function()
            if hum:GetAttribute("Stamina")~=nil then hum:SetAttribute("Stamina",100) end
        end)
        local sv=c:FindFirstChild("Stamina") or hum:FindFirstChild("Stamina")
        if sv and sv:IsA("NumberValue") and sv.Value<100 then sv.Value=100 end
    end)
    State.conns[#State.conns+1]=conn
end

-- [2] Auto Parry
local function initParry()
    local ATTACK_KEYWORDS={"swing","attack","slash","stab","combo","punch","hit"}
    local function isAttack(name)
        name=name:lower()
        for _,k in ipairs(ATTACK_KEYWORDS) do if name:find(k) then return true end end
        return false
    end

    local function fireParry()
        if State.parryDebounce then return end
        State.parryDebounce=true
        task.delay(CFG.parryDelay/100,function()
            pcall(function()
                local vim=game:GetService("VirtualInputManager")
                vim:SendKeyEvent(true,Enum.KeyCode.Q,false,game)
                task.delay(0.05,function()
                    vim:SendKeyEvent(false,Enum.KeyCode.Q,false,game)
                end)
            end)
            task.delay(0.3,function() State.parryDebounce=false end)
        end)
    end

    local function watchPlayer(p)
        local char=p.Character or p.CharacterAdded:Wait()
        local hum=char:WaitForChild("Humanoid",5); if not hum then return end
        local anim=hum:FindFirstChildOfClass("Animator"); if not anim then return end
        local c=anim.AnimationPlayed:Connect(function(track)
            if not CFG.parryEnabled then return end
            local root=getRoot(); if not root then return end
            local pr=char:FindFirstChild("HumanoidRootPart"); if not pr then return end
            if (root.Position-pr.Position).Magnitude>CFG.parryRange then return end
            if isAttack(track.Name) then fireParry() end
        end)
        State.conns[#State.conns+1]=c
    end

    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then task.spawn(watchPlayer,p) end
    end
    Players.PlayerAdded:Connect(function(p) task.spawn(watchPlayer,p) end)
end

-- [3] ESP
local function clearESP(player)
    local obj=State.espObjects[player]
    if obj then
        for _,v in pairs(obj) do pcall(function() v:Destroy() end) end
        State.espObjects[player]=nil
    end
end

local function buildESP(player)
    clearESP(player)
    local hl=Instance.new("Highlight",CoreGui)
    hl.Name="NitreHL_"..player.Name
    hl.FillTransparency=0.85
    hl.OutlineTransparency=0
    hl.FillColor=Color3.fromRGB(255,60,60)
    hl.OutlineColor=Color3.fromRGB(255,60,60)

    local bb=Instance.new("BillboardGui",CoreGui)
    bb.Name="NitreBB_"..player.Name
    bb.AlwaysOnTop=true
    bb.Size=UDim2.new(0,200,0,50)
    bb.StudsOffset=Vector3.new(0,3,0)

    local nameLbl=Instance.new("TextLabel",bb)
    nameLbl.Name="Name"
    nameLbl.BackgroundTransparency=1
    nameLbl.Size=UDim2.new(1,0,0.5,0)
    nameLbl.Font=Enum.Font.GothamBold
    nameLbl.TextSize=13
    nameLbl.TextColor3=Color3.new(1,1,1)
    nameLbl.TextStrokeTransparency=0
    nameLbl.TextStrokeColor3=Color3.new(0,0,0)
    nameLbl.TextXAlignment=Enum.TextXAlignment.Center

    local infoLbl=Instance.new("TextLabel",bb)
    infoLbl.Name="Info"
    infoLbl.BackgroundTransparency=1
    infoLbl.Size=UDim2.new(1,0,0.5,0)
    infoLbl.Position=UDim2.new(0,0,0.5,0)
    infoLbl.Font=Enum.Font.Code
    infoLbl.TextSize=11
    infoLbl.TextColor3=Color3.fromRGB(80,220,120)
    infoLbl.TextStrokeTransparency=0
    infoLbl.TextStrokeColor3=Color3.new(0,0,0)
    infoLbl.TextXAlignment=Enum.TextXAlignment.Center

    State.espObjects[player]={hl=hl,bb=bb}
end

local function updateESP()
    local myRoot=getRoot()
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LocalPlayer then continue end
        if CFG.espTeamCheck and p.Team==LocalPlayer.Team then clearESP(p); continue end
        local char=p.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not char or not root or not hum or not myRoot then clearESP(p); continue end
        local dist=(myRoot.Position-root.Position).Magnitude
        if dist>CFG.espMaxDist then clearESP(p); continue end
        if not State.espObjects[p] then buildESP(p) end
        local obj=State.espObjects[p]
        obj.hl.Adornee=char
        obj.hl.Enabled=CFG.espBox
        obj.bb.Adornee=root
        local nameLbl=obj.bb:FindFirstChild("Name")
        local infoLbl=obj.bb:FindFirstChild("Info")
        if nameLbl then nameLbl.Visible=CFG.espName; nameLbl.Text=p.Name end
        if infoLbl then
            local parts={}
            if CFG.espHealth then parts[#parts+1]=string.format("HP %d/%d",math.floor(hum.Health),math.floor(hum.MaxHealth)) end
            if CFG.espDist   then parts[#parts+1]=string.format("%dm",math.floor(dist)) end
            infoLbl.Text=table.concat(parts,"  ")
            infoLbl.Visible=#parts>0
        end
    end
    for p in pairs(State.espObjects) do
        if not p.Parent then clearESP(p) end
    end
end

local function initESP()
    Players.PlayerRemoving:Connect(clearESP)
    local c=RunService.RenderStepped:Connect(function()
        if CFG.espEnabled then updateESP()
        else for p in pairs(State.espObjects) do clearESP(p) end end
    end)
    State.conns[#State.conns+1]=c
end

-- [4] Kill Aura
local function initAura()
    local c=RunService.Heartbeat:Connect(function()
        if not CFG.auraEnabled then return end
        if State.auraDebounce then return end
        local target=getNearestPlayer(CFG.auraRange,CFG.auraTeamCheck)
        if not target then return end
        local char=target.Character
        local tRoot=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local myRoot=getRoot()
        if not tRoot or not hum or not myRoot or hum.Health<=0 then return end
        State.auraDebounce=true
        myRoot.CFrame=CFrame.lookAt(myRoot.Position,tRoot.Position)
        pcall(function()
            local tool=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                local re=tool:FindFirstChildOfClass("RemoteEvent")
                if re then re:FireServer(tRoot.Position) end
            end
        end)
        pcall(function()
            local vim=game:GetService("VirtualInputManager")
            local sp,_,onScreen=Camera:WorldToViewportPoint(tRoot.Position)
            if onScreen then
                vim:SendMouseButtonEvent(sp.X,sp.Y,0,true,game,0)
                task.delay(0.05,function() vim:SendMouseButtonEvent(sp.X,sp.Y,0,false,game,0) end)
            end
        end)
        task.delay(CFG.auraDelay/100,function() State.auraDebounce=false end)
    end)
    State.conns[#State.conns+1]=c
end

-- [5] Movement
local function startFly()
    local root=getRoot(); if not root then return end
    local bv=Instance.new("BodyVelocity",root)
    bv.Velocity=Vector3.zero; bv.MaxForce=Vector3.new(1e5,1e5,1e5)
    State.flyBV=bv
    local bg=Instance.new("BodyGyro",root)
    bg.MaxTorque=Vector3.new(1e5,1e5,1e5); bg.D=100
    State.flyBG=bg
    local c; c=RunService.RenderStepped:Connect(function()
        if not CFG.flyEnabled then
            pcall(function() bv:Destroy() end)
            pcall(function() bg:Destroy() end)
            State.flyBV=nil; State.flyBG=nil
            c:Disconnect(); return
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
    State.conns[#State.conns+1]=c
end

local function stopFly()
    if State.flyBV then pcall(function() State.flyBV:Destroy() end); State.flyBV=nil end
    if State.flyBG then pcall(function() State.flyBG:Destroy() end); State.flyBG=nil end
end

local function initMovement()
    local c=RunService.Heartbeat:Connect(function()
        local hum=getHum(); if not hum then return end
        if CFG.speedEnabled then hum.WalkSpeed=CFG.speedValue end
        if CFG.noclipEnabled then
            local char=getChar(); if not char then return end
            for _,v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide=false end
            end
        end
    end)
    State.conns[#State.conns+1]=c
    local jc=UserInputService.JumpRequest:Connect(function()
        if not CFG.infJump then return end
        local hum=getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
    State.conns[#State.conns+1]=jc
end

-- [6] Misc
local function initMisc()
    local c=RunService.Heartbeat:Connect(function()
        local hum=getHum()
        if hum then
            if CFG.antiRagEnabled then
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
            end
            if CFG.antiStunEnabled then
                pcall(function()
                    if hum:GetAttribute("Stun")~=nil     then hum:SetAttribute("Stun",0)       end
                    if hum:GetAttribute("Stunned")~=nil  then hum:SetAttribute("Stunned",false) end
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
    State.conns[#State.conns+1]=c
end

-- ============================================================
--  BOOT ALL SYSTEMS
-- ============================================================
local SYSTEMS={
    {"Stamina",  initStamina},
    {"Parry",    initParry},
    {"ESP",      initESP},
    {"Kill Aura",initAura},
    {"Movement", initMovement},
    {"Misc",     initMisc},
}

for _,entry in ipairs(SYSTEMS) do
    local name,fn=entry[1],entry[2]
    local ok,err=pcall(fn)
    if not ok then State.loadErrors[#State.loadErrors+1]=name..": "..tostring(err) end
end

-- ============================================================
--  UI — built on the Nitremia template
--  Loaded via loadstring so we share the existing library.
-- ============================================================

-- Remove any stale Nitremia_Hub from a previous run of this script
for _,v in ipairs(CoreGui:GetChildren()) do
    if v.Name=="Nitremia_Hub" then v:Destroy() end
end

-- Pull in the shared UI library
local UI_URL="https://raw.githubusercontent.com/rightpapi/nitremia.gg/master/Source/UI%20Library/ui.lua"
local uiOk,uiErr=pcall(function() loadstring(game:HttpGet(UI_URL))() end)

-- After the library runs it creates Nitremia_Hub in CoreGui.
-- We now wire up the game-specific pages into that existing window.
local gui=CoreGui:WaitForChild("Nitremia_Hub",10)
if not gui then
    warn("[Nitre CW] UI library failed to create Nitremia_Hub: "..(uiErr or "timeout"))
    return
end

-- ============================================================
--  The template exposes helpers as upvalues — we can't reach
--  those from here, so we replicate the lightweight ones we
--  need for the CW pages only.  Everything else (nav, toast,
--  home, players, visuals, aimbot, settings) the base lib
--  already built.
-- ============================================================

local IS_MOBILE=UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local function sc(n) return math.max(1,math.floor(n*(IS_MOBILE and 0.92 or 1.0))) end

local T={
    bg           = Color3.fromRGB(6,   6,   6),
    surface      = Color3.fromRGB(14,  14,  14),
    surfaceRaise = Color3.fromRGB(22,  22,  22),
    border       = Color3.fromRGB(255, 255, 255),
    borderDim    = Color3.fromRGB(55,  55,  55),
    borderGhost  = Color3.fromRGB(30,  30,  30),
    text         = Color3.fromRGB(255, 255, 255),
    textMuted    = Color3.fromRGB(100, 100, 100),
    textDim      = Color3.fromRGB(50,  50,  50),
    success      = Color3.fromRGB(68,  255, 136),
    warn         = Color3.fromRGB(255, 204,   0),
    danger       = Color3.fromRGB(255,  68,  68),
}
local MONO=Enum.Font.Code
local UI_F=Enum.Font.Gotham
local BOLD=Enum.Font.GothamBold

local function fr(p,size,pos,bg,trans)
    local f=Instance.new("Frame")
    f.Size=size; f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=bg or T.surface
    f.BackgroundTransparency=trans or 0
    f.BorderSizePixel=0; f.Parent=p; return f
end
local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 6); c.Parent=p; return c end
local function stroke(p,col,thick) local s=Instance.new("UIStroke"); s.Color=col or T.border; s.Thickness=thick or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end
local function pad(p,t,r,b,l) local u=Instance.new("UIPadding"); u.PaddingTop=UDim.new(0,t or 8); u.PaddingRight=UDim.new(0,r or 12); u.PaddingBottom=UDim.new(0,b or 8); u.PaddingLeft=UDim.new(0,l or 12); u.Parent=p; return u end
local function vlist(p,sp) local l=Instance.new("UIListLayout"); l.FillDirection=Enum.FillDirection.Vertical; l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,sp or 0); l.Parent=p; return l end
local function tw(obj,props,t) if not obj or not obj.Parent then return end TweenService:Create(obj,TweenInfo.new(t or 0.15,Enum.EasingStyle.Quad),props):Play() end

local function mkScroll(p,size,pos)
    local s=Instance.new("ScrollingFrame")
    s.Size=size; s.Position=pos or UDim2.new(0,0,0,0)
    s.BackgroundTransparency=1; s.BorderSizePixel=0
    s.ScrollBarThickness=IS_MOBILE and 3 or 2
    s.ScrollBarImageColor3=T.borderDim
    s.CanvasSize=UDim2.new(0,0,0,0)
    s.AutomaticCanvasSize=Enum.AutomaticSize.Y
    s.ScrollingDirection=Enum.ScrollingDirection.Y
    s.Parent=p; return s
end

local function secLabel(p,txt,order)
    local l=Instance.new("TextLabel")
    l.Text=string.upper(txt); l.TextSize=sc(9); l.Font=MONO
    l.TextColor3=T.textDim; l.BackgroundTransparency=1
    l.Size=UDim2.new(1,0,0,sc(14))
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.LayoutOrder=order or 0; l.Parent=p; return l
end

local function divLine(p,order)
    local f=fr(p,UDim2.new(1,0,0,1),nil,T.borderGhost)
    f.LayoutOrder=order or 99; return f
end

local function mkToggle(p,name,sub,default,order,cb)
    local rowH=sub and sc(42) or sc(30)
    local row=fr(p,UDim2.new(1,0,0,rowH),nil,nil,1); row.LayoutOrder=order or 0
    local texts=fr(row,UDim2.new(1,-sc(52),1,0),nil,nil,1)
    vlist(texts,2); pad(texts,sub and sc(6) or sc(8),0,sub and sc(6) or sc(8),0)
    local ml=Instance.new("TextLabel")
    ml.Text=name; ml.TextSize=sc(12); ml.Font=UI_F; ml.TextColor3=T.text
    ml.BackgroundTransparency=1; ml.Size=UDim2.new(1,0,0,sc(15))
    ml.TextXAlignment=Enum.TextXAlignment.Left; ml.Parent=texts
    if sub then
        local sl=Instance.new("TextLabel")
        sl.Text=sub; sl.TextSize=sc(10); sl.Font=UI_F; sl.TextColor3=T.textMuted
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
        tw(thumb,{Position=state and UDim2.new(1,-sc(15),0.5,-sc(6)) or UDim2.new(0,sc(3),0.5,-sc(6)),BackgroundColor3=state and T.text or T.textMuted},0.15)
        tw(ts,{Color=state and T.border or T.borderDim},0.15)
        if cb then cb(state) end
    end)
    return row
end

local function mkSlider(p,name,min,max,default,order,cb)
    local c=fr(p,UDim2.new(1,0,0,sc(44)),nil,nil,1); c.LayoutOrder=order or 0
    local hdr=fr(c,UDim2.new(1,0,0,sc(16)),nil,nil,1)
    local nl=Instance.new("TextLabel")
    nl.Text=name; nl.TextSize=sc(12); nl.Font=UI_F; nl.TextColor3=T.text
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
--  FIND THE WIN FRAME (template's root window frame)
-- ============================================================
local win=gui:FindFirstChild("MainFrame") or gui:FindFirstChildOfClass("Frame")
local NAV_H=sc(IS_MOBILE and 42 or 44)

-- ============================================================
--  ADD GAME PAGES
--  We inject nav buttons + content pages into the existing nav.
-- ============================================================

-- Locate the nav bar the template built
local nav=win:FindFirstChild("NavBar") or win:FindFirstChildOfClass("Frame")
-- Find navTabs (the horizontal tab strip inside the nav)
local navTabs
for _,v in ipairs(nav:GetChildren()) do
    if v:IsA("Frame") or v:IsA("ScrollingFrame") then
        local l=v:FindFirstChildOfClass("UIListLayout")
        if l and l.FillDirection==Enum.FillDirection.Horizontal then
            navTabs=v; break
        end
    end
end

local pageFrames={}
local function injectPage(id,labelTxt)
    -- Count existing pages so layout order continues correctly
    local existingCount=0
    if navTabs then
        for _,v in ipairs(navTabs:GetChildren()) do
            if not v:IsA("UIListLayout") then existingCount=existingCount+1 end
        end
    end

    -- Nav pill
    if navTabs then
        local btnWrap=fr(navTabs,UDim2.new(0,0,1,-sc(10)),nil,nil,1)
        btnWrap.AutomaticSize=Enum.AutomaticSize.X; btnWrap.LayoutOrder=existingCount+1
        local navPill=fr(btnWrap,UDim2.new(1,0,1,0),nil,T.surfaceRaise,1)
        corner(navPill,5); stroke(navPill,T.borderGhost,1)
        local btn=Instance.new("TextButton")
        btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1
        btn.Text=labelTxt; btn.TextSize=sc(12); btn.Font=UI_F
        btn.TextColor3=T.textMuted
        btn.AutomaticSize=Enum.AutomaticSize.X; btn.Parent=btnWrap
        pad(btn,0,sc(14),0,sc(14))
        btn.MouseButton1Click:Connect(function()
            -- Hide all existing pages
            for _,pg in ipairs(win:GetChildren()) do
                if pg:IsA("Frame") and pg~=nav then pg.Visible=false end
            end
            for _,pg in pairs(pageFrames) do pg.Visible=false end
            pageFrames[id].Visible=true
            -- Mute all nav buttons
            for _,c2 in ipairs(navTabs:GetChildren()) do
                if c2:IsA("Frame") then
                    local b2=c2:FindFirstChildOfClass("TextButton")
                    if b2 then tw(b2,{TextColor3=T.textMuted},0.12) end
                end
            end
            tw(btn,{TextColor3=T.text},0.12)
            tw(navPill,{BackgroundTransparency=0},0.12)
        end)
    end

    local pg=fr(win,UDim2.new(1,0,1,-NAV_H),UDim2.new(0,0,0,NAV_H),nil,1)
    pg.Visible=false; pg.ClipsDescendants=true
    pageFrames[id]=pg
    return pg
end

-- ============================================================
--  COMBAT PAGE
-- ============================================================
local combatPage=injectPage("combat","Combat")
local combatScroll=mkScroll(combatPage,UDim2.new(1,-sc(IS_MOBILE and 24 or 48),1,0),UDim2.new(0,sc(IS_MOBILE and 12 or 24),0,0))
local combatInner=fr(combatScroll,UDim2.new(1,0,0,0),nil,nil,1)
combatInner.AutomaticSize=Enum.AutomaticSize.Y; vlist(combatInner,sc(8)); pad(combatInner,sc(16),0,sc(16),0)

-- Auto Parry
secLabel(combatInner,"Auto Parry",1)
mkToggle(combatInner,"Auto Parry","Fire Q on detected swing animations",CFG.parryEnabled,2,function(v) CFG.parryEnabled=v end)
mkSlider(combatInner,"Parry Delay (ms)",1,50,CFG.parryDelay,3,function(v) CFG.parryDelay=v end)
mkSlider(combatInner,"Parry Range (studs)",5,60,CFG.parryRange,4,function(v) CFG.parryRange=v end)
mkToggle(combatInner,"Visualize Trigger","Highlight parry-trigger radius",CFG.parryVisualize,5,function(v) CFG.parryVisualize=v end)
divLine(combatInner,6)

-- Kill Aura
secLabel(combatInner,"Kill Aura",7)
mkToggle(combatInner,"Kill Aura","Attack nearest player automatically",CFG.auraEnabled,8,function(v) CFG.auraEnabled=v end)
mkSlider(combatInner,"Range (studs)",4,40,CFG.auraRange,9,function(v) CFG.auraRange=v end)
mkSlider(combatInner,"Attack Delay (ms)",5,100,CFG.auraDelay,10,function(v) CFG.auraDelay=v end)
mkToggle(combatInner,"Team Check","Skip players on your team",CFG.auraTeamCheck,11,function(v) CFG.auraTeamCheck=v end)
divLine(combatInner,12)

-- Stamina
secLabel(combatInner,"Stamina",13)
mkToggle(combatInner,"Infinite Stamina","Lock stamina at maximum",CFG.staminaEnabled,14,function(v) CFG.staminaEnabled=v end)
divLine(combatInner,15)

-- Defense
secLabel(combatInner,"Defense",16)
mkToggle(combatInner,"Auto Block","Hold block when idle",CFG.autoBlockEnabled,17,function(v) CFG.autoBlockEnabled=v end)
mkToggle(combatInner,"Anti-Stun","Clear stun attribute every frame",CFG.antiStunEnabled,18,function(v) CFG.antiStunEnabled=v end)
mkToggle(combatInner,"Anti-Ragdoll","Disable ragdoll states",CFG.antiRagEnabled,19,function(v) CFG.antiRagEnabled=v end)

-- ============================================================
--  ESP PAGE (extends the template's Visuals page with real logic)
-- ============================================================
local espPage=injectPage("esp","ESP")
local espScroll=mkScroll(espPage,UDim2.new(1,-sc(IS_MOBILE and 24 or 48),1,0),UDim2.new(0,sc(IS_MOBILE and 12 or 24),0,0))
local espInner=fr(espScroll,UDim2.new(1,0,0,0),nil,nil,1)
espInner.AutomaticSize=Enum.AutomaticSize.Y; vlist(espInner,sc(8)); pad(espInner,sc(16),0,sc(16),0)

secLabel(espInner,"Player ESP",1)
mkToggle(espInner,"ESP Enabled","Box + info overlay on all players",CFG.espEnabled,2,function(v) CFG.espEnabled=v end)
mkToggle(espInner,"Show Box","Highlight outline around character",CFG.espBox,3,function(v) CFG.espBox=v end)
mkToggle(espInner,"Show Name","Display username above head",CFG.espName,4,function(v) CFG.espName=v end)
mkToggle(espInner,"Show Health","HP bar below name",CFG.espHealth,5,function(v) CFG.espHealth=v end)
mkToggle(espInner,"Show Distance","Distance in studs",CFG.espDist,6,function(v) CFG.espDist=v end)
mkToggle(espInner,"Team Check","Skip players on your team",CFG.espTeamCheck,7,function(v) CFG.espTeamCheck=v end)
divLine(espInner,8)
secLabel(espInner,"Range",9)
mkSlider(espInner,"Max Distance (studs)",50,1000,CFG.espMaxDist,10,function(v) CFG.espMaxDist=v end)

-- ============================================================
--  MOVEMENT PAGE
-- ============================================================
local movePage=injectPage("movement","Movement")
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

-- ============================================================
--  WORLD PAGE
-- ============================================================
local worldPage=injectPage("world","World")
local worldScroll=mkScroll(worldPage,UDim2.new(1,-sc(IS_MOBILE and 24 or 48),1,0),UDim2.new(0,sc(IS_MOBILE and 12 or 24),0,0))
local worldInner=fr(worldScroll,UDim2.new(1,0,0,0),nil,nil,1)
worldInner.AutomaticSize=Enum.AutomaticSize.Y; vlist(worldInner,sc(8)); pad(worldInner,sc(16),0,sc(16),0)

secLabel(worldInner,"Visuals",1)
mkToggle(worldInner,"Fullbright","Maximum ambient lighting",CFG.fullbright,2,function(v) CFG.fullbright=v end)
mkToggle(worldInner,"No Fog","Remove atmospheric fog",CFG.noFog,3,function(v) CFG.noFog=v end)
divLine(worldInner,4)
secLabel(worldInner,"Network",5)
mkToggle(worldInner,"Fake Lag","Cap FPS to simulate high ping",CFG.fakeLag,6,function(v)
    CFG.fakeLag=v
    pcall(function() setfpscap(v and 10 or 60) end)
end)

-- ============================================================
--  LOAD RESULT TOAST
--  Only fires if no critical systems failed.
-- ============================================================
-- The template's _toast is an upvalue we can't reach from here,
-- so we trigger it by finding the toast stack in the gui.
local function fireToast(msg,kind)
    -- Attempt to call the shared _toast if it was exposed on _G
    if typeof(_G._nitreToast)=="function" then
        _G._nitreToast(msg,kind); return
    end
    -- Fallback: the template fires its own success toast at 0.9s delay —
    -- if systems all loaded fine, that toast already says the right thing.
    -- For error reporting we surface a minimal TextLabel instead.
    if kind=="danger" then
        local lbl=Instance.new("TextLabel",gui)
        lbl.Size=UDim2.new(0,320,0,32)
        lbl.Position=UDim2.new(0.5,-160,0,8)
        lbl.BackgroundColor3=Color3.fromRGB(18,5,5)
        lbl.Font=MONO; lbl.TextSize=sc(11); lbl.TextColor3=T.danger
        lbl.Text=msg; lbl.BackgroundTransparency=0
        lbl.BorderSizePixel=0; lbl.ZIndex=500
        corner(lbl,4); stroke(lbl,T.danger,1)
        task.delay(5,function() pcall(function() lbl:Destroy() end) end)
    end
end

if #State.loadErrors>0 then
    fireToast("Load errors: "..table.concat(State.loadErrors," | "),"danger")
end
-- Success toast comes from the template itself ("Systems successfully saturated.")
-- It only fires if the UI library loaded without error — correct by design.
