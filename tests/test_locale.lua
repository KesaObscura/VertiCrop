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

-- The settings window is 330 wide: every text in it fits on one line in every language.
-- Width budget in "Latin letters"; a CJK or Hangul character counts as two.
local function width(s)
  local n = 0
  for ch in s:gmatch("[%z\1-\127\192-\255][\128-\191]*") do
    n = n + ((#ch >= 3) and 2 or 1)
  end
  return n
end

test("every text in the settings window fits on one line in every language", function()
  local all = strings()
  local budget = {
    subtitle = 45, optEnabled = 34, optRec = 34, optAspect = 34, aspect9x16 = 34, aspect4x5 = 34,
    aspect1x1 = 34, optZones = 34, platAll = 30, optBox = 34, zonesNote = 30, optGrid = 34,
    optLabels = 34, optAlpha = 36, cropUnknown = 40, btnReset = 16,
  }
  for lang, t in pairs(all) do
    for key, max in pairs(budget) do
      local text = t[key]:gsub("%%d", "100")
      ok(width(text) <= max, lang .. "." .. key .. " is " .. width(text) .. " wide, budget " .. max)
    end
    -- crop values: two fixed lines, numbers of a 3440x1440 screen
    local crop = t.cropInfo:format(1152, 1440, 1144, 1144)
    for line in crop:gmatch("[^\n]+") do
      ok(width(line) <= 36, lang .. ".cropInfo line '" .. line .. "' is " .. width(line) .. " wide")
    end
  end
end)
