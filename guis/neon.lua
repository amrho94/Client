
local neon = {
    Name = 'Neon',
    Version = '1.0.0',
    Build = 'neon-krs-r1',
    Loaded = false,
    Categories = {},
    Modules = {},
    Settings = {},
    Libraries = {},
    Connections = {},
    Windows = {},
    Components = {},
    HUDAccentObjects = setmetatable({}, {__mode = 'k'}),
    ModuleThemeObjects = setmetatable({}, {__mode = 'k'}),
    OverlayRegistry = {},
    Profile = shared.NeonCustomProfile or 'default',
    Place = game.PlaceId,
    ThreadFix = false,
    EditGUI = false,
    SwitchingProfile = false,
    ModuleSchemaRevision = 0,
    ModuleVisualRevision = 0,
    ActiveThemeName = 'Krs',
    GUIStyleName = 'Neon',
}

shared.NeonBuild = neon.Build

local cloneref = cloneref or function(v) return v end
local playersService = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local runService = cloneref(game:GetService('RunService'))
local textService = cloneref(game:GetService('TextService'))
local lightingService = cloneref(game:GetService('Lighting'))
local httpService = cloneref(game:GetService('HttpService'))
local guiService = cloneref(game:GetService('GuiService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local lplr = playersService.LocalPlayer

local isfile = isfile or function(path)
    local ok, out = pcall(readfile, path)
    return ok and out ~= nil and out ~= ''
end
local writefile = writefile or function() end
local makefolder = makefolder or function() end
local delfile = delfile or function() end
local getcustomasset = getcustomasset or getsynasset

local function protectGui(gui)
    if type(syn) == 'table' and type(syn.protect_gui) == 'function' then
        pcall(syn.protect_gui, gui)
    end
end

local function parentGui(gui)
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then
        gui.Parent = hui
        return
    end
    if neon.ThreadFix then
        gui.Parent = coreGui
    else
        gui.Parent = lplr:WaitForChild('PlayerGui')
        gui.ResetOnSpawn = false
    end
end

local function create(className, parent, props)
    local obj = Instance.new(className)
    if props then
        for key, value in props do
            if key ~= 'Children' then
                local ok = pcall(function() obj[key] = value end)
                if not ok then warn('[Neon] Unable to set '..tostring(key)..' on '..className) end
            end
        end
    end
    obj.Parent = parent
    if props and props.Children then
        for _, child in props.Children do child.Parent = obj end
    end
    return obj
end

local function corner(parent, radius)
    return create('UICorner', parent, {CornerRadius = UDim.new(0, radius or 6)})
end

local function stroke(parent, color, transparency, thickness)
    return create('UIStroke', parent, {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color or Color3.new(1, 1, 1),
        Transparency = transparency == nil and 0.86 or transparency,
        Thickness = thickness or 1
    })
end

local function padding(parent, left, right, top, bottom)
    return create('UIPadding', parent, {
        PaddingLeft = UDim.new(0, left or 0), PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or 0), PaddingBottom = UDim.new(0, bottom or top or 0)
    })
end

local function round(n, step)
    if not step or step <= 0 then return n end
    return math.floor((n / step) + 0.5) * step
end

local function clamp01(n) return math.clamp(tonumber(n) or 0, 0, 1) end

local function stripTags(text)
    text = tostring(text or ''):gsub('<br%s*/>', '\n')
    return text:gsub('<[^<>]->', '')
end

local function makeSignal()
    local signal = {Connections = {}}
    function signal:Connect(callback)
        table.insert(self.Connections, callback)
        local alive = true
        return {
            Disconnect = function()
                if not alive then return end
                alive = false
                local i = table.find(signal.Connections, callback)
                if i then table.remove(signal.Connections, i) end
            end
        }
    end
    function signal:Once(callback)
        local con
        con = self:Connect(function(...)
            if con then con:Disconnect() end
            callback(...)
        end)
        return con
    end
    function signal:Fire(...)
        for _, callback in table.clone(self.Connections) do
            task.spawn(callback, ...)
        end
    end
    function signal:Destroy()
        table.clear(self.Connections)
    end
    return signal
end

local function dispose(value)
    if value == nil then return end
    local kind = typeof(value)
    if kind == 'RBXScriptConnection' then
        pcall(function() value:Disconnect() end)
    elseif kind == 'Instance' then
        pcall(function() value:Destroy() end)
    elseif kind == 'thread' then
        pcall(task.cancel, value)
    elseif type(value) == 'function' then
        pcall(value)
    elseif type(value) == 'table' then
        if type(value.Disconnect) == 'function' then pcall(value.Disconnect, value)
        elseif type(value.Destroy) == 'function' then pcall(value.Destroy, value)
        elseif type(value.Cancel) == 'function' then pcall(value.Cancel, value) end
    end
end

function neon:Clean(value)
    table.insert(self.Connections, value)
    return value
end

local function addMaid(owner)
    owner.Connections = owner.Connections or {}
    function owner:Clean(value)
        table.insert(self.Connections, value)
        return value
    end
    function owner:ClearConnections()
        for i = #self.Connections, 1, -1 do
            dispose(self.Connections[i])
            self.Connections[i] = nil
        end
    end
    return owner
end

local FONT_REGULAR = Font.fromEnum(Enum.Font.Gotham)
local FONT_MEDIUM = Font.fromEnum(Enum.Font.GothamMedium)
local FONT_BOLD = Font.fromEnum(Enum.Font.GothamBold)

local Theme = {
    Window = Color3.fromRGB(13, 18, 24),
    Window2 = Color3.fromRGB(9, 13, 18),
    Surface = Color3.fromRGB(15, 21, 28),
    SurfaceHover = Color3.fromRGB(20, 29, 38),
    SurfaceRaised = Color3.fromRGB(24, 33, 43),
    SurfaceDark = Color3.fromRGB(8, 12, 17),
    Border = Color3.fromRGB(66, 77, 90),
    BorderSoft = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(237, 241, 245),
    TextMuted = Color3.fromRGB(153, 163, 175),
    TextDim = Color3.fromRGB(102, 113, 125),
    Accent = Color3.fromRGB(0, 230, 230),
    Accent2 = Color3.fromRGB(74, 162, 255),
    Accent3 = Color3.fromRGB(151, 87, 255),
    Danger = Color3.fromRGB(255, 87, 100),
    Warning = Color3.fromRGB(255, 194, 72),
    Success = Color3.fromRGB(73, 231, 157),
}

local themePresets = {
    Neon = {Color3.fromRGB(0, 232, 232), Color3.fromRGB(79, 163, 255), Color3.fromRGB(152, 88, 255)},
    Krs = {Color3.fromRGB(0, 223, 223), Color3.fromRGB(0, 173, 196), Color3.fromRGB(83, 128, 182)},
    ['Digital Horizons'] = {Color3.fromRGB(71, 148, 253), Color3.fromRGB(71, 253, 160), Color3.fromRGB(151, 87, 255)},
    Ultraviolet = {Color3.fromRGB(98, 76, 255), Color3.fromRGB(204, 80, 255), Color3.fromRGB(0, 223, 255)},
    Vapor = {Color3.fromRGB(255, 83, 203), Color3.fromRGB(124, 92, 255), Color3.fromRGB(56, 210, 255)},
    Mono = {Color3.fromRGB(205, 213, 224), Color3.fromRGB(144, 156, 171), Color3.fromRGB(237, 241, 245)},
}

local uipallet = {
    Main = Theme.Surface,
    Secondary = Theme.SurfaceRaised,
    Text = Theme.Text,
    TextSecondary = Theme.TextMuted,
    Font = FONT_REGULAR,
    FontSemiBold = FONT_MEDIUM,
    FontBold = FONT_BOLD,
    Tween = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Themes = themePresets,
}
neon.Libraries.uipallet = uipallet

local tween = {}
function tween:Tween(object, info, goals)
    if typeof(object) ~= 'Instance' then return end
    local tw = tweenService:Create(object, info or uipallet.Tween, goals)
    tw:Play()
    return tw
end
neon.Libraries.tween = tween

local function getFontBounds(text, size, font, bounds)
    local enumFont = Enum.Font.Gotham
    local okName, familyName = pcall(function() return font and font.Family end)
    if not okName or not familyName then enumFont = Enum.Font.Gotham end
    local ok, result = pcall(textService.GetTextSize, textService, tostring(text or ''), size or 14, enumFont, bounds or Vector2.new(100000, 100000))
    if ok and result then return result end
    return Vector2.new(#tostring(text or '') * (size or 14) * 0.5, size or 14)
end
neon.Libraries.getfontbounds = getFontBounds
neon.Libraries.targetinfo = {Targets = {}}

local function getNeonAsset(path)
    path = tostring(path or '')
    if isfile(path) and getcustomasset then
        local ok, asset = pcall(getcustomasset, path)
        if ok then return asset end
    end
    local runtime = shared.NeonRuntime
    if runtime and getcustomasset then
        local ok, asset = pcall(runtime.Read, path, getcustomasset, true)
        if ok and asset then return asset end
    end
    return ''
end
neon.Libraries.getneonasset = getNeonAsset
neon.Libraries.getcustomasset = getNeonAsset

local function themePalette()
    return themePresets[neon.ActiveThemeName] or themePresets.Neon
end

function neon:GetThemeColor(offset)
    offset = tonumber(offset) or 0
    local colors = themePalette()
    if self.ReducedMotion and self.ReducedMotion.Enabled then return colors[1] end
    local phase = (os.clock() * 0.075 + offset) % 1
    local sections = #colors
    local scaled = phase * sections
    local index = math.floor(scaled) + 1
    local nextIndex = index % sections + 1
    return colors[index]:Lerp(colors[nextIndex], scaled - math.floor(scaled))
end

function neon:GetGUIColorRGB()
    return self:GetThemeColor(0)
end

function neon:UpdateGUIQueue(hue, sat, value)
    local colorValue = (type(hue) == 'number' and type(sat) == 'number' and type(value) == 'number') and Color3.fromHSV(hue, sat, value) or self:GetThemeColor(0)
    for object, property in self.HUDAccentObjects do
        if object and object.Parent then pcall(function() object[property] = colorValue end)
        else self.HUDAccentObjects[object] = nil end
    end
end

function neon:RegisterHUDAccent(object, property)
    if typeof(object) ~= 'Instance' then return object end
    property = property or (object:IsA('UIStroke') and 'Color' or ((object:IsA('TextLabel') or object:IsA('TextButton')) and 'TextColor3') or ((object:IsA('ImageLabel') or object:IsA('ImageButton')) and 'ImageColor3') or 'BackgroundColor3')
    self.HUDAccentObjects[object] = property
    pcall(function() object[property] = self:GetThemeColor(0) end)
    return object
end

function neon:ApplyThemeGradient(object, property, offset, noAnimate)
    if typeof(object) ~= 'Instance' then return false end
    property = property or 'BackgroundColor3'
    if property ~= 'BackgroundColor3' and property ~= 'TextColor3' and property ~= 'ImageColor3' then
        self:RegisterHUDAccent(object, property)
        return true
    end
    pcall(function() object[property] = self:GetThemeColor(offset or 0) end)
    if property == 'BackgroundColor3' and object:IsA('GuiObject') then
        local gradient = object:FindFirstChild('NeonThemeGradient')
        if not gradient then
            gradient = create('UIGradient', object, {Name = 'NeonThemeGradient', Rotation = 8})
        end
        local colors = themePalette()
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, colors[1]),
            ColorSequenceKeypoint.new(0.52, colors[2]),
            ColorSequenceKeypoint.new(1, colors[3]),
        })
        gradient.Offset = Vector2.new((offset or 0) % 1 - 0.5, 0)
    else
        self:RegisterHUDAccent(object, property)
    end
    return true
end

function neon:RegisterModuleThemeObject(object)
    if typeof(object) == 'Instance' then self.ModuleThemeObjects[object] = true end
    return object
end
function neon:UnregisterModuleThemeObject(object)
    self.ModuleThemeObjects[object] = nil
end

function neon:StyleHUDCard(object)
    if typeof(object) ~= 'Instance' or not object:IsA('GuiObject') then return object end
    object.BorderSizePixel = 0
    object.BackgroundColor3 = Theme.SurfaceDark
    if object.BackgroundTransparency > 0.88 then object.BackgroundTransparency = 0.28 end
    local c = object:FindFirstChild('NeonCardCorner') or object:FindFirstChildWhichIsA('UICorner')
    if not c then c = corner(object, 8); c.Name = 'NeonCardCorner' end
    local s = object:FindFirstChild('NeonCardStroke') or stroke(object, Theme.BorderSoft, 0.88, 1)
    s.Name = 'NeonCardStroke'
    local edge = object:FindFirstChild('NeonCardAccent')
    if not edge then
        edge = create('Frame', object, {Name = 'NeonCardAccent', BorderSizePixel = 0, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 0, 2), BackgroundColor3 = self:GetThemeColor(0), ZIndex = object.ZIndex + 2})
        corner(edge, 2)
        self:RegisterHUDAccent(edge)
    end
    return object
