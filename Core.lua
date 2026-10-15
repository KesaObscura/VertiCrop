local ADDON, ns = ...
local L = ns.L

ns.VERSION = "1.5.1"
local PREFIX = "|cff4fc3f7VertiCrop|r: "
local floor, max, min = math.floor, math.max, math.min

------------------------------------------------------------------------
-- formats and platform safe zones
------------------------------------------------------------------------
ns.ASPECTS = {
  { id = "9x16", w = 9, h = 16, short = "9:16", label = "aspect9x16" },
  { id = "4x5",  w = 4, h = 5,  short = "4:5",  label = "aspect4x5" },
  { id = "1x1",  w = 1, h = 1,  short = "1:1",  label = "aspect1x1" },
  -- for ultrawide screens (21:9, 32:9): the part a normal 16:9 video keeps
  { id = "16x9", w = 16, h = 9, short = "16:9", label = "aspect16x9" },
}

-- Share of the 9:16 frame each app covers (top bar, captions + buttons, side buttons).
-- Rounded from measured 1080x1920 layouts; the apps change them, so they are a guide only.
ns.PLATFORMS = {
  { id = "all" },
  { id = "shorts", name = "YouTube Shorts",  top = 0.125, bottom = 0.20,  left = 0.055, right = 0.185 },
  { id = "tiktok", name = "TikTok",          top = 0.115, bottom = 0.25,  left = 0.055, right = 0.13 },
  { id = "reels",  name = "Instagram Reels", top = 0.135, bottom = 0.205, left = 0.045, right = 0.165 },
}
do -- "all" = the largest margin of every side
  local all = ns.PLATFORMS[1]
  for _, side in ipairs({ "top", "bottom", "left", "right" }) do
    all[side] = 0
    for i = 2, #ns.PLATFORMS do all[side] = max(all[side], ns.PLATFORMS[i][side]) end
  end
end

-- The side buttons (like, comment, share, sound) sit in the lower part of the right edge:
-- their column starts this share of the frame height below the top.
ns.BUTTONS_TOP = 0.33

-- Safe box = the red margins plus a reserve for what moves: long captions push the text up,
-- automatic subtitles, and tall phones (19.5:9, 20:9) that fill the screen and cut up to 9 %
-- of a 9:16 video on each side (1 - (9/19.5) / (9/16) = 18 % in total).
ns.RESERVE = { top = 0.04, bottom = 0.09, right = 0.05, side = 0.09 }

ns.DEFAULTS = {
  enabled = false, rec = false, aspect = "9x16", platform = "all",
  zones = true, box = true, grid = true, labels = true, alpha = 60,
  -- self combat text: moved or not, start point as share of the game window
  ctMove = false, ctX = 0, ctY = 0.5,
}

local function Find(list, id)
  for _, e in ipairs(list) do if e.id == id then return e end end
  return list[1]
end
function ns.Aspect(id) return Find(ns.ASPECTS, id) end
function ns.Platform(id) return Find(ns.PLATFORMS, id) end

------------------------------------------------------------------------
-- geometry (pure functions, tested headless)
------------------------------------------------------------------------
-- largest aw:ah box inside W x H, centered: x, y (bottom-left), w, h
function ns.Fit(W, H, aw, ah)
  local w, h
  if W * ah >= H * aw then h = H; w = H * aw / ah else w = W; h = W * ah / aw end
  return (W - w) / 2, (H - h) / 2, w, h
end

