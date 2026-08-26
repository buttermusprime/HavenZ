# HavenZ Session Log

Per-session narrative entries (what shipped / what's stubbed / what's next) plus a running
metrics table for Phase 14.4's retrospective rollup. Update both at the end of every session.

## Metrics

| Phase | Session | Type | Planned sessions | Actual sessions | Elapsed (approx) | No-op? |
|-------|---------|------|-------------------|------------------|-------------------|--------|
| 0 | 0.1 | build | 1 | 1 | 1 sitting | no |

## Entries

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
