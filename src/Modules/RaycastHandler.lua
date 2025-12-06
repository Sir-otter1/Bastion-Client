-- Bastion Client Raycast Handler
-- Advanced raycast detection and anti-cheat compatibility system

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

local RaycastHandler = {}

-- Raycast settings
local Settings = {
    SafeRaycast_Enabled = true,
    RaycastCooldown = 0.1,
    MaxRaycastsPerSecond = 10,
    AntiDetection_Enabled = true,
    RandomizeTiming = true,
    RandomDelayRange = {0.05, 0.15},
    
    -- Detection thresholds
    SuspiciousRaycastCount = 5,
    SuspiciousRaycastWindow = 2, -- seconds
    MaxSuspiciousActions = 15,
    
    -- Raycast filters
    FilterLocalPlayer = true,
    FilterTeammates = true,
    FilterInvisible = false,
    FilterBots = true,
    
    -- Anti-cheat simulation
    SimulateHumanBehavior = true,
    HumanErrorRate = 0.1, -- 10% chance of "human error"
    ReactionTimeRange = {0.1, 0.3}
}

-- Raycast state tracking
local RaycastState = {
    RaycastHistory = {},
    SuspiciousRays = 0,
    LastRaycast = 0,
    RaycastsPerSecond = 0,
    TotalRaycasts = 0,
    BlockedRaycasts = 0,
    DetectionScore = 0,
    LastCleanup = tick()
}

-- Anti-cheat detection patterns
local DetectionPatterns = {
    -- Common anti-cheat detection methods
    HighFrequencyRaycasts = {
        Threshold = 20,
        Window = 1,
        Penalty = 10
    },
    PerfectAiming = {
        Threshold = 0.95, -- Accuracy threshold
        Window = 5,
        Penalty = 15
    },
    ImpossibleAngles = {
        Threshold = 170, -- Max angle in degrees
        Penalty = 20
    },
    ConsistentTiming = {
        Threshold = 0.05, -- Timing variance threshold
        Window = 3,
        Penalty = 8
    }
}

-- Human behavior simulation
local HumanBehavior = {
    LastMousePosition = nil,
    MouseMovementHistory = {},
    ReactionTimes = {},
    ErrorPatterns = {},
    CurrentStress = 0
}

function RaycastHandler.Initialize()
    -- Setup monitoring
    RunService.Heartbeat:Connect(function()
        RaycastHandler.UpdateDetectionScore()
        RaycastHandler.CleanupOldData()
    end)
    
    print("Bastion Raycast Handler initialized")
end

function RaycastHandler.SafeRaycast(origin, direction, distance, params)
    if not Settings.SafeRaycast_Enabled then
        return Workspace:Raycast(origin, direction, distance, params)
    end
    
    local currentTime = tick()
    
    -- Check cooldown
    if currentTime - RaycastState.LastRaycast < Settings.RaycastCooldown then
        RaycastState.BlockedRaycasts = RaycastState.BlockedRaycasts + 1
        return nil
    end
    
    -- Check rate limit
    if RaycastState.RaycastsPerSecond >= Settings.MaxRaycastsPerSecond then
        RaycastState.BlockedRaycasts = RaycastState.BlockedRaycasts + 1
        return nil
    end
    
    -- Anti-detection checks
    if Settings.AntiDetection_Enabled then
        local suspicious = RaycastHandler.CheckSuspiciousPatterns(origin, direction)
        if suspicious then
            RaycastState.SuspiciousRays = RaycastState.SuspiciousRays + 1
            if RaycastState.SuspiciousRays >= Settings.SuspiciousRaycastCount then
                warn("Bastion Raycast: Too many suspicious raycasts, blocking temporarily")
                return nil
            end
        end
    end
    
    -- Apply random delay if enabled
    if Settings.RandomizeTiming then
        local randomDelay = math.random(
            Settings.RandomDelayRange[1] * 1000,
            Settings.RandomDelayRange[2] * 1000
        ) / 1000
        
        wait(randomDelay)
    end
    
    -- Prepare raycast parameters
    local raycastParams = params or RaycastParams.new()
    
    -- Apply filters
    if Settings.FilterLocalPlayer and LocalPlayer.Character then
        local filterDescendants = raycastParams.FilterDescendantsInstances or {}
        table.insert(filterDescendants, LocalPlayer.Character)
        raycastParams.FilterDescendantsInstances = filterDescendants
    end
    
    if Settings.FilterTeammates then
        local filterDescendants = raycastParams.FilterDescendantsInstances or {}
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Team == LocalPlayer.Team and player.Character then
                table.insert(filterDescendants, player.Character)
            end
        end
        raycastParams.FilterDescendantsInstances = filterDescendants
    end
    
    -- Perform raycast
    local result = Workspace:Raycast(origin, direction, distance, raycastParams)
    
    -- Update tracking
    RaycastHandler.UpdateRaycastHistory(origin, direction, result, currentTime)
    
    -- Simulate human behavior if enabled
    if Settings.SimulateHumanBehavior and result then
        RaycastHandler.SimulateHumanError(result)
    end
    
    RaycastState.LastRaycast = currentTime
    RaycastState.TotalRaycasts = RaycastState.TotalRaycasts + 1
    
    return result
