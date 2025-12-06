--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                      BASTION CLIENT                          ║
    ║              Premium Roblox Bedwars GUI                      ║
    ║                      Version 3.0.0                           ║
    ╚══════════════════════════════════════════════════════════════╝
    
    Controls:
    - RightShift: Toggle GUI
    - Left Click Module: Open settings panel
    - Right Click Module: Quick toggle
]]

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Mouse = Player:GetMouse()

-- Theme Presets
local Themes = {
    Aqua = {
        Primary = Color3.fromRGB(0, 180, 255),
        PrimaryDark = Color3.fromRGB(0, 140, 200),
        PrimaryGlow = Color3.fromRGB(0, 220, 255),
    },
    Purple = {
        Primary = Color3.fromRGB(140, 90, 255),
        PrimaryDark = Color3.fromRGB(100, 60, 200),
        PrimaryGlow = Color3.fromRGB(170, 120, 255),
    },
    Red = {
        Primary = Color3.fromRGB(255, 70, 90),
        PrimaryDark = Color3.fromRGB(200, 50, 70),
        PrimaryGlow = Color3.fromRGB(255, 100, 120),
    },
    Green = {
        Primary = Color3.fromRGB(50, 205, 100),
        PrimaryDark = Color3.fromRGB(40, 160, 80),
        PrimaryGlow = Color3.fromRGB(80, 235, 130),
    },
    Orange = {
        Primary = Color3.fromRGB(255, 150, 50),
        PrimaryDark = Color3.fromRGB(220, 120, 30),
        PrimaryGlow = Color3.fromRGB(255, 180, 80),
    },
    Pink = {
        Primary = Color3.fromRGB(255, 100, 180),
        PrimaryDark = Color3.fromRGB(220, 70, 150),
        PrimaryGlow = Color3.fromRGB(255, 140, 210),
    }
}

-- Current Theme
local CurrentTheme = "Aqua"

local Theme = {
    Background = Color3.fromRGB(18, 18, 24),
    BackgroundLight = Color3.fromRGB(25, 25, 35),
    BackgroundLighter = Color3.fromRGB(35, 35, 48),
    BackgroundCard = Color3.fromRGB(28, 28, 38),
    BackgroundHover = Color3.fromRGB(40, 40, 55),
    Primary = Themes[CurrentTheme].Primary,
    PrimaryDark = Themes[CurrentTheme].PrimaryDark,
    PrimaryGlow = Themes[CurrentTheme].PrimaryGlow,
    Text = Color3.fromRGB(255, 255, 255),
    TextSub = Color3.fromRGB(180, 180, 195),
    TextDim = Color3.fromRGB(120, 120, 140),
    TextMuted = Color3.fromRGB(80, 80, 100),
    Border = Color3.fromRGB(50, 50, 65),
    Success = Color3.fromRGB(50, 205, 100),
    Warning = Color3.fromRGB(255, 180, 50),
    Danger = Color3.fromRGB(255, 70, 80),
    Slider = Color3.fromRGB(45, 45, 60)
}

local function UpdateTheme(themeName)
    CurrentTheme = themeName
    Theme.Primary = Themes[themeName].Primary
    Theme.PrimaryDark = Themes[themeName].PrimaryDark
    Theme.PrimaryGlow = Themes[themeName].PrimaryGlow
end

