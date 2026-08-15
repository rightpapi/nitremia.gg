-- ============================================================
--  ENTRENCHED WW1 — XENO CHEAT SUITE v2.1
--  Compatible: Xeno (84% UNC / 40% sUNC)
--  Added: Projectile Prediction, expanded Silent Aim,
--         cleaner scrollable tabs, FOV circle, more combat opts
-- ============================================================

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local Workspace     = game:GetService("Workspace")
local Lighting      = game:GetService("Lighting")
local Camera        = Workspace.CurrentCamera

local LocalPlayer   = Players.LocalPlayer
local Mouse         = LocalPlayer:GetMouse()

-- ============================================================
--  CONFIG
-- ============================================================
local CFG = {
    -- Aimbot
    AimbotEnabled       = false,
    AimbotKey           = Enum.KeyCode.E,
    AimbotPart          = "Head",
    AimbotSmoothing     = 0.15,
    AimbotFOV           = 180,
    AimbotTeamCheck     = true,
    AimbotVisCheck      = false,
    AimbotPrediction    = true,
    AimbotBulletSpeed   = 900,      -- studs/s — tune per weapon class
    AimbotPredictMult   = 1.0,      -- 0.8–1.2 typical

    -- Silent Aim (expanded)
    SilentAimEnabled    = false,
    SilentAimPart       = "Head",
    SilentAimFOV        = 200,
    SilentAimHitChance  = 100,      -- %
    SilentAimPrediction = true,
    SilentAimBulletSpeed= 900,
    SilentAimPredictMult= 1.0,
    SilentAimSticky     = true,     -- keep lock on current target until dead/out of FOV
    SilentAimTeamCheck  = true,
    SilentAimVisCheck   = false,

    -- ESP
    ESPEnabled          = false,
    ESPBoxes            = true,
    ESPNames            = true,
    ESPHealth           = true,
    ESPDistance         = true,
    ESPTracers          = false,
    ESPMaxDist          = 1000,
    ESPTeamColor        = true,
    ESPShowTeam         = false,

    -- Movement
    SpeedEnabled        = false,
    SpeedValue          = 32,

    -- Combat / Exploits
    InfAmmoEnabled      = false,
    GodModeEnabled      = false,
    NoDigCooldown        = false,
    NoSpreadEnabled     = false,
    NoclipEnabled       = false,
    FullbrightEnabled   = false,
    NoRecoilEnabled     = false,

    -- Visual
    FOVCircleEnabled    = true,
    FOVCircleColor      = Color3.fromRGB(214, 156, 33),
}

-- ============================================================
--  UTILITY
-- ============================================================
local function IsEnemy(player)
    if not CFG.AimbotTeamCheck and not CFG.SilentAimTeamCheck then return true end
    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end
    return true
end

local function GetCharacter(player)
    return player.Character
end

local function GetRoot(player)
    local char = GetCharacter(player)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid(player)
    local char = GetCharacter(player)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetAimPart(player, partName)
    local char = GetCharacter(player)
    if not char then return nil end
    return char:FindFirstChild(partName) or char:FindFirstChild("HumanoidRootPart")
end

local function IsAlive(player)
    local hum = GetHumanoid(player)
    return hum and hum.Health > 0
end

