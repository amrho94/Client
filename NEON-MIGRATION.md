# Upgrading to Neon

## UI and API

The client loads `guis/neon.lua` and `libraries/neon-api.lua`. The old Tenacity UI is no longer loaded.

## Module names

Some IDs keep their old names because profiles and other modules use them. Their menu names are set separately:

| ID | Menu name |
| --- | --- |
| `Speed` | Velocity |
| `Killaura` | Aura |
| `Chams` | Player Glow |
| `NameTags` | Labels |

## Profiles

Profiles save to `neon/profiles/`. If a Neon profile is missing, the core tries the old profile path. Later saves go to the Neon folder.

## Universal and Frontlines

Both game files use Neon API v3. Their HUD styling is shared through `libraries/krs-render.lua`.

Render modes named `Neon` in r1 profiles load as `Krs`. Module IDs stay the same.

This build has not been tested in a Roblox executor.
