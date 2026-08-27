# HavenZ Session Log

Per-session narrative entries (what shipped / what's stubbed / what's next) plus a running
metrics table for Phase 14.4's retrospective rollup. Update both at the end of every session.

## Metrics

| Phase | Session | Type | Planned sessions | Actual sessions | Elapsed (approx) | No-op? |
|-------|---------|------|-------------------|------------------|-------------------|--------|
| 0 | 0.1 | build | 1 | 1 | 1 sitting | no |
| 0 | 0.2 | build | 1 | 1 | 1 sitting | no |
| 0 | 0.3 | build | 1 | 1 | 1 sitting | no |
| 0 | 0.4 | build | 1 | 1 | 1 sitting | no |
| 0 | 0.5 | build | 1 | 1 | 1 sitting | no |
| 1 | 1.1 | build | 1 | 3 | 3 sittings | no |

## Entries

### S1.1 (sitting 3) — direction+distance movement cards, per a design clarification

Still S1.1, not S1.2 — the user corrected this directly: pointing out missing core mechanics
(no real attack effect, no loot target, no legible turn structure, movement with no direction or
distance) isn't a "does the hook feel good" playtest verdict, it's "you haven't finished building
the gray-box yet." S1.2's actual play-and-judge checkpoint has not started. Renumbered this and
the previous entry from "iteration"/"iteration 2" accordingly; see the corrected metrics row above
(session 1.1, 3 sittings so far, not yet closed out).

This sitting: two of sitting 2's fixes turned out to be misreadings, not UI polish — the user
meant a real mechanic ("the whole point of picking what movement card to play" is choosing among
direction+distance options), and pointed out that a separate Stealth-vs-Loud movement distinction
is redundant now that the debug radio dial already governs how loud the player is being for every
action, not just movement.

**Changed:**
- `CardResource.gd` gained `move_direction: Vector2i` and `move_distance: int` fields — baked
  into the card itself, not chosen after playing it. `effect_data` (the generic undecided-shape
  bucket) wasn't the right home for these; they're stable, structural concepts worth being real
  fields.
- Removed `stealth_move.tres` and `loud_move.tres` entirely. The gray-box's move-card pool is now
  12 procedurally-generated `CardResource` instances (4 directions x 3 distances, `North x1`
  through `West x3`), built in code rather than as 12 near-duplicate authored `.tres` files, since
  these are placeholder gray-box content, not designed GDD card concepts the way Attack/Loot/
  Food/Water are. Heat cost scales with distance (`distance * 0.5`, before the radio multiplier) —
  moving further is louder, same spirit as the original "Loud move +1/tile" doc value.
  `MOVE_STEALTH` stays defined on `CardResource` (removing an enum member has wider blast radius
  than a gray-box iteration warrants) but is simply unused now.
- **Interaction model simplified as a consequence**: since a move card now fully determines its
  own destination, there's no more "select a card, then click a tile to confirm" step for
  anything — every card (move or not) resolves the instant it's clicked, matching how Attack/Loot
  already worked. Removed the entire select-then-target flow: `selected_card_index`, tile
  `gui_input` handling, and the highlight-adjacent-tiles logic from iteration 1 are all gone; grid
  tiles are now purely visual (`mouse_filter = IGNORE`, no click handling at all).
- HUD's radio line relabeled "Radio (stealth)" to make the dual role explicit.

**Verified headlessly** (throwaway script, deleted after use): card pool is 16 entries (4 fixed +
12 move), no card named "Stealth" exists anywhere in the pool, a "North x2" card has the correct
`Vector2i(0,-1)`/distance-2 fields and actually moves the player 2 tiles north when played, and a
"West x3" move from near the grid edge clamps to the boundary tile instead of erroring or going
out of bounds.

Also dropped the redundant "(stealth)" qualifier added to the radio HUD label in sitting 3 above —
the radio dial's role is apparent from play, per direct user feedback.

**Next:** confirm with the user whether the gray-box now actually covers what S1.1 asked for, or
whether more core mechanics are still missing. S1.2's play-and-judge checkpoint starts only once
S1.1 is actually done, not automatically after this sitting.