local function WorldToViewport(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function GetFOVDistance(screenPos)
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    return (screenPos - center).Magnitude
end

local function RaycastVisible(origin, target)
    local dir = (target - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local chars = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then table.insert(chars, p.Character) end
    end
    params.FilterDescendantsInstances = chars
    local result = Workspace:Raycast(origin, dir, params)
    return result == nil
end

-- Prediction: classic lead = target_pos + velocity * (distance / bullet_speed) * mult
local function PredictPosition(part, bulletSpeed, mult)
    if not part then return nil end
    local root = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart")
    local vel = root and root.AssemblyLinearVelocity or Vector3.zero
    local origin = Camera.CFrame.Position
    local dist = (part.Position - origin).Magnitude
    local travelTime = dist / math.max(bulletSpeed, 1)
    return part.Position + (vel * travelTime * mult)
end

-- ============================================================
--  DRAWING
-- ============================================================
local DrawObjects = {}

local function NewDrawing(type, props)
    local ok, obj = pcall(function() return Drawing.new(type) end)
    if not ok then return nil end
    for k, v in pairs(props) do
        pcall(function() obj[k] = v end)
    end
    table.insert(DrawObjects, obj)
    return obj
end

local function ClearDrawings()
    for _, obj in ipairs(DrawObjects) do
        pcall(function() obj:Remove() end)
    end
    DrawObjects = {}
end

-- FOV Circle
local FOVCircle = NewDrawing("Circle", {
    Visible = false,
    Thickness = 1.5,
    Color = CFG.FOVCircleColor,
    Filled = false,
    NumSides = 64,
    Radius = 0,
})

-- ============================================================
--  ESP
-- ============================================================
local ESPCache = {}

local function GetESPColor(player)
    if CFG.ESPTeamColor then
        if player.Team == LocalPlayer.Team then
            return Color3.fromRGB(0, 200, 255)
        else
            return Color3.fromRGB(255, 60, 60)
        end
    end
    return Color3.fromRGB(255, 255, 255)
end

local function CreateESPObjects(player)
    ESPCache[player] = {
        Box      = NewDrawing("Square", {Visible=false, Color=Color3.new(1,1,1), Thickness=1.5, Filled=false}),
        Name     = NewDrawing("Text",   {Visible=false, Color=Color3.new(1,1,1), Size=13, Center=true, Outline=true, OutlineColor=Color3.new(0,0,0)}),
        Health   = NewDrawing("Square", {Visible=false, Color=Color3.fromRGB(0,255,80), Thickness=1, Filled=true}),
        HealthBG = NewDrawing("Square", {Visible=false, Color=Color3.fromRGB(40,40,40), Thickness=1, Filled=true}),
        Dist     = NewDrawing("Text",   {Visible=false, Color=Color3.fromRGB(200,200,200), Size=11, Center=true, Outline=true, OutlineColor=Color3.new(0,0,0)}),
        Tracer   = NewDrawing("Line",   {Visible=false, Color=Color3.new(1,1,1), Thickness=1}),
    }
end

local function RemoveESPObjects(player)
    if ESPCache[player] then
        for _, obj in pairs(ESPCache[player]) do
            pcall(function() obj:Remove() end)
        end
        ESPCache[player] = nil
    end
end

local function HideESP(player)
    if ESPCache[player] then
        for _, obj in pairs(ESPCache[player]) do
            pcall(function() obj.Visible = false end)
        end
    end
end

local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not CFG.ESPShowTeam and not IsEnemy(player) then
            HideESP(player)
            continue
        end

        if not ESPCache[player] then CreateESPObjects(player) end
        local esp = ESPCache[player]

        if not CFG.ESPEnabled or not IsAlive(player) then
            HideESP(player)
            continue
        end

        local root = GetRoot(player)
        local hum  = GetHumanoid(player)
        local char = GetCharacter(player)
        if not root or not hum or not char then
            HideESP(player)
            continue
        end

        local rootPos = root.Position
        local dist = (Camera.CFrame.Position - rootPos).Magnitude
        if dist > CFG.ESPMaxDist then
            HideESP(player)
            continue
        end

        local headPart = char:FindFirstChild("Head")
        local topPos   = headPart and headPart.Position + Vector3.new(0, headPart.Size.Y / 2 + 0.1, 0) or rootPos + Vector3.new(0, 3, 0)
        local botPos   = rootPos - Vector3.new(0, 3, 0)

        local topScreen, topOnScreen = WorldToViewport(topPos)
        local botScreen, botOnScreen = WorldToViewport(botPos)

        if not topOnScreen and not botOnScreen then
            HideESP(player)
            continue
        end

        local boxH = math.abs(topScreen.Y - botScreen.Y)
        local boxW = boxH * 0.55
        local boxX = topScreen.X - boxW / 2
        local boxY = topScreen.Y
        local color = GetESPColor(player)

        if CFG.ESPBoxes and esp.Box then
            esp.Box.Visible  = true
            esp.Box.Color    = color
            esp.Box.Size     = Vector2.new(boxW, boxH)
            esp.Box.Position = Vector2.new(boxX, boxY)
        elseif esp.Box then
            esp.Box.Visible = false
        end

        if CFG.ESPNames and esp.Name then
            esp.Name.Visible  = true
            esp.Name.Color    = color
            esp.Name.Text     = player.Name
            esp.Name.Position = Vector2.new(topScreen.X, boxY - 16)
        elseif esp.Name then
            esp.Name.Visible = false
        end

        if CFG.ESPDistance and esp.Dist then
            esp.Dist.Visible  = true
            esp.Dist.Text     = string.format("[%dm]", math.floor(dist / 4))
            esp.Dist.Position = Vector2.new(topScreen.X, botScreen.Y + 2)
        elseif esp.Dist then
            esp.Dist.Visible = false
        end

        if CFG.ESPHealth and esp.Health and esp.HealthBG then
            local hpRatio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            local barX, barW = boxX - 5, 3
            esp.HealthBG.Visible  = true
            esp.HealthBG.Size     = Vector2.new(barW, boxH)
            esp.HealthBG.Position = Vector2.new(barX - barW, boxY)
            esp.Health.Visible    = true
            esp.Health.Size       = Vector2.new(barW, boxH * hpRatio)
            esp.Health.Position   = Vector2.new(barX - barW, boxY + boxH * (1 - hpRatio))
            esp.Health.Color      = Color3.fromRGB(math.floor(255 * (1 - hpRatio)), math.floor(255 * hpRatio), 0)
        elseif esp.Health then
            esp.Health.Visible = false
            esp.HealthBG.Visible = false
        end

        if CFG.ESPTracers and esp.Tracer then
            esp.Tracer.Visible = true
            esp.Tracer.Color   = color
            esp.Tracer.From    = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            esp.Tracer.To      = botScreen
        elseif esp.Tracer then
            esp.Tracer.Visible = false
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if not ESPCache[player] then CreateESPObjects(player) end
    end)
end)

