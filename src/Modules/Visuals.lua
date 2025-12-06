-- Bastion Client Visuals Module
-- ESP, Tracers, NameTags, and other visual enhancements

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local Visuals = {}

-- Visual settings
local Settings = {
    ESP_Enabled = false,
    ESP_Boxes = true,
    ESP_Names = true,
    ESP_Health = true,
    ESP_Distance = true,
    ESP_TeamCheck = true,
    ESP_MaxDistance = 500,
    
    Tracers_Enabled = false,
    Tracers_Thickness = 2,
    Tracers_Color = Color3.fromRGB(255, 255, 255),
    Tracers_From = "Screen", -- "Screen" or "Crosshair"
    
    NameTags_Enabled = false,
    NameTags_ShowHealth = true,
    NameTags_ShowDistance = true,
    NameTags_Font = Enum.Font.Gotham,
    NameTags_Size = 14,
    
    Chams_Enabled = false,
    Chams_Color = Color3.fromRGB(255, 0, 255),
    Chams_Transparency = 0.3,
    Chams_Material = Enum.Material.ForceField
}

-- ESP elements storage
local ESP_Objects = {}
local Tracer_Objects = {}
local NameTag_Objects = {}
local Cham_Objects = {}

-- Raycast detection for anti-cheat compatibility
local RaycastHandler = {
    LastRaycast = 0,
    RaycastCooldown = 0.1,
    SuspiciousRays = 0,
    MaxSuspiciousRays = 5
}

function RaycastHandler.SafeRaycast(origin, direction, params)
    local currentTime = tick()
    
    if currentTime - RaycastHandler.LastRaycast < RaycastHandler.RaycastCooldown then
        return nil
    end
    
    RaycastHandler.LastRaycast = currentTime
    
    local result = Workspace:Raycast(origin, direction, params)
    
    if result and result.Instance and result.Instance:IsDescendantOf(LocalPlayer.Character) then
        RaycastHandler.SuspiciousRays = RaycastHandler.SuspiciousRays + 1
        if RaycastHandler.SuspiciousRays >= RaycastHandler.MaxSuspiciousRays then
            return nil
        end
    end
    
    return result
end

function Visuals.CreateESP(player)
    if ESP_Objects[player] then
        Visuals.RemoveESP(player)
    end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local espObjects = {}
    
    -- Create box ESP
    if Settings.ESP_Boxes then
        local box = Drawing.new("Square")
        box.Color = Color3.fromRGB(255, 255, 255)
        box.Thickness = 2
        box.Transparency = 1
        box.Filled = false
        box.Visible = false
        espObjects.Box = box
    end
    
    -- Create name tag
    if Settings.ESP_Names then
        local nameTag = Drawing.new("Text")
        nameTag.Color = Color3.fromRGB(255, 255, 255)
        nameTag.Size = Settings.NameTags_Size
        nameTag.Font = Settings.NameTags_Font
        nameTag.Center = true
        nameTag.Outline = true
        nameTag.Visible = false
        espObjects.NameTag = nameTag
    end
    
    -- Create health bar
    if Settings.ESP_Health then
        local healthBar = Drawing.new("Square")
        healthBar.Color = Color3.fromRGB(0, 255, 0)
        healthBar.Thickness = 1
        healthBar.Transparency = 1
        healthBar.Filled = true
        healthBar.Visible = false
        espObjects.HealthBar = healthBar
        
        local healthBg = Drawing.new("Square")
        healthBg.Color = Color3.fromRGB(255, 0, 0)
        healthBg.Thickness = 1
        healthBg.Transparency = 1
        healthBg.Filled = true
        healthBg.Visible = false
        espObjects.HealthBg = healthBg
    end
    
    -- Create tracer
    if Settings.Tracers_Enabled then
        local tracer = Drawing.new("Line")
        tracer.Color = Settings.Tracers_Color
        tracer.Thickness = Settings.Tracers_Thickness
        tracer.Transparency = 1
        tracer.Visible = false
        espObjects.Tracer = tracer
    end
    
    ESP_Objects[player] = espObjects
end

function Visuals.RemoveESP(player)
    local espObjects = ESP_Objects[player]
    if not espObjects then return end
    
    for _, obj in pairs(espObjects) do
        if obj.Remove then
            obj:Remove()
        end
    end
    
    ESP_Objects[player] = nil
end

