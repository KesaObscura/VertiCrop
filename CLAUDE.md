# Working on VertiCrop

World of Warcraft addon: 9:16 crop frame and Shorts/TikTok/Reels safe zones over the game.
One zip for Retail, Classic Era, TBC Anniversary, Wrath/Cata Classic, Mists Classic and WoW Forever (comma list in
`## Interface`). Plain Lua 5.1 (no `goto`, no `//`), no libraries, no Blizzard templates for
checkboxes, radios or sliders (they differ between clients; `UIPanelButtonTemplate` and
`UIPanelCloseButton` exist everywhere). Files load in TOC order: `Locale.lua` → `Core.lua` →
`Options.lua`; `Bindings.xml` is loaded by the game.

## Rules

- **Public repository.** No `Claude-Session:` links, no `Co-Authored-By:` trailers, no e-mail
  addresses in commits, PR texts, code or docs. Commit messages describe the change only. Commits
  under the session's default author are fine (owner, 2026-10-15).
- **Every user-visible text in all 9 locale tables** of `Locale.lua` (esMX uses esES).
  Platform names and slash command words stay English.
- **Every control that can be clicked has a tooltip**; a test walks the settings window.
- **Run the tests after every change:** `lua5.1 tests/run.lua` must end with `0 failed`.
- **After every change, bump the version** (`VertiCrop.toc`, `ns.VERSION` in `Core.lua`, a new
  `**VertiCrop X.Y.Z**` block on top of `CHANGELOG.md`; a test checks they match) **and hand the
  owner a test zip** built from the committed state:
  `git archive --format=zip --prefix=VertiCrop/ -o VertiCrop-<version>.zip HEAD -- . ':!tests' ':!tools' ':!docs' ':!.gitignore' ':!.pkgmeta' ':!CURSEFORGE.md' ':!CLAUDE.md'`
  (same contents as `.pkgmeta` packages).
- Work on the session branch; `main` changes only through a PR the owner merges (squash).

## Keep in sync on every user-visible change

- `CHANGELOG.md`, `CURSEFORGE.md` (the CurseForge page; the owner copies it by hand),
  `README.md` (features, commands).
- Interface numbers in `VertiCrop.toc`: when a client gets a new patch, add its number
  (`/dump (select(4, GetBuildInfo()))` in game). Which numbers are confirmed: `docs/notes.md`.

## Facts the code relies on

- The frame is computed in UIParent units; one screen pixel = `UIParent:GetHeight() / physH`
  from `GetPhysicalScreenSize` (nil on clients without it: lines fall back to 1 unit, OBS values
  show "unknown").
- OBS crop width and height are rounded to even numbers (encoders need even sizes).
- Safe zones are shares of the 9:16 frame in `ns.PLATFORMS` (Core.lua), rounded from measured
  1080×1920 layouts (sources in `docs/notes.md`). Shown only for 9:16. The right button zone
  starts `ns.BUTTONS_TOP` (0.33) below the top. The yellow safe box = the platform's red margins
  plus `ns.RESERVE` (long captions, auto subtitles, 9 % side crop of 19.5:9 phones). Since 1.3.0
  it has a step on the right: beside the button column right margin = platform right + 5 %, above
  it (from `ns.BUTTONS_TOP` up) only the 9 % side crop; the step line lies just above the column.
- `icon.tga` (in-game icon, `## IconTexture`) and `docs/images/logo.png` come from
  `tools/preview.py`; TGA because every client reads it (64×64, 32-bit, uncompressed).
- The overlay is a child of UIParent (hidden with Alt+Z), strata DIALOG, never takes the mouse.
  The settings window is FULLSCREEN_DIALOG so the darkening never covers it.
