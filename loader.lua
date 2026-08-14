local Repository = "https://raw.githubusercontent.com/zTonho/VoidraHub/refs/heads/main/"
local HubName = "voidra"
local HubVersion = "0.1.0-beta"
local SettingsFolder = "VoidraHub"
local CacheToken = tostring(os.time())

local Environment = (getgenv and getgenv()) or shared or _G

local function fetch(path)
    local url = Repository .. path .. "?v=" .. CacheToken
    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)

    if not ok then
        error(("[%s] Failed to download %s: %s"):format(HubName, path, tostring(source)), 2)
    end

    if type(source) ~= "string"
        or source == ""
        or source:match("^404")
        or source:find("404: Not Found", 1, true)
    then
        error(("[%s] Invalid response while downloading %s"):format(HubName, path), 2)
    end

    return source
end

local function run(path)
    local chunk, compileError = loadstring(fetch(path))

    if not chunk then
        error(("[%s] Failed to compile %s: %s"):format(HubName, path, tostring(compileError)), 2)
    end

    local ok, result = pcall(chunk)
    if not ok then
        error(("[%s] Failed to run %s: %s"):format(HubName, path, tostring(result)), 2)
    end

    return result
end

if Environment.VoidraHub and type(Environment.VoidraHub.Unload) == "function" then
    pcall(Environment.VoidraHub.Unload)
end

local Library = run("Library.lua")
local Loading = Library:CreateLoading({
    Title = HubName,
    CurrentStep = 1,
    TotalSteps = 4,
    AutoResizeHeight = true,
    WindowWidth = 430,
    WindowHeight = 250,
})

Loading:SetMessage("Loading interface")
Loading:SetDescription(HubVersion)

local ThemeManagerOk, ThemeManager = pcall(run, "addons/ThemeManager.lua")
Loading:SetCurrentStep(2)
Loading:SetMessage("Loading theme manager")

local SaveManagerOk, SaveManager = pcall(run, "addons/SaveManager.lua")
Loading:SetCurrentStep(3)
Loading:SetMessage("Creating window")

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title = HubName,
    Footer = HubVersion,
    Icon = "rbxthumb://type=Asset&id=72568647036813&w=150&h=150",
    IconSize = UDim2.fromOffset(20, 20),
    Font = Enum.Font.RobotoMono,
    AutoShow = true,
    Center = true,
    Resizable = false,
    EnableSidebarResize = false,
    EnableCompacting = false,
    NotifySide = "Left",
    ShowCustomCursor = true,
})

local Tabs = {
    Main = Window:AddTab("Main", "house"),
    Settings = Window:AddTab("UI Settings", "settings"),
}

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "settings")

MenuGroup:AddLabel("Menu keybind"):AddKeyPicker("MenuKeybind", {
    Text = "Menu keybind",
    Default = "RightControl",
    Mode = "Toggle",
    SyncToggleState = false,
})

Library.ToggleKeybind = Options.MenuKeybind

local unloaded = false
local function unload()
    if unloaded then
        return
    end

    unloaded = true

    if Environment.VoidraHub then
        Environment.VoidraHub = nil
    end

    if Library and type(Library.Unload) == "function" then
        Library:Unload()
    end
end

MenuGroup:AddButton({
    Text = "Unload",
    Func = unload,
})

if ThemeManagerOk and ThemeManager then
    ThemeManager:SetLibrary(Library)
    ThemeManager:SetFolder(SettingsFolder)
    ThemeManager:ApplyToTab(Tabs.Settings)

    pcall(function()
        ThemeManager:ApplyTheme("Material")

        if Options.ThemeManager_ThemeList then
            Options.ThemeManager_ThemeList:SetValue("Material")
        end
    end)
else
    warn(("[%s] ThemeManager unavailable: %s"):format(HubName, tostring(ThemeManager)))
end

if SaveManagerOk and SaveManager then
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
    SaveManager:SetFolder(SettingsFolder)
    SaveManager:SetSubFolder(tostring(game.PlaceId))
    SaveManager:BuildConfigSection(Tabs.Settings)

    pcall(function()
        SaveManager:LoadAutoloadConfig()
    end)
else
    warn(("[%s] SaveManager unavailable: %s"):format(HubName, tostring(SaveManager)))
end

pcall(function()
    Library:SetFont(Enum.Font.RobotoMono)

    if Options.FontFace then
        Options.FontFace:SetValue("RobotoMono")
    end
end)

Loading:SetCurrentStep(4)
Loading:SetMessage("Ready")
task.wait(0.2)
Loading:Destroy()

Environment.VoidraHub = {
    Library = Library,
    Window = Window,
    Tabs = Tabs,
    Options = Options,
    Toggles = Toggles,
    ThemeManager = ThemeManagerOk and ThemeManager or nil,
    SaveManager = SaveManagerOk and SaveManager or nil,
    Version = HubVersion,
    Unload = unload,
}

return Environment.VoidraHub
