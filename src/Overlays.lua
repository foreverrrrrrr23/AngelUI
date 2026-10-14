return function(Library, Window, options, createStorage)
    local inputService = game:GetService("UserInputService")
    local runService = game:GetService("RunService")
    local storage = createStorage(options.Persistence)
    local statusOptions = type(options.StatusPanel) == "table" and options.StatusPanel or {}
    local mobileOptions = type(options.MobileButton) == "table" and options.MobileButton or {}
    local create = function(class, props, bindings)
        return Library:AngelCreate(class, props, bindings)
    end
    local connect = function(signal, callback)
        return Library:GiveSignal(signal:Connect(callback))
    end
    local identity = {
        Title = statusOptions.Title or options.Title or "Angel UI",
        Version = options.Version or "1.0.0",
        Name = statusOptions.Name or options.DisplayName or game:GetService("Players").LocalPlayer.DisplayName,
        Icon = options.Icon or "rbxassetid://112157750201789",
        Private = statusOptions.Private == true or options.Private == true,
        Avatar = statusOptions.Avatar,
    }
    local statusEnabled = options.StatusPanel ~= false and statusOptions.Enabled ~= false
    local mobileEnabled = options.MobileButton ~= false and mobileOptions.Enabled ~= false
    local hud = create("Frame", {
        Name = "AngelSessionHUD",
        Position = UDim2.fromOffset(18, 84),
        Size = UDim2.fromOffset(226, 72),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.04,
        ZIndex = 1200,
        Visible = statusEnabled,
        Parent = Library.ScreenGui,
    }, { BackgroundColor3 = "BackgroundColor" })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = hud })
    create("UIStroke", { Transparency = 0.5, Parent = hud }, { Color = "OutlineColor" })
    local hudScale = create("UIScale", { Scale = 1, Parent = hud })
    local avatar = create("ImageLabel", {
        Name = "Avatar",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.fromOffset(30, 30),
        ZIndex = 1201,
        Parent = hud,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = avatar })
    local function label(name, text, x, y, width, size)
        return create("TextLabel", {
            Name = name,
            Text = text,
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(width, 18),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = size,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 1201,
            Parent = hud,
        }, { TextColor3 = "FontColor" })
    end
    local title = label("Hub", identity.Title, 48, 8, 120, 14)
    title.Font = Enum.Font.GothamMedium
    local version = label("Version", "v" .. identity.Version, 175, 10, 44, 10)
    local name = label("Nickname", identity.Name, 48, 26, 165, 11)
    create("Frame", {
        Name = "MetricDivider",
        Position = UDim2.fromOffset(10, 46),
        Size = UDim2.new(1, -20, 0, 1),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.5,
        ZIndex = 1201,
        Parent = hud,
    }, { BackgroundColor3 = "OutlineColor" })
    label("FPSCaption", "FPS", 10, 50, 28, 10)
    label("PingCaption", "PING", 110, 50, 34, 10)
    local fpsLabel = label("FPSValue", "--", 40, 50, 52, 12)
    local pingLabel = label("PingValue", "-- ms", 150, 50, 68, 12)
    fpsLabel.Font, pingLabel.Font = Enum.Font.GothamMedium, Enum.Font.GothamMedium
    Library:RemoveFromRegistry(fpsLabel)
    Library:RemoveFromRegistry(pingLabel)

    local mini = create("TextButton", {
        Name = "AngelHubReopen",
        Text = "",
        Size = UDim2.fromOffset(44, 44),
        Position = UDim2.new(0, 18, 0.45, -22),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Active = true,
        ZIndex = 1,
        Parent = Library.Floats,
    }, { BackgroundColor3 = "BackgroundColor" })
    create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = mini })
    local miniStroke = create("UIStroke", {
        Thickness = 1,
        Transparency = 0.35,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = mini,
    }, { Color = "OutlineColor" })
    local miniLogo = create("ImageLabel", {
        Name = "Logo",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(34, 34),
        ZIndex = mini.ZIndex + 1,
        Parent = mini,
    })
    local hudHit = create("TextButton", {
        Name = "Drag",
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Active = true,
        AutoButtonColor = false,
        ZIndex = 1202,
        Parent = hud,
    })
    local restored, miniPlaced = false, false
    local dragging
    local function clamp(object, x, y)
        local room = object.Parent.AbsoluteSize - object.AbsoluteSize
        object.Position =
            UDim2.fromOffset(math.clamp(x, 6, math.max(6, room.X - 6)), math.clamp(y, 6, math.max(6, room.Y - 6)))
    end
    local function syncMini()
        local hidden = not Window.MainFrame.Visible
        if hidden and not miniPlaced then
            local position = Window.MainFrame.AbsolutePosition - mini.Parent.AbsolutePosition
            clamp(mini, position.X + 4, position.Y + 2)
            miniPlaced = true
        end
        mini.Visible = mobileEnabled and hidden
    end

    function Window:RefreshStatusPanelIdentity(values)
        for key, value in pairs(values or {}) do
            identity[key] = value
        end
        title.Text = identity.Title
        version.Text = "v" .. identity.Version
        name.Text = identity.Private and identity.Title or identity.Name
        avatar.Image = identity.Private and identity.Icon or identity.Avatar or identity.Icon
        miniLogo.Image = identity.Icon
    end
    function Window:SetStatusPanelEnabled(enabled)
        statusEnabled = enabled == true
        hud.Visible = statusEnabled
        if not statusEnabled and dragging and dragging.Object == hud then
            dragging = nil
        end
    end
    function Window:SetMobileButtonEnabled(enabled)
        mobileEnabled = enabled == true
        syncMini()
        if not mobileEnabled and dragging and dragging.Object == mini then
            dragging = nil
        end
    end
    function Window:GetOverlayOptions()
        return { StatusPanel = statusEnabled, MobileButton = mobileEnabled }
    end
    function Window:SavePositions()
        storage:Capture("StatusPanel", hud)
        if miniPlaced then
            storage:Capture("MobileButton", mini)
        end
        return storage:Save()
    end
    function Window:RestorePositions()
        local statusRestored = storage:Restore("StatusPanel", hud)
        miniPlaced = storage:Restore("MobileButton", mini) or miniPlaced
        clamp(hud, hud.Position.X.Offset, hud.Position.Y.Offset)
        if miniPlaced then
            clamp(mini, mini.Position.X.Offset, mini.Position.Y.Offset)
        end
        return statusRestored, miniPlaced
    end
    function Window:ResetOverlayPositions()
        storage:Reset()
        hud.Position = UDim2.fromOffset(18, 84)
        mini.Position = UDim2.new(0, 18, 0.45, -22)
        miniPlaced = false
        syncMini()
    end
    function Window:ResizeStatusPanel(viewport)
        local size = typeof(viewport) == "Vector2" and viewport or Library.ScreenGui.AbsoluteSize
        local reference = statusOptions.ReferenceViewport or Vector2.new(1920, 1057)
        local ratio = math.max(0, math.min(size.X / reference.X, size.Y / reference.Y))
        hudScale.Scale = math.clamp(math.sqrt(ratio), 0.55, 1)
    end
    local function startDrag(object, which, input)
        if dragging or not object.Visible then
            return
        end
        if
            input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch
        then
            return
        end
        dragging = {
            Object = object,
            Which = which,
            Input = input,
            Pointer = Vector2.new(input.Position.X, input.Position.Y),
            Origin = object.AbsolutePosition - object.Parent.AbsolutePosition,
            Moved = false,
        }
    end
    connect(hudHit.InputBegan, function(input)
        startDrag(hud, "StatusPanel", input)
    end)
    connect(mini.InputBegan, function(input)
        startDrag(mini, "MobileButton", input)
    end)
    connect(inputService.InputChanged, function(input)
        local drag = dragging
        if not drag then
            return
        end
        if drag.Input.UserInputType == Enum.UserInputType.Touch then
            if input ~= drag.Input then
                return
            end
        elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end
        local delta = Vector2.new(input.Position.X, input.Position.Y) - drag.Pointer
        if delta.Magnitude >= 8 then
            drag.Moved = true
        end
        if drag.Moved then
            if drag.Object == mini then
                miniPlaced = true
            end
            clamp(drag.Object, drag.Origin.X + delta.X, drag.Origin.Y + delta.Y)
        end
    end)
    local function finishDrag(input, cancelled)
        local drag = dragging
        if not drag then
            return
        end
        if
            input
            and input ~= drag.Input
            and not (
                drag.Input.UserInputType == Enum.UserInputType.MouseButton1
                and input.UserInputType == Enum.UserInputType.MouseButton1
            )
        then
            return
        end
        dragging = nil
        if drag.Moved then
            storage:Capture(drag.Which, drag.Object)
            storage:Save()
        elseif not cancelled and drag.Object == mini and mini.Visible then
            Library.OriginalMouseIconEnabled = true
            Library:Toggle(true)
        end
    end
    connect(inputService.InputEnded, function(input)
        finishDrag(input, false)
    end)
    connect(inputService.WindowFocusReleased, function()
        finishDrag(nil, true)
    end)
    connect(mini:GetPropertyChangedSignal("Visible"), function()
        if not mini.Visible and dragging and dragging.Object == mini then
            finishDrag(nil, true)
        end
    end)
    connect(mini.MouseEnter, function()
        miniStroke.Transparency = 0
    end)
    connect(mini.MouseLeave, function()
        miniStroke.Transparency = 0.35
    end)
    connect(Window.MainFrame:GetPropertyChangedSignal("Visible"), syncMini)
    connect(Library.ScreenGui:GetPropertyChangedSignal("AbsoluteSize"), function()
        if not restored then
            return
        end
        Window:ResizeStatusPanel()
        Window:RestorePositions()
        syncMini()
    end)

    local frames, frameTime, elapsed = 0, 0, 0
    local fps
    local function metricColor(value, isPing)
        local good = isPing and value <= 60 or not isPing and value >= 60
        local fair = isPing and value <= 120 or not isPing and value >= 30
        return Color3.fromHex(good and "69DC9A" or fair and "F3CB66" or "F27783")
    end
    connect(runService.RenderStepped, function(dt)
        if not statusEnabled then
            return
        end
        frames += 1
        frameTime += dt
        if frameTime >= 1 then
            fps = math.round(frames / frameTime)
            frames, frameTime = 0, 0
        end
    end)
    connect(runService.Heartbeat, function(dt)
        if not statusEnabled then
            return
        end
        elapsed += dt
        if elapsed < 1 then
            return
        end
        elapsed = 0
        local ok, ping = pcall(function()
            return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        local valid = ok and type(ping) == "number" and ping == ping and ping >= 0 and ping < math.huge
        fpsLabel.Text = fps and tostring(fps) or "--"
        pingLabel.Text = valid and tostring(math.round(ping)) .. " ms" or "-- ms"
        fpsLabel.TextColor3 = fps and metricColor(fps, false) or Library.Scheme.FontColor
        pingLabel.TextColor3 = valid and metricColor(ping, true) or Library.Scheme.FontColor
    end)
    Window.StatusPanel = { Frame = hud, Avatar = avatar, Name = name, FPS = fpsLabel, Ping = pingLabel }
    Window.MobileButton = { Button = mini, Logo = miniLogo }
    Window.LayoutStorage = storage
    Window:RefreshStatusPanelIdentity()
    Window:ResizeStatusPanel()
    Window:RestorePositions()
    restored = true
    syncMini()
    Library:OnUnload(function()
        Window:SavePositions()
    end)
end
