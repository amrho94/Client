-- Local paths start with neon/; repository paths do not.
local runtime = {
    Name = 'NeonRuntime',
    Repo = shared.NeonRepository or 'amrho94/Client',
    Branch = shared.NeonBranch or 'main',
    Root = 'neon/',
    Stats = {Downloads = 0, DiskHits = 0, MemoryHits = 0}
}

local sources, pending, missing = {}, {}, {}
local refresh = shared.NeonRefresh == true and not shared.NeonDeveloper

local function remoteBase()
    return 'https://raw.githubusercontent.com/'..runtime.Repo..'/'..runtime.Branch..'/'
end

local function remotePath(path)
    assert(type(path) == 'string' and path:sub(1, #runtime.Root) == runtime.Root, 'Invalid Neon runtime path')
    assert(not path:find('..', 1, true), 'Unsafe Neon runtime path')
    return path:sub(#runtime.Root + 1)
end

local function valid(data, path)
    if type(data) ~= 'string' or #data == 0 then return false end
    if path:match('%.lua$') or path:match('%.json$') or path:match('%.txt$') or path:match('%.md$') then
        local head = data:sub(1, 512):lower()
        if head:find('404: not found', 1, true) or head:find('<!doctype html', 1, true)
            or head:find('<html', 1, true) or head:find('repository not found', 1, true) then return false end
    end
    if path:match('%.lua$') then return loadstring(data, '@'..path) ~= nil end
    return true
end

function runtime.Read(path, callback, optional)
    remotePath(path)
    while pending[path] do task.wait() end

    local data = sources[path]
    if data then
        runtime.Stats.MemoryHits += 1
    elseif missing[path] then
        if optional then return nil end
        error('Missing Neon runtime file: '..path, 2)
    else
        pending[path] = true
        local ok, result = pcall(function()
            local function readDisk()
                local diskOK, cached = pcall(readfile, path)
                if diskOK and valid(cached, path) then
                    runtime.Stats.DiskHits += 1
                    return cached
                end
            end

            if not refresh then
                local cached = readDisk()
                if cached then return cached end
            end

            local fetched, body = pcall(game.HttpGet, game, remoteBase()..remotePath(path), true)
            runtime.Stats.Downloads += 1
            if fetched and valid(body, path) then
                pcall(writefile, path, body)
                return body
            end

            -- A refresh should never make a working local install unusable just because
            -- GitHub/executor HTTP failed. Use the last valid disk copy as stale fallback.
            local cached = readDisk()
            if cached then return cached end

            -- Optional files (such as games/<PlaceId>.lua) are genuinely optional.
            -- Executors report missing raw GitHub files inconsistently: false+blank,
            -- thrown 404s, or a literal "404: Not Found" body. Treat all as absent.
            if optional then
                missing[path] = true
                return nil
            end

            error('Failed to fetch '..path..': '..tostring(body), 0)
        end)
        pending[path] = nil
        if not ok then error(result, 2) end
        data = result
        if data ~= nil then sources[path] = data end
    end

    if data == nil then return nil end
    return callback and callback(path) or data
end

function runtime.Asset(relativePath)
    local path = runtime.Root..'assets/'..relativePath
    if not getcustomasset then return '' end
    local ok, result = pcall(runtime.Read, path, getcustomasset)
    return ok and result or ''
end

function runtime.Prefetch(paths)
    local nextIndex, active, errors = 1, math.min(4, #paths), {}
    for _ = 1, active do
        task.spawn(function()
            while nextIndex <= #paths do
                local index = nextIndex; nextIndex += 1
                local ok, err = pcall(runtime.Read, paths[index])
                if not ok then errors[#errors + 1] = tostring(err) end
            end
            active -= 1
        end)
    end
    while active > 0 do task.wait() end
    if #errors > 0 then error(table.concat(errors, '\n'), 2) end
end

function runtime.ClearMemoryCache()
    table.clear(sources); table.clear(missing)
end

return runtime