Players.PlayerRemoving:Connect(RemoveESPObjects)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESPObjects(player) end
end

-- ============================================================
--  TARGET SELECTION (shared by Aimbot + Silent)
-- ============================================================
local StickyTarget = nil

local function GetClosestEnemy(useSilentSettings)
    local fovLimit = useSilentSettings and CFG.SilentAimFOV or CFG.AimbotFOV
    local teamCheck = useSilentSettings and CFG.SilentAimTeamCheck or CFG.AimbotTeamCheck
    local visCheck  = useSilentSettings and CFG.SilentAimVisCheck or CFG.AimbotVisCheck
    local partName  = useSilentSettings and CFG.SilentAimPart or CFG.AimbotPart
    local usePred   = useSilentSettings and CFG.SilentAimPrediction or CFG.AimbotPrediction
    local bSpeed    = useSilentSettings and CFG.SilentAimBulletSpeed or CFG.AimbotBulletSpeed
    local predMult  = useSilentSettings and CFG.SilentAimPredictMult or CFG.AimbotPredictMult

    -- Sticky
    if useSilentSettings and CFG.SilentAimSticky and StickyTarget then
        if IsAlive(StickyTarget) and IsEnemy(StickyTarget) then
            local part = GetAimPart(StickyTarget, partName)
            if part then
                local predPos = usePred and PredictPosition(part, bSpeed, predMult) or part.Position
                local screenPos, onScreen = WorldToViewport(predPos)
                if onScreen and GetFOVDistance(screenPos) <= fovLimit then
                    if not visCheck or RaycastVisible(Camera.CFrame.Position, predPos) then
                        return StickyTarget, predPos
                    end
                end
            end
        end
        StickyTarget = nil
    end

    local closest, closestDist, bestPos = nil, math.huge, nil

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if teamCheck and not IsEnemy(player) then continue end
        if not IsAlive(player) then continue end

        local part = GetAimPart(player, partName)
        if not part then continue end

        local aimPos = usePred and PredictPosition(part, bSpeed, predMult) or part.Position
        local screenPos, onScreen = WorldToViewport(aimPos)
        if not onScreen then continue end

        local fovDist = GetFOVDistance(screenPos)
        if fovDist > fovLimit then continue end

        if visCheck and not RaycastVisible(Camera.CFrame.Position, aimPos) then continue end

        if fovDist < closestDist then
            closestDist = fovDist
            closest = player
            bestPos = aimPos
        end
    end

    if useSilentSettings and CFG.SilentAimSticky then
        StickyTarget = closest
    end

    return closest, bestPos
end

