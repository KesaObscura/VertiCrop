-- Minimal World of Warcraft API mock for headless tests (Lua 5.1).
-- Only what VertiCrop touches. Widgets keep their state in plain fields.
local M = {}
M.ROOT = (arg and arg[0] and arg[0]:match("^(.*)tests/[^/]*$")) or "./"

local methods = {}
local Widget = { __index = methods }
local function noop() end
function methods:SetFrameStrata(s) self.strata = s end
function methods:GetFrameStrata() return self.strata or "MEDIUM" end
function methods:GetEffectiveScale() return self.scale or 1 end
for _, name in ipairs({ "SetClampedToScreen", "SetMovable", "RegisterForDrag",
  "StartMoving", "StopMovingOrSizing", "SetJustifyH", "SetHitRectInsets", "SetPushedTexture",
  "SetDisabledCheckedTexture", "SetBlendMode", "SetTexCoord", "SetOrientation", "SetValueStep",
  "SetObeyStepOnDrag", "SetThumbTexture", "EnableMouseWheel", "SetMotionScriptsWhileDisabled",
  "SetTextColor", "SetTextHeight", "SetNormalTexture", "SetCheckedTexture", "SetHighlightTexture", "SetTexture" }) do
  methods[name] = noop
end

M.all = {}
local function new(kind, parent, name)
  local o = setmetatable({ kind = kind, parent = parent, name = name, shown = true, w = 0, h = 0,
    points = {}, scripts = {}, children = {}, enabled = true, events = {} }, Widget)
  if parent and parent.children then parent.children[#parent.children + 1] = o end
  if parent and parent.scale then o.scale = parent.scale end -- effective scale of a child
  M.all[#M.all + 1] = o
  if name then _G[name] = o end
  return o
end
M.new = new

function methods:Show()
  local was = self.shown
  self.shown = true
  if not was and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide()
  local was = self.shown
  self.shown = false
  if was and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:IsShown() return self.shown end
function methods:SetSize(w, h) self.w, self.h = w, h end
function methods:SetWidth(w) self.w = w end
function methods:SetHeight(h) self.h = h end
function methods:GetWidth() return self.w end
function methods:GetHeight() return self.h end
function methods:SetPoint(...) self.points[#self.points + 1] = { ... } end
function methods:SetAllPoints() self.allPoints = true end
function methods:ClearAllPoints() self.points = {} end
function methods:GetPoint() local p = self.points[1] or {} return p[1], p[2], p[3], p[4], p[5] end
function methods:SetScript(k, f) self.scripts[k] = f end
function methods:GetScript(k) return self.scripts[k] end
function methods:HookScript(k, f)
  local old = self.scripts[k]
  self.scripts[k] = old and function(...) old(...); f(...) end or f
end
function methods:RegisterEvent(e)
  if M.unknownEvents and M.unknownEvents[e] then error("unknown event " .. e) end
  self.events[e] = true
end
function methods:EnableMouse(v) self.mouse = v end
function methods:CreateTexture(_, layer)
  local t = new("Texture", self)
  t.layer = layer
  return t
end
function methods:CreateFontString(_, layer, font)
  local fs = new("FontString", self)
  fs.layer, fs.font = layer, font
  return fs
end
-- animation groups: record what the addon sets, play/stop as a flag
local function newAnimGroup(owner)
  local g = { owner = owner, playing = false, anims = {} }
  function g:SetLooping(v) self.looping = v end
  function g:CreateAnimation(kind)
    local a = { kind = kind }
    function a:SetDuration(d) self.duration = d end
    function a:SetEndDelay(d) self.endDelay = d end
    function a:SetStartDelay(d) self.startDelay = d end
    function a:SetOffset(x, y) self.x, self.y = x, y end
    function a:SetFromAlpha(v) self.fromAlpha = v end
    function a:SetToAlpha(v) self.toAlpha = v end
    g.anims[#g.anims + 1] = a
    g.anim = g.anim or a
    return a
  end
  function g:Play() self.playing = true end
  function g:Stop() self.playing = false end
  return g
end
M.newAnimGroup = newAnimGroup
function methods:CreateAnimationGroup()
  local g = newAnimGroup(self)
  self.animGroup = g -- test access only
  return g
end
function methods:SetColorTexture(r, g, b, a) self.color = { r, g, b, a } end
function methods:SetFontObject(o) self.fontObject = o end
function methods:SetText(t) self.text = t end
function methods:GetText() return self.text end
function methods:SetChecked(v) self.checked = v and true or false end
function methods:GetChecked() return self.checked end
function methods:Enable() self.enabled = true end
function methods:Disable() self.enabled = false end
function methods:IsEnabled() return self.enabled end
function methods:SetMinMaxValues(a, b) self.minV, self.maxV = a, b end
function methods:SetValue(v)
  v = math.max(self.minV or v, math.min(self.maxV or v, v))
  local changed = v ~= self.value
  self.value = v
  if changed and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, v, false) end
end
function methods:GetValue() return self.value or 0 end

-- click like the game: a CheckButton flips its state before OnClick runs
function M.click(f)
  if not f.enabled then return end
  if f.kind == "CheckButton" then f.checked = not f.checked end
  if f.scripts.OnClick then f.scripts.OnClick(f, "LeftButton") end
end

function M.reset(opts)
  opts = opts or {}
  M.all, M.printed = {}, {}
  M.unknownEvents = opts.unknownEvents
  for _, k in ipairs({ "VertiCropDB", "VertiCropOverlay", "VertiCropOptions", "Settings",
    "InterfaceOptions_AddCategory", "GetPhysicalScreenSize", "SettingsPanel" }) do
    _G[k] = nil
  end
  _G.UIParent = new("Frame", nil, "UIParent")
  UIParent.w, UIParent.h = opts.W or 1365.33, opts.H or 768
  UIParent.scale = opts.uiScale or (1080 / 768)
  -- WorldFrame: the game window in its own units (scale 1)
  _G.WorldFrame = new("Frame", nil, "WorldFrame")
  WorldFrame.w, WorldFrame.h = 1920, 1080
  -- Blizzard_CombatText: a frame whose Lua fields an addon must never write (secret values)
  M.cvars = { enableFloatingCombatText = opts.selfText == false and "0" or "1" }
  _G.GetCVar = function(k) return M.cvars[k] end
  _G.SetCVar = function() error("VertiCrop must not set CVars") end
  _G.C_CVar = { GetCVarBool = function(k) return M.cvars[k] == "1" end }
  _G.CombatText = nil
  _G.CombatTextFont = { GetFont = function() return "Fonts\\FRIZQT__.TTF", 50, "" end }
  if opts.combatText ~= false then
    local ct = new("Frame", UIParent, "CombatText")
    ct.scale = UIParent.scale
    ct.textLocations = { startX = 0, startY = 540, endX = 0, endY = 856 }
    -- record every Lua field written on the frame after load
    M.ctWrites = {}
    local fields = {}
    for k, v in pairs(ct) do fields[k] = v end
    for k in pairs(fields) do ct[k] = nil end
    setmetatable(ct, {
      __index = function(_, k) local v = fields[k]; if v ~= nil then return v end; return methods[k] end,
      __newindex = function(_, k, v)
        -- strata: the mock's own SetFrameStrata (a C method in the game, no Lua field)
        if k ~= "animGroup" and k ~= "strata" then M.ctWrites[#M.ctWrites + 1] = k end
        fields[k] = v
      end,
    })
  end
  _G.GameTooltip = new("GameTooltip", nil, "GameTooltip")
  function GameTooltip:SetOwner() end
  function GameTooltip:AddDoubleLine(a, b) self.lines = self.lines or {}; self.lines[#self.lines + 1] = a .. "|" .. b end
  function GameTooltip:AddLine(t) self.lines = self.lines or {}; self.lines[#self.lines + 1] = t end
  _G.UISpecialFrames = {}
  _G.SlashCmdList = {}
  _G.GameFontHighlightSmall = { font = "small" }
  _G.GameFontHighlightSmallOutline = opts.noOutline and nil or { font = "smallOutline" }
  if opts.phys ~= false then
    local pw, ph = (opts.phys or { 2560, 1440 })[1], (opts.phys or { 2560, 1440 })[2]
    _G.GetPhysicalScreenSize = function() return pw, ph end
  end
  if opts.settings then
    M.categories = {}
    _G.Settings = {
      RegisterCanvasLayoutCategory = function(panel, name) return { panel = panel, name = name } end,
      RegisterAddOnCategory = function(c) M.categories[#M.categories + 1] = c end,
    }
  elseif opts.interfaceOptions then
    M.categories = {}
    _G.InterfaceOptions_AddCategory = function(p) M.categories[#M.categories + 1] = p end
  end
  _G.GetLocale = function() return opts.locale or "enUS" end
  _G.CreateFrame = function(kind, name, parent) return new(kind, parent, name) end
  _G.print = function(...) M.printed[#M.printed + 1] = table.concat({ ... }, " ") end
  _G.InCombatLockdown = function() return false end
  _G.HideUIPanel = function(f) f:Hide() end
end

-- load the addon like the client: files in TOC order with a shared namespace, then events
function M.load(opts)
  M.reset(opts)
  M.ns = {}
  for _, f in ipairs(M.tocFiles()) do
    assert(loadfile(M.ROOT .. f))("VertiCrop", M.ns)
  end
  if opts and opts.db then _G.VertiCropDB = opts.db end
  M.fire("ADDON_LOADED", "VertiCrop")
  M.fire("PLAYER_LOGIN")
  M.fire("PLAYER_ENTERING_WORLD")
  -- the overlay starts off at every login; most tests look at it switched on
  if not (opts and opts.off) then M.ns.Set("enabled", true) end
  return M.ns
end

function M.fire(event, ...)
  for _, f in ipairs(M.all) do
    if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
  end
end

function M.read(file)
  local h = assert(io.open(M.ROOT .. file, "rb"))
  local s = h:read("*a")
  h:close()
  return s
end

function M.tocFiles()
  local files = {}
  for line in M.read("VertiCrop.toc"):gmatch("[^\r\n]+") do
    if not line:match("^#") and line:match("%S") then files[#files + 1] = line end
  end
  return files
end

-- every texture of the overlay that is shown, by kind
function M.shownTextures(kind)
  local out = {}
  for _, o in ipairs(M.all) do
    if o.kind == "Texture" and o.parent == _G.VertiCropOverlay and o.shown and (not kind or o.layer == kind) then
      out[#out + 1] = o
    end
  end
  return out
end

return M
