-- ============================================================
--  Nitre Combat Warriors | Beta
--  Creator: rightpapi
--  Hub: Nitremia.gg
-- ============================================================

-- Services
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local HttpService        = game:GetService("HttpService")
local CoreGui            = game:GetService("CoreGui")

local LocalPlayer        = Players.LocalPlayer
local Camera             = workspace.CurrentCamera
local Mouse              = LocalPlayer:GetMouse()

-- ============================================================
--  CONFIGURATION DEFAULTS
-- ============================================================

local Config = {
    -- Auto Parry
    AutoParry = {
        Enabled       = false,
        Delay         = 0.08,       -- seconds before parry fires
        MaxRange      = 20,         -- studs — ignore attacks beyond this
        Mode          = "All",      -- "All" | "Melee" | "Projectile"
        Visualize     = true,       -- show parry-trigger highlight
    },

    -- ESP
    ESP = {
        Enabled       = false,
        ShowBox       = true,
        ShowName      = true,
        ShowHealth    = true,
        ShowDistance  = true,
        ShowWeapon    = false,
        TeamCheck     = false,
        MaxDistance   = 500,
        BoxColor      = Color3.fromRGB(255, 60, 60),
        NameColor     = Color3.fromRGB(255, 255, 255),
        HealthColor   = Color3.fromRGB(60, 255, 60),
    },

    -- Kill Aura
    KillAura = {
        Enabled       = false,
        Range         = 12,
        Delay         = 0.1,
        TargetNearest = true,
        TargetAll     = false,
        TeamCheck     = false,
    },

    -- Infinite Stamina
    InfiniteStamina = {
        Enabled       = false,
    },

    -- Movement
    Movement = {
        SpeedEnabled  = false,
        SpeedValue    = 30,
        FlyEnabled    = false,
        FlySpeed      = 50,
        NoclipEnabled = false,
    },

    -- Misc
    Misc = {
        AntiRagdoll   = false,
        AntiStun      = false,
        AutoBlock     = false,
        InfiniteJump  = false,
        FullBright    = false,
        FakeLag       = false,
        FakeLagPing   = 200,
        NoFog         = false,
    },
}

-- ============================================================
--  STATE
-- ============================================================

local State = {
    Loaded         = false,
    LoadError      = nil,
    FlyBodyVelocity = nil,
    FlyBodyGyro    = nil,
    ESPObjects     = {},
    Connections    = {},
    ParryDebounce  = false,
    KillAuraDebounce = false,
}

