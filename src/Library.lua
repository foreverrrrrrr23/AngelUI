-- Extension factory. Build output embeds the pinned Obsidian source in Library.lua.
return function(Library, style, overlays, persistence)
    Library.AngelVersion = "1.0.0"
    style(Library)
    local createWindow = Library.CreateWindow
    function Library:CreateWindow(options)
        options = table.clone(options or {})
        local defaults = {
            Title = "Angel UI",
            Footer = "Angel UI",
            Size = UDim2.fromOffset(800, 560),
            Center = true,
            AutoShow = true,
            Resizable = true,
            CornerRadius = 14,
            Font = Enum.Font.Gotham,
            ShowCustomCursor = false,
            ShowMobileButtons = false,
            ToggleKeybind = Enum.KeyCode.LeftControl,
            SidebarCompactWidth = 52,
            EnableCompacting = true,
            EnableSidebarResize = false,
            TabButtonsStyle = { Gap = 6, Padding = 6, CornerRadius = 12, Indicator = false },
            Animations = { ToggleWindow = false, TabSwitch = true, Groupbox = true, Dropdown = true },
        }
        for key, value in pairs(defaults) do
            if options[key] == nil then
                options[key] = value
            end
        end
        local window = createWindow(self, options)
        local autoCompact = options.AutoCompactSidebar ~= false
        local compactOptions = type(options.AutoCompactSidebar) == "table" and options.AutoCompactSidebar or {}
        local compactBelow = compactOptions.CompactBelow or 660
        local expandedWidth = compactOptions.ExpandedWidth or 144
        local refreshingSidebar = false
        function window:RefreshSidebar()
            if refreshingSidebar or Library.Unloaded or not autoCompact then
                return
            end
            refreshingSidebar = true
            local width = self.MainFrame.AbsoluteSize.X
            if width == 0 then
                width = self.MainFrame.Size.X.Offset * Library.DPIScale
            end
            local compact = width < compactBelow
            self:SetSidebarWidth(compact and options.SidebarCompactWidth or expandedWidth)
            for _, button in ipairs(Library.TabButtons) do
                button.Label.Visible = not compact
                if button.Icon then
                    button.Icon.AnchorPoint = compact and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5)
                    button.Icon.Position = compact and UDim2.fromScale(0.5, 0.5) or UDim2.fromScale(0, 0.5)
                    button.Icon.Size = UDim2.fromOffset(20, 20)
                    button.Label.TextSize = 13
                    button.Padding.PaddingTop, button.Padding.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
                end
            end
            refreshingSidebar = false
        end
        function window:SetAutoCompactSidebarEnabled(enabled)
            autoCompact = enabled == true
            self:RefreshSidebar()
        end
        local addTab = window.AddTab
        function window:AddTab(...)
            local tab = addTab(self, ...)
            if options.CustomStyling ~= false then
                Library:StyleTab(tab)
            end
            self:RefreshSidebar()
            return tab
        end
        self:GiveSignal(window.MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            window:RefreshSidebar()
        end))
        window:RefreshSidebar()
        overlays(self, window, options, persistence)
        self:SetAngelTheme(options.AngelTheme or "Sakura Bloom")
        if options.Responsive ~= false then
            local function resize()
                if self.Unloaded then
                    return
                end
                local viewport = self.ScreenGui.AbsoluteSize
                local logical = window.MainFrame.Size
                local scale = math.clamp(
                    math.min(1, (viewport.X - 24) / logical.X.Offset, (viewport.Y - 24) / logical.Y.Offset),
                    0.25,
                    1
                )
                self:SetDPIScale(scale * 100)
            end
            self:GiveSignal(self.ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))
            self:GiveSignal(window.MainFrame:GetPropertyChangedSignal("Size"):Connect(resize))
            resize()
        end
        return window
    end
    return Library
end