-- Module Database
local Modules = {
    Combat = {
        {name = "Kill Aura", desc = "Auto attacks nearby enemies", enabled = false, bind = "", settings = {
            {type = "slider", name = "Range", value = 12, min = 5, max = 20, unit = "studs"},
            {type = "slider", name = "CPS", value = 12, min = 5, max = 20, unit = ""},
            {type = "toggle", name = "Players Only", value = true},
            {type = "toggle", name = "Team Check", value = true},
            {type = "dropdown", name = "Mode", value = "Switch", options = {"Switch", "Single", "Multi"}}
        }},
        {name = "Auto Clicker", desc = "Automatically clicks", enabled = false, bind = "", settings = {
            {type = "slider", name = "CPS", value = 14, min = 1, max = 20, unit = ""},
            {type = "toggle", name = "Right Click", value = false},
            {type = "toggle", name = "Only In Game", value = true}
        }},
        {name = "Reach", desc = "Extends attack range", enabled = false, bind = "", settings = {
            {type = "slider", name = "Distance", value = 5, min = 3, max = 8, unit = "studs"}
        }},
        {name = "Aim Assist", desc = "Locks aim to enemies", enabled = false, bind = "", settings = {
            {type = "slider", name = "FOV", value = 90, min = 30, max = 180, unit = "deg"},
            {type = "slider", name = "Smoothing", value = 5, min = 1, max = 10, unit = ""},
            {type = "toggle", name = "Visible Only", value = true},
            {type = "toggle", name = "Show FOV", value = false}
        }},
        {name = "W-Tap", desc = "Auto sprint reset combos", enabled = false, bind = "", settings = {
            {type = "slider", name = "Delay", value = 50, min = 20, max = 150, unit = "ms"}
        }},
        {name = "Combo Lock", desc = "Lock combos on enemies", enabled = false, bind = "", settings = {}}
    },
    Movement = {
        {name = "Speed", desc = "Move faster", enabled = false, bind = "", settings = {
            {type = "slider", name = "Speed", value = 24, min = 16, max = 50, unit = ""},
            {type = "dropdown", name = "Mode", value = "CFrame", options = {"CFrame", "Velocity", "Teleport"}}
        }},
        {name = "Fly", desc = "Fly through the air", enabled = false, bind = "", settings = {
            {type = "slider", name = "Speed", value = 50, min = 10, max = 150, unit = ""},
            {type = "toggle", name = "Noclip", value = false}
        }},
        {name = "Bhop", desc = "Bunny hop automatically", enabled = false, bind = "", settings = {
            {type = "slider", name = "Height", value = 8, min = 5, max = 15, unit = ""}
        }},
        {name = "No Fall", desc = "No fall damage", enabled = false, bind = "", settings = {}},
        {name = "Bridge Assist", desc = "Helps with bridging", enabled = true, bind = "", settings = {
            {type = "slider", name = "Angle", value = 75, min = 60, max = 85, unit = "deg"},
            {type = "toggle", name = "Auto Rotate", value = true}
        }},
        {name = "Sprint", desc = "Always sprinting", enabled = true, bind = "", settings = {}}
    },
    Player = {
        {name = "Auto Armor", desc = "Equips best armor", enabled = true, bind = "", settings = {}},
        {name = "Auto Eat", desc = "Auto eat on low HP", enabled = false, bind = "", settings = {
            {type = "slider", name = "Health", value = 50, min = 10, max = 90, unit = "%"}
        }},
        {name = "Fast Place", desc = "Place blocks faster", enabled = true, bind = "", settings = {
            {type = "slider", name = "Delay", value = 0, min = 0, max = 100, unit = "ms"}
        }},
        {name = "No Slow", desc = "No item use slowdown", enabled = false, bind = "", settings = {}},
        {name = "Auto Tool", desc = "Auto switch tools", enabled = true, bind = "", settings = {}},
        {name = "Scaffold", desc = "Auto bridge blocks", enabled = false, bind = "", settings = {
            {type = "dropdown", name = "Mode", value = "Normal", options = {"Normal", "Diagonal", "God"}},
            {type = "toggle", name = "Safe Walk", value = true}
        }}
    },
    Visuals = {
        {name = "ESP", desc = "See players through walls", enabled = false, bind = "", settings = {
            {type = "toggle", name = "Box", value = true},
            {type = "toggle", name = "Name", value = true},
            {type = "toggle", name = "Health", value = true},
            {type = "toggle", name = "Distance", value = false},
            {type = "toggle", name = "Tracers", value = false}
        }},
        {name = "Chams", desc = "Highlight players", enabled = false, bind = "", settings = {
            {type = "toggle", name = "Show Hidden", value = true}
        }},
        {name = "Bed ESP", desc = "See bed locations", enabled = true, bind = "", settings = {
            {type = "toggle", name = "Show Distance", value = true}
        }},
        {name = "Item ESP", desc = "See dropped items", enabled = false, bind = "", settings = {}},
        {name = "Fullbright", desc = "Maximum brightness", enabled = true, bind = "", settings = {}},
        {name = "No Fog", desc = "Remove fog", enabled = true, bind = "", settings = {}}
    },
    World = {
        {name = "Time Changer", desc = "Change time of day", enabled = false, bind = "", settings = {
            {type = "slider", name = "Hour", value = 12, min = 0, max = 24, unit = "h"}
        }},
        {name = "Weather", desc = "Control weather", enabled = false, bind = "", settings = {
            {type = "dropdown", name = "Type", value = "Clear", options = {"Clear", "Rain", "Fog"}}
        }},
        {name = "Gen ESP", desc = "See generators", enabled = false, bind = "", settings = {}},
        {name = "Shop ESP", desc = "Highlight shops", enabled = false, bind = "", settings = {}},
        {name = "Low Graphics", desc = "Boost FPS", enabled = false, bind = "", settings = {}},
        {name = "No Particles", desc = "Remove particles", enabled = false, bind = "", settings = {}}
    },
    Misc = {
        {name = "Anti AFK", desc = "Prevents AFK kick", enabled = true, bind = "", settings = {}},
        {name = "Auto GG", desc = "Say GG on win", enabled = false, bind = "", settings = {}},
        {name = "Auto Queue", desc = "Auto requeue games", enabled = false, bind = "", settings = {
            {type = "slider", name = "Delay", value = 3, min = 1, max = 10, unit = "s"}
        }},
        {name = "Chat Spam", desc = "Spam in chat", enabled = false, bind = "", settings = {
            {type = "slider", name = "Delay", value = 2, min = 1, max = 10, unit = "s"}
        }},
        {name = "Notifications", desc = "Show notifications", enabled = true, bind = "", settings = {}},
        {name = "Watermark", desc = "Show watermark", enabled = true, bind = "", settings = {}}
    }
}

