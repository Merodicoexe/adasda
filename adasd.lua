-- Rivals Advanced Cheat Script
-- Features: Aimbot, ESP (Box, Skeleton, Healthbar)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Configuration
local Config = {
    Aimbot = {
        Enabled = false,
        TeamCheck = true,
        VisibleCheck = true,
        FOV = 120,
        Smoothness = 0.1,
        AimPart = "Head",
        ShowFOV = true
    },
    ESP = {
        Enabled = true,
        TeamCheck = true,
        Box = true,
        BoxColor = Color3.fromRGB(255, 255, 255),
        Skeleton = true,
        SkeletonColor = Color3.fromRGB(255, 0, 0),
        Healthbar = true,
        HealthbarGreen = Color3.fromRGB(0, 255, 0),
        HealthbarRed = Color3.fromRGB(255, 0, 0),
        Distance = true,
        MaxDistance = 500
    }
}

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.NumSides = 50
FOVCircle.Radius = Config.Aimbot.FOV
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Visible = Config.Aimbot.ShowFOV

-- ESP Storage
local ESPObjects = {}

-- Helper Functions
local function IsAlive(player)
    if not player or not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function IsTeamMate(player)
    if not Config.Aimbot.TeamCheck and not Config.ESP.TeamCheck then return false end
    return player.Team == LocalPlayer.Team
end

local function IsVisible(targetPart)
    if not Config.Aimbot.VisibleCheck then return true end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local ray = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), raycastParams)
    return ray == nil or ray.Instance:IsDescendantOf(targetPart.Parent)
end

local function GetClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) then
            if Config.Aimbot.TeamCheck and IsTeamMate(player) then continue end
            
            local character = player.Character
            local aimPart = character:FindFirstChild(Config.Aimbot.AimPart)
            
            if aimPart then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
                    
                    if distance < Config.Aimbot.FOV and distance < shortestDistance then
                        if IsVisible(aimPart) then
                            closestPlayer = player
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

-- ESP Functions
local function CreateESP(player)
    local esp = {
        BoxOutline = Drawing.new("Square"),
        Box = Drawing.new("Square"),
        HealthbarOutline = Drawing.new("Square"),
        Healthbar = Drawing.new("Square"),
        Distance = Drawing.new("Text"),
        Skeleton = {}
    }
    
    -- Box Setup
    esp.BoxOutline.Thickness = 3
    esp.BoxOutline.Filled = false
    esp.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
    esp.BoxOutline.Visible = false
    
    esp.Box.Thickness = 1
    esp.Box.Filled = false
    esp.Box.Color = Config.ESP.BoxColor
    esp.Box.Visible = false
    
    -- Healthbar Setup
    esp.HealthbarOutline.Thickness = 3
    esp.HealthbarOutline.Filled = false
    esp.HealthbarOutline.Color = Color3.fromRGB(0, 0, 0)
    esp.HealthbarOutline.Visible = false
    
    esp.Healthbar.Filled = true
    esp.Healthbar.Visible = false
    
    -- Distance Setup
    esp.Distance.Size = 14
    esp.Distance.Center = true
    esp.Distance.Outline = true
    esp.Distance.Color = Color3.fromRGB(255, 255, 255)
    esp.Distance.Visible = false
    
    -- Skeleton Setup (Lines connecting body parts)
    local skeletonConnections = {
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"}
    }
    
    for _, connection in pairs(skeletonConnections) do
        local line = Drawing.new("Line")
        line.Thickness = 1
        line.Color = Config.ESP.SkeletonColor
        line.Visible = false
        table.insert(esp.Skeleton, {line = line, from = connection[1], to = connection[2]})
    end
    
    ESPObjects[player] = esp
end

