-- Bastion Client Utility Module
-- Inventory management, chest stealing, auto-bed, and other utilities

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local Utility = {}

-- Utility settings
local Settings = {
    AutoArmor_Enabled = false,
    AutoArmor_Priority = {"diamond", "emerald", "gold", "iron", "leather"},
    
    AutoTool_Enabled = false,
    AutoTool_SwitchOnBreak = true,
    AutoTool_BestTool = true,
    
    ChestSteal_Enabled = false,
    ChestSteal_Mode = "All", -- "All", "Valuables", "Custom"
    ChestSteal_Delay = 0.1,
    ChestSteal_MaxDistance = 20,
    ChestSteal_Items = {"diamond", "emerald", "gold", "iron"},
    
    AutoBed_Enabled = false,
    AutoBed_BreakBeds = true,
    AutoBed_PlaceBeds = false,
    AutoBed_BreakRange = 15,
    
    AutoSword_Enabled = false,
    AutoSword_SwitchOnCombat = true,
    
    InventoryManager_Enabled = false,
    InventoryManager_SortItems = false,
    InventoryManager_DropTrash = false,
    InventoryManager_TrashItems = {"wood", "stone"},
    
    Bridging_Enabled = false,
    Bridging_Mode = "Normal", -- "Normal", "GodBridge", "NinjaBridge"
    Bridging_Block = "wood"
}

-- Utility state
local UtilityState = {
    CurrentTool = nil,
    CurrentArmor = {},
    ChestQueue = {},
    BedQueue = {},
    LastChestCheck = 0,
    LastBedCheck = 0,
    InventoryCache = {},
    ToolCache = {}
}

-- Anti-detection system
local AntiDetection = {
    LastInventoryAction = 0,
    InventoryActionCooldown = 0.2,
    SuspiciousActions = 0,
    MaxSuspiciousActions = 15,
    RandomDelay = 0.1
}

function AntiDetection.SafeInventoryAction(action, delay)
    delay = delay or AntiDetection.RandomDelay
    local currentTime = tick()
    
    if currentTime - AntiDetection.LastInventoryAction < delay then
        wait(delay - (currentTime - AntiDetection.LastInventoryAction))
    end
    
    local success, result = pcall(action)
    AntiDetection.LastInventoryAction = currentTime
    
    if not success then
        AntiDetection.SuspiciousActions = AntiDetection.SuspiciousActions + 1
        warn("Bastion Utility: Inventory action failed -", result)
        
        if AntiDetection.SuspiciousActions >= AntiDetection.MaxSuspiciousActions then
            warn("Bastion Utility: Too many suspicious actions, disabling temporarily")
            return false
        end
    end
    
    return success, result
end

function Utility.Initialize()
    -- Setup character added event
    LocalPlayer.CharacterAdded:Connect(function(char)
        wait(1) -- Wait for character to fully load
        Utility.RefreshInventoryCache()
    end)
    
    print("Bastion Utility initialized")
end

function Utility.Update()
    local character = LocalPlayer.Character
    if not character then return end
    
    -- Auto armor
    if Settings.AutoArmor_Enabled then
        Utility.HandleAutoArmor(character)
    end
    
    -- Auto tool
    if Settings.AutoTool_Enabled then
        Utility.HandleAutoTool(character)
    end
    
    -- Chest stealing
    if Settings.ChestSteal_Enabled then
        Utility.HandleChestSteal(character)
    end
    
    -- Auto bed
    if Settings.AutoBed_Enabled then
        Utility.HandleAutoBed(character)
    end
    
    -- Auto sword
    if Settings.AutoSword_Enabled then
        Utility.HandleAutoSword(character)
    end
    
    -- Inventory manager
    if Settings.InventoryManager_Enabled then
        Utility.HandleInventoryManager(character)
    end
    
    -- Bridging
    if Settings.Bridging_Enabled then
        Utility.HandleBridging(character)
    end
end

function Utility.HandleAutoArmor(character)
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then return end
    
    -- Get current armor
    local currentArmor = {
        helmet = character:FindFirstChildOfClass("Accessory") and character:FindFirstChildOfClass("Accessory"):FindFirstChild("Handle"),
        chestplate = character:FindFirstChild("BodyColors") and character:FindFirstChild("BodyColors"):FindFirstChild("Handle"),
        leggings = character:FindFirstChild("BodyColors") and character:FindFirstChild("BodyColors"):FindFirstChild("Handle"),
        boots = character:FindFirstChild("BodyColors") and character:FindFirstChild("BodyColors"):FindFirstChild("Handle")
    }
    
    -- Find better armor in inventory
    for _, priority in ipairs(Settings.AutoArmor_Priority) do
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find(priority) then
                -- Check if this is armor and better than current
                if Utility.IsBetterArmor(item, currentArmor) then
                    AntiDetection.SafeInventoryAction(function()
                        item.Parent = character
                        wait(0.1)
                        item.Parent = backpack -- Move back to equip
                    end, 0.3)
                end
            end
        end
    end
