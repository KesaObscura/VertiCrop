# VertiCrop – development notes

## Interface numbers in VertiCrop.toc

`## Interface: 120105, 120100, 50504, 40402, 38002, 30405, 20506, 11509, 16001`

| Number | Client | Status |
|---|---|---|
| 16001 | WoW Forever 1.60.1 | confirmed (same as Full Mana Forever and FloorCraft) |
| 120105 / 120100 | Retail (Midnight) 12.1.5 / 12.1.0 | 12.1.5 offered by CurseForge (2026-10-15), not checked in game |
| 50504 | Mists of Pandaria Classic 5.5.4 | confirmed in game (1.3.1, 2026-10-15): loads, icon, settings entry, dead zones, safe box, recording mode, tooltips, OBS values on two lines |
| 40402 | Cataclysm Classic 4.4.2 | offered by CurseForge, not checked in game |
| 38002 | Wrath Classic 3.80.2 (Titan) | offered by CurseForge, not checked in game |
| 30405 | Wrath Classic 3.4.5 | offered by CurseForge, not checked in game |
| 20506 | TBC Anniversary 2.5.6 | offered by CurseForge, not checked in game |
| 11509 | Classic Era 1.15.9 | confirmed in game (1.3.0, 2026-10-15): loads, settings, recording mode, icon |

Game versions to tick on CurseForge for each file: 12.1.5, 1.60.1, 1.15.9, 2.5.6, 3.4.5, 3.80.2,
4.4.2, 5.5.4 (the list CurseForge offered on 2026-10-15). Interface number = major·10000 +
minor·100 + patch.

A number that does not match only makes the game list the addon as out of date on that client;
it never stops it from loading code. Check in game with `/dump (select(4, GetBuildInfo()))` and
drop the guesses once confirmed.

## Safe zones (Core.lua `ns.PLATFORMS`)

Shares of the 1080×1920 frame, rounded. No platform publishes one official number for organic
posts; the sources disagree, especially at the bottom.

| Platform | top | bottom | left | right | from (px of 1080×1920) |
|---|---|---|---|---|---|
| YouTube Shorts | 0.125 | 0.20 | 0.055 | 0.185 | ~241 / 381 / 60 / 201, measured from ad previews, March 2026 (Google's ad-safe margins are larger: 288 / 672 / 48 / 192) |
| TikTok | 0.115 | 0.25 | 0.055 | 0.13 | 220 / 480 / 60 / 140 |
| Instagram Reels | 0.135 | 0.205 | 0.045 | 0.165 | type-safe 896×1264 from 260 px top, 48 px sides; ~180 px right for the icons |

Right button column: only the lower part of the right edge (from 33 % below the top down to the
caption zone), as in all three apps; the upper right corner is free. 33 % is already on the safe
side (the column starts lower in the apps), so the safe box steps out right at that line, without
an extra reserve (owner, 2026-10-15: a 4 % reserve would cut a target frame placed at the top).

Safe box reserve (`ns.RESERVE`): top +4 %, bottom +9 % (long captions and automatic subtitles push
the text up), +5 % beside the buttons, 9 % on each side. The side value is geometry, not a guess:
a phone of 19.5:9 that fills its screen with a 9:16 video cuts 1 - (9/19.5)/(9/16) = 18 % of the
width, 9 % per side (20:9: 10 %). Top, bottom and button reserves are estimates.

Sources: socialync.io safe-zone tools (Shorts, TikTok), adkit.so (YouTube Shorts ad safe
zones), reap.video and vidpros.com (comparisons, Reels).

## Store and repo metadata (set by hand by the owner)

- CurseForge project ID 1746139, page https://www.curseforge.com/wow/addons/verticrop (created 2026-10-15, first file 1.2.2,
  waiting for moderation). `## X-Curse-Project-ID: 1746139` is in the TOC since 1.2.3.
  GitHub About → Website: the CurseForge page.

- GitHub About: "World of Warcraft addon for content creators: an in-game 9:16 crop frame with
  YouTube Shorts, TikTok and Instagram Reels safe zones. Lay out your UI for vertical video before
  you hit record. Retail, Classic and WoW Forever. 9 languages."
- GitHub topics: world-of-warcraft, wow-addon, warcraft-addon, lua, wow-classic, wow-forever,
  youtube-shorts, tiktok, instagram-reels, vertical-video, safe-zone, content-creator, streaming,
  obs, overlay, aspect-ratio. Social preview: `docs/images/social-preview.png`.
- CurseForge summary (at most 256 characters): "See the 9:16 crop of your vertical video in
  game: frame, darkened sides and YouTube Shorts, TikTok and Instagram Reels safe zones. Place your
  UI, record in recording mode, get the crop values for OBS. Retail, Classic and WoW Forever."
- CurseForge avatar: `docs/images/logo.png` (400×400). The in-game icon `icon.tga` (64×64,
  32-bit uncompressed TGA) is drawn from the same picture by `tools/preview.py`.
- CurseForge description images (`CURSEFORGE.md`): 01, 02, 03 from `docs/gallery/` on `main`
  via raw.githubusercontent.com. If CurseForge does not show them, use the forgecdn address of the
  same image from the Media tab instead.
- CurseForge categories: the owner decides; candidates: HUDs, Miscellaneous,
  Development Tools. Game versions: every listed client.
- Gallery: 1280×720 PNGs in `docs/gallery/`, built by `tools/gallery.py <work dir>` from the
  owner's in-game screenshots (1920×1080, English client; the chat box is blurred). Source
  screenshots never go into the repo (names, chat). Order and CurseForge descriptions (≤ 256):
  1. 01_hero — "Lay out your UI for 9:16 in game and see what the phone will show: crop frame,
     YouTube Shorts / TikTok / Reels safe zones and the yellow safe box."
  2. 02_before_after — "Before: unit frames and mana bar outside the crop. After: everything
     inside the safe box, nothing under the app's buttons and captions."
  3. 03_layout_and_recording — "Set up with the zones, then /vcrop rec: nothing inside the frame,
     the crop cuts the dark sides and the border away."
  4. 04_darkening — "Darken the screen outside the frame from 0 to 100 %."
  5. 05_edit_mode — "Works with Edit Mode: save a layout just for recording."
  6. 06_settings — "Everything in one small window: format, platform, safe box, grid,
     recording mode and the exact crop values for OBS."
  Screenshots taken on WoW Forever 1.60.1 with Full Mana Forever (owner's addon) under the
  character.
- GitHub release: tag `vX.Y.Z` (the owner creates it), not a pre-release, zip
  `VertiCrop-X.Y.Z.zip`, body = two-line pitch, install line, the changelog, bug-report link.
