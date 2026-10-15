local M, test, eq, ok = T.M, T.test, T.eq, T.ok

local function open(opts)
  local ns = M.load(opts)
  ns.ToggleOptions(true)
  return ns, VertiCropOptions
end

local function controls(kind)
  local out = {}
  for _, o in ipairs(M.all) do
    if o.kind == kind and o.parent and (o.parent == VertiCropOptions or o.parent.parent == VertiCropOptions) then
      out[#out + 1] = o
    end
  end
  return out
end

local function find(kind, key, value)
  for _, cb in ipairs(controls(kind)) do
    if cb.key == key and (value == nil or cb.value == value) then return cb end
  end
end

test("every control in the window has a tooltip", function()
  open()
  local n = 0
  for _, o in ipairs(M.all) do
    if (o.kind == "CheckButton" or o.kind == "Button" or o.kind == "Slider" or o.mouse)
      and o.parent == VertiCropOptions then
      n = n + 1
      ok(o.scripts.OnEnter, o.kind .. " " .. tostring(o.key or o.text) .. " has no tooltip")
      o.scripts.OnEnter(o)
      ok(GameTooltip.text and GameTooltip.text ~= "", "tooltip title")
    end
  end
  ok(n >= 16, "controls found: " .. n)
end)

test("checkboxes show and change their setting", function()
  local ns = open()
  local grid = find("CheckButton", "grid")
  eq(grid:GetChecked(), true)
  M.click(grid)
  eq(ns.db.grid, false)
  ns.Set("grid", true)
  eq(grid:GetChecked(), true, "window follows changes from slash commands")
end)

test("format and platform radios", function()
  local ns = open()
  local tiktok = find("CheckButton", "platform", "tiktok")
  M.click(tiktok)
  eq(ns.db.platform, "tiktok")
  eq(find("CheckButton", "platform", "all"):GetChecked(), false)
  M.click(find("CheckButton", "aspect", "1x1"))
  eq(ns.db.aspect, "1x1")
  ok(not tiktok:IsEnabled(), "platforms greyed out without 9:16")
  M.click(tiktok)
  eq(ns.db.platform, "tiktok", "a greyed out radio does nothing")
  M.click(find("CheckButton", "aspect", "9x16"))
  ok(tiktok:IsEnabled())
  M.click(find("CheckButton", "zones"))
  ok(not tiktok:IsEnabled(), "platforms greyed out without safe zones")
end)

test("darkness slider in steps of 5", function()
  local ns = open()
  local s = controls("Slider")[1]
  eq(s:GetValue(), 60)
  s:SetValue(43)
  eq(ns.db.alpha, 45)
  s.scripts.OnMouseWheel(s, -1)
  eq(ns.db.alpha, 40)
end)

test("Reset button and Esc", function()
  local ns, win = open()
  ns.Set("alpha", 10)
  for _, b in ipairs(controls("Button")) do
    if b.text == ns.L.btnReset then M.click(b) end
  end
  eq(ns.db.alpha, 60)
  eq(UISpecialFrames[1], "VertiCropOptions")
  ns.ToggleOptions()
  ok(not win:IsShown())
end)

test("game options entry: Settings on new clients, Interface Options on old ones", function()
  M.load({ settings = true })
  eq(#M.categories, 1); eq(M.categories[1].name, "VertiCrop")
  M.load({ interfaceOptions = true })
  eq(#M.categories, 1); eq(M.categories[1].name, "VertiCrop")
  M.load() -- neither: no error, the window and /vcrop still work
end)

test("options entry button opens the window", function()
  M.load({ settings = true })
  local panel = M.categories[1].panel
  for _, c in ipairs(panel.children) do
    if c.kind == "Button" then M.click(c) end
  end
  ok(VertiCropOptions and VertiCropOptions:IsShown())
end)

test("window builds in every language", function()
  for _, loc in ipairs({ "enUS", "deDE", "esES", "esMX", "frFR", "ruRU", "koKR", "ptBR", "zhCN", "zhTW", "itIT" }) do
    local ns = open({ locale = loc })
    ok(controls("CheckButton")[1].text.text ~= nil, loc)
    ok(ns.CropText():find("810", 1, true), loc .. ": " .. ns.CropText())
  end
end)