-- ============================================================
--  SILENT AIM — metatable hook on Mouse.Hit
-- ============================================================
local SilentAimHooked = false
local SilentAimOrigIndex = nil

local function EnableSilentAim()
    if SilentAimHooked then return end
    local mt = getrawmetatable(game)
    if not mt then return end

    local oldIndex = mt.__index
    SilentAimOrigIndex = oldIndex

    setreadonly(mt, false)
    mt.__index = newcclosure(function(self, key)
        if self == Mouse and key == "Hit" and CFG.SilentAimEnabled then
            if math.random(1, 100) > CFG.SilentAimHitChance then
                return oldIndex(self, key)
            end
            local target, predPos = GetClosestEnemy(true)
            if target and predPos then
                return CFrame.new(predPos)
            end
        end
        return oldIndex(self, key)
    end)
    setreadonly(mt, true)
    SilentAimHooked = true
end

local function DisableSilentAim()
    if not SilentAimHooked then return end
    local mt = getrawmetatable(game)
    if not mt then return end
    setreadonly(mt, false)
    mt.__index = SilentAimOrigIndex
    setreadonly(mt, true)
    SilentAimHooked = false
    StickyTarget = nil
end

-- ============================================================
--  INF AMMO / GOD MODE / DIG / SPEED / NOCLIP / FULLBRIGHT
--  (kept from original, cleaned)
-- ============================================================
local InfAmmoConnections = {}

local function HookAmmoValues()
    for _, conn in ipairs(InfAmmoConnections) do pcall(function() conn:Disconnect() end) end
    InfAmmoConnections = {}

    local char = LocalPlayer.Character
    if not char then return end

    local function PatchTool(tool)
        for _, inst in ipairs(tool:GetDescendants()) do
            if inst:IsA("IntValue") or inst:IsA("NumberValue") then
                local name = inst.Name:lower()
                if name:find("ammo") or name:find("bullets") or name:find("rounds") or name:find("magazine") or name:find("mag") or name:find("clip") then
                    local conn = inst.Changed:Connect(function(val)
                        if CFG.InfAmmoEnabled and val < 999 then
                            inst.Value = 999
                        end
                    end)
                    table.insert(InfAmmoConnections, conn)
                    if CFG.InfAmmoEnabled then inst.Value = 999 end
                end
            end
        end
    end

    local tool = char:FindFirstChildOfClass("Tool")
    if tool then PatchTool(tool) end
    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") then PatchTool(item) end
    end

    local conn1 = char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            PatchTool(child)
        end
    end)
    table.insert(InfAmmoConnections, conn1)

    pcall(function()
        for _, obj in ipairs(getgc(true)) do
            if type(obj) == "table" then
                for k, v in pairs(obj) do
                    local kname = tostring(k):lower()
                    if (kname:find("ammo") or kname:find("bullets") or kname:find("magazine")) and type(v) == "number" then
                        if CFG.InfAmmoEnabled then pcall(function() rawset(obj, k, 999) end) end
                    end
                end
            end
        end
    end)
end

local GodModeConn = nil
local function EnableGodMode()
    local hum = GetHumanoid(LocalPlayer)
    if not hum then return end
    pcall(function()
        local mt = getrawmetatable(hum)
        if mt then
            setreadonly(mt, false)
            local oldNewIndex = mt.__newindex
            mt.__newindex = newcclosure(function(self, key, value)
                if self == hum and key == "Health" and CFG.GodModeEnabled then
                    return oldNewIndex(self, key, hum.MaxHealth)
                end
                return oldNewIndex(self, key, value)
            end)
            setreadonly(mt, true)
        end
    end)
    if GodModeConn then GodModeConn:Disconnect() end
    GodModeConn = hum.HealthChanged:Connect(function()
        if CFG.GodModeEnabled then hum.Health = hum.MaxHealth end
    end)
end

local function DisableGodMode()
    if GodModeConn then GodModeConn:Disconnect() GodModeConn = nil end
end

