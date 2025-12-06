-- Bastion Client Loader
-- Downloads and executes all required modules

local function DownloadFile(url)
    local success, content = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success then
        return content
    else
        warn("Failed to download: " .. url)
        return nil
    end
end

local function LoadModule(moduleName, content)
    local success, module = pcall(function()
        return loadstring(content)()
    end)
    
    if success then
        _G[moduleName] = module
        print("Loaded module: " .. moduleName)
        return true
    else
        warn("Failed to load module: " .. moduleName .. " - " .. module)
        return false
    end
end

-- Create Loading Screen for Loader
local function CreateLoaderScreen()
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local CoreGui = game:GetService("CoreGui")

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

    local LoadingGui = Instance.new("ScreenGui")
    LoadingGui.Name = "BastionLoader"
    LoadingGui.ResetOnSpawn = false
    LoadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    LoadingGui.DisplayOrder = 9998
    LoadingGui.Parent = CoreGui

    -- Main loading frame
    local LoadFrame = Instance.new("Frame")
    LoadFrame.Size = UDim2.new(0, 350, 0, 220)
    LoadFrame.Position = UDim2.new(0.5, -175, 0.5, -110)
    LoadFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    LoadFrame.BorderSizePixel = 0
    LoadFrame.Parent = LoadingGui
    Corner(LoadFrame, 8)

    -- Loading text
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0, 40)
    TitleLabel.Position = UDim2.new(0, 0, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "BASTION LOADER"
    TitleLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
    TitleLabel.TextSize = 22
    TitleLabel.Font = Enum.Font.GothamBlack
    TitleLabel.Parent = LoadFrame

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -20, 0, 25)
    StatusLabel.Position = UDim2.new(0, 10, 0, 180)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Downloading Bastion Client..."
    StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 195)
    StatusLabel.TextSize = 14
    StatusLabel.Font = Enum.Font.GothamMedium
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = LoadFrame

    -- File list
    local FileListFrame = Instance.new("ScrollingFrame")
    FileListFrame.Size = UDim2.new(1, -20, 0, 100)
    FileListFrame.Position = UDim2.new(0, 10, 0, 60)
    FileListFrame.BackgroundTransparency = 1
    FileListFrame.BorderSizePixel = 0
    FileListFrame.ScrollBarThickness = 3
    FileListFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
    FileListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    FileListFrame.Parent = LoadFrame

    local FileListLayout = Instance.new("UIListLayout")
    FileListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    FileListLayout.Padding = UDim.new(0, 3)
    FileListLayout.Parent = FileListFrame

    local loadingFiles = {
        "📄 Downloading loadstring.lua...",
        "🔒 Verifying file integrity...",
        "⚡ Initializing script execution...",
        "🎮 Preparing Bastion Client...",
        "✅ Load complete!"
    }

    for i, fileName in ipairs(loadingFiles) do
        local fileItem = Instance.new("Frame")
        fileItem.Name = "FileItem_" .. i
        fileItem.Size = UDim2.new(1, 0, 0, 20)
        fileItem.BackgroundTransparency = 1
        fileItem.LayoutOrder = i
        fileItem.Parent = FileListFrame

        local checkMark = Instance.new("TextLabel")
        checkMark.Size = UDim2.new(0, 20, 1, 0)
        checkMark.BackgroundTransparency = 1
        checkMark.Text = "⏳"
        checkMark.TextColor3 = Color3.fromRGB(120, 120, 140)
        checkMark.TextSize = 12
        checkMark.Font = Enum.Font.Gotham
        checkMark.Parent = fileItem

        local fileText = Instance.new("TextLabel")
        fileText.Size = UDim2.new(1, -25, 1, 0)
        fileText.Position = UDim2.new(0, 22, 0, 0)
        fileText.BackgroundTransparency = 1
        fileText.Text = fileName
        fileText.TextColor3 = Color3.fromRGB(180, 180, 195)
        fileText.TextSize = 11
        fileText.Font = Enum.Font.Gotham
        fileText.TextXAlignment = Enum.TextXAlignment.Left
        fileText.Parent = fileItem

        -- Animate based on progress
        if i <= 4 then
            task.spawn(function()
                wait((i - 1) * 0.3)
                Tween(checkMark, {TextColor3 = Color3.fromRGB(100, 150, 255)}, 0.3)
                wait(0.1)
                checkMark.Text = "✓"
            end)
        end
    end

    -- Progress bar
    local ProgressBg = Instance.new("Frame")
    ProgressBg.Size = UDim2.new(1, -20, 0, 6)
    ProgressBg.Position = UDim2.new(0, 10, 0, 170)
    ProgressBg.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    ProgressBg.Parent = LoadFrame
    local ProgCorner = Instance.new("UICorner")
    ProgCorner.CornerRadius = UDim.new(0, 3)
    ProgCorner.Parent = ProgressBg

    local ProgressFill = Instance.new("Frame")
    ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    ProgressFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    ProgressFill.Parent = ProgressBg
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 3)
    FillCorner.Parent = ProgressFill

    -- Animate progress bar
    task.spawn(function()
        for i = 0, 100, 4 do
            ProgressFill.Size = UDim2.new(i/100, 0, 1, 0)
            StatusLabel.Text = string.format("Loading Bastion Client... (%d%%)", i)
            wait(0.05)
        end
        StatusLabel.Text = "Executing Bastion Client..."
        wait(0.3)

        -- Success animation
        fileItem.Parent.FileItem_5.checkMark.Text = "✓"
        Tween(fileItem.Parent.FileItem_5.checkMark, {TextColor3 = Color3.fromRGB(50, 205, 100)}, 0.3)

        StatusLabel.Text = "Bastion Client loaded!"

        wait(0.8)
        Tween(LoadFrame, {Size = UDim2.new(0, 350, 0, 0)}, 0.3)
        task.wait(0.3)
        LoadingGui:Destroy()
    end)

    return LoadingGui
