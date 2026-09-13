return function(core)
    assert(type(core) == 'table' and core.Name == 'Neon', 'Neon API requires the Neon core')

    local api = {
        Version = 3,
        Brand = 'Neon',
        Core = core,
        Categories = {'Offense', 'Motion', 'Player', 'World', 'Vision', 'Utility', 'Scripts', 'Developer'},
        Modules = {},
        UI = {},
        Profiles = {},
    }

    local function categoryName(name)
        return tostring(name or '')
    end

    local function category(name)
        name = categoryName(name)
        local result = core.Categories[name]
        assert(result, ('Unknown Neon category %q'):format(tostring(name)))
        return result
    end

    local function normalizeSetting(spec)
        assert(type(spec) == 'table', 'Neon setting specification must be a table')
        local out = table.clone(spec)
        local kind = tostring(out.Type or out.Kind or ''):lower()
        out.Type, out.Kind = nil, nil
        if out.Values and not out.List then out.List = out.Values end
        out.Values = nil
        return kind, out
    end

    local creators = {
        toggle='CreateToggle', boolean='CreateToggle',
        slider='CreateSlider', number='CreateSlider',
        range='CreateTwoSlider', twoslider='CreateTwoSlider',
        dropdown='CreateDropdown', mode='CreateDropdown', select='CreateDropdown',
        multidropdown='CreateMultiDropdown', multiselect='CreateMultiDropdown',
        color='CreateColorSlider', colour='CreateColorSlider',
        text='CreateTextBox', textbox='CreateTextBox', input='CreateTextBox',
        list='CreateTextList', textlist='CreateTextList',
        bind='CreateBind', keybind='CreateBind',
        button='CreateButton', action='CreateButton',
        font='CreateFont', targets='CreateTargets',
    }

    local function addSetting(module, spec)
        local kind, normalized = normalizeSetting(spec)
        local creator = creators[kind]
        assert(creator and type(module[creator]) == 'function', ('Unsupported Neon setting type %q'):format(kind))
        return module[creator](module, normalized)
    end

    local function decorate(module)
        if rawget(module, '__neon_api_v3') then return module end
        rawset(module, '__neon_api_v3', true)
        rawset(module, 'Setting', function(self, spec) return addSetting(self, spec) end)
        rawset(module, 'ToggleSetting', function(self, name, default, callback)
            return addSetting(self, {Type='toggle', Name=name, Default=default, Function=callback})
        end)
        rawset(module, 'Slider', function(self, name, min, max, default, callback)
            return addSetting(self, {Type='slider', Name=name, Min=min, Max=max, Default=default, Function=callback})
        end)
        rawset(module, 'Mode', function(self, name, values, default, callback)
            return addSetting(self, {Type='dropdown', Name=name, List=values, Default=default, Function=callback})
        end)
        return module
    end

    function api.Modules:Register(categoryId, spec)
        assert(type(spec) == 'table' and type(spec.Name) == 'string', 'Neon module registration requires Name')
        return decorate(core:_CreateModule(categoryName(categoryId), spec))
    end

    function api.Modules:Get(name)
        return core.Modules[name]
    end

    function api.Modules:Remove(name)
        return core:Remove(name)
    end

    function api.Modules:All()
        local out, seen = {}, {}
        for _, module in core.Modules do
            if type(module) == 'table' and module.Id and not seen[module] then
                seen[module] = true
                out[#out + 1] = module
            end
        end
        table.sort(out, function(a,b) return a.Index < b.Index end)
        return out
    end

    function api:Module(categoryId, spec)
        return self.Modules:Register(categoryId, spec)
    end

    function api:GetModule(name) return self.Modules:Get(name) end
    function api:GetCategory(name) return category(name) end
    function api:Setting(module, spec) return addSetting(module, spec) end

    function api:Notify(title, message, duration, kind)
        return core:CreateNotification(title or 'Neon', message, duration, kind)
    end

    function api:Theme(name)
        if name == nil then return core.ActiveThemeName end
        if core.GradientTheme and core.GradientTheme.SetValue then core.GradientTheme:SetValue(name) end
        return core.ActiveThemeName
    end

    function api.UI:Open() if not core.ClickGUI.Visible then core.GUIBind.Triggered:Fire(true) end end
    function api.UI:Close() if core.ClickGUI.Visible then core.GUIBind.Triggered:Fire(true) end end
    function api.UI:Toggle() core.GUIBind.Triggered:Fire(true) end
    function api.UI:IsOpen() return core.ClickGUI.Visible end
    function api.UI:Overlay(spec) return core:CreateOverlay(spec) end
    function api.UI:Accent(offset) return core:GetThemeColor(offset or 0) end

    function api.Profiles:Save(name) return core:Save(name) end
    function api.Profiles:Load(name) return core:Load(true, name) end
    function api.Profiles:Switch(name) return core:SwitchProfile(name) end
    function api.Profiles:Current() return core.Profile end

    function api:Cleanup(value) return core:Clean(value) end

    -- Call the core directly here to avoid recursing through core.Module.
    core.Module = function(_, categoryId, spec) return api.Modules:Register(categoryId, spec) end
    core.Notify = function(_, ...) return api:Notify(...) end
    core.GetCategory = function(_, name) return category(name) end
    core.GetModule = function(_, name) return api.Modules:Get(name) end

    return api
end