function Visuals.UpdateESP(player)
    local espObjects = ESP_Objects[player]
    if not espObjects then return end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        Visuals.RemoveESP(player)
        return
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local rootPart = character.HumanoidRootPart
    local position = rootPart.Position
    
    -- Distance check
    local distance = (Camera.CFrame.Position - position).Magnitude
    if distance > Settings.ESP_MaxDistance then
        for _, obj in pairs(espObjects) do
            if obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    
    -- Team check
    if Settings.ESP_TeamCheck and player.Team == LocalPlayer.Team then
        for _, obj in pairs(espObjects) do
            if obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    
    -- Get screen position
    local screenPosition, onScreen = Camera:WorldToViewportPoint(position)
    if not onScreen then
        for _, obj in pairs(espObjects) do
            if obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    
    -- Update box ESP
    if espObjects.Box and Settings.ESP_Boxes then
        local size = (Camera:WorldToViewportPoint(position + Vector3.new(0, 3, 0)).Y - 
                     Camera:WorldToViewportPoint(position - Vector3.new(0, 3, 0)).Y) * 0.8
        
        espObjects.Box.Size = Vector2.new(size, size * 1.8)
        espObjects.Box.Position = Vector2.new(screenPosition.X - size/2, screenPosition.Y - size * 0.9)
        espObjects.Box.Visible = Settings.ESP_Enabled
    end
    
    -- Update name tag
    if espObjects.NameTag and Settings.ESP_Names then
        local nameText = player.Name
        if Settings.ESP_Distance then
            nameText = nameText .. " [" .. math.floor(distance) .. "m]"
        end
        
        espObjects.NameTag.Text = nameText
        espObjects.NameTag.Position = Vector2.new(screenPosition.X, screenPosition.Y - 30)
        espObjects.NameTag.Visible = Settings.ESP_Enabled
    end
    
    -- Update health bar
    if espObjects.HealthBar and espObjects.HealthBg and Settings.ESP_Health then
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        local barWidth = 40
        local barHeight = 4
        
        espObjects.HealthBg.Size = Vector2.new(barWidth, barHeight)
        espObjects.HealthBg.Position = Vector2.new(screenPosition.X - barWidth/2 - 25, screenPosition.Y - 20)
        espObjects.HealthBg.Visible = Settings.ESP_Enabled
        
        espObjects.HealthBar.Size = Vector2.new(barWidth * healthPercent, barHeight)
        espObjects.HealthBar.Position = Vector2.new(screenPosition.X - barWidth/2 - 25, screenPosition.Y - 20)
        espObjects.HealthBar.Color = healthPercent > 0.5 and Color3.fromRGB(0, 255, 0) or 
                                   healthPercent > 0.25 and Color3.fromRGB(255, 255, 0) or 
                                   Color3.fromRGB(255, 0, 0)
        espObjects.HealthBar.Visible = Settings.ESP_Enabled
    end
    
    -- Update tracer
    if espObjects.Tracer and Settings.Tracers_Enabled then
        local fromPos
        
        if Settings.Tracers_From == "Screen" then
            fromPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        else -- Crosshair
            fromPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        end
        
        espObjects.Tracer.From = fromPos
        espObjects.Tracer.To = Vector2.new(screenPosition.X, screenPosition.Y)
        espObjects.Tracer.Visible = Settings.ESP_Enabled
    end
end

function Visuals.CreateChams(player)
    if Cham_Objects[player] then
        Visuals.RemoveChams(player)
    end
    
    local character = player.Character
    if not character then return end
    
    local chamObjects = {}
    
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local cham = Instance.new("Highlight")
            cham.Name = "BastionCham"
            cham.Parent = part
            cham.FillColor = Settings.Chams_Color
            cham.OutlineColor = Settings.Chams_Color
            cham.FillTransparency = Settings.Chams_Transparency
            cham.OutlineTransparency = 0
            cham.Enabled = Settings.Chams_Enabled
            
            table.insert(chamObjects, cham)
        end
    end
    
    Cham_Objects[player] = chamObjects
end

function Visuals.RemoveChams(player)
    local chamObjects = Cham_Objects[player]
    if not chamObjects then return end
    
    for _, cham in pairs(chamObjects) do
        if cham and cham.Parent then
            cham:Destroy()
        end
    end
    
    Cham_Objects[player] = nil
end

function Visuals.UpdateChams(player)
    local chamObjects = Cham_Objects[player]
    if not chamObjects then return end
    
    local character = player.Character
    if not character then
        Visuals.RemoveChams(player)
        return
    end
    
    -- Team check
    local shouldBeVisible = Settings.Chams_Enabled
    if Settings.ESP_TeamCheck and player.Team == LocalPlayer.Team then
        shouldBeVisible = false
    end
    
    for _, cham in pairs(chamObjects) do
        if cham and cham.Parent then
            cham.Enabled = shouldBeVisible
        end
    end
end

-- Settings functions
function Visuals.SetESPEnabled(state)
    Settings.ESP_Enabled = state
    
    if not state then
        for player, _ in pairs(ESP_Objects) do
            Visuals.RemoveESP(player)
        end
    end
end

