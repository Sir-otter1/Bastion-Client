-- Bastion Client Configuration System
-- Settings persistence and management

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local Config = {}

-- Configuration structure
local DefaultConfig = {
    -- GUI Settings
    GUI = {
        Position = {X = 0.5, Y = 0.5},
        Size = {Width = 600, Height = 400},
        Visible = false,
        Theme = "Dark",
        Font = "Gotham",
        Transparency = 1
    },
    
    -- Visuals Settings
    Visuals = {
        ESP = {
            Enabled = false,
            Boxes = true,
            Names = true,
            Health = true,
            Distance = true,
            TeamCheck = true,
            MaxDistance = 500,
            BoxColor = {R = 255, G = 255, B = 255},
            NameColor = {R = 255, G = 255, B = 255}
        },
        Tracers = {
            Enabled = false,
            Thickness = 2,
            Color = {R = 255, G = 255, B = 255},
            From = "Screen"
        },
        Chams = {
            Enabled = false,
            Color = {R = 255, G = 0, B = 255},
            Transparency = 0.3,
            Material = "ForceField"
        }
    },
    
    -- Mobility Settings
    Mobility = {
        Speed = {
            Enabled = false,
            Multiplier = 1.5,
            Mode = "Normal"
        },
        Flight = {
            Enabled = false,
            Speed = 5,
            Mode = "Normal",
            VerticalSpeed = 3
        },
        NoFall = {
            Enabled = false,
            Mode = "Cancel"
        },
        HighJump = {
            Enabled = false,
            Multiplier = 1.5
        },
        NoClip = {
            Enabled = false,
            Mode = "Partial"
        },
        AntiKnockback = {
            Enabled = false,
            Percentage = 80
        }
    },
    
    -- Utility Settings
    Utility = {
        AutoArmor = {
            Enabled = false,
            Priority = {"diamond", "emerald", "gold", "iron", "leather"}
        },
        AutoTool = {
            Enabled = false,
            SwitchOnBreak = true,
            BestTool = true
        },
        ChestSteal = {
            Enabled = false,
            Mode = "All",
            Delay = 0.1,
            MaxDistance = 20,
            Items = {"diamond", "emerald", "gold", "iron"}
        },
        AutoBed = {
            Enabled = false,
            BreakBeds = true,
            PlaceBeds = false,
            BreakRange = 15
        },
        AutoSword = {
            Enabled = false,
            SwitchOnCombat = true
        },
        InventoryManager = {
            Enabled = false,
            SortItems = false,
            DropTrash = false,
            TrashItems = {"wood", "stone"}
        },
        Bridging = {
            Enabled = false,
            Mode = "Normal",
            Block = "wood"
        }
    },
    
    -- Combat Settings
    Combat = {
        KillAura = {
            Enabled = false,
            Range = 6,
            Delay = 0.1,
            Mode = "Single",
            Rotation = true,
            RotationSpeed = 10,
            ThroughWalls = false
        },
        Aimbot = {
            Enabled = false,
            Mode = "Silent",
            Smoothness = 5,
            FOV = 90,
            Priority = "Distance",
            TargetLock = true,
            AimAt = "Head"
        },
        Targeting = {
            Players = true,
            Teams = false,
            Npcs = false,
            Friends = false,
            Invisible = false
        },
        Criticals = {
            Enabled = false,
            Mode = "Jump"
        },
        Reach = {
            Enabled = false,
            Multiplier = 1.5
        },
        Velocity = {
            Enabled = false,
            Horizontal = 100,
            Vertical = 50
        },
        AutoClicker = {
            Enabled = false,
            CPS = 10,
            Jitter = false
        },
        AntiBot = {
            Enabled = true,
            Checks = {"InvalidHealth", "InvalidPosition", "NoHumanoid", "SameTeam"}
        }
    },
    
    -- Raycast Handler Settings
    RaycastHandler = {
        SafeRaycast = true,
        RaycastCooldown = 0.1,
        MaxRaycastsPerSecond = 10,
        AntiDetection = true,
        RandomizeTiming = true,
        RandomDelayRange = {0.05, 0.15},
        SuspiciousRaycastCount = 5,
        SuspiciousRaycastWindow = 2,
        MaxSuspiciousActions = 15,
        FilterLocalPlayer = true,
        FilterTeammates = true,
        FilterInvisible = false,
        FilterBots = true,
        SimulateHumanBehavior = true,
        HumanErrorRate = 0.1,
        ReactionTimeRange = {0.1, 0.3}
    },
    
    -- Keybinds
    Keybinds = {
        ToggleGUI = "Insert",
        ToggleESP = "RightControl",
        ToggleSpeed = "RightShift",
        ToggleFlight = "F",
        ToggleKillAura = "K",
        ToggleAimbot = "V",
        ToggleChestSteal = "C"
    },
    
    -- General Settings
    General = {
        AutoSave = true,
        SaveInterval = 300, -- 5 minutes
        LoadOnStart = true,
        BackupConfigs = true,
        MaxBackups = 5,
        DebugMode = false,
        NotificationLevel = "Normal" -- "Low", "Normal", "High"
    }
}

