-- UI layout only; never reads or writes the host script's automation settings.
return function(options)
    options = options or {}
    local environment = (getgenv and getgenv()) or shared
    environment.__AngelUILayouts = environment.__AngelUILayouts or {}
    local key = tostring(options.Key or "Default"):gsub("[^%w_%-]", "_")
    local folder = tostring(options.Folder or "AngelUI")
    local path = folder .. "/" .. key .. "_layout.json"
    local enabled = options.Enabled ~= false
    local http = game:GetService("HttpService")
    local data = environment.__AngelUILayouts[key] or { Version = 1 }
    local storage = { Data = data, Path = path, LastError = nil }

    if enabled and type(isfile) == "function" and type(readfile) == "function" then
        local ok, saved = pcall(function()
            if isfile(path) then
                return http:JSONDecode(readfile(path))
            end
        end)
        if ok and type(saved) == "table" and saved.Version == 1 then
            data = saved
            storage.Data = data
        end
    end

    function storage:Save()
        if not enabled then
            return false
        end
        environment.__AngelUILayouts[key] = data
        if type(writefile) ~= "function" then
            return true
        end
        local ok, err = pcall(function()
            if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(folder) then
                makefolder(folder)
            end
            writefile(path, http:JSONEncode(data))
        end)
        self.LastError = ok and nil or tostring(err)
        return ok
    end

    function storage:Capture(name, object)
        if not enabled or not object.Parent then
            return
        end
        local available = object.Parent.AbsoluteSize - object.AbsoluteSize
        local position = object.AbsolutePosition - object.Parent.AbsolutePosition
        data[name] = {
            X = math.clamp(position.X / math.max(available.X, 1), 0, 1),
            Y = math.clamp(position.Y / math.max(available.Y, 1), 0, 1),
        }
    end

    function storage:Restore(name, object)
        local saved = enabled and data[name]
        if type(saved) ~= "table" then
            return false
        end
        if type(saved.X) ~= "number" or type(saved.Y) ~= "number" then
            return false
        end
        if saved.X ~= saved.X or saved.Y ~= saved.Y then
            return false
        end
        local available = object.Parent.AbsoluteSize - object.AbsoluteSize
        object.Position = UDim2.fromOffset(
            math.clamp(saved.X, 0, 1) * math.max(available.X, 0),
            math.clamp(saved.Y, 0, 1) * math.max(available.Y, 0)
        )
        return true
    end

    function storage:Reset()
        table.clear(data)
        data.Version = 1
        return self:Save()
    end
    return storage
end
