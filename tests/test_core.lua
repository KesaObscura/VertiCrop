local M, test, eq, near, ok = T.M, T.test, T.eq, T.near, T.ok

local function byName(rects)
  local t = {}
  for _, r in ipairs(rects) do t[r.name] = r end
  return t
end

test("off at every login, first install says how to switch it on", function()
  local ns = M.load({ off = true })
  ok(not VertiCropOverlay:IsShown())
  ok(M.printed[1] and M.printed[1]:find("/vcrop opt", 1, true), "first install message")
  local saved = { enabled = true, rec = true, alpha = 30, seen = true }
  ns = M.load({ off = true, db = saved })
  ok(not VertiCropOverlay:IsShown(), "saved 'on' does not survive the login")
  eq(ns.db.alpha, 30, "the other settings stay")
  eq(#M.printed, 0, "no message after the first time")
  ns.Reset()
  eq(ns.db.seen, true, "reset does not bring the message back")
  eq(ns.db.enabled, false)
end)

test("16:9 on an ultrawide screen: the part a normal video keeps", function()
  local ns = M.load()
  local w, h, l, r = ns.CropPixels({ aspect = "16x9" }, 3440, 1440)
  eq(w, 2560); eq(h, 1440); eq(l, 440); eq(r, 440)
  w, h, l, r = ns.CropPixels({ aspect = "16x9" }, 1920, 1080)
  eq(w, 1920); eq(l, 0); eq(r, 0)
  local rects = ns.Layout(1920, 1080, { aspect = "16x9", zones = true, box = true, grid = true, platform = "all" }, 1)
  for _, r2 in ipairs(rects) do ok(r2.kind ~= "zone" and r2.kind ~= "box", "no zones for 16:9: " .. r2.name) end
  ns.db.enabled = true
  SlashCmdList.VERTICROP("16:9")
  eq(ns.db.aspect, "16x9")
end)

test("9:16 on a 16:9 screen: full height, centered", function()
  local ns = M.load()
  local x, y, w, h = ns.Fit(1600, 900, 9, 16)
  eq(h, 900); near(w, 506.25); near(x, (1600 - 506.25) / 2); eq(y, 0)
end)

test("a frame wider than the screen fits the width (portrait monitor)", function()
  local ns = M.load()
  local x, y, w, h = ns.Fit(900, 1600, 1, 1)
  eq(w, 900); eq(h, 900); eq(x, 0); eq(y, 350)
end)

test("masks and frame cover the whole screen exactly once", function()
  local ns = M.load()
  for _, size in ipairs({ { 1365.33, 768 }, { 1024, 768 }, { 768, 1365.33 } }) do
    for _, a in ipairs(ns.ASPECTS) do
      local rects, crop = ns.Layout(size[1], size[2], { aspect = a.id, rec = true }, 1)
      local area = crop.w * crop.h
      for _, r in ipairs(rects) do if r.kind == "mask" then area = area + r.w * r.h end end
      ok(math.abs(area - size[1] * size[2]) < 1e-3, a.id .. " covers " .. area)
    end
  end
end)

test("border lies outside the frame, so the crop cuts it away", function()
  local ns = M.load()
  local rects, c = ns.Layout(1365.33, 768, { aspect = "9x16" }, 0.5)
  local r = byName(rects)
  near(r.borderL.x + r.borderL.w, c.x); near(r.borderL.w, 1)
  near(r.borderR.x, c.x + c.w)
  eq(r.borderT, nil, "no top border when the frame has the full height")
end)

test("recording mode keeps only masks and border", function()
  local ns = M.load()
  local rects = ns.Layout(1365.33, 768, { aspect = "9x16", rec = true, zones = true, grid = true, platform = "all" }, 1)
  for _, r in ipairs(rects) do ok(r.kind == "mask" or r.kind == "border", r.name) end
end)

test("safe zones: per platform, inside the frame, 9:16 only", function()
  local ns = M.load()
  local d = { aspect = "9x16", zones = true, platform = "tiktok" }
  local rects, c = ns.Layout(1365.33, 768, d, 1)
  local r = byName(rects)
  near(r.zoneB.h, 768 * 0.25); near(r.zoneT.y + r.zoneT.h, c.y + c.h)
  near(r.zoneR.x + r.zoneR.w, c.x + c.w); near(r.zoneR.w, c.w * 0.13)
  near(r.zoneR.y, r.zoneB.y + r.zoneB.h)
  near(r.zoneR.y + r.zoneR.h, c.y + c.h * (1 - ns.BUTTONS_TOP), "button column: lower part only")
  near(r.zoneL.y + r.zoneL.h, r.zoneT.y, "left edge zone ends where the top bar starts")
  d.aspect = "4x5"
  eq(byName((ns.Layout(1365.33, 768, d, 1))).zoneT, nil)
end)

test("safe box: red margins plus the reserve, 19.5:9 side crop, inside the frame", function()
  local ns = M.load()
  local d = { aspect = "9x16", box = true, platform = "tiktok" }
  local r = byName((ns.Layout(1365.33, 768, d, 1)))
  local _, _, w, h = ns.Fit(1365.33, 768, 9, 16)
  local x = (1365.33 - w) / 2
  near(r.boxL.x - x, w * 0.09, "tall phones cut 9 % per side")
  near(x + w - (r.boxR.x + r.boxR.w), w * (0.13 + 0.05), "right beside the buttons: buttons + reserve")
  near(x + w - (r.boxRT.x + r.boxRT.w), w * 0.09, "right above the buttons: only the side crop")
  near(r.boxS.y, h * (1 - ns.BUTTONS_TOP), "the step sits just above the button column")
  near(r.boxB.y, h * (0.25 + 0.09), "bottom: captions + long-caption reserve")
  near(h - (r.boxT.y + r.boxT.h), h * (0.115 + 0.04))
  ok(1 - 16 / 19.5 <= 2 * ns.RESERVE.side + 1e-9, "reserve covers a 19.5:9 phone")
  d.box, d.zones = false, true
  eq(byName((ns.Layout(1365.33, 768, d, 1))).boxL, nil)
  d.box, d.aspect = true, "1x1"
  eq(byName((ns.Layout(1365.33, 768, d, 1))).boxL, nil, "9:16 only")
end)

test("safe box never runs into a red zone, for every platform", function()
  local ns = M.load()
  local function overlap(a, b)
    return a.x < b.x + b.w - 1e-6 and b.x < a.x + a.w - 1e-6 and a.y < b.y + b.h - 1e-6 and b.y < a.y + a.h - 1e-6
  end
  for _, p in ipairs(ns.PLATFORMS) do
    local rects = ns.Layout(1920, 1080, { aspect = "9x16", zones = true, box = true, platform = p.id }, 1)
    local zones, boxes = {}, {}
    for _, r in ipairs(rects) do
      if r.kind == "zone" then zones[#zones + 1] = r elseif r.kind == "box" then boxes[#boxes + 1] = r end
    end
    eq(#boxes, 6, p.id)
    for _, b in ipairs(boxes) do
      for _, z in ipairs(zones) do ok(not overlap(b, z), p.id .. ": " .. b.name .. " in " .. z.name) end
    end
  end
end)

test("'All' takes the largest margin of every side", function()
  local ns = M.load()
  local all = ns.Platform("all")
  for _, side in ipairs({ "top", "bottom", "left", "right" }) do
    for _, p in ipairs(ns.PLATFORMS) do ok(all[side] >= p[side], side .. " " .. p.id) end
  end
  near(all.bottom, 0.25); near(all.right, 0.185)
end)

test("crop pixels for OBS: even size, left + width + right = screen", function()
  local ns = M.load()
  local w, h, l, r = ns.CropPixels({ aspect = "9x16" }, 2560, 1440)
  eq(w, 810); eq(h, 1440); eq(l, 875); eq(r, 875)
  w, h, l, r = ns.CropPixels({ aspect = "9x16" }, 1920, 1080)
  eq(w, 608); eq(h, 1080); eq(l + w + r, 1920)
  w, h, l, r = ns.CropPixels({ aspect = "4x5" }, 3440, 1440)
  eq(w, 1152); eq(l + w + r, 3440)
  eq(ns.CropPixels({ aspect = "9x16" }, nil, nil), nil)
  -- windowed mode with odd sizes: still even, 1:1 still square, nothing outside the window
  for _, s in ipairs({ { 1281, 721 }, { 1600, 899 }, { 1023, 767 }, { 899, 1600 } }) do
    for _, a in ipairs(ns.ASPECTS) do
      w, h, l, r = ns.CropPixels({ aspect = a.id }, s[1], s[2])
      ok(w % 2 == 0 and h % 2 == 0, a.id .. " " .. s[1] .. "x" .. s[2] .. ": " .. w .. "x" .. h)
      ok(w <= s[1] and h <= s[2] and l >= 0 and r >= 0 and l + w + r == s[1], a.id .. " fits")
      if a.id == "1x1" then eq(w, h, "square") end
    end
  end
end)

test("overlay draws masks with the darkness setting and hides when off", function()
  local ns = M.load({ db = { alpha = 35 } })
  ok(VertiCropOverlay:IsShown())
  local masks = M.shownTextures("BACKGROUND")
  eq(#masks, 2, "left and right on a wide screen")
  near(masks[1].color[4], 0.35)
  ns.Set("enabled", false)
  ok(not VertiCropOverlay:IsShown())
end)

test("switching options hides what is no longer drawn", function()
  local ns = M.load()
  ok(#M.shownTextures("BORDER") == 4, "4 safe zones")
  ok(#M.shownTextures("ARTWORK") == 12, "grid: 4 lines and the cross, safe box: 6 lines")
  ns.Set("rec", true)
  eq(#M.shownTextures("BORDER"), 0); eq(#M.shownTextures("ARTWORK"), 0)
  eq(#M.shownTextures("OVERLAY"), 2, "border stays")
end)

test("labels: zone names and frame size, none in recording mode", function()
  local ns = M.load()
  local texts = {}
  for _, o in ipairs(M.all) do
    if o.kind == "FontString" and o.parent == VertiCropOverlay and o.shown then texts[o.text] = true end
  end
  ok(texts["Top bar"] and texts["Captions and buttons"] and texts["Buttons"] and texts["Safe box"])
  ok(texts["9:16\n810 × 1440"], "frame size label")
  ns.Set("rec", true)
  for _, o in ipairs(M.all) do
    if o.kind == "FontString" and o.parent == VertiCropOverlay then ok(not o.shown, tostring(o.text)) end
  end
end)

test("line thickness follows screen pixels", function()
  M.load({ phys = { 2560, 1440 } })
  local b = M.shownTextures("OVERLAY")[1]
  near(b.w, 2 * 768 / 1440)
end)

test("works without GetPhysicalScreenSize and without outline fonts", function()
  local ns = M.load({ phys = false, noOutline = true })
  ok(VertiCropOverlay:IsShown())
  eq(ns.CropText(), ns.L.cropUnknown)
end)

test("an unknown event on an old client does not stop loading", function()
  local ns = M.load({ unknownEvents = { UI_SCALE_CHANGED = true } })
  ok(ns.db and VertiCropOverlay:IsShown())
end)

test("saved settings are validated", function()
  local ns = M.load({ db = { alpha = 250, aspect = "21x9", platform = "myspace", grid = "yes" } })
  eq(ns.db.alpha, 100); eq(ns.db.aspect, "9x16"); eq(ns.db.platform, "all"); eq(ns.db.grid, true)
end)

test("redraws when the screen size changes", function()
  M.load()
  local before = M.shownTextures("BACKGROUND")[1].w
  UIParent.w = 1024
  UIParent.scripts.OnSizeChanged(UIParent)
  ok(M.shownTextures("BACKGROUND")[1].w < before)
end)

test("slash commands", function()
  local ns = M.load()
  local cmd = SlashCmdList.VERTICROP
  cmd("")
  eq(ns.db.enabled, false)
  cmd("rec")
  eq(ns.db.enabled, true, "rec turns the overlay on"); eq(ns.db.rec, true)
  cmd("4:5")
  eq(ns.db.aspect, "4x5")
  cmd("px")
  ok(M.printed[#M.printed]:find("1152 × 1440", 1, true), M.printed[#M.printed])
  cmd("reset")
  eq(ns.db.aspect, "9x16"); eq(ns.db.rec, false)
  cmd("help")
  ok(M.printed[#M.printed]:find("/vcrop rec", 1, true))
  cmd("opt")
  ok(VertiCropOptions:IsShown())
end)

test("key bindings and addon compartment have their functions", function()
  M.load()
  ok(BINDING_NAME_VERTICROP_TOGGLE and BINDING_NAME_VERTICROP_REC and BINDING_NAME_VERTICROP_OPTIONS)
  local xml = M.read("Bindings.xml")
  for fn in xml:gmatch(">%s*([%w_]+)%(%)%s*<") do ok(type(_G[fn]) == "function", fn) end
  for name in xml:gmatch('name="([%w_]+)"') do ok(_G["BINDING_NAME_" .. name], name) end
  ok(type(VertiCrop_OnCompartmentClick) == "function")
end)

test("addon menu at the minimap: tooltip with state, left click settings, right click overlay", function()
  local ns = M.load({ off = true })
  local toc = M.read("VertiCrop.toc")
  for fn in toc:gmatch("AddonCompartmentFunc%a*:%s*([%w_]+)") do ok(type(_G[fn]) == "function", fn) end
  GameTooltip.lines = nil
  VertiCrop_OnCompartmentEnter("VertiCrop", UIParent)
  local l = GameTooltip.lines
  eq(l[1], ns.L.optEnabled .. "|" .. ns.L.stateOff)
  eq(l[3], ns.L.clickLeft .. "|" .. ns.L.doOptions)
  eq(l[4], ns.L.clickRight .. "|" .. ns.L.doToggle)
  ok(GameTooltip.shown)
  VertiCrop_OnCompartmentLeave()
  ok(not GameTooltip.shown)
  VertiCrop_OnCompartmentClick("VertiCrop", "RightButton")
  eq(ns.db.enabled, true, "right click: overlay on")
  VertiCrop_OnCompartmentClick("VertiCrop", "LeftButton")
  ok(VertiCropOptions and VertiCropOptions:IsShown(), "left click: settings")
end)

local function ctShift()
  local a = CombatText.animGroup and CombatText.animGroup.anim
  if not (a and CombatText.animGroup.playing) then return nil end
  return a.x, a.y
end

test("combat text: off by default, the game's own place stays", function()
  M.load()
  eq(ctShift(), nil)
  eq(CombatText:GetFrameStrata(), "MEDIUM")
  eq(#M.ctWrites, 0)
end)

test("combat text: the frame is shifted by an animation, no field of it is written", function()
  local ns = M.load()
  ns.db.ctX, ns.db.ctY = -0.2, 0.3
  ns.Set("ctMove", true)
  local g = CombatText.animGroup
  eq(g.looping, "REPEAT"); eq(g.anim.kind, "Translation"); eq(g.anim.duration, 0)
  local k = 1 / UIParent.scale -- WorldFrame units -> CombatText units
  local x, y = ctShift()
  -- the game starts the text 384/768 of the WorldFrame height up, counted in CombatText units,
  -- and puts the first message one line of CombatTextFont (60 in the mock) lower
  near(x, -0.2 * 1920 * k); near(y, 0.3 * 1080 * k - 0.5 * 1080 + 60)
  eq(CombatText:GetFrameStrata(), "HIGH", "above other frames")
  M.fire("UI_SCALE_CHANGED")
  x, y = ctShift()
  near(y, 0.3 * 1080 * k - 0.5 * 1080 + 60, "same place after a scale change")
  ns.Set("ctMove", false)
  eq(ctShift(), nil, "switched off: the game's place again")
  eq(CombatText:GetFrameStrata(), "MEDIUM")
  eq(#M.ctWrites, 0, "written: " .. table.concat(M.ctWrites, ","))
  eq(CombatText.textLocations.startY, 540, "the game's own data untouched")
end)

test("combat text: game text off is only reported, never switched on", function()
  local ns = M.load({ selfText = false })
  ns.Set("ctMove", true) -- the mock's SetCVar errors
  ok(M.printed[#M.printed]:find(ns.L.msgCTOff, 1, true))
  eq(M.cvars.enableFloatingCombatText, "0")
end)

test("combat text: Blizzard_CombatText loaded later gets the shift then", function()
  local ns = M.load({ combatText = false })
  ns.Set("ctMove", true)
  eq(ns.db.ctMove, true)
  local ct = M.new("Frame", UIParent, "CombatText")
  ct.scale = UIParent.scale
  M.fire("ADDON_LOADED", "Blizzard_CombatText")
  ok(ctShift(), "shifted once the game loads it")
end)

test("combat text: the mover box sets the start point", function()
  local ns = M.load()
  ns.ToggleTextMover(true)
  eq(ns.db.ctMove, true, "the mover switches moving on")
  local box = VertiCropTextMover
  ok(box:IsShown())
  -- dragged so that its top centre is at 3/4 of the width and 1/4 of the height (UIParent units)
  local k = 1 / UIParent.scale
  box.GetLeft = function() return 1920 * 0.75 * k - 85 end
  box.GetRight = function() return 1920 * 0.75 * k + 85 end
  box.GetTop = function() return 1080 * 0.25 * k end
  box.scale = UIParent.scale
  box.scripts.OnDragStop(box)
  ok(math.abs(ns.db.ctX - 0.25) < 1e-9 and math.abs(ns.db.ctY - 0.25) < 1e-9, ns.db.ctX .. " " .. ns.db.ctY)
  local x, y = ctShift()
  near(x, 0.25 * 1920 * k); near(y, 0.25 * 1080 * k - 0.5 * 1080 + 60)
  -- the sample text rises from the start line like the game's: 225/768 of the height in 1.9 s
  local g = box.sampleGroup
  ok(g.playing and g.looping == "REPEAT", "sample loops while the box is shown")
  eq(g.anims[1].kind, "Translation"); near(g.anims[1].y, 225 / 768 * 1080); eq(g.anims[1].duration, 1.9)
  near(box:GetHeight(), 130 / 768 * 1080 + 25, "the box covers where messages appear")
  local sample
  for _, o in ipairs(M.all) do if o.parent == box and o.fontFile then sample = o end end
  ok(sample, "sample in the game's font"); eq(sample.fontSize, 25, "and the game's message size")
  ns.ToggleTextMover(false)
  ok(not box:IsShown())
  ns.Reset()
  eq(ns.db.ctMove, false); eq(ctShift(), nil)
  eq(#M.ctWrites, 0)
end)

test("combat text: the real text follows the box while it is dragged", function()
  local ns = M.load()
  ns.ToggleTextMover(true)
  local box = VertiCropTextMover
  local k = 1 / UIParent.scale
  box.GetLeft = function() return 1920 * 0.5 * k - 85 end
  box.GetRight = function() return 1920 * 0.5 * k + 85 end
  box.GetTop = function() return 1080 * 0.8 * k end
  box.scale = UIParent.scale
  box.scripts.OnDragStart(box)
  ok(box.scripts.OnUpdate, "follows during the drag")
  box.scripts.OnUpdate(box, 0.2)
  near(ns.db.ctY, 0.8)
  local _, y = ctShift()
  near(y, 0.8 * 1080 * k - 0.5 * 1080 + 60)
  box.scripts.OnDragStop(box)
  eq(box.scripts.OnUpdate, nil, "no work once dropped")
  ns.ToggleTextMover(false)
  eq(#M.ctWrites, 0)
end)
