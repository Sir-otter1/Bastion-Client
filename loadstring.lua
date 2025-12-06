-- Bastion Client Loadstring
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
    
    -- Base URL for raw files (update with your actual repo)
    local baseUrl = "https://raw.githubusercontent.com/yourusername/Bastion-Client/main/src/"
    
    -- List of required files
    local requiredFiles = {
        {name = "Config", file = "Config.lua"},
        {name = "GUI", file = "GUI/init.lua"},
        {name = "Visuals", file = "Modules/Visuals.lua"},
        {name = "Mobility", file = "Modules/Mobility.lua"},
        {name = "Utility", file = "Modules/Utility.lua"},
        {name = "Combat", file = "Modules/Combat.lua"},
        {name = "RaycastHandler", file = "Modules/RaycastHandler.lua"},
        {name = "Main", file = "main.lua"}
    }
    
    -- Download and load all modules
    local loadedModules = 0
    
    for _, moduleInfo in pairs(requiredFiles) do
        local url = baseUrl .. moduleInfo.file
        local content = DownloadFile(url)
        
        if content then
            if LoadModule(moduleInfo.name, content) then
                loadedModules = loadedModules + 1
            end
        end
        
        wait(0.1) -- Small delay to avoid rate limiting
    end
    
    -- Initialize the main client
    if _G.Main then
        print("Initializing Bastion Client...")
        _G.Main.Initialize()
        print("Bastion Client loaded successfully!")
        print("Press INSERT to toggle GUI")
    else
        warn("Failed to load main module")
    end
    
    print(string.format("Loaded %d/%d modules", loadedModules, #requiredFiles))
end

-- Fallback: Load from local files if download fails
local function LoadLocalFiles()
    print("Attempting to load from local files...")
    
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

-- Return the loadstring for easy execution
return LoadBastionClient
