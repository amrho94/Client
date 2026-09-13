-- Put the project files in neon/ before running this.
shared.NeonDeveloper=true
shared.NeonRefresh=false
local source=assert(readfile('neon/loader.lua'),'Missing neon/loader.lua')
return assert(loadstring(source,'@neon/loader.lua'))()
