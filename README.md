# Neon

Roblox client based on TenacityForRoblox, with a Krs-inspired UI. Written in Luau.

## Runtime

```lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/amrho94/Client/main/loader.lua', true))()
```

The loader uses the repository shown above. Set `shared.NeonRepository` and `shared.NeonBranch` before loading to use your own fork. The ZIP changes need to be uploaded there before the remote loader can use them.

For local use, put the contents of `Neon-client/` in your executor's `neon/` folder and run `launch-local.lua`. Profiles and cached files are stored under `neon/`.

## Files

- `loader.lua` — starts the client.
- `main.lua` — loads the UI and game modules.
- `guis/loading.lua` — loading screen.
- `guis/neon.lua` — UI, settings, profiles and module controls.
- `libraries/neon-api.lua` — public API v3.
- `libraries/krs-render.lua` — shared HUD styling.
- `libraries/runtime.lua` — downloads and caches files.
- `games/universal.lua` — modules shared across games.
- `games/<place>.lua` — game-specific modules.
- `libraries/additions.lua` — bundled extensions.

## Categories

`Offense`, `Motion`, `Player`, `World`, `Vision`, `Utility`, `Scripts`, `Developer`

Use these names when registering modules. See `API.md` for examples and `NEON-MIGRATION.md` for profile compatibility notes.

## Development flags

- `shared.NeonRefresh = true` — force a source refresh.
- `shared.NeonDeveloper = true` — use local cached files without forced refresh.
- `shared.NeonIndependent = true` — load the shell without game modules.
- `shared.NeonRepository = "owner/repo"` — override the remote repository.
- `shared.NeonBranch = "branch"` — override the remote branch.
