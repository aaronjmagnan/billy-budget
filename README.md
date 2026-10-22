# Billy Budget (working title)

A roguelite set in a sealed-off arcade. Every cabinet holds a trapped beast and a different mini-game. Win to distill an item, lose and the beast may break free. See [DESIGN.md](DESIGN.md) for the full vision.

## Current state: Stage 1 prototype

One floor, four cabinets, one floor boss. Placeholder shapes, no art or sound yet.

- **BEAT KEEPER** (pink): rhythm. Press strike as notes cross the line.
- **ECHO GRID** (cyan): memory. Repeat the pattern with the movement keys. Fragile, only 2 containment.
- **PRESSURE LOCK** (amber): timing. Stop the needle in the green zone four times.
- **STATIC RAIN** (green): dodge. Survive 14 seconds of falling static. Fragile.

Win a cabinet for a **pure** item, near-miss for a **cracked** one, fail and its containment cracks. Run out of containment and the beast escapes: beat it for a **raw** item (+1 strike damage, -1 max heart). Cracked cabinets can also fail on their own later.

You need 2 items to cross the threshold (or force it for 2 hearts). Each item strips one of the boss's four colored facets. More items, weaker boss.

## Controls

| Action | Keys |
| --- | --- |
| Move | WASD or arrow keys |
| Strike | J or Space |
| Dash | K or Shift |
| Use cabinet / door | E or Enter |
| Restart | R |

## How to play it

1. Clone this repo with GitHub Desktop.
2. Open Godot 4.7, click **Import**, and pick `project.godot` in the cloned folder.
3. Press **Command B** (Mac) or **F5** to run.

## Tuning without code

Select the **Floor** node in `scenes/main.tscn` and look at the Inspector: items needed to cross, heart cost, hearts, breach chance, boss health, roaming beasts. Select any cabinet to change its name, color, mini-game, containment, or item. Move cabinets by dragging them in the 2D view.

## Folders

- `scenes/` scenes you open in Godot
- `scripts/` game logic (`minigames/` holds one script per cabinet game)
- `assets/` art, audio, fonts (empty for now)
- `tests/` automated checks
