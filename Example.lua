-- Replace foreverrrrrrr23 with the owner of your published repository.
local base = "https://raw.githubusercontent.com/foreverrrrrrr23/AngelUI/main/"
local Library = loadstring(game:HttpGet(base .. "Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Angel Hub",
    Version = "2.0",
    Footer = "Angel UI • Example",
    Icon = "rbxassetid://77132715337164",
    AngelTheme = "Sakura Bloom",
    Size = UDim2.fromOffset(800, 560),
    StatusPanel = { Enabled = true },
    MobileButton = { Enabled = true },
    Persistence = { Enabled = true, Folder = "AngelUI", Key = "MyScript" },
    AutoCompactSidebar = { CompactBelow = 660, ExpandedWidth = 144 },
})

local Main = Window:AddTab({ Name = "Dashboard", Icon = "layout-dashboard", Description = "Your script overview" })
local Features = Main:AddLeftGroupbox("Features", "sparkles")
Features:AddToggle("ExampleAutoFarm", {
    Text = "Auto Farm",
    Default = false,
    Callback = function(enabled)
        print("Example only: Auto Farm", enabled)
    end,
})
Features:AddDropdown("ExampleTargets", {
    Text = "Targets",
    Values = { "Target A", "Target B", "Target C" },
    Multi = true,
    DragSelect = false,
    AllowNull = true,
    Callback = function(selected)
        print("Selection changed", selected)
    end,
})
local Settings = Window:AddTab({ Name = "Config", Icon = "settings", Description = "Appearance and overlays" })
local Overlays = Settings:AddLeftGroupbox("Overlays", "panels-top-left")
Overlays:AddToggle("ExampleHUD", {
    Text = "FPS / Ping Panel",
    Default = true,
    Callback = function(enabled)
        Window:SetStatusPanelEnabled(enabled)
    end,
})
Overlays:AddToggle("ExampleMobile", {
    Text = "Small Reopen Button",
    Default = true,
    Callback = function(enabled)
        Window:SetMobileButtonEnabled(enabled)
    end,
})
Overlays:AddToggle("ExampleCompact", {
    Text = "Compact Sidebar Automatically",
    Default = true,
    Callback = function(enabled)
        Window:SetAutoCompactSidebarEnabled(enabled)
    end,
})
Overlays:AddDropdown("ExampleTheme", {
    Text = "Theme",
    Values = Library:GetAngelThemes(),
    Default = "Sakura Bloom",
    Callback = function(theme)
        Library:SetAngelTheme(theme)
    end,
})
Overlays:AddButton({
    Text = "Reset Overlay Positions",
    Func = function()
        Window:ResetOverlayPositions()
    end,
})
Overlays:AddButton({
    Text = "Minimize",
    Func = function()
        Library:Toggle(false)
    end,
})
Window:RefreshStatusPanelIdentity({ Name = "Angel Hub", Private = true })