-- ArrayList Settings
local ArrayListSettings = {
    enabled = true,
    position = UDim2.new(1, -10, 0, 100),
    anchor = Vector2.new(1, 0),
    showBinds = true,
    sortMode = "Length", -- Length, Alphabetical
    background = true,
    backgroundOpacity = 0.5
}

-- State
local CurrentCategory = "Combat"
local SelectedModule = nil
local WaitingForBind = nil
local GUIVisible = true
local Connections = {}

-- Utilities
local function Tween(obj, props, dur, style, dir)
    local info = TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
    local tween = TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

local function Corner(parent, rad)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, rad or 6)
    c.Parent = parent
    return c
end

local function Stroke(parent, col, thick)
    local s = Instance.new("UIStroke")
    s.Color = col or Theme.Border
    s.Thickness = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function Padding(parent, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.Parent = parent
    return p
end

local function GetActiveModules()
    local active = {}
    for _, cat in pairs(Modules) do
        for _, m in ipairs(cat) do
            if m.enabled then
                table.insert(active, m)
            end
        end
    end
    
    if ArrayListSettings.sortMode == "Length" then
        table.sort(active, function(a, b) return #a.name > #b.name end)
    else
        table.sort(active, function(a, b) return a.name < b.name end)
    end
    
    return active
end

-- Module Functions
local ModuleFunctions = {
    ["Fullbright"] = function(enabled)
        if enabled then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        else
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
            Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        end
    end,
    ["No Fog"] = function(enabled)
        Lighting.FogEnd = enabled and 100000 or 1000
        Lighting.FogStart = enabled and 100000 or 0
    end,
    ["Sprint"] = function(enabled)
        local character = Player.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = enabled and 20 or 16
            end
        end
    end,
    ["Low Graphics"] = function(enabled)
        if enabled then
            settings().Rendering.QualityLevel = 1
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    v.Enabled = false
                end
            end
        else
            settings().Rendering.QualityLevel = 10
        end
    end,
    ["Time Changer"] = function(enabled, settings)
        if enabled and settings then
            for _, s in ipairs(settings) do
                if s.name == "Hour" then
                    Lighting.ClockTime = s.value
                    break
                end
            end
        end
    end
}

local function ExecuteModule(name, enabled, moduleSettings)
    if ModuleFunctions[name] then
        pcall(function()
            ModuleFunctions[name](enabled, moduleSettings)
        end)
    end
end

-- Create ScreenGui
local Gui = Instance.new("ScreenGui")
Gui.Name = "BastionClient"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.DisplayOrder = 999
Gui.Parent = PlayerGui

-- ═══════════════════════════════════════════════════════════════
-- ARRAYLIST (Draggable HUD)
-- ═══════════════════════════════════════════════════════════════

local ArrayList = Instance.new("Frame")
ArrayList.Name = "ArrayList"
ArrayList.Size = UDim2.new(0, 200, 0, 400)
ArrayList.Position = ArrayListSettings.position
ArrayList.AnchorPoint = ArrayListSettings.anchor
ArrayList.BackgroundTransparency = 1
ArrayList.Parent = Gui

local ArrayLayout = Instance.new("UIListLayout")
ArrayLayout.SortOrder = Enum.SortOrder.LayoutOrder
ArrayLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ArrayLayout.Padding = UDim.new(0, 2)
ArrayLayout.Parent = ArrayList

-- ArrayList Dragging
local ArrayDragging = false
local ArrayDragStart, ArrayStartPos

ArrayList.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        ArrayDragging = true
        ArrayDragStart = input.Position
        ArrayStartPos = ArrayList.Position
    end
end)

ArrayList.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        ArrayDragging = false
        ArrayListSettings.position = ArrayList.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if ArrayDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - ArrayDragStart
        ArrayList.Position = UDim2.new(
            ArrayStartPos.X.Scale, ArrayStartPos.X.Offset + delta.X,
            ArrayStartPos.Y.Scale, ArrayStartPos.Y.Offset + delta.Y
        )
    end
end)

