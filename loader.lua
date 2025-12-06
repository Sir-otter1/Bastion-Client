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

-- Main loader function
local function LoadBastionClient()
    print("Loading Bastion Client...")

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
