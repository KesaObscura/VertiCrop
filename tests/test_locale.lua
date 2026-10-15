local M, test, eq, ok = T.M, T.test, T.eq, T.ok

local function strings()
  local ns = M.load()
  local i = 1
  while true do
    local name, value = debug.getupvalue(getmetatable(ns.L).__index, i)
    if not name then break end
    if name == "strings" then return value end
    i = i + 1
  end
end

local function placeholders(s)
  local out = {}
  for p in s:gmatch("%%[%d%.]*[sdf%%]") do out[#out + 1] = p end
  return table.concat(out, " ")
end

test("every language has exactly the English keys and placeholders", function()
  local all = strings()
  local en = all.enUS
  local n = 0
  for lang, t in pairs(all) do
    n = n + 1
    for k, v in pairs(en) do
      ok(rawget(t, k), lang .. " misses " .. k)
      eq(placeholders(t[k]), placeholders(v), lang .. "." .. k .. " placeholders")
    end
    for k in pairs(t) do ok(en[k], lang .. " has extra key " .. k) end
  end
  eq(n, 9, "languages")
end)

test("every key used in the code exists, and every key is used", function()
  local en = strings().enUS
  local code = M.read("Core.lua") .. M.read("Options.lua")
  for k in code:gmatch("L%.([%a_][%w_]*)") do ok(en[k], "missing key " .. k) end
  for k in pairs(en) do
    local used = code:find("L%." .. k .. "[^%w_]") or code:find('"' .. k .. '"')
    ok(used, "unused key " .. k)
  end
end)

test("the game language picks the texts, unknown ones fall back to English", function()
  eq(M.load({ locale = "ruRU" }).L.optRec, "Режим записи")
  eq(M.load({ locale = "esMX" }).L.optRec, "Modo grabación")
  eq(M.load({ locale = "itIT" }).L.optRec, "Recording mode")
end)