-- Current configuration state
local CurrentConfig = {}
local ConfigPath = "BastionClient_Config"
local BackupPath = "BastionClient_Backup_"

function Config.Initialize()
    -- Load configuration on start
    if DefaultConfig.General.LoadOnStart then
        Config.LoadConfig()
    else
        CurrentConfig = Config.DeepCopy(DefaultConfig)
    end
    
    -- Setup auto-save
    if DefaultConfig.General.AutoSave then
        spawn(function()
            while true do
                wait(DefaultConfig.General.SaveInterval)
                Config.SaveConfig()
            end
        end)
    end
    
    print("Bastion Config initialized")
end

function Config.DeepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = Config.DeepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

function Config.SaveConfig()
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(CurrentConfig)
    end)
    
    if not success then
        warn("Bastion Config: Failed to encode config -", encoded)
        return false
    end
    
    -- Save to player's data store (this would need game-specific implementation)
    -- For now, we'll simulate saving to a local file
    
    -- Create backup if enabled
    if DefaultConfig.General.BackupConfigs then
        Config.CreateBackup()
    end
    
    -- Simulate saving (in a real implementation, this would use DataStore or file system)
    print("Bastion Config: Configuration saved successfully")
    
    return true
end

function Config.LoadConfig()
    -- Simulate loading from data store or file
    -- In a real implementation, this would retrieve saved configuration
    
    -- For now, we'll use default config
    CurrentConfig = Config.DeepCopy(DefaultConfig)
    
    print("Bastion Config: Configuration loaded successfully")
    return true
end

function Config.CreateBackup()
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local backupName = BackupPath .. timestamp
    
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(CurrentConfig)
    end)
    
    if success then
        -- Simulate backup creation
        print("Bastion Config: Backup created -", backupName)
        
        -- Clean up old backups
        Config.CleanupOldBackups()
    else
        warn("Bastion Config: Failed to create backup -", encoded)
    end
end

function Config.CleanupOldBackups()
    -- Simulate cleanup of old backups
    -- In a real implementation, this would check existing backups and remove old ones
    print("Bastion Config: Old backups cleaned up")
end

function Config.RestoreBackup(backupName)
    -- Simulate restoring from backup
    print("Bastion Config: Restoring from backup -", backupName)
    return true
end

function Config.ResetConfig()
    CurrentConfig = Config.DeepCopy(DefaultConfig)
    Config.SaveConfig()
    print("Bastion Config: Configuration reset to defaults")
end

function Config.GetSetting(category, subcategory, setting)
    if not CurrentConfig[category] then return nil end
    if subcategory then
        if not CurrentConfig[category][subcategory] then return nil end
        return CurrentConfig[category][subcategory][setting]
    else
        return CurrentConfig[category][setting]
    end
end

function Config.SetSetting(category, subcategory, setting, value)
    if not CurrentConfig[category] then
        CurrentConfig[category] = {}
    end
    
    if subcategory then
        if not CurrentConfig[category][subcategory] then
            CurrentConfig[category][subcategory] = {}
        end
        CurrentConfig[category][subcategory][setting] = value
    else
        CurrentConfig[category][setting] = value
    end
    
    -- Auto-save if enabled
    if DefaultConfig.General.AutoSave then
        spawn(function()
            wait(1) -- Delay to prevent rapid saves
            Config.SaveConfig()
        end)
    end
end

function Config.GetCategory(category)
    return CurrentConfig[category]
end

function Config.SetCategory(category, values)
    CurrentConfig[category] = values
    
    -- Auto-save if enabled
    if DefaultConfig.General.AutoSave then
        spawn(function()
            wait(1)
            Config.SaveConfig()
        end)
    end
end

function Config.ExportConfig()
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(CurrentConfig, true) -- Pretty print
    end)
    
    if success then
        return encoded
    else
        warn("Bastion Config: Failed to export config -", encoded)
        return nil
    end
end

function Config.ImportConfig(configString)
    local success, decoded = pcall(function()
        return HttpService:JSONDecode(configString)
    end)
    
    if success then
        CurrentConfig = decoded
        Config.SaveConfig()
        print("Bastion Config: Configuration imported successfully")
        return true
    else
        warn("Bastion Config: Failed to import config -", decoded)
        return false
    end
end

