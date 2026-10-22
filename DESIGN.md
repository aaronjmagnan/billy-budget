# Billy Budget's Cage Arcade - Design Document v0.2

North star for the project. Everything built should serve the premise and the loop below. Revise this file before revising the code.

## One-line pitch

Bud, a teenager who has never played a video game, sneaks into a sealed-off arcade to rescue friends who were eaten by the beasts trapped inside its machines. A roguelite where every arcade cabinet is a different mini-game, losing lets the beast out, and fighting it is the other way to win.

## Tone

Eerie and wistful, never gory. Dark arcade, humming screens, something alive in the walls. The fear comes from being a kid out of your depth, not from shock content. Moments of warmth: the friends' voices, the hideout radio, the first cabinet you finally beat.

## Premise

- Billy Budget, a game designer, discovered that a game built around a beast acts as a trap. The beast is pulled into the cabinet. Every time the game is played, the cabinet distills a little of the beast into a usable item.
- The arcade is the designer's menagerie. It goes far deeper than the building should allow.
- Billy Budget vanished. The same night, a group of kids disappeared inside. The news reports the military has cordoned off the block because the arcade is "unstable."
- The hero, one of the group who was not there that night, has never gamed. They sneak in through a gap in the perimeter to bring their friends back.

## Protagonist

- **Bud**, a teenager. No gaming experience. This is the tutorial: the game teaches him (and the player) each cabinet honestly.
- Look: scraggly brown hair, white hoodie, baggy gray pants with rolled cuffs, chunky white sneakers. Chunky proportions that read at 32x32.
- Laid back: idle with hands in his hoodie pocket. Secretly a boxer and weightlifter: he snaps into a boxing guard when beasts are near. Fights bare-fisted by default; jab is his strike, a ducking boxer's slip is his dash. Later actions can draw on boxing and lifting.
- Outfits: white hoodie is the default; dark gray hoodie and black hoodie with white trim are unlockable or selectable outfits.
- In multiplayer, players can name their own character. Bud may later appear as a helper NPC or Easter egg.
- Motivation is always the friends, never "beating the arcade." Items are "things I pulled out of these machines so I can go deeper," not loot.
- Grows across runs through unlocks and through the player's own skill.

## Pocket inventory and improvised weapons

- Bud's inventory is the front pocket of his hoodie. Absurdly large things sometimes fit in it; pulling them out is part of the joke.
- Anything in the pocket can be swung at a beast. Damage depends on the item and can be fractional: a piece of paper does almost nothing, a joystick does real damage, something huge hits hard but slowly. Damage values are floats in code for this reason.
- Inventory rules, limits, and perks are not designed yet.

## The friends (meta-progression)

- Each friend is trapped in a specific cabinet on a specific floor.
- Before rescue they appear as glitches and voices in screens: the hint system.
- Rescuing a friend unlocks them as a playable character with a distinct personality and cabinet strengths (the one who actually gamed, the reckless one, the observant one).
- In multiplayer, other players play as rescued friends. Rescue is how the roster grows.

## The hub

- The hideout: a maintenance tunnel or neighbor's basement just inside the cordon.
- Between runs: patch up, look at the floor map, listen to the radio. News bulletins escalate over time (the military plans to seal it, then worse). This is the ticking clock for the final act.
- Rescued friends live here.

## The designer (mystery and ending)

- Speaks through notes in cabinets, the PA system, maintenance logs.
- Deepest floor answers whether they fled, were taken, or went in on purpose.
- Candidate twist: the final beast is wearing the designer.

## Core loop (one floor)

1. Enter the floor. Scout the four cabinets and the silhouette of the floor boss.
2. Fight whatever is already roaming.
3. Play cabinets. Must earn at least 2 items to cross the threshold without a heavy cost. 3 or 4 items make the boss fight progressively easier.
4. Deal with anything that escapes.
5. Face the floor boss. Descend.

Target run length: 30 minutes. 8 to 12 floors. Mini-games 45 to 90 seconds. Boss fights 1 to 2 minutes. Death to new run in under 5 seconds.

## Cabinets (the doors)

