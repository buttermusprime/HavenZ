# HavenZ-Specific Lessons

Lessons that are real but don't generalize to other Godot projects. For engine gotchas, pixel-art guidelines, and timeline pitfalls that apply to *any* project, see `C:\Users\17cor\OneDrive\Documents\Godot\dev-notes\GODOT_LESSONS.md` — don't duplicate those here. The roadmap-lifecycle postmortem review that seeded `TIMELINE_PITFALLS.md` in that shared folder was originally commissioned for HavenZ (`HavenZ_Roadmap_Briefing_1.md` in Downloads) and has since been generalized there.

## Gameplay systems to watch for a second use before extracting (2026-08-01)

Per `GODOT_LESSONS.md` #18 — these are HavenZ systems that look like reusable *patterns*, not proven-reusable yet. Build them here, cleanly decoupled and data-driven as already scoped, but don't spin any into a standalone repo until a second real project would actually reuse the same one:
- **Card/deck engine** — `CardResource` + Deck/Hand/Discard + the play/drop resolution branch + a Container-based hand UI. Load-bearing skeleton of basically any deckbuilder, tile-tactics or not.
- **Grid-signal-propagation system** — the Noise mechanic, generalized: a value that spreads across tile neighbors, decays over time, and is blocked by walls. Directly reusable for stealth games, fire/gas spread, fog of war — HavenZ is just the first user.
- **Data-driven enemy AI** — `EnemyResource` + a shared pathing function specialized per type is a pattern, not a zombie-specific thing.
- **Persistent world-marker system** — the corpse mechanic (spawn a marker holding state at a location, decay it over time, let the player recover it) generalizes past "corpse" into any breadcrumb/cache/checkpoint mechanic.

## Roadmap gaps flagged for reconciliation into the real roadmap (2026-08-01)

Found reviewing the GDD/roadmap for gaps outside the Asset Audit / Recommendations / Engineering Lessons sections that already exist there. These are action items for the next HavenZ planning session, not lessons already learned — the general principle behind several of them has already been folded into `TIMELINE_PITFALLS.md`/`LOCALIZATION_GUIDELINES.md`/`PIXEL_ART_GUIDELINES.md` in the shared folder; this list is the HavenZ-specific instance of each, roughly in order of how much it's worth worrying about:

1. **Audio is entirely unplanned.** The GDD never mentions sound; the Asset Audit only ever covered visual sprites. Phase 12.2 stubs audio as a TODO but nothing resolves it.
2. **No tutorial/onboarding design.** The GDD's SWOT calls "legible core tension" HavenZ's strongest differentiator, but legibility to a first-time player requires teaching it, not just telegraphing it well during play.
3. **Playtesting stays entirely internal.** Phase 9 and Phase 14 are the developer (plus "ideally one other person") — no step for outside players before the Next Fest push.
4. **The localization CSV is a stub nobody reads from.** S0.1 creates `strings.csv`, but no later session actually plumbs UI text through an id-lookup — currently dead scaffolding (see `LOCALIZATION_GUIDELINES.md`'s warning about exactly this pattern).
5. **No remote backup of the codebase.** `git init` is local-only everywhere in the roadmap — the same single-point-of-failure risk that lost Sheepshead's phase plan, applied to the code itself.
6. **No colorblind check on the palette scheduled.** Cheap once the real master palette exists (Phase 2.2) — see `PIXEL_ART_GUIDELINES.md` §4.
7. **No Steamworks integration plan.** Achievements, cloud saves, Steam Input/controller glyphs aren't mentioned despite the GDD being explicitly Steam-bound with wishlist targets — needs lead time (Partner account, App ID) that's easy to leave too late.
8. **No session-handoff convention.** With ~40 sessions across this roadmap, there's no lightweight running dev log — now addressed at the system level via `GODOT_LESSONS.md` #29 (`docs/SESSION_LOG.md`); HavenZ should adopt it once real sessions start.
9. **Input scheme is assumed, not designed.** Click/drag targeting is implied in the card UI sessions, but there's no explicit keyboard/controller decision — relevant for Steam Deck compatibility given the target platform.
