-- Host-specific menu routing; contains no farm workers or game remote calls.
return function(Context)
    local Runtime, Config = Context.Runtime, Context.Config
    local HubEnvironment = Context.Environment
    local withExecutorUIContext = Context.UIContext
    local enemyDisplayLabel = Context.EnemyLabel
    local HUB_THEME_LOGOS = Context.ThemeLogos
    local ANGEL_HUB_LOGO = Context.Logo
    local env = getgenv()
    if env.AngelObsidianPreview then
        env.AngelObsidianPreview.destroy()
    end
    local L = assert(Context.Library, "AngelUI library is required")
    -- Keep descriptions readable and allow status controls to update their tooltip.
    local addTooltip = L.AddTooltip
    local function wrapTooltip(text)
        if type(text) ~= "string" then
            return text
        end
        local lines, line = {}, ""
        for word in text:gmatch("%S+") do
            if #line + #word > 62 then
                table.insert(lines, line)
                line = ""
            end
            line = line == "" and word or line .. " " .. word
        end
        table.insert(lines, line)
        return table.concat(lines, "\n")
    end
    function L:AddTooltip(text, disabledText, target)
        local tooltip = addTooltip(self, wrapTooltip(text), wrapTooltip(disabledText), target)
        tooltip._angelTarget = target
        return tooltip
    end
    L.Scheme.Font = Font.fromEnum(Enum.Font.Gotham)
    local W = L:CreateWindow({
        Title = "",
        Icon = ANGEL_HUB_LOGO,
        Version = Runtime.version,
        CustomStyling = false,
        Responsive = false,
        StatusPanel = {
            Enabled = true,
            Title = "Angel Hub",
            Private = Config.StreamerMode == true,
            Name = "@" .. game.Players.LocalPlayer.Name,
            Avatar = "rbxthumb://type=AvatarHeadShot&id="
                .. tostring(game.Players.LocalPlayer.UserId)
                .. "&w=150&h=150",
        },
        MobileButton = true,
        Persistence = { Enabled = true, Folder = "AngelUI", Key = "AngelHub_"
            .. tostring(game.Players.LocalPlayer.UserId) },
        Footer = "Angel Hub  •  " .. Runtime.gameName .. "  •  v2.0",
        IconSize = UDim2.fromOffset(30, 30),
        Size = UDim2.fromOffset(800, 560),
        Center = true,
        AutoShow = true,
        Resizable = true,
        CornerRadius = 14,
        Font = Enum.Font.Gotham,
        SidebarCompacted = true,
        SidebarCompactWidth = 52,
        EnableCompacting = true,
        EnableSidebarResize = false,
        SearchbarSize = UDim2.fromOffset(166, 30),
        GlobalSearch = false,
        ShowCustomCursor = false,
        ShowMobileButtons = false,
        ToggleKeybind = Enum.KeyCode.LeftControl,
        TabButtonsStyle = { Gap = 6, Padding = 6, CornerRadius = 12, Indicator = false },
        TabTransitionTime = 0.18,
        TabSwipeOffset = 12,
        TabSwipeFrom = "auto",
        Animations = { ToggleWindow = false, TabSwitch = true, Groupbox = true, Dropdown = true },
    })
    local UI = { ScreenGui = L.ScreenGui, controls = {}, tabs = {}, library = L }
    local window =
        { main = W.MainFrame, screenGui = L.ScreenGui, themeProperties = {}, theme = {}, settings = {}, hidden = false }
    local facade, pages, serial = {}, {}, 0
    local closeMenus, polishHeader
    local function copy(v)
        return type(v) == "table" and table.clone(v) or v
    end
    function window:Connect(signal, fn)
        return Runtime.trackConnection(signal:Connect(fn))
    end
    local function bind(object, property, binding)
        local key = type(binding) == "table" and binding[1] or binding
        local value = window.theme[key]
        if type(binding) == "table" and binding[2] then
            value = binding[2](value)
        end
        if value ~= nil then
            object[property] = value
        end
    end
    function window:Create(class, props, bindings)
        local object = Instance.new(class)
        for key, value in pairs(props) do
            if key ~= "Parent" then
                object[key] = value
            end
        end
        object.Parent = props.Parent
        if bindings then
            self.themeProperties[object] = bindings
            for key, value in pairs(bindings) do
                bind(object, key, value)
            end
        end
        return object
    end
    function window:DestroySubtree(object)
        object:Destroy()
    end
    function window:_bindLocale(object, key, value)
        if object then
            object[key] = tostring(value or "")
        end
    end
    function window:Show()
        local input = game:GetService("UserInputService")
        if not L.IsMobile then
            input.MouseIconEnabled = true
        end
        L:Toggle(true)
        L.OriginalMouseIconEnabled = true
        self.hidden = false
    end
    function window:Hide()
        L.OriginalMouseIconEnabled = true
        L:Toggle(false)
        self.hidden = true
        if not L.IsMobile then
            game:GetService("UserInputService").MouseIconEnabled = not Config.BlackScreen
        end
    end
    function window:Unload()
        if self.unloaded then
            return
        end
        self.unloaded = true
        L:Unload()
    end
    L:OnUnload(function()
        window.unloaded = true
    end)
    local palettes = {
        Dark = { Color3.fromRGB(22, 22, 25), Color3.fromRGB(35, 35, 40), Color3.fromRGB(170, 174, 191) },
        Cobalt = { Color3.fromRGB(17, 23, 35), Color3.fromRGB(29, 41, 60), Color3.fromRGB(100, 165, 235) },
        Amethyst = { Color3.fromRGB(25, 21, 33), Color3.fromRGB(40, 32, 51), Color3.fromRGB(183, 143, 232) },
        ["Sakura Bloom"] = { Color3.fromRGB(24, 21, 29), Color3.fromRGB(42, 34, 45), Color3.fromRGB(237, 156, 209) },
    }
    function UI:GetThemes()
        local out = {}
        for name in pairs(palettes) do
            out[name] = true
        end
        return out
    end
    function UI:SetTheme(name)
        local oldLogo = ANGEL_HUB_LOGO
        ANGEL_HUB_LOGO = HUB_THEME_LOGOS[name] or HUB_THEME_LOGOS.Dark
        if Context.SetLogo then
            Context.SetLogo(ANGEL_HUB_LOGO)
        end
        for _, class in ipairs({ "ImageLabel", "ImageButton" }) do
            for _, image in ipairs(L.ScreenGui:QueryDescendants(class)) do
                if image.Image == oldLogo or image.Image == "rbxassetid://83917794721401" then
                    image.Image = ANGEL_HUB_LOGO
                end
            end
        end
        local privacy = Runtime.streamPrivacy
        if privacy then
            for object, entry in pairs(privacy.entries) do
                local record = entry.saved and entry.saved.Image
                if record and object.Parent and object.Image == record.applied then
                    entry.writing = true
                    object.Image = ANGEL_HUB_LOGO
                    record.applied = ANGEL_HUB_LOGO
                    entry.writing = false
                end
            end
        end
        if Runtime.setLoadingLogo then
            Runtime.setLoadingLogo(ANGEL_HUB_LOGO)
        end
        local p = palettes[name] or palettes.Dark
        L.Scheme.BackgroundColor, L.Scheme.MainColor, L.Scheme.AccentColor = p[1], p[2], p[3]
        L.Scheme.FontColor, L.Scheme.OutlineColor = Color3.fromRGB(240, 234, 244), p[2]:Lerp(p[3], 0.22)
        local t = window.theme
        for _, key in ipairs({ "WindowColor", "ElementBackground", "SurfaceColor", "CardBackground" }) do
            t[key] = p[1]
        end
        for _, key in ipairs({
            "NeutralButton",
            "NeutralButtonHover",
            "SecondaryElementBackground",
            "TabBackgroundSelected",
        }) do
            t[key] = p[2]
        end
        for _, key in ipairs({ "ContentColor", "TitlingColor", "TextColor", "IconColor" }) do
            t[key] = L.Scheme.FontColor
        end
        for _, key in ipairs({ "AccentColor", "AccentStroke", "ToggleEnabled" }) do
            t[key] = p[3]
        end
        t.SurfaceStroke, t.ElementStroke, t.Font, t.TitleFont =
            L.Scheme.OutlineColor, L.Scheme.OutlineColor, L.Scheme.Font, L.Scheme.Font
        L:UpdateColorsUsingRegistry()
        for object, bindings in pairs(window.themeProperties) do
            if object.Parent then
                for key, value in pairs(bindings) do
                    bind(object, key, value)
                end
            else
                window.themeProperties[object] = nil
            end
        end
        for _, page in pairs(pages) do
            if page.native._angelPaint then
                page.native._angelPaint()
            end
        end
        for _, selector in pairs(Runtime.menuSelectors or {}) do
            selector:Set(selector.Value)
        end
        if Runtime.applyLoadingTheme then
            Runtime.applyLoadingTheme(t)
        end
        if polishHeader then
            polishHeader()
        end
    end
    UI:SetTheme(Config.Theme)
    function UI:Notify(p)
        if not window.unloaded then
            L:Notify({ Title = p.Title, Description = p.Content, Time = p.Duration or 4 })
        end
    end
    local groups = {
        Farming = { "Farming", "AFK Energy", "Quests", "Collectibles" },
        Events = { "Time Trial", "Portals", "Raids", "Invasion" },
        ["Spins & Rerolls"] = { "Spins & Pets", "Passives & Amulets" },
        ["Equipment & Upgrades"] = {
            "Equipment",
            "Jewels & Crafting",
            "Grimoires",
            "Spirits",
            "Ghoul Lab",
            "Progression",
            "Totem",
        },
        Consumables = { "Potions", "Juices", "Shops" },
        ["Harbor & Shops"] = { "Harbor", "Rewards" },
        Settings = { "Player", "Settings" },
    }
    for _, mode in ipairs(Runtime.modeOrder) do
        local p = Runtime.modePresets[mode]
        if p.discovered then
            table.insert(groups.Events, p.source)
        end
    end
    local routes = {}
    for target, sources in pairs(groups) do
        for _, source in ipairs(sources) do
            routes[source] = target
        end
    end
    local icons = {
        Dashboard = "layout-dashboard",
        ["Activity Order"] = "list-ordered",
        Farming = "crosshair",
        Events = "swords",
        ["Spins & Rerolls"] = "dices",
        ["Equipment & Upgrades"] = "shield",
        Consumables = "flask-conical",
        ["Harbor & Shops"] = "ship",
        Settings = "settings",
        ["About & Server"] = "info",
    }
    local sourceIcons = {
        ["Time Trial"] = "swords",
        Portals = "door-open",
        Raids = "shield",
        Invasion = "flag",
        Potions = "flask-conical",
        Juices = "cup-soda",
        Harbor = "ship",
        Shops = "shopping-bag",
        Rewards = "gift",
        Equipment = "shield",
        ["Jewels & Crafting"] = "gem",
        Grimoires = "book-open",
        Spirits = "sparkles",
        ["Ghoul Lab"] = "flask-conical",
        Progression = "trending-up",
        Player = "user",
        Settings = "settings",
        Farming = "crosshair",
        ["AFK Energy"] = "zap",
        Quests = "scroll-text",
        Collectibles = "gem",
        ["Spins & Pets"] = "dices",
        ["Passives & Amulets"] = "paw-print",
    }
    Runtime.menuGroups, Runtime.menuTabs, Runtime.menuSelected, Runtime.menuSelectors = groups, {}, {}, {}
    local function animate(object, properties)
        game:GetService("TweenService"):Create(object, TweenInfo.new(0.14), properties):Play()
    end
    local function getPage(name, order)
        if pages[name] then
            return pages[name]
        end
        local descriptions = {
            Dashboard = "Your Angel Hub overview",
            ["Activity Order"] = "Choose what runs first",
            Farming = "Enemies, quests and collectibles",
            Events = "Entry, combat and exit rules",
            ["Spins & Rerolls"] = "Gachas, passives and ordered rolls",
            ["Equipment & Upgrades"] = "Builds, crafting and progression",
            Consumables = "Potion and Juice profiles",
            ["Harbor & Shops"] = "Crews, voyages and rewards",
            Settings = "Appearance and player settings",
            ["About & Server"] = "Version, server and update history",
        }
        local pageNames = {
            Farming = "Farm",
            Events = "Combat",
            ["Activity Order"] = "Priority",
            ["Spins & Rerolls"] = "Rolls",
            ["Equipment & Upgrades"] = "Loadout",
            Consumables = "Boosts",
            ["Harbor & Shops"] = "Harbor",
            Settings = "Config",
            ["About & Server"] = "Server",
        }
        local native = W:AddTab({
            Name = pageNames[name] or name,
            Description = descriptions[name] or "Angel Hub • " .. Runtime.gameName,
            Icon = icons[name] or "layers",
        })
        local tabOrder = {
            Dashboard = 1,
            ["Activity Order"] = 4,
            Farming = 2,
            Events = 3,
            ["Spins & Rerolls"] = 5,
            ["Equipment & Upgrades"] = 6,
            Consumables = 7,
            ["Harbor & Shops"] = 8,
            Settings = 9,
            ["About & Server"] = 10,
        }
        native:SetOrder(order or tabOrder[name] or 11)
        local page = {
            name = name,
            native = native,
            elements = {},
            boxes = {},
            tabPage = native.Sides[1],
            section = "Overview",
            source = name,
        }
        pages[name] = page
        function page:Select()
            native:Show()
            window.selectedTab = self
        end
        local hovered = false
        local signature = window:Create(
            "Frame",
            {
                Name = "AngelSelection",
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 2, 0.5, 0),
                Size = UDim2.fromOffset(2, 22),
                ZIndex = 3,
                Parent = native.Button,
            },
            { BackgroundColor3 = "AccentColor" }
        )
        window:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = signature })
        window:Create(
            "UIGradient",
            {
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.85),
                    NumberSequenceKeypoint.new(0.3, 0),
                    NumberSequenceKeypoint.new(0.7, 0),
                    NumberSequenceKeypoint.new(1, 0.85),
                }),
                Parent = signature,
            }
        )
        local selectionGlow = window:Create(
            "Frame",
            {
                Name = "AngelSelectionGlow",
                BorderSizePixel = 0,
                Active = false,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                ZIndex = native.Button.ZIndex,
                Parent = native.Button,
            },
            { BackgroundColor3 = "AccentColor" }
        )
        window:Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = selectionGlow })
        window:Create(
            "UIGradient",
            {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.25),
                    NumberSequenceKeypoint.new(0.45, 0.65),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Parent = selectionGlow,
            }
        )
        for _, child in ipairs(native.Button:QueryDescendants("ImageLabel, TextLabel")) do
            child.ZIndex = native.Button.ZIndex + 2
        end
        local function paint()
            if not Runtime.alive or window.unloaded then
                return
            end
            local selected = L.ActiveTab == native
            local image = L.TabButtons[1] and native.Button:QueryDescendants("ImageLabel")[1]
            animate(
                native.Button,
                {
                    BackgroundColor3 = selected and L.Scheme.MainColor:Lerp(L.Scheme.AccentColor, 0.16)
                        or L.Scheme.MainColor,
                    BackgroundTransparency = selected and 0 or hovered and 0.25 or 1,
                }
            )
            if image then
                animate(
                    image,
                    {
                        ImageColor3 = selected and L.Scheme.AccentColor
                            or hovered and L.Scheme.FontColor
                            or L.Scheme.FontColor:Lerp(L.Scheme.BackgroundColor, 0.25),
                    }
                )
            end
            animate(signature, { BackgroundTransparency = selected and 0 or 1 })
            animate(selectionGlow, { BackgroundTransparency = selected and 0.82 or 1 })
            if image then
                animate(image, { Rotation = not selected and hovered and -5 or 0 })
            end
            local caption = native.Button:QueryDescendants("TextLabel")[1]
            if caption then
                animate(caption, { TextTransparency = selected and 0 or hovered and 0.06 or 0.15 })
                caption.FontFace = selected and Font.fromEnum(Enum.Font.GothamMedium) or L.Scheme.Font
            end
            if selected then
                window.selectedTab = page
            end
        end
        native._angelPaint = paint
        local image = L.TabButtons[#L.TabButtons].Icon
        L.Registry[native.Button].BackgroundColor3 = function()
            return L.ActiveTab == native and L.Scheme.MainColor:Lerp(L.Scheme.AccentColor, 0.16) or L.Scheme.MainColor
        end
        if image then
            L.Registry[image].ImageColor3 = function()
                return L.ActiveTab == native and L.Scheme.AccentColor
                    or L.Scheme.FontColor:Lerp(L.Scheme.BackgroundColor, 0.25)
            end
        end
        window:Connect(native.Button.MouseEnter, function()
            hovered = true
            task.defer(paint)
        end)
        window:Connect(native.Button.MouseLeave, function()
            hovered = false
            task.defer(paint)
        end)
        window:Connect(native.Button.MouseButton1Click, function()
            task.defer(paint)
        end)
        window:Connect(native.Container:GetPropertyChangedSignal("Visible"), function()
            if closeMenus then
                closeMenus()
            end
            task.defer(paint)
        end)
        local image = L.TabButtons[#L.TabButtons].Icon
        if image then
            image.AnchorPoint = Vector2.new(0.5, 0.5)
            image.Position = UDim2.fromScale(0.5, 0.5)
            image.Size = UDim2.fromOffset(20, 20)
        end
        native.Button.Size = UDim2.new(1, 0, 0, 40)
        page.fullWidth = name == "Dashboard" or name == "Activity Order"
        if page.fullWidth then
            function native:RefreshSides()
                self.Sides[1].Size = UDim2.fromScale(1, 1)
                self.Sides[2].Visible = false
            end
            native:RefreshSides()
        end
        local sources = groups[name]
        if sources then
            Runtime.menuSelected[name] = sources[1]
            local bar = window:Create(
                "ScrollingFrame",
                {
                    Name = "ModeTabs",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -4, 0, 36),
                    Position = UDim2.fromOffset(2, 2),
                    CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.X,
                    ScrollBarThickness = 2,
                    Parent = native.Container,
                }
            )
            local modeLayout = window:Create(
                "UIListLayout",
                {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 8),
                    Parent = bar,
                }
            )
            local refresh = native.RefreshSides
            function native:RefreshSides()
                refresh(self)
                for index, side in ipairs(self.Sides) do
                    side.Position = UDim2.new(index == 2 and not window.singleColumn and 1 or 0, 0, 0, 40)
                    side.Size = window.singleColumn and UDim2.new(1, 0, 1, -40) or UDim2.new(0.5, -5, 1, -40)
                    side.Visible = index == 1 or not window.singleColumn
                end
            end
            local selector = { buttons = {}, Value = sources[1] }
            local sourceLabels = {
                Farming = "Targets",
                Collectibles = "Collectibles",
                ["Time Trial"] = "Trials",
                ["Spins & Pets"] = "Gachas & Pets",
                ["Passives & Amulets"] = "Passives",
                ["Jewels & Crafting"] = "Jewels",
                Progression = "Upgrades",
                ["Auto Tower"] = "Towers",
            }
            for index, source in ipairs(sources) do
                local sourceLabel = sourceLabels[source] or source:gsub("^Auto ", "")
                local buttonWidth = math.max(
                    94,
                    game:GetService("TextService")
                        :GetTextSize(sourceLabel, 13, Enum.Font.Gotham, Vector2.new(1000, 30)).X
                        + 50
                )
                local button = window:Create(
                    "TextButton",
                    {
                        Text = "",
                        TextSize = 13,
                        FontFace = L.Scheme.Font,
                        AutoButtonColor = false,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Size = UDim2.fromOffset(buttonWidth, 30),
                        LayoutOrder = index,
                        Parent = bar,
                    },
                    { BackgroundColor3 = "NeutralButton", TextColor3 = "ContentColor" }
                )
                window:Create(
                    "UIPadding",
                    { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = button }
                )
                window:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = button })
                local content = window:Create(
                    "Frame",
                    {
                        BackgroundTransparency = 1,
                        AutomaticSize = Enum.AutomaticSize.X,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromScale(0, 1),
                        Parent = button,
                    }
                )
                local modeLayout = window:Create(
                    "UIListLayout",
                    {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 6),
                        Parent = content,
                    }
                )
                local glyph = window:Create(
                    "ImageLabel",
                    { BackgroundTransparency = 1, Size = UDim2.fromOffset(16, 16), LayoutOrder = 1, Parent = content },
                    { ImageColor3 = "AccentColor" }
                )
                L:ApplyLucideIcon(glyph, L:GetIcon(sourceIcons[source] or "layers"))
                local text = window:Create(
                    "TextLabel",
                    {
                        Text = sourceLabel,
                        BackgroundTransparency = 1,
                        FontFace = L.Scheme.Font,
                        TextSize = 13,
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2.fromScale(0, 1),
                        LayoutOrder = 2,
                        Parent = content,
                    },
                    { TextColor3 = "ContentColor" }
                )
                local line = window:Create(
                    "Frame",
                    {
                        Name = "SelectionAccent",
                        BorderSizePixel = 0,
                        AnchorPoint = Vector2.new(0.5, 1),
                        Position = UDim2.new(0.5, 0, 1, -1),
                        Size = UDim2.new(0.64, 0, 0, 1),
                        Parent = button,
                    },
                    { BackgroundColor3 = "AccentColor" }
                )
                window:Create(
                    "UIGradient",
                    {
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 1),
                            NumberSequenceKeypoint.new(0.5, 0),
                            NumberSequenceKeypoint.new(1, 1),
                        }),
                        Parent = line,
                    }
                )
                local stroke = window:Create(
                    "UIStroke",
                    { Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = button },
                    { Color = "AccentColor" }
                )
                local scale = window:Create("UIScale", { Scale = 1, Parent = button })
                local entry =
                    { button = button, line = line, label = text, icon = glyph, stroke = stroke, scale = scale, hovered = false }
                selector.buttons[source] = entry
                window:Connect(button.MouseEnter, function()
                    entry.hovered = true
                    selector:Set(selector.Value)
                end)
                window:Connect(button.MouseLeave, function()
                    entry.hovered = false
                    selector:Set(selector.Value)
                end)
                window:Connect(button.MouseButton1Click, function()
                    scale.Scale = 0.96
                    animate(scale, { Scale = 1 })
                end)
                window:Connect(button.MouseButton1Click, function()
                    Runtime.selectMenuMode(name, source)
                end)
            end
            function selector:Set(value)
                local changed = self.Value ~= value
                self.Value = value
                if changed then
                    task.defer(function()
                        if not Runtime.alive or window.unloaded then
                            return
                        end
                        withExecutorUIContext(function()
                            local entry = self.buttons[value]
                            if not entry then
                                return
                            end
                            local scale = math.max(L.DPIScale, 0.25)
                            local width = bar.AbsoluteSize.X / scale
                            local left = (entry.button.AbsolutePosition.X - bar.AbsolutePosition.X) / scale
                                + bar.CanvasPosition.X
                            local right = left + entry.button.AbsoluteSize.X / scale
                            local position = bar.CanvasPosition.X
                            if left < position then
                                position = left
                            elseif right > position + width then
                                position = right - width
                            end
                            bar.CanvasPosition = Vector2.new(
                                math.clamp(position, 0, math.max(0, modeLayout.AbsoluteContentSize.X / scale - width)),
                                0
                            )
                        end)
                    end)
                end
                for source, entry in pairs(self.buttons) do
                    local selected = source == value
                    animate(entry.button, { BackgroundTransparency = selected and 0 or entry.hovered and 0.3 or 1 })
                    animate(entry.stroke, { Transparency = selected and 0.4 or entry.hovered and 0.8 or 1 })
                    animate(entry.scale, { Scale = not selected and entry.hovered and 1.025 or 1 })
                    animate(
                        entry.line,
                        { BackgroundTransparency = selected and 0.15 or 1, Size = UDim2.new(
                            selected and 0.64 or 0.3,
                            0,
                            0,
                            1
                        ) }
                    )
                    local color = selected and L.Scheme.AccentColor
                        or entry.hovered and L.Scheme.FontColor
                        or L.Scheme.FontColor:Lerp(L.Scheme.BackgroundColor, 0.25)
                    animate(entry.label, { TextColor3 = color })
                    animate(entry.icon, { ImageColor3 = color })
                end
            end
            Runtime.menuSelectors[name] = selector
            local function alignModes()
                modeLayout.HorizontalAlignment = modeLayout.AbsoluteContentSize.X <= bar.AbsoluteSize.X
                        and Enum.HorizontalAlignment.Center
                    or Enum.HorizontalAlignment.Left
            end
            window:Connect(modeLayout:GetPropertyChangedSignal("AbsoluteContentSize"), alignModes)
            window:Connect(bar:GetPropertyChangedSignal("AbsoluteSize"), alignModes)
            native:RefreshSides()
        end
        return page
    end
    local function boxFor(page, source, section)
        local key = source .. "\0" .. section
        if page.boxes[key] then
            return page.boxes[key]
        end
        local count = 0
        for _, entry in pairs(page.boxes) do
            if entry.source == source then
                count += 1
            end
        end
        local uniqueTitle = source .. " / " .. section
        local sectionIcons = {
            ["Auto Farm"] = "crosshair",
            ["Target tools"] = "wrench",
            ["Farm monitor"] = "activity",
            ["Target queue"] = "list-ordered",
            ["Activity queue"] = "list-ordered",
            ["Start & destination"] = "play",
            ["Exit rules"] = "log-out",
            ["Combat behavior"] = "swords",
            ["Damage build"] = "shield",
            ["World farm between waves"] = "crosshair",
            ["Farm missing entry items"] = "ticket",
            ["Join other players"] = "users",
            ["Live status"] = "activity",
            ["Quest goals"] = "scroll-text",
            ["Objective farming"] = "crosshair",
            ["Loot boxes"] = "package",
            ["Inventory equipment"] = "shield",
            ["Multiplier profiles"] = "sliders-horizontal",
            ["Craft goals"] = "gem",
            ["Progress"] = "activity",
            ["Awakening"] = "sparkles",
            ["Stat rerolls"] = "dices",
            ["Crew management"] = "users",
            ["Inventory usage"] = "flask-conical",
            ["Opening statistics"] = "chart-column",
            ["Walk speed"] = "footprints",
            ["Jumping"] = "arrow-up",
            ["Appearance"] = "palette",
        }
        local box = page.native:AddGroupbox({
            Side = (page.fullWidth or count % 2 == 0) and "Left" or "Right",
            Name = uniqueTitle,
            IconName = sectionIcons[section],
            PopOut = false,
        })
        for _, label in ipairs(box.Holder:QueryDescendants("TextLabel")) do
            if label.Text == uniqueTitle then
                label.Text = section
            end
        end
        L:StyleGroupbox(box)
        local surface = box.Holder
        for _, label in ipairs(surface:QueryDescendants("TextLabel")) do
            if label.Text == section then
                label.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
                if L.Registry[label] then
                    L.Registry[label].FontFace = function()
                        return Font.fromEnum(Enum.Font.GothamMedium)
                    end
                end
            end
        end
        local entry = {
            box = box,
            source = source,
            section = section,
            column = (page.fullWidth or count % 2 == 0) and 1 or 2,
            order = serial,
        }
        page.boxes[key] = entry
        if groups[page.name] then
            box:SetVisible(Runtime.menuSelected[page.name] == source)
        end
        return entry
    end
    local function ordered(value, previous, values)
        if type(value) ~= "table" then
            return value
        end
        local set = {}
        for k, v in pairs(value) do
            if type(k) == "number" then
                set[v] = true
            elseif v then
                set[k] = true
            end
        end
        local result = {}
        for _, v in ipairs(type(previous) == "table" and previous or {}) do
            if set[v] then
                table.insert(result, v)
                set[v] = nil
            end
        end
        for _, v in ipairs(values or {}) do
            if set[v] then
                table.insert(result, v)
                set[v] = nil
            end
        end
        return result
    end
    local friendlyControls = {
        ["Native_AutoClaimQuests"] = {
            title = "Auto Collect Quests",
            description = "Only claim completed quest rewards, including Ghoul daily and weekly quests. Works with Auto Quest off; does not farm objectives or accept quests.",
        },
        ["AutoFarm"] = {
            title = "Auto Farm",
            description = "Fight the selected enemies in your chosen order. Choose targets below first.",
        },
        ["PriorityList"] = {
            title = "Target Queue",
            description = "Select targets in order. Unavailable enemies are skipped until they respawn. Deselect and select again to move a target to the end.",
        },
        ["AutoFarmPortal"] = {
            title = "Farm More Portals",
            description = "Farm the required tickets and run raids to obtain your selected portal ranks. Works separately from Use My Portals.",
        },
        ["PortalRanks"] = {
            title = "Allowed Portal Ranks",
            description = "These ranks apply to opening, joining and farming portals.",
        },
        ["AutoJoinPortal"] = {
            title = "Join Other Players' Portals",
            description = "Join public portals that match your allowed ranks.",
        },
        ["PortalHighestFirst"] = {
            title = "Prefer Higher Ranks",
            description = "On: highest selected rank first. Off: lowest selected rank first.",
        },
        ["PortalTicketMinDamagePercent"] = {
            title = "Minimum Damage for Ticket Farming (%)",
            description = "For portal ticket farming only. Skip enemies if one hit deals less than this percentage of their maximum health.",
        },
        ["AutoJoinRaid"] = {
            title = "Join Other Players' Raids",
            description = "Join public raids on the selected map.",
        },
        ["AutoFarmTicket"] = {
            title = "Farm More Raid Tickets",
            description = "Farm missing tickets for the selected raid. Works separately from Use My Raid Tickets.",
        },
        ["RaidMap"] = { title = "Raid Map", description = "Choose which raid to run, join or farm tickets for." },
        ["TicketMinDamagePercent"] = {
            title = "Minimum Damage for Ticket Farming (%)",
            description = "For raid ticket farming only. Skip enemies if one hit deals less than this percentage of their maximum health.",
        },
        ["AutoGacha"] = {
            title = "Auto Gacha",
            description = "Spin the selected regular gachas in their chosen order while you can afford them.",
        },
        ["GachaPriorityList"] = {
            title = "Gachas to Spin",
            description = "Select regular gachas in the order you want to spend on them.",
        },
        ["AutoPetGacha"] = {
            title = "Pet Auto Spin",
            description = "Start the game's built-in Auto Spin for the pet gacha selected below.",
        },
        ["PetGachaSelection"] = { title = "Pet Gacha", description = "Choose which pet gacha to spin." },
        ["PetGachaWhen"] = {
            title = "When to Spin Pets",
            description = "Always: spin whenever possible. After gachas: wait until the selected regular gachas cannot afford another spin.",
        },
        ["AutoEquipStats"] = {
            title = "Automatically Apply Stat Choices",
            description = "Apply the chosen stat when entering a mode or changing a choice. Return to the World choice outside these modes.",
        },
        ["AutoEquipWeapon"] = {
            title = "Equip Best Weapons",
            description = "Automatically equip your best inventory weapons.",
        },
        ["AutoEquipAccessory"] = {
            title = "Equip Best Accessories",
            description = "Automatically equip your best inventory accessories.",
        },
        ["AutoEquipPet"] = { title = "Equip Best Pets", description = "Automatically equip your best inventory pets." },
        ["AutoMergeWeapons"] = {
            title = "Automatically Merge Weapons",
            description = "Merge all available weapons every 10 seconds. Separate from equipping them.",
        },
        ["StreamerMode"] = {
            title = "Stream Mode (Beta)",
            description = "Mask your nickname in the hub, game UI, chat, player list and Roblox menus. Local visual privacy; protected surfaces may be unavailable.",
        },
        ["AntiAFK"] = {
            title = "Anti-AFK",
            description = "Keep the character from being disconnected for inactivity.",
        },
        ["SpeedEnabled"] = {
            title = "Custom Walk Speed",
            description = "Use the walk speed set below. Off restores normal movement.",
        },
        ["SpeedValue"] = { title = "Walk Speed", description = "Used only while Custom Walk Speed is on." },
        ["InfinityJump"] = { title = "Midair Jump", description = "Allow another jump while you are in the air." },
        ["JumpHighEnabled"] = { title = "Custom Jump Height", description = "Use the jump height set below." },
        ["JumpHeightValue"] = { title = "Jump Height", description = "Used only while Custom Jump Height is on." },
    }
    -- Menu catalog: grouping and placement only; feature callbacks keep their original bindings.
    local sectionAliases = {
        ["Farming and target order"] = "Targets",
        ["Automatic entry and exit"] = "Start & destination",
        ["Mode settings"] = "Combat behavior",
        ["Equipment"] = "Damage build",
        ["Join public rooms"] = "Join other players",
        ["Entry materials"] = "Farm missing entry items",
        ["Item Roll Priority"] = "Reroll order",
        ["Optional: merge weapons"] = "Weapon merging",
        ["Auto Equip Avatar"] = "Avatar & power",
        ["Auto Equip Power"] = "Avatar & power",
        ["Auto Rank UP"] = "Rank progression",
        ["Auto Upgrade"] = "System upgrades",
        ["Upgrades"] = "System upgrades",
        ["Auto Claim Quests"] = "Claim completed quests",
        ["Auto Commandment"] = "Commandment upgrades",
        ["Auto Red Cloud Totem"] = "Totem progression",
        ["Auto Index Tasks"] = "Achievements & index",
        ["Auto Achievements"] = "Achievements & index",
        ["Auto Battlepass"] = "Battlepass",
        ["Equip Best per dock"] = "Crew management",
        ["Fill Empty Slots"] = "Crew management",
        ["Harbor"] = "Crew management",
        ["Clover Awakening"] = "Awakening",
        ["Grimoire Stats"] = "Stat rerolls",
        ["Spirit Pages"] = "Automatic upgrades",
        ["Upgrade target"] = "Upgrade goals",
        ["Owned pages and materials"] = "Owned pages",
        ["1. Spend inventory potions (optional)"] = "Inventory usage",
        ["1. Spend inventory juices (optional)"] = "Inventory usage",
        ["Keyboard shortcut and saved settings"] = "Saved settings",
        ["Stop the hub"] = "Stop & unload",
    }
    local function controlLocation(source, section, kind, props)
        local flag, title = props.Flag or "", props.Title or ""
        if source == "Farming" then
            if flag == "AutoFarm" or flag == "PriorityList" then
                section = "Auto Farm"
            elseif kind == "Button" then
                section = "Target tools"
            elseif kind == "Paragraph" then
                section = title == "Queue preview" and "Target queue" or "Farm monitor"
            end
        end
        if source == "Spins & Rerolls" then
            source, section = "Spins & Pets", "Opening statistics"
        end
        if source == "Harbor" then
            if flag == "AutoDevilFruitBox" then
                source, section = "Collectibles", "Loot boxes"
            elseif title == "Harbor status" then
                section = "Live status"
            else
                local boat = flag:match("^Native_AutoHarborSend(.+)$") or flag:match("^Native_AutoHarborCollect(.+)$")
                local boats = {
                    SmallBoat = "Small Boat",
                    GoingMerry = "Going Merry",
                    ThousandSunny = "Thousand Sunny",
                    MobyDick = "Moby Dick",
                }
                if boats[boat] then
                    section = "Voyage: " .. boats[boat]
                    props = table.clone(props)
                    props.Title = flag:find("Collect", 1, true) and "Auto collect rewards" or "Auto send boat"
                end
            end
        end
        if source == "Quests" then
            if flag == "AutoQuest" or flag == "QuestGroupOrder" then
                section = "Quest goals"
            elseif
                flag == "QuestAutoModes"
                or flag == "QuestRaidWorldFarm"
                or flag == "QuestRaidMap"
                or flag == "QuestAutoSpin"
            then
                section = "Objective farming"
            elseif flag == "QuestUseItems" or flag == "QuestItems" or flag == "QuestRollStats" then
                section = "Resource permissions"
            elseif kind == "Paragraph" and title ~= "Automatic quest progress" then
                section = "Live status"
            else
                section = "Guide"
            end
        end
        if source == "Player" then
            if flag:find("Speed", 1, true) then
                section = "Walk speed"
            elseif flag:find("Jump", 1, true) then
                section = "Jumping"
            end
        end
        if source == "Equipment" then
            if flag == "InvasionAutoEquip" then
                section = "Multiplier profiles"
            elseif kind == "Paragraph" and title == "Status" then
                section = "Live status"
            end
        end
        if flag == "Native_AutoClaimQuests" then
            source, section = "Quests", "Claim completed quests"
        end
        for mode, preset in pairs(Runtime.modePresets) do
            if source == preset.source then
                if flag == preset.auto then
                    section = "Start & destination"
                elseif flag == preset.timer then
                    section = "Exit rules"
                elseif flag == preset.legit then
                    section = "Combat behavior"
                elseif flag == preset.beru then
                    section = "Beru focus"
                elseif flag == preset.adaptiveDamage then
                    section = "Damage build"
                elseif
                    flag == mode .. "WorldSpot"
                    or flag == mode .. "WorldBosses"
                    or flag == mode .. "WorldTargetHits"
                then
                    section = "World farm between waves"
                elseif flag == preset.acquire or flag == preset.damage then
                    section = "Farm missing entry items"
                elseif kind == "Paragraph" and (title == "Status" or title:lower():find("status", 1, true)) then
                    section = "Live status"
                end
                for _, selector in ipairs(preset.selectors or {}) do
                    if flag == selector.Flag then
                        section = "Start & destination"
                    end
                end
                if flag == "PortalHighestFirst" then
                    section = "Start & destination"
                end
                break
            end
        end
        if
            kind == "Paragraph"
            and (
                title:match("^How ")
                or title == "One Spirit, several pages"
                or title == "Automatic upgrade priority"
                or title == "Reroll an Inventory Item"
            )
        then
            section = "Guide"
        end
        return source, sectionAliases[section] or section, props
    end
    local layouts = {
        Dashboard = { "Overview", "Quick access" },
        Events = {
            "Start & destination",
            "Exit rules",
            "Combat behavior",
            "Beru focus",
            "Damage build",
            "Farm missing entry items",
            "Join other players",
            "World farm between waves",
            "Live status",
            "Activity priority",
        },
        Farming = {
            "Auto Farm",
            "Target tools",
            "Farm monitor",
            "Target queue",
            "Quest goals",
            "Objective farming",
            "Resource permissions",
            "Commandment Fragment",
            "Loot boxes",
            "Claim completed quests",
            "Live status",
        },
        ["Spins & Rerolls"] = {
            "Regular gachas",
            "Pet auto spin",
            "Spin speed",
            "Opening statistics",
            "Reroll order",
            "Hero Passive",
            "Shadow Passive",
            "Weapon Passive",
            "Amulet Building",
        },
        ["Equipment & Upgrades"] = {
            "Inventory equipment",
            "Multiplier profiles",
            "Avatar & power",
            "Weapon merging",
            "Invasion equipment",
            "Craft goals",
            "Automatic requirements",
            "Material farming settings",
            "Progress",
            "Awakening",
            "Stat rerolls",
            "Automatic upgrades",
            "Upgrade goals",
            "Owned pages",
            "Rank progression",
            "System upgrades",
            "Progression upgrades",
            "Commandment upgrades",
            "Totem progression",
            "Live status",
        },
        Consumables = {
            "Inventory usage",
            "Manage potions during Auto Farm",
            "Manage juices during Auto Farm",
            "Time Trial Shop",
            "Pirate Shop",
        },
        ["Harbor & Shops"] = {
            "Voyage: Small Boat",
            "Voyage: Going Merry",
            "Voyage: Thousand Sunny",
            "Voyage: Moby Dick",
            "Crew management",
            "Dock 1 / Crew settings",
            "Dock 2 / Crew settings",
            "Dock 3 / Crew settings",
            "System upgrades",
            "Live status",
            "Time Trial Shop",
            "Pirate Shop",
            "Free Rewards",
            "Battlepass",
            "Achievements & index",
            "Chest Rewards",
        },
        Settings = {
            "Appearance",
            "Walk speed",
            "Jumping",
            "Player",
            "Automation",
            "Connection",
            "Saved settings",
            "Stop & unload",
        },
        ["Activity Order"] = { "Activity queue" },
    }
    local function organizePage(page)
        local entries = {}
        local preferred = layouts[page.name] or {}
        for _, entry in pairs(page.boxes) do
            table.insert(entries, entry)
        end
        table.sort(entries, function(a, b)
            local aa = table.find(preferred, a.section) or (a.section == "Guide" and 999 or 100)
            local bb = table.find(preferred, b.section) or (b.section == "Guide" and 999 or 100)
            if aa ~= bb then
                return aa < bb
            end
            return a.order < b.order
        end)
        local counts = {}
        for _, entry in ipairs(entries) do
            local index = (counts[entry.source] or 0) + 1
            counts[entry.source] = index
            entry.column = page.fullWidth and 1 or (index % 2 == 1 and 1 or 2)
            entry.order = index
            entry.box.BoxHolder.LayoutOrder = index
            entry.box.BoxHolder.Parent =
                page.native.Sides[(window.singleColumn or page.fullWidth) and 1 or entry.column]
            if entry.section == "Guide" then
                entry.box:SetCollapsed(true)
            end
            local controls = {}
            for _, control in ipairs(page.elements) do
                if control._angelSource == entry.source and control._angelGroup == entry.section then
                    table.insert(controls, control)
                end
            end
            local ranks = { Toggle = 1, Dropdown = 2, Slider = 3, Button = 4, Paragraph = 5 }
            table.sort(controls, function(a, b)
                local aa, bb = ranks[a._angelKind] or 6, ranks[b._angelKind] or 6
                if page.name == "Dashboard" or page.name == "About & Server" then
                    aa, bb = 0, 0
                end
                if aa ~= bb then
                    return aa < bb
                end
                return a._angelOrder < b._angelOrder
            end)
            for order, control in ipairs(controls) do
                if control.main then
                    control.main.LayoutOrder = order
                end
            end
            entry.box:Resize()
        end
    end
    local function makeControl(page, source, section, kind, props)
        local help = props.Flag and friendlyControls[props.Flag]
        if help then
            props = table.clone(props)
            props.Title, props.Desc = help.title, help.description
        end
        source, section, props = controlLocation(source, section, kind, props)
        local notes = {
            ["Start here"] = true,
            ["Passive & Amulet Order"] = true,
            ["Refresh crew before each voyage"] = true,
            ["Craft portal settings"] = true,
            ["Craft activity control"] = true,
            ["Shortcut"] = true,
            ["Saved Settings"] = true,
        }
        if kind == "Paragraph" and (section == "Guide" or notes[props.Title]) then
            local noop = function() end
            return { native = { Set = noop, Refresh = noop }, Set = noop, SetDesc = noop, Refresh = noop }
        end
        if
            source == "Farming"
            and kind == "Paragraph"
            and (props.Title == "Status" or props.Title == "Queue preview")
        then
            props = table.clone(props)
            props.Title = ""
        end
        if kind ~= "Paragraph" then
            props = table.clone(props)
            local titles = {
                ["Refresh enemies"] = "Refresh Targets",
                ["Farm More Portals"] = "Auto Portal Supply",
                ["Allowed Portal Ranks"] = "Portal Ranks",
                ["Join Other Players' Portals"] = "Auto Join Portals",
                ["Join Other Players' Raids"] = "Auto Join Raids",
                ["Farm More Raid Tickets"] = "Auto Ticket Farm",
                ["Gachas to Spin"] = "Gacha Queue",
                ["Pet Auto Spin"] = "Auto Pet Spin",
                ["Automatically Apply Stat Choices"] = "Auto Build Swap",
                ["Automatically Merge Weapons"] = "Auto Merge",
                ["Custom Walk Speed"] = "Speed Override",
                ["Custom Jump Height"] = "Jump Override",
                ["Midair Jump"] = "Infinite Jump",
            }
            props.Title = titles[props.Title] or props.Title
        end
        local target = routes[source] or source
        if target ~= page.name then
            page = getPage(target)
        end
        local entry = boxFor(page, source, section)
        local box = entry.box
        local control = { Value = copy(props.Value), Values = copy(props.Values), kind = kind, muted = true }
        local native =
            { name = props.Title, _angelFlag = props.Flag, _angelKind = kind, _angelGroup = section, _angelSource = source }
        local raw
        local priority = props.PrioritySelection
            or props.Flag == "PriorityList"
            or (
                props.Multi and (
                    props.EnemyLabels
                    or props.Ordered
                    or tostring(props.Flag):find("PriorityList", 1, true)
                )
            )
        local function formatOption(value)
            local label = (props.Flag == "PriorityList" or props.EnemyLabels) and enemyDisplayLabel(value)
                or tostring(value)
            local selection = props.PrioritySelection and props.PrioritySelection() or control.Value
            local index = type(selection) == "table" and table.find(selection, value)
            return priority and index and (tostring(index) .. ". " .. label) or label
        end
        local function callback(value)
            if control.muted or not Runtime.alive then
                return
            end
            if props.Multi then
                value = ordered(value, control.Value, control.Values)
            end
            control.Value = copy(value)
            if props.Callback then
                props.Callback(value)
            end
            if kind == "Dropdown" and raw and priority then
                task.defer(function()
                    if Runtime.alive and not window.unloaded then
                        withExecutorUIContext(function()
                            raw:BuildDropdownList()
                            raw:Display()
                        end)
                    end
                end)
            end
        end
        serial += 1
        local id = "Angel_" .. (props.Flag or tostring(serial))
        if kind == "Toggle" then
            raw = box:AddToggle(
                id,
                { Text = props.Title, Tooltip = props.Desc, Default = props.Value == true, Callback = callback }
            )
            L:StyleToggle(raw)
        elseif kind == "Dropdown" then
            raw = box:AddDropdown(
                id,
                {
                    Text = props.Title,
                    Tooltip = props.Desc,
                    Values = props.Values or {},
                    Multi = props.Multi == true,
                    DragSelect = false,
                    Default = props.Value,
                    AllowNull = true,
                    FormatListValue = formatOption,
                    FormatDisplayValue = formatOption,
                    Callback = callback,
                }
            )
        elseif kind == "Slider" then
            control.Value = props.Value.Default
            raw = box:AddSlider(
                id,
                {
                    Text = props.Title,
                    Tooltip = props.Desc,
                    Min = props.Value.Min,
                    Max = props.Value.Max,
                    Default = props.Value.Default,
                    Rounding = (props.Step or 1) < 1 and 2 or 0,
                    Callback = callback,
                }
            )
        elseif kind == "Button" then
            raw = box:AddButton({
                Text = props.Title,
                Tooltip = props.Desc,
                Func = function()
                    callback()
                end,
            })
        elseif kind == "Paragraph" then
            local frame = window:Create(
                "Frame",
                {
                    BackgroundTransparency = 1,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Size = UDim2.fromScale(1, 0),
                    Parent = box.Container,
                }
            )
            local label = window:Create(
                "TextLabel",
                {
                    BackgroundTransparency = 1,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Size = UDim2.fromScale(1, 0),
                    Text = props.Desc or "",
                    TextSize = 13,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = frame,
                },
                { TextColor3 = "ContentColor", FontFace = "Font" }
            )
            if props.Title ~= "" then
                label.Text = (props.Title or "") .. "\n" .. label.Text
            end
            frame.AutomaticSize, label.AutomaticSize = Enum.AutomaticSize.None, Enum.AutomaticSize.None
            local function resizeParagraph()
                if not frame.Parent or label.Text == "" then
                    return
                end
                local width = math.max(100, frame.AbsoluteSize.X / L.DPIScale)
                local height = game:GetService("TextService")
                    :GetTextSize(label.Text, 13, Enum.Font.Gotham, Vector2.new(width, 100000)).Y + 4
                label.Size = UDim2.new(1, 0, 0, height)
                frame.Size = UDim2.new(1, 0, 0, height)
                box:Resize()
            end
            raw = {
                Holder = frame,
                SetValue = function(_, value)
                    label.Text = (props.Title ~= "" and (props.Title .. "\n") or "") .. tostring(value or "")
                    resizeParagraph()
                end,
            }
            window:Connect(frame:GetPropertyChangedSignal("AbsoluteSize"), resizeParagraph)
            resizeParagraph()
            window:Connect(frame:GetPropertyChangedSignal("AbsoluteSize"), function()
                if Runtime.alive then
                    box:Resize()
                end
            end)
        end
        native._angelOrder = serial
        native.main = raw.Holder or raw.Container
        native.raw = raw
        function native:Set(value, silent)
            local muted = control.muted
            control.muted = silent == true or muted
            local actual = value
            if props.Multi and type(value) == "table" then
                actual = {}
                for _, v in ipairs(value) do
                    actual[v] = true
                end
            end
            if raw.SetValue then
                raw:SetValue(actual)
            end
            control.muted = muted
        end
        function native:Refresh(values)
            if raw.SetValues then
                raw:SetValues(values)
            end
        end
        function native._refreshPriorityLabels()
            if raw.BuildDropdownList then
                raw:BuildDropdownList()
                raw:Display()
            end
        end
        if kind == "Dropdown" then
            local rebuild, setValues = raw.BuildDropdownList, raw.SetValues
            function raw:BuildDropdownList()
                local scroll = self.Menu.Menu.CanvasPosition
                rebuild(self)
                if self.Menu.Active then
                    self.Menu.Menu.CanvasPosition = scroll
                end
            end
            function raw:SetValues(values)
                local same = type(values) == "table" and type(self.Values) == "table"
                if same then
                    for key, value in pairs(values) do
                        if self.Values[key] ~= value then
                            same = false
                            break
                        end
                    end
                    if same then
                        for key in pairs(self.Values) do
                            if values[key] == nil then
                                same = false
                                break
                            end
                        end
                    end
                end
                if not same then
                    setValues(self, values)
                end
            end
            local display = raw.Display
            function raw:Display()
                display(self)
                if not self.Holder then
                    return
                end
                local selected = props.PrioritySelection and props.PrioritySelection() or control.Value or {}
                local parts = {}
                if priority and type(selected) == "table" then
                    for _, value in ipairs(selected) do
                        table.insert(parts, formatOption(value))
                    end
                end
                for _, button in ipairs(self.Holder:QueryDescendants("TextButton")) do
                    if button.Text ~= "" then
                        if priority then
                            button.Text = #parts > 0 and table.concat(parts, " • ") or "---"
                        end
                        button.TextTruncate = Enum.TextTruncate.AtEnd
                        button.TextWrapped = false
                        button.ClipsDescendants = true
                        button.Size = UDim2.new(1, -22 - button.Position.X.Offset, 0, 21)
                        break
                    end
                end
            end
            raw:Display()
        end
        function control:Set(value, silent)
            self.Value = copy(value)
            native:Set(value, silent)
        end
        function control:Display()
            native:Set(self.Value, true)
        end
        function control:Refresh(values)
            self.Values = copy(values)
            local old = self.muted
            self.muted = true
            native:Refresh(values)
            native:Set(self.Value, true)
            self.muted = old
        end
        function control:SetDesc(text)
            if kind == "Paragraph" then
                native:Set(text, true)
                return
            end
            raw.Tooltip = text
            local tooltip = raw.TooltipTable
            if tooltip and tooltip._angelTarget then
                local target, disabled = tooltip._angelTarget, tooltip.Disabled
                tooltip:Destroy()
                raw.TooltipTable = L:AddTooltip(text, raw.DisabledTooltip, target)
                raw.TooltipTable.Disabled = disabled
            end
        end
        for _, method in ipairs({ "Set", "Refresh", "_refreshPriorityLabels" }) do
            local original = native[method]
            native[method] = function(...)
                local args = table.pack(...)
                return withExecutorUIContext(function()
                    return original(table.unpack(args, 1, args.n))
                end)
            end
        end
        control.native = native
        control.muted = false
        table.insert(page.elements, native)
        if props.Flag then
            UI.controls[props.Flag] = control
        end
        box:Resize()
        return control
    end
    local createControl = makeControl
    makeControl = function(...)
        local args = table.pack(...)
        return withExecutorUIContext(function()
            return createControl(table.unpack(args, 1, args.n))
        end)
    end
    function window:CreateTab(props)
        local page = getPage(props.name, props.customOrder)
        function page:GetGroupbox(section)
            return boxFor(self, self.name, section).box
        end
        function page:CreateText(p)
            return makeControl(self, self.name, self.section, "Paragraph", { Title = p.name or "", Desc = p.text }).native
        end
        function page:CreateButton(p)
            return makeControl(self, self.name, self.section, "Button", { Title = p.name, Callback = p.callback }).native
        end
        function page:CreateDivider(p)
            self.section = p.text
            return {}
        end
        function page:CreateGroup()
            return self
        end
        return page
    end
    local names = {
        ["Auto Trial"] = "Time Trial",
        ["Auto Portal"] = "Portals",
        ["Auto Raid"] = "Raids",
        ["Auto Farm"] = "Farming",
        ["Priority order"] = "Activity Order",
        Gachas = "Spins & Pets",
        Misc = "Player",
        Buy = "Shops",
    }
    function facade:Tab(props)
        local source = props.Source or names[props.Title] or props.Title
        local target = routes[source] or source
        local page = window:CreateTab({ name = target })
        local wrapper = { native = page, group = source, source = source }
        function wrapper:Section(title)
            self.group = title
        end
        function wrapper:Select()
            if routes[source] then
                Runtime.selectMenuMode(target, source)
            end
            page:Select()
        end
        for _, kind in ipairs({ "Toggle", "Dropdown", "Slider", "Button", "Paragraph" }) do
            wrapper[kind] = function(self, p)
                return makeControl(page, source, self.group, kind, p)
            end
        end
        if not Runtime.menuTabs[target] then
            Runtime.menuTabs[target] = wrapper
            table.insert(UI.tabs, wrapper)
        end
        return wrapper
    end
    local createPage = window.CreateTab
    function window:CreateTab(props)
        return withExecutorUIContext(function()
            return createPage(self, props)
        end)
    end
    window:Connect(window.main:GetPropertyChangedSignal("Visible"), function()
        if window.main.Visible and L.Overlay then
            L.Overlay.Visible = true
        end
    end)
    if L.Overlay then
        L.Overlay.Visible = true
    end
    closeMenus = function()
        for _, option in pairs(L.Options) do
            if option.Menu and option.Menu.Close then
                option.Menu:Close()
            end
        end
    end
    function Runtime.selectMenuMode(target, source)
        closeMenus()
        Runtime.menuSelected[target] = source
        local selector = Runtime.menuSelectors[target]
        if selector then
            selector:Set(source)
        end
        local page = pages[target]
        if not page then
            return
        end
        for _, entry in pairs(page.boxes) do
            entry.box:SetVisible(entry.source == source and (not entry.condition or entry.condition()))
        end
        for _, side in ipairs(page.native.Sides) do
            side.CanvasPosition = Vector2.zero
        end
    end
    local updatingLayout = false
    function Runtime.updateUILayout(viewport)
        if updatingLayout or window.unloaded then
            return
        end
        updatingLayout = true
        viewport = viewport or workspace.CurrentCamera.ViewportSize
        local portrait = viewport.X < 600 and viewport.Y > viewport.X
        window.singleColumn = portrait
        window.uiScaleLimit = 1
        W:SetSidebarWidth(portrait and 52 or 144)
        for _, button in ipairs(L.TabButtons) do
            button.Label.TextSize = 13
            button.Padding.PaddingTop, button.Padding.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
            if button.Icon then
                button.Icon.AnchorPoint = portrait and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5)
                button.Icon.Position = portrait and UDim2.fromScale(0.5, 0.5) or UDim2.fromScale(0, 0.5)
                button.Icon.Size = UDim2.fromOffset(20, 20)
            end
        end
        local logical = portrait and Vector2.new(480, 640) or Vector2.new(800, 560)
        window.main.Size = UDim2.fromOffset(logical.X, logical.Y)
        local scale = math.min(window.uiScaleLimit, (viewport.X - 24) / logical.X, (viewport.Y - 24) / logical.Y)
        L:SetDPIScale(math.max(0.25, scale) * 100)
        window.main.AnchorPoint = Vector2.new(0.5, 0.5)
        window.main.Position = UDim2.fromScale(0.5, 0.5)
        for _, page in pairs(pages) do
            local single = portrait or page.fullWidth
            for _, entry in pairs(page.boxes) do
                entry.box.BoxHolder.Parent = page.native.Sides[single and 1 or entry.column]
                entry.box.BoxHolder.LayoutOrder = entry.order
                entry.box:Resize()
            end
            if single then
                page.native.Sides[1].Position = UDim2.fromOffset(0, groups[page.name] and 40 or 0)
                page.native.Sides[1].Size = UDim2.new(1, 0, 1, groups[page.name] and -40 or 0)
                page.native.Sides[2].Visible = false
            else
                page.native.Sides[2].Visible = true
                page.native:RefreshSides()
            end
        end
        if polishHeader then
            polishHeader()
        end
        Runtime.uiViewport = viewport
        if Runtime.resizeSessionHUD then
            Runtime.resizeSessionHUD(viewport)
        end
        updatingLayout = false
    end
    function Runtime.organizeObsidianTabs()
        for target, sources in pairs(groups) do
            Runtime.selectMenuMode(target, Runtime.menuSelected[target] or sources[1])
        end
        for _, page in pairs(pages) do
            organizePage(page)
        end
        W:SetCompact(true)
        Runtime.updateUILayout()
        for _, page in pairs(pages) do
            page.native:_angelPaint()
        end
    end
    function facade:SetToggleKey(key)
        L.ToggleKeybind = key
    end
    function facade:Destroy()
        window:Unload()
    end
    -- Native floating button stays reachable by touch when the window is hidden.
    window.reopenButton = W.MobileButton.Button
    Runtime.minimizedUI = { button = W.MobileButton.Button, logo = W.MobileButton.Logo }
    Runtime.nativeUIWindow = W
    Runtime.resizeSessionHUD = function(viewport)
        W:ResizeStatusPanel(viewport)
    end
    function window:SetStatusPanelEnabled(enabled)
        W:SetStatusPanelEnabled(enabled)
    end
    function window:SetMobileButtonEnabled(enabled)
        W:SetMobileButtonEnabled(enabled)
    end
    window:Connect(window.main:GetPropertyChangedSignal("Visible"), function()
        window.hidden = not window.main.Visible
    end)
    window:Connect(game:GetService("RunService").Heartbeat, function()
        if Runtime.settingsActions then
            Runtime.settingsActions.syncBlackScreen()
        end
    end)
    -- Keep the native header and search behavior; only tune their layout.
    local header = { buttons = {} }
    for _, frame in ipairs(window.main:GetChildren()) do
        if frame:IsA("Frame") and frame.Size.Y.Offset == 48 then
            header.bar = frame
            break
        end
    end
    if header.bar then
        for _, textbox in ipairs(header.bar:QueryDescendants("TextBox")) do
            if textbox.PlaceholderText == "Search" then
                header.search = textbox
                break
            end
        end
        for _, child in ipairs(header.bar:GetChildren()) do
            if child:IsA("ImageLabel") then
                header.move = child
            end
        end
        if header.search then
            local info = header.search.Parent:FindFirstChildOfClass("Frame")
            if info then
                local labels = info:QueryDescendants("TextLabel")
                header.title, header.description = labels[1], labels[2]
                local padding = info:FindFirstChildOfClass("UIPadding")
                if padding then
                    padding.PaddingTop, padding.PaddingBottom = UDim.new(), UDim.new()
                end
                local layout = info:FindFirstChildOfClass("UIListLayout")
                if layout then
                    layout.Padding = UDim.new(0, 2)
                end
            end
        end
        for _, item in ipairs({ {
            "minus",
            -42,
            function()
                window:Hide()
            end,
        } }) do
            local button = window:Create(
                "TextButton",
                {
                    Name = "Header" .. item[1],
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, item[2], 0.5, 0),
                    Size = UDim2.fromOffset(28, 28),
                    Parent = header.bar,
                },
                { BackgroundColor3 = "NeutralButton" }
            )
            window:Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = button })
            local icon = window:Create(
                "ImageLabel",
                {
                    BackgroundTransparency = 1,
                    ImageTransparency = 0.25,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(16, 16),
                    Parent = button,
                },
                { ImageColor3 = "ContentColor" }
            )
            L:ApplyLucideIcon(icon, L:GetIcon(item[1]))
            window:Connect(button.MouseEnter, function()
                animate(button, { BackgroundTransparency = 0 })
                animate(icon, { ImageTransparency = 0, ImageColor3 = window.theme.AccentColor })
            end)
            window:Connect(button.MouseLeave, function()
                animate(button, { BackgroundTransparency = 1 })
                animate(icon, { ImageTransparency = 0.25, ImageColor3 = window.theme.ContentColor })
            end)
            window:Connect(button.MouseButton1Click, item[3])
            header.buttons[item[1]] = button
        end
    end
    polishHeader = function()
        if window.unloaded or not header.search then
            return
        end
        withExecutorUIContext(function()
            local search = header.search
            search.Parent.Position, search.Parent.Size = UDim2.new(1, -80, 0.5, 0), UDim2.new(1, -150, 0, 36)
            local width = window.main.AbsoluteSize.X / math.max(L.DPIScale, 0.25)
            search.Size = UDim2.fromOffset(math.clamp(math.floor(width * 0.25), 110, 200), 32)
            search.TextScaled, search.TextSize, search.TextXAlignment = false, 13, Enum.TextXAlignment.Left
            search.PlaceholderText = "Search..."
            local padding = search:FindFirstChildOfClass("UIPadding")
            if padding then
                padding.PaddingLeft = UDim.new(0, 29)
            end
            local icon = search:FindFirstChildOfClass("ImageLabel")
            if icon then
                icon.Position = UDim2.fromOffset(-20, 0)
            end
            for index, label in ipairs({ header.title, header.description }) do
                label.AutomaticSize, label.Size = Enum.AutomaticSize.None, UDim2.new(1, 0, 0, index == 1 and 17 or 13)
                label.TextSize, label.TextWrapped, label.TextTruncate =
                    index == 1 and 15 or 11, false, Enum.TextTruncate.AtEnd
                label.FontFace = index == 1 and Font.fromEnum(Enum.Font.GothamMedium) or L.Scheme.Font
            end
            if header.move then
                header.move.Size, header.move.Position, header.move.ImageTransparency =
                    UDim2.fromOffset(18, 18), UDim2.new(1, -13, 0.5, 0), 0.3
            end
        end)
    end
    polishHeader()
    Runtime.headerUI = header
    -- Angel identity: compact brand, quiet accent and short event-driven motion.
    local brandRow = window:Create(
        "Frame",
        {
            Name = "AngelBrand",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            LayoutOrder = 0,
            Parent = header.title.Parent,
        }
    )
    window:Create(
        "UIListLayout",
        {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            Parent = brandRow,
        }
    )
    window:Create(
        "TextLabel",
        {
            Text = "ANGEL HUB",
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            TextSize = 16,
            Font = Enum.Font.GothamMedium,
            LayoutOrder = 1,
            Parent = brandRow,
        },
        { TextColor3 = "ContentColor" }
    )
    local lab = window:Create(
        "TextLabel",
        {
            Text = "2.0",
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(30, 15),
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            LayoutOrder = 2,
            Parent = brandRow,
        },
        { BackgroundColor3 = "NeutralButton", TextColor3 = "AccentColor" }
    )
    window:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = lab })
    local glow = window:Create(
        "Frame",
        {
            Name = "AngelHeaderTint",
            BorderSizePixel = 0,
            BackgroundTransparency = 0.9,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 0,
            Parent = header.bar,
        },
        { BackgroundColor3 = "AccentColor" }
    )
    window:Create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = glow })
    local polishNativeHeader = polishHeader
    polishHeader = function()
        polishNativeHeader()
        if window.unloaded then
            return
        end
        withExecutorUIContext(function()
            header.description.Visible = false
            header.title.LayoutOrder, header.title.TextSize = 1, 12
            header.title.Size, header.title.TextTransparency = UDim2.new(1, 0, 0, 14), 0.15
            header.title.FontFace = L.Scheme.Font
            local layout = header.title.Parent:FindFirstChildOfClass("UIListLayout")
            if layout then
                layout.SortOrder = Enum.SortOrder.LayoutOrder
            end
            -- The native sidebar divider otherwise crosses the brand text.
            for _, frame in ipairs(window.main:GetChildren()) do
                if frame:IsA("Frame") and frame.Size.X.Offset == 1 and frame.Size.Y.Scale == 1 then
                    frame.Position = UDim2.new(0, frame.Position.X.Offset, 0, 48)
                    frame.Size = UDim2.new(0, 1, 1, -48)
                end
            end
            for _, holder in ipairs(header.bar:GetChildren()) do
                if holder:IsA("Frame") and holder:FindFirstChildOfClass("ImageLabel") then
                    local logoLayout = holder:FindFirstChildOfClass("UIListLayout")
                    if logoLayout then
                        logoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
                    end
                    local padding = holder:FindFirstChildOfClass("UIPadding")
                    if not padding then
                        padding = window:Create("UIPadding", { Parent = holder })
                    end
                    padding.PaddingLeft = UDim.new(0, 14)
                end
            end
        end)
    end
    polishHeader()
    header.brand = brandRow
    -- Animate only the surface; scaling triggers responsive layout during every frame.
    local surfaceTransparency = window.main.BackgroundTransparency
    local openTween
    local function animateOpening()
        if not Runtime.alive or window.unloaded then
            return
        end
        if openTween then
            openTween:Cancel()
        end
        withExecutorUIContext(function()
            window.main.BackgroundTransparency = surfaceTransparency
            if not window.main.Visible then
                return
            end
            window.main.BackgroundTransparency = math.min(1, surfaceTransparency + 0.12)
            openTween = game:GetService("TweenService"):Create(
                window.main,
                TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { BackgroundTransparency = surfaceTransparency }
            )
            openTween:Play()
        end)
    end
    window:Connect(window.main:GetPropertyChangedSignal("Visible"), animateOpening)
    table.insert(Runtime.finalizers, function()
        if openTween then
            openTween:Cancel()
        end
    end)

    window:Connect(window.main:GetPropertyChangedSignal("AbsoluteSize"), function()
        task.defer(polishHeader)
    end)

    window:Connect(window.screenGui:GetPropertyChangedSignal("AbsoluteSize"), function()
        Runtime.updateUILayout()
    end)
    window:Connect(window.main:GetPropertyChangedSignal("Size"), function()
        if updatingLayout then
            return
        end
        local viewport = Runtime.uiViewport or workspace.CurrentCamera.ViewportSize
        local logical = window.main.Size
        local scale = math.min(
            window.uiScaleLimit or 1,
            (viewport.X - 24) / math.max(logical.X.Offset, 1),
            (viewport.Y - 24) / math.max(logical.Y.Offset, 1)
        )
        if math.abs(L.DPIScale - scale) > 0.001 then
            L:SetDPIScale(math.max(0.25, scale) * 100)
        end
    end)
    Runtime.uiTest = false
    Runtime.ui, Runtime.window, Runtime.config = UI, window, Config
    env.AngelHubUIPreview = window
    return UI, facade
end
