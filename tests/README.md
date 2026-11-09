# Tests (out of game)

Mocked wiring/state tests for ForeverMouseSensitivity. They do **not** run in the WoW client.

## Run

From the addon root:

```sh
lua tests/run.lua
npx --yes luaparse ForeverMouseSensitivity.lua
```

## Covered

- `ADDON_LOADED`: SavedVariables restore/defaulting/normalization, CVar apply (mocked), settings registration.
- State transitions via `applySensitivity` (observable): slash set/reset/invalid, apply success/failure state, CVar/print/status effects.
- Slash/settings-open and compartment globals.

## Not covered (in-game only)

- Real frame rendering/templates (`OptionsSliderTemplate`), slider/edit box behavior details.
- Actual `C_CVar` persistence/semantics, combat lockdown/protected restrictions beyond mock return values.
- `Settings`/Interface Options UI behavior on the target client.

## Files

- `wow_mock.lua` — minimal WoW global stubs with observable state.
- `test_wiring.lua` — addon load + event/slash/state assertions.
- `run.lua` — runs all test files.
