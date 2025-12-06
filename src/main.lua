-- Bastion Client - Roblox Bedwars Client
-- Main Entry Point

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Wait for player to load
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- Anti-detection system
local AntiDetection = {
    RandomDelay = 0.1,
    LastAction = tick(),
    SuspiciousActions = 0,
    MaxSuspiciousActions = 10
}

function AntiDetection.SafeAction(action, delay)
    delay = delay or AntiDetection.RandomDelay
    local currentTime = tick()
    
    if currentTime - AntiDetection.LastAction < delay then
        wait(delay - (currentTime - AntiDetection.LastAction))
    end
    
    local success, result = pcall(action)
    AntiDetection.LastAction = tick()
    
    if not success then
        AntiDetection.SuspiciousActions = AntiDetection.SuspiciousActions + 1
        warn("Bastion Client: Action failed -", result)
        
        if AntiDetection.SuspiciousActions >= AntiDetection.MaxSuspiciousActions then
            warn("Bastion Client: Too many suspicious actions, disabling temporarily")
            return false
        end
    end
    
    return success, result
end

-- Module loader
local Modules = {}

function Modules.LoadModule(moduleName, modulePath)
    local success, module = pcall(function()
        return require(modulePath)
    end)
    
    if success then
        Modules[moduleName] = module
        print("Bastion Client: Loaded module -", moduleName)
        return true
    else
        warn("Bastion Client: Failed to load module -", moduleName, "-", module)
        return false
    end
end

-- Load all modules
Modules.LoadModule("GUI", script.Parent.GUI)
Modules.LoadModule("Visuals", script.Parent.Modules.Visuals)
Modules.LoadModule("Mobility", script.Parent.Modules.Mobility)
Modules.LoadModule("Utility", script.Parent.Modules.Utility)
Modules.LoadModule("Combat", script.Parent.Modules.Combat)
Modules.LoadModule("RaycastHandler", script.Parent.Modules.RaycastHandler)

-- Initialize modules
if Modules.GUI then
    Modules.GUI.Initialize()
end

-- Main update loop
RunService.Heartbeat:Connect(function()
    -- Update all active modules
    for name, module in pairs(Modules) do
        if module.Update and type(module.Update) == "function" then
            AntiDetection.SafeAction(function()
                module.Update()
            end, 0.05)
        end
    end
end)

-- Cleanup on disconnect
LocalPlayer.CharacterRemoving:Connect(function()
    for name, module in pairs(Modules) do
        if module.Cleanup and type(module.Cleanup) == "function" then
            pcall(module.Cleanup)
        end
    end
end)

print("Bastion Client initialized successfully!")
print("Press INSERT to toggle GUI")
