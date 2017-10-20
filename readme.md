# Sizzle

Sizzle is a platformer in which the player can't touch a spot on the ground for more than a short period of time or else the player dies (takes damage?)

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
- Obstacles
  - Pit spikes
  - Wall spikes

## Required
. Gravity
. Player vs. wall / tile collisions
. Player walking
. Tile grid
. Tiles with cooldown
. UI showing tile cooldown
. Level timer
. Ceiling tile collisions
. Player jumping
. Camera follows player
. Spikes
. Death
. Game over screen
. Level end
. Indestructible collision tiles
. Main menu
. Level reset
. Support multiple levels
. 3 Levels

## Important
- Player special moves
  - Wall jump
  - Dash slice
  . Wall slide
  . Double jump
- Moving obstacles
- Interesting setting
- Time high score
- Black-out tiles outside level range
- Improved levels
. Animated movement
. Death animation
. Fall animation


## Nice-to-have
- Tutorial
- Gated special moves
- Animated backgrounds
- Particles on player movement and idle
- Wait for all buttons up on all menu screens before recognizing btnp()
- Allow for non-looping animations
- Juicier motion and animations

## Interesting ideas
- Player can press a button to be dropped in from ceiling
	- Game becomes about clearing blocks rather than traversal
- Destroyed tiles regrow over time
- High score based on fewest jumps to reach finish