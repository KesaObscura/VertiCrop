local _, ns = ...
local L = ns.L
local floor = math.floor

-- Own small window instead of Blizzard templates for checkboxes and sliders: those templates
-- differ between Retail, Classic and Forever. Only textures every client ships are used.
local win
local checks, radios = {}, {}
local slider, sliderText, cropText, zonesNote, moveButton
local refreshing = false

local TEXT_ON, TEXT_OFF = { 1, 1, 1 }, { 0.5, 0.5, 0.5 }

local function Tip(f, title, text)
  f:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(type(title) == "function" and title() or title, 1, 1, 1)
    if text then GameTooltip:AddLine(text, 0.9, 0.82, 0.5, true) end
    GameTooltip:Show()
  end)
  f:SetScript("OnLeave", function() GameTooltip:Hide() end)
  if f.SetMotionScriptsWhileDisabled then f:SetMotionScriptsWhileDisabled(true) end
end

local function Text(parent, font, text)
  local fs = parent:CreateFontString(nil, "ARTWORK", font)
  fs:SetJustifyH("LEFT")
  fs:SetText(text or "")
  return fs
end

local function Line(parent, layer, r, g, b, a)
  local t = parent:CreateTexture(nil, layer)
  t:SetColorTexture(r, g, b, a)
  return t
end

