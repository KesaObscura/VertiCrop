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
  ok(tiktok:IsEnabled(), "the safe box still uses the platform")
  M.click(find("CheckButton", "box"))
  ok(not tiktok:IsEnabled(), "platforms greyed out without safe zones and safe box")
  M.click(find("CheckButton", "aspect", "4x5"))
  ok(not find("CheckButton", "box"):IsEnabled(), "safe box greyed out without 9:16")
  ok(not find("CheckButton", "zones"):IsEnabled(), "dead zones greyed out without 9:16")
end)

test("crop values show top and bottom when the format is wider than the screen", function()
  local ns = M.load({ phys = { 1920, 1200 } })
  ns.db.aspect = "16x9"
  eq(ns.CropText(), ns.L.cropInfo:format(1920, 1080, 0, 0) .. "\n" .. ns.L.cropTB:format(60, 60))
  ns.db.aspect = "9x16"
  eq(ns.CropText(), ns.L.cropInfo:format(676, 1200, 622, 622), "nothing to cut at top and bottom: two lines")
  ns = M.load({ phys = { 1600, 899 } })
  eq(ns.CropText(), ns.L.cropInfo:format(506, 898, 547, 547) .. "\n" .. ns.L.cropTB:format(0, 1),
    "odd window height: one pixel off the bottom")
end)

test("closing the window, recording mode, overlay off or a right click hide the combat text box", function()
  local ns, win = open()
  ns.ToggleTextMover(true)
  local box = VertiCropTextMover
  win:Hide()
  ok(not box:IsShown(), "Esc or the close button")
  ns.ToggleOptions(true); ns.ToggleTextMover(true)
  VertiCrop_ToggleRec()
  ok(not box:IsShown(), "recording mode on")
  VertiCrop_ToggleRec()
  eq(ns.db.enabled, false, "the recording key ends with everything off, no zones at the end of a clip")
  ns.Set("enabled", true); ns.ToggleTextMover(true)
  VertiCrop_Toggle()
  eq(ns.db.enabled, false); ok(not box:IsShown(), "overlay off")
  ns.ToggleTextMover(true)
  box.scripts.OnMouseUp(box, "LeftButton")
  ok(box:IsShown(), "a left click is a drag, not the end")
  box.scripts.OnMouseUp(box, "RightButton")
  ok(not box:IsShown(), "right click: done")
  eq(ns.db.ctMove, true, "moving stays on")
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
  local reset
  for _, b in ipairs(controls("Button")) do if b.text == ns.L.btnReset then reset = b end end
  M.click(reset)
  eq(ns.db.alpha, 10, "the first click only asks")
  eq(reset.text, ns.L.btnResetSure)
  reset.scripts.OnUpdate(reset, 3.5)
  eq(reset.text, ns.L.btnReset, "after 3 s it asks again")
  M.click(reset); M.click(reset)
  eq(ns.db.alpha, 60, "two clicks reset")
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

test("the settings window remembers where it was dragged", function()
  local ns, win = open()
  win:ClearAllPoints()
  win:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 120, -80)
  win.scripts.OnDragStop(win)
  local pos = ns.db.pos
  eq(pos[1], "TOPLEFT"); eq(pos[2], "TOPLEFT"); eq(pos[3], 120); eq(pos[4], -80)
  ns.Reset()
  eq(ns.db.pos, pos, "reset keeps the place")
  -- next login: the window opens there
  ns, win = open({ db = { pos = { "TOPLEFT", "TOPLEFT", 120, -80 } } })
  local p, _, rp, x, y = win:GetPoint()
  eq(p, "TOPLEFT"); eq(rp, "TOPLEFT"); eq(x, 120); eq(y, -80)
  -- a broken saved value falls back to the default place
  ns, win = open({ db = { pos = { "TOPLEFT", 5 } } })
  eq((win:GetPoint()), "RIGHT")
end)

test("opened from the game's options, the window stays when that panel closes", function()
  local ns = M.load({ settings = true })
  local function special()
    local n = 0
    for _, v in ipairs(UISpecialFrames) do if v == "VertiCropOptions" then n = n + 1 end end
    return n
  end
  ns.ToggleOptions(true)
  eq(special(), 1, "Esc closes it normally")
  ns.ToggleOptions(false); ns.ToggleOptions(true)
  eq(special(), 1, "never twice")
  ns.ToggleOptions(false)
  _G.SettingsPanel = M.new("Frame", UIParent, "SettingsPanel")
  ns.ToggleOptions(true)
  eq(special(), 0, "not while the game's options are open: closing them closes every special frame")
  _G.SettingsPanel = nil
end)

test("first-install line names the minimap menu only where it exists", function()
  local ns = M.load({ off = true })
  eq(M.printed[1]:find(ns.L.msgMenu, 1, true), nil, "Classic: no addon compartment")
  _G.AddonCompartmentFrame = {}
  ns = M.load({ off = true })
  ok(M.printed[1]:find(ns.L.msgMenu, 1, true), "Retail / Forever")
  _G.AddonCompartmentFrame = nil
end)

test("Move... is greyed out in recording mode, the box never opens there", function()
  local ns = open()
  local move
  for _, o in ipairs(controls("Button")) do if o.text == ns.L.btnCTMove then move = o end end
  ok(move and move:IsEnabled())
  VertiCrop_ToggleRec()
  ok(not move:IsEnabled(), "greyed out")
  move.scripts.OnEnter(move)
  ok(table.concat(GameTooltip.lines or {}, " "):find(ns.L.ctMoveRec, 1, true), "tooltip says why")
  ns.ToggleTextMover(true)
  ok(not (VertiCropTextMover and VertiCropTextMover:IsShown()), "not even from code")
  VertiCrop_ToggleRec()
  ok(move:IsEnabled())
end)

test("recording mode closes the settings window; /vcrop with a format says it", function()
  local ns, win = open()
  ns.Set("rec", true)
  ok(not win:IsShown(), "the window would reach into a 1:1 or 16:9 frame")
  SlashCmdList.VERTICROP("4:5")
  eq(ns.db.aspect, "4x5")
  ok(M.printed[#M.printed]:find(ns.L.msgFormat:format("4:5"), 1, true))
  ok(ns.L.help:find("16:9", 1, true), "the help names the formats")
end)
