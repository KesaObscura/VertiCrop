local _, ns = ...
local L = ns.L
local max, min = math.max, math.min

-- Moves the game's own self combat text (damage taken, heals received ...), drawn by
-- Blizzard_CombatText. Its messages are font strings of the CombatText frame, anchored with
-- their top to the bottom centre of WorldFrame at x 0, y = 384/768 of the WorldFrame height in
-- every float mode, and scroll up 225/768 of it in 1.9 s. Those numbers come from the WorldFrame
-- size but count in the font strings' own units (CombatText, a UIParent child): at a UI scale
-- below 1 the game's text starts below the middle of the window.
-- A new message goes under the start point: its top is put at the bottom of a font string that
-- hangs from the start point in CombatTextFont (one font height lower), then the text is set to
-- 25 high. Messages that come while others still fly go lower, by up to 130/768 of the height.
--
-- Nothing on Blizzard's frame may be written from addon code: in clients with secret combat
-- values (WoW Forever) a Lua field written by an addon taints Blizzard's AddMessage, and every
-- combat message then fails on a secret number. So the frame is only shifted as a whole by a
-- Translation animation (it changes where the frame draws, no Lua field) and raised by
-- SetFrameStrata. The game's self combat text setting is only read, never set.

local GAME_START_Y = 384 / 768 -- the game's start, share of the WorldFrame height (CombatText units)
local GAME_RISE = 225 / 768    -- how far the game's text scrolls up, same units
local GAME_SECONDS = 1.9       -- in this time
local GAME_TEXT_HEIGHT = 25    -- height of the game's messages, CombatText units
local HOLD = 3600              -- one animation cycle; it repeats

local shiftGroup, shift, origStrata, mover

local function Frame() return _G.CombatText end

-- how far below the start point the game puts the first message, CombatText units: the height
-- of a line in CombatTextFont, measured like the game does on a font string of our own
local measure
local function FontDrop()
  local font, ct = _G.CombatTextFont, Frame()
  if not (font and ct) then return 0 end
  if not measure then
    local holder = CreateFrame("Frame", nil, UIParent)
    holder:SetSize(1, 1)
    holder:SetAlpha(0)
    measure = holder:CreateFontString(nil, "OVERLAY")
    measure:SetPoint("TOP")
    measure.holder = holder
  end
  measure:SetFontObject(font)
  measure:SetText("0")
  local h = measure:GetStringHeight()
  if h and h > 0 then return h * measure.holder:GetEffectiveScale() / ct:GetEffectiveScale() end
  return tonumber(font.GetFont and select(2, font:GetFont())) or 0
end

local function GameTextOn()
  if C_CVar and C_CVar.GetCVarBool then return C_CVar.GetCVarBool("enableFloatingCombatText") end
  return not GetCVar or GetCVar("enableFloatingCombatText") ~= "0"
end
ns.GameCombatTextOn = GameTextOn

-- shift from the game's start point to the saved one, in the CombatText frame's own units
function ns.CombatTextShift()
  local ct = Frame()
  if not ct or not WorldFrame then return 0, 0 end
  local W, H = WorldFrame:GetWidth(), WorldFrame:GetHeight()
  local k = WorldFrame:GetEffectiveScale() / ct:GetEffectiveScale()
  return ns.db.ctX * W * k, ns.db.ctY * H * k - GAME_START_Y * H + FontDrop()
end

function ns.ApplyCombatText()
  local ct = Frame()
  if not ct or not ns.db then return end
  if not shiftGroup then
    shiftGroup = ct:CreateAnimationGroup()
    shiftGroup:SetLooping("REPEAT")
    shift = shiftGroup:CreateAnimation("Translation")
    shift:SetDuration(0)
    shift:SetEndDelay(HOLD)
  end
  shiftGroup:Stop() -- a running group keeps its old offset
  if ns.db.ctMove then
    shift:SetOffset(ns.CombatTextShift())
    shiftGroup:Play()
    if not origStrata then
      origStrata = ct:GetFrameStrata()
      ct:SetFrameStrata("HIGH") -- above the frames it would otherwise hide behind
    end
  elseif origStrata then
    ct:SetFrameStrata(origStrata)
    origStrata = nil
  end
end

function ns.SetCombatTextMove(on)
  ns.db.ctMove = on and true or false
  if on and not GameTextOn() then print("|cff4fc3f7VertiCrop|r: " .. L.msgCTOff) end
  ns.ApplyCombatText()
  if not on and mover and mover:IsShown() then ns.ToggleTextMover(false) end
end

------------------------------------------------------------------------
-- mover: a box with sample text, dragged to where the text should start
------------------------------------------------------------------------
local function ToMover()
  return WorldFrame:GetEffectiveScale() / mover:GetEffectiveScale()
end

local function PlaceMover()
  local k = ToMover()
  mover:ClearAllPoints()
  mover:SetPoint("TOP", UIParent, "BOTTOMLEFT", (ns.db.ctX + 0.5) * WorldFrame:GetWidth() * k,
    ns.db.ctY * WorldFrame:GetHeight() * k)
end

-- the box's top centre is the start point
local function ReadMover()
  local left, right, top = mover:GetLeft(), mover:GetRight(), mover:GetTop()
  if not (left and right and top) then return end
  local k = ToMover()
  ns.db.ctX = max(-0.5, min(0.5, (left + right) / 2 / k / WorldFrame:GetWidth() - 0.5))
  ns.db.ctY = max(0, min(1, top / k / WorldFrame:GetHeight()))
  ns.ApplyCombatText()
end

-- while dragged the real text follows the box (a few times a second is enough)
local sinceRead = 0
local function FollowDrag(_, elapsed)
  sinceRead = sinceRead + (elapsed or 0)
  if sinceRead >= 0.1 then
    sinceRead = 0
    ReadMover()
  end