### S1.1 (sitting 2) — completing missing core mechanics

Still S1.1 — see the note in sitting 3 above about the corrected framing. The user played the
sitting-1 build and pointed out 6 things the gray-box was missing, not 6 opinions about feel:

**Fixed (real gaps, not later-phase scope):**
- **Hand overflowed off-screen with no scroll** — `HandContainer` is now wrapped in a horizontal
  `ScrollContainer`; card display names shortened too (Stealth/Loud/Attack/Loot/Food/Water).
- **Turn end wasn't legible** and **no action/movement counters existed** — replaced the
  "exactly 1 card = 1 turn" simplification with a visible `ACTIONS_PER_TURN = 2` counter shown in
  the HUD; the turn boundary (enemy moves, decay ticks) now only fires when it hits 0, with an
  explicit "-- Turn N ends, zombie moves --" status message. Documented in a header comment that
  the REAL turn-length rule (ends when no legal play + Supply-card extensions) is session 4.4's
  job, not something this counter is meant to anticipate.
- **No distinct Food/Water cards** — `CardResource` already had `SUPPLY_FOOD`/`SUPPLY_WATER`
  categories from session 0.2; added `data/gray_box_cards/supply_{food,water}.tres` and removed
  the single generic `supply.tres` placeholder. Hand size bumped 5 → 6 to show one of every type
  from the start (a deliberate, playtest-driven deviation from S1.1's literal "5-card hand" spec).
- **No reason to move (loot had no target)** — added `LOOT_TILE_COUNT = 3` marked tiles (distinct
  green base tint) that the Loot card can actually claim (+1 salvage, shown in HUD), replenished
  back up to 3 after each pickup. Still a bare signal, not Phase 6's real Supply Request economy.
- **Attack had no target, no way to know where it lands** — rather than building real
  facing/directional combat (not asked for anywhere in the roadmap), Attack now auto-targets
  whichever of the 4 adjacent tiles the zombie occupies, dealing 1 damage; killing it respawns it
  at its original spawn tile with full HP. Zombie HP shown in the HUD.
- **Unclear where a move card could actually go** — selecting a move card now highlights its up
  to 4 valid adjacent destination tiles (distinct gold tint); clicking the same card again cancels
  the selection (previously had no way to back out of a selection at all).

**Deliberately not done** (flagged to the user as possibly-intentional-later, not silently
skipped): literal multi-tile/directional movement cards — nothing in the roadmap or the locked
input-scheme decision calls for movement further than one tile per play; treated the "direction"
complaint as a missing-affordance problem (solved by highlighting) rather than a new mechanic,
pending user confirmation.

**Verified headlessly** (throwaway script, deleted after use) before handing back: 6-card initial
hand, 2-action turn economy (turn only rolls over at 0, resets to 2), loot pickup increments
salvage and the tile count self-heals back to 3, combat deals exactly 1 damage per hit and
respawns the zombie at full HP after 3 hits, and move-card selection highlights up to 4 tiles.
Two of the test's own assertions were initially too strict/wrong (silently falling back to
`hand[-1]` when a searched-for card wasn't in hand, and asserting the respawned zombie's exact
position when it can legitimately take its own AI turn again immediately after respawning in the
same action tick) — fixed in the test, not the game code, after confirming the underlying
mechanic was actually correct both times.

**Next:** more missing-mechanic feedback arrived (sitting 3, above) — still S1.1, not yet the real
S1.2 playtest checkpoint.

### S1.1 (sitting 1) — Gray-box the core loop

**Shipped:** the first real gameplay code in the project — a playable prototype of HavenZ's core
hook, `scenes/gray_box/GrayBox.tscn`/`.gd`, now the project's `run/main_scene`:
- A 10x8 grid of `TileResource` instances (created at runtime, not authored `.tres` — the class
  is used exactly as intended for procedural per-tile state), rendered as plain `ColorRect`s with
  a heat-value `Label` overlay, tinted redder as heat rises.
- A player square that moves one orthogonal tile at a time by clicking a move-type card, then
  clicking an adjacent tile — per this phase's mouse point-and-click input-scheme decision.