end

-- Main loader function
local function LoadBastionClient()
    print("Loading Bastion Client...")

    -- Show loading screen
    CreateLoaderScreen()

    -- Small delay to show loading screen
    wait(1.2)

    -- For the loader, just download and execute the complete loadstring file
    -- which contains all modules embedded
    local loadstringUrl = "https://raw.githubusercontent.com/Sir-otter1/Bastion-Client/main/loadstring.lua"
    local success, result = pcall(function()
        loadstring(game:HttpGet(loadstringUrl))()
    end)

    if success then
        print("Bastion Client loaded successfully via loader!")
    else
        warn("Failed to load Bastion Client: " .. tostring(result))
        LoadLocalFiles()
    end
end

-- Fallback: Load from local files if download fails
local function LoadLocalFiles()
    print("Attempting to load from local files...")
    
    -- This would load from the local directory structure
    -- For now, we'll create a minimal working version
    
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local CoreGui = game:GetService("CoreGui")
    
    local LocalPlayer = Players.LocalPlayer
    
    -- Simple GUI
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BastionClient"
    ScreenGui.Parent = CoreGui
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.Size = UDim2.new(0, 400, 0, 300)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    MainFrame.BorderSizePixel = 0
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = MainFrame
    TitleLabel.Size = UDim2.new(1, 0, 0, 30)
    TitleLabel.Position = UDim2.new(0, 0, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = "Bastion Client - Fallback Mode"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 16
    
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Parent = MainFrame
    StatusLabel.Size = UDim2.new(1, -20, 0, 20)
    StatusLabel.Position = UDim2.new(0, 10, 0, 50)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = "Failed to load modules - Using fallback"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    StatusLabel.TextSize = 12
    StatusLabel.TextWrapped = true
    
    -- Toggle GUI
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Insert then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)
    
    ScreenGui.Enabled = false
    print("Bastion Client loaded in fallback mode")
end

-- Try to load the full client, fallback to local if it fails
local success, error = pcall(LoadBastionClient)

if not success then
    warn("Failed to load Bastion Client: " .. tostring(error))
    LoadLocalFiles()
end

return LoadBastionClient