local function UpdateESP(player, esp)
    if not IsAlive(player) then
        esp.Box.Visible = false
        esp.BoxOutline.Visible = false
        esp.Healthbar.Visible = false
        esp.HealthbarOutline.Visible = false
        esp.Distance.Visible = false
        for _, skelLine in pairs(esp.Skeleton) do
            skelLine.line.Visible = false
        end
        return
    end
    
    if Config.ESP.TeamCheck and IsTeamMate(player) then
        esp.Box.Visible = false
        esp.BoxOutline.Visible = false
        esp.Healthbar.Visible = false
        esp.HealthbarOutline.Visible = false
        esp.Distance.Visible = false
        for _, skelLine in pairs(esp.Skeleton) do
            skelLine.line.Visible = false
        end
        return
    end
    
    local character = player.Character
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if not rootPart or not humanoid then return end
    
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    
    if distance > Config.ESP.MaxDistance then
        esp.Box.Visible = false
        esp.BoxOutline.Visible = false
        esp.Healthbar.Visible = false
        esp.HealthbarOutline.Visible = false
        esp.Distance.Visible = false
        for _, skelLine in pairs(esp.Skeleton) do
            skelLine.line.Visible = false
        end
        return
    end
    
    -- Calculate Box Dimensions
    local head = character:FindFirstChild("Head")
    if not head then return end
    
    local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    local legPos, legOnScreen = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
    
    if headOnScreen and legOnScreen then
        local height = math.abs(headPos.Y - legPos.Y)
        local width = height / 2
        
        -- Draw Box
        if Config.ESP.Box then
            esp.BoxOutline.Size = Vector2.new(width, height)
            esp.BoxOutline.Position = Vector2.new(headPos.X - width / 2, headPos.Y - height / 2)
            esp.BoxOutline.Visible = true
            
            esp.Box.Size = Vector2.new(width, height)
            esp.Box.Position = Vector2.new(headPos.X - width / 2, headPos.Y - height / 2)
            esp.Box.Visible = true
        else
            esp.Box.Visible = false
            esp.BoxOutline.Visible = false
        end
        
        -- Draw Healthbar
        if Config.ESP.Healthbar then
            local healthPercentage = humanoid.Health / humanoid.MaxHealth
            
            esp.HealthbarOutline.Size = Vector2.new(3, height)
            esp.HealthbarOutline.Position = Vector2.new(headPos.X - width / 2 - 7, headPos.Y - height / 2)
            esp.HealthbarOutline.Visible = true
            
            esp.Healthbar.Size = Vector2.new(3, height * healthPercentage)
            esp.Healthbar.Position = Vector2.new(headPos.X - width / 2 - 7, headPos.Y + height / 2 - height * healthPercentage)
            esp.Healthbar.Color = Config.ESP.HealthbarGreen:Lerp(Config.ESP.HealthbarRed, 1 - healthPercentage)
            esp.Healthbar.Visible = true
        else
            esp.Healthbar.Visible = false
            esp.HealthbarOutline.Visible = false
        end
        
        -- Draw Distance
        if Config.ESP.Distance then
            esp.Distance.Text = string.format("[%dm]", math.floor(distance))
            esp.Distance.Position = Vector2.new(headPos.X, legPos.Y + 5)
            esp.Distance.Visible = true
        else
            esp.Distance.Visible = false
        end
        
        -- Draw Skeleton
        if Config.ESP.Skeleton then
            for _, skelLine in pairs(esp.Skeleton) do
                local fromPart = character:FindFirstChild(skelLine.from)
                local toPart = character:FindFirstChild(skelLine.to)
                
                if fromPart and toPart then
                    local fromPos, fromOnScreen = Camera:WorldToViewportPoint(fromPart.Position)
                    local toPos, toOnScreen = Camera:WorldToViewportPoint(toPart.Position)
                    
                    if fromOnScreen and toOnScreen then
                        skelLine.line.From = Vector2.new(fromPos.X, fromPos.Y)
                        skelLine.line.To = Vector2.new(toPos.X, toPos.Y)
                        skelLine.line.Visible = true
                    else
                        skelLine.line.Visible = false
                    end
                else
                    skelLine.line.Visible = false
                end
            end
        else
            for _, skelLine in pairs(esp.Skeleton) do
                skelLine.line.Visible = false
            end
        end
    else
        esp.Box.Visible = false
        esp.BoxOutline.Visible = false
        esp.Healthbar.Visible = false
        esp.HealthbarOutline.Visible = false
        esp.Distance.Visible = false
        for _, skelLine in pairs(esp.Skeleton) do
            skelLine.line.Visible = false
        end
    end
