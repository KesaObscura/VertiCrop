local _, ns = ...
local L = ns.L
local max, min = math.max, math.min

-- Moves the game's own self combat text (damage taken, heals received ...), drawn by
-- Blizzard_CombatText. That addon keeps its start and end points in CombatText.textLocations,
-- in WorldFrame units from the bottom centre, and rebuilds them in UpdateDisplayedMessages
-- (on load, on a resolution change and when the float mode changes). After every rebuild the
-- start point is set to the saved place; the scroll distance and direction stay the game's.
-- Font, colours, float mode and which messages show stay the game's settings.

local hooked, origStrata, mover

local function Frame()
  local ct = _G.CombatText
  if ct and type(ct.textLocations) == "table" and ct.UpdateDisplayedMessages then return ct end
end

-- saved place as share of the game window: x from the centre (-0.5 .. 0.5), y from the bottom
function ns.ApplyCombatText()
  local ct = Frame()
  if not ct or not ns.db or not WorldFrame then return end
  local loc = ct.textLocations
  if ns.db.ctMove and loc.startX and loc.startY then
    local W, H = WorldFrame:GetWidth(), WorldFrame:GetHeight()
    local dx, dy = (loc.endX or loc.startX) - loc.startX, (loc.endY or loc.startY) - loc.startY
    loc.startX, loc.startY = ns.db.ctX * W, ns.db.ctY * H
    loc.endX, loc.endY = loc.startX + dx, loc.startY + dy
    -- on top of the frames it would otherwise hide behind
    if not origStrata then
      origStrata = ct:GetFrameStrata()
      ct:SetFrameStrata("HIGH")
    end
  elseif origStrata then
    ct:SetFrameStrata(origStrata)
    origStrata = nil
    ct:UpdateDisplayedMessages() -- the game puts its own place back
  end
end

local function Hook()
  local ct = Frame()
  if hooked or not ct or not hooksecurefunc then return end
  hooksecurefunc(ct, "UpdateDisplayedMessages", ns.ApplyCombatText)
  hooked = true
  ns.ApplyCombatText()
end
ns.HookCombatText = Hook

-- the self text must be on in the game's settings, otherwise there is nothing to move
local function EnsureGameText()
  if GetCVar and SetCVar and GetCVar("enableFloatingCombatText") == "0" then
    SetCVar("enableFloatingCombatText", "1")
    print("|cff4fc3f7VertiCrop|r: " .. L.msgCTOn)
  end
  if not Frame() and CombatText_LoadUI then pcall(CombatText_LoadUI) end
  Hook()
end

function ns.SetCombatTextMove(on)
  ns.db.ctMove = on and true or false
  if on then EnsureGameText() end
  ns.ApplyCombatText()
  if not on and mover then mover:Hide() end
end

------------------------------------------------------------------------
-- mover: a box with sample text, dragged to where the text should start
------------------------------------------------------------------------
local function Scale()
  return WorldFrame:GetEffectiveScale() / mover:GetEffectiveScale()
end

local function PlaceMover()
  local k = Scale()
  local W, H = WorldFrame:GetWidth(), WorldFrame:GetHeight()
  mover:ClearAllPoints()
  mover:SetPoint("TOP", UIParent, "BOTTOMLEFT", (ns.db.ctX + 0.5) * W * k, ns.db.ctY * H * k)
end

local function SaveMover()
  local k = Scale()
  local W, H = WorldFrame:GetWidth(), WorldFrame:GetHeight()
  local left, right, top = mover:GetLeft(), mover:GetRight(), mover:GetTop()
  if not (left and right and top) then return end
  ns.db.ctX = max(-0.5, min(0.5, (left + right) / 2 / k / W - 0.5))
  ns.db.ctY = max(0, min(1, top / k / H))
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
events:SetScript("OnEvent", function(_, event, name)
  if event == "PLAYER_LOGIN" or name == "Blizzard_CombatText" then
    if ns.db and ns.db.ctMove then EnsureGameText() else Hook() end
  end
end)
