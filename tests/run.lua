-- Run from the repository root: lua5.1 tests/run.lua
local M = dofile((arg[0]:match("^(.*)run%.lua$") or "./") .. "mock_wow.lua")
local T = { M = M }
local tests, failed = {}, 0
function T.test(name, fn) tests[#tests + 1] = { name = name, fn = fn } end
function T.eq(a, b, msg) if a ~= b then error((msg or "") .. " expected " .. tostring(b) .. ", got " .. tostring(a), 2) end end
function T.near(a, b, msg) if math.abs(a - b) > 1e-6 then error((msg or "") .. " expected " .. tostring(b) .. ", got " .. tostring(a), 2) end end
function T.ok(v, msg) if not v then error(msg or "expected true", 2) end end
_G.T = T
local dir = arg[0]:match("^(.*)run%.lua$") or "./"
for _, f in ipairs({ "test_core.lua", "test_ui.lua", "test_locale.lua", "test_meta.lua" }) do
  assert(loadfile(dir .. f))()
end
for _, t in ipairs(tests) do
  local ok, err = pcall(t.fn)
  if ok then io.write("ok   ", t.name, "\n") else failed = failed + 1; io.write("FAIL ", t.name, "\n     ", tostring(err), "\n") end
end
io.write(("\n%d tests, %d failed\n"):format(#tests, failed))
os.exit(failed == 0 and 0 or 1)
