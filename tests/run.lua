-- Run all ForeverMouseSensitivity out-of-game tests.
-- Usage (from addon root): lua tests/run.lua

local files = {
  "tests/test_wiring.lua",
}

local failed = 0
for _, f in ipairs(files) do
  local ok, err = xpcall(function() dofile(f) end, debug.traceback)
  if not ok then
    failed = failed + 1
    io.stderr:write("\nFAIL: " .. f .. "\n" .. tostring(err) .. "\n")
  end
end

if failed > 0 then
  io.stderr:write("\n" .. failed .. " test file(s) failed\n")
  os.exit(1)
end
print("all tests passed")