local function PatchDigCooldown()
    local char = LocalPlayer.Character
    if not char then return end
    local function ZeroCooldowns(parent)
        for _, inst in ipairs(parent:GetDescendants()) do
            if inst:IsA("NumberValue") or inst:IsA("IntValue") then
                local name = inst.Name:lower()
                if name:find("cooldown") or name:find("cd") or name:find("delay") or name:find("timer") then
                    if CFG.NoDigCooldown then
                        pcall(function() inst.Value = 0 end)
                        inst.Changed:Connect(function(v)
                            if CFG.NoDigCooldown and v > 0 then pcall(function() inst.Value = 0 end) end
                        end)
                    end
                end
            end
        end
    end
    for _, tool in ipairs(char:GetChildren()) do if tool:IsA("Tool") then ZeroCooldowns(tool) end end
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do if tool:IsA("Tool") then ZeroCooldowns(tool) end end
end

local function ApplySpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.WalkSpeed = CFG.SpeedEnabled and CFG.SpeedValue or 16
end

local NoclipConn = nil
local function EnableNoclip()
    if NoclipConn then return end
    NoclipConn = RunService.Stepped:Connect(function()
        if not CFG.NoclipEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
end

local function DisableNoclip()
    if NoclipConn then NoclipConn:Disconnect() NoclipConn = nil end
end

local function SetFullbright(enabled)
    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    else
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
        Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
        Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
    end
end

-- ============================================================
--  CHARACTER REFRESH
-- ============================================================
local function OnCharacterAdded(char)
    task.wait(1.5)
    if CFG.GodModeEnabled then EnableGodMode() end
    if CFG.InfAmmoEnabled then HookAmmoValues() end
    if CFG.NoDigCooldown then PatchDigCooldown() end
    ApplySpeed()
end

LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
if LocalPlayer.Character then OnCharacterAdded(LocalPlayer.Character) end

-- ============================================================
--  MAIN LOOP
-- ============================================================
local AimbotActive = false

RunService.RenderStepped:Connect(function()
    UpdateESP()

    -- FOV Circle
    if FOVCircle then
        local show = CFG.FOVCircleEnabled and (CFG.AimbotEnabled or CFG.SilentAimEnabled)
        FOVCircle.Visible = show
        if show then
            local radius = CFG.AimbotEnabled and CFG.AimbotFOV or CFG.SilentAimFOV
            FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            FOVCircle.Radius = radius
            FOVCircle.Color = CFG.FOVCircleColor
        end
    end

    -- Aimbot
    if CFG.AimbotEnabled and AimbotActive then
        local target, predPos = GetClosestEnemy(false)
        if target and predPos then
            local targetCF = CFrame.new(Camera.CFrame.Position, predPos)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, CFG.AimbotSmoothing)
        end
    end

    if CFG.SpeedEnabled then ApplySpeed() end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == CFG.AimbotKey then AimbotActive = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == CFG.AimbotKey then AimbotActive = false end
end)

