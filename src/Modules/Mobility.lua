-- Bastion Client Mobility Module
-- Speed, Flight, NoFall, and other movement enhancements

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ContextActionService = game:GetService("ContextActionService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Mobility = {}

-- Mobility settings
local Settings = {
    Speed_Enabled = false,
    Speed_Multiplier = 1.5,
    Speed_Mode = "Normal", -- "Normal", "Bhop", "Strafe"
    
    Flight_Enabled = false,
    Flight_Speed = 5,
    Flight_Mode = "Normal", -- "Normal", "Jetpack", "Glide"
    Flight_VerticalSpeed = 3,
    
    NoFall_Enabled = false,
    NoFall_Mode = "Cancel", -- "Cancel", "Fake"
    
    HighJump_Enabled = false,
    HighJump_Multiplier = 1.5,
    
    NoClip_Enabled = false,
    NoClip_Mode = "Partial", -- "Partial", "Full"
    
    AntiKnockback_Enabled = false,
    AntiKnockback_Percentage = 80
}

-- Movement state tracking
local MovementState = {
    OriginalWalkSpeed = 16,
    OriginalJumpPower = 50,
    OriginalGravity = Workspace.Gravity,
    IsFlying = false,
    IsNoClipping = false,
    LastGrounded = tick(),
    VelocityHistory = {},
    InputHistory = {}
}

-- Anti-detection system
local AntiDetection = {
    LastSpeedChange = 0,
    SpeedChangeCooldown = 0.5,
    SuspiciousMovements = 0,
    MaxSuspiciousMovements = 10,
    RandomDelay = 0.1
}

function AntiDetection.SafeMovement(action, delay)
    delay = delay or AntiDetection.RandomDelay
    local currentTime = tick()
    
    if currentTime - AntiDetection.LastSpeedChange < delay then
        wait(delay - (currentTime - AntiDetection.LastSpeedChange))
    end
    
    local success, result = pcall(action)
    AntiDetection.LastSpeedChange = currentTime
    
    if not success then
        AntiDetection.SuspiciousMovements = AntiDetection.SuspiciousMovements + 1
        warn("Bastion Mobility: Movement action failed -", result)
        
        if AntiDetection.SuspiciousMovements >= AntiDetection.MaxSuspiciousMovements then
            warn("Bastion Mobility: Too many suspicious movements, disabling temporarily")
            return false
        end
    end
    
    return success, result
end

function Mobility.Initialize()
    -- Store original values
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            MovementState.OriginalWalkSpeed = humanoid.WalkSpeed
            MovementState.OriginalJumpPower = humanoid.JumpPower
        end
    end
    
    -- Setup character added event
    LocalPlayer.CharacterAdded:Connect(function(char)
        wait(1) -- Wait for character to fully load
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            MovementState.OriginalWalkSpeed = humanoid.WalkSpeed
            MovementState.OriginalJumpPower = humanoid.JumpPower
        end
    end)
    
    print("Bastion Mobility initialized")
end

function Mobility.Update()
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    -- Speed hack
    if Settings.Speed_Enabled then
        Mobility.HandleSpeed(humanoid, rootPart)
    end
    
    -- Flight
    if Settings.Flight_Enabled then
        Mobility.HandleFlight(rootPart)
    end
    
    -- No fall damage
    if Settings.NoFall_Enabled then
        Mobility.HandleNoFall(humanoid, rootPart)
    end
    
    -- High jump
    if Settings.HighJump_Enabled then
        Mobility.HandleHighJump(humanoid)
    end
    
    -- No clip
    if Settings.NoClip_Enabled then
        Mobility.HandleNoClip(character)
    end
    
    -- Anti knockback
    if Settings.AntiKnockback_Enabled then
        Mobility.HandleAntiKnockback(rootPart)
    end
    
    -- Update movement state
    Mobility.UpdateMovementState(character, humanoid)
end

function Mobility.HandleSpeed(humanoid, rootPart)
    local targetSpeed = MovementState.OriginalWalkSpeed * Settings.Speed_Multiplier
    
    if Settings.Speed_Mode == "Normal" then
        AntiDetection.SafeMovement(function()
            humanoid.WalkSpeed = targetSpeed
        end, 0.2)
        
    elseif Settings.Speed_Mode == "Bhop" then
        -- Bunny hop style speed
        humanoid.WalkSpeed = targetSpeed
        
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                humanoid.JumpPower = MovementState.OriginalJumpPower * 1.2
            end
        else
            humanoid.JumpPower = MovementState.OriginalJumpPower
        end
        
    elseif Settings.Speed_Mode == "Strafe" then
        -- Strafe speed boost
        humanoid.WalkSpeed = targetSpeed
        
        local moveDirection = humanoid.MoveDirection
        if moveDirection.Magnitude > 0 then
            local cameraForward = Camera.CFrame.LookVector
            local dotProduct = moveDirection:Dot(cameraForward)
            
            if math.abs(dotProduct) < 0.5 then -- Strafing
                humanoid.WalkSpeed = targetSpeed * 1.2
            end
        end
    end
end

function Mobility.HandleFlight(rootPart)
    if Settings.Flight_Mode == "Normal" then
        -- Normal flight mode
        local flyVelocity = Vector3.new(0, 0, 0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            flyVelocity = flyVelocity + Camera.CFrame.LookVector * Settings.Flight_Speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            flyVelocity = flyVelocity - Camera.CFrame.LookVector * Settings.Flight_Speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            flyVelocity = flyVelocity - Camera.CFrame.RightVector * Settings.Flight_Speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            flyVelocity = flyVelocity + Camera.CFrame.RightVector * Settings.Flight_Speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            flyVelocity = flyVelocity + Vector3.new(0, Settings.Flight_VerticalSpeed, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            flyVelocity = flyVelocity - Vector3.new(0, Settings.Flight_VerticalSpeed, 0)
        end
        
        AntiDetection.SafeMovement(function()
            rootPart.Velocity = flyVelocity
        end, 0.05)
        
    elseif Settings.Flight_Mode == "Jetpack" then
        -- Jetpack mode - only when holding space
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            local jetpackVelocity = Vector3.new(0, Settings.Flight_VerticalSpeed * 1.5, 0)
            
            -- Add horizontal movement based on look direction
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                jetpackVelocity = jetpackVelocity + Camera.CFrame.LookVector * Settings.Flight_Speed * 0.5
            end
            
            AntiDetection.SafeMovement(function()
                rootPart.Velocity = rootPart.Velocity + jetpackVelocity * 0.1
            end, 0.05)
        end
        
    elseif Settings.Flight_Mode == "Glide" then
        -- Glide mode - slow fall with horizontal control
        local currentVelocity = rootPart.Velocity
        
        if currentVelocity.Y < 0 then -- Falling
            local glideVelocity = Vector3.new(
                currentVelocity.X * 0.95, -- Slight horizontal damping
                -2, -- Slow fall
                currentVelocity.Z * 0.95
            )
            
            -- Add horizontal control
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                glideVelocity = glideVelocity + Camera.CFrame.LookVector * Settings.Flight_Speed * 0.3
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                glideVelocity = glideVelocity - Camera.CFrame.LookVector * Settings.Flight_Speed * 0.3
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                glideVelocity = glideVelocity - Camera.CFrame.RightVector * Settings.Flight_Speed * 0.3
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                glideVelocity = glideVelocity + Camera.CFrame.RightVector * Settings.Flight_Speed * 0.3
            end
            
            AntiDetection.SafeMovement(function()
                rootPart.Velocity = glideVelocity
            end, 0.05)
        end
    end
end

function Mobility.HandleNoFall(humanoid, rootPart)
    if Settings.NoFall_Mode == "Cancel" then
        -- Cancel fall damage by resetting velocity before hitting ground
        local currentVelocity = rootPart.Velocity
        
        if currentVelocity.Y < -50 then -- Falling too fast
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
            raycastParams.IgnoreWater = false
            
            local result = Workspace:Raycast(
                rootPart.Position,
                Vector3.new(0, -10, 0),
                raycastParams
            )
            
            if result and result.Distance < 5 then -- Close to ground
                AntiDetection.SafeMovement(function()
                    rootPart.Velocity = Vector3.new(currentVelocity.X, -10, currentVelocity.Z)
                end, 0.1)
            end
        end
        
    elseif Settings.NoFall_Mode == "Fake" then
        -- Fake fall damage by temporarily disabling humanoid state changes
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Freefall then
            -- Check if we're about to hit the ground
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
            raycastParams.IgnoreWater = false
            
            local result = Workspace:Raycast(
                rootPart.Position,
                Vector3.new(0, -5, 0),
                raycastParams
            )
            
            if result and result.Distance < 2 then
                -- Temporarily set state to landed to prevent damage
                AntiDetection.SafeMovement(function()
                    humanoid:ChangeState(Enum.HumanoidStateType.Landed)
                    wait(0.1)
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end, 0.1)
            end
        end
    end
end

function Mobility.HandleHighJump(humanoid)
    local targetJumpPower = MovementState.OriginalJumpPower * Settings.HighJump_Multiplier
    
    AntiDetection.SafeMovement(function()
        humanoid.JumpPower = targetJumpPower
    end, 0.2)
end

function Mobility.HandleNoClip(character)
    if Settings.NoClip_Mode == "Partial" then
        -- Partial no clip - only for certain parts
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = false
            end
        end
        
    elseif Settings.NoClip_Mode == "Full" then
        -- Full no clip - all parts
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

function Mobility.HandleAntiKnockback(rootPart)
    local currentVelocity = rootPart.Velocity
    
    -- Reduce horizontal velocity (knockback)
    local horizontalVelocity = Vector3.new(currentVelocity.X, 0, currentVelocity.Z)
    local reductionAmount = (100 - Settings.AntiKnockback_Percentage) / 100
    
    if horizontalVelocity.Magnitude > 10 then -- Likely knockback
        local reducedVelocity = horizontalVelocity * reductionAmount
        local newVelocity = Vector3.new(reducedVelocity.X, currentVelocity.Y, reducedVelocity.Z)
        
        AntiDetection.SafeMovement(function()
            rootPart.Velocity = newVelocity
        end, 0.05)
    end
end

function Mobility.UpdateMovementState(character, humanoid)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Track velocity history
    table.insert(MovementState.VelocityHistory, rootPart.Velocity)
    if #MovementState.VelocityHistory > 10 then
        table.remove(MovementState.VelocityHistory, 1)
    end
    
    -- Track grounded state
    local state = humanoid:GetState()
    if state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Standing then
        MovementState.LastGrounded = tick()
    end
    
    -- Track input history
    local currentInput = {
        W = UserInputService:IsKeyDown(Enum.KeyCode.W),
        A = UserInputService:IsKeyDown(Enum.KeyCode.A),
        S = UserInputService:IsKeyDown(Enum.KeyCode.S),
        D = UserInputService:IsKeyDown(Enum.KeyCode.D),
        Space = UserInputService:IsKeyDown(Enum.KeyCode.Space),
        Shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    }
    
    table.insert(MovementState.InputHistory, currentInput)
    if #MovementState.InputHistory > 20 then
        table.remove(MovementState.InputHistory, 1)
    end
end

-- Settings functions
function Mobility.SetSpeedEnabled(state)
    Settings.Speed_Enabled = state
    
    if not state then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                AntiDetection.SafeMovement(function()
                    humanoid.WalkSpeed = MovementState.OriginalWalkSpeed
                end, 0.2)
            end
        end
    end
end

function Mobility.SetSpeedMultiplier(multiplier)
    Settings.Speed_Multiplier = multiplier
end

function Mobility.SetFlightEnabled(state)
    Settings.Flight_Enabled = state
    
    if not state then
        MovementState.IsFlying = false
    end
end

function Mobility.SetFlightSpeed(speed)
    Settings.Flight_Speed = speed
end

function Mobility.SetNoFallEnabled(state)
    Settings.NoFall_Enabled = state
end

function Mobility.SetHighJumpEnabled(state)
    Settings.HighJump_Enabled = state
    
    if not state then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                AntiDetection.SafeMovement(function()
                    humanoid.JumpPower = MovementState.OriginalJumpPower
                end, 0.2)
            end
        end
    end
end

function Mobility.SetNoClipEnabled(state)
    Settings.NoClip_Enabled = state
    
    if not state then
        -- Restore collision
        local character = LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

function Mobility.SetAntiKnockbackEnabled(state)
    Settings.AntiKnockback_Enabled = state
end

function Mobility.SetAntiKnockbackPercentage(percentage)
    Settings.AntiKnockback_Percentage = math.clamp(percentage, 0, 100)
end

-- Cleanup function
function Mobility.Cleanup()
    -- Restore original values
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            AntiDetection.SafeMovement(function()
                humanoid.WalkSpeed = MovementState.OriginalWalkSpeed
                humanoid.JumpPower = MovementState.OriginalJumpPower
            end, 0.2)
        end
        
        -- Restore collision
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    
    -- Restore gravity
    Workspace.Gravity = MovementState.OriginalGravity
end

-- Initialize the module
Mobility.Initialize()

return Mobility
