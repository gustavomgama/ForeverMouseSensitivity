-- Wiring/state tests for ForeverMouseSensitivity. Run: lua tests/test_wiring.lua
-- Covers mocked WoW wiring only (no real frames/CVars/combat).

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

-- 1) ADDON_LOADED: no saved -> defaults to 90/45
do
  local ns = loadAddon(mock, { db = nil, cvars = { cameraYawMoveSpeed = "2.50", cameraPitchMoveSpeed = "2.50" } })
  addonLoaded(mock, ns)
  ok(ns.db.sensitivity == 90.00, "default yaw 90")
  ok(mock.cvars.cameraYawMoveSpeed == "90.00", "yaw default applied")
  ok(mock.cvars.cameraPitchMoveSpeed == "45.00", "pitch default applied")
  ok(ns.applyState == "applied", "applied state")
  ok(#mock.prints == 1, "single chat line on login")
  ok(mock.prints[1]:match("loaded: 90.00"), "chat reports loaded value")
  ok(ns.statusText and ns.statusText.text == "", "no load status in UI")
end

-- 2) ADDON_LOADED: invalid saved value falls back to 90/45
do
  local ns = loadAddon(mock, { db = { sensitivity = 999 } })
  addonLoaded(mock, ns)
  ok(ns.db.sensitivity == 90.00, "fallback default yaw 90")
  ok(mock.cvars.cameraYawMoveSpeed == "90.00", "yaw fallback")
  ok(mock.cvars.cameraPitchMoveSpeed == "45.00", "pitch fallback")
end

-- 3) Slash sets value (2dp), yaw=v pitch=v/2, no chat, allows 0
do
  local ns = loadAddon(mock, { db = { sensitivity = 90.0 } })
  addonLoaded(mock, ns)
  local chatCount = #mock.prints
  SlashCmdList.FOREVERMOUSESENSITIVITY("0")
  ok(ns.db.sensitivity == 0.00, "zero allowed")
  ok(mock.cvars.cameraYawMoveSpeed == "0.00", "zero yaw")
  ok(mock.cvars.cameraPitchMoveSpeed == "0.00", "zero pitch")
  SlashCmdList.FOREVERMOUSESENSITIVITY("31.678")
  ok(ns.db.sensitivity == 31.68, "stored as 2dp number")
  ok(mock.cvars.cameraYawMoveSpeed == "31.68", "yaw 2dp")
  ok(mock.cvars.cameraPitchMoveSpeed == "15.84", "pitch half 2dp")
  ok(#mock.prints == chatCount, "no chat on slash apply")
  ok(ns.statusText and ns.statusText.text == "", "no success text")
  ok(mock.findEditBox().text == "31.68", "box shows 2dp value")
end

-- 4) Slash reset uses defaults 90/45
do
  local ns = loadAddon(mock, { db = { sensitivity = 2.5 } })
  addonLoaded(mock, ns)
  local chatCount = #mock.prints
  SlashCmdList.FOREVERMOUSESENSITIVITY("reset")
  ok(ns.db.sensitivity == 90.00, "reset default yaw")
  ok(mock.cvars.cameraYawMoveSpeed == "90.00", "reset yaw")
  ok(mock.cvars.cameraPitchMoveSpeed == "45.00", "reset pitch")
  ok(#mock.prints == chatCount, "no chat on reset")
end

-- 5) Invalid input does not overwrite DB, UI error, no chat
do
  local ns = loadAddon(mock, { db = { sensitivity = 2.5 } })
  addonLoaded(mock, ns)
  local beforeYaw = mock.cvars.cameraYawMoveSpeed
  local chatCount = #mock.prints
  SlashCmdList.FOREVERMOUSESENSITIVITY("abc")
  ok(ns.db.sensitivity == 2.5, "db unchanged")
  ok(mock.cvars.cameraYawMoveSpeed == beforeYaw, "cvars unchanged")
  ok(ns.statusText and ns.statusText.text:match("between 0.00 and 100.00"), "ui error")
  ok(#mock.prints == chatCount, "no chat on invalid")
end

-- 6) CVar apply failure saves value but marks failed in UI
do
  local ns = loadAddon(mock, { db = { sensitivity = 1.0 }, cvarLocked = true })
  addonLoaded(mock, ns)
  ok(ns.db.sensitivity == 1.0, "value still saved/normalized")
  ok(ns.applyState == "failed", "failed state")
  ok(mock.prints[1]:match("could not apply"), "login chat reports failure")
  ok(ns.statusText and ns.statusText.text == "", "no load status in UI")
end

-- 7) Slash opens settings path
do
  local ns = loadAddon(mock, { db = { sensitivity = 1.0 } })
  addonLoaded(mock, ns)
  SlashCmdList.FOREVERMOUSESENSITIVITY("")
  ok(mock.settingsOpened == 42, "opens registered category")
end

-- 8) Compartment globals exist and aliases kept
do
  local ns = loadAddon(mock)
  addonLoaded(mock, ns)
  ok(type(ForeverMouseSensitivity_OnAddonCompartmentClick) == "function", "compartment click")
  ok(type(ForeverMouseSensitivity_OnAddonCompartmentEnter) == "function", "compartment enter")
  ok(type(ForeverMouseSensitivity_OnAddonCompartmentLeave) == "function", "compartment leave")
  ok(SLASH_FOREVERMOUSESENSITIVITY1 == "/sens", "slash 1")
  ok(SLASH_FOREVERMOUSESENSITIVITY2 == "/sensitivity", "slash 2")
end

-- 9) Step buttons apply increments and keep the box in 2dp form
do
  local ns = loadAddon(mock, { db = { sensitivity = 90.0 } })
  addonLoaded(mock, ns)
  local box = mock.findEditBox()
  ok(box and box.text == "90.00", "box shows current value")
  mock.findButton("+0.10"):Click()
  ok(ns.db.sensitivity == 90.10, "plus 0.10")
  ok(mock.cvars.cameraYawMoveSpeed == "90.10", "step applied")
  ok(box.text == "90.10", "box updated")
  mock.findButton("-1"):Click()
  ok(ns.db.sensitivity == 89.10, "minus 1")
  ok(ns.statusText.text == "", "no success text")
end

-- 10) Apply shows the green check texture
do
  local ns = loadAddon(mock, { db = { sensitivity = 90.0 } })
  addonLoaded(mock, ns)
  local check = mock.findCheckTexture()
  ok(check and check.shown == false, "check hidden before apply")
  mock.findButton("Apply"):Click()
  ok(check.shown == true, "check shown after apply")
end

print("ok - test_wiring (" .. 10 .. " cases)")