- Each cabinet is a self-contained mini-game with its own rules, art, and music. Mechanically different from each other: rhythm, racing, memory, stealth, shooter, puzzle, fighter, and more over time.
- Cabinets hint at what they are (marquee art, attract-mode sound) and which boss facet their item counters.
- Pool of cabinets widens with depth and with unlocks. Later floors can use 3 cabinets with harder games or 5 where you need 3, so count is a difficulty dial.
- Every few floors, one slot is not a cabinet: a prize counter (shop), a rest spot, a deal, or a guildmate's ghost.

## Containment gauge

- Every cabinet shows a visible containment gauge. A loss cracks it. When it breaks, the beast escapes onto the floor.
- Cabinets vary: some start fragile, some sturdy. Relics can reinforce or weaken gauges.
- A cracked but intact cabinet may fail later, while you play another cabinet or during the boss fight. Failures stack into chaos.
- Partial results: a full win grants the item, a near miss grants a lesser "cracked" version, a hard fail cracks the gauge harder.

## Items: pure vs raw

- Win the game cleanly: pure item. Reliable, the distilled power.
- Beast escapes and you beat it in combat: raw item. Same core power plus a wild side effect. Maybe stronger, maybe unstable, maybe it bleeds a little beast into you.
- Some players will deliberately lose to get raw items. This is intended.
- Items stack and transform, Isaac-style. Relics modify both mini-games and combat from one shared pool. Combinations should produce absurd results.

## Floor boss

- The oldest beast on the floor, in a cabinet that has been failing for years.
- Has four facets. Each of the floor's cabinet items counters one. Two items: beatable the hard way. Three: a fair fight. Four: a victory lap.
- Losing to the boss (to decide): end of run, or the boss takes something and lets you through diminished.

## Combat

- Readable 2D action: move, dodge, strike, one special. Relics modify it.
- Enemies are what spilled out of screens. They carry the visual language of their cabinet.
- Combat is connective tissue between cabinets, and the main event when containment fails.

## Risk and reward

- Threshold with fewer than 2 items: allowed but costly (health, a relic, a companion). Desperate players will try it.
- Deals: power now for a cost that follows you (a memory, a friend's help, a favor owed). Never gruesome.
- Secrets: cabinets that only appear after certain actions, games that change if you arrive with a certain relic, unlocks found by accident then hunted on purpose.

## Teams and goals (in-game only)

- Solo is the complete product. No feature requires a second human.
- Teams are async first: a shared contract at the prize counter ("clear floor 5 without a continue," "collect three boss tokens this week"). Progress pools whenever each person plays. Rewards unlock cabinets and relics for everyone.
- Ghosts of guildmates appear playing cabinets on your floor and can hand you a token. Early on, these can be AI stand-ins so the world is never empty.
- Live co-op comes last, as a reward for teams that gel.

## What we deliberately avoid

- Twin-stick combat as the core verb (cabinets are the core verb).
- Grid room maps.
- Shock or gross-out aesthetics.
- Any real-life goal tracking in v1.

## Tech

- Engine: Godot 4, GDScript.
- Steam: GodotSteam for lobbies, achievements, cloud saves.
- Persistence for teams and contracts: Supabase.
- Art and music: sourced or made separately. Each cabinet gets its own visual and musical identity.

## Build order (each stage shippable on its own)

1. Floor skeleton: one floor, four placeholder cabinets, threshold rule, one boss with four facets.
2. Combat layer: move, dodge, strike, special, two enemy types.
3. Three real cabinets (rhythm, memory, shooter) with containment gauges and pure/raw items.
4. Run structure: 8 floors, death and restart, hub with radio.
5. Relic system with stacking and at least 20 relics.
6. Friends: first rescue, first unlockable character, glitch hints.
7. More cabinets, deals, secrets, floor variety.
8. Steam integration and export.
9. Async teams and contracts via Supabase.
10. Live co-op.

## Open questions

- Boss loss: run over, or diminished pass-through?
- Exact number of friends (4 feels right: one per starting cabinet type).
- ~~Name of the arcade and the designer.~~ Billy Budget's Cage Arcade; Billy Budget is the designer.
- Inventory rules: pocket size, what counts as an item, perks.
- ~~Art direction.~~ 32x32 pixel art (Bud's sheet is the reference for scale and outline style).