- A 5-card hand of real `CardResource` instances loaded from five new sample resources
  (`data/gray_box_cards/{stealth_move,loud_move,attack,loot,supply}.tres`) — noise_cost values
  match the ones documented on `CardResource.gd` itself (Attack +3, Loot +2, MoveLoud +1,
  MoveStealth +0; Supply has no doc-specified value, set to 0.0 here as a placeholder, flagged
  the same as Trap/Distraction for tuning). Playing a card replaces it in the hand from the same
  5-card pool and ends the turn.
- Per-tile heat that rises on a played card's `noise_cost` (times the debug radio multiplier
  below) and decays by a flat rate each turn — except a tile pauses decay entirely for a turn if
  `this_turn_origins` was non-empty during it, per the design doc's "a fight in one spot should
  visibly compound" requirement. Verified directly: heat rose 3.0 on an Attack, held while the
  player kept acting there, then resumed decaying the next turn the player was elsewhere.
- One enemy square, loaded from session 0.2's `enemy_walker_basic.tres`, that scans tiles within
  its `noise_aggro_radius` each turn, finds the hottest one, and rolls a pull chance that scales
  with that heat value (linear up to a gray-box-only `ENEMY_PULL_HEAT_SCALE` constant, not a hard
  threshold) before taking one grid step toward it if the roll succeeds.
