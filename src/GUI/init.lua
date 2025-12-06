-- Bastion Client GUI Framework
-- Custom non-AI looking GUI with tab system

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local BastionGUI = {}

-- GUI State
local ScreenGui
local MainFrame
local TabFrame
local ContentFrame
local CurrentTab = "Visuals"
local IsDragging = false
local DragStart = nil
local startPos = nil

-- Colors and styling
local Colors = {
    Background = Color3.fromRGB(25, 25, 35),
    Secondary = Color3.fromRGB(35, 35, 45),
    Accent = Color3.fromRGB(100, 150, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 180, 180),
    TabActive = Color3.fromRGB(80, 120, 200),
    TabInactive = Color3.fromRGB(50, 50, 60),
    Button = Color3.fromRGB(60, 60, 70),
    ButtonHover = Color3.fromRGB(70, 70, 80),
    ToggleOn = Color3.fromRGB(100, 200, 100),
    ToggleOff = Color3.fromRGB(200, 100, 100)
}

-- Tab definitions
local Tabs = {
    "Visuals",
    "Mobility", 
    "Utility",
    "Combat"
}

-- Module references (will be set by main.lua)
local Modules = {}

function BastionGUI.Initialize()
    -- Create main ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BastionClient"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create main frame
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.Size = UDim2.new(0, 600, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    MainFrame.BackgroundColor3 = Colors.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = false -- We'll handle dragging manually
    
    -- Add corner rounding
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame
    
    -- Add shadow effect
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Parent = MainFrame
    Shadow.Size = UDim2.new(1, 10, 1, 10)
    Shadow.Position = UDim2.new(0, -5, 0, -5)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://131604521"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.5
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    Shadow.ZIndex = MainFrame.ZIndex - 1
    
    -- Create title bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Parent = MainFrame
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.Position = UDim2.new(0, 0, 0, 0)
    TitleBar.BackgroundColor3 = Colors.Secondary
    TitleBar.BorderSizePixel = 0
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = TitleBar
    
    -- Title label
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Parent = TitleBar
    TitleLabel.Size = UDim2.new(0, 200, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = "Bastion Client"
    TitleLabel.TextColor3 = Colors.Text
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Close button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Parent = TitleBar
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -35, 0, 2.5)
    CloseButton.BackgroundColor3 = Colors.Button
    CloseButton.BorderSizePixel = 0
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Colors.Text
    CloseButton.TextSize = 18
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 4)
    CloseCorner.Parent = CloseButton
    
    -- Tab frame
    TabFrame = Instance.new("Frame")
    TabFrame.Name = "TabFrame"
    TabFrame.Parent = MainFrame
    TabFrame.Size = UDim2.new(1, 0, 0, 40)
    TabFrame.Position = UDim2.new(0, 0, 0, 35)
    TabFrame.BackgroundColor3 = Colors.Background
    TabFrame.BorderSizePixel = 0
    
    -- Content frame
    ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Parent = MainFrame
    ContentFrame.Size = UDim2.new(1, 0, 1, -75)
    ContentFrame.Position = UDim2.new(0, 0, 0, 75)
    ContentFrame.BackgroundColor3 = Colors.Background
    ContentFrame.BorderSizePixel = 0
    
    -- Create tabs
    BastionGUI.CreateTabs()
    
    -- Setup dragging
    BastionGUI.SetupDragging()
    
    -- Setup input handling
    BastionGUI.SetupInputs()
    
    -- Initially hide GUI
    ScreenGui.Enabled = false
    
    print("Bastion GUI initialized")
end