local function RefreshArrayList()
    for _, child in ipairs(ArrayList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    if not ArrayListSettings.enabled then return end
    
    local active = GetActiveModules()
    
    for i, mod in ipairs(active) do
        local item = Instance.new("Frame")
        item.Size = UDim2.new(0, 0, 0, 22)
        item.BackgroundColor3 = Theme.Background
        item.BackgroundTransparency = ArrayListSettings.background and ArrayListSettings.backgroundOpacity or 1
        item.LayoutOrder = i
        item.AutomaticSize = Enum.AutomaticSize.X
        item.Parent = ArrayList
        
        -- Accent bar on right
        local accent = Instance.new("Frame")
        accent.Size = UDim2.new(0, 2, 1, 0)
        accent.Position = UDim2.new(1, 0, 0, 0)
        accent.BackgroundColor3 = Theme.Primary
        accent.BorderSizePixel = 0
        accent.Parent = item
        
        -- Gradient based on position
        local hue = (i - 1) / math.max(#active, 1) * 0.15
        local rainbow = Color3.fromHSV((0.5 + hue) % 1, 0.7, 1)
        accent.BackgroundColor3 = rainbow
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0, 0, 1, 0)
        nameLabel.AutomaticSize = Enum.AutomaticSize.X
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = mod.name
        nameLabel.TextColor3 = Theme.Text
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.GothamMedium
        nameLabel.Parent = item
        
        Padding(nameLabel, 0, 0, 8, 8)
        
        if ArrayListSettings.showBinds and mod.bind ~= "" then
            local bindLabel = Instance.new("TextLabel")
            bindLabel.Size = UDim2.new(0, 0, 1, 0)
            bindLabel.Position = UDim2.new(1, 0, 0, 0)
            bindLabel.AutomaticSize = Enum.AutomaticSize.X
            bindLabel.BackgroundTransparency = 1
            bindLabel.Text = " [" .. mod.bind .. "]"
            bindLabel.TextColor3 = Theme.TextDim
            bindLabel.TextSize = 12
            bindLabel.Font = Enum.Font.Gotham
            bindLabel.Parent = nameLabel
        end
        
        -- Slide in animation
        item.Position = UDim2.new(1, 30, 0, 0)
        Tween(item, {Position = UDim2.new(0, 0, 0, 0)}, 0.15)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- WATERMARK
-- ═══════════════════════════════════════════════════════════════

local Watermark = Instance.new("Frame")
Watermark.Name = "Watermark"
Watermark.Size = UDim2.new(0, 280, 0, 32)
Watermark.Position = UDim2.new(0, 10, 0, 10)
Watermark.BackgroundColor3 = Theme.Background
Watermark.BackgroundTransparency = 0.2
Watermark.Parent = Gui
Corner(Watermark, 6)
Stroke(Watermark, Theme.Primary, 1)

local WatermarkGradient = Instance.new("Frame")
WatermarkGradient.Size = UDim2.new(0, 3, 1, 0)
WatermarkGradient.BackgroundColor3 = Theme.Primary
WatermarkGradient.Parent = Watermark

local WatermarkText = Instance.new("TextLabel")
WatermarkText.Size = UDim2.new(1, -15, 1, 0)
WatermarkText.Position = UDim2.new(0, 12, 0, 0)
WatermarkText.BackgroundTransparency = 1
WatermarkText.Text = "BASTION | " .. Player.Name .. " | FPS: 60 | " .. os.date("%H:%M")
WatermarkText.TextColor3 = Theme.Text
WatermarkText.TextSize = 13
WatermarkText.Font = Enum.Font.GothamMedium
WatermarkText.TextXAlignment = Enum.TextXAlignment.Left
WatermarkText.Parent = Watermark

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════

local NotifHolder = Instance.new("Frame")
NotifHolder.Name = "Notifications"
NotifHolder.Size = UDim2.new(0, 300, 1, -50)
NotifHolder.Position = UDim2.new(1, -310, 0, 45)
NotifHolder.BackgroundTransparency = 1
NotifHolder.Parent = Gui

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.Padding = UDim.new(0, 6)
NotifLayout.Parent = NotifHolder

local function Notify(title, msg, dur, color)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 60)
    notif.BackgroundColor3 = Theme.Background
    notif.BackgroundTransparency = 0.1
    notif.ClipsDescendants = true
    notif.Parent = NotifHolder
    Corner(notif, 6)
    
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = color or Theme.Primary
    bar.BorderSizePixel = 0
    bar.Parent = notif
    
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 0, 22)
    titleLbl.Position = UDim2.new(0, 12, 0, 8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Theme.Text
    titleLbl.TextSize = 14
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = notif
    
    local msgLbl = Instance.new("TextLabel")
    msgLbl.Size = UDim2.new(1, -20, 0, 22)
    msgLbl.Position = UDim2.new(0, 12, 0, 30)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Text = msg
    msgLbl.TextColor3 = Theme.TextSub
    msgLbl.TextSize = 12
    msgLbl.Font = Enum.Font.Gotham
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.TextTruncate = Enum.TextTruncate.AtEnd
    msgLbl.Parent = notif
    
    -- Progress bar
    local progress = Instance.new("Frame")
    progress.Size = UDim2.new(1, 0, 0, 2)
    progress.Position = UDim2.new(0, 0, 1, -2)
    progress.BackgroundColor3 = color or Theme.Primary
    progress.BorderSizePixel = 0
    progress.Parent = notif
    
    -- Animate
    notif.Position = UDim2.new(1, 50, 0, 0)
    Tween(notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.25)
    Tween(progress, {Size = UDim2.new(0, 0, 0, 2)}, dur or 3, Enum.EasingStyle.Linear)
    
    task.delay(dur or 3, function()
        Tween(notif, {Position = UDim2.new(1, 50, 0, 0)}, 0.25)
        task.wait(0.25)
        notif:Destroy()
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN GUI (Vape V4 Style)
-- ═══════════════════════════════════════════════════════════════

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 620, 0, 420)
Main.Position = UDim2.new(0.5, -310, 0.5, -210)
Main.BackgroundColor3 = Theme.Background
Main.Parent = Gui
Corner(Main, 8)

-- Top accent line
local TopLine = Instance.new("Frame")
TopLine.Size = UDim2.new(1, 0, 0, 2)
TopLine.BackgroundColor3 = Theme.Primary
TopLine.BorderSizePixel = 0
TopLine.Parent = Main

local TopGradient = Instance.new("UIGradient")
TopGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.PrimaryDark),
    ColorSequenceKeypoint.new(0.5, Theme.PrimaryGlow),
    ColorSequenceKeypoint.new(1, Theme.PrimaryDark)
})
TopGradient.Parent = TopLine

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 45)
Header.Position = UDim2.new(0, 0, 0, 2)
Header.BackgroundColor3 = Theme.BackgroundLight
Header.BorderSizePixel = 0
Header.Parent = Main

