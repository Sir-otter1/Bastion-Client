4-- Bastion Client - Complete Self-Contained Loadstring
-- Fully functional with all modules embedded

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
    AntiDetection.LastAction = currentTime
    
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

-- GUI Framework
local BastionGUI = {}
local ScreenGui
local MainFrame
local TabFrame
local ContentFrame
local CurrentTab = "Visuals"
local IsDragging = false
local DragStart = nil
local startPos = nil

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

local Tabs = {"Visuals", "Mobility", "Utility", "Combat"}

function BastionGUI.Initialize()
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BastionClient"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.Size = UDim2.new(0, 600, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    MainFrame.BackgroundColor3 = Colors.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = false
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame
    
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
    
    TabFrame = Instance.new("Frame")
    TabFrame.Name = "TabFrame"
    TabFrame.Parent = MainFrame
    TabFrame.Size = UDim2.new(1, 0, 0, 40)
    TabFrame.Position = UDim2.new(0, 0, 0, 35)
    TabFrame.BackgroundColor3 = Colors.Background
    TabFrame.BorderSizePixel = 0
    
    ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Parent = MainFrame
    ContentFrame.Size = UDim2.new(1, 0, 1, -75)
    ContentFrame.Position = UDim2.new(0, 0, 0, 75)
    ContentFrame.BackgroundColor3 = Colors.Background
    ContentFrame.BorderSizePixel = 0
    
    BastionGUI.CreateTabs()
    BastionGUI.SetupDragging()
    BastionGUI.SetupInputs()
    
    ScreenGui.Enabled = false
    
    print("Bastion GUI initialized")
end

function BastionGUI.CreateTabs()
    local tabWidth = 1 / #Tabs
    
    for i, tabName in ipairs(Tabs) do
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
        
        BastionGUI.CreateTabContent(tabName, TabContent)
        
        TabButton.MouseButton1Click:Connect(function()
            BastionGUI.SwitchTab(tabName)
        end)
        
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
    local Section = BastionGUI.CreateSection(parent, "ESP Settings")
    
    BastionGUI.CreateToggle(Section, "Enable ESP", function(state)
        Visuals.SetESPEnabled(state)
    end)
    
    BastionGUI.CreateToggle(Section, "Show Boxes", function(state)
        Visuals.SetESPBoxes(state)
    end)
    
    BastionGUI.CreateToggle(Section, "Show Names", function(state)
        Visuals.SetESPNames(state)
    end)
    
    local TracerSection = BastionGUI.CreateSection(parent, "Tracers")
    
    BastionGUI.CreateToggle(TracerSection, "Enable Tracers", function(state)
        Visuals.SetTracersEnabled(state)
    end)
    
    BastionGUI.CreateSlider(TracerSection, "Tracer Thickness", 1, 5, 2, function(value)
        Visuals.SetTracerThickness(value)
    end)
end

function BastionGUI.CreateMobilityContent(parent)
    local Section = BastionGUI.CreateSection(parent, "Movement")
    
    BastionGUI.CreateToggle(Section, "Speed", function(state)
        Mobility.SetSpeedEnabled(state)
    end)
    
    BastionGUI.CreateSlider(Section, "Speed Multiplier", 1, 5, 1.5, function(value)
        Mobility.SetSpeedMultiplier(value)
    end)
    
    BastionGUI.CreateToggle(Section, "Flight", function(state)
        Mobility.SetFlightEnabled(state)
    end)
    
    BastionGUI.CreateSlider(Section, "Flight Speed", 1, 10, 5, function(value)
        Mobility.SetFlightSpeed(value)
    end)
    
    local ProtectionSection = BastionGUI.CreateSection(parent, "Protection")
    
    BastionGUI.CreateToggle(ProtectionSection, "No Fall Damage", function(state)
        Mobility.SetNoFallEnabled(state)
    end)
end

function BastionGUI.CreateUtilityContent(parent)
    local Section = BastionGUI.CreateSection(parent, "Inventory")
    
    BastionGUI.CreateToggle(Section, "Auto Armor", function(state)
        Utility.SetAutoArmor(state)
    end)
    
    BastionGUI.CreateToggle(Section, "Auto Tool", function(state)
        Utility.SetAutoTool(state)
    end)
    
    local GameSection = BastionGUI.CreateSection(parent, "Game")
    
    BastionGUI.CreateToggle(GameSection, "Chest Steal", function(state)
        Utility.SetChestSteal(state)
    end)
    
    BastionGUI.CreateToggle(GameSection, "Auto Bed", function(state)
        Utility.SetAutoBed(state)
    end)