end

function RaycastHandler.SafeWorldToViewportPoint(worldPosition)
    if not Settings.SafeRaycast_Enabled then
        return workspace.CurrentCamera:WorldToViewportPoint(worldPosition)
    end
    
    -- Add small random offset to simulate human imperfection
    if Settings.SimulateHumanBehavior and math.random() < Settings.HumanErrorRate then
        local offset = Vector3.new(
            math.random(-2, 2),
            math.random(-2, 2),
            0
        )
        worldPosition = worldPosition + offset
    end
    
    return workspace.CurrentCamera:WorldToViewportPoint(worldPosition)
end

function RaycastHandler.SafeFindPartOnRay(ray, params)
    if not Settings.SafeRaycast_Enabled then
        return Workspace:FindPartOnRay(ray, params)
    end
    
    local origin = ray.Origin
    local direction = ray.Direction
    local distance = direction.Magnitude
    
    return RaycastHandler.SafeRaycast(origin, direction, distance, params)
end

function RaycastHandler.CheckSuspiciousPatterns(origin, direction)
    local currentTime = tick()
    
    -- Check high frequency raycasts
    local recentRaycasts = 0
    for _, raycast in pairs(RaycastState.RaycastHistory) do
        if currentTime - raycast.Time < DetectionPatterns.HighFrequencyRaycasts.Window then
            recentRaycasts = recentRaycasts + 1
        end
    end
    
    if recentRaycasts >= DetectionPatterns.HighFrequencyRaycasts.Threshold then
        RaycastState.DetectionScore = RaycastState.DetectionScore + DetectionPatterns.HighFrequencyRaycasts.Penalty
        return true
    end
    
    -- Check impossible angles
    local lookVector = workspace.CurrentCamera.CFrame.LookVector
    local rayDirection = direction.Unit
    local angle = math.deg(math.acos(math.clamp(lookVector:Dot(rayDirection), -1, 1)))
    
    if angle > DetectionPatterns.ImpossibleAngles.Threshold then
        RaycastState.DetectionScore = RaycastState.DetectionScore + DetectionPatterns.ImpossibleAngles.Penalty
        return true
    end
    
    -- Check consistent timing
    local timingVariance = RaycastHandler.CalculateTimingVariance()
    if timingVariance < DetectionPatterns.ConsistentTiming.Threshold then
        RaycastState.DetectionScore = RaycastState.DetectionScore + DetectionPatterns.ConsistentTiming.Penalty
        return true
    end
    
    return false
end

function RaycastHandler.UpdateRaycastHistory(origin, direction, result, time)
    local raycastData = {
        Origin = origin,
        Direction = direction,
        Result = result,
        Time = time,
        Success = result ~= nil
    }
    
    table.insert(RaycastState.RaycastHistory, raycastData)
    
    -- Limit history size
    if #RaycastState.RaycastHistory > 100 then
        table.remove(RaycastState.RaycastHistory, 1)
    end