-- Logo
local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(0, 130, 1, 0)
Logo.Position = UDim2.new(0, 15, 0, 0)
Logo.BackgroundTransparency = 1
Logo.Text = "BASTION"
Logo.TextColor3 = Theme.Primary
Logo.TextSize = 20
Logo.Font = Enum.Font.GothamBlack
Logo.TextXAlignment = Enum.TextXAlignment.Left
Logo.Parent = Header

-- Category Tabs
local TabHolder = Instance.new("Frame")
TabHolder.Size = UDim2.new(0, 380, 0, 30)
TabHolder.Position = UDim2.new(0, 145, 0.5, -15)
TabHolder.BackgroundTransparency = 1
TabHolder.Parent = Header

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 5)
TabLayout.Parent = TabHolder

local Categories = {"Combat", "Movement", "Player", "Visuals", "World", "Misc"}
local TabButtons = {}

for i, cat in ipairs(Categories) do
    local tab = Instance.new("TextButton")
    tab.Name = cat
    tab.Size = UDim2.new(0, 60, 1, 0)
    tab.BackgroundColor3 = Theme.BackgroundLighter
    tab.BackgroundTransparency = cat == CurrentCategory and 0 or 1
    tab.Text = cat
    tab.TextColor3 = cat == CurrentCategory and Theme.Primary or Theme.TextDim
    tab.TextSize = 12
    tab.Font = Enum.Font.GothamSemibold
    tab.LayoutOrder = i
    tab.Parent = TabHolder
    Corner(tab, 5)
    
    TabButtons[cat] = tab
end

-- Settings Icon
local SettingsBtn = Instance.new("TextButton")
SettingsBtn.Size = UDim2.new(0, 30, 0, 30)
SettingsBtn.Position = UDim2.new(1, -80, 0.5, -15)
SettingsBtn.BackgroundColor3 = Theme.BackgroundLighter
SettingsBtn.Text = "⚙"
SettingsBtn.TextColor3 = Theme.TextDim
SettingsBtn.TextSize = 16
SettingsBtn.Font = Enum.Font.GothamBold
SettingsBtn.Parent = Header
Corner(SettingsBtn, 6)

-- Window Controls
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
CloseBtn.BackgroundColor3 = Theme.BackgroundLighter
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Theme.TextDim
CloseBtn.TextSize = 20
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Header
Corner(CloseBtn, 6)

-- Content Area
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -47)
Content.Position = UDim2.new(0, 0, 0, 47)
Content.BackgroundTransparency = 1
Content.Parent = Main