end

local screen = create('ScreenGui', nil, {
    Name = 'Neon', DisplayOrder = 9999999, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Global
})
protectGui(screen)
parentGui(screen)
-- Game modules read AbsoluteSize and gui.ScaledGui.ClickGui from this root.
local guiRoot = create('Frame', screen, {Name = 'GuiRoot', BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)})
local scaledGui = create('Frame', guiRoot, {Name = 'ScaledGui', BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)})
local clickgui = create('Frame', scaledGui, {Name = 'ClickGui', BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false})
local hudGui = create('Frame', scaledGui, {Name = 'HUD', BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)})
local holder = create('Folder', guiRoot, {Name = 'NeonObjects'})
neon.gui = guiRoot
neon.ScreenGui = screen
neon.ScaledGui = scaledGui
neon.ClickGUI = clickgui
neon.holder = holder

local blurEffect = create('BlurEffect', lightingService, {Name = 'NeonUIBlur', Enabled = false, Size = 0})
neon:Clean(blurEffect)
function neon:BlurCheck()
    if not blurEffect or not blurEffect.Parent then return end
    local should = clickgui.Visible and (not self.Blur or self.Blur.Enabled)
    blurEffect.Enabled = should
    tween:Tween(blurEffect, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = should and 12 or 0})
end

local backdrop = create('TextButton', clickgui, {
    Name = 'Backdrop', Text = '', AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(2, 5, 8),
    BackgroundTransparency = 0.55, Size = UDim2.fromScale(1, 1), ZIndex = 1
})

local shadow = create('Frame', clickgui, {
    Name = 'WindowShadow', AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(1014, 654), BackgroundColor3 = Color3.new(), BackgroundTransparency = 0.48, ZIndex = 2
})
corner(shadow, 14)

local root = create('Frame', clickgui, {
    Name = 'NeonWindow', AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(1000, 640), BackgroundColor3 = Theme.Window, BackgroundTransparency = 0.06,
    BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 3
})
corner(root, 11)
stroke(root, Color3.new(1,1,1), 0.86, 1)
neon.Windows.Main = root

local header = create('Frame', root, {Name = 'Header', BackgroundColor3 = Theme.Window2, BackgroundTransparency = 0.12, BorderSizePixel = 0, Size = UDim2.new(1,0,0,52), ZIndex = 5})
local headerLine = create('Frame', header, {BorderSizePixel = 0, BackgroundColor3 = Theme.BorderSoft, BackgroundTransparency = 0.88, Position = UDim2.new(0,14,1,-1), Size = UDim2.new(1,-28,0,1), ZIndex = 6})
local brandMark = create('Frame', header, {Name='BrandMark', BorderSizePixel=0, BackgroundColor3=Theme.Accent, Position=UDim2.fromOffset(18,17), Size=UDim2.fromOffset(18,18), ZIndex=7})
corner(brandMark, 5)
local brandN = create('TextLabel', brandMark, {BackgroundTransparency=1, Size=UDim2.fromScale(1,1), Text='N', TextColor3=Color3.fromRGB(7,15,20), TextSize=12, FontFace=FONT_BOLD, ZIndex=8})
local title = create('TextLabel', header, {BackgroundTransparency=1, Position=UDim2.fromOffset(46,0), Size=UDim2.fromOffset(220,52), Text='Neon  /  Modules', TextColor3=Theme.Text, TextSize=17, TextXAlignment=Enum.TextXAlignment.Left, FontFace=FONT_MEDIUM, ZIndex=7})

local close = create('TextButton', header, {Name='Close', AutoButtonColor=false, BackgroundColor3=Theme.SurfaceRaised, BackgroundTransparency=0.24, Position=UDim2.new(1,-42,0,12), Size=UDim2.fromOffset(28,28), Text='×', TextColor3=Theme.TextMuted, TextSize=20, FontFace=FONT_REGULAR, ZIndex=8})
corner(close, 6)

local searchHolder = create('Frame', header, {Name='SearchHolder', BackgroundColor3=Theme.SurfaceRaised, BackgroundTransparency=0.23, Position=UDim2.new(1,-292,0,11), Size=UDim2.fromOffset(238,30), BorderSizePixel=0, ZIndex=7})
corner(searchHolder, 6)
stroke(searchHolder, Theme.BorderSoft, 0.88, 1)
local searchIcon = create('TextLabel', searchHolder, {BackgroundTransparency=1, Position=UDim2.fromOffset(9,0), Size=UDim2.fromOffset(20,30), Text='⌕', TextSize=18, TextColor3=Theme.TextDim, FontFace=FONT_MEDIUM, ZIndex=8})
local searchBox = create('TextBox', searchHolder, {BackgroundTransparency=1, Position=UDim2.fromOffset(31,0), Size=UDim2.new(1,-39,1,0), Text='', PlaceholderText='Search', ClearTextOnFocus=false, TextColor3=Theme.Text, PlaceholderColor3=Theme.TextDim, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, FontFace=FONT_REGULAR, ZIndex=8})
neon.SearchBar = searchBox

local tabBar = create('Frame', root, {Name='CategoryTabs', BackgroundTransparency=1, Position=UDim2.fromOffset(12,58), Size=UDim2.new(1,-24,0,36), ZIndex=5})
local tabLayout = create('UIListLayout', tabBar, {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,7), SortOrder=Enum.SortOrder.LayoutOrder, VerticalAlignment=Enum.VerticalAlignment.Center})

local body = create('Frame', root, {Name='Body', BackgroundTransparency=1, Position=UDim2.fromOffset(12,100), Size=UDim2.new(1,-24,1,-134), ZIndex=4})
local modulePane = create('Frame', body, {Name='ModulePane', BackgroundColor3=Theme.SurfaceDark, BackgroundTransparency=0.31, BorderSizePixel=0, Size=UDim2.new(0.635,-5,1,0), ZIndex=5})
corner(modulePane, 8)
stroke(modulePane, Theme.BorderSoft, 0.91, 1)
local moduleList = create('ScrollingFrame', modulePane, {Name='ModuleList', BackgroundTransparency=1, BorderSizePixel=0, Position=UDim2.fromOffset(7,7), Size=UDim2.new(1,-14,1,-14), ScrollBarThickness=3, ScrollBarImageColor3=Theme.Accent, ScrollBarImageTransparency=0.2, CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y, ZIndex=6})
local moduleLayout = create('UIListLayout', moduleList, {Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder})

local inspector = create('Frame', body, {Name='Inspector', BackgroundColor3=Theme.SurfaceDark, BackgroundTransparency=0.31, BorderSizePixel=0, Position=UDim2.new(0.635,6,0,0), Size=UDim2.new(0.365,-6,1,0), ZIndex=5})
corner(inspector, 8)
stroke(inspector, Theme.BorderSoft, 0.91, 1)
local inspectorHeader = create('Frame', inspector, {BackgroundTransparency=1, Size=UDim2.new(1,0,0,55), ZIndex=6})
local inspectorTitle = create('TextLabel', inspectorHeader, {BackgroundTransparency=1, Position=UDim2.fromOffset(14,7), Size=UDim2.new(1,-28,0,22), Text='Inspector', TextColor3=Theme.Text, TextSize=15, FontFace=FONT_MEDIUM, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=7})
local inspectorSub = create('TextLabel', inspectorHeader, {BackgroundTransparency=1, Position=UDim2.fromOffset(14,29), Size=UDim2.new(1,-28,0,18), Text='Select a module to edit', TextColor3=Theme.TextDim, TextSize=11, FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=7})
local inspectorDivider = create('Frame', inspector, {BackgroundColor3=Theme.BorderSoft, BackgroundTransparency=0.91, BorderSizePixel=0, Position=UDim2.fromOffset(10,54), Size=UDim2.new(1,-20,0,1), ZIndex=7})
local settingsHost = create('Frame', inspector, {Name='SettingsHost', BackgroundTransparency=1, Position=UDim2.fromOffset(7,61), Size=UDim2.new(1,-14,1,-68), ZIndex=6})

local emptyInspector = create('Frame', settingsHost, {Name='Empty', BackgroundTransparency=1, Size=UDim2.fromScale(1,1), ZIndex=6})
local emptyGlyph = create('TextLabel', emptyInspector, {BackgroundTransparency=1, Position=UDim2.new(0.5,-30,0.5,-44), Size=UDim2.fromOffset(60,50), Text='◇', TextColor3=Theme.TextDim, TextSize=36, FontFace=FONT_REGULAR, ZIndex=7})
local emptyText = create('TextLabel', emptyInspector, {BackgroundTransparency=1, Position=UDim2.new(0,18,0.5,4), Size=UDim2.new(1,-36,0,44), Text='Right-click a module\nor use the gear button.', TextColor3=Theme.TextDim, TextSize=12, FontFace=FONT_REGULAR, TextWrapped=true, ZIndex=7})

local footer = create('Frame', root, {Name='Footer', BackgroundColor3=Theme.Window2, BackgroundTransparency=0.13, BorderSizePixel=0, Position=UDim2.new(0,0,1,-28), Size=UDim2.new(1,0,0,28), ZIndex=5})
local footerText = create('TextLabel', footer, {BackgroundTransparency=1, Position=UDim2.fromOffset(14,0), Size=UDim2.new(1,-160,1,0), Text='Ctrl+F  search   •   RShift  close   •   RMB  settings', TextColor3=Theme.TextDim, TextSize=10, FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6})
local countText = create('TextLabel', footer, {BackgroundTransparency=1, Position=UDim2.new(1,-140,0,0), Size=UDim2.fromOffset(126,28), Text='0 modules', TextColor3=Theme.TextMuted, TextSize=10, FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Right, ZIndex=6})

local watermark = create('Frame', hudGui, {Name='Watermark', BackgroundColor3=Theme.SurfaceDark, BackgroundTransparency=0.2, Position=UDim2.fromOffset(14,14), Size=UDim2.fromOffset(205,30), BorderSizePixel=0, ZIndex=50})
corner(watermark, 7)
stroke(watermark, Theme.BorderSoft, 0.88, 1)
local watermarkEdge = create('Frame', watermark, {BorderSizePixel=0, BackgroundColor3=Theme.Accent, Size=UDim2.new(1,-10,0,2), Position=UDim2.fromOffset(5,0), ZIndex=52})
corner(watermarkEdge, 2)
local watermarkText = create('TextLabel', watermark, {BackgroundTransparency=1, Position=UDim2.fromOffset(10,1), Size=UDim2.new(1,-20,1,-1), Text='Neon 1.0.0  |  0 fps', TextColor3=Theme.TextMuted, TextSize=11, FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=51})
neon:RegisterHUDAccent(watermarkEdge)

local arrayList = create('Frame', hudGui, {Name='ActiveModules', BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-12,0,12), Size=UDim2.fromOffset(360,700), ZIndex=45})
local arrayLayout = create('UIListLayout', arrayList, {HorizontalAlignment=Enum.HorizontalAlignment.Right, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,4)})
local arrayRows = {}

local notificationHost = create('Frame', hudGui, {Name='Notifications', BackgroundTransparency=1, AnchorPoint=Vector2.new(1,1), Position=UDim2.new(1,-14,1,-14), Size=UDim2.fromOffset(430,520), ZIndex=100})
local notificationLayout = create('UIListLayout', notificationHost, {VerticalAlignment=Enum.VerticalAlignment.Bottom, HorizontalAlignment=Enum.HorizontalAlignment.Right, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6)})
local notificationRecent = {}

function neon:AllowNotification(titleText, bodyText, kind, now)
    local cooldown = self.NotificationCooldown and self.NotificationCooldown.Value or 0
    if cooldown <= 0 then return true end
    local key = tostring(kind or 'info')..'\0'..tostring(titleText)..'\0'..tostring(bodyText)
    if notificationRecent[key] and now - notificationRecent[key] < cooldown then return false end
    notificationRecent[key] = now
    return true
end

