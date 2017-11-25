# Sizzle

Sizzle is a platformer.

Setting: Space between multiple pieces of spaceships, finding doors to keep well-fed enough to find the re-entry vehicle.

## Required
- Spaceship tilesets
 - Debris x3
 . Cracked side panel
 . Nose cone L/R
 . Side panel L/R
 . Vents
 . Internal panel
 . Logo
 . Exit Door
 . Side panel with window
 . Gasket
 . Floor
- Asteroid tilesets
- Moving obstacles / platforms
- Change player start position to be not middle of camera
. Starfield background
. Draw starfield background behind each level
. Black out tiles outside level range

## Nice-to-have
- Tutorial
- Gated special moves
- Animated backgrounds
- Booster exhaust / particles
- Multiple exits
- Nebulae, planets, etc. in background
- Wait for all buttons up on all menu screens before recognizing btnp()
- Allow for non-looping animations
- Juicier motion and animations

## Features / Notes 
- Previously landed-on tiles have a cooldown time longer than the touch-time to prevent going back and forth
- Player movement
  - Left / right
  - Jump
- Player special moves
  - Double-jump
  - Jump slash
  - Wall-jump
  - Wall-slide (warms up wall tiles just like standing on the ground)
  - Heat-up (warms up tiles even more)

## Interesting ideas
- Player can press a button to be dropped in from ceiling
	- Game becomes about clearing blocks rather than traversal
- Destroyed tiles regrow over time
- High score based on fewest jumps to reach finish
- Music voices change volume based on player activity (e.g. melody horns as player starts running)
- Vertical scroll

## Level design ideas
Scenarios
 - Trying to hop from one piece of falling debris to another to keep from hitting the grounde
Precision and control
 - Land between spikes
 - Jump from between spikes
 - Ceiling spikes
 - Long jumps
Timing
 - Avoid incoming obstacles
 - Homing obstacles
 - Many choices
 - Disappearing floor