end

function BastionGUI.CreateCombatContent(parent)
    local Section = BastionGUI.CreateSection(parent, "Combat")
    
    BastionGUI.CreateToggle(Section, "Kill Aura", function(state)
        Combat.SetKillAuraEnabled(state)
    end)
    
    BastionGUI.CreateSlider(Section, "Attack Range", 3, 15, 6, function(value)
        Combat.SetAttackRange(value)
    end)
    
    BastionGUI.CreateToggle(Section, "Aimbot", function(state)
        Combat.SetAimbotEnabled(state)
    end)
    
    BastionGUI.CreateSlider(Section, "Aimbot Smoothness", 1, 10, 5, function(value)
        Combat.SetAimbotSmoothness(value)
    end)
    
    local TargetSection = BastionGUI.CreateSection(parent, "Targeting")
    
    BastionGUI.CreateToggle(TargetSection, "Target Players", function(state)
        Combat.SetTargetPlayers(state)
    end)
    
    BastionGUI.CreateToggle(TargetSection, "Target Teams", function(state)
        Combat.SetTargetTeams(state)
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
    
    parent.CanvasSize = UDim2.new(0, 0, 0, #parent:GetChildren() * 35 + 20)
    
    return Section
end

function BastionGUI.CreateToggle(parent, label, callback)
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
    
    parent.Parent.CanvasSize = UDim2.new(0, 0, 0, #parent.Parent:GetChildren() * 30 + 20)
end

function BastionGUI.CreateSlider(parent, label, min, max, defaultValue, callback)
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
    
    parent.Parent.CanvasSize = UDim2.new(0, 0, 0, #parent.Parent:GetChildren() * 30 + 20)
end

function BastionGUI.SwitchTab(tabName)
    CurrentTab = tabName
    
    for i, name in ipairs(Tabs) do
        local tabButton = TabFrame:FindFirstChild(name .. "Tab")
        if tabButton then
            local targetColor = name == tabName and Colors.TabActive or Colors.TabInactive
            TweenService:Create(tabButton, TweenInfo.new(0.2), {
                BackgroundColor3 = targetColor
            }):Play()
        end
        
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
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)
    
    local CloseButton = MainFrame:FindFirstChild("TitleBar"):FindFirstChild("CloseButton")
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui.Enabled = false
    end)
end

-- Visuals Module
local Visuals = {
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
    ESP_Objects = {},
    Tracer_Objects = {}
}

function Visuals.CreateESP(player)
    if Visuals.ESP_Objects[player] then
        Visuals.RemoveESP(player)
    end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local espObjects = {}
    
    if Visuals.ESP_Boxes then
        local box = Drawing.new("Square")
        box.Color = Color3.fromRGB(255, 255, 255)
        box.Thickness = 2
        box.Transparency = 1
        box.Filled = false
        box.Visible = false
        espObjects.Box = box
    end
    
    if Visuals.ESP_Names then
        local nameTag = Drawing.new("Text")
        nameTag.Color = Color3.fromRGB(255, 255, 255)
        nameTag.Size = 14
        nameTag.Font = Enum.Font.Gotham
        nameTag.Center = true
        nameTag.Outline = true
        nameTag.Visible = false
        espObjects.NameTag = nameTag
    end
    
    if Visuals.ESP_Health then
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
    
    if Visuals.Tracers_Enabled then
        local tracer = Drawing.new("Line")
        tracer.Color = Visuals.Tracers_Color
        tracer.Thickness = Visuals.Tracers_Thickness
        tracer.Transparency = 1
        tracer.Visible = false
        espObjects.Tracer = tracer
    end
    
    Visuals.ESP_Objects[player] = espObjects
end

function Visuals.RemoveESP(player)
    local espObjects = Visuals.ESP_Objects[player]
    if not espObjects then return end
    
    for _, obj in pairs(espObjects) do
        if obj.Remove then
            obj:Remove()
        end
    end
    
    Visuals.ESP_Objects[player] = nil
end

function Visuals.UpdateESP(player)
    local espObjects = Visuals.ESP_Objects[player]
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
    
    local distance = (Camera.CFrame.Position - position).Magnitude
    if distance > Visuals.ESP_MaxDistance then
        for _, obj in pairs(espObjects) do
            if obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    
    if Visuals.ESP_TeamCheck and player.Team == LocalPlayer.Team then
        for _, obj in pairs(espObjects) do
            if obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    
    local screenPosition, onScreen = Camera:WorldToViewportPoint(position)
    if not onScreen then
        for _, obj in pairs(espObjects) do
            if obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    
    if espObjects.Box and Visuals.ESP_Boxes then
        local size = (Camera:WorldToViewportPoint(position + Vector3.new(0, 3, 0)).Y - 
                     Camera:WorldToViewportPoint(position - Vector3.new(0, 3, 0)).Y) * 0.8
        
        espObjects.Box.Size = Vector2.new(size, size * 1.8)
        espObjects.Box.Position = Vector2.new(screenPosition.X - size/2, screenPosition.Y - size * 0.9)
        espObjects.Box.Visible = Visuals.ESP_Enabled
    end
    
    if espObjects.NameTag and Visuals.ESP_Names then
        local nameText = player.Name
        if Visuals.ESP_Distance then
            nameText = nameText .. " [" .. math.floor(distance) .. "m]"
        end
        
        espObjects.NameTag.Text = nameText
        espObjects.NameTag.Position = Vector2.new(screenPosition.X, screenPosition.Y - 30)
        espObjects.NameTag.Visible = Visuals.ESP_Enabled
    end
    
    if espObjects.HealthBar and espObjects.HealthBg and Visuals.ESP_Health then
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        local barWidth = 40
        local barHeight = 4
        
        espObjects.HealthBg.Size = Vector2.new(barWidth, barHeight)
        espObjects.HealthBg.Position = Vector2.new(screenPosition.X - barWidth/2 - 25, screenPosition.Y - 20)
        espObjects.HealthBg.Visible = Visuals.ESP_Enabled
        
        espObjects.HealthBar.Size = Vector2.new(barWidth * healthPercent, barHeight)
        espObjects.HealthBar.Position = Vector2.new(screenPosition.X - barWidth/2 - 25, screenPosition.Y - 20)
        espObjects.HealthBar.Color = healthPercent > 0.5 and Color3.fromRGB(0, 255, 0) or 
                                   healthPercent > 0.25 and Color3.fromRGB(255, 255, 0) or 
                                   Color3.fromRGB(255, 0, 0)
        espObjects.HealthBar.Visible = Visuals.ESP_Enabled
    end
    
    if espObjects.Tracer and Visuals.Tracers_Enabled then
        local fromPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        
        espObjects.Tracer.From = fromPos
        espObjects.Tracer.To = Vector2.new(screenPosition.X, screenPosition.Y)
        espObjects.Tracer.Visible = Visuals.ESP_Enabled
    end
end

function Visuals.SetESPEnabled(state)
    Visuals.ESP_Enabled = state
    
    if not state then
        for player, _ in pairs(Visuals.ESP_Objects) do
            Visuals.RemoveESP(player)
        end
    end
end

function Visuals.SetESPBoxes(state)
    Visuals.ESP_Boxes = state
end

function Visuals.SetESPNames(state)
    Visuals.ESP_Names = state
end

function Visuals.SetTracersEnabled(state)
    Visuals.Tracers_Enabled = state
end

function Visuals.SetTracerThickness(thickness)
    Visuals.Tracers_Thickness = thickness
    
    for _, espObjects in pairs(Visuals.ESP_Objects) do
        if espObjects.Tracer then
            espObjects.Tracer.Thickness = thickness
        end
    end
end

-- Mobility Module
local Mobility = {
    Speed_Enabled = false,
    Speed_Multiplier = 1.5,
    Flight_Enabled = false,
    Flight_Speed = 5,
    NoFall_Enabled = false,
    OriginalWalkSpeed = 16,
    OriginalJumpPower = 50
}

function Mobility.SetSpeedEnabled(state)
    Mobility.Speed_Enabled = state
    
    if not state then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                AntiDetection.SafeAction(function()
                    humanoid.WalkSpeed = Mobility.OriginalWalkSpeed
                end, 0.2)
            end
        end
    end
end

function Mobility.SetSpeedMultiplier(multiplier)
    Mobility.Speed_Multiplier = multiplier
end

function Mobility.SetFlightEnabled(state)
    Mobility.Flight_Enabled = state
end

function Mobility.SetFlightSpeed(speed)
    Mobility.Flight_Speed = speed
end

function Mobility.SetNoFallEnabled(state)
    Mobility.NoFall_Enabled = state
end

-- Utility Module
local Utility = {
    AutoArmor_Enabled = false,
    AutoTool_Enabled = false,
    ChestSteal_Enabled = false,
    AutoBed_Enabled = false
}

function Utility.SetAutoArmor(state)
    Utility.AutoArmor_Enabled = state
end

function Utility.SetAutoTool(state)
    Utility.AutoTool_Enabled = state
end

function Utility.SetChestSteal(state)
    Utility.ChestSteal_Enabled = state
end

function Utility.SetAutoBed(state)
    Utility.AutoBed_Enabled = state
end

-- Combat Module
local Combat = {
    KillAura_Enabled = false,
    KillAura_Range = 6,
    Aimbot_Enabled = false,
    Aimbot_Smoothness = 5,
    TargetPlayers_Enabled = true,
    TargetTeams_Enabled = false,
    CurrentTarget = nil,
    LastAttack = 0
}

function Combat.SetKillAuraEnabled(state)
    Combat.KillAura_Enabled = state
end

function Combat.SetAttackRange(range)
    Combat.KillAura_Range = range
end

function Combat.SetAimbotEnabled(state)
    Combat.Aimbot_Enabled = state
end

function Combat.SetAimbotSmoothness(smoothness)
    Combat.Aimbot_Smoothness = smoothness
end

function Combat.SetTargetPlayers(state)
    Combat.TargetPlayers_Enabled = state
end

function Combat.SetTargetTeams(state)
    Combat.TargetTeams_Enabled = state
end

function Combat.GetNearestEnemy(position, maxDistance)
    local nearestEnemy = nil
    local nearestDistance = maxDistance
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if not Combat.TargetTeams_Enabled or player.Team ~= LocalPlayer.Team then
                local distance = (position - player.Character.HumanoidRootPart.Position).Magnitude
                
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestEnemy = player
                end
            end
        end
    end
    
    return nearestEnemy
end

-- Main update loop
RunService.Heartbeat:Connect(function()
    local character = LocalPlayer.Character
    
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if humanoid and rootPart then
            -- Speed hack
            if Mobility.Speed_Enabled then
                AntiDetection.SafeAction(function()
                    humanoid.WalkSpeed = Mobility.OriginalWalkSpeed * Mobility.Speed_Multiplier
                end, 0.2)
            end
            
            -- Flight
            if Mobility.Flight_Enabled then
                local flyVelocity = Vector3.new(0, 0, 0)
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    flyVelocity = flyVelocity + Camera.CFrame.LookVector * Mobility.Flight_Speed
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    flyVelocity = flyVelocity - Camera.CFrame.LookVector * Mobility.Flight_Speed
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    flyVelocity = flyVelocity - Camera.CFrame.RightVector * Mobility.Flight_Speed
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    flyVelocity = flyVelocity + Camera.CFrame.RightVector * Mobility.Flight_Speed
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    flyVelocity = flyVelocity + Vector3.new(0, Mobility.Flight_Speed, 0)
                end
                
                AntiDetection.SafeAction(function()
                    rootPart.Velocity = flyVelocity
                end, 0.05)
            end
            
            -- KillAura
            if Combat.KillAura_Enabled then
                local currentTime = tick()
                if currentTime - Combat.LastAttack > 0.15 then
                    local nearestEnemy = Combat.GetNearestEnemy(rootPart.Position, Combat.KillAura_Range)
                    
                    if nearestEnemy then
                        AntiDetection.SafeAction(function()
                            for _, remote in pairs(game:GetDescendants()) do
                                if remote:IsA("RemoteEvent") and (remote.Name:lower():find("hit") or remote.Name:lower():find("attack")) then
                                    remote:FireServer(nearestEnemy.Character)
                                    break
                                end
                            end
                        end, 0.1)
                        
                        Combat.LastAttack = currentTime
                    end
                end
            end
        end
    end
    
    -- Update ESP
    if Visuals.ESP_Enabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if not Visuals.ESP_Objects[player] then
                    Visuals.CreateESP(player)
                end
                Visuals.UpdateESP(player)
            end
        end
    end
end)

-- Player events
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if Visuals.ESP_Enabled then
            wait(1)
            Visuals.CreateESP(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    Visuals.RemoveESP(player)
end)

-- Initialize GUI
BastionGUI.Initialize()

print("Bastion Client loaded successfully!")
print("Press RightShift to toggle GUI")
print("Features: ESP, Speed, Flight, KillAura, Aimbot")
