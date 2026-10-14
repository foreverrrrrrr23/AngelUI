return function(Library)
    local tweenService = game:GetService("TweenService")
    local palettes = {
        Dark = { Color3.fromRGB(22, 22, 25), Color3.fromRGB(35, 35, 40), Color3.fromRGB(170, 174, 191) },
        Cobalt = { Color3.fromRGB(17, 23, 35), Color3.fromRGB(29, 41, 60), Color3.fromRGB(100, 165, 235) },
        Amethyst = { Color3.fromRGB(25, 21, 33), Color3.fromRGB(40, 32, 51), Color3.fromRGB(183, 143, 232) },
        ["Sakura Bloom"] = { Color3.fromRGB(24, 21, 29), Color3.fromRGB(42, 34, 45), Color3.fromRGB(237, 156, 209) },
    }

    function Library:AngelCreate(class, props, bindings)
        local object = Instance.new(class)
        for key, value in pairs(props) do
            if key ~= "Parent" then
                object[key] = value
            end
        end
        object.Parent = props.Parent
        if bindings then
            self:AddToRegistry(object, bindings)
            for key, value in pairs(bindings) do
                object[key] = type(value) == "function" and value() or self.Scheme[value]
            end
            object.Destroying:Once(function()
                self:RemoveFromRegistry(object)
            end)
        end
        return object
    end

    function Library:SetAngelTheme(name)
        local palette = assert(palettes[name], "Unknown AngelUI theme: " .. tostring(name))
        self.AngelTheme = name
        self.Scheme.BackgroundColor, self.Scheme.MainColor, self.Scheme.AccentColor = table.unpack(palette)
        self.Scheme.FontColor = Color3.fromRGB(240, 234, 244)
        self.Scheme.OutlineColor = palette[2]:Lerp(palette[3], 0.22)
        self:UpdateColorsUsingRegistry()
        for _, toggle in pairs(self.Toggles) do
            toggle:Display()
        end
    end

    function Library:GetAngelThemes()
        local names = {}
        for name in pairs(palettes) do
            table.insert(names, name)
        end
        table.sort(names)
        return names
    end

    function Library:StyleToggle(toggle)
        if not toggle or toggle._AngelStyled or toggle.Variant ~= "Switch" then
            return toggle
        end
        toggle._AngelStyled = true
        local switch = toggle.Holder:FindFirstChildOfClass("Frame")
        local stroke = switch and switch:FindFirstChildOfClass("UIStroke")
        if not stroke then
            return toggle
        end
        switch.Size = UDim2.fromOffset(48, 18)
        toggle.TextLabel.Size = UDim2.new(1, -58, 1, 0)
        local color = function()
            return toggle.Value and self.Scheme.BackgroundColor or self.Scheme.FontColor
        end
        local state = self:AngelCreate("TextLabel", {
            Name = "AngelToggleState",
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 24, 1, 0),
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            Active = false,
            ZIndex = switch.ZIndex + 1,
            Parent = switch,
        }, { TextColor3 = color })
        local transparency = function()
            return toggle.Value and 1 or toggle.Disabled and 0.75 or 0.2
        end
        self.Registry[stroke].Transparency = transparency
        local display = toggle.Display
        function toggle:Display()
            display(self)
            stroke.Transparency = transparency()
            state.Text = self.Value and "ON" or "OFF"
            state.AnchorPoint = Vector2.new(self.Value and 0 or 1, 0)
            state.Position = UDim2.new(self.Value and 0 or 1, self.Value and 1 or -1, 0, 0)
            state.TextColor3 = color()
            state.TextTransparency = self.Disabled and 0.7 or self.Value and 0 or 0.25
        end
        toggle:Display()
        return toggle
    end

    function Library:StyleGroupbox(box)
        if box._AngelStyled then
            return box
        end
        box._AngelStyled = true
        local surface = box.Holder
        local color = function()
            return self.Scheme.BackgroundColor:Lerp(self.Scheme.MainColor, 0.35)
        end
        self.Registry[surface].BackgroundColor3 = color
        surface.BackgroundColor3 = color()
        self:AngelCreate("UIGradient", {
            Rotation = 28,
            Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(215, 215, 215)),
            Parent = surface,
        })
        local addToggle = box.AddToggle
        function box:AddToggle(...)
            return Library:StyleToggle(addToggle(self, ...))
        end
        return box
    end

    function Library:StyleTab(tab)
        if tab._AngelStyled then
            return tab
        end
        tab._AngelStyled = true
        local addGroupbox = tab.AddGroupbox
        function tab:AddGroupbox(...)
            return Library:StyleGroupbox(addGroupbox(self, ...))
        end
        local button = tab.Button
        local glow = self:AngelCreate("Frame", {
            Name = "AngelSelectionGlow",
            BorderSizePixel = 0,
            Active = false,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ZIndex = button.ZIndex,
            Parent = button,
        }, { BackgroundColor3 = "AccentColor" })
        self:AngelCreate("UICorner", { CornerRadius = UDim.new(0, 12), Parent = glow })
        self:AngelCreate("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.25),
                NumberSequenceKeypoint.new(0.45, 0.65),
                NumberSequenceKeypoint.new(1, 1),
            }),
            Parent = glow,
        })
        local mark = self:AngelCreate("Frame", {
            Name = "AngelSelection",
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.fromOffset(2, 22),
            ZIndex = button.ZIndex + 3,
            Parent = button,
        }, { BackgroundColor3 = "AccentColor" })
        self:AngelCreate("UICorner", { CornerRadius = UDim.new(1, 0), Parent = mark })
        self:AngelCreate("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.85),
                NumberSequenceKeypoint.new(0.3, 0),
                NumberSequenceKeypoint.new(0.7, 0),
                NumberSequenceKeypoint.new(1, 0.85),
            }),
            Parent = mark,
        })
        local hovered = false
        local label
        for _, child in ipairs(button:QueryDescendants("TextLabel")) do
            if child.Text == tab.Name then
                label = child
                break
            end
        end
        local icon = button:FindFirstChildOfClass("ImageLabel")
        local buttonColor = function()
            return self.ActiveTab == tab and self.Scheme.MainColor:Lerp(self.Scheme.AccentColor, 0.16)
                or self.Scheme.MainColor
        end
        local iconColor = function()
            return self.ActiveTab == tab and self.Scheme.AccentColor
                or hovered and self.Scheme.FontColor
                or self.Scheme.FontColor:Lerp(self.Scheme.BackgroundColor, 0.25)
        end
        self.Registry[button].BackgroundColor3 = buttonColor
        if icon and self.Registry[icon] then
            self.Registry[icon].ImageColor3 = iconColor
        end
        local function paint()
            if self.Unloaded then
                return
            end
            local selected = self.ActiveTab == tab
            button.BackgroundColor3 = buttonColor()
            button.BackgroundTransparency = selected and 0 or hovered and 0.25 or 1
            if icon then
                icon.ImageColor3 = iconColor()
            end
            tweenService:Create(glow, TweenInfo.new(0.14), { BackgroundTransparency = selected and 0.82 or 1 }):Play()
            tweenService:Create(mark, TweenInfo.new(0.14), { BackgroundTransparency = selected and 0 or 1 }):Play()
            if label then
                label.TextTransparency = selected and 0 or hovered and 0.06 or 0.15
                label.FontFace = Font.fromEnum(selected and Enum.Font.GothamMedium or Enum.Font.Gotham)
                label.TextColor3 = self.Scheme.FontColor
            end
        end
        for _, child in ipairs(button:QueryDescendants("TextLabel, ImageLabel")) do
            child.ZIndex = button.ZIndex + 2
        end
        local show, hide = tab.Show, tab.Hide
        function tab:Show(...)
            local result = show(self, ...)
            paint()
            return result
        end
        function tab:Hide(...)
            local result = hide(self, ...)
            paint()
            return result
        end
        self:GiveSignal(button.MouseEnter:Connect(function()
            hovered = true
            paint()
        end))
        self:GiveSignal(button.MouseLeave:Connect(function()
            hovered = false
            paint()
        end))
        paint()
        return tab
    end
end
