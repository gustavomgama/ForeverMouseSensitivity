-- Wiring/state tests for ForeverMouseSensitivity. Run: lua tests/test_wiring.lua
-- Covers mocked WoW wiring only (no real frames/CVars/combat). See tests/README.md.

if not unpack and table.unpack then unpack = table.unpack end

local function ok(cond, msg)
  if not cond then error(msg or "assertion failed", 2) end
end

local function loadAddon(mock, opts)
  mock.reset(opts)
  local ns = {}
  local chunk = assert(loadfile("ForeverMouseSensitivity.lua"))
  chunk("ForeverMouseSensitivity", ns)
  return ns
end

local function addonLoaded(mock, ns, addonName)
  addonName = addonName or "ForeverMouseSensitivity"
  mock.fireEvent("ADDON_LOADED", addonName)
  return ns
end

local mock = dofile("tests/wow_mock.lua")

-- 1) ADDON_LOADED restores defaults and applies CVars
do
  local ns = loadAddon(mock, { db = nil })
  addonLoaded(mock, ns)
  ok(ns.db.sensitivity == 1.0, "default sensitivity")
  ok(mock.cvars.cameraYawMoveSpeed == "1.0", "yaw applied")
  ok(mock.cvars.cameraPitchMoveSpeed == "1.0", "pitch applied")
  ok(ns.applyState == "applied", "applied state")
  ok(_G.ForeverMouseSensitivityDB == ns.db, "saved var bound")
  ok(mock.settingsRegistered and mock.settingsOpened == nil, "settings registered")
end

-- 2) ADDON_LOADED normalizes saved value
do
  local ns = loadAddon(mock, { db = { sensitivity = 999 } })
  addonLoaded(mock, ns)
  ok(ns.db.sensitivity == 100, "clamped to max")
  ok(mock.cvars.cameraYawMoveSpeed == "100.0" or mock.cvars.cameraYawMoveSpeed == "100", "max applied")
end

-- 3) Slash sets value, rounds, applies
do
  local ns = loadAddon(mock, { db = { sensitivity = 1.0 } })
  addonLoaded(mock, ns)
  SlashCmdList.FOREVERMOUSESENSITIVITY("31.678")
  ok(ns.db.sensitivity == 31.68, "rounded to step")
  ok(mock.cvars.cameraYawMoveSpeed == "31.68", "cvar string")
  ok(ns.applyState == "applied", "state applied")
  ok(mock.findLastPrint("set to 31.68"), "slash reports success")
end

-- 4) Slash reset
do
  local ns = loadAddon(mock, { db = { sensitivity = 2.5 } })
  addonLoaded(mock, ns)
  SlashCmdList.FOREVERMOUSESENSITIVITY("reset")
  ok(ns.db.sensitivity == 1.0, "reset default")
  ok(mock.cvars.cameraYawMoveSpeed == "1.0", "reset applied")
end

-- 5) Invalid input does not overwrite DB
do
  local ns = loadAddon(mock, { db = { sensitivity = 2.5 } })
  addonLoaded(mock, ns)
  local beforeYaw = mock.cvars.cameraYawMoveSpeed
  SlashCmdList.FOREVERMOUSESENSITIVITY("abc")
  ok(ns.db.sensitivity == 2.5, "db unchanged")
  ok(mock.cvars.cameraYawMoveSpeed == beforeYaw, "cvars unchanged")
  ok(mock.findLastPrint("must be between"), "error reported")
end

-- 6) CVar apply failure (combat/locked mock) saves value but marks failed
do
  local ns = loadAddon(mock, { db = { sensitivity = 1.0 }, cvarLocked = true })
  addonLoaded(mock, ns)
  ok(ns.db.sensitivity == 1.0, "value still saved/normalized")
  ok(ns.applyState == "failed", "failed state")
  ok(ns.statusText and ns.statusText.text:match("Could not apply"), "status reports failure")
end

-- 7) Slash opens settings path
do
  local ns = loadAddon(mock, { db = { sensitivity = 1.0 } })
  addonLoaded(mock, ns)
  SlashCmdList.FOREVERMOUSESENSITIVITY("")
  ok(mock.settingsOpened == 42, "opens registered category")
end

-- 8) Compartment globals exist
do
  local ns = loadAddon(mock)
  addonLoaded(mock, ns)
  ok(type(ForeverMouseSensitivity_OnAddonCompartmentClick) == "function", "compartment click")
  ok(type(ForeverMouseSensitivity_OnAddonCompartmentEnter) == "function", "compartment enter")
  ok(type(ForeverMouseSensitivity_OnAddonCompartmentLeave) == "function", "compartment leave")
end

print("ok - test_wiring (" .. 8 .. " cases)")