end

-- the box is one line of the game's text: the first message appears in it (the next ones,
-- while others still fly, a bit lower); the sample rises from it like the game's text: same
-- size, distance and time
local LABEL = 18
local function StartSample()
  local ct = Frame()
  local toMover = (ct and ct:GetEffectiveScale() or UIParent:GetEffectiveScale()) / mover:GetEffectiveScale()
  local H = WorldFrame:GetHeight()
  local line = (GAME_TEXT_HEIGHT + 2) * toMover
  mover.area:SetHeight(line)
  mover:SetHeight(line + LABEL)
  local font = _G.CombatTextFont
  local file, _, flags = font and font.GetFont and font:GetFont()
  if file then mover.sample:SetFont(file, GAME_TEXT_HEIGHT * toMover, flags or "") end
  mover.sampleRise:SetOffset(0, GAME_RISE * H * toMover)
  mover.sampleGroup:Stop()
  mover.sampleGroup:Play()
end

local function BuildMover()
  mover = CreateFrame("Frame", "VertiCropTextMover", UIParent)
  mover:SetSize(260, 45) -- height set by StartSample
  mover:SetFrameStrata("FULLSCREEN_DIALOG")
  mover:SetClampedToScreen(true)
  mover:EnableMouse(true)
  mover:SetMovable(true)
  mover:RegisterForDrag("LeftButton")
  mover:SetScript("OnDragStart", function(self)
    self:StartMoving()
    sinceRead = 0
    self:SetScript("OnUpdate", FollowDrag)
  end)
  mover:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    self:StopMovingOrSizing()
    ReadMover()
    PlaceMover()
  end)
  -- only an outline: the real text appears inside the box and must stay visible
  local area = mover:CreateTexture(nil, "BACKGROUND")
  area:SetPoint("TOPLEFT")
  area:SetPoint("TOPRIGHT")
  area:SetHeight(27)
  mover.area = area
  local function Edge(p1, p2, w, h, a)
    local t = mover:CreateTexture(nil, "ARTWORK")
    t:SetPoint(p1, area)
    t:SetPoint(p2, area)
    if w then t:SetWidth(w) else t:SetHeight(h) end
    t:SetColorTexture(0.31, 0.76, 0.97, a)
  end
  Edge("TOPLEFT", "TOPRIGHT", nil, 2, 1) -- the start line
  Edge("TOPLEFT", "BOTTOMLEFT", 1, nil, 0.6)
  Edge("TOPRIGHT", "BOTTOMRIGHT", 1, nil, 0.6)
  Edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1, 0.6)
  -- the label below: no fill (the next messages appear there) and white, not the safe box's yellow
  local tab = mover:CreateTexture(nil, "BACKGROUND")
  tab:SetPoint("TOPLEFT", area, "BOTTOMLEFT", 0, -1)
  tab:SetPoint("BOTTOMRIGHT")
  local title = mover:CreateFontString(nil, "OVERLAY",
    _G.GameFontHighlightSmallOutline and "GameFontHighlightSmallOutline" or "GameFontHighlightSmall")
  title:SetPoint("TOPLEFT", tab, "TOPLEFT", 4, -3)
  title:SetPoint("TOPRIGHT", tab, "TOPRIGHT", -4, -3)
  title:SetText(L.moverHere)
  -- sample text in our own frame, never through Blizzard's AddMessage: its top starts on the
  -- line and it rises like the real text, again and again
  local sample = mover:CreateFontString(nil, "OVERLAY", _G.CombatTextFont and "CombatTextFont" or "GameFontNormalLarge")
  sample:SetPoint("TOP", mover, "TOP", 0, 0)
  sample:SetText("|cffff4040-123|r")
  mover.sample = sample
  mover.sampleGroup = sample:CreateAnimationGroup()
  mover.sampleGroup:SetLooping("REPEAT")
  mover.sampleRise = mover.sampleGroup:CreateAnimation("Translation")
  mover.sampleRise:SetDuration(GAME_SECONDS)
  local fade = mover.sampleGroup:CreateAnimation("Alpha")
  fade:SetFromAlpha(1)
  fade:SetToAlpha(0)
  fade:SetStartDelay(GAME_SECONDS * 0.7)
  fade:SetDuration(GAME_SECONDS * 0.3)
  mover:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.optCT, 1, 1, 1)
    GameTooltip:AddLine(L.tipMover, 0.9, 0.82, 0.5, true)
    GameTooltip:Show()
  end)
  mover:SetScript("OnLeave", function() GameTooltip:Hide() end)
  mover:SetScript("OnMouseUp", function(_, button)
    if button == "RightButton" then ns.ToggleTextMover(false) end
  end)
  mover:Hide()
end

-- show = true / false, nil toggles
function ns.ToggleTextMover(show)
  if not mover then BuildMover() end
  if show == nil then show = not mover:IsShown() end
  if show then
    if not ns.db.ctMove then ns.SetCombatTextMove(true) end
    PlaceMover()
    mover:Show()
    StartSample()
  else
    mover.sampleGroup:Stop()
    mover:SetScript("OnUpdate", nil)
    mover:Hide()
  end
  if ns.RefreshOptions then ns.RefreshOptions() end
end

function ns.TextMoverShown() return mover and mover:IsShown() or false end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
for _, e in ipairs({ "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED" }) do
  pcall(events.RegisterEvent, events, e) -- the shift is in screen units
end
events:SetScript("OnEvent", function(_, event, name)
  if event ~= "ADDON_LOADED" or name == "Blizzard_CombatText" then ns.ApplyCombatText() end
end)