-- Everything the overlay draws, as rectangles in UIParent units from the bottom-left corner.
-- px = one screen pixel in UIParent units (lines stay 1-2 pixels thick at any UI scale).
function ns.Layout(W, H, d, px)
  px = px or 1
  local a = ns.Aspect(d.aspect)
  local x, y, w, h = ns.Fit(W, H, a.w, a.h)
  local rects = {}
  local function add(name, kind, rx, ry, rw, rh)
    if rw > 0 and rh > 0 then
      rects[#rects + 1] = { name = name, kind = kind, x = rx, y = ry, w = rw, h = rh }
    end
  end

  -- darkened screen outside the frame
  add("maskL", "mask", 0, 0, x, H)
  add("maskR", "mask", x + w, 0, W - x - w, H)
  add("maskT", "mask", x, y + h, w, H - y - h)
  add("maskB", "mask", x, 0, w, y)

  -- the border sits just outside the frame, so the crop cuts it away
  local t = 2 * px
  if x >= t then
    add("borderL", "border", x - t, y, t, h)
    add("borderR", "border", x + w, y, t, h)
  end
  if y >= t then
    add("borderT", "border", x, y + h, w, t)
    add("borderB", "border", x, y - t, w, t)
  end

  -- inside the frame: nothing in recording mode
  if not d.rec then
    local p = ns.Platform(d.platform)
    if d.zones and a.id == "9x16" then
      local zt, zb = p.top * h, p.bottom * h
      add("zoneT", "zone", x, y + h - zt, w, zt)
      add("zoneB", "zone", x, y, w, zb)
      add("zoneR", "zone", x + w - p.right * w, y + zb, p.right * w, h * (1 - ns.BUTTONS_TOP) - zb)
      add("zoneL", "zone", x, y + zb, p.left * w, h - zt - zb)
    end
    if d.box and a.id == "9x16" then
      -- a step on the right: beside the button column the box keeps clear of the buttons,
      -- above the column only the side crop of tall phones is cut
      local R = ns.RESERVE
      local bl = max(p.left, R.side) * w
      local brLow, brTop = max(p.right + R.right, R.side) * w, R.side * w
      local bt, bb = (p.top + R.top) * h, (p.bottom + R.bottom) * h
      local stepY = y + h * (1 - ns.BUTTONS_TOP)
      local top, t2 = y + h - bt, 2 * px
      add("boxL", "box", x + bl, y + bb, t2, top - y - bb)
      add("boxB", "box", x + bl, y + bb, w - bl - brLow, t2)
      add("boxT", "box", x + bl, top - t2, w - bl - brTop, t2)
      -- the step line lies just above the button column, never on it
      add("boxR", "box", x + w - brLow - t2, y + bb, t2, stepY + t2 - y - bb)
      add("boxS", "box", x + w - brLow - t2, stepY, brLow - brTop + t2, t2)
      add("boxRT", "box", x + w - brTop - t2, stepY, t2, top - stepY)
    end
    if d.grid then
      add("gridV1", "grid", x + w / 3 - px / 2, y, px, h)
      add("gridV2", "grid", x + w * 2 / 3 - px / 2, y, px, h)
      add("gridH1", "grid", x, y + h / 3 - px / 2, w, px)
      add("gridH2", "grid", x, y + h * 2 / 3 - px / 2, w, px)
      local len = min(w, h) * 0.08
      add("crossV", "grid", x + w / 2 - px, y + h / 2 - len / 2, 2 * px, len)
      add("crossH", "grid", x + w / 2 - len / 2, y + h / 2 - px, len, 2 * px)
    end
  end
  return rects, { x = x, y = y, w = w, h = h, aspect = a }
end

local function Even(v) return floor(v / 2 + 0.5) * 2 end

-- Crop in screen pixels for OBS: width, height, left, right, top, bottom.
-- Width and height are even: video encoders need even sizes.
function ns.CropPixels(d, physW, physH)
  if not physW or not physH or physW <= 0 or physH <= 0 then return nil end
  local a = ns.Aspect(d.aspect)
  -- even limits: a window with an odd size (windowed mode) must not give an odd crop
  local maxW, maxH = physW - physW % 2, physH - physH % 2
  local w, h
  if physW * a.h >= physH * a.w then
    h = maxH
    w = min(Even(h * a.w / a.h), maxW)
  else
    w = maxW
    h = min(Even(w * a.h / a.w), maxH)
  end
  local left, top = floor((physW - w) / 2), floor((physH - h) / 2)
  return w, h, left, physW - w - left, top, physH - h - top
end

function ns.PhysicalSize()
  if GetPhysicalScreenSize then
    local w, h = GetPhysicalScreenSize()
    if w and h and w > 0 and h > 0 then return w, h end
  end
end

function ns.CropText()
  local w, h, left, right = ns.CropPixels(ns.db, ns.PhysicalSize())
  if not w then return L.cropUnknown end
  return L.cropInfo:format(w, h, left, right)
end

------------------------------------------------------------------------
-- overlay
------------------------------------------------------------------------
local overlay = CreateFrame("Frame", "VertiCropOverlay", UIParent)
overlay:SetAllPoints(UIParent)
overlay:SetFrameStrata("DIALOG")
overlay:Hide()
ns.overlay = overlay

local LAYERS = { mask = "BACKGROUND", zone = "BORDER", grid = "ARTWORK", box = "ARTWORK", border = "OVERLAY" }
local COLORS = {
  zone = { 0.95, 0.15, 0.15, 0.28 },
  grid = { 1, 1, 1, 0.35 },
  box = { 1, 0.82, 0.1, 0.9 },
  border = { 0.31, 0.76, 0.97, 0.95 },
}
local pool, labels = {}, {}

local function Color(tex, r, g, b, a)
  if tex.SetColorTexture then tex:SetColorTexture(r, g, b, a) else tex:SetTexture(r, g, b, a) end
end

local function Texture(name, kind)
  local t = pool[name]
  if not t then
    t = overlay:CreateTexture(nil, LAYERS[kind])
    pool[name] = t
  end
  return t
end

-- the game's "...Outline" font objects keep the whole font family (Latin, Cyrillic, Korean,
-- Chinese); a single font file set by hand would turn other alphabets into boxes
local function Label(name)
  local fs = labels[name]
  if not fs then
    fs = overlay:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(_G.GameFontHighlightSmallOutline or _G.GameFontHighlightSmall)
    labels[name] = fs
  end
  return fs