-- Module List (Left side)
local ModuleList = Instance.new("Frame")
ModuleList.Name = "ModuleList"
ModuleList.Size = UDim2.new(0.5, -5, 1, -10)
ModuleList.Position = UDim2.new(0, 10, 0, 5)
ModuleList.BackgroundColor3 = Theme.BackgroundLight
ModuleList.Parent = Content
Corner(ModuleList, 6)

local ModuleScroll = Instance.new("ScrollingFrame")
ModuleScroll.Size = UDim2.new(1, -10, 1, -10)
ModuleScroll.Position = UDim2.new(0, 5, 0, 5)
ModuleScroll.BackgroundTransparency = 1
ModuleScroll.ScrollBarThickness = 3
ModuleScroll.ScrollBarImageColor3 = Theme.Primary
ModuleScroll.BorderSizePixel = 0
ModuleScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ModuleScroll.Parent = ModuleList

local ModLayout = Instance.new("UIListLayout")
ModLayout.SortOrder = Enum.SortOrder.LayoutOrder
ModLayout.Padding = UDim.new(0, 4)
ModLayout.Parent = ModuleScroll

-- Settings Panel (Right side)
local SettingsPanel = Instance.new("Frame")
SettingsPanel.Name = "SettingsPanel"
SettingsPanel.Size = UDim2.new(0.5, -15, 1, -10)
SettingsPanel.Position = UDim2.new(0.5, 5, 0, 5)
SettingsPanel.BackgroundColor3 = Theme.BackgroundLight
SettingsPanel.ClipsDescendants = true
SettingsPanel.Parent = Content
Corner(SettingsPanel, 6)

local SettingsTitle = Instance.new("TextLabel")
SettingsTitle.Size = UDim2.new(1, -20, 0, 35)
SettingsTitle.Position = UDim2.new(0, 10, 0, 5)
SettingsTitle.BackgroundTransparency = 1
SettingsTitle.Text = "Select a module"
SettingsTitle.TextColor3 = Theme.TextDim
SettingsTitle.TextSize = 14
SettingsTitle.Font = Enum.Font.GothamMedium
SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingsTitle.Parent = SettingsPanel

local SettingsScroll = Instance.new("ScrollingFrame")
SettingsScroll.Size = UDim2.new(1, -10, 1, -45)
SettingsScroll.Position = UDim2.new(0, 5, 0, 40)
SettingsScroll.BackgroundTransparency = 1
SettingsScroll.ScrollBarThickness = 3
SettingsScroll.ScrollBarImageColor3 = Theme.Primary
SettingsScroll.BorderSizePixel = 0
SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SettingsScroll.Visible = false
SettingsScroll.Parent = SettingsPanel

local SetLayout = Instance.new("UIListLayout")
SetLayout.SortOrder = Enum.SortOrder.LayoutOrder
SetLayout.Padding = UDim.new(0, 6)
SetLayout.Parent = SettingsScroll

-- Theme Customization Panel
local ThemePanel = Instance.new("Frame")
ThemePanel.Name = "ThemePanel"
ThemePanel.Size = UDim2.new(1, 0, 1, 0)
ThemePanel.BackgroundTransparency = 1
ThemePanel.Visible = false
ThemePanel.Parent = SettingsPanel

local ThemePanelTitle = Instance.new("TextLabel")
ThemePanelTitle.Size = UDim2.new(1, -20, 0, 30)
ThemePanelTitle.Position = UDim2.new(0, 10, 0, 10)
ThemePanelTitle.BackgroundTransparency = 1
ThemePanelTitle.Text = "GUI Customization"
ThemePanelTitle.TextColor3 = Theme.Text
ThemePanelTitle.TextSize = 16
ThemePanelTitle.Font = Enum.Font.GothamBold
ThemePanelTitle.TextXAlignment = Enum.TextXAlignment.Left
ThemePanelTitle.Parent = ThemePanel

-- Theme Color Options
local ThemeColors = Instance.new("Frame")
ThemeColors.Size = UDim2.new(1, -20, 0, 100)
ThemeColors.Position = UDim2.new(0, 10, 0, 50)
ThemeColors.BackgroundTransparency = 1
ThemeColors.Parent = ThemePanel

local ColorTitle = Instance.new("TextLabel")
ColorTitle.Size = UDim2.new(1, 0, 0, 20)
ColorTitle.BackgroundTransparency = 1
ColorTitle.Text = "Accent Color"
ColorTitle.TextColor3 = Theme.TextSub
ColorTitle.TextSize = 12
ColorTitle.Font = Enum.Font.GothamMedium
ColorTitle.TextXAlignment = Enum.TextXAlignment.Left
ColorTitle.Parent = ThemeColors

