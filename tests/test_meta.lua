local M, test, eq, ok = T.M, T.test, T.eq, T.ok

local function tocField(name)
  return M.read("VertiCrop.toc"):match("## " .. name:gsub("%-", "%%-") .. ":%s*([^\r\n]+)")
end

test("version is the same in the TOC, Core.lua and the changelog", function()
  local ns = M.load()
  eq(tocField("Version"), ns.VERSION, "TOC")
  eq(M.read("CHANGELOG.md"):match("%*%*VertiCrop ([%d%.]+)%*%*"), ns.VERSION, "CHANGELOG")
end)

test("TOC: Forever and the other game versions, notes in every language", function()
  local versions = {}
  for v in tocField("Interface"):gmatch("%d+") do versions[v] = true end
  ok(versions["16001"], "WoW Forever")
  ok(versions["11509"] and versions["50504"], "Classic Era and Mists Classic")
  for _, loc in ipairs({ "deDE", "esES", "esMX", "frFR", "ruRU", "koKR", "ptBR", "zhCN", "zhTW" }) do
    ok(tocField("Notes-" .. loc), "Notes-" .. loc)
  end
  ok(#M.tocFiles() == 4)
end)

test("own icon: TOC points to icon.tga, 64x64 uncompressed 32-bit", function()
  eq(tocField("IconTexture"), "Interface\\AddOns\\VertiCrop\\icon")
  local h = M.read("icon.tga"):sub(1, 18)
  eq(h:byte(3), 2, "uncompressed true color")
  eq(h:byte(13) + 256 * h:byte(14), 64); eq(h:byte(15) + 256 * h:byte(16), 64)
  eq(h:byte(17), 32, "bits per pixel")
end)

test("plain Lua 5.1, no globals leak besides the documented ones", function()
  local allowed = {
    VertiCropDB = true, VertiCrop_Toggle = true, VertiCrop_ToggleRec = true, VertiCrop_OpenOptions = true,
    VertiCrop_OnCompartmentClick = true, VertiCrop_OnCompartmentEnter = true, VertiCrop_OnCompartmentLeave = true, SLASH_VERTICROP1 = true, SLASH_VERTICROP2 = true,
    BINDING_HEADER_VERTICROP = true, BINDING_NAME_VERTICROP_TOGGLE = true,
    BINDING_NAME_VERTICROP_REC = true, BINDING_NAME_VERTICROP_OPTIONS = true,
  }
  local before = {}
  M.reset()
  for k in pairs(_G) do before[k] = true end
  M.load()
  for k in pairs(_G) do
    if not before[k] and not allowed[k] and k ~= "VertiCropOverlay" and k ~= "VertiCropOptions" then
      error("leaked global " .. k)
    end
  end
end)

test("every game version ticked on CurseForge has its interface number in the TOC", function()
  local versions = {}
  for v in tocField("Interface"):gmatch("%d+") do versions[v] = true end
  for _, gv in ipairs({ "12.1.5", "1.60.1", "1.15.9", "2.5.6", "3.4.5", "3.80.2", "4.4.2", "5.5.4" }) do
    local a, b, c = gv:match("(%d+)%.(%d+)%.(%d+)")
    local n = tostring(a * 10000 + b * 100 + c)
    ok(versions[n], gv .. " -> " .. n)
  end
end)