end

function Utility.HandleAutoTool(character)
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local currentTool = humanoid:FindFirstChildOfClass("Tool")
    
    -- Find best tool for current situation
    local targetPart = Utility.GetTargetPart()
    if targetPart then
        local bestTool = Utility.GetBestTool(targetPart)
        
        if bestTool and bestTool ~= currentTool then
            AntiDetection.SafeInventoryAction(function()
                humanoid:EquipTool(bestTool)
            end, 0.2)
        end
    end
end

function Utility.HandleChestSteal(character)
    local currentTime = tick()
    
    if currentTime - UtilityState.LastChestCheck < 1 then return end
    UtilityState.LastChestCheck = currentTime
    
    -- Find nearby chests
    local nearbyChests = Utility.FindNearbyChests(character.HumanoidRootPart.Position, Settings.ChestSteal_MaxDistance)
    
    for _, chest in pairs(nearbyChests) do
        if not chest:FindFirstChild("BastionProcessed") then
            Utility.StealFromChest(chest)
        end
    end
end

function Utility.HandleAutoBed(character)
    local currentTime = tick()
    
    if currentTime - UtilityState.LastBedCheck < 2 then return end
    UtilityState.LastBedCheck = currentTime
    
    if Settings.AutoBed_BreakBeds then
        local nearbyBeds = Utility.FindNearbyBeds(character.HumanoidRootPart.Position, Settings.AutoBed_BreakRange)
        
        for _, bed in pairs(nearbyBeds) do
            if bed:FindFirstChild("BastionProcessed") then continue end
            
            -- Check if bed is enemy bed
            if Utility.IsEnemyBed(bed) then
                Utility.BreakBed(bed)
            end
        end
    end
    
    if Settings.AutoBed_PlaceBeds then
        Utility.HandleBedPlacement(character)
    end
end