local ColorGrid = Instance.new("Frame")
ColorGrid.Size = UDim2.new(1, 0, 0, 60)
ColorGrid.Position = UDim2.new(0, 0, 0, 25)
ColorGrid.BackgroundTransparency = 1
ColorGrid.Parent = ThemeColors

local ColorGridLayout = Instance.new("UIGridLayout")
ColorGridLayout.CellSize = UDim2.new(0, 40, 0, 40)
ColorGridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
ColorGridLayout.Parent = ColorGrid

for name, colors in pairs(Themes) do
    local colorBtn = Instance.new("TextButton")
    colorBtn.Name = name
    colorBtn.Size = UDim2.new(0, 40, 0, 40)
    colorBtn.BackgroundColor3 = colors.Primary
    colorBtn.Text = ""
    colorBtn.Parent = ColorGrid
    Corner(colorBtn, 8)
    
    if name == CurrentTheme then
        Stroke(colorBtn, Theme.Text, 2)
    end
    
    colorBtn.MouseButton1Click:Connect(function()
        -- Update stroke on all buttons
        for _, btn in ipairs(ColorGrid:GetChildren()) do
            if btn:IsA("TextButton") then
                local stroke = btn:FindFirstChildOfClass("UIStroke")
                if stroke then stroke:Destroy() end
            end
        end
        Stroke(colorBtn, Theme.Text, 2)
        
        -- Update theme
        UpdateTheme(name)
        
        -- Update GUI elements with new theme
        TopLine.BackgroundColor3 = Theme.Primary
        Logo.TextColor3 = Theme.Primary
        WatermarkGradient.BackgroundColor3 = Theme.Primary
        ModuleScroll.ScrollBarImageColor3 = Theme.Primary
        SettingsScroll.ScrollBarImageColor3 = Theme.Primary
        
        Notify("Theme", "Changed to " .. name, 2, Theme.Primary)
        RefreshArrayList()
    end)
end

-- ArrayList Settings in Theme Panel
local ArraySettings = Instance.new("Frame")
ArraySettings.Size = UDim2.new(1, -20, 0, 180)
ArraySettings.Position = UDim2.new(0, 10, 0, 160)
ArraySettings.BackgroundTransparency = 1
ArraySettings.Parent = ThemePanel

local ArrayTitle = Instance.new("TextLabel")
ArrayTitle.Size = UDim2.new(1, 0, 0, 20)
ArrayTitle.BackgroundTransparency = 1
ArrayTitle.Text = "ArrayList Settings"
ArrayTitle.TextColor3 = Theme.TextSub
ArrayTitle.TextSize = 12
ArrayTitle.Font = Enum.Font.GothamMedium
ArrayTitle.TextXAlignment = Enum.TextXAlignment.Left
ArrayTitle.Parent = ArraySettings

-- ArrayList Enabled Toggle
local ArrayToggle = Instance.new("Frame")
ArrayToggle.Size = UDim2.new(1, 0, 0, 30)
ArrayToggle.Position = UDim2.new(0, 0, 0, 28)
ArrayToggle.BackgroundTransparency = 1
ArrayToggle.Parent = ArraySettings

local ArrayToggleLbl = Instance.new("TextLabel")
ArrayToggleLbl.Size = UDim2.new(1, -50, 1, 0)
ArrayToggleLbl.BackgroundTransparency = 1
ArrayToggleLbl.Text = "Enabled"
ArrayToggleLbl.TextColor3 = Theme.TextDim
ArrayToggleLbl.TextSize = 12
ArrayToggleLbl.Font = Enum.Font.Gotham
ArrayToggleLbl.TextXAlignment = Enum.TextXAlignment.Left
ArrayToggleLbl.Parent = ArrayToggle

local ArrayToggleBtn = Instance.new("TextButton")
ArrayToggleBtn.Size = UDim2.new(0, 40, 0, 20)
ArrayToggleBtn.Position = UDim2.new(1, -40, 0.5, -10)
ArrayToggleBtn.BackgroundColor3 = ArrayListSettings.enabled and Theme.Primary or Theme.Slider
ArrayToggleBtn.Text = ""
ArrayToggleBtn.Parent = ArrayToggle
Corner(ArrayToggleBtn, 10)

local ArrayToggleKnob = Instance.new("Frame")
ArrayToggleKnob.Size = UDim2.new(0, 16, 0, 16)
ArrayToggleKnob.Position = ArrayListSettings.enabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
ArrayToggleKnob.BackgroundColor3 = Theme.Text
ArrayToggleKnob.Parent = ArrayToggleBtn
Corner(ArrayToggleKnob, 8)