end

local function PlaceLabel(name, text, rect, wrap)
  local fs = Label(name)
  fs:ClearAllPoints()
  fs:SetPoint("CENTER", UIParent, "BOTTOMLEFT", rect.x + rect.w / 2, rect.y + rect.h / 2)
  fs:SetWidth(wrap and rect.w or 0)
  fs:SetText(text)
  fs:Show()
end

function ns.Render()
  local d = ns.db
  if not d then return end
  if not d.enabled then
    overlay:Hide()
    if ns.RefreshOptions then ns.RefreshOptions() end
    return
  end
  overlay:Show()

  local W, H = UIParent:GetWidth(), UIParent:GetHeight()
  local _, physH = ns.PhysicalSize()
  local rects, crop = ns.Layout(W, H, d, physH and H / physH or 1)
  local used, byName = {}, {}
  for _, r in ipairs(rects) do
    local t = Texture(r.name, r.kind)
    if r.kind == "mask" then
      Color(t, 0, 0, 0, d.alpha / 100)
    else
      local c = COLORS[r.kind]
      Color(t, c[1], c[2], c[3], c[4])
    end
    t:ClearAllPoints()
    t:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", r.x, r.y)
    t:SetSize(r.w, r.h)
    t:Show()
    used[r.name], byName[r.name] = true, r
  end
  for name, t in pairs(pool) do if not used[name] then t:Hide() end end

  for _, fs in pairs(labels) do fs:Hide() end
  if d.labels and not d.rec then
    if byName.zoneT then PlaceLabel("zoneT", L.zoneTop, byName.zoneT) end
    if byName.zoneB then PlaceLabel("zoneB", L.zoneBottom, byName.zoneB) end
    if byName.zoneR then PlaceLabel("zoneR", L.zoneRight, byName.zoneR, true) end
    if byName.boxT then
      local b = byName.boxT
      PlaceLabel("box", L.zoneBox, { x = b.x, y = b.y - 16, w = b.w, h = 14 })
    end
    -- frame size beside the frame, outside the crop
    if crop.x >= 90 then
      local w, h = ns.CropPixels(d, ns.PhysicalSize())
      local fs = Label("info")
      fs:ClearAllPoints()
      fs:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", crop.x - 10, crop.y + crop.h - 10)
      fs:SetWidth(0)
      fs:SetText(w and ("%s\n%d × %d"):format(crop.aspect.short, w, h) or crop.aspect.short)
      fs:Show()
    end
  end
  if ns.RefreshOptions then ns.RefreshOptions() end
end

------------------------------------------------------------------------
-- settings
------------------------------------------------------------------------
local function Validate(d)
  for k, v in pairs(ns.DEFAULTS) do
    if type(d[k]) ~= type(v) then d[k] = v end
  end
  d.alpha = max(0, min(100, floor(d.alpha + 0.5)))
  d.ctX = max(-0.5, min(0.5, d.ctX))
  d.ctY = max(0, min(1, d.ctY))
  d.aspect = ns.Aspect(d.aspect).id
  d.platform = ns.Platform(d.platform).id
  return d
end

function ns.Set(key, value)
  if key == "ctMove" and ns.SetCombatTextMove then
    ns.SetCombatTextMove(value)
  else
    ns.db[key] = value
  end
  Validate(ns.db)
  ns.Render()
