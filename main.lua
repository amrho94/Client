if not game:IsLoaded() then game.Loaded:Wait() end
local previous=shared.Neon
if previous then pcall(function()previous:Uninject()end)end

local core
local rawLoadstring=loadstring
local function compile(source,name)
    local chunk,err=rawLoadstring(source,name)
    if not chunk then
        warn('[Neon] Compile failed: '..tostring(err))
        if core then core:CreateNotification('Neon','Failed to compile '..tostring(name)..': '..tostring(err),30,'alert')end
        error(err,2)
    end
    return chunk
end

local queue_on_teleport=queue_on_teleport or function()end
local isfile=isfile or function(file)local ok,value=pcall(readfile,file);return ok and value~=nil and value~=''end
local cloneref=cloneref or function(value)return value end
local Players=cloneref(game:GetService('Players'))

local runtime=shared.NeonRuntime
if not runtime then
    runtime=assert(compile(readfile('neon/libraries/runtime.lua'),'@neon/libraries/runtime.lua'))()
    shared.NeonRuntime=runtime
end
local read=runtime.Read

local loading=compile(read('neon/guis/loading.lua'),'@neon/guis/loading.lua')()
shared.NeonLoading=loading
loading:SetLoadingProgress(.07,'Initializing runtime')

local preload={'neon/guis/neon.lua','neon/libraries/neon-api.lua'}
if not shared.NeonIndependent then preload[#preload+1]='neon/games/universal.lua'end
runtime.Prefetch(preload)
loading:SetLoadingProgress(.25,'Constructing Neon shell')

core=compile(read('neon/guis/neon.lua'),'@neon/guis/neon.lua')()
assert(type(core)=='table'and core.Name=='Neon','Neon UI did not return a valid core.')
assert(core.Build=='neon-krs-r1','Stale Neon core detected: '..tostring(core.Build))
shared.Neon=core
shared.NeonBuild=core.Build

local apiFactory=compile(read('neon/libraries/neon-api.lua'),'@neon/libraries/neon-api.lua')()
core.API=apiFactory(core)
shared.NeonAPI=core.API

loading:SetTheme(core.Libraries.uipallet,core.GUIColor)
core.HideLoadingScreen=function(_,immediate)loading:HideLoadingScreen(immediate)end
core:Clean(function()loading:HideLoadingScreen(true)end)

local function finish()
    core.Init=nil
    loading:SetLoadingProgress(.82,'Restoring Neon profile')

    if not core.Libraries.additions then
        local ok,err=pcall(function()
            local init=compile(read('neon/libraries/additions.lua'),'@neon/libraries/additions.lua')()
            init(core)
        end)
        if not ok then core:CreateNotification('Extensions',tostring(err),12,'alert')end
    end

    core:Load()
    loading:SetLoadingProgress(1,'Neon ready')
    core:HideLoadingScreen()

    task.spawn(function()
        repeat
            task.wait(30)
            if shared.Neon~=core or not core.Loaded then break end
            core:Save()
        until not core.Loaded
    end)

    local queued=false
    core:Clean(Players.LocalPlayer.OnTeleport:Connect(function()
        if queued or shared.NeonIndependent then return end
        queued=true;core:Save()
        local teleportScript=[[
            shared.NeonReload=true
            local ok,source=pcall(readfile,'neon/loader.lua')
            if ok then
                assert(loadstring(source,'@neon/loader.lua'))()
            else
                local repo=shared.NeonRepository or 'expectedbadthings/TenacityForRoblox'
                local branch=shared.NeonBranch or 'main'
                assert(loadstring(game:HttpGet(('https://raw.githubusercontent.com/%s/%s/loader.lua'):format(repo,branch),true),'@Neon/loader.lua'))()
            end
        ]]
        if shared.NeonDeveloper then teleportScript='shared.NeonDeveloper=true\n'..teleportScript end
        if shared.NeonCustomProfile then teleportScript='shared.NeonCustomProfile='..string.format('%q',shared.NeonCustomProfile)..'\n'..teleportScript end
        queue_on_teleport(teleportScript)
    end))

    if not shared.NeonReload and core.Settings.GUI.Options['GUI bind indicator'].Enabled then
        local bind=core.GUIBind and table.concat(core.GUIBind.Keys,' + '):upper() or 'RSHIFT'
        core:CreateNotification('Neon','Ready — '..bind..' opens the workspace.',5)
    end
end

loading:SetLoadingProgress(.48,'Registering modules')
if not shared.NeonIndependent then
    compile(read('neon/games/universal.lua'),'@neon/games/universal.lua')()
    local gamePath='neon/games/'..game.PlaceId..'.lua'
    if not shared.NeonDeveloper or isfile(gamePath) then
        local source=read(gamePath,nil,true)
        if source then compile(source,'@'..gamePath)(...) end
    end
    finish()
else
    core.Init=finish
    return core
end