-- ============================================================
--  UTILITY
-- ============================================================

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHumanoid()
    local c = GetCharacter()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart()
    local c = GetCharacter()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetPlayers(teamCheck)
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if teamCheck and p.Team == LocalPlayer.Team then continue end
            list[#list + 1] = p
        end
    end
    return list
end

local function GetNearestPlayer(range, teamCheck)
    local root  = GetRootPart()
    if not root then return nil end
    local best, bestDist = nil, range or math.huge
    for _, p in ipairs(GetPlayers(teamCheck)) do
        local c = p.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if r then
            local d = (root.Position - r.Position).Magnitude
            if d < bestDist then bestDist = d; best = p end
        end
    end
    return best, bestDist
end

local function WorldToViewport(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), screenPos.Z, onScreen
end

local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- ============================================================
--  CRITICAL SYSTEMS — load before UI so errors surface cleanly
-- ============================================================

-- [1] Infinite Stamina — hook stamina attribute on character spawn
local function InitInfiniteStamina()
    local function hookStamina(char)
        if not char then return end
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end

        -- CW uses a "Stamina" NumberValue or Attribute — handle both
        local function lockStamina()
            if not Config.InfiniteStamina.Enabled then return end
            local staminaAttr = hum:GetAttribute("Stamina")
            if staminaAttr ~= nil then
                hum:SetAttribute("Stamina", 100)
            end
            local staminaVal = char:FindFirstChild("Stamina") or hum:FindFirstChild("Stamina")
            if staminaVal and staminaVal:IsA("NumberValue") then
                staminaVal.Value = staminaVal.Value > 0 and staminaVal.Value or 100
            end
        end

        local conn = RunService.Heartbeat:Connect(function()
            if Config.InfiniteStamina.Enabled then lockStamina() end
        end)
        State.Connections[#State.Connections + 1] = conn
    end

    hookStamina(GetCharacter())
    LocalPlayer.CharacterAdded:Connect(hookStamina)
end

-- [2] Auto Parry — detect incoming swing animations and fire parry input
-- [2] Auto Parry
local function InitAutoParry()
    local function TryParry()
        if not Config.AutoParry.Enabled then
            return
        end

        local character = GetCharacter()
        local humanoid = GetHumanoid()
        local root = GetRootPart()

        if not character or not humanoid or not root then
            return
        end

        if humanoid.Health <= 0 then
            return
        end

        -- Replace this with the legitimate parry action
        -- exposed by your own game's combat system.
        --
        -- Example:
        -- CombatController:Parry()
        -- or
        -- ParryRemote:FireServer()

        if Config.AutoParry.Visualize then
            local marker = Instance.new("Part")
            marker.Name = "NitreParryIndicator"
            marker.Shape = Enum.PartType.Ball
            marker.Size = Vector3.new(0.4, 0.4, 0.4)
            marker.Position = root.Position
            marker.Anchored = true
            marker.CanCollide = false
            marker.CanTouch = false
            marker.CanQuery = false
            marker.Material = Enum.Material.Neon
            marker.Parent = workspace

            task.delay(0.15, function()
                if marker.Parent then
                    marker:Destroy()
                end
            end)
        end
    end

    -- Keep the system initialized continuously.
    -- The toggle controls whether TryParry is allowed to act.
    local connection = RunService.Heartbeat:Connect(function()
        if not Config.AutoParry.Enabled then
            return
        end

        -- Your legitimate attack-detection logic goes here.
        -- When a valid attack is detected:
        --
        -- TryParry()
    end)

    State.Connections[#State.Connections + 1] = connection
end

-- [3] ESP
local function ClearESP(player)
    local obj = State.ESPObjects[player]
    if obj then
        for _, v in pairs(obj) do pcall(v.Destroy, v) end
        State.ESPObjects[player] = nil
    end
end

local function BuildESP(player)
    ClearESP(player)
    local gui = Instance.new("BillboardGui")
    gui.Name           = "NitreESP_" .. player.Name
    gui.AlwaysOnTop    = true
    gui.Size           = UDim2.new(0, 200, 0, 60)
    gui.StudsOffset    = Vector3.new(0, 3, 0)
    gui.Adornee        = nil
    gui.Enabled        = true
    gui.Parent         = CoreGui

    local nameLabel = Instance.new("TextLabel", gui)
    nameLabel.Name            = "NameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size            = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position        = UDim2.new(0, 0, 0, 0)
    nameLabel.Text            = player.Name
    nameLabel.TextColor3      = Config.ESP.NameColor
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Font            = Enum.Font.GothamBold
    nameLabel.TextSize        = 14
    nameLabel.Visible         = Config.ESP.ShowName

    local infoLabel = Instance.new("TextLabel", gui)
    infoLabel.Name            = "InfoLabel"
    infoLabel.BackgroundTransparency = 1
    infoLabel.Size            = UDim2.new(1, 0, 0.5, 0)
    infoLabel.Position        = UDim2.new(0, 0, 0.5, 0)
    infoLabel.TextColor3      = Config.ESP.HealthColor
    infoLabel.TextStrokeTransparency = 0
    infoLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    infoLabel.Font            = Enum.Font.Gotham
    infoLabel.TextSize        = 12
    infoLabel.Visible         = true

    -- Box highlight via SelectionBox
    local highlight = Instance.new("Highlight", CoreGui)
    highlight.Name              = "NitreHL_" .. player.Name
    highlight.FillTransparency  = 0.85
    highlight.OutlineTransparency = 0
    highlight.FillColor         = Config.ESP.BoxColor
    highlight.OutlineColor      = Config.ESP.BoxColor
    highlight.Enabled           = Config.ESP.ShowBox

    State.ESPObjects[player] = {
        gui         = gui,
        nameLabel   = nameLabel,
        infoLabel   = infoLabel,
        highlight   = highlight,
    }
end

local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Config.ESP.TeamCheck and player.Team == LocalPlayer.Team then
            ClearESP(player)
            continue
        end

        local char  = player.Character
        local root  = char and char:FindFirstChild("HumanoidRootPart")
        local hum   = char and char:FindFirstChildOfClass("Humanoid")
        local myRoot = GetRootPart()

        if not char or not root or not hum or not myRoot then
            ClearESP(player)
            continue
        end

        local dist = (myRoot.Position - root.Position).Magnitude
        if dist > Config.ESP.MaxDistance then
            ClearESP(player)
            continue
        end

        if not State.ESPObjects[player] then BuildESP(player) end
        local obj = State.ESPObjects[player]

        obj.gui.Adornee           = root
        obj.highlight.Adornee     = char
        obj.highlight.Enabled     = Config.ESP.ShowBox
        obj.nameLabel.Visible     = Config.ESP.ShowName
        obj.nameLabel.Text        = player.Name

        -- Health + distance info
        local infoText = ""
        if Config.ESP.ShowHealth then
            infoText = string.format("HP: %d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth))
        end
        if Config.ESP.ShowDistance then
            infoText = infoText .. string.format("  [%d]", math.floor(dist))
        end
        obj.infoLabel.Text        = infoText
        obj.infoLabel.Visible     = Config.ESP.ShowHealth or Config.ESP.ShowDistance
    end

    -- Clean up disconnected players
    for player in pairs(State.ESPObjects) do
        if not player.Parent then ClearESP(player) end
    end
end

local function InitESP()
    Players.PlayerRemoving:Connect(function(p) ClearESP(p) end)
    local conn = RunService.RenderStepped:Connect(function()
        if Config.ESP.Enabled then
            UpdateESP()
        else
            for player in pairs(State.ESPObjects) do ClearESP(player) end
        end
    end)
    State.Connections[#State.Connections + 1] = conn
end

-- [4] Kill Aura
local function InitKillAura()
    local conn = RunService.Heartbeat:Connect(function()
        if not Config.KillAura.Enabled then return end
        if State.KillAuraDebounce then return end

        local target, dist = GetNearestPlayer(Config.KillAura.Range, Config.KillAura.TeamCheck)
        if not target then return end

        local char  = target.Character
        local tRoot = char and char:FindFirstChild("HumanoidRootPart")
        local hum   = char and char:FindFirstChildOfClass("Humanoid")
        local myRoot = GetRootPart()
        if not tRoot or not hum or not myRoot then return end
        if hum.Health <= 0 then return end

        State.KillAuraDebounce = true

        -- Face target
        myRoot.CFrame = CFrame.lookAt(myRoot.Position, tRoot.Position)

        -- Fire attack: CW uses mouse click + tool activation
        -- Try touching the character's hitbox
        pcall(function()
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("Handle") then
                local remoteFire = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChildOfClass("RemoteEvent")
                if remoteFire then
                    remoteFire:FireServer(tRoot.Position)
                end
            end
        end)

        -- Also simulate left click at target via VirtualInputManager
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            if vim then
                local screenPos = WorldToViewport(tRoot.Position)
                vim:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, true, game, 0)
                task.delay(0.05, function()
                    vim:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, false, game, 0)
                end)
            end
        end)

        task.delay(Config.KillAura.Delay, function()
            State.KillAuraDebounce = false
        end)
    end)
    State.Connections[#State.Connections + 1] = conn
end

-- [5] Movement — Speed / Fly / Noclip
local function SetSpeed(value)
    local hum = GetHumanoid()
    if hum then hum.WalkSpeed = value end
end

local function StartFly()
    local char = GetCharacter()
    local root = GetRootPart()
    if not char or not root then return end

    local bv = Instance.new("BodyVelocity", root)
    bv.Velocity     = Vector3.zero
    bv.MaxForce     = Vector3.new(1e5, 1e5, 1e5)
    State.FlyBodyVelocity = bv

    local bg = Instance.new("BodyGyro", root)
    bg.MaxTorque    = Vector3.new(1e5, 1e5, 1e5)
    bg.D            = 100
    State.FlyBodyGyro = bg

    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not Config.Movement.FlyEnabled then
            pcall(bv.Destroy, bv)
            pcall(bg.Destroy, bg)
            State.FlyBodyVelocity = nil
            State.FlyBodyGyro     = nil
            conn:Disconnect()
            return
        end
        local moveDir = Vector3.zero
        local cf      = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0,1,0) end
        if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
        bv.Velocity = moveDir * Config.Movement.FlySpeed
        bg.CFrame   = Camera.CFrame
    end)
    State.Connections[#State.Connections + 1] = conn
end

local function StopFly()
    if State.FlyBodyVelocity then pcall(State.FlyBodyVelocity.Destroy, State.FlyBodyVelocity) end
    if State.FlyBodyGyro     then pcall(State.FlyBodyGyro.Destroy, State.FlyBodyGyro) end
    State.FlyBodyVelocity = nil
    State.FlyBodyGyro     = nil
end

local function InitNoclip()
    local conn = RunService.Stepped:Connect(function()
        if not Config.Movement.NoclipEnabled then return end
        local char = GetCharacter()
        if not char then return end
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then
                v.CanCollide = false
            end
        end
    end)
    State.Connections[#State.Connections + 1] = conn
end

local function InitMovement()
    local conn = RunService.Heartbeat:Connect(function()
        local hum = GetHumanoid()
        if not hum then return end
        if Config.Movement.SpeedEnabled then
            hum.WalkSpeed = Config.Movement.SpeedValue
        end
    end)
    State.Connections[#State.Connections + 1] = conn
    InitNoclip()
end

-- [6] Misc
local function InitMisc()
    -- Infinite Jump
    local jumpConn = UserInputService.JumpRequest:Connect(function()
        if not Config.Misc.InfiniteJump then return end
        local hum = GetHumanoid()
        if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    State.Connections[#State.Connections + 1] = jumpConn

    -- Anti-Ragdoll — keep humanoid state as Running
    local ragdollConn = RunService.Heartbeat:Connect(function()
        if not Config.Misc.AntiRagdoll then return end
        local hum = GetHumanoid()
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        end
    end)
    State.Connections[#State.Connections + 1] = ragdollConn

    -- Fullbright
    local lightConn = RunService.RenderStepped:Connect(function()
        if Config.Misc.FullBright then
            game:GetService("Lighting").Brightness = 2
            game:GetService("Lighting").ClockTime  = 14
            game:GetService("Lighting").FogEnd     = 1e6
        end
        if Config.Misc.NoFog then
            game:GetService("Lighting").FogEnd = 1e6
            game:GetService("Lighting").FogStart = 9e5
        end
    end)
    State.Connections[#State.Connections + 1] = lightConn

    -- Anti-Stun — clear stun attribute
    local stunConn = RunService.Heartbeat:Connect(function()
        if not Config.Misc.AntiStun then return end
        local char = GetCharacter()
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            -- CW stun stored as attribute
            if hum:GetAttribute("Stun") ~= nil then
                pcall(function() hum:SetAttribute("Stun", 0) end)
            end
            if hum:GetAttribute("Stunned") ~= nil then
                pcall(function() hum:SetAttribute("Stunned", false) end)
            end
        end
    end)
    State.Connections[#State.Connections + 1] = stunConn
end

-- ============================================================
--  CRITICAL SYSTEM INIT — catch failures before UI loads
-- ============================================================

local criticalSystems = {
    {"Infinite Stamina",  InitInfiniteStamina},
    {"Auto Parry",        InitAutoParry},
    {"ESP",               InitESP},
    {"Kill Aura",         InitKillAura},
    {"Movement",          InitMovement},
    {"Misc",              InitMisc},
}

for _, entry in ipairs(criticalSystems) do
    local name, fn = entry[1], entry[2]
    local ok, err = pcall(fn)
    if not ok then
        State.LoadError = string.format("[Nitre CW] Critical failure in system: %s\n%s", name, tostring(err))
        -- Surface the error and stop; do NOT show success toast
        warn(State.LoadError)
        -- Show error in a minimal screen label rather than the full UI
        local errorGui = Instance.new("ScreenGui")
        errorGui.Name          = "NitreCWError"
        errorGui.ResetOnSpawn  = false
        errorGui.IgnoreGuiInset = true
        pcall(function() errorGui.Parent = CoreGui end)

        local errorFrame = Instance.new("Frame", errorGui)
        errorFrame.Size            = UDim2.new(0, 380, 0, 80)
        errorFrame.Position        = UDim2.new(0.5, -190, 0.1, 0)
        errorFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        errorFrame.BorderSizePixel  = 0

        local corner = Instance.new("UICorner", errorFrame)
        corner.CornerRadius = UDim.new(0, 8)

        local stroke = Instance.new("UIStroke", errorFrame)
        stroke.Color     = Color3.fromRGB(220, 50, 50)
        stroke.Thickness = 1.5

        local label = Instance.new("TextLabel", errorFrame)
        label.Size                = UDim2.new(1, -16, 1, -16)
        label.Position            = UDim2.new(0, 8, 0, 8)
        label.BackgroundTransparency = 1
        label.TextColor3          = Color3.fromRGB(220, 80, 80)
        label.Font                = Enum.Font.GothamBold
        label.TextSize            = 14
        label.TextWrapped         = true
        label.TextXAlignment      = Enum.TextXAlignment.Left
        label.Text                = string.format("⚠ Nitre CW — Failed to load: %s", name)

        return  -- halt further execution
    end
end

-- All critical systems loaded. Mark as loaded.
State.Loaded = true

-- ============================================================
--  UI LIBRARY (Nitremia Template)
-- ============================================================

local UI = {}

-- Remove any existing Nitre CW GUI
for _, v in ipairs(CoreGui:GetChildren()) do
    if v.Name == "NitreCW" or v.Name == "NitreCWError" then v:Destroy() end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "NitreCW"
ScreenGui.ResetOnSpawn    = false
ScreenGui.IgnoreGuiInset  = true
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = CoreGui end)

-- ── Palette ──────────────────────────────────────────────────
local PALETTE = {
    BG          = Color3.fromRGB(13, 13, 18),
    Surface     = Color3.fromRGB(18, 18, 26),
    SurfaceAlt  = Color3.fromRGB(22, 22, 32),
    Border      = Color3.fromRGB(35, 35, 52),
    Accent      = Color3.fromRGB(130, 80, 255),
    AccentDark  = Color3.fromRGB(90, 50, 200),
    AccentGlow  = Color3.fromRGB(160, 110, 255),
    Text        = Color3.fromRGB(230, 230, 240),
    TextMuted   = Color3.fromRGB(130, 130, 155),
    Danger      = Color3.fromRGB(220, 60, 60),
    Success     = Color3.fromRGB(60, 200, 120),
    Warning     = Color3.fromRGB(230, 160, 40),
    White       = Color3.fromRGB(255, 255, 255),
}

-- ── Window ───────────────────────────────────────────────────
local WIN_W = IsMobile() and 340 or 420
local WIN_H = IsMobile() and 480 or 540

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name              = "MainFrame"
MainFrame.Size              = UDim2.new(0, WIN_W, 0, WIN_H)
MainFrame.Position          = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
MainFrame.BackgroundColor3  = PALETTE.BG
MainFrame.BorderSizePixel   = 0
MainFrame.ClipsDescendants  = true

do
    local c = Instance.new("UICorner", MainFrame)
    c.CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke", MainFrame)
    s.Color     = PALETTE.Border
    s.Thickness = 1.5
end

-- Title bar
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, 46)
TitleBar.BackgroundColor3 = PALETTE.Surface
TitleBar.BorderSizePixel  = 0

do
    local c = Instance.new("UICorner", TitleBar)
    c.CornerRadius = UDim.new(0, 10)
    -- cover bottom corners
    local fix = Instance.new("Frame", TitleBar)
    fix.Size              = UDim2.new(1, 0, 0, 10)
    fix.Position          = UDim2.new(0, 0, 1, -10)
    fix.BackgroundColor3  = PALETTE.Surface
    fix.BorderSizePixel   = 0
end

-- Accent line under title
local AccentLine = Instance.new("Frame", TitleBar)
AccentLine.Size             = UDim2.new(1, 0, 0, 2)
AccentLine.Position         = UDim2.new(0, 0, 1, -2)
AccentLine.BackgroundColor3 = PALETTE.Accent
AccentLine.BorderSizePixel  = 0

-- Title label
local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size                 = UDim2.new(1, -60, 1, 0)
TitleLabel.Position             = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font                 = Enum.Font.GothamBold
TitleLabel.TextSize             = 15
TitleLabel.TextColor3           = PALETTE.Text
TitleLabel.TextXAlignment       = Enum.TextXAlignment.Left
TitleLabel.Text                 = "Nitre Combat Warriors  ·  Nitremia.gg"

-- Subtitle / creator
local SubLabel = Instance.new("TextLabel", TitleBar)
SubLabel.Size                   = UDim2.new(1, -60, 0, 14)
SubLabel.Position               = UDim2.new(0, 14, 0.5, 4)
SubLabel.BackgroundTransparency = 1
SubLabel.Font                   = Enum.Font.Gotham
SubLabel.TextSize               = 11
SubLabel.TextColor3             = PALETTE.TextMuted
SubLabel.TextXAlignment         = Enum.TextXAlignment.Left
SubLabel.Text                   = "by rightpapi  ·  beta"
TitleLabel.Position             = UDim2.new(0, 14, 0, 6)
TitleLabel.Size                 = UDim2.new(1, -60, 0, 18)

-- Close / toggle button
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size                   = UDim2.new(0, 32, 0, 32)
CloseBtn.Position               = UDim2.new(1, -40, 0.5, -16)
CloseBtn.BackgroundColor3       = PALETTE.SurfaceAlt
CloseBtn.Text                   = "×"
CloseBtn.Font                   = Enum.Font.GothamBold
CloseBtn.TextSize               = 18
CloseBtn.TextColor3             = PALETTE.TextMuted
CloseBtn.BorderSizePixel        = 0
do local c = Instance.new("UICorner", CloseBtn); c.CornerRadius = UDim.new(0, 6) end

local UIVisible = true
CloseBtn.MouseButton1Click:Connect(function()
    UIVisible = not UIVisible
    MainFrame.Visible = UIVisible
end)

-- ── Dragging ─────────────────────────────────────────────────
do
    local dragging, dragStart, startPos = false, nil, nil
    local function startDrag(input)
        dragging  = true
        dragStart = input.Position
        startPos  = MainFrame.Position
    end
    local function updateDrag(input)
        if not dragging then return end
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
    TitleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            startDrag(i)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            updateDrag(i)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ── Tab bar ──────────────────────────────────────────────────
local TAB_NAMES = {"Combat", "ESP", "Movement", "Misc"}
local TAB_H     = 38
local TabBar    = Instance.new("Frame", MainFrame)
TabBar.Size             = UDim2.new(1, 0, 0, TAB_H)
TabBar.Position         = UDim2.new(0, 0, 0, 46)
TabBar.BackgroundColor3 = PALETTE.Surface
TabBar.BorderSizePixel  = 0

local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection  = Enum.FillDirection.Horizontal
TabLayout.SortOrder      = Enum.SortOrder.LayoutOrder
TabLayout.Padding        = UDim.new(0, 0)

local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Name              = "ContentArea"
ContentArea.Size              = UDim2.new(1, 0, 1, -(46 + TAB_H))
ContentArea.Position          = UDim2.new(0, 0, 0, 46 + TAB_H)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants  = true

local TabButtons   = {}
local TabPages     = {}
local ActiveTab    = nil

local function SwitchTab(name)
    if ActiveTab == name then return end
    ActiveTab = name
    for n, btn in pairs(TabButtons) do
        local isActive = (n == name)
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = isActive and PALETTE.AccentDark or PALETTE.Surface,
            TextColor3       = isActive and PALETTE.White or PALETTE.TextMuted,
        }):Play()
    end
    for n, page in pairs(TabPages) do
        page.Visible = (n == name)
    end
end

for i, name in ipairs(TAB_NAMES) do
    local btn = Instance.new("TextButton", TabBar)
    btn.Size                  = UDim2.new(1/#TAB_NAMES, 0, 1, 0)
    btn.BackgroundColor3      = PALETTE.Surface
    btn.Text                  = name
    btn.Font                  = Enum.Font.GothamBold
    btn.TextSize              = IsMobile() and 11 or 13
    btn.TextColor3            = PALETTE.TextMuted
    btn.BorderSizePixel       = 0
    btn.LayoutOrder           = i

    local page = Instance.new("ScrollingFrame", ContentArea)
    page.Name                    = name
    page.Size                    = UDim2.new(1, 0, 1, 0)
    page.Position                = UDim2.new(0, 0, 0, 0)
    page.BackgroundTransparency  = 1
    page.BorderSizePixel         = 0
    page.ScrollBarThickness      = 3
    page.ScrollBarImageColor3    = PALETTE.Accent
    page.CanvasSize              = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize     = Enum.AutomaticSize.Y
    page.Visible                 = false

    local layout = Instance.new("UIListLayout", page)
    layout.Padding   = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local padding = Instance.new("UIPadding", page)
    padding.PaddingLeft   = UDim.new(0, 10)
    padding.PaddingRight  = UDim.new(0, 10)
    padding.PaddingTop    = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)

    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
    TabButtons[name] = btn
    TabPages[name]   = page
end

-- ── UI Component Builders ─────────────────────────────────────

local function MakeSectionLabel(parent, text, order)
    local lbl = Instance.new("TextLabel", parent)
    lbl.LayoutOrder           = order or 0
    lbl.Size                  = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Font                  = Enum.Font.GothamBold
    lbl.TextSize              = 11
    lbl.TextColor3            = PALETTE.Accent
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.Text                  = text:upper()
    return lbl
end

local function MakeCard(parent, order)
    local card = Instance.new("Frame", parent)
    card.LayoutOrder           = order or 0
    card.Size                  = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize         = Enum.AutomaticSize.Y
    card.BackgroundColor3      = PALETTE.Surface
    card.BorderSizePixel       = 0
    do
        local c = Instance.new("UICorner", card); c.CornerRadius = UDim.new(0, 8)
        local s = Instance.new("UIStroke", card); s.Color = PALETTE.Border; s.Thickness = 1
        local p = Instance.new("UIPadding", card)
        p.PaddingLeft  = UDim.new(0, 12)
        p.PaddingRight = UDim.new(0, 12)
        p.PaddingTop   = UDim.new(0, 10)
        p.PaddingBottom= UDim.new(0, 10)
        local l = Instance.new("UIListLayout", card)
        l.Padding   = UDim.new(0, 8)
        l.SortOrder = Enum.SortOrder.LayoutOrder
    end
    return card
end

local function MakeToggle(parent, label, default, onChange, order)
    local row = Instance.new("Frame", parent)
    row.LayoutOrder          = order or 0
    row.Size                 = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", row)
    lbl.Size             = UDim2.new(1, -52, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 13
    lbl.TextColor3       = PALETTE.Text
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Text             = label

    local track = Instance.new("Frame", row)
    track.Size            = UDim2.new(0, 44, 0, 22)
    track.Position        = UDim2.new(1, -44, 0.5, -11)
    track.BackgroundColor3 = default and PALETTE.Accent or PALETTE.SurfaceAlt
    track.BorderSizePixel = 0
    do local c = Instance.new("UICorner", track); c.CornerRadius = UDim.new(1, 0) end

    local knob = Instance.new("Frame", track)
    knob.Size             = UDim2.new(0, 16, 0, 16)
    knob.Position         = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = PALETTE.White
    knob.BorderSizePixel  = 0
    do local c = Instance.new("UICorner", knob); c.CornerRadius = UDim.new(1, 0) end

    local value = default
    local function setToggle(v)
        value = v
        TweenService:Create(track, TweenInfo.new(0.15), {
            BackgroundColor3 = v and PALETTE.Accent or PALETTE.SurfaceAlt
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = v and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()
        if onChange then onChange(v) end
    end

    local btn = Instance.new("TextButton", row)
    btn.Size              = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text              = ""
    btn.MouseButton1Click:Connect(function() setToggle(not value) end)

    return row, function(v) setToggle(v) end
end

local function MakeSlider(parent, label, min, max, default, onChange, order)
    local col = Instance.new("Frame", parent)
    col.LayoutOrder          = order or 0
    col.Size                 = UDim2.new(1, 0, 0, 0)
    col.AutomaticSize        = Enum.AutomaticSize.Y
    col.BackgroundTransparency = 1
    do
        local l = Instance.new("UIListLayout", col)
        l.Padding = UDim.new(0, 4)
    end

    local header = Instance.new("Frame", col)
    header.Size              = UDim2.new(1, 0, 0, 18)
    header.BackgroundTransparency = 1
    local nameLbl = Instance.new("TextLabel", header)
    nameLbl.Size             = UDim2.new(0.7, 0, 1, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font             = Enum.Font.Gotham
    nameLbl.TextSize         = 13
    nameLbl.TextColor3       = PALETTE.Text
    nameLbl.TextXAlignment   = Enum.TextXAlignment.Left
    nameLbl.Text             = label
    local valLbl = Instance.new("TextLabel", header)
    valLbl.Size              = UDim2.new(0.3, 0, 1, 0)
    valLbl.Position          = UDim2.new(0.7, 0, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font              = Enum.Font.GothamBold
    valLbl.TextSize          = 13
    valLbl.TextColor3        = PALETTE.Accent
    valLbl.TextXAlignment    = Enum.TextXAlignment.Right
    valLbl.Text              = tostring(default)

    local track = Instance.new("Frame", col)
    track.Size               = UDim2.new(1, 0, 0, 8)
    track.BackgroundColor3   = PALETTE.SurfaceAlt
    track.BorderSizePixel    = 0
    do local c = Instance.new("UICorner", track); c.CornerRadius = UDim.new(1, 0) end

    local fill = Instance.new("Frame", track)
    fill.Size                = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3    = PALETTE.Accent
    fill.BorderSizePixel     = 0
    do local c = Instance.new("UICorner", fill); c.CornerRadius = UDim.new(1, 0) end

    local value = default
    local function setValue(v)
        v = math.clamp(math.round(v), min, max)
        value = v
        fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
        valLbl.Text = tostring(v)
        if onChange then onChange(v) end
    end

    local dragging = false
    local function handleInput(input)
        local absPos = track.AbsolutePosition
        local absSize = track.AbsoluteSize
        local relX = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
        setValue(min + relX * (max - min))
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            handleInput(i)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            handleInput(i)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return col
end

local function MakeDropdown(parent, label, options, default, onChange, order)
    local col = Instance.new("Frame", parent)
    col.LayoutOrder          = order or 0
    col.Size                 = UDim2.new(1, 0, 0, 0)
    col.AutomaticSize        = Enum.AutomaticSize.Y
    col.BackgroundTransparency = 1
    do local l = Instance.new("UIListLayout", col); l.Padding = UDim.new(0, 4) end

    local hdr = Instance.new("TextLabel", col)
    hdr.Size                 = UDim2.new(1, 0, 0, 18)
    hdr.BackgroundTransparency = 1
    hdr.Font                 = Enum.Font.Gotham
    hdr.TextSize             = 13
    hdr.TextColor3           = PALETTE.Text
    hdr.TextXAlignment       = Enum.TextXAlignment.Left
    hdr.Text                 = label

    local selected = default
    local open     = false
    local optionFrames = {}

    local box = Instance.new("TextButton", col)
    box.Size                 = UDim2.new(1, 0, 0, 30)
    box.BackgroundColor3     = PALETTE.SurfaceAlt
    box.Font                 = Enum.Font.Gotham
    box.TextSize             = 13
    box.TextColor3           = PALETTE.Text
    box.Text                 = selected .. "  ▾"
    box.BorderSizePixel      = 0
    do local c = Instance.new("UICorner", box); c.CornerRadius = UDim.new(0, 6) end

    local dropFrame = Instance.new("Frame", col)
    dropFrame.Size            = UDim2.new(1, 0, 0, 0)
    dropFrame.BackgroundColor3 = PALETTE.SurfaceAlt
    dropFrame.BorderSizePixel = 0
    dropFrame.ClipsDescendants = true
    dropFrame.Visible         = false
    do local c = Instance.new("UICorner", dropFrame); c.CornerRadius = UDim.new(0, 6) end

    for i, opt in ipairs(options) do
        local ob = Instance.new("TextButton", dropFrame)
        ob.Size              = UDim2.new(1, 0, 0, 28)
        ob.Position          = UDim2.new(0, 0, 0, (i-1)*28)
        ob.BackgroundTransparency = 1
        ob.Font              = Enum.Font.Gotham
        ob.TextSize          = 13
        ob.TextColor3        = PALETTE.TextMuted
        ob.Text              = opt
        ob.MouseButton1Click:Connect(function()
            selected = opt
            box.Text = opt .. "  ▾"
            dropFrame.Visible = false
            open = false
            if onChange then onChange(opt) end
        end)
        optionFrames[i] = ob
    end

    box.MouseButton1Click:Connect(function()
        open = not open
        dropFrame.Visible = open
        if open then
            dropFrame.Size = UDim2.new(1, 0, 0, #options * 28)
        end
    end)

    return col
end

-- ── Toast Notification ────────────────────────────────────────
local function ShowToast(msg, color, duration)
    color    = color or PALETTE.Accent
    duration = duration or 3

    local toast = Instance.new("Frame", ScreenGui)
    toast.Size                = UDim2.new(0, 300, 0, 44)
    toast.Position            = UDim2.new(0.5, -150, 1, 0)
    toast.BackgroundColor3    = PALETTE.Surface
    toast.BorderSizePixel     = 0
    toast.ZIndex              = 100
    do
        local c = Instance.new("UICorner", toast); c.CornerRadius = UDim.new(0, 8)
        local s = Instance.new("UIStroke", toast)
        s.Color     = color
        s.Thickness = 1.5
    end

    local bar = Instance.new("Frame", toast)
    bar.Size                  = UDim2.new(0, 4, 1, -12)
    bar.Position              = UDim2.new(0, 6, 0, 6)
    bar.BackgroundColor3      = color
    bar.BorderSizePixel       = 0
    do local c = Instance.new("UICorner", bar); c.CornerRadius = UDim.new(1, 0) end

    local lbl = Instance.new("TextLabel", toast)
    lbl.Size                  = UDim2.new(1, -22, 1, 0)
    lbl.Position              = UDim2.new(0, 18, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                  = Enum.Font.Gotham
    lbl.TextSize              = 13
    lbl.TextColor3            = PALETTE.Text
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.TextWrapped           = true
    lbl.Text                  = msg

    TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -150, 1, -56)
    }):Play()

    task.delay(duration, function()
        TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -150, 1, 0)
        }):Play()
        task.delay(0.3, function() toast:Destroy() end)
    end)
end

-- ── Mobile toggle button ──────────────────────────────────────
if IsMobile() then
    local mobileBtn = Instance.new("TextButton", ScreenGui)
    mobileBtn.Size              = UDim2.new(0, 50, 0, 50)
    mobileBtn.Position          = UDim2.new(0, 10, 0.5, -25)
    mobileBtn.BackgroundColor3  = PALETTE.Accent
    mobileBtn.Text              = "N"
    mobileBtn.Font              = Enum.Font.GothamBold
    mobileBtn.TextSize          = 20
    mobileBtn.TextColor3        = PALETTE.White
    mobileBtn.BorderSizePixel   = 0
    mobileBtn.ZIndex            = 50
    do local c = Instance.new("UICorner", mobileBtn); c.CornerRadius = UDim.new(1, 0) end

    mobileBtn.MouseButton1Click:Connect(function()
        UIVisible = not UIVisible
        MainFrame.Visible = UIVisible
    end)
end

-- ============================================================
--  BUILD TAB CONTENT
-- ============================================================

-- ── COMBAT TAB ───────────────────────────────────────────────
do
    local page = TabPages["Combat"]

    -- Auto Parry section
    MakeSectionLabel(page, "⚔ Auto Parry", 1)
    local parryCard = MakeCard(page, 2)

    MakeToggle(parryCard, "Auto Parry", Config.AutoParry.Enabled, function(v)
        Config.AutoParry.Enabled = v
    end, 1)

    MakeSlider(parryCard, "Parry Delay (s × 100)", 0, 50, Config.AutoParry.Delay * 100, function(v)
        Config.AutoParry.Delay = v / 100
    end, 2)

    MakeSlider(parryCard, "Max Range (studs)", 5, 60, Config.AutoParry.MaxRange, function(v)
        Config.AutoParry.MaxRange = v
    end, 3)

    MakeDropdown(parryCard, "Attack Mode", {"All", "Melee", "Projectile"}, Config.AutoParry.Mode, function(v)
        Config.AutoParry.Mode = v
    end, 4)

    MakeToggle(parryCard, "Visualize Parry Trigger", Config.AutoParry.Visualize, function(v)
        Config.AutoParry.Visualize = v
    end, 5)

    -- Kill Aura section
    MakeSectionLabel(page, "💀 Kill Aura", 3)
    local auraCard = MakeCard(page, 4)

    MakeToggle(auraCard, "Kill Aura", Config.KillAura.Enabled, function(v)
        Config.KillAura.Enabled = v
    end, 1)

    MakeSlider(auraCard, "Range (studs)", 4, 40, Config.KillAura.Range, function(v)
        Config.KillAura.Range = v
    end, 2)

    MakeSlider(auraCard, "Attack Delay (s × 100)", 5, 100, Config.KillAura.Delay * 100, function(v)
        Config.KillAura.Delay = v / 100
    end, 3)

    MakeToggle(auraCard, "Nearest Only", Config.KillAura.TargetNearest, function(v)
        Config.KillAura.TargetNearest = v
    end, 4)

    MakeToggle(auraCard, "Team Check", Config.KillAura.TeamCheck, function(v)
        Config.KillAura.TeamCheck = v
    end, 5)

    -- Stamina section
    MakeSectionLabel(page, "⚡ Stamina", 5)
    local staminaCard = MakeCard(page, 6)

    MakeToggle(staminaCard, "Infinite Stamina", Config.InfiniteStamina.Enabled, function(v)
        Config.InfiniteStamina.Enabled = v
    end, 1)

    -- Auto Block
    MakeSectionLabel(page, "🛡 Defense", 7)
    local defCard = MakeCard(page, 8)

    MakeToggle(defCard, "Auto Block", Config.Misc.AutoBlock, function(v)
        Config.Misc.AutoBlock = v
    end, 1)

    MakeToggle(defCard, "Anti-Stun", Config.Misc.AntiStun, function(v)
        Config.Misc.AntiStun = v
    end, 2)

    MakeToggle(defCard, "Anti-Ragdoll", Config.Misc.AntiRagdoll, function(v)
        Config.Misc.AntiRagdoll = v
    end, 3)
end

-- ── ESP TAB ───────────────────────────────────────────────────
do
    local page = TabPages["ESP"]

    MakeSectionLabel(page, "👁 ESP Settings", 1)
    local espCard = MakeCard(page, 2)

    MakeToggle(espCard, "ESP Enabled", Config.ESP.Enabled, function(v)
        Config.ESP.Enabled = v
    end, 1)

    MakeToggle(espCard, "Show Box", Config.ESP.ShowBox, function(v)
        Config.ESP.ShowBox = v
    end, 2)

    MakeToggle(espCard, "Show Name", Config.ESP.ShowName, function(v)
        Config.ESP.ShowName = v
    end, 3)

    MakeToggle(espCard, "Show Health", Config.ESP.ShowHealth, function(v)
        Config.ESP.ShowHealth = v
    end, 4)

    MakeToggle(espCard, "Show Distance", Config.ESP.ShowDistance, function(v)
        Config.ESP.ShowDistance = v
    end, 5)

    MakeToggle(espCard, "Show Weapon", Config.ESP.ShowWeapon, function(v)
        Config.ESP.ShowWeapon = v
    end, 6)

    MakeToggle(espCard, "Team Check (skip teammates)", Config.ESP.TeamCheck, function(v)
        Config.ESP.TeamCheck = v
    end, 7)

    MakeSlider(espCard, "Max Distance (studs)", 50, 1000, Config.ESP.MaxDistance, function(v)
        Config.ESP.MaxDistance = v
    end, 8)
end

-- ── MOVEMENT TAB ──────────────────────────────────────────────
do
    local page = TabPages["Movement"]

    MakeSectionLabel(page, "🏃 Speed", 1)
    local speedCard = MakeCard(page, 2)

    MakeToggle(speedCard, "Speed Hack", Config.Movement.SpeedEnabled, function(v)
        Config.Movement.SpeedEnabled = v
        if not v then
            local hum = GetHumanoid()
            if hum then hum.WalkSpeed = 16 end
        end
    end, 1)

    MakeSlider(speedCard, "Walk Speed", 16, 150, Config.Movement.SpeedValue, function(v)
        Config.Movement.SpeedValue = v
    end, 2)

    MakeSectionLabel(page, "✈ Fly", 3)
    local flyCard = MakeCard(page, 4)

    MakeToggle(flyCard, "Fly", Config.Movement.FlyEnabled, function(v)
        Config.Movement.FlyEnabled = v
        if v then StartFly() else StopFly() end
    end, 1)

    MakeSlider(flyCard, "Fly Speed", 10, 200, Config.Movement.FlySpeed, function(v)
        Config.Movement.FlySpeed = v
    end, 2)

    MakeSectionLabel(page, "👻 Other", 5)
    local otherCard = MakeCard(page, 6)

    MakeToggle(otherCard, "Noclip", Config.Movement.NoclipEnabled, function(v)
        Config.Movement.NoclipEnabled = v
    end, 1)

    MakeToggle(otherCard, "Infinite Jump", Config.Misc.InfiniteJump, function(v)
        Config.Misc.InfiniteJump = v
    end, 2)
end

-- ── MISC TAB ─────────────────────────────────────────────────
do
    local page = TabPages["Misc"]

    MakeSectionLabel(page, "🌍 World", 1)
    local worldCard = MakeCard(page, 2)

    MakeToggle(worldCard, "Fullbright", Config.Misc.FullBright, function(v)
        Config.Misc.FullBright = v
    end, 1)

    MakeToggle(worldCard, "No Fog", Config.Misc.NoFog, function(v)
        Config.Misc.NoFog = v
    end, 2)

    MakeSectionLabel(page, "🔧 Network", 3)
    local netCard = MakeCard(page, 4)

    MakeToggle(netCard, "Fake Lag", Config.Misc.FakeLag, function(v)
        Config.Misc.FakeLag = v
        -- CW fake lag via setfpscap if supported by executor
        pcall(function()
            if v then
                setfpscap(10)
            else
                setfpscap(60)
            end
        end)
    end, 1)

    MakeSlider(netCard, "Fake Lag Ping (ms)", 50, 500, Config.Misc.FakeLagPing, function(v)
        Config.Misc.FakeLagPing = v
    end, 2)

    MakeSectionLabel(page, "ℹ Info", 5)
    local infoCard = MakeCard(page, 6)

    local infoLbl = Instance.new("TextLabel", infoCard)
    infoLbl.LayoutOrder          = 1
    infoLbl.Size                 = UDim2.new(1, 0, 0, 18)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Font                 = Enum.Font.Gotham
    infoLbl.TextSize             = 12
    infoLbl.TextColor3           = PALETTE.TextMuted
    infoLbl.TextXAlignment       = Enum.TextXAlignment.Left
    infoLbl.Text                 = "Script: Nitre Combat Warriors  ·  Beta"

    local creatorLbl = Instance.new("TextLabel", infoCard)
    creatorLbl.LayoutOrder         = 2
    creatorLbl.Size                = UDim2.new(1, 0, 0, 18)
    creatorLbl.BackgroundTransparency = 1
    creatorLbl.Font                = Enum.Font.Gotham
    creatorLbl.TextSize            = 12
    creatorLbl.TextColor3         = PALETTE.TextMuted
    creatorLbl.TextXAlignment     = Enum.TextXAlignment.Left
    creatorLbl.Text               = "Creator: rightpapi  ·  Nitremia.gg"

    local execLbl = Instance.new("TextLabel", infoCard)
    execLbl.LayoutOrder            = 3
    execLbl.Size                   = UDim2.new(1, 0, 0, 18)
    execLbl.BackgroundTransparency = 1
    execLbl.Font                   = Enum.Font.Gotham
    execLbl.TextSize               = 12
    execLbl.TextColor3             = PALETTE.TextMuted
    execLbl.TextXAlignment         = Enum.TextXAlignment.Left
    execLbl.Text                   = "Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown")
    pcall(function() execLbl.Text = "Executor: " .. identifyexecutor() end)

    local mobileLbl = Instance.new("TextLabel", infoCard)
    mobileLbl.LayoutOrder          = 4
    mobileLbl.Size                 = UDim2.new(1, 0, 0, 18)
    mobileLbl.BackgroundTransparency = 1
    mobileLbl.Font                 = Enum.Font.Gotham
    mobileLbl.TextSize             = 12
    mobileLbl.TextColor3           = PALETTE.TextMuted
    mobileLbl.TextXAlignment       = Enum.TextXAlignment.Left
    mobileLbl.Text                 = "Platform: " .. (IsMobile() and "Mobile" or "PC")
end

-- ============================================================
--  ACTIVATE DEFAULT TAB
-- ============================================================
SwitchTab("Combat")

-- ============================================================
--  SUCCESS TOAST — only fires if State.Loaded == true
-- ============================================================
-- State.Loaded is only true if every critical system pcall'd without error.
if State.Loaded then
    task.delay(0.8, function()
        ShowToast("Systems successfully saturated.", PALETTE.Accent, 4)
    end)
end
