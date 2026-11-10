<img width="872" height="463" alt="Captura de tela 2026-11-10 195102" src="https://github.com/user-attachments/assets/77db273c-f8fd-4f57-9c45-53dd7ca358a7" />

# Forever Mouse Sensitivity

A tiny World of Warcraft: Forever addon to set your mouse/camera turn speed with decimal precision.

## Features

- Slider from **0.00 to 100.00**
- Single value box that both displays and accepts the value, always shown as `X.XX`
- Step buttons: `+0.01` `+0.10` `+1` and `-0.01` `-0.10` `-1`
- Apply / Enter sends the value, Reset returns to the Blizzard default (`90.00`)
- A green check mark flashes next to **Apply** when the value was applied![Uploading Captura de tela 2026-11-10 195102.png…]()

- Errors (out of range, locked CVar) are reported inside the panel, never in chat
- Saved automatically per account (`ForeverMouseSensitivityDB`)
- Applied on login and reload; one chat line reports the loaded value
- In-game settings panel under **Options → AddOns → Forever Mouse Sensitivity**
- Addon compartment tooltip shows current sensitivity

## Slash commands

| Command | What it does |
|---|---|
| `/sens` | Open the settings panel |
| `/sens 31.68` | Set sensitivity to 31.68 |
| `/sens reset` | Reset to the default (90.00) |
| `/sensitivity` | Alias for `/sens` |

## What it changes

The addon sets these CVars, always written with two decimals:

- `cameraYawMoveSpeed` — the value you enter
- `cameraPitchMoveSpeed` — the same value scaled by `45/90`

So the Blizzard defaults (`90` yaw / `45` pitch) are produced by entering `90.00`.

If the game is in combat or the CVar is locked, the value is still saved and the panel shows a warning.

## Install

Copy the `ForeverMouseSensitivity` folder into:

```
World of Warcraft\_forever_\Interface\AddOns\
```

Then enable it in the AddOns list.

## Notes

- Interface: `16001` (WoW: Forever 1.60.1)
- Accepted range: `0.00`–`100.00`; anything else is rejected with a panel message.
- Settings persist across characters (account-wide SavedVariables).
- Tests: `lua tests/run.lua` (mocked WoW API, no client required).
