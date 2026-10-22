# Changelog

**VertiCrop 1.5.7**

- Move combat text: the game's own floating combat text about you (damage taken, heals received) starts where you want it, for example inside the 9:16 frame, and is drawn above other frames. "Move..." in the settings shows a small see-through box, one line of combat text high, to drag: the real text appears in it and follows the box while you drag it; a sample number in the game's size rises from the line again and again, as far and as fast as the game's text. Font, colours and float mode stay the game's settings; the game's self combat text must be on in the game options (VertiCrop never changes game settings). Off by default; switched off, the game's own place comes back
- Safe with the secret combat values of WoW Forever: the game's combat text frame is only shifted as a whole, none of its data is touched. The start point is exact at every UI scale
- The combat text box never ends up in a recording: it closes with the settings window (also with Esc), when recording mode goes on and when the overlay goes off. Right-click on the box finishes moving
- Recording mode is off after every login too, like the overlay: the recording key no longer brings back the zones after a login. A /reload is not a login: the overlay and recording mode stay as they were
- The frame is the OBS crop to the pixel: no column of the border or the darkening can reach into the video
- Easier to read on any ground: dead zones have a solid red inner edge, the yellow lines and the grid a thin dark shadow, the labels are a quarter larger, and "Safe box" sits above its top line, out of the space for your UI
- Crop values for OBS show top and bottom when there is something to cut there: 16:9 on a 16:10 screen (1920 × 1200: 60 and 60), or one pixel off an odd window height
- Reset keeps the overlay shown
- "Dead zones" is greyed out for formats other than 9:16, like the safe box; the tooltips use the new name everywhere
- After the loading screen: the first-install line now also names the addon menu at the minimap, and players who update hear once about Move combat text. The game's Options → AddOns page lists the commands
- Clearer words: the combat text box says "Combat text starts here"; in Russian and French the safe box got its own word, so "frame" means only the crop frame
- "How to use it" in five steps: an Edit Mode layout for recording, combat text, which OBS source, why 1440p gives a sharper clip

**VertiCrop 1.4.1**

- Addon menu at the minimap: a tooltip shows whether the overlay and recording mode are on, and what a click does. Left click opens the settings, right click switches the overlay on or off

**VertiCrop 1.4.0**

- New format 16:9 for ultrawide screens (21:9, 32:9): see which part of the screen a normal YouTube video keeps, with the crop values for OBS (on 3440 × 1440: 2560 × 1440, left 440, right 440). `/vcrop 16:9` switches to it. On a 16:9 screen the frame is the whole screen

**VertiCrop 1.3.2**

- The settings window remembers where you dragged it, also after /reload and the next login. Reset keeps the place

**VertiCrop 1.3.1**

- The red zones are called "Dead zones" now: the old name "Safe zones (red)" read as if red were safe, next to the yellow safe box. The platform choice is called "Platform"
- The settings window is a little wider, and every text in it fits on one line in every language: the crop values for OBS are two fixed lines (size, then left and right), long notes are shorter. A test checks the length of every text in all 9 languages
- Chinese tooltip of the dead zones reworded

**VertiCrop 1.3.0**

- The yellow safe box has a step on the right: beside the side buttons it keeps clear of them as before, above the button column it reaches out to the edge that tall phones cut (9 %). On 1920 × 1080 that is about 88 px more room at the top right, for example for the target frame. The step follows the chosen platform: YouTube Shorts, TikTok, Instagram Reels or All

**VertiCrop 1.2.3**

- Crop values for OBS stay even in windowed mode with an odd window size (for example 1600 × 899: 506 × 898 instead of 506 × 899); video encoders need even sizes. 1:1 stays square there too

**VertiCrop 1.2.2**

- Up to date on Wrath of the Lich King Classic (3.4.5 and 3.80.2) and Cataclysm Classic (4.4.2) too, not only listed as out of date there

**VertiCrop 1.2.1**

- Own icon in the addon list and in the addon menu at the minimap: the 9:16 frame with its safe zones

**VertiCrop 1.2.0**

- The overlay starts off at every login: it is a tool for setting up your UI and recording, not for playing. Switch it on with `/vcrop`, your key binding, the settings window or the addon menu at the minimap; all other settings are kept
- The first time after installing, one chat line tells how to switch it on

**VertiCrop 1.1.0**

- New "Safe box" (yellow, on by default): keep what matters inside it and it stays visible even with long captions, automatic subtitles and on tall phones (19.5:9, 20:9) that fill the screen and cut the sides of a 9:16 video. It adds a reserve to the red zones of the chosen platform: 4 % at the top, 9 % at the bottom, 5 % beside the buttons, 9 % on each side
- The red button zone on the right now covers only the lower part of the edge, where the like, comment and share buttons are; the upper right corner is free again (for example for the target frame)

**VertiCrop 1.0.0**

- First release: a 9:16 crop frame over the game, the screen outside it darkened (0–100 %), a thin border just outside the frame
- Safe zones of YouTube Shorts, TikTok and Instagram Reels, or "All" (the largest margin of every side), with names on them
- Rule-of-thirds grid and center cross
- Recording mode: hides everything inside the frame, so only the dark sides and the border stay, outside the crop
- Formats 9:16, 4:5 (Instagram feed) and 1:1
- Crop values for OBS in pixels (width, height, left, right): in the settings window and with `/vcrop px`
- Settings window (`/vcrop opt`, the game's AddOns options and the addon menu at the minimap), key bindings, 9 languages
- One download for Retail, Classic Era, Mists of Pandaria Classic, TBC Anniversary and WoW Forever