function BastionGUI.CreateTabs()
    local tabWidth = 1 / #Tabs
    
    for i, tabName in ipairs(Tabs) do
        -- Tab button
        local TabButton = Instance.new("TextButton")
        TabButton.Name = tabName .. "Tab"
        TabButton.Parent = TabFrame
        TabButton.Size = UDim2.new(tabWidth, -2, 1, 0)
        TabButton.Position = UDim2.new(tabWidth * (i - 1), i == 1 and 0 or 2, 0, 0)
        TabButton.BackgroundColor3 = i == 1 and Colors.TabActive or Colors.TabInactive
        TabButton.BorderSizePixel = 0
        TabButton.Font = Enum.Font.Gotham
        TabButton.Text = tabName
        TabButton.TextColor3 = Colors.Text
        TabButton.TextSize = 14
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 4)
        TabCorner.Parent = TabButton
        
        -- Tab content
        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = tabName .. "Content"
        TabContent.Parent = ContentFrame
        TabContent.Size = UDim2.new(1, -10, 1, -10)
        TabContent.Position = UDim2.new(0, 5, 0, 5)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.ScrollBarThickness = 4
        TabContent.ScrollBarImageColor3 = Colors.Accent
        TabContent.Visible = i == 1
        
        -- Add tab content based on module
        BastionGUI.CreateTabContent(tabName, TabContent)
        
        -- Tab click handler
        TabButton.MouseButton1Click:Connect(function()
            BastionGUI.SwitchTab(tabName)
        end)
        
        -- Tab hover effect
        TabButton.MouseEnter:Connect(function()
            if tabName ~= CurrentTab then
                TweenService:Create(TabButton, TweenInfo.new(0.2), {
                    BackgroundColor3 = Colors.TabActive
                }):Play()
            end
        end)
        
        TabButton.MouseLeave:Connect(function()
            if tabName ~= CurrentTab then
                TweenService:Create(TabButton, TweenInfo.new(0.2), {
                    BackgroundColor3 = Colors.TabInactive
                }):Play()
            end
        end)
    end
end

function BastionGUI.CreateTabContent(tabName, parent)
    if tabName == "Visuals" then
        BastionGUI.CreateVisualsContent(parent)
    elseif tabName == "Mobility" then
        BastionGUI.CreateMobilityContent(parent)
    elseif tabName == "Utility" then
        BastionGUI.CreateUtilityContent(parent)
    elseif tabName == "Combat" then
        BastionGUI.CreateCombatContent(parent)
    end
end

function BastionGUI.CreateVisualsContent(parent)
    -- Section: ESP
    local Section = BastionGUI.CreateSection(parent, "ESP Settings")
    
    BastionGUI.CreateToggle(Section, "Enable ESP", "esp_enabled", function(state)
        if Modules.Visuals then
            Modules.Visuals.SetESPEnabled(state)
        end
    end)
    
    BastionGUI.CreateToggle(Section, "Show Boxes", "esp_boxes", function(state)
        if Modules.Visuals then
            Modules.Visuals.SetESPBoxes(state)
        end
    end)
    
    BastionGUI.CreateToggle(Section, "Show Names", "esp_names", function(state)
        if Modules.Visuals then
            Modules.Visuals.SetESPNames(state)
        end
    end)
    
    BastionGUI.CreateToggle(Section, "Show Health", "esp_health", function(state)
        if Modules.Visuals then
            Modules.Visuals.SetESPHealth(state)
        end
    end)
    
    -- Section: Tracers
    local TracerSection = BastionGUI.CreateSection(parent, "Tracers")
    
    BastionGUI.CreateToggle(TracerSection, "Enable Tracers", "tracers_enabled", function(state)
        if Modules.Visuals then
            Modules.Visuals.SetTracersEnabled(state)
        end
    end)
    
    BastionGUI.CreateSlider(TracerSection, "Tracer Thickness", "tracer_thickness", 1, 5, 2, function(value)
        if Modules.Visuals then
            Modules.Visuals.SetTracerThickness(value)
        end
    end)
end

