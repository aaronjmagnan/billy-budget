# Project notes for Claude

Godot 4.7 roguelite, GDScript only. DESIGN.md is the north star; update it before changing direction in code.

## Conventions

- Typed GDScript, tabs for indentation, one class per file with `class_name` where other scripts reference it.
- Placeholder visuals are drawn in `_draw()` so the game runs with zero assets. When real art arrives, add a Sprite2D/AnimatedSprite2D and keep the logic untouched.
- Anything a designer might tune is an `@export` on the Floor or the Cabinet, so the owner can adjust it in the Inspector without code.
- Input actions are registered in code in `scripts/game_input.gd` (autoload). Add new actions there.
- New cabinet games: extend `MiniGame` (`scripts/minigames/minigame.gd`), override the `_game_*` hooks, call `end_game(Result.WIN | NEAR | FAIL)`, then add the script to `MINIGAMES` in `scripts/floor_level.gd` and to the `game_type` enum in `scripts/cabinet.gd`. Every mini-game must end on its own if the player does nothing.
- The owner tests on a Mac in the Godot editor and pulls changes with GitHub Desktop. Keep commits small and describe what changed in plain language.

## Verify before pushing

```
godot --headless --path . --import
godot --headless --path . -s res://tests/smoke_test.gd   # must print SMOKE TEST: OK
godot --headless --path . --quit-after 600              # must print no errors
```

Extend `tests/smoke_test.gd` when adding rules to the loop.