function Visuals.SetESPBoxes(state)
    Settings.ESP_Boxes = state
    
    for player, espObjects in pairs(ESP_Objects) do
        if espObjects.Box then
            espObjects.Box:Remove()
            espObjects.Box = nil
        end
        
        if state then
            local box = Drawing.new("Square")
            box.Color = Color3.fromRGB(255, 255, 255)
            box.Thickness = 2
            box.Transparency = 1
            box.Filled = false
            box.Visible = false
            espObjects.Box = box
        end
    end
end

function Visuals.SetESPNames(state)
    Settings.ESP_Names = state
    
    for player, espObjects in pairs(ESP_Objects) do
        if espObjects.NameTag then
            espObjects.NameTag:Remove()
            espObjects.NameTag = nil
        end
        
        if state then
            local nameTag = Drawing.new("Text")
            nameTag.Color = Color3.fromRGB(255, 255, 255)
            nameTag.Size = Settings.NameTags_Size
            nameTag.Font = Settings.NameTags_Font
            nameTag.Center = true
            nameTag.Outline = true
            nameTag.Visible = false
            espObjects.NameTag = nameTag
        end
    end
end

function Visuals.SetESPHealth(state)
    Settings.ESP_Health = state
    
    for player, espObjects in pairs(ESP_Objects) do
        if espObjects.HealthBar then
            espObjects.HealthBar:Remove()
            espObjects.HealthBar = nil
        end
        if espObjects.HealthBg then
            espObjects.HealthBg:Remove()
            espObjects.HealthBg = nil
        end
        
        if state then
            local healthBar = Drawing.new("Square")
            healthBar.Color = Color3.fromRGB(0, 255, 0)
            healthBar.Thickness = 1
            healthBar.Transparency = 1
            healthBar.Filled = true
            healthBar.Visible = false
            espObjects.HealthBar = healthBar
            
            local healthBg = Drawing.new("Square")
            healthBg.Color = Color3.fromRGB(255, 0, 0)
            healthBg.Thickness = 1
            healthBg.Transparency = 1
            healthBg.Filled = true
            healthBg.Visible = false
            espObjects.HealthBg = healthBg
        end
    end
end

function Visuals.SetTracersEnabled(state)
    Settings.Tracers_Enabled = state
    
    for player, espObjects in pairs(ESP_Objects) do
        if espObjects.Tracer then
            espObjects.Tracer:Remove()
            espObjects.Tracer = nil
        end
        
        if state then
            local tracer = Drawing.new("Line")
            tracer.Color = Settings.Tracers_Color
            tracer.Thickness = Settings.Tracers_Thickness
            tracer.Transparency = 1
            tracer.Visible = false
            espObjects.Tracer = tracer
        end
    end
end

function Visuals.SetTracerThickness(thickness)
    Settings.Tracers_Thickness = thickness
    
    for _, espObjects in pairs(ESP_Objects) do
        if espObjects.Tracer then
            espObjects.Tracer.Thickness = thickness
        end
    end
end

function Visuals.SetChamsEnabled(state)
    Settings.Chams_Enabled = state
    
    for player, _ in pairs(Cham_Objects) do
        Visuals.UpdateChams(player)
    end
end

-- Main update loop
function Visuals.Update()
    -- Update ESP for all players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            -- Create ESP if it doesn't exist
            if Settings.ESP_Enabled and not ESP_Objects[player] then
                Visuals.CreateESP(player)
            end
            
            -- Update ESP
            if ESP_Objects[player] then
                Visuals.UpdateESP(player)
            end
            
            -- Create/Update Chams
            if Settings.Chams_Enabled then
                if not Cham_Objects[player] then
                    Visuals.CreateChams(player)
                else
                    Visuals.UpdateChams(player)
                end
            elseif Cham_Objects[player] then
                Visuals.RemoveChams(player)
            end
        end
    end
    
    -- Clean up disconnected players
    for player, _ in pairs(ESP_Objects) do
        if not Players:FindFirstChild(player.Name) then
            Visuals.RemoveESP(player)
        end
    end
    
    for player, _ in pairs(Cham_Objects) do
        if not Players:FindFirstChild(player.Name) then
            Visuals.RemoveChams(player)
        end
    end
end

-- Player added/removed events
Players.PlayerAdded:Connect(function(player)
    if Settings.ESP_Enabled then
        player.CharacterAdded:Connect(function()
            wait(1) -- Wait for character to load
            Visuals.CreateESP(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    Visuals.RemoveESP(player)
    Visuals.RemoveChams(player)
end)

-- Cleanup function
function Visuals.Cleanup()
    for player, _ in pairs(ESP_Objects) do
        Visuals.RemoveESP(player)
    end
    
    for player, _ in pairs(Cham_Objects) do
        Visuals.RemoveChams(player)
    end
end

return Visuals