ArrayToggleBtn.MouseButton1Click:Connect(function()
    ArrayListSettings.enabled = not ArrayListSettings.enabled
    Tween(ArrayToggleBtn, {BackgroundColor3 = ArrayListSettings.enabled and Theme.Primary or Theme.Slider}, 0.15)
    Tween(ArrayToggleKnob, {Position = ArrayListSettings.enabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.15)
    ArrayList.Visible = ArrayListSettings.enabled
    RefreshArrayList()
end)

-- Show Binds Toggle
local BindsToggle = Instance.new("Frame")
BindsToggle.Size = UDim2.new(1, 0, 0, 30)
BindsToggle.Position = UDim2.new(0, 0, 0, 60)
BindsToggle.BackgroundTransparency = 1
BindsToggle.Parent = ArraySettings

local BindsToggleLbl = Instance.new("TextLabel")
BindsToggleLbl.Size = UDim2.new(1, -50, 1, 0)
BindsToggleLbl.BackgroundTransparency = 1
BindsToggleLbl.Text = "Show Keybinds"
BindsToggleLbl.TextColor3 = Theme.TextDim
BindsToggleLbl.TextSize = 12
BindsToggleLbl.Font = Enum.Font.Gotham
BindsToggleLbl.TextXAlignment = Enum.TextXAlignment.Left
BindsToggleLbl.Parent = BindsToggle

local BindsToggleBtn = Instance.new("TextButton")
BindsToggleBtn.Size = UDim2.new(0, 40, 0, 20)
BindsToggleBtn.Position = UDim2.new(1, -40, 0.5, -10)
BindsToggleBtn.BackgroundColor3 = ArrayListSettings.showBinds and Theme.Primary or Theme.Slider
BindsToggleBtn.Text = ""
BindsToggleBtn.Parent = BindsToggle
Corner(BindsToggleBtn, 10)

local BindsToggleKnob = Instance.new("Frame")
BindsToggleKnob.Size = UDim2.new(0, 16, 0, 16)
BindsToggleKnob.Position = ArrayListSettings.showBinds and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
BindsToggleKnob.BackgroundColor3 = Theme.Text
BindsToggleKnob.Parent = BindsToggleBtn
Corner(BindsToggleKnob, 8)

BindsToggleBtn.MouseButton1Click:Connect(function()
    ArrayListSettings.showBinds = not ArrayListSettings.showBinds
    Tween(BindsToggleBtn, {BackgroundColor3 = ArrayListSettings.showBinds and Theme.Primary or Theme.Slider}, 0.15)
    Tween(BindsToggleKnob, {Position = ArrayListSettings.showBinds and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.15)
    RefreshArrayList()
end)

-- Sort Mode
local SortOption = Instance.new("Frame")
SortOption.Size = UDim2.new(1, 0, 0, 30)
SortOption.Position = UDim2.new(0, 0, 0, 92)
SortOption.BackgroundTransparency = 1
SortOption.Parent = ArraySettings

local SortLbl = Instance.new("TextLabel")
SortLbl.Size = UDim2.new(1, -80, 1, 0)
SortLbl.BackgroundTransparency = 1
SortLbl.Text = "Sort Mode"
SortLbl.TextColor3 = Theme.TextDim
SortLbl.TextSize = 12
SortLbl.Font = Enum.Font.Gotham
SortLbl.TextXAlignment = Enum.TextXAlignment.Left
SortLbl.Parent = SortOption

local SortBtn = Instance.new("TextButton")
SortBtn.Size = UDim2.new(0, 75, 0, 24)
SortBtn.Position = UDim2.new(1, -75, 0.5, -12)
SortBtn.BackgroundColor3 = Theme.Slider
SortBtn.Text = ArrayListSettings.sortMode
SortBtn.TextColor3 = Theme.Text
SortBtn.TextSize = 11
SortBtn.Font = Enum.Font.GothamMedium
SortBtn.Parent = SortOption
Corner(SortBtn, 5)

SortBtn.MouseButton1Click:Connect(function()
    ArrayListSettings.sortMode = ArrayListSettings.sortMode == "Length" and "Alphabetical" or "Length"
    SortBtn.Text = ArrayListSettings.sortMode
    RefreshArrayList()
end)

-- Settings Button Click
local SettingsPanelOpen = false

SettingsBtn.MouseButton1Click:Connect(function()
    SettingsPanelOpen = not SettingsPanelOpen
    ThemePanel.Visible = SettingsPanelOpen
    SettingsScroll.Visible = not SettingsPanelOpen and SelectedModule ~= nil
    SettingsTitle.Visible = not SettingsPanelOpen
    
    if SettingsPanelOpen then
        SettingsBtn.TextColor3 = Theme.Primary
    else
        SettingsBtn.TextColor3 = Theme.TextDim
    end
end)

-- Settings Creators
local function CreateSettingToggle(parent, setting, order)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 28)
    container.BackgroundTransparency = 1
    container.LayoutOrder = order
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1