end

function RaycastHandler.CalculateTimingVariance()
    if #RaycastState.RaycastHistory < 2 then return 1 end
    
    local intervals = {}
    for i = 2, #RaycastState.RaycastHistory do
        local interval = RaycastState.RaycastHistory[i].Time - RaycastState.RaycastHistory[i-1].Time
        table.insert(intervals, interval)
    end
    
    local mean = 0
    for _, interval in pairs(intervals) do
        mean = mean + interval
    end
    mean = mean / #intervals
    
    local variance = 0
    for _, interval in pairs(intervals) do
        variance = variance + (interval - mean) ^ 2
    end
    variance = variance / #intervals
    
    return math.sqrt(variance)
end

function RaycastHandler.SimulateHumanError(result)
    if not result.Instance then return end
    
    -- Simulate human reaction time
    local reactionTime = math.random(
        Settings.ReactionTimeRange[1] * 1000,
        Settings.ReactionTimeRange[2] * 1000
    ) / 1000
    
    -- Add small position error occasionally
    if math.random() < Settings.HumanErrorRate then
        local errorOffset = Vector3.new(
            math.random(-1, 1) * 0.1,
            math.random(-1, 1) * 0.1,
            math.random(-1, 1) * 0.1
        )
        result.Position = result.Position + errorOffset
    end
    
    -- Update stress level based on situation
    RaycastHandler.UpdateStressLevel(result)
end

function RaycastHandler.UpdateStressLevel(result)
    local stressIncrease = 0
    
    -- Increase stress for hitting players
    if result.Instance and result.Instance.Parent:FindFirstChildOfClass("Humanoid") then
        stressIncrease = stressIncrease + 2
    end
    
    -- Increase stress for long distances
    if result.Distance and result.Distance > 50 then
        stressIncrease = stressIncrease + 1
    end
    
    HumanBehavior.CurrentStress = math.clamp(
        HumanBehavior.CurrentStress + stressIncrease,
        0,
        100
    )
    
    -- Decay stress over time
    HumanBehavior.CurrentStress = HumanBehavior.CurrentStress * 0.99
end

function RaycastHandler.UpdateDetectionScore()
    local currentTime = tick()
    
    -- Calculate raycasts per second
    local recentRaycasts = 0
    for _, raycast in pairs(RaycastState.RaycastHistory) do
        if currentTime - raycast.Time < 1 then
            recentRaycasts = recentRaycasts + 1
        end
    end
    
    RaycastState.RaycastsPerSecond = recentRaycasts
    
    -- Decay detection score over time
    RaycastState.DetectionScore = RaycastState.DetectionScore * 0.98
    
    -- Reset suspicious rays if score is low
    if RaycastState.DetectionScore < 10 then
        RaycastState.SuspiciousRays = 0
    end
end

function RaycastHandler.CleanupOldData()
    local currentTime = tick()
    
    -- Clean up old raycast history
    if currentTime - RaycastState.LastCleanup > 60 then -- Every minute
        local cutoffTime = currentTime - 300 -- Keep last 5 minutes
        
        for i = #RaycastState.RaycastHistory, 1, -1 do
            if RaycastState.RaycastHistory[i].Time < cutoffTime then
                table.remove(RaycastState.RaycastHistory, i)
            end
        end
        
        RaycastState.LastCleanup = currentTime
    end
end

function RaycastHandler.IsSuspiciousActivity()
    return RaycastState.DetectionScore > 50 or RaycastState.SuspiciousRays >= Settings.SuspiciousRaycastCount
end

function RaycastHandler.GetDetectionLevel()
    if RaycastState.DetectionScore < 20 then
        return "Low"
    elseif RaycastState.DetectionScore < 50 then
        return "Medium"
    elseif RaycastState.DetectionScore < 80 then
        return "High"
    else
        return "Critical"
    end
end