function neon:CreateNotification(titleText, bodyText, duration, kind)
    titleText = tostring(titleText or 'Neon')
    bodyText = stripTags(tostring(bodyText or ''))
    if self.Notifications and not self.Notifications.Enabled then return end
    if not self:AllowNotification(titleText, bodyText, kind, os.clock()) then return end
    duration = math.clamp(tonumber(duration) or 3.5, 0.5, 30)
    local accent = kind == 'alert' and Theme.Danger or kind == 'warning' and Theme.Warning or kind == 'success' and Theme.Success or self:GetThemeColor(0)
    local card = create('Frame', notificationHost, {BackgroundColor3=Theme.SurfaceDark, BackgroundTransparency=0.1, BorderSizePixel=0, Size=UDim2.fromOffset(330,62), ZIndex=110})
    corner(card, 8)
    stroke(card, Theme.BorderSoft, 0.88, 1)
    local line = create('Frame', card, {BorderSizePixel=0, BackgroundColor3=accent, Position=UDim2.fromOffset(0,0), Size=UDim2.fromOffset(3,62), ZIndex=112})
    corner(line, 8)
    local ttl = create('TextLabel', card, {BackgroundTransparency=1, Position=UDim2.fromOffset(13,7), Size=UDim2.new(1,-26,0,20), Text=titleText, TextColor3=Theme.Text, TextSize=14, FontFace=FONT_MEDIUM, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=112})
    local msg = create('TextLabel', card, {BackgroundTransparency=1, Position=UDim2.fromOffset(13,29), Size=UDim2.new(1,-26,0,19), Text=bodyText, TextColor3=Theme.TextMuted, TextSize=11, FontFace=FONT_REGULAR, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=112})
    local progress = create('Frame', card, {BorderSizePixel=0, BackgroundColor3=accent, Position=UDim2.new(0,6,1,-5), Size=UDim2.new(1,-12,0,2), ZIndex=112})
    corner(progress, 2)
    card.Position = UDim2.fromOffset(25,0)
    card.BackgroundTransparency = 1
    ttl.TextTransparency = 1; msg.TextTransparency = 1; line.BackgroundTransparency = 1; progress.BackgroundTransparency = 1
    tween:Tween(card, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position=UDim2.new(), BackgroundTransparency=0.1})
    tween:Tween(ttl, TweenInfo.new(0.22), {TextTransparency=0})
    tween:Tween(msg, TweenInfo.new(0.22), {TextTransparency=0})
    tween:Tween(line, TweenInfo.new(0.22), {BackgroundTransparency=0})
    tween:Tween(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size=UDim2.fromOffset(0,2)})
    task.delay(duration, function()
        if not card.Parent then return end
        tween:Tween(card, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position=UDim2.fromOffset(25,0), BackgroundTransparency=1})
        tween:Tween(ttl, TweenInfo.new(0.15), {TextTransparency=1})
        tween:Tween(msg, TweenInfo.new(0.15), {TextTransparency=1})
        tween:Tween(line, TweenInfo.new(0.15), {BackgroundTransparency=1})
        task.delay(0.22, function() if card.Parent then card:Destroy() end end)
    end)
    return card
end
neon.Notify = neon.CreateNotification

local CATEGORY_MAP = {
    Offense='Offense', Motion='Motion', Player='Player', World='World',
    Vision='Vision', Utility='Utility', Scripts='Scripts', Developer='Developer'
}
local CATEGORY_ORDER = {'Offense','Motion','Player','World','Vision','Utility','Scripts','Developer'}
local CATEGORY_GLYPH = {Offense='⚡', Motion='↗', Player='●', World='◆', Vision='◉', Utility='≡', Scripts='⌁', Developer='<> '}

local DISPLAY_NAMES = {
    AimAssist='Aim Assist', SilentAim='Silent Aim', TriggerBot='Trigger Bot', AutoClicker='Auto Clicker',
    AntiFall='Void Safety', HighJump='High Jump', HitBoxes='Hitboxes', Invisible='Invisibility', Jesus='Water Walk',
    Killaura='Aura', LongJump='Long Jump', MouseTP='Cursor Teleport', Speed='Velocity', Spider='Wall Climb',
    SpinBot='Spin', TargetStrafe='Orbit', GunModifications='Weapon Tuning', GrenadeTP='Grenade Warp',
    FrontlinesFly='Flight+', Bot='Automation',
    Arrows='Edge Pointers', Chams='Player Glow', ESP='Entity ESP', Fullbright='Exposure', Health='Vital Bars',
    NameTags='Labels', PlayerModel='Avatar Render', Search='Object Scanner', Tracers='Beams', Waypoints='Markers',
    Breadcrumbs='Trails', ['China Hat']='Halo', DragonWings='Wings', Disguise='Identity Mask', FOV='Field of View',
    FPS='Frame Counter', Keystrokes='Inputs', Memory='Memory Meter', Ping='Latency', ['Song Beats']='Beat Pulse',
    Speedmeter='Velocity Meter', ['Time Changer']='World Time', RTXShaders='World Shader', GunViewmodel='Viewmodel',
    GunChanger='Weapon Skin', CustomKnife='Knife Skin', SkyThemes='Skybox', Fireflies='Ambient Particles',
    FakePlayer='Target Dummy', HeadshotSound='Hit Audio', GrenadeESP='Grenade Indicator', NoHurtCam='Damage Camera',
    VisualComfort='Camera Comfort', ThirdPerson='Third Person', BulletTracers='Shot Trails', AmmoHUD='Ammo Display',
    HitEffects='Impact FX', KillEffects='Elimination FX',
    BedESP='Bed Overlay', KitESP='Kit Tags', StorageESP='Storage Overlay', ['Bed Break Effect']='Bed Break FX',
    ['Clean Kit']='Clean Loadout', Crosshair='Reticle', ['Damage Indicator']='Damage Numbers', ['FPS Boost']='Performance Mode',
    ['Hit Color']='Hit Flash', HitFix='Hit Sync', Interface='Game HUD', ['Kill Effect']='Elimination FX', ['Reach Display']='Range Meter',
    SoundChanger='Sound Pack', ['UI Cleanup']='Clean HUD', Viewmodel='Hand Viewmodel', WinEffect='Victory FX', TexturePacks='Texture Pack',
    GamingChair='Hover Chair', Atmosphere='Environment', Cape='Cape', Clock='Clock',
    ['Anti-AFK']='Idle Guard', FastProxPrompt='Instant Prompt', Freecam='Free Camera', Gravity='Gravity Control',
    SafeWalk='Edge Guard', Wallhop='Wall Hop', Xray='X-Ray', AutoRejoin='Auto Rejoin', ChatSpammer='Chat Loop',
    ServerHop='Server Hop', StaffDetector='Staff Watch', StateSpoofer='State Mask', AntiRagdoll='Ragdoll Guard',
    PickupRange='Pickup Range', LowHealthAlert='Low Health Alert', BreakReminder='Break Reminder', AutoRespawn='Auto Respawn',
    CuteVisuals='Dream Particles',
}
neon.DisplayNames = DISPLAY_NAMES
neon.CategoryMap = CATEGORY_MAP

local selectedCategory = 'Offense'
local selectedModule
local categoryButtons = {}
local categoryObjects = {}
local searchQuery = ''

local function canonicalCategory(name)
    return CATEGORY_MAP[tostring(name)] or tostring(name)
end

local function visibleName(name)
    return DISPLAY_NAMES[name] or tostring(name):gsub('(%l)(%u)', '%1 %2')
end

local function setAccent(object, property, alpha)
    local c = neon:GetThemeColor(0)
    pcall(function() object[property or 'BackgroundColor3'] = c end)
    if alpha and object:IsA('GuiObject') then object.BackgroundTransparency = alpha end
end

local function createCategory(name)
    if categoryObjects[name] then return categoryObjects[name] end
    local category = {Name=name, Modules={}, Options={}, List={}, ListEnabled={}}
    addMaid(category)
    function category:CreateModule(props) return neon:_CreateModule(self.Name, props) end
    categoryObjects[name] = category
    neon.Categories[name] = category
    local order = table.find(CATEGORY_ORDER, name) or 99
    local btn = create('TextButton', tabBar, {Name=name, AutoButtonColor=false, BackgroundColor3=Theme.SurfaceRaised, BackgroundTransparency=0.23, Size=UDim2.fromOffset(name == 'Developer' and 112 or 104, 28), Text=(CATEGORY_GLYPH[name] or '•')..'  '..name, TextColor3=Theme.TextMuted, TextSize=11, FontFace=FONT_REGULAR, LayoutOrder=order, ZIndex=7})
    corner(btn, 6)
    local s = stroke(btn, Theme.BorderSoft, 0.94, 1)
    categoryButtons[name] = {Button=btn, Stroke=s}
    return category
end

for _, name in CATEGORY_ORDER do createCategory(name) end
for legacy, canonical in CATEGORY_MAP do
    neon.Categories[legacy] = neon.Categories[canonical] or createCategory(canonical)
end

local function setCategory(name)
    name = canonicalCategory(name)
    if not categoryObjects[name] then name = 'Offense' end
    selectedCategory = name
    for cat, data in categoryButtons do
        local active = cat == name
        data.Button.TextColor3 = active and Theme.Text or Theme.TextMuted
        data.Button.BackgroundTransparency = active and 0.04 or 0.23
        data.Button.BackgroundColor3 = active and neon:GetThemeColor(0):Lerp(Theme.Surface, 0.76) or Theme.SurfaceRaised
        data.Stroke.Color = active and neon:GetThemeColor(0) or Theme.BorderSoft
        data.Stroke.Transparency = active and 0.55 or 0.94
    end
    neon:RefreshModuleVisibility()
end

for name, data in categoryButtons do
    neon:Clean(data.Button.MouseButton1Click:Connect(function() setCategory(name) end))
end

local function ensureSettingsPage(module)
    if module.SettingsPage then return module.SettingsPage end
    local page = create('ScrollingFrame', settingsHost, {Name=module.Id..'Settings', BackgroundTransparency=1, BorderSizePixel=0, Size=UDim2.fromScale(1,1), CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarThickness=3, ScrollBarImageColor3=Theme.Accent, Visible=false, ZIndex=7})
    local layout = create('UIListLayout', page, {Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder})
    module.SettingsPage = page
    module.SettingsLayout = layout
    return page
end

local function settingFrame(module, name, height, visible)
    local page = ensureSettingsPage(module)
    local frame = create('Frame', page, {Name=name, BackgroundColor3=Theme.Surface, BackgroundTransparency=0.16, BorderSizePixel=0, Size=UDim2.new(1,-2,0,height or 38), Visible=visible ~= false, ZIndex=8})
    corner(frame, 6)
    stroke(frame, Theme.BorderSoft, 0.94, 1)
    return frame
end

local function labelFor(frame, text, width)
    return create('TextLabel', frame, {BackgroundTransparency=1, Position=UDim2.fromOffset(10,0), Size=UDim2.new(1,width or -100,1,0), Text=text, TextColor3=Theme.TextMuted, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, FontFace=FONT_REGULAR, TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=9})
end

local function commonSetting(component, module, props, typeName)
    component.Name = props.Name
    component.Type = typeName
    component.Default = props.Default
    component.Visible = props.Visible ~= false
    component.Darker = props.Darker == true
    component.Function = props.Function or function() end
    module.Options[props.Name] = component
    module.OptionOrder[#module.OptionOrder + 1] = component
    if component.Object then component.Object.Visible = component.Visible end
    function component:SetVisible(value)
        self.Visible = value == true
        if self.Object then self.Object.Visible = self.Visible end
    end
    function component:Destroy()
        if module.Options[self.Name] == self then module.Options[self.Name] = nil end
        if self.Object then self.Object:Destroy() end
    end
    return component
end

local function animateSwitch(track, knob, enabled)
    tween:Tween(track, TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = enabled and neon:GetThemeColor(0) or Color3.fromRGB(72,78,86), BackgroundTransparency = enabled and 0 or 0.12})
    tween:Tween(knob, TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position=UDim2.new(0, enabled and 18 or 3, 0.5, -7), BackgroundColor3=Color3.fromRGB(244,246,248)})
end

local settingConstructors = {}

