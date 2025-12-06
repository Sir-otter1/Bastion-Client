-- Bastion Client Combat Module
-- KillAura, Aimbot, Targeting, and other combat enhancements

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local Combat = {}

-- Combat settings
local Settings = {
    KillAura_Enabled = false,
    KillAura_Range = 6,
    KillAura_Delay = 0.1,
    KillAura_Mode = "Single", -- "Single", "Multi", "Switch"
    KillAura_Rotation = true,
    KillAura_RotationSpeed = 10,
    KillAura_ThroughWalls = false,
    
    Aimbot_Enabled = false,
    Aimbot_Mode = "Silent", -- "Silent", "Lock", "Smooth"
    Aimbot_Smoothness = 5,
    Aimbot_FOV = 90,
    Aimbot_Priority = "Distance", -- "Distance", "Health", "Angle"
    Aimbot_TargetLock = true,
    Aimbot_AimAt = "Head", -- "Head", "Body", "Nearest"
    
    TargetPlayers_Enabled = true,
    TargetTeams_Enabled = false,
    TargetNpcs_Enabled = false,
    TargetFriends_Enabled = false,
    TargetInvisible_Enabled = false,
    
    Criticals_Enabled = false,
    Criticals_Mode = "Jump", -- "Jump", "Packet"
    
    Reach_Enabled = false,
    Reach_Multiplier = 1.5,
    
    Velocity_Enabled = false,
    Velocity_Horizontal = 100,
    Velocity_Vertical = 50,
    
    AutoClicker_Enabled = false,
    AutoClicker_CPS = 10, -- Clicks Per Second
    AutoClicker_Jitter = false,
    
    AntiBot_Enabled = true,
    AntiBot_Checks = {"InvalidHealth", "InvalidPosition", "NoHumanoid", "SameTeam"}
}

-- Combat state
local CombatState = {
    CurrentTarget = nil,
    LastAttack = 0,
    LastAimbotUpdate = 0,
    AttackCooldown = 0.15,
    TargetHistory = {},
    AimbotTarget = nil,
    OriginalCameraCFrame = nil,
    BotCheckCache = {}
}

-- Anti-detection system
local AntiDetection = {
    LastCombatAction = 0,
    CombatActionCooldown = 0.05,
    SuspiciousActions = 0,
    MaxSuspiciousActions = 20,
    RandomDelay = 0.1,
    AttackPattern = {},
    PatternIndex = 1
}

function AntiDetection.SafeCombatAction(action, delay)
    delay = delay or AntiDetection.RandomDelay
    local currentTime = tick()
    
    if currentTime - AntiDetection.LastCombatAction < delay then
        wait(delay - (currentTime - AntiDetection.LastCombatAction))
    end
    
    local success, result = pcall(action)
    AntiDetection.LastCombatAction = currentTime
    
    if not success then
        AntiDetection.SuspiciousActions = AntiDetection.SuspiciousActions + 1
        warn("Bastion Combat: Combat action failed -", result)
        
        if AntiDetection.SuspiciousActions >= AntiDetection.MaxSuspiciousActions then
            warn("Bastion Combat: Too many suspicious actions, disabling temporarily")
            return false
        end
    end
    
    return success, result
end

function Combat.Initialize()
    -- Setup character added event
    LocalPlayer.CharacterAdded:Connect(function(char)
        wait(1) -- Wait for character to fully load
        Combat.RefreshCombatState()
    end)
    
    print("Bastion Combat initialized")
end

function Combat.Update()
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    -- Update current target
    Combat.UpdateTarget(character)
    
    -- KillAura
    if Settings.KillAura_Enabled then
        Combat.HandleKillAura(character)
    end
    
    -- Aimbot
    if Settings.Aimbot_Enabled then
        Combat.HandleAimbot(character)
    end
    
    -- Criticals
    if Settings.Criticals_Enabled then
        Combat.HandleCriticals(humanoid)
    end
    
    -- Reach
    if Settings.Reach_Enabled then
        Combat.HandleReach(character)
    end
    
    -- Velocity
    if Settings.Velocity_Enabled then
        Combat.HandleVelocity(rootPart)
    end
    
    -- AutoClicker
    if Settings.AutoClicker_Enabled then
        Combat.HandleAutoClicker()
    end
    
    -- Update combat state
    Combat.UpdateCombatState(character)