function Utility.HandleAutoSword(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local currentTool = humanoid:FindFirstChildOfClass("Tool")
    
    -- Check if in combat
    local nearestEnemy = Utility.GetNearestEnemy(character.HumanoidRootPart.Position, 10)
    
    if nearestEnemy then
        -- Switch to sword if not already holding one
        if not currentTool or not Utility.IsSword(currentTool) then
            local sword = Utility.GetBestSword()
            if sword then
                AntiDetection.SafeInventoryAction(function()
                    humanoid:EquipTool(sword)
                end, 0.2)
            end
        end
    end
end

function Utility.HandleInventoryManager(character)
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then return end
    
    if Settings.InventoryManager_SortItems then
        Utility.SortInventory(backpack)
    end
    
    if Settings.InventoryManager_DropTrash then
        Utility.DropTrashItems(backpack)
    end
end

function Utility.HandleBridging(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local rootPart = character.HumanoidRootPart
    
    -- Check if player is in bridging position
    if UserInputService:IsKeyDown(Enum.KeyCode.W) and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        local targetPosition = rootPart.Position + rootPart.CFrame.LookVector * 3
        
        if Settings.Bridging_Mode == "Normal" then
            Utility.PlaceBlock(targetPosition)
        elseif Settings.Bridging_Mode == "GodBridge" then
            Utility.PlaceGodBridge(rootPart)
        elseif Settings.Bridging_Mode == "NinjaBridge" then
            Utility.PlaceNinjaBridge(rootPart)
        end
    end
end

-- Helper functions
function Utility.IsBetterArmor(armor, currentArmor)
    -- Simple armor comparison based on material priority
    local armorMaterial = Utility.GetArmorMaterial(armor)
    
    for _, current in pairs(currentArmor) do
        if current then
            local currentMaterial = Utility.GetArmorMaterial(current)
            if Utility.CompareArmorMaterials(armorMaterial, currentMaterial) <= 0 then
                return false
            end
        end
    end
    
    return true
end

function Utility.GetArmorMaterial(armor)
    if not armor then return "none" end
    
    local name = armor.Name:lower()
    if name:find("diamond") then return "diamond"
    elseif name:find("emerald") then return "emerald"
    elseif name:find("gold") then return "gold"
    elseif name:find("iron") then return "iron"
    elseif name:find("leather") then return "leather"
    else return "none" end
end

function Utility.CompareArmorMaterials(material1, material2)
    local priority = {
        ["none"] = 0,
        ["leather"] = 1,
        ["iron"] = 2,
        ["gold"] = 3,
        ["emerald"] = 4,
        ["diamond"] = 5
    }
    
    return (priority[material1] or 0) - (priority[material2] or 0)
end

function Utility.GetTargetPart()
    local mouse = LocalPlayer:GetMouse()
    local target = mouse.Target
    
    if target and target:IsDescendantOf(Workspace) then
        return target
    end
    
    return nil
end

function Utility.GetBestTool(target)
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then return nil end
    
    local bestTool = nil
    local bestEffectiveness = 0
    
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local effectiveness = Utility.GetToolEffectiveness(tool, target)
            if effectiveness > bestEffectiveness then
                bestEffectiveness = effectiveness
                bestTool = tool
            end
        end
    end
    
    return bestTool
end

function Utility.GetToolEffectiveness(tool, target)
    -- Simple effectiveness calculation based on tool type and target material
    local toolName = tool.Name:lower()
    local targetName = target.Name:lower()
    
    if toolName:find("sword") then return 1 end
    if toolName:find("pickaxe") and targetName:find("stone") then return 3 end
    if toolName:find("axe") and targetName:find("wood") then return 3 end
    if toolName:find("shovel") and targetName:find("dirt") then return 3 end
    
    return 1
end

function Utility.FindNearbyChests(position, maxDistance)
    local chests = {}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("chest") then
            local chestPosition = obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetModelCFrame().Position
            local distance = (position - chestPosition).Magnitude
            
            if distance <= maxDistance then
                table.insert(chests, obj)
            end
        end
    end
    
    return chests
end

function Utility.StealFromChest(chest)
    -- Mark as processed
    local processedTag = Instance.new("BoolValue")
    processedTag.Name = "BastionProcessed"
    processedTag.Parent = chest
    
    -- Simulate chest opening and stealing
    AntiDetection.SafeInventoryAction(function()
        -- This would need to be adapted based on the specific game's chest system
        -- For now, we'll simulate the action
        
        -- Fire remote events for chest interaction
        for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") and remote.Name:lower():find("chest") then
                remote:FireServer(chest)
                wait(Settings.ChestSteal_Delay)
            end
        end
        
        -- Remove processed tag after some time
        game:GetService("Debris"):AddItem(processedTag, 5)
    end, Settings.ChestSteal_Delay)
end

function Utility.FindNearbyBeds(position, maxDistance)
    local beds = {}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("bed") then
            local bedPosition = obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetModelCFrame().Position
            local distance = (position - bedPosition).Magnitude
            
            if distance <= maxDistance then
                table.insert(beds, obj)
            end
        end
    end
    
    return beds
end

function Utility.IsEnemyBed(bed)
    -- Check if bed belongs to enemy team
    local bedTeam = bed:FindFirstChild("Team")
    if bedTeam then
        return bedTeam.Value ~= LocalPlayer.Team
    end
    
    -- Check bed color vs player team color
    local bedColor = bed.PrimaryPart and bed.PrimaryPart.Color
    local playerColor = LocalPlayer.Team and LocalPlayer.Team.TeamColor
    
    if bedColor and playerColor then
        return bedColor ~= playerColor.Color
    end
    
    return true -- Assume enemy if can't determine
end

function Utility.BreakBed(bed)
    -- Mark as processed
    local processedTag = Instance.new("BoolValue")
    processedTag.Name = "BastionProcessed"
    processedTag.Parent = bed
    
    AntiDetection.SafeInventoryAction(function()
        -- This would need to be adapted based on the specific game's bed breaking system
        for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") and remote.Name:lower():find("break") then
                remote:FireServer(bed)
                break
            end
        end
        
        -- Remove processed tag
        game:GetService("Debris"):AddItem(processedTag, 3)
    end, 0.2)
end

function Utility.GetNearestEnemy(position, maxDistance)
    local nearestEnemy = nil
    local nearestDistance = maxDistance
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (position - player.Character.HumanoidRootPart.Position).Magnitude
            
            if distance < nearestDistance then
                nearestDistance = distance
                nearestEnemy = player
            end
        end
    end
    
    return nearestEnemy
end

function Utility.IsSword(tool)
    local toolName = tool.Name:lower()
    return toolName:find("sword") or toolName:find("blade") or toolName:find("knife")
end

function Utility.GetBestSword()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then return nil end
    
    local bestSword = nil
    local bestDamage = 0
    
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and Utility.IsSword(tool) then
            local damage = Utility.GetSwordDamage(tool)
            if damage > bestDamage then
                bestDamage = damage
                bestSword = tool
            end
        end
    end
    
    return bestSword
end

function Utility.GetSwordDamage(sword)
    -- This would need to be adapted based on the specific game's sword damage system
    local swordName = sword.Name:lower()
    
    if swordName:find("diamond") then return 8
    elseif swordName:find("iron") then return 6
    elseif swordName:find("gold") then return 5
    elseif swordName:find("stone") then return 4
    elseif swordName:find("wood") then return 3
    else return 4 end
end

function Utility.SortInventory(backpack)
    -- Simple inventory sorting by item type and value
    local items = {}
    
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(items, {
                Item = item,
                Priority = Utility.GetItemPriority(item)
            })
        end
    end
    
    -- Sort by priority
    table.sort(items, function(a, b)
        return a.Priority > b.Priority
    end)
    
    -- Rearrange items (this is a simplified version)
    for i, itemData in ipairs(items) do
        local targetPosition = Vector3.new((i-1) * 2, 0, 0)
        -- This would need to be adapted based on the specific game's inventory system
    end
end

function Utility.GetItemPriority(item)
    local itemName = item.Name:lower()
    
    if itemName:find("diamond") then return 100
    elseif itemName:find("emerald") then return 90
    elseif itemName:find("gold") then return 80
    elseif itemName:find("iron") then return 70
    elseif itemName:find("stone") then return 60
    elseif itemName:find("wood") then return 50
    else return 10 end
end

function Utility.DropTrashItems(backpack)
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            for _, trashItem in pairs(Settings.InventoryManager_TrashItems) do
                if item.Name:lower():find(trashItem) then
                    AntiDetection.SafeInventoryAction(function()
                        item.Parent = Workspace
                        wait(0.1)
                        item:Destroy()
                    end, 0.3)
                    break
                end
            end
        end
    end
end

function Utility.PlaceBlock(position)
    -- This would need to be adapted based on the specific game's block placement system
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then return end
    
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find(Settings.Bridging_Block) then
            AntiDetection.SafeInventoryAction(function()
                -- Simulate block placement
                for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
                    if remote:IsA("RemoteEvent") and remote.Name:lower():find("place") then
                        remote:FireServer(position, tool)
                        break
                    end
                end
            end, 0.2)
            break
        end
    end
end

function Utility.PlaceGodBridge(rootPart)
    -- Advanced bridging technique
    local positions = {
        rootPart.Position + rootPart.CFrame.LookVector * 3,
        rootPart.Position + rootPart.CFrame.LookVector * 6,
        rootPart.Position + rootPart.CFrame.LookVector * 9
    }
    
    for _, pos in pairs(positions) do
        Utility.PlaceBlock(pos)
        wait(0.05)
    end
end

function Utility.PlaceNinjaBridge(rootPart)
    -- Quick bridging with backward momentum
    local forward = rootPart.CFrame.LookVector
    local backward = -forward
    
    -- Place block while moving backward
    Utility.PlaceBlock(rootPart.Position + forward * 3)
    
    -- Apply backward velocity for momentum
    AntiDetection.SafeInventoryAction(function()
        rootPart.Velocity = backward * 10
    end, 0.1)
end

function Utility.RefreshInventoryCache()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then return end
    
    UtilityState.InventoryCache = {}
    UtilityState.ToolCache = {}
    
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(UtilityState.InventoryCache, item)
            
            if Utility.IsSword(item) then
                table.insert(UtilityState.ToolCache, item)
            end
        end
    end
end

-- Settings functions
function Utility.SetAutoArmor(state)
    Settings.AutoArmor_Enabled = state
end

function Utility.SetAutoTool(state)
    Settings.AutoTool_Enabled = state
end

function Utility.SetChestSteal(state)
    Settings.ChestSteal_Enabled = state
end

function Utility.SetAutoBed(state)
    Settings.AutoBed_Enabled = state
end

function Utility.SetAutoSword(state)
    Settings.AutoSword_Enabled = state
end

function Utility.SetInventoryManager(state)
    Settings.InventoryManager_Enabled = state
end

function Utility.SetBridging(state)
    Settings.Bridging_Enabled = state
end

-- Cleanup function
function Utility.Cleanup()
    -- Clean up any processed tags
    for _, obj in pairs(Workspace:GetDescendants()) do
        local processedTag = obj:FindFirstChild("BastionProcessed")
        if processedTag then
            processedTag:Destroy()
        end
    end
end

-- Initialize the module
Utility.Initialize()

return Utility