-- ============================================================
--  GUI — CLEANER LAYOUT (scrollable tabs, no overflow)
-- ============================================================
local COL = {
    IRON        = Color3.fromRGB(28, 28, 24),
    IRON_LIGHT  = Color3.fromRGB(38, 38, 33),
    IRON_MID    = Color3.fromRGB(50, 50, 43),
    IRON_EDGE   = Color3.fromRGB(18, 18, 15),
    AMBER       = Color3.fromRGB(214, 156, 33),
    AMBER_DIM   = Color3.fromRGB(140, 100, 20),
    AMBER_GLOW  = Color3.fromRGB(255, 190, 60),
    RED_STATUS  = Color3.fromRGB(180, 40, 30),
    TEXT_MAIN   = Color3.fromRGB(220, 210, 180),
    TEXT_DIM    = Color3.fromRGB(130, 120, 100),
    TEXT_HEADER = Color3.fromRGB(240, 225, 170),
    RIVET       = Color3.fromRGB(80, 76, 65),
    SLIDER_TRK  = Color3.fromRGB(22, 22, 18),
    DIVIDER     = Color3.fromRGB(60, 58, 48),
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EntSuite"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 460, 0, 560)
MainFrame.Position = UDim2.new(0, 100, 0, 60)
MainFrame.BackgroundColor3 = COL.IRON
MainFrame.BorderColor3 = COL.IRON_EDGE
MainFrame.BorderSizePixel = 2
MainFrame.Parent = ScreenGui

local TopAccentBar = Instance.new("Frame")
TopAccentBar.Size = UDim2.new(1, 0, 0, 3)
TopAccentBar.BackgroundColor3 = COL.AMBER
TopAccentBar.BorderSizePixel = 0
TopAccentBar.ZIndex = 2
TopAccentBar.Parent = MainFrame

local function MakeRivet(ax, ay, px, py)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(0, 7, 0, 7)
    r.AnchorPoint = Vector2.new(ax, ay)
    r.Position = UDim2.new(px, 0, py, 0)
    r.BackgroundColor3 = COL.RIVET
    r.BorderColor3 = COL.IRON_EDGE
    r.BorderSizePixel = 1
    r.ZIndex = 3
    r.Parent = MainFrame
    local uc = Instance.new("UICorner")
    uc.CornerRadius = UDim.new(1, 0)
    uc.Parent = r
end
MakeRivet(0,0,0,0) MakeRivet(1,0,1,0) MakeRivet(0,1,0,1) MakeRivet(1,1,1,1)

-- Title
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.Position = UDim2.new(0, 0, 0, 3)
TitleBar.BackgroundColor3 = COL.IRON_MID
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0, 30, 1, 0)
TitleIcon.Position = UDim2.new(0, 8, 0, 0)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text = "✛"
TitleIcon.TextColor3 = COL.AMBER
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.TextSize = 16
TitleIcon.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -110, 1, 0)
TitleLabel.Position = UDim2.new(0, 38, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "ENTRENCHED  //  FIELD OPS v2.1"
TitleLabel.TextColor3 = COL.TEXT_HEADER
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local VerLabel = Instance.new("TextLabel")
VerLabel.Size = UDim2.new(0, 55, 1, 0)
VerLabel.Position = UDim2.new(1, -60, 0, 0)
VerLabel.BackgroundTransparency = 1
VerLabel.Text = "XENO"
VerLabel.TextColor3 = COL.AMBER_DIM
VerLabel.Font = Enum.Font.Code
VerLabel.TextSize = 10
VerLabel.Parent = TitleBar

-- Drag
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Tab strip with horizontal scroll (fixes overflow)
local TabScroll = Instance.new("ScrollingFrame")
TabScroll.Name = "TabScroll"
TabScroll.Size = UDim2.new(1, 0, 0, 34)
TabScroll.Position = UDim2.new(0, 0, 0, 39)
TabScroll.BackgroundColor3 = COL.IRON_EDGE
TabScroll.BorderSizePixel = 0
TabScroll.ScrollBarThickness = 3
TabScroll.ScrollBarImageColor3 = COL.AMBER_DIM
TabScroll.ScrollingDirection = Enum.ScrollingDirection.X
TabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
TabScroll.Parent = MainFrame

local TabList = Instance.new("UIListLayout")
TabList.FillDirection = Enum.FillDirection.Horizontal
TabList.SortOrder = Enum.SortOrder.LayoutOrder
TabList.Padding = UDim.new(0, 0)
TabList.Parent = TabScroll

local TabUnderline = Instance.new("Frame")
TabUnderline.Size = UDim2.new(1, 0, 0, 1)
TabUnderline.Position = UDim2.new(0, 0, 1, -1)
TabUnderline.BackgroundColor3 = COL.AMBER_DIM
TabUnderline.BorderSizePixel = 0
TabUnderline.Parent = TabScroll

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -16, 1, -84)
ContentArea.Position = UDim2.new(0, 8, 0, 78)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants = true
ContentArea.Parent = MainFrame

-- UI helpers
local function MakeDivider(parent, y)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, 0, 0, 1)
    d.Position = UDim2.new(0, 0, 0, y)
    d.BackgroundColor3 = COL.DIVIDER
    d.BorderSizePixel = 0
    d.Parent = parent
end

local function MakeSectionHeader(parent, text, y)
    local bracket = Instance.new("Frame")
    bracket.Size = UDim2.new(0, 3, 0, 14)
    bracket.Position = UDim2.new(0, 0, 0, y + 4)
    bracket.BackgroundColor3 = COL.AMBER
    bracket.BorderSizePixel = 0
    bracket.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 22)
    lbl.Position = UDim2.new(0, 10, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = "[ " .. text .. " ]"
    lbl.TextColor3 = COL.TEXT_HEADER
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
end

local function MakeToggle(parent, labelText, y, cfgKey, callback)
    local row = Instance.new("Frame")
    row.Size =
