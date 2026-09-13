# Neon API v3

Use `shared.NeonAPI` to register modules. The core is available through `shared.Neon`.

## Register a module

```lua
local Neon = shared.NeonAPI

local Velocity = Neon:Module('Motion', {
    Name = 'ExampleVelocity',
    DisplayName = 'Velocity+',
    Tooltip = 'Example Neon module.',
    Function = function(enabled)
        print('enabled:', enabled)
    end
})
```

`Name` is the module ID used by profiles. Change `DisplayName` to rename a module in the menu without breaking its saved settings.

## Settings

```lua
local AutoJump = Velocity:Setting({
    Type = 'toggle',
    Name = 'Auto Jump',
    Default = true
})

local Speed = Velocity:Setting({
    Type = 'slider',
    Name = 'Speed',
    Min = 1,
    Max = 50,
    Default = 20
})

local Mode = Velocity:Setting({
    Type = 'dropdown',
    Name = 'Mode',
    List = {'Normal', 'Pulse'},
    Default = 'Normal'
})
```

Supported types: `toggle`, `slider`, `range`, `dropdown`, `multidropdown`, `color`, `text`, `list`, `bind`, `button`, `font`, and `targets`.

Each module has `module.Bind` and a keybind setting. For a HUD module, pass `Size = UDim2...` when registering and draw into `module.Children`. The core handles showing, dragging and saving its position.

## API object

```lua
local API = shared.NeonAPI

local module = API.Modules:Register('Vision', {...})
API.Modules:Get('ESP')
API.Modules:Remove('Example')
API.Modules:All()

API:Notify('Neon', 'Hello', 3, 'info')
API:Theme('Digital Horizons')

API.UI:Open()
API.UI:Close()
API.UI:Toggle()
API.UI:IsOpen()
API.UI:Overlay({...})

API.Profiles:Save('default')
API.Profiles:Load('default')
API.Profiles:Switch('testing')
```

## Categories

- `Offense` — combat.
- `Motion` — movement.
- `Player` — player and inventory settings.
- `World` — world settings.
- `Vision` — visuals and HUDs.
- `Utility` — other tools.
- `Scripts` — extra scripts.
- `Developer` — debugging.

Use the category names exactly as listed.