function BastionGUI.CreateMobilityContent(parent)
    -- Section: Movement
    local Section = BastionGUI.CreateSection(parent, "Movement")
    
    BastionGUI.CreateToggle(Section, "Speed", "speed_enabled", function(state)
        if Modules.Mobility then
            Modules.Mobility.SetSpeedEnabled(state)
        end
    end)
    
    BastionGUI.CreateSlider(Section, "Speed Multiplier", "speed_multiplier", 1, 5, 1.5, function(value)
        if Modules.Mobility then
            Modules.Mobility.SetSpeedMultiplier(value)
        end
    end)
    
    BastionGUI.CreateToggle(Section, "Flight", "flight_enabled", function(state)
        if Modules.Mobility then
            Modules.Mobility.SetFlightEnabled(state)
        end
    end)
    
    BastionGUI.CreateSlider(Section, "Flight Speed", "flight_speed", 1, 10, 5, function(value)
        if Modules.Mobility then
            Modules.Mobility.SetFlightSpeed(value)
        end
    end)
    
    -- Section: Protection
    local ProtectionSection = BastionGUI.CreateSection(parent, "Protection")
    
    BastionGUI.CreateToggle(ProtectionSection, "No Fall Damage", "nofall_enabled", function(state)
        if Modules.Mobility then
            Modules.Mobility.SetNoFallEnabled(state)
        end
    end)
end

function BastionGUI.CreateUtilityContent(parent)
    -- Section: Inventory
    local Section = BastionGUI.CreateSection(parent, "Inventory")
    
    BastionGUI.CreateToggle(Section, "Auto Armor", "auto_armor", function(state)
        if Modules.Utility then
            Modules.Utility.SetAutoArmor(state)
        end
    end)
    
    BastionGUI.CreateToggle(Section, "Auto Tool", "auto_tool", function(state)
        if Modules.Utility then
            Modules.Utility.SetAutoTool(state)
        end
    end)
    
    -- Section: Game
    local GameSection = BastionGUI.CreateSection(parent, "Game")
    
    BastionGUI.CreateToggle(GameSection, "Chest Steal", "chest_steal", function(state)
        if Modules.Utility then
            Modules.Utility.SetChestSteal(state)
        end
    end)
    
    BastionGUI.CreateToggle(GameSection, "Auto Bed", "auto_bed", function(state)
        if Modules.Utility then
            Modules.Utility.SetAutoBed(state)
        end
    end)
end

function BastionGUI.CreateCombatContent(parent)
    -- Section: Combat
    local Section = BastionGUI.CreateSection(parent, "Combat")
    
    BastionGUI.CreateToggle(Section, "Kill Aura", "killaura_enabled", function(state)
        if Modules.Combat then
            Modules.Combat.SetKillAuraEnabled(state)
        end
    end)
    
    BastionGUI.CreateSlider(Section, "Attack Range", "attack_range", 3, 15, 6, function(value)
        if Modules.Combat then
            Modules.Combat.SetAttackRange(value)
        end
    end)
    
    BastionGUI.CreateToggle(Section, "Aimbot", "aimbot_enabled", function(state)
        if Modules.Combat then
            Modules.Combat.SetAimbotEnabled(state)
        end
    end)
    
    BastionGUI.CreateSlider(Section, "Aimbot Smoothness", "aimbot_smooth", 1, 10, 5, function(value)
        if Modules.Combat then
            Modules.Combat.SetAimbotSmoothness(value)
        end
    end)
    
    -- Section: Targeting
    local TargetSection = BastionGUI.CreateSection(parent, "Targeting")
    
    BastionGUI.CreateToggle(TargetSection, "Target Players", "target_players", function(state)
        if Modules.Combat then
            Modules.Combat.SetTargetPlayers(state)
        end
    end)
    
    BastionGUI.CreateToggle(TargetSection, "Target Teams", "target_teams", function(state)
        if Modules.Combat then
            Modules.Combat.SetTargetTeams(state)
        end
    end)
end

function BastionGUI.CreateSection(parent, title)
    local Section = Instance.new("Frame")
    Section.Name = title .. "Section"
    Section.Parent = parent
    Section.Size = UDim2.new(1, -10, 0, 30)
    Section.Position = UDim2.new(0, 5, 0, #parent:GetChildren() * 35)
    Section.BackgroundColor3 = Colors.Secondary
    Section.BorderSizePixel = 0
    
    local SectionCorner = Instance.new("UICorner")
    SectionCorner.CornerRadius = UDim.new(0, 4)
    SectionCorner.Parent = Section
    
    local SectionLabel = Instance.new("TextLabel")
    SectionLabel.Name = "SectionLabel"
    SectionLabel.Parent = Section
    SectionLabel.Size = UDim2.new(1, -10, 1, 0)
    SectionLabel.Position = UDim2.new(0, 5, 0, 0)
    SectionLabel.BackgroundTransparency = 1
    SectionLabel.Font = Enum.Font.GothamBold
    SectionLabel.Text = title
    SectionLabel.TextColor3 = Colors.Text
    SectionLabel.TextSize = 14
    SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Update content frame size
    local contentHeight = #parent:GetChildren() * 35
    parent.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 20)
    
    return Section