end

function ns.Reset()
  -- the first-install message and the window position are not settings: they stay
  local seen, pos = ns.db.seen, ns.db.pos
  for k in pairs(ns.db) do ns.db[k] = nil end
  ns.db.seen, ns.db.pos = seen, pos
  Validate(ns.db)
  if ns.SetCombatTextMove then ns.SetCombatTextMove(false) end
  ns.Render()
end

local function Say(msg) print(PREFIX .. msg) end

function VertiCrop_Toggle()
  ns.Set("enabled", not ns.db.enabled)
  Say(ns.db.enabled and L.msgOn or L.msgOff)
end

function VertiCrop_ToggleRec()
  ns.db.enabled = true
  ns.Set("rec", not ns.db.rec)
  Say(ns.db.rec and L.msgRecOn or L.msgRecOff)
end

function VertiCrop_OpenOptions()
  if ns.ToggleOptions then ns.ToggleOptions(true) end
end

-- addon menu at the minimap: left click settings, right click overlay on/off
function VertiCrop_OnCompartmentClick(_, button)
  if button == "RightButton" then
    VertiCrop_Toggle()
  elseif ns.ToggleOptions then
    ns.ToggleOptions()
  end
end

local function State(on)
  if on then return L.stateOn, 0.4, 1, 0.4 end
  return L.stateOff, 0.6, 0.6, 0.6
end

function VertiCrop_OnCompartmentEnter(_, button)
  GameTooltip:SetOwner(button or UIParent, "ANCHOR_LEFT")
  GameTooltip:SetText("VertiCrop |cff8a93a6" .. ns.VERSION .. "|r", 1, 0.82, 0)
  local text, r, g, b = State(ns.db and ns.db.enabled)
  GameTooltip:AddDoubleLine(L.optEnabled, text, 1, 1, 1, r, g, b)
  text, r, g, b = State(ns.db and ns.db.rec)
  GameTooltip:AddDoubleLine(L.optRec, text, 1, 1, 1, r, g, b)
  GameTooltip:AddDoubleLine(L.clickLeft, L.doOptions, 0.4, 0.8, 1, 1, 1, 1)
  GameTooltip:AddDoubleLine(L.clickRight, L.doToggle, 0.4, 0.8, 1, 1, 1, 1)
  GameTooltip:Show()
end

function VertiCrop_OnCompartmentLeave()
  GameTooltip:Hide()
end

BINDING_HEADER_VERTICROP = "VertiCrop"
BINDING_NAME_VERTICROP_TOGGLE = L.bindToggle
BINDING_NAME_VERTICROP_REC = L.bindRec
BINDING_NAME_VERTICROP_OPTIONS = L.bindOptions

------------------------------------------------------------------------
-- slash commands
------------------------------------------------------------------------
SLASH_VERTICROP1 = "/vcrop"
SLASH_VERTICROP2 = "/verticrop"
SlashCmdList.VERTICROP = function(msg)
  local cmd = ((msg or ""):match("^%s*(%S*)") or ""):lower()
  if cmd == "" or cmd == "toggle" then
    VertiCrop_Toggle()
  elseif cmd == "rec" then
    VertiCrop_ToggleRec()
  elseif cmd == "opt" or cmd == "options" or cmd == "config" then
    VertiCrop_OpenOptions()
  elseif cmd == "px" then
    Say(ns.CropText())
  elseif cmd == "reset" then
    ns.Reset()
    Say(L.msgReset)
  else
    for _, a in ipairs(ns.ASPECTS) do
      if cmd == a.short then
        ns.db.enabled = true
        ns.Set("aspect", a.id)
        return
      end
    end
    Say(L.help)
  end
end

------------------------------------------------------------------------
-- events
------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
for _, e in ipairs({ "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED" }) do
  pcall(events.RegisterEvent, events, e)
end
events:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 ~= ADDON then return end
    VertiCropDB = Validate(type(VertiCropDB) == "table" and VertiCropDB or {})
    ns.db = VertiCropDB
    -- a setup tool, not something to play with: every login starts with the overlay off
    ns.db.enabled = false
    if not ns.db.seen then
      ns.db.seen = true
      Say(L.msgFirst)
    end
    if ns.InitOptions then ns.InitOptions() end
  end
  ns.Render()
end)
UIParent:HookScript("OnSizeChanged", function() ns.Render() end)