- A debug-only radio heat-burst multiplier (keys 0-5, 0 = Off/baseline 1.0x, 1-5 stand in for the
  Portable Radio System's 5 volume tiers, sessions 10.5/10.6) applied on top of every card's
  noise_cost, so the volume-vs-heat tradeoff that later system depends on gets a first feel-check
  now instead of at Phase 10. Throwaway scaffolding only, not the real system.
- Card-button click handlers use `Callable.bind(i)` rather than a lambda capturing the hand-index
  loop variable, sidestepping GDScript's capture-by-value gotcha entirely instead of working
  around it.
- Verified end-to-end with a throwaway headless script (deleted after use): card play raises the
  correct tile's heat, the turn counter advances, decay pauses/resumes correctly, movement lands
  on the right tile, and the enemy moves toward a near-certain-heat tile. All passed.

**Real bugs caught and fixed along the way** (all filed in the shared
`Godot/dev-notes/PENDING_LESSONS.md`, since none are HavenZ-specific):
- `abs()` on statically-typed `int` values (`Vector2i.x`/`.y`) defeats GDScript's `:=` type
  inference the same way untyped-array-indexing does — fixed by switching to `absi()`, the same
  family as the already-known `signi()`.
- A node your own script `add_child()`s during a headless `--script`'s `_initialize()` is not
  necessarily `_ready()` yet when `add_child()` returns — needed an `await process_frame` before
  reading its state in the verification script. Refines (doesn't contradict) the S0.3 finding
  that autoloads specifically ARE ready by `_initialize()` — a manually-added node is a different
  timing case.

**Stubbed / deferred:**
- No walls, no adjacency heat bleed (not asked for by this session's own prompt — that's Phase
  2.5/7.1 scope), no real card effects beyond the heat side-effect, no turn-extension for Supply
  cards (Phase 4.4 scope). Grid size (10x8) and tile pixel size (24px) are gray-box-only choices,
  independent of the real 16px asset unit — the data model is what survives into Phase 2's
  reskin, not these literal pixel dimensions.
- `run/main_scene` now points at the gray-box, not a real title/menu screen (none exists yet).

**Next (corrected in sitting 3):** turned out this build was still missing core mechanics
(sitting 2), not ready for the real S1.2 playtest-and-judge checkpoint yet.

### S0.5 — Testing conventions

**Shipped:**
- `res://scripts/tests/{logic,ui,integration}/` created (each with a `.gitkeep` so the empty
  folders survive a fresh clone), so every future test file has an obvious home from day one
  instead of landing in one flat folder that needs sorting later.
- `CLAUDE.md` gained a "Testing conventions" section, right alongside S0.4's pause convention:
  the shared blast-radius classification (cosmetic / structural scene edit / logic /
  cross-cutting) adapted to concrete HavenZ examples, the mechanical `.tscn`-diff test for telling
  cosmetic from structural without reopening the editor, the required `# Exercises: file.gd, ...`
  depends-on header convention, and an explicit note that checkpoints (1.2, 9.1, 14.1-14.3) always
  run the full suite regardless of blast radius — this rule is for iteration speed between
  checkpoints, not a substitute for them.

**Stubbed / deferred:**
- No real tests exist yet — this session is structure and documentation only, since no gameplay
  code exists yet either. Session 4.1 is the first to actually populate `logic/`.

**Next:** Phase 0 (Foundation & Tooling) is now complete. Session 1.1 (gray-box the core loop) is
the first session of Phase 1 — Concept Validation, and the first to write real gameplay code.

### S0.4 — Pause architecture

**Shipped:**
- `CLAUDE.md` created at the project root, documenting the pause convention: `get_tree().paused`
  is the single source of truth; every node's `process_mode` must be set deliberately
  (`PROCESS_MODE_PAUSABLE` for anything that should freeze — AI timers, decay/propagation ticks,
  card animations, corpse/respawn; `PROCESS_MODE_ALWAYS`/`PROCESS_MODE_WHEN_PAUSED` for anything
  that must keep responding while paused — the pause menu, the gamepad virtual cursor). Chosen as
  `CLAUDE.md` rather than a plain README since every future Claude Code session in this project
  loads it automatically — the exact "every session needs this without re-deriving it" property
  the roadmap asked for. Session 0.5 will add its testing-convention section to this same file.
- Confirmed the underlying lesson was already flagged into the shared
  `Godot/dev-notes/PENDING_LESSONS.md` back on 2026-08-02 when the roadmap itself moved pause
  earlier (v9) — no duplicate entry needed, just linked from `CLAUDE.md`'s reasoning.
- Also caught up on two lessons-ledger entries skipped during S0.2/S0.3 (should have been logged
  when found, not retroactively): the CSV-importer crash-on-empty-file bug and the
  class_name/autoload name-collision bug, both filed in `PENDING_LESSONS.md` as General Use.

**Stubbed / deferred:**
- No pause menu, no pause-triggering input, no code at all — this session is the decision +
  documentation only, exactly as scoped. Session 8.5 builds the real (if UI-minimal) menu against
  actual AI/state-machine code during the vertical slice; Session 12.3 wires it to Settings/Main
  Menu once those exist.

**Next:** Session 0.5 (testing conventions) per the roadmap — the last Phase 0 session before
Phase 1's concept-validation gray-box.

### S0.3 — Audio bus setup

**Shipped:**
- `audio/default_bus_layout.tres` — Master (implicit), SFX, and Music buses, both new buses
  routed to Master at 0 dB. Generated programmatically (`AudioServer.add_bus`/`set_bus_send` +
  `AudioServer.generate_bus_layout()` + `ResourceSaver.save()`) via a throwaway headless script
  rather than hand-typing the resource format, to avoid guessing at Godot's exact property
  naming. Wired in via `project.godot`'s new `[audio] buses/default_bus_layout` key.
- `systems/audio/AudioSettings.gd` + `AudioSettings.tscn`, registered as the `AudioSettings`
  autoload singleton (`[autoload]` in project.godot). Holds `master_volume`/`sfx_volume`/
  `music_volume` as linear 0..1 (Settings-menu-slider shape), applies them to the real
  `AudioServer` buses via `linear_to_db()`, and persists them through a `ConfigFile` at
  `user://settings.cfg` — loaded on `_ready()`, saved on every setter call. No Settings UI exists
  yet (that's session 12.1); this is the apply/persist layer built ahead of it, same pattern as
  session 0.1's localization stub. Bus lookup is by name (`AudioServer.get_bus_index`), not a
  hardcoded index, so it stays correct if the bus layout changes later.
- The `AudioSettings` scene also hosts two silent placeholder `AudioStreamPlayer` children,
  `SFXPlaceholder` (bus="SFX") and `MusicPlaceholder` (bus="Music") — no stream assigned yet, so
  session 12.2 (and whichever session first needs a music cue) only has to drop an
  AudioStream in and call play(), not build bus routing from scratch.
- **Real bug caught while building this:** the script was originally declared
  `class_name AudioSettings extends Node`, which collided with the autoload singleton of the same
  name — Godot refuses to load a script whose `class_name` shadows an existing autoload
  ("Class 'AudioSettings' hides an autoload singleton"), breaking the whole project. Fixed by
  dropping the redundant `class_name` — the autoload registration already provides global access
  via that name, so the class-level identifier was never needed. Caught via the same
  headless-editor-then-verify discipline used for S0.2's CSV bug, not by inspection.
- Verified end-to-end with a throwaway headless `SceneTree` script (deleted after use, per the
  "no `res://scripts/tests/` folder until session 0.5" constraint): all three buses resolve by
  name, the autoload is present in `root` with correct default volumes applied, a volume change
  round-trips through the real `ConfigFile` on disk, and both placeholder players report the
  correct `bus` property. One timing gotcha worth remembering: a custom `SceneTree`-extending
  `--script` main loop does NOT yet have autoloads under `root` inside `_init()` — they're added
  later in engine startup. Override `_initialize()` instead when a headless verification script
  needs to see autoloads.

**Stubbed / deferred:**
- No real audio assets — see the roadmap's Audio Audit table (Core SFX set, ambient loop, radio
  cues/station music) for what still needs sourcing before these buses carry real sound.
- No Settings UI to drive `AudioSettings`'s setters yet (session 12.1); no persisted-volume
  loading test beyond the one round-trip check above.
- A Radio bus/volume-tier system (5 tiers + Off, per the Portable Radio System design folded into
  the roadmap) is Phase 10 scope, not built here — deliberately not pre-built to avoid guessing
  at a shape that system doesn't need yet.

**Next:** Session 0.4 (pause architecture) per the roadmap.

### S0.2 — Core Resource class definitions

**Shipped:**
- Closed out S0.1's deferred item first: ran the Godot 4.6 editor headlessly
  (`--headless --editor --quit`) against the project for the first time. Caught a real bug —
  `localization/strings.csv` had only its `keys,en` header row with zero data rows, which crashes
  Godot's CSV-translation importer (`bucket_table_size == 0`, a division-by-zero-shaped failure
  in the translation compiler when there are no entries to bucket). Fixed by adding one real row
  (`GAME_TITLE,HavenZ` — will actually be consumed by session 12.3's Main Menu). Re-ran headless
  import twice more to confirm `strings.csv.import` and `strings.en.translation` now generate
  correctly and are non-empty. One cosmetic, apparently-harmless artifact remains: Godot logs
  `Failed loading resource: res://localization/strings.csv` / `Resource file not found` at the
  very start of every headless boot (editor and `--script` modes alike), before the import/UID
  system is initialized — but the compiled translation loads and resolves correctly once the
  engine is past that point, confirmed via a throwaway verification script. Not chased further;
  flag it again if it ever turns out to matter once real UI text ships in Phase 4/12.
- Four Resource classes in `res://data/`, `class_name` + PascalCase per the roadmap:
  - `CardResource.gd` — id, display_name, category enum (Attack/Loot/Trap/Distraction/
    MoveStealth/MoveLoud/SupplyFood/SupplyWater/SupplyMedical/SupplyScrap), noise_cost (float),
    effect_data (Dictionary, shape deferred to Phase 1/4). Noise System Design's starting values
    (Attack +3, Loot +2, MoveLoud +1/tile, MoveStealth +0) and the two undocumented ones (Trap
    low/near-zero, Distraction high, both flagged for Phase 1 tuning) are documented in a comment
    for future per-card authoring, not hardcoded into the class.
  - `TileResource.gd` — walkable, blocks_zombie, blocks_noise (bools), heat (float scalar,
    additive/subtractive only per the design doc), and `this_turn_origins` — a Dictionary used
    as a set of HeatOrigin enum values (player/zombie/wildlife/radio/other) that touched the tile
    this turn, with `add_heat_origin()`/`clear_turn_origins()` helpers. Deliberately not
    `@export`ed — it's runtime turn state, not authored per-tile data.
  - `EnemyResource.gd` — id, display_name, max_hp, move_speed, noise_aggro_radius,
    sprite_frames (SpriteFrames, unset until Phase 2's art pipeline).
  - `CorpseResource.gd` — deck_snapshot (Array[CardResource]), position (Vector2i),
    cards_remaining (int).
- One sample `.tres` per class in `res://data/samples/` (`card_attack_basic`, `tile_default`,
  `enemy_walker_basic`, `corpse_sample`), hand-written in Godot 4 resource-text format and
  verified loadable via a throwaway headless `SceneTree` script (`load()` on all four, checked
  `get_script()` resolves to the right class, then deleted the script — not a real test file,
  since `res://scripts/tests/` doesn't exist until session 0.5).

**Stubbed / deferred:**
- No gameplay logic, scenes, or art — resource class definitions only, per the session's own
  scope. The noise_cost-into-tile-heat comment the roadmap asks for belongs at the first real
  write site, which doesn't exist until session 2.5/7.1.
- The cosmetic strings.csv boot-log warning above, if it turns out not to be harmless.

**Incidental:** the headless editor run auto-normalized `project.godot` on exit — it dropped the
explicit `window/stretch/aspect="keep"` line and reordered two `[rendering]` keys. Confirmed this
is Godot pruning values that already equal the engine default ("keep" is Godot 4's default
stretch aspect), not a settings regression — pixel-perfect scaling is unaffected. Left as the
editor wrote it rather than re-adding a line the editor will just strip again next save.

**Next:** Session 0.3 (audio bus setup) per the roadmap, continuing Phase 0's foundation work.

### S0.1 — Project settings, git & repo hygiene

### S0.1 — Project settings, git & repo hygiene

**Shipped:**
- `project.godot`: pixel-perfect 2D display config — 512x288 base viewport (32x18 tiles at the
  asset pack's 16px unit), `canvas_items` stretch mode + `integer` scale_mode + `aspect=keep`
  (locks whole-pixel scaling, no mixels), Nearest texture filtering project-wide, 2D
  transform/vertex pixel snapping. Initial windowed size set to 1024x576 (exact 2x).
- Removed the unused `[physics] 3d/physics_engine="Jolt Physics"` line — this project is 2D-only.
- `localization/strings.csv` created (native Godot CSV translation format, `keys,en` header) and
  registered under `[internationalization]` in project.godot. No UI exists yet to route through
  `tr()`, but every session that adds player-facing text must use it from here on — see
  `docs/LESSONS.md` gap #4 (this was previously flagged as dead scaffolding risk).
- `.gitignore` added (Godot 4 template) and local git repo initialized with an initial commit.
- This file (`SESSION_LOG.md`) created.
- Pushed to a private remote: https://github.com/buttermusprime/HavenZ.git (`origin/master`).
- `docs/ROADMAP.md` added — a faithful structural conversion of `HavenZ_Roadmap.html` (the
  published artifact, still kept at the project root as the reference copy) via a one-off
  regex-based HTML-to-Markdown script, not a hand rewrite. Covers all 61 sessions (1 tentative)
  across 15 phases + POST, plus the Start.01-10 reference sections, Field Notes, and the Card
  Roster proposal. Spot-checked structurally against the source after several regex bugs (a
  malformed `</p>`-for-`</div>` typo in 2 source callouts, a non-greedy div-matching bug in the
  palette swatch section, and checkpoint/parallel-track session cards using an extra CSS class
  that the first pass didn't match) — all fixed and re-verified before committing.

**Stubbed / deferred:**
- Godot editor has not yet been opened against the new project.godot — the localization CSV and
  any texture import settings won't actually take effect until the editor does its first import
  pass. Open the project once before trusting `tr()` lookups or texture filtering in-editor.

**Next:** Session 0.2 (shared data model — CardResource/TileResource) per the roadmap, or open
the editor first to confirm the display/import settings actually took.
