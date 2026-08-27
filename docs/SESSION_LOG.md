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

## Entries

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