end

local function RemoveESP(player)
    if ESPObjects[player] then
        ESPObjects[player].Box:Remove()
        ESPObjects[player].BoxOutline:Remove()
        ESPObjects[player].Healthbar:Remove()
        ESPObjects[player].HealthbarOutline:Remove()
        ESPObjects[player].Distance:Remove()
        for _, skelLine in pairs(ESPObjects[player].Skeleton) do
            skelLine.line:Remove()
        end
        ESPObjects[player] = nil
    end
end

-- Initialize ESP for all players
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

-- Handle new players
Players.PlayerAdded:Connect(function(player)
    CreateESP(player)
end)

-- Handle leaving players
Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- Main Loop
RunService.RenderStepped:Connect(function()
    -- Update FOV Circle
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = mousePos
    FOVCircle.Radius = Config.Aimbot.FOV
    FOVCircle.Visible = Config.Aimbot.ShowFOV and Config.Aimbot.Enabled
    
    -- Update ESP
    if Config.ESP.Enabled then
        for player, esp in pairs(ESPObjects) do
            if player.Parent == Players then
                UpdateESP(player, esp)
            else
                RemoveESP(player)
            end
        end
    else
        for player, esp in pairs(ESPObjects) do
            esp.Box.Visible = false
            esp.BoxOutline.Visible = false
            esp.Healthbar.Visible = false
            esp.HealthbarOutline.Visible = false
            esp.Distance.Visible = false
            for _, skelLine in pairs(esp.Skeleton) do
                skelLine.line.Visible = false
            end
        end
    end
    
    -- Aimbot
    if Config.Aimbot.Enabled then
        local target = GetClosestPlayerToCursor()
        if target and target.Character then
            local aimPart = target.Character:FindFirstChild(Config.Aimbot.AimPart)
            if aimPart then
                local aimPosition = Camera:WorldToViewportPoint(aimPart.Position)
                local mousePosition = UserInputService:GetMouseLocation()
                
                local deltaX = (aimPosition.X - mousePosition.X) * Config.Aimbot.Smoothness
                local deltaY = (aimPosition.Y - mousePosition.Y) * Config.Aimbot.Smoothness
                
                mousemoverel(deltaX, deltaY)
            end
        end
    end
end)

-- Keybinds
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Toggle Aimbot (Right Mouse Button)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Config.Aimbot.Enabled = not Config.Aimbot.Enabled
        print("Aimbot:", Config.Aimbot.Enabled and "Enabled" or "Disabled")
    end
    
    -- Toggle ESP (INSERT)
    if input.KeyCode == Enum.KeyCode.Insert then
        Config.ESP.Enabled = not Config.ESP.Enabled
        print("ESP:", Config.ESP.Enabled and "Enabled" or "Disabled")
    end
    
    -- Toggle Box ESP (B)
    if input.KeyCode == Enum.KeyCode.B then
        Config.ESP.Box = not Config.ESP.Box
        print("Box ESP:", Config.ESP.Box and "Enabled" or "Disabled")
    end
    
    -- Toggle Skeleton ESP (K)
    if input.KeyCode == Enum.KeyCode.K then
        Config.ESP.Skeleton = not Config.ESP.Skeleton
        print("Skeleton ESP:", Config.ESP.Skeleton and "Enabled" or "Disabled")
    end
    
    -- Toggle Healthbar ESP (H)
    if input.KeyCode == Enum.KeyCode.H then
        Config.ESP.Healthbar = not Config.ESP.Healthbar
        print("Healthbar ESP:", Config.ESP.Healthbar and "Enabled" or "Disabled")
    end
end)

print("Rivals Cheat Script Loaded!")
print("Controls:")
print("- Right Mouse Button: Toggle Aimbot")
print("- INSERT: Toggle ESP")
print("- B: Toggle Box ESP")
print("- K: Toggle Skeleton ESP")
print("- H: Toggle Healthbar ESP")