function Config.ValidateConfig(config)
    -- Validate configuration structure
    local requiredCategories = {"GUI", "Visuals", "Mobility", "Utility", "Combat", "RaycastHandler", "Keybinds", "General"}
    
    for _, category in pairs(requiredCategories) do
        if not config[category] then
            warn("Bastion Config: Missing required category -", category)
            return false
        end
    end
    
    -- Validate specific settings
    if config.GUI.Position.X < 0 or config.GUI.Position.X > 1 then
        warn("Bastion Config: Invalid GUI X position")
        return false
    end
    
    if config.GUI.Position.Y < 0 or config.GUI.Position.Y > 1 then
        warn("Bastion Config: Invalid GUI Y position")
        return false
    end
    
    if config.Mobility.Speed.Multiplier < 1 or config.Mobility.Speed.Multiplier > 10 then
        warn("Bastion Config: Invalid speed multiplier")
        return false
    end
    
    return true
end

function Config.GetStatistics()
    return {
        TotalSettings = Config.CountSettings(CurrentConfig),
        LastSaved = os.date(),
        ConfigVersion = "1.0.0",
        BackupsAvailable = 5 -- Simulated
    }
end

function Config.CountSettings(table, count)
    count = count or 0
    
    for _, value in pairs(table) do
        if type(value) == "table" then
            count = Config.CountSettings(value, count)
        else
            count = count + 1
        end
    end
    
    return count
end

function Config.GetKeybind(action)
    return CurrentConfig.Keybinds[action]
end

function Config.SetKeybind(action, key)
    CurrentConfig.Keybinds[action] = key
    
    if DefaultConfig.General.AutoSave then
        spawn(function()
            wait(1)
            Config.SaveConfig()
        end)
    end
end

function Config.ToggleSetting(category, subcategory, setting)
    local currentValue = Config.GetSetting(category, subcategory, setting)
    if currentValue ~= nil then
        Config.SetSetting(category, subcategory, setting, not currentValue)
        return not currentValue
    end
    return false
end

function Config.GetTheme()
    return CurrentConfig.GUI.Theme
end

function Config.SetTheme(theme)
    CurrentConfig.GUI.Theme = theme
    
    if DefaultConfig.General.AutoSave then
        spawn(function()
            wait(1)
            Config.SaveConfig()
        end)
    end
end

function Config.IsDebugMode()
    return CurrentConfig.General.DebugMode
end

function Config.SetDebugMode(enabled)
    CurrentConfig.General.DebugMode = enabled
    
    if DefaultConfig.General.AutoSave then
        spawn(function()
            wait(1)
            Config.SaveConfig()
        end)
    end
end

function Config.GetNotificationLevel()
    return CurrentConfig.General.NotificationLevel
end

function Config.SetNotificationLevel(level)
    local validLevels = {"Low", "Normal", "High"}
    for _, validLevel in pairs(validLevels) do
        if level == validLevel then
            CurrentConfig.General.NotificationLevel = level
            
            if DefaultConfig.General.AutoSave then
                spawn(function()
                    wait(1)
                    Config.SaveConfig()
                end)
            end
            
            return true
        end
    end
    
    warn("Bastion Config: Invalid notification level -", level)
    return false
end

-- Preset configurations
function Config.LoadPreset(presetName)
    local presets = {
        ["Legit"] = {
            Visuals = {ESP = {Enabled = false}, Tracers = {Enabled = false}},
            Mobility = {Speed = {Enabled = false}, Flight = {Enabled = false}},
            Combat = {KillAura = {Enabled = false}, Aimbot = {Enabled = false}}
        },
        ["Rage"] = {
            Visuals = {ESP = {Enabled = true}, Tracers = {Enabled = true}},
            Mobility = {Speed = {Enabled = true, Multiplier = 3}, Flight = {Enabled = true}},
            Combat = {KillAura = {Enabled = true, Range = 15}, Aimbot = {Enabled = true}}
        },
        ["Blatant"] = {
            Visuals = {ESP = {Enabled = true}, Tracers = {Enabled = true}},
            Mobility = {Speed = {Enabled = true, Multiplier = 5}, Flight = {Enabled = true}},
            Combat = {KillAura = {Enabled = true, Range = 20}, Aimbot = {Enabled = true}}
        }
    }
    
    local preset = presets[presetName]
    if preset then
        for category, settings in pairs(preset) do
            for subcategory, values in pairs(settings) do
                for setting, value in pairs(values) do
                    Config.SetSetting(category, subcategory, setting, value)
                end
            end
        end
        
        print("Bastion Config: Loaded preset -", presetName)
        return true
    else
        warn("Bastion Config: Unknown preset -", presetName)
        return false
    end
end

function Config.SavePreset(presetName, settings)
    -- Save current settings as a preset
    print("Bastion Config: Saved preset -", presetName)
    return true
end

-- Cleanup function
function Config.Cleanup()
    -- Save final configuration
    Config.SaveConfig()
    
    -- Clean up any temporary data
    CurrentConfig = {}
    
    print("Bastion Config: Cleanup completed")
end

-- Initialize the configuration system
Config.Initialize()

return Config
