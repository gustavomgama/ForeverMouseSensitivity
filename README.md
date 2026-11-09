# Forever Mouse Sensitivity

A tiny World of Warcraft: Forever addon to set your mouse/camera turn speed with decimal precision.

## Features

- Slider from **0.1 to 100** in **0.01 steps**
- Manual numeric entry (type `31.68` and press Enter or Apply)
- Reset button back to `1.00`
- Slash command support
- Saved automatically per account (`ForeverMouseSensitivityDB`)
- Applies on login/reload; panel shows applied/locked status
- In-game settings panel under **Options → AddOns → Forever Mouse Sensitivity**
- Addon compartment tooltip shows current sensitivity

## Slash commands

| Command | What it does |
|---|---|
| `/sens` | Open the settings panel |
| `/sens 31.68` | Set sensitivity to 31.68 |
| `/sens reset` | Reset to 1.00 |
| `/sensitivity` | Alias for `/sens` |

## What it changes

The addon sets these CVars:

- `cameraYawMoveSpeed`
- `cameraPitchMoveSpeed`

If the game is in combat or the CVar is locked, it prints a warning instead of silently failing.

## Install

Copy the `ForeverMouseSensitivity` folder into:

```
World of Warcraft\_forever_\Interface\AddOns\
```

Then enable it in the AddOns list.

## Notes

- Interface: `16001` (WoW: Forever 1.60.1)
- Values are clamped to 0.1–100.
- Settings persist across characters (account-wide SavedVariables).