settingConstructors.Toggle = function(module, props)
    props = props or {}; props.Name = props.Name or 'Toggle'
    local frame = settingFrame(module, props.Name, 38, props.Visible)
    labelFor(frame, props.Name, -64)
    local track = create('TextButton', frame, {AutoButtonColor=false, BackgroundColor3=Color3.fromRGB(72,78,86), BackgroundTransparency=0.12, Position=UDim2.new(1,-46,0.5,-9), Size=UDim2.fromOffset(36,18), Text='', ZIndex=10})
    corner(track, 9)
    local knob = create('Frame', track, {BackgroundColor3=Color3.fromRGB(244,246,248), BorderSizePixel=0, Position=UDim2.new(0,3,0.5,-7), Size=UDim2.fromOffset(14,14), ZIndex=11})
    corner(knob, 7)
    local component = commonSetting({Enabled=props.Default == true, Object=frame}, module, props, 'Toggle')
    function component:Toggle(skipCallback)
        self.Enabled = not self.Enabled
        animateSwitch(track, knob, self.Enabled)
        if not skipCallback then task.spawn(self.Function, self.Enabled) end
        return self.Enabled
    end
    function component:SetValue(value, skipCallback)
        value = value == true
        if self.Enabled ~= value then self.Enabled = value; animateSwitch(track, knob, value); if not skipCallback then task.spawn(self.Function, value) end end
    end
    function component:Save(data) data[self.Name] = self.Enabled end
    function component:Load(data) self:SetValue(type(data)=='table' and data.Enabled or data, false) end
    animateSwitch(track, knob, component.Enabled)
    track.MouseButton1Click:Connect(function() component:Toggle() end)
    return component
end