-- checkbox bound to a boolean setting
local function Check(parent, key, label, tip, x, y)
  local cb = CreateFrame("CheckButton", nil, parent)
  cb:SetSize(24, 24)
  cb:SetPoint("TOPLEFT", x, y)
  cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
  cb:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
  cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
  cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
  cb:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
  cb.text = Text(cb, "GameFontHighlight", label)
  cb.text:SetPoint("LEFT", cb, "RIGHT", 2, 1)
  cb:SetHitRectInsets(0, -230, 0, 0)
  cb:SetScript("OnClick", function(self)
    if refreshing then return end
    ns.Set(key, self:GetChecked() and true or false)
  end)
  Tip(cb, label, tip)
  cb.key = key
  checks[#checks + 1] = cb
  return cb
end

-- radio button bound to one value of a setting
local RADIO = "Interface\\Buttons\\UI-RadioButton"
local function RadioTexture(cb, left, right)
  local t = cb:CreateTexture()
  t:SetTexture(RADIO)
  t:SetTexCoord(left, right, 0, 1)
  t:SetAllPoints()
  return t
end

local function Radio(parent, key, value, label, tip, x, y)
  local cb = CreateFrame("CheckButton", nil, parent)
  cb:SetSize(16, 16)
  cb:SetPoint("TOPLEFT", x, y)
  cb:SetNormalTexture(RadioTexture(cb, 0, 0.25))
  cb:SetCheckedTexture(RadioTexture(cb, 0.25, 0.5))
  local hl = RadioTexture(cb, 0.5, 0.75)
  hl:SetBlendMode("ADD")
  cb:SetHighlightTexture(hl)
  cb.text = Text(cb, "GameFontHighlightSmall", label)
  cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
  cb:SetHitRectInsets(0, -200, 0, 0)
  cb:SetScript("OnClick", function()
    if refreshing then return end
    ns.Set(key, value)
  end)
  Tip(cb, label, tip)
  cb.key, cb.value = key, value
  radios[#radios + 1] = cb
  return cb
end

local function SetActive(cb, on)
  if on then cb:Enable() else cb:Disable() end
  local c = on and (cb.onColor or TEXT_ON) or TEXT_OFF
  cb.text:SetTextColor(c[1], c[2], c[3])
end

function ns.RefreshOptions()
  if not win or not ns.db then return end
  local d = ns.db
  refreshing = true
  local is916 = d.aspect == "9x16"
  for _, cb in ipairs(checks) do
    cb:SetChecked(d[cb.key] and true or false)
    if cb.key == "box" or cb.key == "zones" then SetActive(cb, is916) end
  end
  for _, cb in ipairs(radios) do
    cb:SetChecked(d[cb.key] == cb.value)
    if cb.key == "platform" then SetActive(cb, (d.zones or d.box) and is916) end
  end
  if is916 then zonesNote:Hide() else zonesNote:Show() end
  slider:SetValue(d.alpha)
  sliderText:SetText(L.optAlpha:format(d.alpha))
  cropText:SetText(ns.CropText())
  moveButton:SetText(ns.TextMoverShown and ns.TextMoverShown() and L.btnCTDone or L.btnCTMove)
  refreshing = false
end

local function Build()
  win = CreateFrame("Frame", "VertiCropOptions", UIParent)
  win:SetSize(330, 662)
  win:SetPoint("RIGHT", UIParent, "RIGHT", -40, 0)
  -- the place the window was dragged to last time
  local pos = ns.db and ns.db.pos
  if type(pos) == "table" and type(pos[1]) == "string" and type(pos[2]) == "string"
    and type(pos[3]) == "number" and type(pos[4]) == "number" then
    win:ClearAllPoints()
    win:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
  end
  win:SetFrameStrata("FULLSCREEN_DIALOG")
  win:SetClampedToScreen(true)
  win:EnableMouse(true)
  win:SetMovable(true)
  win:RegisterForDrag("LeftButton")
  win:SetScript("OnDragStart", win.StartMoving)
  win:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    if point and ns.db then ns.db.pos = { point, relPoint, x, y } end
  end)
  win:Hide()
  if UISpecialFrames then table.insert(UISpecialFrames, "VertiCropOptions") end -- Esc closes it

  local bg = Line(win, "BACKGROUND", 0.05, 0.06, 0.09, 0.95)
  bg:SetAllPoints()
  for _, e in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" } }) do
    local t = Line(win, "BORDER", 0.31, 0.76, 0.97, 0.6)
    t:SetPoint(e[1]); t:SetPoint(e[2]); t:SetHeight(1)
  end
  for _, e in ipairs({ { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
    local t = Line(win, "BORDER", 0.31, 0.76, 0.97, 0.6)
    t:SetPoint(e[1]); t:SetPoint(e[2]); t:SetWidth(1)
  end

  local title = Text(win, "GameFontNormalLarge", "VertiCrop |cff8a93a6" .. ns.VERSION .. "|r")
  title:SetPoint("TOPLEFT", 14, -12)
  local sub = Text(win, "GameFontHighlightSmall", L.subtitle)
  sub:SetPoint("TOPLEFT", 14, -34)

  local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", 2, 2)
  close:SetScript("OnClick", function() win:Hide() end)
  Tip(close, L.optClose)

  local y = -56
  Check(win, "enabled", L.optEnabled, L.tipEnabled, 12, y)
  Check(win, "rec", L.optRec, L.tipRec, 12, y - 26)

  y = y - 62
  local fmt = Text(win, "GameFontNormal", L.optAspect)
  fmt:SetPoint("TOPLEFT", 16, y)
  for i, a in ipairs(ns.ASPECTS) do
    Radio(win, "aspect", a.id, L[a.label], L.tipAspect, 18, y - 2 - 20 * i)
  end

  y = y - 2 - 20 * (#ns.ASPECTS + 1) - 8
  Check(win, "zones", L.optZones, L.tipZones, 12, y)
  for i, p in ipairs(ns.PLATFORMS) do
    local r = Radio(win, "platform", p.id, p.name or L.platAll, L.tipPlatform, 40, y - 8 - 20 * i)
    Tip(r, L.optPlatform .. ": " .. (p.name or L.platAll), L.tipPlatform)
  end
  local box = Check(win, "box", L.optBox, L.tipBox, 12, y - 14 - 20 * (#ns.PLATFORMS + 1))
  box.onColor = { 1, 0.82, 0.1 }
  zonesNote = Text(win, "GameFontDisableSmall", L.zonesNote)
  zonesNote:SetPoint("TOPLEFT", 42, y - 44 - 20 * (#ns.PLATFORMS + 1))

  y = y - 164
  Check(win, "grid", L.optGrid, L.tipGrid, 12, y)
  Check(win, "labels", L.optLabels, L.tipLabels, 12, y - 26)

  y = y - 64
  sliderText = Text(win, "GameFontNormal", "")
  sliderText:SetPoint("TOPLEFT", 16, y)
  slider = CreateFrame("Slider", nil, win)
  slider:SetOrientation("HORIZONTAL")
  slider:SetSize(260, 16)
  slider:SetPoint("TOPLEFT", 18, y - 20)
  slider:SetMinMaxValues(0, 100)
  slider:SetValueStep(5)
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
  slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  local track = Line(slider, "BACKGROUND", 0.3, 0.33, 0.4, 0.9)
  track:SetPoint("LEFT"); track:SetPoint("RIGHT"); track:SetHeight(4)
  slider:EnableMouseWheel(true)
  slider:SetScript("OnMouseWheel", function(self, delta)
    self:SetValue(self:GetValue() + delta * 5)
  end)
  slider:SetScript("OnValueChanged", function(_, value)
    if refreshing then return end
    ns.Set("alpha", floor(value / 5 + 0.5) * 5)
  end)
  Tip(slider, function() return L.optAlpha:format(ns.db.alpha) end, L.tipAlpha)

  cropText = Text(win, "GameFontHighlightSmall", "")
  cropText:SetPoint("TOPLEFT", 16, y - 44)
  cropText:SetWidth(298)
  local cropHover = CreateFrame("Frame", nil, win)
  cropHover:SetPoint("TOPLEFT", cropText, "TOPLEFT")
  cropHover:SetSize(298, 38)
  cropHover:EnableMouse(true)
  Tip(cropHover, ns.CropText, L.tipCropInfo)

  -- the game's own self combat text: move it, e.g. into the 9:16 frame
  y = y - 92
  local sep = Line(win, "ARTWORK", 0.31, 0.76, 0.97, 0.35)
  sep:SetPoint("TOPLEFT", 14, y + 8); sep:SetSize(300, 1)
  Check(win, "ctMove", L.optCT, L.tipCT, 12, y)
  moveButton = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
  moveButton:SetSize(130, 22)
  moveButton:SetPoint("TOPLEFT", 40, y - 28)
  moveButton:SetScript("OnClick", function() ns.ToggleTextMover() end)
  Tip(moveButton, L.btnCTMove, L.tipCTMove)

  local reset = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
  reset:SetSize(120, 22)
  reset:SetPoint("BOTTOMLEFT", 14, 12)
  reset:SetText(L.btnReset)
  reset:SetScript("OnClick", function() ns.Reset() end)
  Tip(reset, L.btnReset, L.tipReset)

  win:SetScript("OnShow", ns.RefreshOptions)
  -- the combat text box belongs to the window: Esc or the close button ends moving too
  win:SetScript("OnHide", function()
    if ns.TextMoverShown and ns.TextMoverShown() then ns.ToggleTextMover(false) end
  end)
end

-- show = true opens, false closes, nil toggles
function ns.ToggleOptions(show)
  if not win then Build() end
  if show == nil then show = not win:IsShown() end
  if show then win:Show(); ns.RefreshOptions() else win:Hide() end
end

------------------------------------------------------------------------
-- entry in the game's AddOns options (Settings on new clients, Interface Options on old ones)
------------------------------------------------------------------------
function ns.InitOptions()
  local panel = CreateFrame("Frame")
  panel.name = "VertiCrop"
  local t = Text(panel, "GameFontNormalLarge", "VertiCrop")
  t:SetPoint("TOPLEFT", 16, -16)
  local s = Text(panel, "GameFontHighlightSmall", L.subtitle)
  s:SetPoint("TOPLEFT", 16, -40)
  local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  b:SetSize(240, 26)
  b:SetPoint("TOPLEFT", 16, -64)
  b:SetText(L.btnOpen)
  Tip(b, L.btnOpen, L.tipOpen)
  b:SetScript("OnClick", function()
    -- closing Blizzard's panel from addon code is only safe out of combat
    if not (InCombatLockdown and InCombatLockdown()) then
      if SettingsPanel then pcall(HideUIPanel, SettingsPanel) end
      if InterfaceOptionsFrame then pcall(HideUIPanel, InterfaceOptionsFrame) end
    end
    ns.ToggleOptions(true)
  end)

  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutCategory(panel, "VertiCrop"))
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end
end