function RaycastHandler.GetStatistics()
    return {
        TotalRaycasts = RaycastState.TotalRaycasts,
        BlockedRaycasts = RaycastState.BlockedRaycasts,
        RaycastsPerSecond = RaycastState.RaycastsPerSecond,
        DetectionScore = RaycastState.DetectionScore,
        SuspiciousRays = RaycastState.SuspiciousRays,
        DetectionLevel = RaycastHandler.GetDetectionLevel(),
        StressLevel = HumanBehavior.CurrentStress
    }
end

function RaycastHandler.ResetDetection()
    RaycastState.DetectionScore = 0
    RaycastState.SuspiciousRays = 0
    RaycastState.RaycastHistory = {}
    HumanBehavior.CurrentStress = 0
end

-- Advanced raycast functions
function RaycastHandler.MultiRaycast(origins, directions, distances, params)
    local results = {}
    
    for i, origin in pairs(origins) do
        local direction = directions[i]
        local distance = distances[i]
        
        local result = RaycastHandler.SafeRaycast(origin, direction, distance, params)
        table.insert(results, result)
        
        -- Add small delay between raycasts
        if i < #origins then
            wait(Settings.RandomDelayRange[1])
        end
    end
    
    return results
end

function RaycastHandler.SphereCast(origin, radius, direction, distance, params)
    -- Perform multiple raycasts in a sphere pattern
    local results = {}
    local rayCount = 8
    
    for i = 1, rayCount do
        local angle = (i / rayCount) * math.pi * 2
        local offset = Vector3.new(
            math.cos(angle) * radius,
            0,
            math.sin(angle) * radius
        )
        
        local rayOrigin = origin + offset
        local result = RaycastHandler.SafeRaycast(rayOrigin, direction, distance, params)
        
        if result then
            table.insert(results, result)
        end
    end
    
    -- Return the closest result
    local closestResult = nil
    local closestDistance = distance
    
    for _, result in pairs(results) do
        if result.Distance < closestDistance then
            closestDistance = result.Distance
            closestResult = result
        end
    end
    
    return closestResult
end

function RaycastHandler.AnticipatoryRaycast(target, predictionTime)
    -- Predict target movement and raycast to future position
    if not target or not target.PrimaryPart then return nil end
    
    local currentVelocity = target.PrimaryPart.Velocity
    local predictedPosition = target.PrimaryPart.Position + (currentVelocity * predictionTime)
    
    local origin = workspace.CurrentCamera.CFrame.Position
    local direction = (predictedPosition - origin).Unit
    local distance = (predictedPosition - origin).Magnitude
    
    return RaycastHandler.SafeRaycast(origin, direction, distance)
end

-- Settings functions
function RaycastHandler.SetSafeRaycastEnabled(state)
    Settings.SafeRaycast_Enabled = state
end

function RaycastHandler.SetRaycastCooldown(cooldown)
    Settings.RaycastCooldown = cooldown
end

function RaycastHandler.SetAntiDetectionEnabled(state)
    Settings.AntiDetection_Enabled = state
end

function RaycastHandler.SetMaxRaycastsPerSecond(maxRPS)
    Settings.MaxRaycastsPerSecond = maxRPS
end

function RaycastHandler.SetFilterLocalPlayer(state)
    Settings.FilterLocalPlayer = state
end

function RaycastHandler.SetFilterTeammates(state)
    Settings.FilterTeammates = state
end

function RaycastHandler.SetSimulateHumanBehavior(state)
    Settings.SimulateHumanBehavior = state
end

function RaycastHandler.SetHumanErrorRate(rate)
    Settings.HumanErrorRate = math.clamp(rate, 0, 1)
end

-- Cleanup function
function RaycastHandler.Cleanup()
    RaycastHandler.ResetDetection()
    RaycastState = {
        RaycastHistory = {},
        SuspiciousRays = 0,
        LastRaycast = 0,
        RaycastsPerSecond = 0,
        TotalRaycasts = 0,
        BlockedRaycasts = 0,
        DetectionScore = 0,
        LastCleanup = tick()
    }
    HumanBehavior = {
        LastMousePosition = nil,
        MouseMovementHistory = {},
        ReactionTimes = {},
        ErrorPatterns = {},
        CurrentStress = 0
    }
end

-- Initialize the module
RaycastHandler.Initialize()

return RaycastHandler
