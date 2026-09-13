return function(neon)
	local textService = game:GetService('TextService')
	local runService = game:GetService('RunService')

	local api = {
		Version = 2,
		Name = 'Krs',
		Palette = {
			Void = Color3.fromRGB(7, 10, 14),
			Surface = Color3.fromRGB(12, 17, 22),
			Raised = Color3.fromRGB(17, 24, 31),
			Border = Color3.fromRGB(72, 88, 101),
			Text = Color3.fromRGB(238, 244, 247),
			Muted = Color3.fromRGB(137, 153, 164),
			Dim = Color3.fromRGB(89, 104, 115),
			Danger = Color3.fromRGB(255, 91, 104),
			Warning = Color3.fromRGB(255, 190, 91),
			Healthy = Color3.fromRGB(77, 229, 174)
		},
		Objects = setmetatable({}, {__mode = 'k'})
	}

	local function create(class, parent, properties)
		local object = Instance.new(class)
		for property, value in properties or {} do object[property] = value end
		object.Parent = parent
		return object
	end

	local function corner(parent, radius)
		return create('UICorner', parent, {CornerRadius = UDim.new(0, radius or 4)})
	end

	local function stroke(parent, color, transparency, thickness)
		return create('UIStroke', parent, {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = color or api.Palette.Border,
			Transparency = transparency == nil and 0.72 or transparency,
			Thickness = thickness or 1
		})
	end

	function api:Accent(offset)
		local ok, color = pcall(function()
			return neon:GetThemeColor(offset or 0)
		end)
		return ok and typeof(color) == 'Color3' and color or Color3.fromRGB(0, 220, 220)
	end

	function api:IsMode(value)
		-- Accept the old mode name when loading r1 profiles.
		return value == 'Krs' or value == 'Neon'
	end

	function api:TextBounds(text, size, font)
		local ok, bounds = pcall(textService.GetTextSize, textService, tostring(text or ''), size or 12,
			font or Enum.Font.Gotham, Vector2.new(100000, 100000))
		return ok and bounds or Vector2.new(#tostring(text or '') * (size or 12) * 0.5, size or 12)
	end

	function api:Register(object, property, offset)
		if typeof(object) ~= 'Instance' then return object end
		self.Objects[object] = {Property = property or 'BackgroundColor3', Offset = offset or 0}
		pcall(function() object[property or 'BackgroundColor3'] = self:Accent(offset) end)
		return object
	end

	function api:Card(parent, options)
		options = options or {}
		local root = create('Frame', parent, {
			Name = options.Name or 'KrsCard',
			AnchorPoint = options.AnchorPoint or Vector2.zero,
			Position = options.Position or UDim2.new(),
			Size = options.Size or UDim2.fromOffset(180, 34),
			BackgroundColor3 = options.BackgroundColor or self.Palette.Surface,
			BackgroundTransparency = options.Transparency == nil and 0.12 or options.Transparency,
			BorderSizePixel = 0,
			ClipsDescendants = options.ClipsDescendants == true,
			Visible = options.Visible ~= false,
			ZIndex = options.ZIndex or 2
		})
		corner(root, options.Radius or 4)
		local outline = stroke(root, self.Palette.Border, options.BorderTransparency or 0.68, 1)
		local accent = create('Frame', root, {
			Name = 'Accent',
			BackgroundColor3 = self:Accent(options.Offset),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 5),
			Size = UDim2.new(0, 2, 1, -10),
			ZIndex = root.ZIndex + 2
		})
		corner(accent, 2)
		self:Register(accent, 'BackgroundColor3', options.Offset)

		local dot
		if options.Dot ~= false then
			dot = create('Frame', root, {
				Name = 'Status',
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = self:Accent((options.Offset or 0) + 0.04),
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(options.DotX or 12, options.DotY or math.floor((options.Height or 34) / 2)),
				Size = UDim2.fromOffset(options.DotSize or 5, options.DotSize or 5),
				ZIndex = root.ZIndex + 2
			})
			corner(dot, 99)
			self:Register(dot, 'BackgroundColor3', (options.Offset or 0) + 0.04)
		end

		return {Root = root, Accent = accent, Status = dot, Stroke = outline}
	end

	function api:Metric(label, caption, options)
		if typeof(label) ~= 'Instance' or not label:IsA('TextLabel') then return label end
		options = options or {}
		label.BackgroundColor3 = self.Palette.Surface
		label.BackgroundTransparency = options.Transparency == nil and 0.12 or options.Transparency
		label.BorderSizePixel = 0
		label.TextColor3 = self.Palette.Text
		label.TextSize = options.TextSize or 15
		label.TextXAlignment = options.TextXAlignment or Enum.TextXAlignment.Right
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
		corner(label, 4)
		stroke(label, self.Palette.Border, 0.70, 1)

		local accent = create('Frame', label, {
			Name = 'KrsAccent', BackgroundColor3 = self:Accent(options.Offset), BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 5), Size = UDim2.new(0, 2, 1, -10), ZIndex = label.ZIndex + 2
		})
		corner(accent, 2)
		self:Register(accent, 'BackgroundColor3', options.Offset)
		local captionLabel = create('TextLabel', label, {
			Name = 'KrsCaption', BackgroundTransparency = 1, Position = UDim2.fromOffset(11, 0),
			Size = UDim2.new(0.58, -11, 1, 0), Text = tostring(caption or ''):upper(),
			TextColor3 = self.Palette.Muted, TextSize = 9, FontFace = Font.fromEnum(Enum.Font.GothamMedium),
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = label.ZIndex + 2
		})
		local padding = create('UIPadding', label, {PaddingRight = UDim.new(0, 10)})
		return label, captionLabel, accent, padding
	end

	function api:Tag(parent, adornee, text, options)
		options = options or {}
		local size = options.TextSize or 12
		local bounds = self:TextBounds(text, size, Enum.Font.GothamMedium)
		local billboard = create('BillboardGui', parent, {
			Name = options.Name or 'KrsTag', Adornee = adornee, AlwaysOnTop = options.AlwaysOnTop ~= false,
			LightInfluence = 0, MaxDistance = options.MaxDistance or 1000,
			Size = UDim2.fromOffset(bounds.X + 27, math.max(22, bounds.Y + 9)),
			StudsOffsetWorldSpace = options.Offset3D or Vector3.new()
		})
		local card = self:Card(billboard, {
			Size = UDim2.fromScale(1, 1), Transparency = options.Transparency or 0.12,
			Radius = 4, Offset = options.Offset, Height = math.max(22, bounds.Y + 9)
		})
		local label = create('TextLabel', card.Root, {
			Name = 'Label', BackgroundTransparency = 1, Position = UDim2.fromOffset(21, 0),
			Size = UDim2.new(1, -27, 1, 0), FontFace = Font.fromEnum(Enum.Font.GothamMedium),
			Text = tostring(text or ''), TextColor3 = options.Color or self.Palette.Text,
			TextSize = size, TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center, RichText = options.RichText == true,
			ZIndex = card.Root.ZIndex + 2
		})
		return {Billboard = billboard, Root = card.Root, Accent = card.Accent, Status = card.Status, Stroke = card.Stroke, Label = label}
	end

	function api:HealthColor(health)
		health = math.clamp(tonumber(health) or 0, 0, 1)
		if health < 0.28 then return self.Palette.Danger end
		if health < 0.58 then return self.Palette.Warning end
		return self.Palette.Healthy
	end

	function api:ApplyColor(data, color)
		if type(data) ~= 'table' or typeof(color) ~= 'Color3' then return end
		for _, key in {'Accent', 'Status', 'Core', 'Main', 'Glow', 'Fill'} do
			local object = data[key]
			if typeof(object) == 'Instance' then
				pcall(function() object.BackgroundColor3 = color end)
				pcall(function() object.ImageColor3 = color end)
				pcall(function() object.Color = color end)
			elseif object then
				pcall(function() object.Color = color end)
			end
		end
	end

	local elapsed = 0
	local connection = runService.RenderStepped:Connect(function(dt)
		elapsed += dt
		if elapsed < 1 / 24 then return end
		elapsed = 0
		for object, data in self.Objects do
			if object and object.Parent then
				pcall(function() object[data.Property] = self:Accent(data.Offset) end)
			else
				self.Objects[object] = nil
			end
		end
	end)

	neon:Clean(function()
		connection:Disconnect()
		table.clear(api.Objects)
	end)
	neon.Libraries.krsrender = api
	return api
end
