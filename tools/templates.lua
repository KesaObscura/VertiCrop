-- Prints the overlay geometry of a 1080x1920 9:16 frame for every platform as tab separated
-- lines (platform, name, kind, x, y, w, h; y from the bottom). Used by tools/templates.py.
-- Usage: lua5.1 tools/templates.lua (io.write: the WoW mock replaces print)
arg = { [0] = "tests/run.lua" }
local M = dofile("tests/mock_wow.lua")
local ns = M.load({ off = true })
for _, p in ipairs(ns.PLATFORMS) do
  local d = { aspect = "9x16", zones = true, box = true, platform = p.id }
  for _, r in ipairs((ns.Layout(1080, 1920, d, 2))) do
    if r.kind == "zone" or r.kind == "edge" or r.kind == "box" then
      io.write(table.concat({ p.id, r.name, r.kind, r.x, r.y, r.w, r.h }, "\t"), "\n")
    end
  end
end
