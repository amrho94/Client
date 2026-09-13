-- Set NeonRepository and NeonBranch before loading to use a fork.
if shared.NeonBooting then return end
shared.NeonBooting = true
shared.NeonRepository = shared.NeonRepository or 'amrho94/Client'

local previous = shared.Neon
local hotReload = shared.NeonSessionBooted == true or previous ~= nil
shared.NeonSessionBooted = true

if hotReload then
    shared.NeonReload = true
    if not shared.NeonDeveloper then
        shared.NeonRefresh = true
    end
end
local function boot()
    assert(type(readfile)=='function' and type(writefile)=='function' and type(makefolder)=='function',
        'Neon requires executor filesystem support.')

    for _, path in ipairs({
        'neon', 'neon/assets', 'neon/assets/new', 'neon/games', 'neon/guis',
        'neon/libraries', 'neon/profiles', 'neon/additions', 'neon/additions/configs'
    }) do pcall(makefolder, path) end

    local cacheRevision='neon-krs-r1-amrho94-client'
    local marker='neon/profiles/cache-revision.txt'
    local markerOK,current=pcall(readfile,marker)
    local refreshForRevision=not markerOK or current~=cacheRevision
    if refreshForRevision and not shared.NeonDeveloper then shared.NeonRefresh=true end

    local runtimePath='neon/libraries/runtime.lua'
    local cached, source=pcall(readfile,runtimePath)
    local chunk=cached and type(source)=='string' and loadstring(source,'@'..runtimePath)
    if not chunk then
        local repo=shared.NeonRepository or 'amrho94/Client'
        local branch=shared.NeonBranch or 'main'
        source=game:HttpGet(('https://raw.githubusercontent.com/%s/%s/libraries/runtime.lua'):format(repo,branch),true)
        chunk=assert(loadstring(source,'@'..runtimePath))
        writefile(runtimePath,source)
    end

    local runtime=chunk()
    shared.NeonRuntime=runtime
    pcall(writefile,'neon/profiles/commit.txt',runtime.Branch or 'main')

    if not game:IsLoaded() then game.Loaded:Wait() end
    assert(loadstring(runtime.Read('neon/main.lua'),'@neon/main.lua'))()
    if refreshForRevision then pcall(writefile,marker,cacheRevision) end
end

local ok, err=xpcall(boot,function(message)
    local trace='';pcall(function()trace=debug.traceback(nil,2)end)
    return tostring(message)..(trace~=''and('\n'..trace)or'')
end)

shared.NeonBooting=nil
shared.NeonRefresh=nil
if not ok then
    if shared.NeonLoading then pcall(shared.NeonLoading.HideLoadingScreen,shared.NeonLoading,true) end
    local current=shared.Neon
    if current and current~=previous then pcall(function()current:Uninject()end)end
    error('[Neon] Startup failed: '..tostring(err),0)
end
