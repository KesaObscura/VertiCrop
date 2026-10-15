# VertiCrop – development notes

## Interface numbers in VertiCrop.toc

`## Interface: 120105, 120100, 50504, 20506, 20505, 11509, 16001`

| Number | Client | Status |
|---|---|---|
| 16001 | WoW Forever 1.60.1 | confirmed (same as Full Mana Forever and FloorCraft) |
| 120105 / 120100 | Retail (Midnight) 12.1.5 / 12.1.0 | from the TOC format page of the Warcraft Wiki, not checked in game |
| 50504 | Mists of Pandaria Classic 5.5.4 | from the Warcraft Wiki, not checked in game |
| 11509 | Classic Era 1.15.9 | from the Warcraft Wiki, not checked in game |
| 20506 / 20505 | TBC Anniversary | unclear which one is live, both listed |

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

Sources: socialync.io safe-zone tools (Shorts, TikTok), adkit.so (YouTube Shorts ad safe
zones), reap.video and vidpros.com (comparisons, Reels).

## Store and repo metadata (set by hand by the owner)

- GitHub About: "World of Warcraft addon for content creators: an in-game 9:16 crop frame with
  YouTube Shorts, TikTok and Instagram Reels safe zones. Lay out your UI for vertical video before
  you hit record. Retail, Classic and WoW Forever. 9 languages."
- GitHub topics: world-of-warcraft, wow-addon, warcraft-addon, lua, wow-classic, wow-forever,
  youtube-shorts, tiktok, instagram-reels, vertical-video, safe-zone, content-creator, streaming,
  obs, overlay, aspect-ratio. Social preview: `docs/images/social-preview.png`.
- CurseForge summary (at most 256 characters): "See the 9:16 crop of your vertical video in
  game: frame, darkened sides and YouTube Shorts, TikTok and Instagram Reels safe zones. Place your
  UI, record in recording mode, get the crop values for OBS. Retail, Classic and WoW Forever."
- CurseForge categories: the owner decides; candidates: HUDs, Miscellaneous,
  Development Tools. Game versions: every listed client.
- Gallery: 1280×720 PNGs from the owner's in-game screenshots (English addon texts). Source
  screenshots never go into the repo (names, chat).
- GitHub release: tag `vX.Y.Z` (the owner creates it), not a pre-release, zip
  `VertiCrop-X.Y.Z.zip`, body = two-line pitch, install line, the changelog, bug-report link.
