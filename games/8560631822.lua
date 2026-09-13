local neon = assert(shared.Neon, 'Neon core is unavailable')
local runtime = assert(shared.NeonRuntime, 'Neon runtime is unavailable')

local path = 'neon/games/6872274481.lua'
local source = runtime.Read(path)
local loader, err = loadstring(source, '@'..path)
if not loader then
	neon:Notify('Neon', 'Failed to load BedWars support: '..tostring(err), 30, 'alert')
	error(err, 0)
end

return loader(...)