settingConstructors.Slider = function(module, props)
    props = props or {}; props.Name = props.Name or 'Slider'
    local min, max = tonumber(props.Min) or 0, tonumber(props.Max) or 100
    if max <= min then max = min + 1 end
    local decimal = tonumber(props.Decimal) or 1
    local step = 1 / math.max(decimal, 1)
    local value = math.clamp(tonumber(props.Default) or min, min, max)
    local frame = settingFrame(module, props.Name, 46, props.Visible)
    labelFor(frame, props.Name, -105)
    local valueLabel = create('TextLabel', frame, {BackgroundTransparency=1, Position=UDim2.new(1,-95,0,0), Size=UDim2.fromOffset(84,30), Text='', TextColor3=Theme.Text, TextSize=10, TextXAlignment=Enum.TextXAlignment.Right, FontFace=FONT_MEDIUM, ZIndex=10})
    local bar = create('TextButton', frame, {AutoButtonColor=false, Text='', BackgroundColor3=Color3.fromRGB(59,67,76), BackgroundTransparency=0.28, Position=UDim2.new(0,10,1,-11), Size=UDim2.new(1,-20,0,3), ZIndex=10})
    corner(bar, 2)
    local fill = create('Frame', bar, {BorderSizePixel=0, BackgroundColor3=neon:GetThemeColor(0), Size=UDim2.fromScale(0,1), ZIndex=11})
    corner(fill, 2); neon:RegisterHUDAccent(fill)
    local component = commonSetting({Value=value, Min=min, Max=max, Decimal=decimal, Object=frame}, module, props, 'Slider')
    local function suffix(v)
        if type(props.Suffix) == 'function' then local ok,r=pcall(props.Suffix,v); if ok then return tostring(r or '') end end
        return tostring(props.Suffix or '')
    end
    local function render()
        local p = (component.Value-min)/(max-min)
        fill.Size = UDim2.fromScale(math.clamp(p,0,1),1)
        local display = decimal > 1 and string.format('%.'..math.min(3, math.ceil(math.log10(decimal)))..'f', component.Value) or tostring(math.floor(component.Value + 0.5))
        display = display:gsub('(%..-)0+$','%1'):gsub('%.$','')
        valueLabel.Text = display..suffix(component.Value)
    end
    function component:SetValue(v, skipCallback)
        v = math.clamp(round(tonumber(v) or self.Value, step), min, max)
        if self.Value == v then render(); return end
        self.Value = v; render(); if not skipCallback then task.spawn(self.Function, v) end
    end
    function component:Save(data) data[self.Name] = self.Value end
    function component:Load(data) self:SetValue(type(data)=='table' and (data.Value or data.value) or data, false) end
    local dragging=false
    local function update(pos)
        local p=math.clamp((pos.X-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)
        component:SetValue(min+(max-min)*p)
    end
    bar.MouseButton1Down:Connect(function(x,y) dragging=true; update(Vector2.new(x,y)) end)
    inputService.InputChanged:Connect(function(input) if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then update(input.Position) end end)
    inputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    render()
    return component
end

settingConstructors.TwoSlider = function(module, props)
    props = props or {}; props.Name = props.Name or 'Range'
    local min, max = tonumber(props.Min) or 0, tonumber(props.Max) or 100
    local decimal = tonumber(props.Decimal) or 1
    local step = 1 / math.max(decimal, 1)
    local low = tonumber(props.DefaultMin or props.Default or props.MinValue) or min
    local high = tonumber(props.DefaultMax or props.Default2 or props.MaxValue) or max
    low, high = math.clamp(low,min,max), math.clamp(high,min,max)
    if low > high then low,high=high,low end
    local frame = settingFrame(module, props.Name, 48, props.Visible)
    labelFor(frame, props.Name, -110)
    local valueLabel = create('TextLabel', frame, {BackgroundTransparency=1, Position=UDim2.new(1,-100,0,0), Size=UDim2.fromOffset(90,30), Text='', TextColor3=Theme.Text, TextSize=10, TextXAlignment=Enum.TextXAlignment.Right, FontFace=FONT_MEDIUM, ZIndex=10})
    local bar = create('TextButton', frame, {AutoButtonColor=false, Text='', BackgroundColor3=Color3.fromRGB(59,67,76), BackgroundTransparency=0.28, Position=UDim2.new(0,10,1,-11), Size=UDim2.new(1,-20,0,3), ZIndex=10})
    corner(bar,2)
    local fill=create('Frame',bar,{BorderSizePixel=0,BackgroundColor3=neon:GetThemeColor(0),ZIndex=11});corner(fill,2);neon:RegisterHUDAccent(fill)
    local component=commonSetting({ValueMin=low,ValueMax=high,MinValue=low,MaxValue=high,LowValue=low,HighValue=high,Min=min,Max=max,Decimal=decimal,Object=frame},module,props,'TwoSlider')
    local function syncAliases() component.MinValue=component.ValueMin; component.MaxValue=component.ValueMax; component.LowValue=component.ValueMin; component.HighValue=component.ValueMax end
    local function render()
        syncAliases()
        local p1=(component.ValueMin-min)/(max-min); local p2=(component.ValueMax-min)/(max-min)
        fill.Position=UDim2.fromScale(p1,0); fill.Size=UDim2.fromScale(math.max(p2-p1,0),1)
        valueLabel.Text=tostring(component.ValueMin)..' – '..tostring(component.ValueMax)
    end
    function component:SetValue(a,b,skipCallback)
        if type(a)=='table' then b=a.Max or a[2] or a.ValueMax; a=a.Min or a[1] or a.ValueMin end
        a=math.clamp(round(tonumber(a) or self.ValueMin,step),min,max); b=math.clamp(round(tonumber(b) or self.ValueMax,step),min,max)
        if a>b then a,b=b,a end
        self.ValueMin,self.ValueMax=a,b; render(); if not skipCallback then task.spawn(self.Function,a,b) end
    end
    function component:Save(data) data[self.Name]={Min=self.ValueMin,Max=self.ValueMax} end
    function component:Load(data) if type(data)=='table' then self:SetValue(data.Min or data.ValueMin or data[1],data.Max or data.ValueMax or data[2],false) end end
    local dragging=false
    local function update(pos)
        local p=math.clamp((pos.X-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)
        local v=math.clamp(round(min+(max-min)*p,step),min,max)
        if math.abs(v-component.ValueMin)<=math.abs(v-component.ValueMax) then component:SetValue(v,component.ValueMax) else component:SetValue(component.ValueMin,v) end
    end
    bar.MouseButton1Down:Connect(function(x,y) dragging=true; update(Vector2.new(x,y)) end)
    inputService.InputChanged:Connect(function(input) if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then update(input.Position) end end)
    inputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    render(); return component
end

local openDropdown
settingConstructors.Dropdown = function(module, props)
    props=props or {}; props.Name=props.Name or 'Mode'; props.List=props.List or props.Values or {}
    local list=table.clone(props.List)
    local value=props.Default or list[1] or ''
    local frame=settingFrame(module,props.Name,38,props.Visible)
    labelFor(frame,props.Name,-145)
    local button=create('TextButton',frame,{AutoButtonColor=false,BackgroundColor3=Theme.SurfaceRaised,BackgroundTransparency=0.16,Position=UDim2.new(1,-135,0.5,-12),Size=UDim2.fromOffset(125,24),Text=tostring(value)..'  ▾',TextColor3=Theme.Text,TextSize=10,FontFace=FONT_REGULAR,ZIndex=10})
    corner(button,5);stroke(button,Theme.BorderSoft,0.92,1)
    local dropdown=create('Frame',screen,{Name='NeonDropdown',BackgroundColor3=Theme.SurfaceDark,BackgroundTransparency=0.04,Size=UDim2.fromOffset(160,0),Visible=false,ZIndex=500})
    corner(dropdown,6);stroke(dropdown,Theme.BorderSoft,0.84,1)
    local listFrame=create('ScrollingFrame',dropdown,{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(4,4),Size=UDim2.new(1,-8,1,-8),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ZIndex=501})
    local layout=create('UIListLayout',listFrame,{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder})
    local component=commonSetting({Value=value,List=list,Object=frame},module,props,'Dropdown')
    local function rebuild()
        listFrame:ClearAllChildren(); layout=create('UIListLayout',listFrame,{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder})
        for i,item in component.List do
            local entry=create('TextButton',listFrame,{AutoButtonColor=false,BackgroundColor3=item==component.Value and neon:GetThemeColor(i*0.03):Lerp(Theme.Surface,0.77) or Theme.Surface,BackgroundTransparency=item==component.Value and 0.03 or 0.28,Size=UDim2.new(1,0,0,26),Text=tostring(item),TextColor3=item==component.Value and Theme.Text or Theme.TextMuted,TextSize=10,FontFace=FONT_REGULAR,ZIndex=502,LayoutOrder=i})
            corner(entry,4)
            entry.MouseButton1Click:Connect(function() component:SetValue(item); dropdown.Visible=false; if openDropdown==dropdown then openDropdown=nil end end)
        end
        dropdown.Size=UDim2.fromOffset(160,math.clamp(#component.List*28+8,36,220))
    end
    function component:SetValue(v,skipCallback)
        if table.find(self.List,v)==nil and #self.List>0 then v=self.List[1] end
        if self.Value==v then button.Text=tostring(v)..'  ▾'; return end
        self.Value=v; button.Text=tostring(v)..'  ▾'; rebuild(); if not skipCallback then task.spawn(self.Function,v) end
    end
    function component:Change(newList)
        self.List=table.clone(newList or {}); if not table.find(self.List,self.Value) then self.Value=self.List[1] or '' end; button.Text=tostring(self.Value)..'  ▾'; rebuild()
    end
    function component:Save(data) data[self.Name]=self.Value end
    function component:Load(data) self:SetValue(type(data)=='table' and (data.Value or data.value) or data,false) end
    button.MouseButton1Click:Connect(function()
        if openDropdown and openDropdown~=dropdown then openDropdown.Visible=false end
        local pos=button.AbsolutePosition; dropdown.Position=UDim2.fromOffset(pos.X,pos.Y+button.AbsoluteSize.Y+4); dropdown.Visible=not dropdown.Visible; openDropdown=dropdown.Visible and dropdown or nil
    end)
    rebuild(); return component
end
settingConstructors.MultiDropdown = function(module, props)
    props=props or {};props.Name=props.Name or 'Options';props.List=props.List or props.Values or {}
    local list=table.clone(props.List)
    local enabled={}
    local defaults=props.Default
    if type(defaults)=='table' then for _,v in defaults do if table.find(list,v)then table.insert(enabled,v)end end
    elseif defaults~=nil and table.find(list,defaults) then table.insert(enabled,defaults) end
    local frame=settingFrame(module,props.Name,38,props.Visible);labelFor(frame,props.Name,-145)
    local button=create('TextButton',frame,{AutoButtonColor=false,BackgroundColor3=Theme.SurfaceRaised,BackgroundTransparency=0.16,Position=UDim2.new(1,-135,0.5,-12),Size=UDim2.fromOffset(125,24),Text='',TextColor3=Theme.Text,TextSize=9,FontFace=FONT_REGULAR,ZIndex=10});corner(button,5);stroke(button,Theme.BorderSoft,0.92,1)
    local dropdown=create('Frame',screen,{Name='NeonMultiDropdown',BackgroundColor3=Theme.SurfaceDark,BackgroundTransparency=0.04,Size=UDim2.fromOffset(180,0),Visible=false,ZIndex=500});corner(dropdown,6);stroke(dropdown,Theme.BorderSoft,0.84,1)
    local listFrame=create('ScrollingFrame',dropdown,{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(4,4),Size=UDim2.new(1,-8,1,-8),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ZIndex=501})
    local component=commonSetting({List=list,ListEnabled=enabled,Value=enabled,Object=frame},module,props,'MultiDropdown')
    local function updateButton()
        local n=#component.ListEnabled
        button.Text=(n==0 and 'None' or n==1 and tostring(component.ListEnabled[1]) or tostring(n)..' selected')..'  ▾'
    end
    local rebuild
    function component:GetValue(value)return table.find(self.ListEnabled,value)~=nil end
    function component:SetValue(value,state,skipCallback)
        if type(value)=='table' then
            self.ListEnabled={};for _,v in value do if table.find(self.List,v)then table.insert(self.ListEnabled,v)end end
        else
            local index=table.find(self.ListEnabled,value);state=state==nil and index==nil or state==true
            if state and not index and table.find(self.List,value)then table.insert(self.ListEnabled,value)elseif not state and index then table.remove(self.ListEnabled,index)end
        end
        self.Value=self.ListEnabled;updateButton();if rebuild then rebuild()end;if not skipCallback then task.spawn(self.Function,self.ListEnabled)end
    end
    function component:Change(newList)self.List=table.clone(newList or{});for i=#self.ListEnabled,1,-1 do if not table.find(self.List,self.ListEnabled[i])then table.remove(self.ListEnabled,i)end end;updateButton();rebuild()end
    function component:Save(data)data[self.Name]=table.clone(self.ListEnabled)end
    function component:Load(data)local value=type(data)=='table'and(data.ListEnabled or data.Value or data)or{};self:SetValue(value,nil,false)end
    rebuild=function()
        listFrame:ClearAllChildren();create('UIListLayout',listFrame,{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder})
        for i,item in component.List do
            local on=component:GetValue(item)
            local entry=create('TextButton',listFrame,{AutoButtonColor=false,BackgroundColor3=on and neon:GetThemeColor(i*0.03):Lerp(Theme.Surface,0.77)or Theme.Surface,BackgroundTransparency=on and 0.03 or 0.28,Size=UDim2.new(1,0,0,26),Text=(on and '●  'or'○  ')..tostring(item),TextColor3=on and Theme.Text or Theme.TextMuted,TextSize=10,FontFace=FONT_REGULAR,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=502,LayoutOrder=i});corner(entry,4);padding(entry,8,4,0,0)
            entry.MouseButton1Click:Connect(function()component:SetValue(item)end)
        end
        dropdown.Size=UDim2.fromOffset(180,math.clamp(#component.List*28+8,36,220))
    end
    button.MouseButton1Click:Connect(function()
        if openDropdown and openDropdown~=dropdown then openDropdown.Visible=false end
        local pos=button.AbsolutePosition;dropdown.Position=UDim2.fromOffset(pos.X,pos.Y+button.AbsoluteSize.Y+4);dropdown.Visible=not dropdown.Visible;openDropdown=dropdown.Visible and dropdown or nil
    end)
    updateButton();rebuild();return component
end

settingConstructors.TextBox = function(module,props)
    props=props or {};props.Name=props.Name or 'Text'
    local frame=settingFrame(module,props.Name,42,props.Visible);labelFor(frame,props.Name,-160)
    local box=create('TextBox',frame,{BackgroundColor3=Theme.SurfaceRaised,BackgroundTransparency=0.16,Position=UDim2.new(1,-150,0.5,-13),Size=UDim2.fromOffset(140,26),Text=tostring(props.Default or ''),PlaceholderText=tostring(props.Placeholder or ''),ClearTextOnFocus=false,TextColor3=Theme.Text,PlaceholderColor3=Theme.TextDim,TextSize=10,FontFace=FONT_REGULAR,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=10})
    corner(box,5);stroke(box,Theme.BorderSoft,0.92,1);padding(box,7,7,0,0)
    local component=commonSetting({Value=tostring(props.Default or ''),Object=frame},module,props,'TextBox')
    function component:SetValue(v,skipCallback) self.Value=tostring(v or '');box.Text=self.Value;if not skipCallback then task.spawn(self.Function,self.Value) end end
    function component:Save(data)data[self.Name]=self.Value end
    function component:Load(data)self:SetValue(type(data)=='table' and (data.Value or data.value) or data,false)end
    box.FocusLost:Connect(function(enter) component.Value=box.Text;task.spawn(component.Function,enter,component.Value) end)
    return component
end

settingConstructors.ColorSlider = function(module,props)
    props=props or {};props.Name=props.Name or 'Color'
    local h=tonumber(props.DefaultHue) or 0.5; local s=tonumber(props.DefaultSat) or 1; local v=tonumber(props.DefaultValue) or 1; local o=props.DefaultOpacity==nil and 1 or tonumber(props.DefaultOpacity)
    local frame=settingFrame(module,props.Name,72,props.Visible);labelFor(frame,props.Name,-70)
    local preview=create('Frame',frame,{BackgroundColor3=Color3.fromHSV(h,s,v),Position=UDim2.new(1,-38,0,8),Size=UDim2.fromOffset(28,18),BorderSizePixel=0,ZIndex=10});corner(preview,5);stroke(preview,Theme.BorderSoft,0.82,1)
    local huebar=create('TextButton',frame,{AutoButtonColor=false,Text='',BackgroundColor3=Color3.new(1,1,1),Position=UDim2.new(0,10,1,-30),Size=UDim2.new(1,-20,0,7),ZIndex=10});corner(huebar,3)
    local grad=create('UIGradient',huebar,{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromHSV(0,1,1)),ColorSequenceKeypoint.new(.17,Color3.fromHSV(.17,1,1)),ColorSequenceKeypoint.new(.33,Color3.fromHSV(.33,1,1)),ColorSequenceKeypoint.new(.5,Color3.fromHSV(.5,1,1)),ColorSequenceKeypoint.new(.67,Color3.fromHSV(.67,1,1)),ColorSequenceKeypoint.new(.83,Color3.fromHSV(.83,1,1)),ColorSequenceKeypoint.new(1,Color3.fromHSV(1,1,1))})})
    local alpha=create('TextButton',frame,{AutoButtonColor=false,Text='',BackgroundColor3=Theme.SurfaceRaised,Position=UDim2.new(0,10,1,-14),Size=UDim2.new(1,-20,0,4),ZIndex=10});corner(alpha,2)
    local afill=create('Frame',alpha,{BorderSizePixel=0,BackgroundColor3=Color3.fromHSV(h,s,v),Size=UDim2.fromScale(o,1),ZIndex=11});corner(afill,2)
    local component=commonSetting({Hue=h,Sat=s,Value=v,Opacity=o,Rainbow=false,Object=frame},module,props,'ColorSlider')
    local function render() preview.BackgroundColor3=Color3.fromHSV(component.Hue,component.Sat,component.Value);afill.BackgroundColor3=preview.BackgroundColor3;afill.Size=UDim2.fromScale(component.Opacity,1) end
    function component:SetValue(a,b,c,d,skipCallback)
        if type(a)=='table' then local t=a;a=t.Hue or t[1];b=t.Sat or t[2];c=t.Value or t[3];d=t.Opacity or t[4] end
        self.Hue=clamp01(a or self.Hue);self.Sat=clamp01(b or self.Sat);self.Value=clamp01(c or self.Value);self.Opacity=clamp01(d==nil and self.Opacity or d);render();if not skipCallback then task.spawn(self.Function,self.Hue,self.Sat,self.Value,self.Opacity) end
    end
    function component:Save(data)data[self.Name]={Hue=self.Hue,Sat=self.Sat,Value=self.Value,Opacity=self.Opacity,Rainbow=self.Rainbow}end
    function component:Load(data)if type(data)=='table'then self.Rainbow=data.Rainbow==true;self:SetValue(data.Hue,data.Sat,data.Value,data.Opacity,false)end end
    local dragHue,dragAlpha=false,false
    local function updateHue(pos) component:SetValue(math.clamp((pos.X-huebar.AbsolutePosition.X)/math.max(huebar.AbsoluteSize.X,1),0,1),component.Sat,component.Value,component.Opacity) end
    local function updateAlpha(pos) component:SetValue(component.Hue,component.Sat,component.Value,math.clamp((pos.X-alpha.AbsolutePosition.X)/math.max(alpha.AbsoluteSize.X,1),0,1)) end
    huebar.MouseButton1Down:Connect(function(x,y)dragHue=true;updateHue(Vector2.new(x,y))end)
    alpha.MouseButton1Down:Connect(function(x,y)dragAlpha=true;updateAlpha(Vector2.new(x,y))end)
    inputService.InputChanged:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseMovement then if dragHue then updateHue(i.Position) elseif dragAlpha then updateAlpha(i.Position) end end end)
    inputService.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then dragHue=false;dragAlpha=false end end)
    render();return component
end

settingConstructors.TextList = function(module,props)
    props=props or {};props.Name=props.Name or 'List'
    local frame=settingFrame(module,props.Name,78,props.Visible);labelFor(frame,props.Name,-60)
    local display=create('TextLabel',frame,{BackgroundTransparency=1,Position=UDim2.fromOffset(10,25),Size=UDim2.new(1,-20,0,18),Text='',TextColor3=Theme.TextDim,TextSize=9,FontFace=FONT_REGULAR,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=9})
    local box=create('TextBox',frame,{BackgroundColor3=Theme.SurfaceRaised,BackgroundTransparency=0.16,Position=UDim2.fromOffset(10,47),Size=UDim2.new(1,-52,0,23),Text='',PlaceholderText=tostring(props.Placeholder or 'add value'),ClearTextOnFocus=false,TextColor3=Theme.Text,PlaceholderColor3=Theme.TextDim,TextSize=9,FontFace=FONT_REGULAR,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=10});corner(box,5);padding(box,6,6,0,0)
    local add=create('TextButton',frame,{AutoButtonColor=false,BackgroundColor3=Theme.SurfaceRaised,BackgroundTransparency=0.08,Position=UDim2.new(1,-36,0,47),Size=UDim2.fromOffset(26,23),Text='+',TextColor3=Theme.Text,TextSize=14,FontFace=FONT_MEDIUM,ZIndex=10});corner(add,5)
    local initial=type(props.Default)=='table' and table.clone(props.Default) or {}
    local component=commonSetting({List=table.clone(initial),ListEnabled=table.clone(initial),Object=frame},module,props,'TextList')
    local function render() display.Text=#component.ListEnabled>0 and table.concat(component.ListEnabled,', ') or 'No entries' end
    function component:GetValue(name)return table.find(self.ListEnabled,name)~=nil end
    function component:Change(value)
        if type(value)=='table' then self.List=table.clone(value);self.ListEnabled=table.clone(value) end;render();task.spawn(self.Function,self.ListEnabled)
    end
    function component:ChangeValue()render();task.spawn(self.Function,self.ListEnabled)end
    function component:Add(value)
        value=tostring(value or ''):match('^%s*(.-)%s*$');if value=='' then return end
        if type(props.TextFunction)=='function' then local ok,converted=pcall(props.TextFunction,value);if ok and converted~=nil then value=tostring(converted)end end
        if not table.find(self.List,value) then table.insert(self.List,value) end;if not table.find(self.ListEnabled,value) then table.insert(self.ListEnabled,value) end;render();task.spawn(self.Function,self.ListEnabled)
    end
    function component:Remove(value)local i=table.find(self.List,value);if i then table.remove(self.List,i)end;i=table.find(self.ListEnabled,value);if i then table.remove(self.ListEnabled,i)end;render();task.spawn(self.Function,self.ListEnabled)end
    function component:Save(data)data[self.Name]={List=self.List,ListEnabled=self.ListEnabled}end
    function component:Load(data)if type(data)=='table'then self.List=table.clone(data.List or data);self.ListEnabled=table.clone(data.ListEnabled or data.List or data);render();task.spawn(self.Function,self.ListEnabled)end end
    local function submit()local val=box.Text;if val~='' then component:Add(val);box.Text=''end end
    add.MouseButton1Click:Connect(submit);box.FocusLost:Connect(function(enter)if enter then submit()end end)
    render();return component
end

local function newBind(owner, moduleBind)
    local bind={Keys={},Hold=false,Triggered=makeSignal(),Object=nil,Module=moduleBind==true}
    function bind:SetBind(keys)
        if type(keys)=='string'then keys={keys}end;self.Keys={}
        for _,key in ipairs(keys or {})do if tostring(key)~=''then table.insert(self.Keys,tostring(key))end end
        if self.Refresh then self:Refresh()end
    end
    function bind:SetVisible(value)if self.Object then self.Object.Visible=value==true end end
    function bind:Save(data)data.Bind={Keys=table.clone(self.Keys),Hold=self.Hold}end
    function bind:Load(data)data=data and (data.Bind or data) or {};self.Keys=table.clone(data.Keys or {});self.Hold=data.Hold==true;if self.Refresh then self:Refresh()end end
    function bind:Destroy()self.Triggered:Destroy();if self.Object and self.Object.Parent then self.Object:Destroy()end end
    return bind
end

local bindingTarget
settingConstructors.Bind = function(module,props)
    props=props or {};props.Name=props.Name or 'Bind'
    local frame=settingFrame(module,props.Name,38,props.Visible);labelFor(frame,props.Name,-130)
    local button=create('TextButton',frame,{AutoButtonColor=false,BackgroundColor3=Theme.SurfaceRaised,BackgroundTransparency=0.16,Position=UDim2.new(1,-120,0.5,-12),Size=UDim2.fromOffset(110,24),Text='None',TextColor3=Theme.Text,TextSize=9,FontFace=FONT_REGULAR,ZIndex=10});corner(button,5)
    local component=newBind(module,props.Module)
    component.Name=props.Name;component.Object=frame;component.Visible=props.Visible~=false;frame.Visible=component.Visible;module.Options[props.Name]=component;module.OptionOrder[#module.OptionOrder+1]=component
    function component:Refresh()button.Text=bindingTarget==self and 'Press a key…' or (#self.Keys>0 and table.concat(self.Keys,' + ') or 'None')end
    function component:SetVisible(value)self.Visible=value==true;frame.Visible=self.Visible end
    function component:Save(data)data[self.Name]={Keys=table.clone(self.Keys),Hold=self.Hold}end
    function component:Load(data)data=type(data)=='table'and data or {};self.Keys=table.clone(data.Keys or data.Bind or {});self.Hold=data.Hold==true;self:Refresh()end
    button.MouseButton1Click:Connect(function()bindingTarget=component;component:Refresh()end)
    component:Refresh();return component
end

settingConstructors.Button = function(module,props)
    props=props or {};props.Name=props.Name or 'Action'
    local frame=settingFrame(module,props.Name,38,props.Visible)
    local button=create('TextButton',frame,{AutoButtonColor=false,BackgroundColor3=Theme.SurfaceRaised,BackgroundTransparency=0.1,Position=UDim2.fromOffset(6,5),Size=UDim2.new(1,-12,1,-10),Text=props.Name,TextColor3=Theme.Text,TextSize=10,FontFace=FONT_MEDIUM,ZIndex=10});corner(button,5)
    local component=commonSetting({Object=frame},module,props,'Button')
    function component:Save()end;function component:Load()end
    button.MouseButton1Click:Connect(function()task.spawn(component.Function)end)
    return component
end

settingConstructors.Font = function(module,props)
    props=props or {};props.Name=props.Name or 'Font'
    local names={};for _,item in Enum.Font:GetEnumItems()do table.insert(names,item.Name)end;table.sort(names)
    local default=props.Default or 'Gotham';if not table.find(names,default)then default='Gotham'end
    local dd=settingConstructors.Dropdown(module,{Name=props.Name,List=names,Default=default,Darker=props.Darker,Visible=props.Visible,Function=function(name)end})
    local component={Name=props.Name,Type='Font',Object=dd.Object,Value=Font.fromEnum(Enum.Font[default]),Dropdown=dd,Visible=dd.Visible}
    -- Keep the font wrapper in the dropdown slot.
    module.Options[props.Name]=component
    for i,v in module.OptionOrder do if v==dd then module.OptionOrder[i]=component break end end
    local originalSet=dd.SetValue
    function component:SetValue(name,skipCallback)originalSet(dd,name,true);self.Value=Font.fromEnum(Enum.Font[dd.Value] or Enum.Font.Gotham);if not skipCallback then task.spawn(props.Function or function()end,self.Value)end end
    function component:SetVisible(value)dd:SetVisible(value);self.Visible=dd.Visible end
    function component:Save(data)data[self.Name]=dd.Value end
    function component:Load(data)self:SetValue(type(data)=='table'and(data.Value or data.value)or data,false)end
    return component
end

settingConstructors.Targets = function(module,props)
    props=props or {}
    local component={Name=props.Name or 'Targets',Type='Targets',Object=nil}
    local names={'Players','NPCs','Walls'}
    for _,name in names do
        if props[name]~=nil then
            component[name]=settingConstructors.Toggle(module,{Name=(props.Name and props.Name..' ' or '')..name,Default=props[name],Function=function()if props.Function then props.Function()end end})
        else component[name]={Enabled=false} end
    end
    return component
end

local function createArrayRow(module)
    if arrayRows[module] then return end
    local row=create('Frame',arrayList,{Name=module.Id,BackgroundColor3=Theme.SurfaceDark,BackgroundTransparency=0.18,BorderSizePixel=0,Size=UDim2.fromOffset(0,25),Visible=false,ZIndex=46})
    corner(row,5);stroke(row,Theme.BorderSoft,0.9,1)
    local edge=create('Frame',row,{BorderSizePixel=0,BackgroundColor3=neon:GetThemeColor(module.Index*0.04),Size=UDim2.fromOffset(2,17),Position=UDim2.fromOffset(4,4),ZIndex=48});corner(edge,2)
    local text=create('TextLabel',row,{BackgroundTransparency=1,Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-20,1,0),Text=module.DisplayName,TextColor3=Theme.Text,TextSize=10,FontFace=FONT_REGULAR,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=47})
    arrayRows[module]={Frame=row,Text=text,Edge=edge}
end

local function refreshArrayList()
    local active={}
    for _,module in neon.Modules do
        if type(module)=='table' and module.Id and module.Enabled and module.Visible~=false and not module.Internal then table.insert(active,module)end
    end
    table.sort(active,function(a,b)return #a.DisplayName>#b.DisplayName end)
    local activeSet={}
    for i,module in active do
        activeSet[module]=true;createArrayRow(module);local data=arrayRows[module]
        data.Frame.Visible=true;data.Frame.LayoutOrder=i
        local extra=type(module.ExtraText)=='function'and module.ExtraText()or module.ExtraText
        data.Text.Text=module.DisplayName..(extra and extra~=''and('  '..tostring(extra))or'')
        local bounds=getFontBounds(data.Text.Text,10,FONT_REGULAR)
        data.Frame.Size=UDim2.fromOffset(math.clamp(bounds.X+24,70,340),25)
    end
    for module,data in arrayRows do if not activeSet[module]then data.Frame.Visible=false end end
end

function neon:UpdateTextGUI() refreshArrayList() end

local function moduleRowVisual(module, hover)
    if not module.Row then return end
    local enabled=module.Enabled
    local bg=enabled and neon:GetThemeColor(module.Index*0.035):Lerp(Theme.Surface,0.77) or (hover and Theme.SurfaceHover or Theme.Surface)
    module.Row.BackgroundColor3=bg
    module.Row.BackgroundTransparency=enabled and 0.03 or (hover and 0.08 or 0.22)
    module.NameLabel.TextColor3=enabled and Theme.Text or (hover and Theme.Text or Theme.TextMuted)
    module.Dot.BackgroundColor3=enabled and neon:GetThemeColor(module.Index*0.035) or Color3.fromRGB(102,108,116)
    module.ToggleTrack.BackgroundColor3=enabled and neon:GetThemeColor(module.Index*0.035) or Color3.fromRGB(80,86,94)
    module.ToggleKnob.Position=UDim2.new(0,enabled and 18 or 3,0.5,-7)
    module.ToggleKnob.BackgroundColor3=Color3.fromRGB(245,246,248)
    module.RowStroke.Color=selectedModule==module and neon:GetThemeColor(0) or Theme.BorderSoft
    module.RowStroke.Transparency=selectedModule==module and 0.55 or 0.94
end

function neon:SelectModule(module)
    if selectedModule and selectedModule.SettingsPage then selectedModule.SettingsPage.Visible=false;moduleRowVisual(selectedModule,false)end
    selectedModule=module
    emptyInspector.Visible=module==nil
    if not module then inspectorTitle.Text='Inspector';inspectorSub.Text='Select a module to edit';return end
    inspectorTitle.Text=module.DisplayName
    inspectorSub.Text=module.Tooltip~='' and stripTags(module.Tooltip) or module.Category..' module'
    local page=ensureSettingsPage(module);page.Visible=true
    moduleRowVisual(module,false)
end

function neon:_CreateModule(categoryName,props)
    assert(type(props)=='table' and type(props.Name)=='string','Neon module requires Name')
    local id=props.Id or props.Name
    if self.Modules[id] and self.Modules[id].Destroy then self.Modules[id]:Destroy() end
    local category=canonicalCategory(categoryName)
    local categoryObject=categoryObjects[category] or createCategory(category)
    local module=addMaid({
        Id=id,Name=id,DisplayName=props.DisplayName or visibleName(id),Category=category,
        Enabled=false,Visible=props.Visible~=false,Tooltip=tostring(props.Tooltip or ''),ExtraText=props.ExtraText,
        Options={},OptionOrder={},Index=0,Function=props.Function or function()end,Internal=props.Internal==true,
    })
    local n, counted=0,{};for _,m in self.Modules do if type(m)=='table'and m.Id and not counted[m]then counted[m]=true;n+=1 end end;module.Index=n+1
    self.Modules[id]=module
    if module.DisplayName~=id and self.Modules[module.DisplayName]==nil then self.Modules[module.DisplayName]=module end
    categoryObject.Modules[id]=module

    -- HUD modules draw into module.Children.
    if props.Size then
        local startX=22+((module.Index-1)%5)*18
        local startY=72+((module.Index-1)%5)*18
        local children=create('Frame',hudGui,{Name=id..'HUD',BackgroundTransparency=1,BorderSizePixel=0,Position=props.Position or UDim2.fromOffset(startX,startY),Size=props.Size,Visible=false,Active=true,ZIndex=30})
        module.Children=children
        local dragging,dragOrigin,startPos=false,nil,nil
        neon:Clean(children.InputBegan:Connect(function(input)
            if clickgui.Visible and input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;dragOrigin=input.Position;startPos=children.Position end
        end))
        neon:Clean(inputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
                local delta=input.Position-dragOrigin
                children.Position=startPos+UDim2.fromOffset(delta.X,delta.Y)
            end
        end))
        neon:Clean(inputService.InputEnded:Connect(function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end))
    end

    local row=create('TextButton',moduleList,{Name=id,AutoButtonColor=false,BackgroundColor3=Theme.Surface,BackgroundTransparency=0.22,BorderSizePixel=0,Size=UDim2.new(1,-2,0,40),Text='',Visible=module.Visible,ZIndex=8,LayoutOrder=module.Index})
    corner(row,5);local rowStroke=stroke(row,Theme.BorderSoft,0.94,1)
    local dot=create('Frame',row,{BackgroundColor3=Color3.fromRGB(102,108,116),BorderSizePixel=0,Position=UDim2.fromOffset(12,17),Size=UDim2.fromOffset(7,7),ZIndex=10});corner(dot,4)
    local nameLabel=create('TextLabel',row,{BackgroundTransparency=1,Position=UDim2.fromOffset(30,0),Size=UDim2.new(1,-124,1,0),Text=module.DisplayName,TextColor3=Theme.TextMuted,TextSize=12,FontFace=FONT_REGULAR,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=10})
    local gear=create('TextButton',row,{AutoButtonColor=false,BackgroundTransparency=1,Position=UDim2.new(1,-84,0,0),Size=UDim2.fromOffset(34,40),Text='⋮',TextColor3=Theme.TextDim,TextSize=18,FontFace=FONT_MEDIUM,ZIndex=11})
    local toggleTrack=create('TextButton',row,{AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(80,86,94),BackgroundTransparency=0.12,Position=UDim2.new(1,-47,0.5,-9),Size=UDim2.fromOffset(36,18),Text='',ZIndex=11});corner(toggleTrack,9)
    local toggleKnob=create('Frame',toggleTrack,{BackgroundColor3=Color3.fromRGB(245,246,248),BorderSizePixel=0,Position=UDim2.new(0,3,0.5,-7),Size=UDim2.fromOffset(14,14),ZIndex=12});corner(toggleKnob,7)
    module.Object=row;module.Row=row;module.RowStroke=rowStroke;module.Dot=dot;module.NameLabel=nameLabel;module.ToggleTrack=toggleTrack;module.ToggleKnob=toggleKnob
    ensureSettingsPage(module)

    -- Keep module.Bind available for profiles and game modules.
    local moduleBind=settingConstructors.Bind(module,{Name='Keybind',Module=true})
    module.Bind=moduleBind

    function module:SetDisplayName(name)
        self.DisplayName=tostring(name or self.Id);self.NameLabel.Text=self.DisplayName;if arrayRows[self]then arrayRows[self].Text.Text=self.DisplayName end
    end
    function module:SetVisible(value)
        self.Visible=value==true;self.Row.Visible=self.Visible;neon.ModuleSchemaRevision+=1;neon:RefreshModuleVisibility()
    end
    function module:Toggle(multiple)
        self.Enabled=not self.Enabled
        neon.ModuleVisualRevision+=1
        if self.Children then self.Children.Visible=self.Enabled end
        if not self.Enabled then self:ClearConnections() end
        moduleRowVisual(self,false)
        neon:UpdateTextGUI()
        if neon.Loaded then neon:RecordRecent(self.Id) end
        task.spawn(self.Function,self.Enabled)
        return self.Enabled
    end
    function module:Save(data)
        local options={}
        for _,option in self.OptionOrder do if option.Save then pcall(option.Save,option,options)end end
        local bindData={};self.Bind:Save(bindData)
        data[self.Id]={Enabled=self.Enabled,Visible=self.Visible,Options=options,Bind=bindData.Bind or bindData.Keybind,Position=self.Children and {X=self.Children.Position.X.Offset,Y=self.Children.Position.Y.Offset} or nil}
    end
    function module:Load(data)
        if type(data)~='table'then return end
        if type(data.Options)=='table'then for name,val in data.Options do local option=self.Options[name];if option and option.Load then pcall(option.Load,option,val)end end end
        if data.Bind then self.Bind:Load(data.Bind)end
        if data.Visible~=nil then self:SetVisible(data.Visible)end
        if data.Position and self.Children then self.Children.Position=UDim2.fromOffset(tonumber(data.Position.X)or 0,tonumber(data.Position.Y)or 0)end
        local desired=data.Enabled==true and not self.Bind.Hold
        if self.Enabled~=desired then self:Toggle(true)end
    end
    function module:Destroy()
        if self.Enabled then pcall(self.Toggle,self,true)end
        self:ClearConnections();if self.Bind then self.Bind:Destroy()end
        if self.SettingsPage then self.SettingsPage:Destroy()end
        if self.Row then self.Row:Destroy()end
        if self.Children then self.Children:Destroy()end
        if arrayRows[self]then arrayRows[self].Frame:Destroy();arrayRows[self]=nil end
        if neon.Modules[self.Id]==self then neon.Modules[self.Id]=nil end
        if neon.Modules[self.DisplayName]==self then neon.Modules[self.DisplayName]=nil end
        if categoryObject.Modules[self.Id]==self then categoryObject.Modules[self.Id]=nil end
    end
    for name,constructor in settingConstructors do
        module['Create'..name]=function(self2,p)return constructor(self2,p)end
    end
    -- Game modules can add custom inspector controls here.
    for name,constructor in self.Components do
        module['Create'..name]=function(self2,p)
            local result=constructor(p or {},ensureSettingsPage(self2),self2)
            if type(result)=='table' then
                result.Name=result.Name or name
                self2.Options[name]=self2.Options[name] or result
                if not table.find(self2.OptionOrder,result)then table.insert(self2.OptionOrder,result)end
            end
            return result
        end
    end
    function module:Setting(spec)
        local kind=tostring(spec.Type or spec.Kind or ''):lower();local map={toggle='Toggle',boolean='Toggle',slider='Slider',number='Slider',range='TwoSlider',twoslider='TwoSlider',dropdown='Dropdown',mode='Dropdown',select='Dropdown',multidropdown='MultiDropdown',color='ColorSlider',colour='ColorSlider',textbox='TextBox',text='TextBox',input='TextBox',list='TextList',textlist='TextList',bind='Bind',keybind='Bind',button='Button',action='Button',font='Font',targets='Targets'}
        local ctor=settingConstructors[map[kind] or ''];assert(ctor,'Unsupported Neon setting type '..kind);local copy=table.clone(spec);copy.Type=nil;copy.Kind=nil;return ctor(self2,copy)
    end
    function module:ToggleSetting(name,default,callback)return self:CreateToggle({Name=name,Default=default,Function=callback})end
    function module:Slider(name,min,max,default,callback)return self:CreateSlider({Name=name,Min=min,Max=max,Default=default,Function=callback})end
    function module:Mode(name,values,default,callback)return self:CreateDropdown({Name=name,List=values,Default=default,Function=callback})end

    local hover=false
    row.MouseEnter:Connect(function()hover=true;moduleRowVisual(module,true)end)
    row.MouseLeave:Connect(function()hover=false;moduleRowVisual(module,false)end)
    row.MouseButton1Click:Connect(function()if not neon.EditGUI then module:Toggle()end end)
    row.MouseButton2Click:Connect(function()neon:SelectModule(module)end)
    gear.MouseButton1Click:Connect(function()neon:SelectModule(module)end)
    toggleTrack.MouseButton1Click:Connect(function()module:Toggle()end)
    moduleRowVisual(module,false)
    self.ModuleSchemaRevision+=1
    self:RefreshModuleVisibility()
    return module
end

function neon:Module(categoryName,props)return self:_CreateModule(categoryName,props)end

function neon:Remove(name)
    local module=self.Modules[name]
    if module and module.Destroy then module:Destroy();return true end
    return false
end
function neon:GetModule(name)return self.Modules[name]end
function neon:GetCategory(name)return self.Categories[canonicalCategory(name)] or self.Categories[name]end

function neon:RefreshModuleVisibility()
    local count=0;local q=searchQuery:lower()
    local seen={}
    for _,module in self.Modules do
        if type(module)=='table'and module.Id and not seen[module]then
            seen[module]=true
            local cat=module.Category==selectedCategory
            local match=q==''or module.DisplayName:lower():find(q,1,true)or module.Id:lower():find(q,1,true)or module.Tooltip:lower():find(q,1,true)
            local show=module.Visible and cat and match
            if module.Row then module.Row.Visible=show end
            if show then count+=1 end
        end
    end
    countText.Text=tostring(count)..(count==1 and ' module' or ' modules')
end

function neon:CreateCategory(props)
    return createCategory(canonicalCategory(props.Name or props.Name or 'Utility'))
end

function neon:CreateCategoryList(props)
    props=props or {};local name=props.Name or 'List'
    local component=addMaid({Name=name,Options={},List={},ListEnabled={},ColorUpdate={Event=makeSignal()},Type='CategoryList'})
    function component:GetValue(value)
        for _,entry in self.List do if (type(entry)=='table'and entry.Name or entry)==value then return true end end
        return false
    end
    function component:Add(value,enabled)
        value=tostring(value or '');if value==''or self:GetValue(value)then return end
        table.insert(self.List,{Name=value,Enabled=enabled~=false});if enabled~=false then table.insert(self.ListEnabled,value)end
    end
    function component:Remove(value)
        for i=#self.List,1,-1 do local e=self.List[i];if(type(e)=='table'and e.Name or e)==value then table.remove(self.List,i)end end
        local i=table.find(self.ListEnabled,value);if i then table.remove(self.ListEnabled,i)end
    end
    function component:ChangeValue() end
    function component:CreateToggle(p)local dummy={Options=self.Options,OptionOrder={}};local c=settingConstructors.Toggle(dummy,p);self.Options[p.Name]=c;return c end
    function component:CreateColorSlider(p)local dummy={Options=self.Options,OptionOrder={}};local c=settingConstructors.ColorSlider(dummy,p);self.Options[p.Name]=c;return c end
    local hostCategory=(name=='Friends'or name=='Targets')and'Player'or'Utility'
    local module=neon:_CreateModule(hostCategory,{Name='__system_'..name,DisplayName=name,Tooltip=props.Tooltip or ('Manage '..name:lower()),Internal=true,Function=function()end})
    component.Module=module
    function component:CreateToggle(p)local c=module:CreateToggle(p);self.Options[p.Name]=c;return c end
    function component:CreateColorSlider(p)local c=module:CreateColorSlider(p);self.Options[p.Name]=c;return c end
    local listOption=module:CreateTextList({Name=name,Placeholder=props.Placeholder or 'add entry',Default={}})
    component.List=listOption.List;component.ListEnabled=listOption.ListEnabled
    local rawAdd=listOption.Add
    function listOption:Add(value)rawAdd(self,value);component.List=self.List;component.ListEnabled=self.ListEnabled end
    neon.Categories[name]=component
    return component
end

local function settingsGroup(name)
    local group={Name=name,Options={}}
    function group:CreateToggle(props)
        local obj={Name=props.Name,Enabled=props.Default==true,Function=props.Function or function()end,Type='Toggle',Object=create('Frame',screen,{Visible=false})}
        function obj:Toggle()self.Enabled=not self.Enabled;task.spawn(self.Function,self.Enabled)end
        function obj:SetValue(v,skip)self.Enabled=v==true;if not skip then task.spawn(self.Function,self.Enabled)end end
        function obj:Save(data)data[self.Name]=self.Enabled end
        function obj:Load(data)self:SetValue(type(data)=='table'and data.Enabled or data,false)end
        group.Options[props.Name]=obj;return obj
    end
    function group:Save(data)local out={};for _,o in self.Options do if o.Save then o:Save(out)end end;data[name]={Options=out}end
    function group:Load(data)data=data and(data.Options or data)or{};for key,v in data do local o=self.Options[key];if o and o.Load then o:Load(v)end end end
    neon.Settings[name]=group;return group
end

local modulesSettings=settingsGroup('Modules')
modulesSettings:CreateToggle({Name='Use team color',Default=true})
modulesSettings:CreateToggle({Name='Teams by server',Default=true})
local guiSettings=settingsGroup('GUI')
guiSettings:CreateToggle({Name='GUI bind indicator',Default=true})

-- Universal expects Friends and Targets here.
local friends=neon:CreateCategoryList({Name='Friends',Placeholder='Roblox username'})
friends:CreateToggle({Name='Use friends',Default=true})
friends:CreateToggle({Name='Recolor visuals',Default=true})
friends:CreateColorSlider({Name='Friends color',DefaultHue=0.46,DefaultSat=0.75,DefaultValue=1,Function=function(...)friends.ColorUpdate.Event:Fire(...)end})
local targets=neon:CreateCategoryList({Name='Targets',Placeholder='Roblox username'})

-- Profiles is a settings list, not a category.
local profiles={Name='Profiles',List={{Name='default',Enabled=true}},ListEnabled={'default'},Options={}}
function profiles:GetValue(name)for _,v in self.List do if v.Name==name then return true end end;return false end
function profiles:Add(name)if not self:GetValue(name)then table.insert(self.List,{Name=name,Enabled=true});table.insert(self.ListEnabled,name)end end
function profiles:ChangeValue()end
neon.Categories.Profiles=profiles

local interfaceModule=neon:_CreateModule('Utility',{Name='__neon_interface',DisplayName='Interface',Tooltip='Neon UI, HUD and theme controls.',Internal=true,Function=function()end})
interfaceModule.Enabled=true
neon.Blur=interfaceModule:CreateToggle({Name='Background blur',Default=true,Function=function()neon:BlurCheck()end})
neon.Notifications=interfaceModule:CreateToggle({Name='Notifications',Default=true})
neon.ToggleNotifications=interfaceModule:CreateToggle({Name='Toggle notifications',Default=false})
neon.ReducedMotion=interfaceModule:CreateToggle({Name='Reduced motion',Default=false})
neon.NotificationCooldown=interfaceModule:CreateSlider({Name='Notification cooldown',Min=0,Max=10,Default=0,Decimal=10,Suffix='s'})
neon.EffectUpdateRate=interfaceModule:CreateSlider({Name='Visual update rate',Min=15,Max=120,Default=60,Suffix=' fps'})
neon.GradientTheme=interfaceModule:CreateDropdown({Name='Theme',List={'Krs','Neon','Digital Horizons','Ultraviolet','Vapor','Mono'},Default='Krs',Function=function(value)neon.ActiveThemeName=value;neon:RefreshTheme()end})
neon.GUIColor={Hue=0.5,Sat=1,Value=1}

function neon:RefreshTheme()
    local colors=themePalette();Theme.Accent,Theme.Accent2,Theme.Accent3=colors[1],colors[2],colors[3]
    moduleList.ScrollBarImageColor3=colors[1]
    if inspector:FindFirstChildWhichIsA('ScrollingFrame',true) then end
    for name,data in categoryButtons do if name==selectedCategory then data.Button.BackgroundColor3=colors[1]:Lerp(Theme.Surface,0.76);data.Stroke.Color=colors[1]end end
    for _,module in self.Modules do if type(module)=='table'and module.Id then moduleRowVisual(module,false)end end
    for obj,prop in self.HUDAccentObjects do if obj and obj.Parent then pcall(function()obj[prop]=self:GetThemeColor(0)end)end end
end

function neon:RecordRecent(name)
    self.Recent=self.Recent or {};self.Recent[name]=os.clock()
end
function neon:ToggleFavorite(name)
    self.Favorites=self.Favorites or {};self.Favorites[name]=not self.Favorites[name];return true
end

function neon:CreateOverlay(props)
    props=props or {};local name=props.Name or 'Overlay'
    local container=create('Frame',hudGui,{Name='Overlay_'..name,BackgroundTransparency=1,Position=props.Position or UDim2.fromOffset(250,120),Size=props.Size and UDim2.fromOffset(math.max(props.Size.X.Offset+210,220),math.max(props.Size.Y.Offset+48,80))or UDim2.fromOffset(260,160),Visible=false,ZIndex=35})
    local headerBar=create('Frame',container,{Name='Header',BackgroundColor3=Theme.SurfaceDark,BackgroundTransparency=0.12,Size=UDim2.new(1,0,0,28),BorderSizePixel=0,ZIndex=36});corner(headerBar,7);stroke(headerBar,Theme.BorderSoft,0.9,1)
    local accent=create('Frame',headerBar,{BorderSizePixel=0,BackgroundColor3=self:GetThemeColor(0),Size=UDim2.new(1,-10,0,2),Position=UDim2.fromOffset(5,0),ZIndex=38});corner(accent,2);self:RegisterHUDAccent(accent)
    local ttl=create('TextLabel',headerBar,{BackgroundTransparency=1,Position=UDim2.fromOffset(9,1),Size=UDim2.new(1,-18,1,-1),Text=visibleName(name),TextColor3=Theme.TextMuted,TextSize=10,FontFace=FONT_MEDIUM,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=37})
    local children=create('Frame',container,{Name='Children',BackgroundTransparency=1,Position=UDim2.fromOffset(0,32),Size=UDim2.new(1,0,1,-32),ZIndex=35})
    local overlay={Name=name,Children=children,Object=container,Connections={}}
    addMaid(overlay)
    local module=self:_CreateModule('Vision',{Name='__overlay_'..name,DisplayName=visibleName(name),Tooltip='HUD overlay',Function=function(enabled)container.Visible=enabled;if props.Function then props.Function(enabled)end end})
    overlay.Button=module
    for ctorName,_ in settingConstructors do overlay['Create'..ctorName]=function(_,p)return module['Create'..ctorName](module,p)end end
    function overlay:Toggle(...)return module:Toggle(...)end
    setmetatable(overlay,{__index=function(_,k)return module[k]end})
    local dragging=false;local dragOrigin;local startPos
    headerBar.InputBegan:Connect(function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 and clickgui.Visible then dragging=true;dragOrigin=input.Position;startPos=container.Position end end)
    inputService.InputChanged:Connect(function(input)if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then local d=input.Position-dragOrigin;container.Position=startPos+UDim2.fromOffset(d.X,d.Y)end end)
    inputService.InputEnded:Connect(function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    self.OverlayRegistry[name]=overlay
    return overlay
end

neon.GUIBind=newBind(neon,true)
neon.GUIBind.Keys={'RightShift'}
function neon.GUIBind:Refresh()end

local function setGuiVisible(value)
    if clickgui.Visible==value then return end
    clickgui.Visible=value
    if value then
        root.Size=UDim2.fromOffset(970,610);root.BackgroundTransparency=0.22;shadow.BackgroundTransparency=0.72
        tween:Tween(root,TweenInfo.new(0.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(1000,640),BackgroundTransparency=0.06})
        tween:Tween(shadow,TweenInfo.new(0.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundTransparency=0.48})
    end
    neon:BlurCheck()
end
neon.GUIBind.Triggered:Connect(function()setGuiVisible(not clickgui.Visible)end)
close.MouseButton1Click:Connect(function()setGuiVisible(false)end)
backdrop.MouseButton1Click:Connect(function()setGuiVisible(false)end)
root.Active=true

searchBox:GetPropertyChangedSignal('Text'):Connect(function()searchQuery=searchBox.Text:lower():match('^%s*(.-)%s*$')or'';neon:RefreshModuleVisibility()end)

local pressed={}
local function normalizeKey(input)
    if input.KeyCode and input.KeyCode~=Enum.KeyCode.Unknown then return input.KeyCode.Name end
    return input.UserInputType and input.UserInputType.Name or nil
end
local function bindMatches(keys)
    if #keys==0 then return false end
    for _,key in keys do if not pressed[key] then return false end end
    return true
end
neon:Clean(inputService.InputBegan:Connect(function(input,processed)
    local key=normalizeKey(input);if not key then return end;pressed[key]=true
    if bindingTarget then
        if key=='Escape'then bindingTarget:SetBind({}) else bindingTarget:SetBind({key})end
        bindingTarget=nil;return
    end
    if processed and inputService:GetFocusedTextBox() then return end
    if inputService:IsKeyDown(Enum.KeyCode.LeftControl) and key=='F' and clickgui.Visible then searchBox:CaptureFocus();return end
    if bindMatches(neon.GUIBind.Keys) then neon.GUIBind.Triggered:Fire(true);return end
    local seen={}
    for _,module in neon.Modules do
        if type(module)=='table'and module.Id and not seen[module]then
            seen[module]=true
            local bind=module.Bind
            if bind and bindMatches(bind.Keys)then
                if bind.Hold then if not module.Enabled then module:Toggle(true)end;bind.Triggered:Fire(true)
                else module:Toggle(true);bind.Triggered:Fire(true)end
            end
        end
    end
end))
neon:Clean(inputService.InputEnded:Connect(function(input)
    local key=normalizeKey(input);if key then pressed[key]=nil end
    local seen={}
    for _,module in neon.Modules do
        if type(module)=='table'and module.Id and not seen[module]then seen[module]=true;local bind=module.Bind;if bind and bind.Hold and module.Enabled and not bindMatches(bind.Keys)then module:Toggle(true);bind.Triggered:Fire(false)end end
    end
end))

local function ensureFolders()
    for _,path in {'neon','neon/profiles','neon/games','neon/guis','neon/libraries','neon/assets','neon/additions','neon/additions/configs'}do pcall(makefolder,path)end
end
local function profilePath(name)return 'neon/profiles/'..tostring(name or neon.Profile)..tostring(neon.Place)..'.txt'end

function neon:Save(name)
    if self.SwitchingProfile then return end
    ensureFolders();name=name or self.Profile
    local data={Brand='Neon',Version=self.Version,Profile=name,Theme=self.ActiveThemeName,Modules={},Categories={},Settings={}}
    local seen={}
    for _,module in self.Modules do if type(module)=='table'and module.Id and not seen[module]then seen[module]=true;module:Save(data.Modules)end end
    for _,catName in {'Friends','Targets'}do local cat=self.Categories[catName];if cat then data.Categories[catName]={List=cat.List,ListEnabled=cat.ListEnabled,Options={}};for optionName,opt in cat.Options do if opt.Save then opt:Save(data.Categories[catName].Options)end end end end
    for name2,group in self.Settings do group:Save(data.Settings)end
    local ok,encoded=pcall(httpService.JSONEncode,httpService,data);if ok then pcall(writefile,profilePath(name),encoded)end
    return ok
end

local function decodeFile(path)
    local ok,raw=pcall(readfile,path);if not ok or type(raw)~='string'then return nil end
    local ok2,data=pcall(httpService.JSONDecode,httpService,raw);return ok2 and data or nil
end

function neon:Load(_,name)
    name=name or self.Profile;self.Profile=name
    local data=decodeFile(profilePath(name))
    -- Import an old profile only if no Neon profile exists.
    if not data then data=decodeFile('tenacity/profiles/'..tostring(name)..tostring(self.Place)..'.txt')end
    if data then
        if data.Theme and themePresets[data.Theme]then self.ActiveThemeName=data.Theme;if self.GradientTheme then self.GradientTheme:SetValue(data.Theme,true)end end
        if type(data.Settings)=='table'then for groupName,groupData in data.Settings do local group=self.Settings[groupName];if group then group:Load(groupData)end end end
        if type(data.Categories)=='table'then for _,catName in {'Friends','Targets'}do local saved=data.Categories[catName];local cat=self.Categories[catName];if saved and cat then cat.List=table.clone(saved.List or{});cat.ListEnabled=table.clone(saved.ListEnabled or{});if saved.Options then for optionName,val in saved.Options do local opt=cat.Options[optionName];if opt and opt.Load then pcall(opt.Load,opt,val)end end end end end end
        if type(data.Modules)=='table'then
            local seen={}
            for key,moduleData in data.Modules do local module=self.Modules[key];if module and not seen[module]then seen[module]=true;pcall(module.Load,module,moduleData)end end
        elseif type(data.Categories)=='table'then -- Old profiles grouped modules by category.
            for _,categoryData in data.Categories do if type(categoryData)=='table'and type(categoryData.Modules)=='table'then for key,moduleData in categoryData.Modules do local module=self.Modules[key];if module then pcall(module.Load,module,moduleData)end end end end
        end
    end
    self.Loaded=true;self:RefreshTheme();self:RefreshModuleVisibility();self:UpdateTextGUI();return true
end

function neon:SwitchProfile(name)
    if type(name)~='string'or name==''or name==self.Profile then return false end
    self:Save();self.Profile=name;if not self.Categories.Profiles:GetValue(name)then self.Categories.Profiles:Add(name)end;self:Load(true,name);return true
end
function neon:CycleProfile(direction)
    local names={};for _,v in self.Categories.Profiles.List do table.insert(names,v.Name)end;table.sort(names);if #names<2 then return end;local i=table.find(names,self.Profile)or 1;self:SwitchProfile(names[((i-1+(direction or 1))%#names)+1])
end

function neon:GetKeybindRows(activeOnly)
    local rows={};local seen={}
    for _,module in self.Modules do if type(module)=='table'and module.Id and not seen[module]then seen[module]=true;if module.Bind and #module.Bind.Keys>0 and(not activeOnly or module.Enabled)then table.insert(rows,{Name=module.DisplayName,Keys=table.concat(module.Bind.Keys,' + '),Enabled=module.Enabled,Hold=module.Bind.Hold})end end end
    table.sort(rows,function(a,b)if a.Enabled~=b.Enabled then return a.Enabled end return a.Name:lower()<b.Name:lower()end);return rows
end

function neon:BulkDisable()
    for _,module in self.Modules do if type(module)=='table'and module.Id and module.Enabled and module~=interfaceModule then pcall(module.Toggle,module,true)end end
end
function neon:UndoBulkDisable()end

function neon:Uninject()
    if self.Loaded==nil then return end
    pcall(self.Save,self)
    self.Loaded=nil
    local seen={}
    for _,module in self.Modules do if type(module)=='table'and module.Id and not seen[module]then seen[module]=true;if module.Enabled then pcall(module.Toggle,module,true)end;module:ClearConnections()end end
    for i=#self.Connections,1,-1 do dispose(self.Connections[i]);self.Connections[i]=nil end
    if blurEffect and blurEffect.Parent then pcall(function()blurEffect:Destroy()end)end
    if screen and screen.Parent then pcall(function()screen:Destroy()end)end
    if shared.Neon==self then shared.Neon=nil end
    shared.NeonBuild=nil
end

-- Kept for game modules that still call these hooks.
function neon:RegisterGUIStyleObject(object)return object end
function neon:ApplyGUIStyleObject(object)return object end
function neon:UpdateGUI()self:RefreshTheme()end
function neon:Color(hue)return hue,1,1 end
function neon:LoadOptions(obj,data)for name,val in data or{}do local option=obj.Options and obj.Options[name];if option and option.Load then option:Load(val)end end end
function neon:SaveOptions(obj)local out={};for _,option in obj.OptionOrder or{}do if option.Save then option:Save(out)end end;return out end

local frameCount,lastFps,fps=0,os.clock(),0
local lastVisual=0
neon:Clean(runService.RenderStepped:Connect(function()
    frameCount+=1
    local now=os.clock()
    if now-lastFps>=0.5 then fps=math.floor(frameCount/(now-lastFps)+0.5);frameCount=0;lastFps=now;watermarkText.Text='Neon '..neon.Version..'  |  '..fps..' fps' end
    local rate=neon.EffectUpdateRate and neon.EffectUpdateRate.Value or 60
    if now-lastVisual<(1/math.max(rate,1))then return end;lastVisual=now
    neon:UpdateGUIQueue()
    if clickgui.Visible then
        for _,module in neon.Modules do if type(module)=='table'and module.Id and module.Enabled then moduleRowVisual(module,false)end end
    end
end))

setCategory('Offense')
neon:SelectModule(nil)

return neon