end

function Combat.UpdateTarget(character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local bestTarget = nil
    local bestScore = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local score = Combat.GetTargetScore(player, rootPart.Position)
            
            if score < bestScore then
                bestScore = score
                bestTarget = player
            end
        end
    end
    
    -- Check NPCs if enabled
    if Settings.TargetNpcs_Enabled then
        for _, npc in pairs(Workspace:GetDescendants()) do
            if npc:IsA("Model") and npc:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(npc) then
                local score = Combat.GetNPCTargetScore(npc, rootPart.Position)
                
                if score < bestScore then
                    bestScore = score
                    bestTarget = npc
                end
            end
        end
    end
    
    CombatState.CurrentTarget = bestTarget
end

function Combat.GetTargetScore(player, fromPosition)
    local character = player.Character
    if not character then return math.huge end
    
    -- Anti-bot checks
    if Settings.AntiBot_Enabled and Combat.IsBot(character) then
        return math.huge
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return math.huge end
    
    -- Team check
    if not Settings.TargetTeams_Enabled and player.Team == LocalPlayer.Team then
        return math.huge
    end
    
    -- Friend check
    if not Settings.TargetFriends_Enabled and Combat.IsFriend(player) then
        return math.huge
    end
    
    -- Invisible check
    if not Settings.TargetInvisible_Enabled and humanoid.Health <= 0 then
        return math.huge
    end
    
    -- Distance calculation
    local distance = (fromPosition - rootPart.Position).Magnitude
    if distance > Settings.KillAura_Range then
        return math.huge
    end
    
    -- Calculate score based on priority
    local score = 0
    
    if Settings.Aimbot_Priority == "Distance" then
        score = distance
    elseif Settings.Aimbot_Priority == "Health" then
        score = humanoid.Health / humanoid.MaxHealth
    elseif Settings.Aimbot_Priority == "Angle" then
        local lookVector = Camera.CFrame.LookVector
        local toTarget = (rootPart.Position - Camera.CFrame.Position).Unit
        local angle = math.acos(math.clamp(lookVector:Dot(toTarget), -1, 1))
        score = angle
    end
    
    return score
end

function Combat.GetNPCTargetScore(npc, fromPosition)
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    local rootPart = npc:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return math.huge end
    
    local distance = (fromPosition - rootPart.Position).Magnitude
    if distance > Settings.KillAura_Range then return math.huge end
    
    return distance
end

function Combat.IsBot(character)
    if not Settings.AntiBot_Enabled then return false end
    
    local characterName = character.Name
    if CombatState.BotCheckCache[characterName] ~= nil then
        return CombatState.BotCheckCache[characterName]
    end
    
    local isBot = false
    
    for _, check in pairs(Settings.AntiBot_Checks) do
        if check == "InvalidHealth" then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and (humanoid.Health <= 0 or humanoid.Health > 100) then
                isBot = true
                break
            end
        elseif check == "InvalidPosition" then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart and (rootPart.Position.Y < -1000 or rootPart.Position.Y > 10000) then
                isBot = true
                break
            end
        elseif check == "NoHumanoid" then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then
                isBot = true
                break
            end
        elseif check == "SameTeam" then
            local player = Players:GetPlayerFromCharacter(character)
            if player and player.Team == LocalPlayer.Team then
                isBot = true
                break
            end
        end
    end
    
    CombatState.BotCheckCache[characterName] = isBot
    return isBot
end

function Combat.IsFriend(player)
    -- This would need to be adapted based on the specific game's friend system
    return false -- Simplified for now
end

function Combat.HandleKillAura(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    local currentTime = tick()
    if currentTime - CombatState.LastAttack < CombatState.AttackCooldown then return end
    
    local targets = Combat.GetTargetsInRange(rootPart.Position, Settings.KillAura_Range)
    
    if #targets > 0 then
        if Settings.KillAura_Mode == "Single" then
            Combat.AttackTarget(targets[1], character)
        elseif Settings.KillAura_Mode == "Multi" then
            for _, target in pairs(targets) do
                Combat.AttackTarget(target, character)
            end
        elseif Settings.KillAura_Mode == "Switch" then
            local target = targets[1]
            if target ~= CombatState.CurrentTarget then
                Combat.AttackTarget(target, character)
            end
        end
        
        -- Handle rotation
        if Settings.KillAura_Rotation then
            Combat.HandleKillAuraRotation(targets[1], rootPart)
        end
        
        CombatState.LastAttack = currentTime
    end
end

function Combat.HandleAimbot(character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local target = CombatState.CurrentTarget
    if not target then return end
    
    local targetCharacter = target.Character or target
    local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    
    if not targetHumanoid or not targetRootPart then return end
    
    local currentTime = tick()
    if currentTime - CombatState.LastAimbotUpdate < 0.016 then return end -- 60 FPS limit
    
    local aimPosition = Combat.GetAimPosition(targetCharacter)
    
    if Settings.Aimbot_Mode == "Silent" then
        Combat.HandleSilentAim(aimPosition)
    elseif Settings.Aimbot_Mode == "Lock" then
        Combat.HandleLockAim(aimPosition, rootPart)
    elseif Settings.Aimbot_Mode == "Smooth" then
        Combat.HandleSmoothAim(aimPosition, rootPart)
    end
    
    CombatState.LastAimbotUpdate = currentTime
end

function Combat.HandleCriticals(humanoid)
    if Settings.Criticals_Mode == "Jump" then
        -- Jump criticals
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Jumping then
            -- Apply critical damage
            humanoid.JumpPower = humanoid.JumpPower * 1.5
            wait(0.1)
            humanoid.JumpPower = humanoid.JumpPower / 1.5
        end
    elseif Settings.Criticals_Mode == "Packet" then
        -- Packet criticals (would need game-specific implementation)
        -- This is a placeholder for packet manipulation
    end
end

function Combat.HandleReach(character)
    -- This would need to be adapted based on the specific game's reach system
    -- For now, we'll simulate it by adjusting attack range
    CombatState.AttackCooldown = 0.15 / Settings.Reach_Multiplier
end

function Combat.HandleVelocity(rootPart)
    local target = CombatState.CurrentTarget
    if not target then return end
    
    local targetCharacter = target.Character or target
    local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    
    if not targetRootPart then return end
    
    local direction = (targetRootPart.Position - rootPart.Position).Unit
    local velocity = Vector3.new(
        direction.X * Settings.Velocity_Horizontal,
        Settings.Velocity_Vertical,
        direction.Z * Settings.Velocity_Horizontal
    )
    
    AntiDetection.SafeCombatAction(function()
        rootPart.Velocity = velocity
    end, 0.1)
end

function Combat.HandleAutoClicker()
    local mouse = LocalPlayer:GetMouse()
    local clickInterval = 1 / Settings.AutoClicker_CPS
    
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        if tick() - CombatState.LastAttack >= clickInterval then
            mouse:Click()
            CombatState.LastAttack = tick()
            
            -- Add jitter if enabled
            if Settings.AutoClicker_Jitter then
                local jitter = Vector3.new(
                    math.random(-2, 2),
                    math.random(-2, 2),
                    0
                )
                mouse.TargetFilter = nil
                Camera:CFrame = Camera:CFrame * CFrame.new(jitter * 0.1)
            end
        end
    end
end

function Combat.HandleKillAuraRotation(target, rootPart)
    local targetCharacter = target.Character or target
    local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    
    if not targetRootPart then return end
    
    local lookAtCFrame = CFrame.lookAt(rootPart.Position, targetRootPart.Position)
    
    AntiDetection.SafeCombatAction(function()
        rootPart.CFrame = rootPart.CFrame:Lerp(lookAtCFrame, Settings.KillAura_RotationSpeed * 0.01)
    end, 0.05)
end

function Combat.GetTargetsInRange(position, range)
    local targets = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character then
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local distance = (position - rootPart.Position).Magnitude
                    if distance <= range then
                        table.insert(targets, player)
                    end
                end
            end
        end
    end
    
    return targets
end

function Combat.AttackTarget(target, attacker)
    local targetCharacter = target.Character or target
    local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    
    if not targetHumanoid then return end
    
    AntiDetection.SafeCombatAction(function()
        -- This would need to be adapted based on the specific game's combat system
        for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") and remote.Name:lower():find("hit") or remote.Name:lower():find("attack") then
                remote:FireServer(targetCharacter)
                break
            end
        end
    end, Settings.KillAura_Delay)
end

function Combat.GetAimPosition(targetCharacter)
    local rootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    local head = targetCharacter:FindFirstChild("Head")
    
    if Settings.Aimbot_AimAt == "Head" and head then
        return head.Position
    elseif Settings.Aimbot_AimAt == "Body" and rootPart then
        return rootPart.Position
    else -- Nearest
        local cameraPosition = Camera.CFrame.Position
        local nearestPart = nil
        local nearestDistance = math.huge
        
        for _, part in pairs(targetCharacter:GetChildren()) do
            if part:IsA("BasePart") then
                local distance = (cameraPosition - part.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestPart = part
                end
            end
        end
        
        return nearestPart and nearestPart.Position or rootPart.Position
    end
end

function Combat.HandleSilentAim(aimPosition)
    -- Silent aim - modify camera without actual movement
    local lookAtCFrame = CFrame.lookAt(Camera.CFrame.Position, aimPosition)
    CombatState.OriginalCameraCFrame = Camera.CFrame
    
    -- This would need to be adapted based on the specific game's aim system
    Camera:CFrame = lookAtCFrame
    wait(0.016) -- One frame
    if CombatState.OriginalCameraCFrame then
        Camera:CFrame = CombatState.OriginalCameraCFrame
    end
end

function Combat.HandleLockAim(aimPosition, rootPart)
    -- Lock aim - direct camera control
    local lookAtCFrame = CFrame.lookAt(rootPart.Position, aimPosition)
    
    AntiDetection.SafeCombatAction(function()
        Camera:CFrame = lookAtCFrame
    end, 0.016)
end

function Combat.HandleSmoothAim(aimPosition, rootPart)
    -- Smooth aim - gradual camera movement
    local lookAtCFrame = CFrame.lookAt(rootPart.Position, aimPosition)
    local smoothFactor = Settings.Aimbot_Smoothness * 0.01
    
    AntiDetection.SafeCombatAction(function()
        Camera:CFrame = Camera:CFrame:Lerp(lookAtCFrame, smoothFactor)
    end, 0.016)
end

function Combat.UpdateCombatState(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Update attack pattern for anti-detection
    local currentPattern = {
        Time = tick(),
        Health = humanoid.Health,
        Position = character.HumanoidRootPart.Position
    }
    
    table.insert(CombatState.AttackPattern, currentPattern)
    if #CombatState.AttackPattern > 10 then
        table.remove(CombatState.AttackPattern, 1)
    end
    
    -- Clean up bot check cache periodically
    if tick() % 30 < 0.1 then -- Every 30 seconds
        CombatState.BotCheckCache = {}
    end
end

function Combat.RefreshCombatState()
    CombatState.CurrentTarget = nil
    CombatState.LastAttack = 0
    CombatState.LastAimbotUpdate = 0
    CombatState.AimbotTarget = nil
    CombatState.BotCheckCache = {}
end

-- Settings functions
function Combat.SetKillAuraEnabled(state)
    Settings.KillAura_Enabled = state
end

function Combat.SetAttackRange(range)
    Settings.KillAura_Range = range
end

function Combat.SetAimbotEnabled(state)
    Settings.Aimbot_Enabled = state
    if not state then
        CombatState.AimbotTarget = nil
    end
end

function Combat.SetAimbotSmoothness(smoothness)
    Settings.Aimbot_Smoothness = smoothness
end

function Combat.SetTargetPlayers(state)
    Settings.TargetPlayers_Enabled = state
end

function Combat.SetTargetTeams(state)
    Settings.TargetTeams_Enabled = state
end

function Combat.SetCriticalsEnabled(state)
    Settings.Criticals_Enabled = state
end

function Combat.SetReachEnabled(state)
    Settings.Reach_Enabled = state
end

function Combat.SetVelocityEnabled(state)
    Settings.Velocity_Enabled = state
end

function Combat.SetAutoClickerEnabled(state)
    Settings.AutoClicker_Enabled = state
end

function Combat.SetAntiBotEnabled(state)
    Settings.AntiBot_Enabled = state
end

-- Cleanup function
function Combat.Cleanup()
    Combat.RefreshCombatState()
    
    -- Restore camera if modified
    if CombatState.OriginalCameraCFrame then
        Camera:CFrame = CombatState.OriginalCameraCFrame
    end
end

-- Initialize the module
Combat.Initialize()

return Combat
