local _, ns = ...
local L = ns.L
local max, min = math.max, math.min

-- Moves the game's own self combat text (damage taken, heals received ...), drawn by
-- Blizzard_CombatText. Its messages are font strings of the CombatText frame, anchored to the
-- bottom centre of WorldFrame; the game starts them at the centre of the window (x 0,
-- y = 384/768 of the height) in every float mode.
--
-- Nothing on Blizzard's frame may be written from addon code: in clients with secret combat
-- values (WoW Forever) a Lua field written by an addon taints Blizzard's AddMessage, and every
-- combat message then fails on a secret number. So the frame is only shifted as a whole by a
-- Translation animation (it changes where the frame draws, no Lua field) and raised by
-- SetFrameStrata. The game's self combat text setting is only read, never set.

local GAME_START_Y = 384 / 768 -- where the game starts the text, share of the window height
local HOLD = 3600              -- one animation cycle; it repeats

local shiftGroup, shift, origStrata, mover

local function Frame() return _G.CombatText end

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
  return ns.db.ctX * W * k, (ns.db.ctY - GAME_START_Y) * H * k
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
  if not on and mover then mover:Hide() end
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

local function SaveMover()
  local left, right, top = mover:GetLeft(), mover:GetRight(), mover:GetTop()
  if not (left and right and top) then return end
  local k = ToMover()
  ns.db.ctX = max(-0.5, min(0.5, (left + right) / 2 / k / WorldFrame:GetWidth() - 0.5))
  ns.db.ctY = max(0, min(1, top / k / WorldFrame:GetHeight()))
  ns.ApplyCombatText()
  PlaceMover()
end

local function BuildMover()
  mover = CreateFrame("Frame", "VertiCropTextMover", UIParent)
  mover:SetSize(170, 46)
  mover:SetFrameStrata("FULLSCREEN_DIALOG")
  mover:SetClampedToScreen(true)
  mover:EnableMouse(true)
  mover:SetMovable(true)
  mover:RegisterForDrag("LeftButton")
  mover:SetScript("OnDragStart", mover.StartMoving)
  mover:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveMover()
  end)
  local bg = mover:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.31, 0.76, 0.97, 0.35)
  local title = mover:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  title:SetPoint("TOP", 0, -4)
  title:SetText(L.optCT)
  -- sample text in our own frame: never through Blizzard's AddMessage
  local sample = mover:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  sample:SetPoint("BOTTOM", 0, 5)
  sample:SetText("|cff66ff66+125|r   |cffff4040-42|r")
  mover:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.btnCTMove, 1, 1, 1)
    GameTooltip:AddLine(L.tipCTMove, 0.9, 0.82, 0.5, true)
    GameTooltip:Show()
  end)
  mover:SetScript("OnLeave", function() GameTooltip:Hide() end)
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
  else
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