end

function BastionGUI.CreateToggle(parent, label, configKey, callback)
    local Toggle = Instance.new("Frame")
    Toggle.Name = label .. "Toggle"
    Toggle.Parent = parent.Parent
    Toggle.Size = UDim2.new(1, -10, 0, 25)
    Toggle.Position = UDim2.new(0, 5, 0, #parent.Parent:GetChildren() * 30)
    Toggle.BackgroundTransparency = 1
    
    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Name = "ToggleLabel"
    ToggleLabel.Parent = Toggle
    ToggleLabel.Size = UDim2.new(0, 200, 1, 0)
    ToggleLabel.Position = UDim2.new(0, 0, 0, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Font = Enum.Font.Gotham
    ToggleLabel.Text = label
    ToggleLabel.TextColor3 = Colors.Text
    ToggleLabel.TextSize = 12
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Parent = Toggle
    ToggleButton.Size = UDim2.new(0, 40, 0, 20)
    ToggleButton.Position = UDim2.new(1, -45, 0, 2.5)
    ToggleButton.BackgroundColor3 = Colors.ToggleOff
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Font = Enum.Font.Gotham
    ToggleButton.Text = ""
    ToggleButton.TextSize = 12
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 10)
    ToggleCorner.Parent = ToggleButton
    
    local ToggleKnob = Instance.new("Frame")
    ToggleKnob.Name = "ToggleKnob"
    ToggleKnob.Parent = ToggleButton
    ToggleKnob.Size = UDim2.new(0, 16, 0, 16)
    ToggleKnob.Position = UDim2.new(0, 2, 0, 2)
    ToggleKnob.BackgroundColor3 = Colors.Text
    ToggleKnob.BorderSizePixel = 0
    
    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(0, 8)
    KnobCorner.Parent = ToggleKnob
    
    local isOn = false
    
    local function updateToggle(state)
        isOn = state
        local targetColor = state and Colors.ToggleOn or Colors.ToggleOff
        local targetPosition = state and UDim2.new(0, 22, 0, 2) or UDim2.new(0, 2, 0, 2)
        
        TweenService:Create(ToggleButton, TweenInfo.new(0.2), {
            BackgroundColor3 = targetColor
        }):Play()
        
        TweenService:Create(ToggleKnob, TweenInfo.new(0.2), {
            Position = targetPosition
        }):Play()
        
        if callback then
            callback(state)
        end
    end
    
    ToggleButton.MouseButton1Click:Connect(function()
        updateToggle(not isOn)
    end)
    
    -- Update content frame size
    parent.Parent.CanvasSize = UDim2.new(0, 0, 0, #parent.Parent:GetChildren() * 30 + 20)
end

function BastionGUI.CreateSlider(parent, label, configKey, min, max, defaultValue, callback)
    local Slider = Instance.new("Frame")
    Slider.Name = label .. "Slider"
    Slider.Parent = parent.Parent
    Slider.Size = UDim2.new(1, -10, 0, 35)
    Slider.Position = UDim2.new(0, 5, 0, #parent.Parent:GetChildren() * 30)
    Slider.BackgroundTransparency = 1
    
    local SliderLabel = Instance.new("TextLabel")
    SliderLabel.Name = "SliderLabel"
    SliderLabel.Parent = Slider
    SliderLabel.Size = UDim2.new(0, 200, 0, 20)
    SliderLabel.Position = UDim2.new(0, 0, 0, 0)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.Font = Enum.Font.Gotham
    SliderLabel.Text = label
    SliderLabel.TextColor3 = Colors.Text
    SliderLabel.TextSize = 12
    SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Name = "ValueLabel"
    ValueLabel.Parent = Slider
    ValueLabel.Size = UDim2.new(0, 50, 0, 20)
    ValueLabel.Position = UDim2.new(1, -55, 0, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Font = Enum.Font.Gotham
    ValueLabel.Text = tostring(defaultValue)
    ValueLabel.TextColor3 = Colors.TextSecondary
    ValueLabel.TextSize = 12
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    local SliderBar = Instance.new("Frame")
    SliderBar.Name = "SliderBar"
    SliderBar.Parent = Slider
    SliderBar.Size = UDim2.new(1, -60, 0, 4)
    SliderBar.Position = UDim2.new(0, 0, 0, 25)
    SliderBar.BackgroundColor3 = Colors.Button
    SliderBar.BorderSizePixel = 0
    
    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(0, 2)
    BarCorner.Parent = SliderBar
    
    local SliderFill = Instance.new("Frame")
    SliderFill.Name = "SliderFill"
    SliderFill.Parent = SliderBar
    SliderFill.Size = UDim2.new((defaultValue - min) / (max - min), 0, 1, 0)
    SliderFill.Position = UDim2.new(0, 0, 0, 0)
    SliderFill.BackgroundColor3 = Colors.Accent
    SliderFill.BorderSizePixel = 0
    
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 2)
    FillCorner.Parent = SliderFill
    
    local SliderButton = Instance.new("TextButton")
    SliderButton.Name = "SliderButton"
    SliderButton.Parent = Slider
    SliderButton.Size = UDim2.new(1, -60, 0, 20)
    SliderButton.Position = UDim2.new(0, 0, 0, 15)
    SliderButton.BackgroundTransparency = 1
    SliderButton.BorderSizePixel = 0
    SliderButton.Text = ""
    SliderButton.TextSize = 12
    
    local isDragging = false
    local currentValue = defaultValue
    
    local function updateValue(value)
        currentValue = math.clamp(value, min, max)
        ValueLabel.Text = string.format("%.1f", currentValue)
        
        local fillPercent = (currentValue - min) / (max - min)
        SliderFill.Size = UDim2.new(fillPercent, 0, 1, 0)
        
        if callback then
            callback(currentValue)
        end
    end
    
    SliderButton.MouseButton1Down:Connect(function()
        isDragging = true
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relativeX = (input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X
            local value = min + (relativeX * (max - min))
            updateValue(value)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    
    -- Update content frame size
    parent.Parent.CanvasSize = UDim2.new(0, 0, 0, #parent.Parent:GetChildren() * 30 + 20)
end

function BastionGUI.SwitchTab(tabName)
    CurrentTab = tabName
    
    -- Update tab buttons
    for i, name in ipairs(Tabs) do
        local tabButton = TabFrame:FindFirstChild(name .. "Tab")
        if tabButton then
            local targetColor = name == tabName and Colors.TabActive or Colors.TabInactive
            TweenService:Create(tabButton, TweenInfo.new(0.2), {
                BackgroundColor3 = targetColor
            }):Play()
        end
        
        -- Update tab content visibility
        local tabContent = ContentFrame:FindFirstChild(name .. "Content")
        if tabContent then
            tabContent.Visible = name == tabName
        end
    end
end

function BastionGUI.SetupDragging()
    local TitleBar = MainFrame:FindFirstChild("TitleBar")
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            IsDragging = true
            DragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if IsDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - DragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            IsDragging = false
        end
    end)
end

function BastionGUI.SetupInputs()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Insert then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)
    
    -- Close button
    local CloseButton = MainFrame:FindFirstChild("TitleBar"):FindFirstChild("CloseButton")
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui.Enabled = false
    end)
end

function BastionGUI.SetModules(modules)
    Modules = modules
end

function BastionGUI.IsVisible()
    return ScreenGui and ScreenGui.Enabled
end

function BastionGUI.SetVisible(visible)
    if ScreenGui then
        ScreenGui.Enabled = visible
    end
end

function BastionGUI.Update()
    -- GUI updates happen in real-time through tweens and events
end

function BastionGUI.Cleanup()
    if ScreenGui then
        ScreenGui:Destroy()
    end
end

return BastionGUI
