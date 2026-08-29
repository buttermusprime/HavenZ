<!-- Converted from HavenZ_Roadmap.html (the published Claude Code roadmap artifact) on 2026-08-25. -->
<!-- Faithful structural conversion, not a rewrite. If anything here looks off, treat the .html as source of truth until re-synced. -->

*Planning document — no code written · v18, card synergy open question added to GDD*

# HavenZ Development Roadmap

A session-by-session build order for the HavenZ GDD — resequenced so the riskiest, least-precedented system (noise-driven card economy) gets proven with zero art before anything else, and content breadth waits until one full vertical slice works end to end.

Godot 4.6 · GDScript | Tile-tactics deckbuilder | Single dev + Claude Code | Target: Winter Next Fest demo | 61 sessions (1 tentative) · 15 phases + POST | + PixelPipe (separate, upstream, own clock) | 6mo / $1k = flexible guardrails, not hard walls

> **What changed from v1.** A briefing doc distilled from 26 shipped games' postmortems reordered this plan: the art-import pipeline no longer comes first — a zero-art gray-box proving the noise+card-hand hook does. Zombie variety and the full card roster, previously mid-plan, moved to Phase 11 (after one enemy type and one vertical loop are validated). A dedicated rework gate (Phase 9) now sits between "the loop works" and "add content." See Lifecycle lessons applied for the full mapping.

> **Still true from v1.** §2.2/§3's "time pressure"/"turn clock" phrasing is still treated as a removed mechanic — Noise (§8) remains the only tension system this plan builds toward. The asset-pack/GDD mismatches from v1 (hunger meter, no Water card art, etc.) are now consolidated into the audit table below instead of being scattered through the phases.

> **What changed in v5.** The Aseprite/Godot/Claude Code pipeline (v2-v4's Phase 2) moved out into its own standalone project — [PixelPipe](https://claude.ai/code/artifact/6299ff45-f8a7-4dda-b1b7-1628b9d58237) — built and validated before HavenZ development starts, so it isn't rebuilt for whatever comes after HavenZ either. Phase 2 here is now five light "configure and run the tool" sessions instead of seven "build the tool" sessions. Sections referencing it are marked provisional until PixelPipe's own roadmap has actually been executed once.

> **What changed in v6.** Two things: a new Modular Systems Priority section tags four gameplay systems (card/deck engine, grid-signal propagation, data-driven enemy AI, persistent world-marker) as extraction candidates for whatever game comes after HavenZ, without extracting them yet. And nine planning gaps found outside the existing Asset Audit/Recommendations/Engineering Lessons sections got real sessions instead of staying a list: an audio audit + bus setup + tutorial pass, a colorblind check, external playtesting, native-Godot localization wired to real UI text, a Steamworks stub, a remote-git-backup and session-log habit, and an explicit input-scheme decision. 5 new sessions added (40 → 45).

> **What changed in v7.** Two clarifications and one new section. First: **PixelPipe's build time does not count against HavenZ's 6-month target** — the clock starts at Phase 0.1, not at the start of PixelPipe. Second: the SESSION_LOG.md from Phase 0.1 now tracks planned-vs-actual session counts per phase (not just narrative notes), rolled up in a new Phase 14.4 retrospective that feeds the shared cross-project learning system — so the next roadmap's estimates are calibrated against a real project, not just the 26-game external briefing. Third, a new Timeline & Budget SWOT section below records a risk analysis run against this plan, with the framing correction that matters most: **both the 6-month timeline and the $1,000 sales target are semi-flexible guardrails against scope drift and attention drift, not hard deadlines** — HavenZ is a hobby project, $1,000 is a cost-recoup goal rather than a survival one, and either target is worth extending for a big enough payoff. Read the SWOT's risk items in that light, not as a countdown.

> **What changed in v8.** Gamepad input graduated from "deferred" to fully locked-in, consolidated in a new Input Scheme section: a stick-driven virtual cursor with configurable sensitivity/deadzone/axis-inversion (session 4.2), A=click/play and B=back reserved exclusively for that role, X-or-Y=drop a card (exact button TBD in session 4.4), D-pad for both hand quick-switch and menu scrolling, hold-A-to-adjust for sliders, and a dedicated Menu-button pause system (new session 12.5, previously unplanned entirely). Also locked in: turns end when no card in hand is legally playable rather than on a fixed count, with Food/Water extending a turn — this is now built explicitly in session 4.4 and referenced by sessions 6.1 and 7.1. And the follow-camera got two real sessions instead of an implicit assumption: finalize-before-playtest (8.4) and improve-after-playtest (9.2). 4 new sessions (46 → 50).

> **What changed in v9.** v8's pause system (session 12.5) moved out of Phase 12 entirely, per direct experience on past projects: pause built late, after AI/state-machine code has already accumulated without pause-awareness, caused scene-loading bugs, broken NPC/AI logic, and inconsistent-on-resume state machines. Now split in two: **session 0.4** decides the `get_tree().paused` + explicit `process_mode` convention before any stateful system exists (new Engineering Lesson E8), and **session 8.5** builds the real pause menu during the vertical slice — tested against real zombie AI and the corpse/respawn flow — specifically so session 9.1's rework gate catches pause bugs while the codebase is still small. Session 12.3 comes back later only to wire the pause menu's Settings/Main-Menu buttons up once those screens are real. Net +1 session (50 → 51).

> **What changed in v10.** The Modular Systems Priority section now has three extraction tiers instead of two: Tier 1 (extract before use — PixelPipe), Tier 2 (tag now, extract right after first proof — new), Tier 3 (tag now, wait for a literal second project — the four existing gameplay-system candidates). **UI Shell** is the new Tier 2 entry: Main Menu, Settings, Pause, Save/Load, and the gamepad virtual cursor (sessions 0.4, 4.2, 8.5, 12.1, 12.3) are standardized enough across the industry that the abstraction risk is low, but still benefit from one real, shipped implementation to generalize from rather than being drafted from spec alone. New **session 14.5** pulls the proven code into its own addon repo right after Phase 12 ships — deliberately not deferred to a second game, and deliberately not pre-built standalone before HavenZ touches it either. 1 new session (51 → 52).

> **What changed in v11.** A separate design exploration of the noise mechanic (HavenZ_Noise_System_Design.md) was evaluated and folded in — new Noise System Design reference section, plus revisions across the sessions that touch it: concrete starting heat values now cited in 5.1/5.2/5.3, session 7.1's zombie pull rewritten from a binary threshold to a probabilistic roll (and now generates its own heat for free zombie-to-zombie chaining), session 6.1 gained the Dominion-model dilution rationale, session 8.3 now ties corpse retrieval risk to the new off-screen persistence system. Two new sessions for genuinely new mechanics: **7.3** (off-screen tile heat persistence + ambient repopulation — explicitly not keyed off elapsed turns, to avoid smuggling a timer back in) and **10.4** (day/night as a run-level layer above per-tile heat). **12.2** split in two: VFX/SFX stays, the noise/alert telegraph became its own **12.6** (ring + tile tint, with two hard accessibility requirements — independent toggles, independent sufficiency). Wildlife and rival-scavenger noise sources were evaluated and explicitly deferred — both already correctly scoped as post-MVP by GDD §9/§11, not decisions made fresh here. 3 new sessions (52 → 55).

> **What changed in v12.** A full self-audit pass — no new sessions, no scope changes, all corrections to cross-references, ownership gaps, and clarity. Renumbered the old session **12.6** to **12.5** to close the numbering gap left when v9 moved the pause system out of Phase 12 (every cross-reference below now reads 12.5). Assigned owners to two previously-orphaned art gaps: the Water/Purified Water card art (now explicitly commissioned in session 11.3) and the Supply Request ticket/board placeholder (now explicitly built in session 6.2). Gave the heat-event audio cue a home in session 12.2, closing the loop the Noise System Design's Open Question 03 raised but never assigned. Session 2.6's colorblind check is now explicitly scoped to palette hues (the only thing that exists at that point in the build), with a real re-check of the shipped ring/tint colors added to session 12.5 once they're actual on-screen elements. Extraction-candidate tag-chips now appear on every session named in a Modular Systems group, not just the first one in each group (added to 3.1, 7.3, 4.4, 8.2, 8.3); session 14.5's chip was relabeled from "UI Shell candidate" to "UI Shell extraction" since it's the payoff session, not a candidate awaiting one. Session 0.1's SESSION_LOG.md now tracks build vs. checkpoint/human-judgment sessions as a distinct column, and flags no-op-eligible sessions (9.2 explicitly logs its outcome there) so Phase 14.4's retrospective doesn't read a zero-code session as a missed estimate. Session 2.1 now opens with an explicit instruction to reconcile Phase 2's provisional prompts against PixelPipe's real Handoff doc before running anything, instead of relying on remembering to do that later. Session 12.1 gains a self-check pass exercising the full gamepad scheme end-to-end before being called done, since sliders are the last piece of that scheme to exist and nothing else in the plan tests the complete set before Phase 14's external playtest. Session 12.4 now explicitly considers whether first-time control prompts (not just the noise mechanic) belong in onboarding. Session 0.2 gets a one-line comment instruction at the CardResource.noise_cost → TileResource.heat handoff, since they're the same currency under two names for scope-minimization reasons, not an oversight. Session 14.5 now flags itself as likely undercounted as a single session. The SWOT's stale "46 sessions" weakness and the footer's stale compile date were also corrected. Session count unchanged at 55.

> **What changed in v13.** Folded in the new Testing Strategy section from the shared TESTING_STRATEGY.md at the cross-project Godot dev-notes folder (general-use, not written for HavenZ specifically) — a blast-radius classification for scoping which tests actually need re-running after a given edit, a test suite split by layer (`logic/`, `ui/`, `integration/`), and a one-line depends-on header convention. One new session: **0.5** establishes the folder split and documents the convention before any test file exists, the same "decide it before code accumulates against a different assumption" pattern session 0.4 already used for pause. Engineering Lesson E4 now cross-references it — E4 governs whether headless tests can be trusted at all, the new section governs which subset to run day-to-day, and neither replaces the other. Session 4.1, the first session to actually write a test, now names the real file path and header instead of "a small in-editor test... or sanity check," so the convention has a concrete first example rather than staying abstract. Sessions 9.1 and 14.3 — the vertical-slice go/no-go and the ship-packaging gate — now explicitly run the full suite regardless of how cosmetic recent edits looked, per the strategy's own explicit carve-out that checkpoints are the backstop against a wrong scoping call, not another place to scope. 1 new session (55 → 56).

> **What changed in v14.** Folded in a new design doc, HavenZ_Radio_System_Summary.md — a free, menu-based Portable Radio (5 volume tiers + Off, no turn cost, no card/inventory slot) that adds a card-play heat burst scaled by tier through the existing heat model, plus an independent randomized event timer (distress calls, supply drops, moment-of-silence) that only runs while the radio is on. Placed as horizontal-expansion scope, not vertical-slice scope — per the same Lifecycle Lesson 3 reasoning that moved zombie variety and the full card roster to Phase 11, this is genuinely new content, not part of proving the core loop, so it lands in **Phase 10** (new sessions **10.5**, the access/heat-burst core, and **10.6**, the event system), after Phase 9's go/no-go gate — not before it. One exception: the design doc itself asks for the volume-vs-heat tradeoff to be tuned "alongside base heat values" during gray-box prototyping, so **session 1.1** gained a lightweight debug-only heat-multiplier stand-in for early feel-tuning, separate from the real build. Session 10.6 resolves three things the source doc names but doesn't fully specify: what moment-of-silence actually references (tied to sessions 8.1/8.2), whether supply-drop loot can satisfy an active Request (session 6.2) or is bonus-only, and distress-call's actual mechanical payload, which the doc leaves undefined entirely. Explicitly confirmed this is not a reintroduction of the removed turn-clock — it's opt-in, player-controlled via volume, and only ever grants opportunities, never applies pressure on its own. The Noise System Design table gained a row for this new heat source; the Asset Audit's Audio table gained a row for the three event-announcement sound cues; the Modular Systems table's persistent-world-marker row now also cites 10.6, since reusing the corpse-marker grammar for a second in-project purpose is itself a small piece of evidence for that tag. 2 new sessions (56 → 58).

> **What changed in v15.** A round of dispositions on an early critique pass: (1) three people external to the primary developer now join session 9.1's go/no-go, not just Phase 14.1 — 9.1 and Phase 1.2 both also gain an explicit 3-attempts rule, so "iterate again" has a real endpoint. (2) Session 9.1's playtest checklist now explicitly watches for Scrap-heavy dead-turn hands and death-location manipulation of corpse-retrieval risk — both flagged as real but left as things to observe, not redesign preemptively. (3) The difficulty-scalar language in sessions 10.2/10.4/11.4 and Phase 10's own phase-goal corrected — this was always meant to be a small group of independently-tunable scalars, not one shared value; the old text was a documentation bug. (4) TileResource.heat's origin-tracking (session 0.2, referenced in 7.1/10.5) moved from a single overwritable `last_heat_origin` tag to a `this_turn_origins` set, since Phase 10 lets player/zombie/radio heat land on the same tile in the same turn. (5) Recommendation 08 corrected — GDD §15 has real content a prior parse missed, and §16's mislabeling is already fixed upstream; retracting the "still blank" claim. (6) Phase 13 now starts after Phase 9 confirms the vertical slice works, not at Phase 3. (7) Localization infrastructure stays in session 0.1 (cheap now, expensive to retrofit), but target-locale selection is explicitly deferred to real marketing signal, revisited in session 13.2. (8) Session 10.6 gained an explicit end-to-end verification pass, now including 3 real test songs, not just SFX cues. (9) New session **10.7** scales the Radio to its real full build — a minimum of 3 music stations at ~1 hour of real content each, plus an extended event roster — as Phase 10's second, larger-scale testing point; the Asset Audit's Music row is no longer an open scope question. (10) **Session 14.5 (UI Shell extraction) moves to a new post-launch section (POST.1)**, off the pre-ship critical path entirely — the UI Shell sessions (0.4/4.2/8.5/12.1/12.3) were always built extractable-by-design, so only the actual repo-split was ever waiting on timing, and it was never meant to make HavenZ itself depend on the extracted copy, the same non-goal PixelPipe already established. (11) A real early pace comparison against PixelPipe's and Sheepshead's actual build velocity, logged in the SWOT's Weaknesses. Net **+1 session (58 → 59)** within the pre-ship count — new session 10.7 — plus former session 14.5 relocated (not new) to POST.1, tracked separately outside the pre-ship total.

> **What changed in v16.** Two closing dispositions on the last open items from the critique pass. Steam Deck now gets a real but tentative marketing session — **13.4** — contingent on the cheap Deck-legibility check already noted in the Input Scheme section actually confirming viability; if that check fails, the session simply doesn't run. Not a committed dev-time line item, just tracked so the opportunity the SWOT flags doesn't fall through the cracks. Separately, a clarifying confirmation rather than a change: session 1.1's debug radio-heat-multiplier stand-in was correctly placed there all along — the Radio system needs real debugging validation at both ends of development, the early gray-box feel-check (1.1) and the full build (10.5–10.7), not just one; the earlier critique's "scope leak" framing was wrong. **+1 session (59 → 60, 1 of them tentative)**.

> **What changed in v17.** A design-improvement pass, synced with corresponding edits to the GDD itself (not just this document). GDD changes: removed the "No border = 0, Purple = 1 to Red = 6" hard 7-step noise scale and the per-phase noise-map flash/appear-disappear language — both artifacts of an earlier design; §7 and the Minute-to-Minute Chain now describe the noise overlay as a persistent diegetic tile tint, on by default and togglable off in Settings, matching what session 12.5 already builds. The GDD also now specifies how a dropped card gets re-salvaged: playing an Action (Looting) card on its landing tile, the same as any naturally-spawned loot — wired into sessions 4.4 and 5.3 here. Roadmap-only changes: session 12.2 gained an on-screen combo flasher for chained plays, giving the "momentum is a resource" pillar (GDD §3) a visible payoff. A new Design Recommendation **09** flags more emotional weight for the corpse system (e.g. a cause-of-death summary on the marker) as an open idea for whenever Phase 8 is real — not committed, not scheduled. Session 10.4's day/night cadence is no longer an open tuning question at the endpoints: sun starts setting ~20 minutes into a run, the zombie ring nearly reaches Home Haven by ~30 minutes, directly anchored to GDD §4's own 20-30 minute session-length target (the Noise System Design's open-question table updated to match). New session **13.0** refreshes GDD §14's market research right when Phase 13 actually starts, since real calendar time will have passed since it was compiled; session 13.2 now names the No More Noise/Project Zomboid differentiation angle explicitly instead of a general §14 pointer. A simple card-synergy concept for the "high combinatorics" pillar was discussed but deliberately not implemented yet — see the design-notes discussion for this version. **+1 session (60 → 61, 1 of them tentative)**.

> **What changed in v18.** The v17 card-synergy brainstorm now has a real home in the GDD, not just this document: a new "Open Design Question — Card Synergy" note appended to Design Pillars (§3) lists the three directions from that discussion (a flat same-category chain discount, a three-way Quiet→Aggressive→Loud posture cycle, and a minimal two-node version of it) as things to actually try, not committed design. Session 1.2's gray-box checkpoint now points at it directly — if an iteration attempt is close but not landing, trying a synergy rule against the abstract gray-box categories is explicitly cheaper than waiting until Phase 4's real card logic exists to find out it doesn't help. No session count change (61, 1 tentative) — this is content inside an existing checkpoint, not a new one.

> **What changed in v19.** Real development started 2026-08-25 — this revision syncs against the actual build for the first time via a new Session Status & Progress table below, the same convention PixelPipe and Sheepshead's own roadmaps already use. No session prompts were rewritten to match final implementation details — `docs/SESSION_LOG.md` remains the full narrative of what actually shipped and every deviation/bug found along the way; this table is a status layer on top, not a replacement. Current state: **Phase 0-2 complete** (12 of 61 pre-ship sessions), with one exception — **S2.4 is Deferred, not Done** (no real rendered art existed yet to tune against). S1.1 took 6 real sittings against direct playtest feedback before S1.2 passed on the first attempt. **Next: S4.3 (Hand UI).**

## START.00 — Session Status & Progress

_Real build status, synced 2026-08-29 from `docs/SESSION_LOG.md` and the repo's commit history — this table only, not the session prompts below, is updated as sessions land._

| Session | Title | Status | Date | Notes |
| --- | --- | --- | --- | --- |
| 0.1 | Project settings, git & repo hygiene | Done | 2026-08-25 | Pushed to origin/master; docs/ROADMAP.md added. |
| 0.2 | Core Resource class definitions | Done | 2026-08-26 | Also fixed a broken CSV translation import. |
| 0.3 | Audio bus setup | Done | 2026-08-26 | — |
| 0.4 | Pause architecture | Done | 2026-08-26 | — |
| 0.5 | Testing conventions | Done | 2026-08-26 | — |
| 1.1 | Gray-box the core loop | Done | 2026-08-27 | 6 real sittings — movement redesigned twice, a real range-check bug fixed. Full history in SESSION_LOG. |
| 1.2 | Playtest & go/no-go | PASS | 2026-08-28 | Go on the first real attempt. |
| 2.1 | Configure PixelPipe for HavenZ | Done | 2026-08-28 | Corrected two provisional-text mismatches (pixel_scale, ignore_globs). |
| 2.2 | Real palette extraction & reconciliation | Done | 2026-08-29 | 141-color master palette adopted. |
| 2.3 | Real pack conversion & sync | Done | 2026-08-29 | Found/fixed a real PixelPipe bug (116 palette-mode source PNGs exporting blank). |
| 2.4 | HavenZ palette tuning pass | **Deferred** | — | No real rendered art existed yet to tune against. Re-check triggers: real HP-colored UI, a zombie-adjacent scene. |
| 2.5 | Reskin the validated gray-box | Done | 2026-08-29 | Heat decay extended into real ring-based propagation. |
| 2.6 | Colorblind accessibility check | Done | 2026-08-29 | Named groups clean; two forward-looking findings flagged. |
| 3.1 | Haven placement & wall/entrance tiles | Done | 2026-08-29 | Found/fixed a real heat-bleed-through-wall bug (only the final target's flag was ever checked, not tiles in between); player movement and zombie pathing both now enforce walls too. |
| 3.2 | World set-dressing & biome zones | Done | 2026-08-29 | Substituted the real HVAC_Overgrown_Green/Bleak-Yellow tint for the roadmap's imprecise "beige/gray/dark buildings" text — no such 3-way shell tint exists in the pack. |
| 4.1 | Deck / hand / draw-pile data | Done | 2026-08-29 | Resolved a real conflict between this roadmap's own drop-replenish summary and GDD §7's explicit no-replenish-on-drop rule, in the GDD's favor. First real committed test file (deck_test.gd). |
| 4.2 | Gamepad virtual cursor system | Done | 2026-08-29 | A/B route through real push_input() mouse-button events, not a bespoke signal pair. Second real test file (scripts/tests/ui/). |
| 4.3 | Hand UI | Not Started | — | — |
| 4.4 | Play/drop resolution branch | Not Started | — | — |
| 5.1 | Movement cards — Stealth & Loud | Not Started | — | — |
| 5.2 | Melee Attack cards | Not Started | — | — |
| 5.3 | Looting, Trap & Distraction cards | Not Started | — | — |
| 6.1 | Supply cards | Not Started | — | — |
| 6.2 | Supply Request loop | Not Started | — | — |
| 6.3 | Crafting sub-loop | Not Started | — | — |
| 7.1 | Base zombie & noise pathing | Not Started | — | — |
| 7.2 | Combat resolution & death trigger | Not Started | — | — |
| 7.3 | Off-screen tile persistence & ambient repopulation | Not Started | — | — |
| 8.1 | Corpse marker | Not Started | — | — |
| 8.2 | Respawn & card inheritance | Not Started | — | — |
| 8.3 | Corpse decay & recovery | Not Started | — | — |
| 8.4 | Camera follow finalization | Not Started | — | — |
| 8.5 | Pause system (core + minimal UI) | Not Started | — | — |
| 9.1 | Play the full loop & decide | Not Started | — | — |
| 9.2 | Camera improvements from playtest feedback | Not Started | — | — |
| 10.1 | Trade/Craft Haven menu | Not Started | — | — |
| 10.2 | Difficulty ramp | Not Started | — | — |
| 10.3 | Starting-loadout progression | Not Started | — | — |
| 10.4 | Day/night pressure layer | Not Started | — | — |
| 10.5 | Portable Radio: access & heat-burst core | Not Started | — | S1.1's debug radio multiplier already gave this an early feel-check. |
| 10.6 | Radio events: distress calls, supply drops & moment-of-silence | Not Started | — | — |
| 10.7 | Radio full buildout: music stations & extended events | Not Started | — | — |
| 11.1 | Action card roster | Not Started | — | — |
| 11.2 | Movement card roster | Not Started | — | — |
| 11.3 | Supply roster & recipes | Not Started | — | — |
| 11.4 | Zombie variety | Not Started | — | — |
| 12.1 | Difficulty / accessibility settings | Not Started | — | — |
| 12.2 | Audio/VFX pass | Not Started | — | — |
| 12.3 | Main menu & save/load | Not Started | — | — |
| 12.4 | First-run tutorial / onboarding | Not Started | — | — |
| 12.5 | Diegetic heat display (ring + tile tint) | Not Started | — | Re-runs S2.6's colorblind check against real rendered colors. |
| 13.0 | Refresh market research | Not Started | — | — |
| 13.1 | Start the devlog now | Not Started | — | Starts once Phase 9 confirms the vertical slice works. |
| 13.2 | Steam page & press-kit copy | Not Started | — | — |
| 13.3 | Steamworks integration stub | Not Started | — | — |
| 13.4 | Steam Deck marketing angle | Not Started | — | Tentative — contingent on the Deck-legibility check passing. |
| 14.1 | External playtest round | Not Started | — | — |
| 14.2 | Playtest & balance pass | Not Started | — | — |
| 14.3 | Demo packaging | Not Started | — | — |
| 14.4 | Retrospective & metrics rollup | Not Started | — | — |
| POST.1 | Extract the UI Shell | Not Started | — | Post-launch, not counted in the 61. |

**16 of 61 pre-ship sessions done, 1 deferred, 44 not started** (plus POST.1). Real elapsed time: 5 active calendar days (2026-08-25 through 2026-08-29), 28 commits, 21 real working sittings against those 16 sessions.

## START.01 — Lifecycle Lessons Applied

_Mapped from the briefing doc's 7-stage studio lifecycle (26 shipped games, indie hits to AAA failures) directly onto what changed in this roadmap._

| Lifecycle stage | Lesson from the field | What changed here |
| --- | --- | --- |
| **1. Concept validation** | Hardest failures (Concord, Suicide Squad) had no distinct hook; hardest successes (Vampire Survivors, Balatro) proved theirs in days, with no art. | New **Phase 1**: a squares-and-numbers gray-box of the noise+card-hand loop, before any art import. If it isn't compelling here, stop and redesign before Phase 2. |
| **2. Pre-production** | Indie successes reuse one strong mechanic deeply; AAA failures (Anthem, Cities: Skylines II) started content before systems were validated. | Phase 0 locks `CardResource`/`TileResource`/`EnemyResource` before anything is built on top of them. Noise/zombie-attraction is treated as the single highest-risk system and validated alone in Phase 1. |
| **3. Full production** | Larian's tooling/iteration discipline shipped huge systems on schedule; Marvel's Avengers' production didn't match its actual (live-service) structure. | Zombie variety (was Phase 5) and the full card roster (was Phase 8) both moved to **Phase 11**, after the single-enemy-type vertical slice (Phases 5–8) proves out — content breadth is horizontal expansion, not part of validating the loop. |
| **4. Alpha playtesting** | Concord/Suicide Squad shipped known core-loop problems anyway because fixes felt too late; Among Us/Vampire Survivors spent real time debugging feel pre-breakout. | New **Phase 9**: a dedicated go/no-go rework gate on the vertical slice, separate from Phase 14's tuning-only pass. Negative signal on card economy/noise pacing/death-recovery feel is explicitly non-negotiable to act on here, now joined by 3 playtesters external to the primary developer, recruited specifically so the go/no-go isn't judged on solo signal alone — Phase 14.1 remains a second, larger external round against the full content roster. |
| **5. Marketing / launch prep** | Balatro/Dave the Diver built wishlist momentum for months pre-launch; Concord had almost none. | New **Phase 13**, explicitly a parallel calendar track starting once Phase 3 makes the game look real — not a final-weeks task. |
| **6. Post-launch support** | No Man's Sky recovered via sustained, well-scoped updates; Suicide Squad over-committed to a season cadence it couldn't support. | Not a phase — an operating principle for after Phase 14: extend via existing systems (new cards/Havens/supply types), don't publish a dated content roadmap. |
| **7. Structural advantage** | Concord, Redfall, Suicide Squad, Anthem all failed or were abandoned as live-service commitments outran their playerbase. | Scope guardrail carried in Phase 0's intro: single-player, one platform (PC/Steam), no server/online dependency, ever. |

## START.02 — Asset Audit

_PostApocalypse_AssetPack_v1.1.2 is built for a real-time survival shooter, not a turn-based tile-tactics deckbuilder. Most of it transfers cleanly; this is everything that doesn't, sorted into what to draw and what to leave alone._

### What you need to draw or commission

| Priority | Asset | Why it's missing / needed | Workaround until then |
| --- | --- | --- | --- |
| High | Water / Purified Water supply card (world sprite + inventory icon, 2 tiers) | §10.8 has zero supporting art. Food has two tiers (`Canned-food`, `Canned-soup`); Water has nothing comparable. | Placeholder icon through Phase 6-10 — session 11.3 is the explicit commit point for drawing the real asset, not indefinitely deferred. |
| High | Noise ring/pulse sprite (a few Aseprite frames, expanding fading outline) — the tile tint needs no new art, just a shader/modulate effect on existing tiles | The pack has no detection/telegraph UI anywhere, yet GDD §14.4's own SWOT calls "visible noise, telegraphed zombie moves" HavenZ's single strongest differentiator. Full design in the Noise System Design section. This is the one system backing the game's core hook with zero art. | Debug color-overlay only (Phases 1-2) — needs the real ring+tint pair (session 12.5) before any playtest that isn't you. |
| Medium | Supply Request "ticket"/board visual at Home Haven | No bulletin-board/request-slip art exists; this is the central hook of the game and currently has no dedicated presentation. | Resolved as part of session 6.2 — the Crafting UI cell art reuse is the actual MVP presentation, not a placeholder waiting on a later session. A bespoke board asset is optional post-MVP polish. |
| Low | First Aid Kit field pickup sprite | `Icon_First-Aid-Kit_*` exists in the UI icon set; no matching world sprite in `Objects/Pickable/`. | Reuse `Bandage.png` world sprite for both Medical tiers. |
| Low | Card frame / border art | The pack is entirely world/icon art — zero trading-card UI anywhere in it. | Plain programmer-art `StyleBoxFlat` panel is enough for MVP (Phase 4). |
| Low | Corpse direction-compass icon | No dedicated compass/arrow asset exists. | Reuse/rotate `Crafting_Arrow.png` (Phase 8). |
| Low | "Home Haven" distinguishing marker | Entrance-tile art has palette variants but nothing marks "this one is yours" vs. other Havens. | Reserve one palette tint (e.g. Green) exclusively for the Home Haven. |

### What to ignore or deprioritize

| Asset group | Why it doesn't fit / isn't needed |
| --- | --- |
| Multi-stage reload choreography (Shotgun's 4-part reload + racking sheets) | Real-time-shooter second-by-second animation. Turn-based card resolution needs at most one "reloading" pose, not a racking sequence — skip the granular frames. |
| `UI/Hunger/` meter | A continuously-depleting meter conflicts with §10.7–10.8's one-shot consumed-card model. Hide for MVP, or repurpose the bar visual for something that actually is continuous (see Recommendation 03). |
| Rain/puddle weather animation (`Downspout_Rainwater`, `Rain-drop-splash`) | Pure ambience, not mentioned anywhere in the GDD. Shelve as optional post-MVP atmosphere. |
| Full vehicle recolor matrix (6 colors × 3 wear states × 9 car types) | Not wrong, just excessive — pick 1–2 colors per car type for MVP to cut import/decision overhead. The rest is free variety to reach for later, not a day-one requirement. |
| Helmet character skin (own Idle/Punch/Pickup/Death sheets) | No armor/equipment system exists in the GDD. Don't build one to use it — reserve it as a free visual unlock for a later starting-loadout tier instead (see Card Roster / Recommendations). |

### Audio — a gap the pack never covered at all

_The Asset Audit above only ever covered visual sprites because that's all PostApocalypse_AssetPack_v1.1.2 contains. The GDD itself never mentions sound anywhere — no music, no SFX, no ambience. Nothing above should be read as "audio is fine"; it was simply out of scope until now._

| Priority | Need | Why | Interim plan |
| --- | --- | --- | --- |
| High | Core SFX set (footsteps, card play/draw, zombie hit/death, melee/ranged attack) | Without these, the ring/tint heat-telegraph work in Phase 12.5 has nothing audible backing the visual telegraph — noise as a mechanic is easier to read when it's also heard. Session 12.2 now owns building the actual heat-event cue that closes this gap. | Source free/CC-licensed SFX packs first (itch.io, freesound.org, respecting §11's no-AI-art spirit for audio too); commission only what's still missing. |
| Medium | Ambient loop(s) — wind, distant groans, city hum | Cheap atmosphere for a game whose whole hook is tension; currently the world would be silent. | One loop is enough for MVP; per-biome variants (matching the Green/Bleak-Yellow zones from Phase 3.2) are a post-MVP nice-to-have. |
| Medium | Radio event-announcement cues (distress call, supply drop, moment-of-silence — 3 short bytes) | Session 10.6's event system announces each fire with a sound cue before the nav marker appears; none of these exist in the pack or anywhere else in the Audio table. | Same free/CC-licensed sourcing pass as the Core SFX set row above; no new visual asset needed since the marker itself reuses session 8.3's compass grammar. |
| Medium | Radio station music — 3 test songs, then a minimum of 3 full ~1-hour station loops | No longer an open scope question as of the Radio system's full buildout decision (session 10.7) — committed content, not an optional in-run bed. | Source or compose 3 short test tracks for session 10.6's verification pass (same free/CC-licensed sourcing pass as the Core SFX row); commission/curate the full station loops for session 10.7. |

## START.03 — Color Palette (extracted from the pack)

_Sampled directly from ~24 representative sprites already in PostApocalypse_AssetPack_v1.1.2 (character, zombies, both nature biomes, building/brick/roof tiles, vehicles, hazard props, and UI) — not invented. A 40-color `.gpl` file and a matching swatch PNG are provided alongside this roadmap for Aseprite (File → Palette → Import Palette, or File → Open the PNG then Sprite → Color Mode → Indexed)._

> **This is a seed sample, not the final palette.** 24 files out of the pack's ~1,100 is enough to find real patterns (see below) but not enough to guarantee full coverage — there are almost certainly colors elsewhere in the pack, including some of the "weird" ones worth fixing, that this sample missed. A full extraction across every file happens once — using the standalone PixelPipe tool, not custom code inside this project — before anything gets locked in as the master palette the rest of the pipeline builds on.

> **What the sampling found.** The pack already runs on one unified palette, not per-object color choices: the same warm red family (`#984850`/`#782838`/`#582838`) shows up in brick, rust, *and* hazard barrels/hydrants — brick and danger read as the same color on purpose. The same sickly green (`#A0C098`) appears as both a zombie highlight and a leaf highlight, quietly tying the undead to the environment. Keep reusing colors across categories the way the source art already does, rather than picking a fresh color per new card/prop.

**Ink & Shadow (near-universal outline)**
- Ink Outline — `#302038`
- Void Shadow — `#301020`
- Soft Shadow — `#484058`

**Survivor**
- Skin Light — `#E8C0B0`
- Skin Shadow — `#B88890`
- Leather Brown — `#705048`
- Hair Shadow — `#483030`
- Clothing Navy — `#404050`

**Undead**
- Zombie Flesh — `#688080`
- Flesh Shadow — `#506068`
- Sickly Green — `#A0C098`
- Bruise Mauve — `#A09098`
- Bat Fur — `#A0A0A8`
- Old Blood — `#603848`

**Green Zone (wilds)**
- Leaf Highlight — `#78A088`
- Ground Base — `#709888`
- Ground Mid — `#80A080`

**Bleak Wastes**
- Dry Highlight — `#B0B088`
- Dust Tan — `#A09870`
- Dead Brown — `#806060`
- Wastes Shadow — `#503040`

**Concrete & Masonry**
- Concrete Grey — `#808088`
- Concrete Shadow — `#606068`
- Warm Highlight — `#C0A098`

**Brick, Rust & Hazard (one shared warm-red family)**
- Rust Red — `#984850`
- Brick Red — `#782838`
- Brick Shadow — `#602840`
- Deep Rust — `#582838`
- Dark Brick — `#482838`

**Metal**
- Chrome Highlight — `#D0C8C8`
- Dull Steel — `#605050`
- Cool Metal — `#585070`

**UI — Vitality & Sustenance**
- HP Red — `#B05058`
- HP Shadow — `#902840`
- Hunger Tan — `#886050`
- Hunger Shadow — `#704848`

**UI — Parchment**
- Paper White — `#F8F8F8`
- Parchment — `#C0B8A0`
- Parchment Shadow — `#B8B098`
- Panel Slate — `#686070`

## START.04 — Engineering Lessons (from Sheepshead)

_Real Godot 4.6 + Claude Code gotchas hit while building the Sheepshead card game, generalized and wired into specific sessions below rather than left to be rediscovered._

**E1 — Use `ResourceLoader.list_directory`, never `DirAccess`, for any folder scan that must survive export**

`DirAccess` returns files under their internal `.import` stub name in exported builds — confirmed to silently break folder-based asset scanning. Directly relevant to **PixelPipe's D.3** art-validation tool (built once, used by HavenZ and any future project) and any later HavenZ system that enumerates a folder of `.tres` cards/enemies/tiles at runtime.

**E2 — Lock one canonical pixel-scale factor before importing mixed-resolution art**

Sizing a display box to "match" another element without deriving it from native resolution × a shared scale factor produces mismatched sprites ("mixels"). HavenZ mixes 16px characters with much larger vehicle/building tiles — this is a real risk, not a hypothetical one. **Two separate scale factors are involved, not one:** the display/render scale (screen pixels per logical-tile pixel) is already locked in **S0.1** via the 512×288 viewport + `canvas_items`/`integer` stretch mode, independent of PixelPipe entirely. PixelPipe's own `pixel_scale` config field (locked in **Phase 2.1**) is a narrower, unrelated art-hygiene check — every exported PNG's dimensions must be a clean multiple of it — and turned out to be `1` for this pack, since its sprites are irregularly cropped to content bounds rather than aligned to a shared grid. Structural guidance also lives in PixelPipe's own Build Guideline 01.

**E3 — GDScript lambdas capture outer variables by value, not reference**

Mutating a plain scalar from inside a closure never reaches the outer scope; wrap shared state in a `Dictionary`/`Array` instead. Watch for this in **Phase 1.1**'s noise-decay tick and **Phase 4.4**'s play/drop resolution callbacks.

**E4 — A passing headless test is necessary, not sufficient**

Real click hit-testing, rendering, and some packed-scene signal wiring can pass every editor/headless check and still fail only in an exported build. Verify against a real export periodically through production (not only at **Phase 14.3**) — especially after Phase 2's import tooling and Phase 11's roster-scanning sessions. See the Testing Strategy section for which subset of automated tests to run after a given edit day-to-day — this lesson is about whether headless tests can be trusted at all, not which ones to scope in or out; the two questions are independent.

**E5 — Commit this roadmap into the repo, not just this artifact**

Sheepshead's original phase plan was lost — referenced in code comments but never located afterward. Save this document as `docs/ROADMAP.md` in the HavenZ repo during **Phase 0.1**'s first commit.

**E6 — Local git alone is still a single point of failure**

E5 fixes "the roadmap is only in chat/Downloads" — the same risk still applies to the actual codebase if `git init` is never followed by a push to a remote. **Phase 0.1** now includes pushing to a private remote immediately, not just initializing locally.

**E7 — A running session log prevents the exact confusion E5 is fixing, at a smaller scale**

Sheepshead's "what did Phase 9 and Phase 14 actually mean" problem happened because nothing recorded session-to-session intent. With 40+ sessions planned here, **Phase 0.1** also creates `docs/SESSION_LOG.md` — every session appends what shipped, what's stubbed, and what's next, in a couple of sentences, before ending.

**E8 — Decide the pause convention before any stateful system exists — building pause late means retrofitting it onto code that never expected it**

Reported directly from past projects: a pause system added after AI/state-machine code has already accumulated caused scene-loading bugs, broken NPC/AI logic, and state machines left in inconsistent states on resume. **Phase 0.4** decides the `get_tree().paused` + explicit `process_mode` convention before Phase 1's gray-box even exists, and **Phase 8.5** builds the real pause menu during the vertical slice — tested against real zombie AI and the corpse/respawn flow — specifically so Phase 9's rework gate catches pause bugs while the codebase is still small, instead of Phase 12 discovering them against the full roster.

## START.05 — Pixel Art Pipeline

_This used to be a HavenZ-internal build-out (v2/v3 of this roadmap). It's now a separate, standalone tool — [PixelPipe](https://claude.ai/code/artifact/6299ff45-f8a7-4dda-b1b7-1628b9d58237) — built in its own project, before HavenZ dev starts, so it can serve HavenZ *and* whatever comes after it. This section is now just what HavenZ needs to know to consume it._

> **The core idea — one pipeline, not two.** Every sprite in the game, whether it originated in the purchased asset pack or was drawn from scratch, ends up as an `.aseprite` source file in the same `res://art_source/` tree, exported by the same PixelPipe command, checked by the same validation tool. Godot never touches a `.aseprite` file, and nothing downstream needs to know or care which pipeline a given sprite came from. Making that true is PixelPipe's job, not HavenZ's — HavenZ's revised Phase 2 (below) is just configuring and running it against this project's real assets.

> **This section is provisional.** Exact config field names, command syntax, and the addon's file layout will only be final once PixelPipe has actually been built — see its own roadmap's Handoff section. Revisit HavenZ's Phase 2 sessions once that's done; treat anything here as "the shape of it," not a locked spec.

### What HavenZ provides to PixelPipe

| HavenZ-side location | What it is |
| --- | --- |
| pixelpipe.config.json (in the HavenZ repo) | Points PixelPipe at res://art_source/, res://art/, the haven-z/ Godot project root, HavenZ's active palette, and the locked pixel-scale constant |
| PostApocalypse_AssetPack_v1.1.2 (unzipped) | The raw input to PixelPipe's palette extraction + conversion — HavenZ never hand-processes it |
| Any hand-drawn .aseprite files | Authored directly in res://art_source/, same as pack-derived files after conversion — no HavenZ-specific handling needed |

### What PixelPipe hands back

| HavenZ-side location | What it is |
| --- | --- |
| res://art/**/*.png + *.json | Generated sprite sheets + frame/tag/slice metadata — never hand-edited, regenerated by PixelPipe's sync command |
| haven-z/addons/pixelpipe/ | The SpriteFrames-from-JSON importer, the palette-remap shader, and the validation EditorScript — installed once, not rebuilt per project |
| res://data/*.tres | CardResource/EnemyResource entries pointing at the generated PNGs — still written by Claude Code, per the usual session prompts |

### Recommendations (still HavenZ-specific)

**P1 — Draw new HavenZ assets in Indexed color mode against the project's active palette**

Set new `.aseprite` files to Sprite → Color Mode → Indexed with HavenZ's palette loaded. This makes off-palette colors physically impossible to paint by accident — enforcing, going forward, the same shared-color-family discipline the original asset pack already follows (see the Color Palette section's "what the sampling found" note).

**P2 — One file per entity, Tags for states — not one file per state**

The purchased pack ships one PNG per animation state (`Zombie_Small_Down_Idle-Sheet6.png`, `..._Walk-Sheet6.png`, etc.) because that's how it was sold — PixelPipe's conversion preserves that shape for pack-derived assets, but anything HavenZ draws from scratch should keep Idle/Walk/Attack/Death as Tags inside a single `.aseprite` file per entity instead.

**P3 — Fix one export preset and reuse it for every HavenZ asset**

Aseprite's sprite-sheet export dialog remembers padding/trim/packing settings per use — lock one configuration the first time PixelPipe exports something HavenZ-specific and reuse it, so sheet conventions stay uniform across the whole game, the same way GDD §13 asks for consistent naming everywhere else.

## START.06 — Modular Systems Priority

_HavenZ isn't the only game planned — more are coming after it, which changes the payoff math on anything built here that's even plausibly reusable. PixelPipe is the precedent; these are the next candidates._

> **The rule this still follows — now in three tiers, not two.** "More games are coming" lowers the bar for *flagging* a candidate, not for *extracting* it — but not every candidate waits the same length of time. **Tier 1, extract before use:** tooling with zero gameplay-design risk (PixelPipe) — the right shape doesn't depend on what game you're making, so there's nothing to prove first. **Tier 2, tag now / extract right after first proof:** infrastructure whose shape is genre-agnostic and industry-standard enough that the risk of guessing wrong is low, but which still needs one real, concrete implementation to generalize from rather than being drafted from spec alone (the UI Shell, below). **Tier 3, tag now / wait for a literal second project:** gameplay systems whose right abstraction genuinely isn't knowable until built against something twice — HavenZ's own noise-propagation mechanic might need something a second game wouldn't.

| System | Tier | Home session(s) | Why it's a candidate |
| --- | --- | --- | --- |
| UI Shell (menus, settings, pause, save, gamepad cursor) | 2 | Phase 0.4, 4.2, 8.5, 12.1, 12.3 | Main Menu → Settings → Pause → Save is one of the most standardized patterns in all of game dev — low abstraction risk, unlike a genre-specific mechanic. The stick-to-cursor layer (4.2) alone makes any mouse-driven Control UI gamepad-navigable for free. Extraction deliberately moved to post-launch (POST.1), not squeezed into the pre-ship critical path — sessions 0.4/4.2/8.5/12.1/12.3 are still built extractable-by-design throughout, so the code itself was never waiting on this session, only the actual repo-split was. Same non-goal as PixelPipe's role: this exists to serve whatever project comes after HavenZ, not to make HavenZ itself depend on the extracted copy. |
| Card/deck engine | 3 | Phase 0.2, Phase 4 | CardResource + Deck/Hand/Discard + the play/drop resolution branch is the skeleton of any deckbuilder, tile-tactics or not. |
| Grid-signal propagation (heat) | 3 | Phase 2.5, 3.1, 7.1, 7.3 | The Noise system's per-tile "heat" value, generalized, is "a value that bleeds to neighbors at a decaying fraction, pauses decaying while actively generated, and is blocked by a wall flag" — the same shape as stealth-game sound, fire/gas spread, or fog of war. See the Noise System Design section for the concrete parameters this was built against. |
| Data-driven enemy AI | 3 | Phase 7.1 | EnemyResource + one shared pathing function specialized per type is a pattern, not a zombie-specific thing. |
| Persistent world-marker system | 3 | Phase 8.1–8.3, 10.6–10.7 | Spawn a marker holding state at a location, decay it over time, let the player recover it — generalizes past "corpse" into any breadcrumb/cache/checkpoint mechanic. Session 10.6 reuses the exact same marker grammar for the radio's event system, extended further by 10.7's larger event roster — a second in-project use before a second game, which is itself a small piece of evidence for this tag. |

> **Already extracted, for scale.** PixelPipe is the Tier 1 worked example: identified as reusable before any HavenZ-specific art-pipeline code existed, and pulled into its own repo immediately because tooling carries none of the "prove it twice" risk gameplay systems do.

## START.07 — Timeline & Budget SWOT

_A risk read on this plan against two targets: finishing in ~6 months without exceeding usage budget, and reaching $1,000 in Steam sales. Read this against the framing below, not as a countdown._

> **How to read this.** Both targets are semi-flexible guardrails, not hard walls. The 6-month window exists to limit scope and keep this project from drifting into a different one — not a business deadline. The $1,000 figure is a cost-recoup goal for a hobby project (Claude usage + assets), not something anyone is financially dependent on. Either is worth extending for a big enough payoff. The Threats/Weaknesses below are real structural risks worth knowing about, not reasons to panic or rush.

#### Strengths

- **Scope discipline is structural, not aspirational.** Gray-box-first, the Phase 9 rework gate, vertical-slice-before-horizontal — all exist specifically to catch a bad concept or broken loop cheaply, before it's expensive to fix.
- **Art cost is mostly solved.** PixelPipe unifying the purchased pack means very little new art needs hand-drawing or paying for.
- **Marketing starts mid-build, not post-launch.** Phase 13 running in parallel from Phase 3 onward directly targets the wishlist-momentum lever the GDD's own market research says matters most.
- **The workflow is proven, not a first attempt.** Small-scoped, one-system-per-session Claude Code work on a Godot project already worked once (Sheepshead).

#### Weaknesses

- **56 sessions understates real usage.** Sheepshead's own history shows bugs and engine gotchas that took multiple rounds, not one session each — the planned count is a floor.
- **Early pace check (v15, 2026-08-05).** PixelPipe: 13/20 sessions in 3 days, ~4+/day, clean one-pass. Sheepshead comparable: similar row-pace but 2-3x real rounds on UI/feel sessions (portrait creator, tutorial). Blended estimate for HavenZ: ~2-3 months elapsed + PixelPipe's ~1 week, comfortably inside the 6-month guardrail. Expect this to bend hardest in Phase 12 (Sheepshead's own heaviest-iteration territory) and around 9.1/14.1's open-ended human-paced gates.
- **No slack is budgeted anywhere.** All 15 phases run forward-only; one stubborn bug has nowhere to absorb into before a self-imposed deadline.
- **Per-session cost likely rises late.** Phase 11/12 sessions load a much larger existing codebase each time than Phase 0/1 did — flat session count doesn't mean flat usage cost.
- **Checkpoints are open-ended by design.** Phase 9 and 14.1 could mean "proceed" or "redo three phases" — that's the right call to make, but it's not a fixed-cost step.

#### Opportunities

- **PixelPipe's cost is shared, not sunk into HavenZ alone** — if a next project follows soon enough to actually reuse it.
- **$1,000 is a genuinely low bar for this genre** — the GDD's own market research cites niche successes clearing far more on smaller audiences. Likely the easier of the two targets, if the game ships at all.
- **The metrics rollup (Phase 14.4) pays forward** — the next roadmap's session estimates get calibrated against a real project instead of a 26-game external sample.
- **Steam Deck fit may be cheaper than expected** — see the input-scheme note below; worth revisiting specifically as a sales lever, not just UX. Now a tentative marketing session (13.4), contingent on that check confirming viability, not a committed line item.

#### Threats

- **Steam sales are unpredictable regardless of execution.** The GDD's own SWOT cites a review-bomb sinking a strong-pedigree comp — no roadmap controls launch-day algorithmic visibility.
- **Calendar hours, not usage credits, are probably the real bottleneck** — checkpoints, playtest recruiting, marketing copy, and Steamworks paperwork are all human time on top of Claude Code time.
- **PixelPipe sits upstream of all HavenZ art.** A stall there (an Aseprite CLI/version mismatch, the kind of thing that hit Sheepshead repeatedly) delays everything downstream of it.
- **This is a genuinely novel mechanic combination** — good for differentiation, bad for schedule predictability, since Phase 9 exists precisely because this can't be estimated from a comparable game.

> **Bottom line.** $1,000 in sales is probably the more achievable target on its own — it's a low bar in this genre and the marketing sequencing is unusually disciplined for a solo project. The 6-month/no-overage timeline is the one under real pressure, not because the plan is undisciplined but because PixelPipe's build sits in front of the clock, no phase has slack, and per-session cost likely climbs late. Per the framing above, that's an acceptable risk to hold consciously, not a reason to cut scope preemptively — extend either target if something mid-build turns out to be worth the extra time.

## START.08 — Input Scheme

_Gamepad support graduated from "deferred" (v6) to a fully locked-in, first-class scheme in this pass — consolidated here since it's referenced across half a dozen sessions._

| Interaction | PC | Gamepad | Built in |
| --- | --- | --- | --- |
| Cursor movement | Mouse | One stick, with configurable sensitivity, deadzone, and independent per-axis inversion | Session 4.2 |
| Click / confirm | Left click | A | Session 4.2 |
| Back / cancel | Right click or Esc, context-dependent | B — reserved exclusively for back/cancel, never overloaded | Session 4.2 |
| Play a hand card | Left click | A | Session 4.4 |
| Drop a hand card | Right click | X or Y — exact button decided during session 4.4, record the choice here once picked | Session 4.4 |
| Quick-switch focus between hand cards | Hover | D-pad left/right | Session 4.3 |
| Scroll a menu list (crafting, trade) | Mouse wheel / scrollbar | D-pad up/down | Sessions 6.3, 10.1 |
| Adjust a slider | Drag | Hold A over the slider to switch the stick from cursor movement to value adjustment; release A to resume cursor control | Session 12.1 |
| Pause | Esc (or equivalent) | Menu/Start button — deliberately separate from A/B so it's never ambiguous with in-context cancel | Sessions 0.4 (rule), 8.5 (core+minimal UI), 12.3 (wired to real Settings/Main Menu) |
| Camera | None — automatic follow-cam | None — automatic follow-cam | Sessions 8.4, 9.2 |

> **The turn-end rule, since it's load-bearing for the input scheme too.** A player's turn isn't a fixed one-card allotment — it ends automatically once no card remaining in hand is legally playable (built in session 4.4). Food/Water Supply cards (session 6.1) extend a turn by granting extra Action/Movement plays, so a well-stocked, lucky hand can chain several plays — meaning "how many times will A get pressed this turn" is itself variable, not fixed, and the zombie/world turn (session 7.1) only fires once that chain runs out.

> **Steam Deck note, carried over from the prior review.** Deck's default Steam Input behavior emulates a mouse via its trackpads for games with no declared controller support, which may cover basic play acceptably with zero extra code beyond what's here — the open risk is UI legibility at Deck's 1280×800/16:10 screen, not input mapping. Still not a scheduled dev session; verify cheaply (windowed-resolution testing on the dev PC) before deciding whether it needs one. If that check passes, session 13.4 is where the marketing angle gets drafted — tentative, and contingent on this verification, not committed up front.

## START.09 — Noise System Design

_Evaluated and folded in from a separate design exploration (HavenZ_Noise_System_Design.md, draft/pending GDD review). This is a quick-reference for the sessions that implement it, not a copy of the full source doc — read that directly for the reasoning behind each number._

> **Evaluation: this holds up, and reinforces discipline already in the roadmap.** It doesn't reintroduce a timer — it explicitly rejects keying anything off "turns since the player left" as a hidden clock in disguise, the exact thing this whole plan was built to avoid. The probabilistic zombie pull is a real improvement over the roadmap's original binary-threshold framing (Phase 7.1, revised below). The diegetic ring/tint display sharpens what Phase 12's noise/alert session already vaguely scoped. Adopted into the roadmap below, with three deliberate exceptions.

> **Three things deliberately NOT adopted for MVP, and why.** (1) **Wildlife noise sources** (crows, dogs, rats) — the design doc flags this as an open "MVP or post-launch?" question; it's already answered by the GDD itself, which lists "Pets or Wild Animals / NPCs making additional noise" under §9 Future Possible Systems, not MVP. No wildlife art exists in the pack either. (2) **Rival scavengers** — the design doc marks this "future/optional" itself, and it conflicts with GDD §11's "No NPC dialogue or characters beyond a simple trade/craft menu" scope restriction. (3) **Zombie-to-zombie heat chaining**, by contrast, *is* adopted for MVP — it needs no new art, reuses the same origin-tagged heat data the player's own actions already write to, and directly serves the "compounding risk" tension the whole system exists to create (session 7.1, revised below).

### Starting parameters (tune during Phase 14 playtesting, not before)

| Parameter | Starting value | Home session |
| --- | --- | --- |
| Combat action heat | +3 per action | 5.2 |
| Salvage (Loot) action heat | +2 per action | 5.3 |
| Loud movement heat | +1 per tile moved | 5.1 |
| Stealth movement heat | +0 | 5.1 |
| Trap / Distraction heat | Not specified by the design doc — Trap should be low/near-zero (stealthy setup), Distraction high (its entire purpose is to be loud). Flagged for tuning in session 5.3. | 5.3 |
| Adjacency bleed | 40% of source heat, 1 tile out; ~15% at 2 tiles | 2.5 |
| Passive decay | −1 heat/turn, only on tiles not currently being actively generated in | 1.1, 2.5 |
| Zombie pull | Probabilistic roll vs. heat each turn within radius — higher heat = higher probability + larger radius, never a hard binary trigger | 7.1 |
| Off-screen tile persistence | Residual heat keeps decaying/rolling for pull at reduced frequency; flat ambient-repopulation chance once heat hits 0 — never keyed off elapsed turns | 7.3 |
| Radio card-play heat burst | Not specified by its own design doc — additive on top of a card's own heat cost, scaled by the radio's active volume tier (5 discrete tiers + Off, Off = zero burst). Debug-only early validation in 1.1; per-tier multipliers are an open tuning item for Phase 14. | 1.1 (debug), 10.5 (real) |

### How this replaces the timer

| Old job of the timer | New mechanism |
| --- | --- |
| Force the player to keep moving, turn to turn | Per-tile heat compounding while stationary + decay while moving on |
| Prevent infinite "perfect hand" fishing in a safe spot | Off-screen/ambient repopulation on left tiles (session 7.3) — no tile is ever permanently safe |
| Escalating overall run pressure | Day/night asymmetric density, tightening from map edges toward Haven (session 10.4) |
| Bound total effective actions per run | Food/Water dilution, Dominion-style (session 6.1) — self-balancing, not a hard cap |

### Open questions carried forward from the source doc

**01 — Exact heat values and decay rates**

Placeholders above — needs a gray-box prototype (Phase 1) to tune, not more theorycraft. Trap/Distraction specifically have no starting value at all yet.

**02 — Day/night cadence**

Resolved (v17): anchored to real elapsed run time rather than turn count — sun starts setting ~20 minutes in, zombie ring nearly reaches Home Haven by ~30 minutes, directly tied to GDD §4's 20-30 minute session-length target. The exact interpolation curve between those two anchors remains a Phase 14 tuning question.

**03 — Audio-only cue set**

If a player disables both the ring and the tile tint (session 12.5's hard requirement), is there enough non-visual signal left? Session 12.2 now owns building a dedicated heat-event SFX cue for exactly this reason — but whether it's actually sufficient on its own is still a real accessibility question to verify once session 12.5 exists, not assumed away just because a cue now exists.

## START.10 — Testing Strategy

_Folded in from TESTING_STRATEGY.md at the shared cross-project Godot dev-notes folder — general-use, not written for HavenZ specifically, and already referenced by GODOT_LESSONS.md #30. The problem it solves: without an explicit rule, a session defaults to "when in doubt, re-run everything" after any edit, which is safe but wastes time on changes that structurally can't touch the rules engine (a StyleBox color tweak doesn't need the heat-propagation suite run against it). This is about skipping *irrelevant* tests, not skipping verification — Engineering Lesson E4's real-export checks still apply on top of whatever scoped set of tests actually runs._

### Classify the edit by blast radius before choosing what to verify

| Edit type | What it looks like in HavenZ | What to actually verify |
| --- | --- | --- |
| Cosmetic | Card panel StyleBox tweaks (4.3), palette/tint alpha values (2.4, 12.5's tile tint), anchor/position changes — no nodes added/removed, no signal rewiring | A visual spot-check only (editor or real export per E4). Cannot affect pure-logic tests — running them is pure waste. |
| Structural scene edit | Hand UI node changes (4.3), Settings menu layout (12.1), Main Menu wiring (12.3), any `%UniqueName` target change | Only the tests that touch that specific scene — genuinely can break something, but the blast radius is still local. |
| Logic | Heat propagation (2.5/7.1), zombie pathing (7.1), play/drop resolution (4.4), Supply Request tracking (6.2), corpse decay (8.3) | Tests for that system, plus anything that depends on it per the header convention below. |
| Cross-cutting | CardResource/TileResource/EnemyResource/CorpseResource schema changes (0.2), any future autoload | The full suite — this is the one case where broad re-testing is actually correct, not just cautious. |

> **How to tell cosmetic from structural mechanically, not by eyeballing intent.** `.tscn` is a text format — a `git diff` that only touches property values (`position =`, `offset_*=`, `color =`, `theme_override_*=`) is cosmetic; one that adds/removes a `[node]` or `[connection]` block, or changes a `unique_name_in_owner` flag, is structural. This answers the question directly without reopening the editor.

### Suite layout and the depends-on convention

**01 — Split the suite by layer, not one flat folder**

res://scripts/tests/logic/ (pure rule/data logic, zero UI dependency), res://scripts/tests/ui/ (click-path/interaction tests), res://scripts/tests/integration/ (full-flow/end-to-end checkpoints) — established in session 0.5, before any test file exists. A cosmetic edit then only ever needs a look in ui/, never logic/ at all.

**02 — A one-line depends-on header per test file**

`# Exercises: heat_propagation.gd, tile_resource.gd` at the top of every test file. Before running tests after an edit, cross-reference the session's actual changed files (`git diff --name-only`) against these headers — only run matches, plus anything in integration/ if the edit was structural or cross-cutting. Cheap to maintain, turns "which tests cover my change" into a grep instead of a memory exercise.

**03 — Precedent already exists — PixelPipe's own roadmap**

PixelPipe's docs/ROADMAP.md already has a "session built... → before marking it Done, actually..." decision table mapping change-type to what to verify — proof this pattern works in practice, oriented toward *sufficiency* (don't ship undertested) rather than this section's *scoping* (don't over-test). If a project already has its own version of this table, keep it — this section is the shared reference to draw on, not a replacement.

> **What this does not replace.** Blast-radius scoping is for day-to-day iteration speed, not pre-milestone or pre-ship gates. Sessions 9.1 (vertical-slice go/no-go) and 14.3 (demo packaging) both now run the full suite regardless of how cosmetic recent edits looked — that's the backstop that catches a case where the blast-radius classification itself was wrong. Scope aggressively between checkpoints; don't scope the checkpoint itself.

## PH.00 — Foundation & Tooling

_Engine settings, git, the shared data model, and the testing convention (0.5) — deliberately zero art and zero gameplay. Scope guardrail for everything downstream: single-player, PC/Steam only, no server dependency, ever (Lifecycle lesson 7)._

#### S0.1 — Project settings, git & repo hygiene

_2D-correct engine settings, git init *and* a remote push, a native-Godot localization stub, a running session log with planned-vs-actual metrics, this roadmap committed into the repo._

**Session prompt:** Set up the HavenZ Godot 4.6 project for 2D pixel-art development only: switch the default viewport stretch mode to canvas_items with pixel-perfect scaling, set the default texture filter project-wide to Nearest, disable mipmaps, and remove the unused 3D Jolt Physics setting from project.godot. Initialize git with a Godot-appropriate .gitignore, then push it to a private remote (GitHub or similar) immediately — local-only git is still a single point of failure. Create res://localization/strings.csv using Godot's native CSV translation format (a "keys" column plus one column per locale, e.g. keys,en) rather than a hand-rolled id/text pair, and register it under Project Settings → Localization so it imports as a real Translation resource — every later session that displays text must go through tr("KEY"), never a literal string. Build this infrastructure now even though no second locale is committed yet — retrofitting tr() across an already-large codebase later is a far bigger job than the small day-one cost of writing every string through tr() from the start. Which locale(s), if any, are actually worth translating into is a separate, later decision — see session 13.2. Create docs/SESSION_LOG.md and docs/ROADMAP.md (this document) in the repo. SESSION_LOG.md needs two things, not just a narrative: a short "what shipped / what's stubbed / what's next" entry per session, and a running metrics table (columns: Phase, session code, session type [build vs. checkpoint/human-judgment], planned-vs-actual session count for that phase, rough elapsed calendar time, no-op flag for a conditional session — like 9.2 — that ends up shipping zero code) updated at the end of every session going forward — this is the data Phase 14.4's retrospective rolls up, and what future project roadmaps get calibrated against instead of guessing; the session-type and no-op columns exist specifically so a calendar-heavy playtest session or a legitimately-empty conditional session doesn't read as a missed build estimate later. Do not unzip or import any art this session, and write no gameplay code — pipeline and repo hygiene only, ending in one commit.

#### S0.2 — Core Resource class definitions *[Extraction candidate]*

_CardResource, TileResource, EnemyResource, CorpseResource — locked before any content or prototype code touches them._

**Session prompt:** Define the data-driven Resource classes HavenZ will build everything else on top of, including the Phase 1 prototype: CardResource (id, display_name, category enum [Attack, Loot, Trap, Distraction, MoveStealth, MoveLoud, SupplyFood, SupplyWater, SupplyMedical, SupplyScrap], noise_cost, effect data — noise_cost's starting values per category come from the Noise System Design section: Combat +3, Salvage/Loot +2, Loud movement +1/tile, Stealth movement +0; Trap and Distraction don't have design-doc values yet, treat Trap as low/near-zero and Distraction as high, and flag both for tuning), TileResource (walkable, blocks_zombie, blocks_noise, heat — a single scalar current value that only ever changes by addition [a rise from an action or bleed] or subtraction [decay], never wholesale overwritten by a new source; plus a this_turn_origins set — not a single last_heat_origin tag — tracking which origin types [player/zombie/wildlife/radio/other] contributed heat to this tile during the current turn, cleared at the start of each new turn. A single last-origin tag can't survive the case where player, zombie, and radio heat all land on the same tile in the same turn once Phase 10 exists, and session 12.2's audio cue needs to know all of them, not just whichever wrote last. This is still far short of a full per-origin numeric Dictionary — it tracks which sources touched a tile this turn, not how much each contributed), EnemyResource (id, display_name, max_hp, move_speed, noise_aggro_radius, sprite refs), and CorpseResource (deck snapshot, position, cards_remaining). Add a one-line code comment wherever a played card's noise_cost value gets written into a tile's heat (first exercised for real in session 2.5/7.1) noting that these are the same currency under two different field names — CardResource keeps "noise_cost" to match GDD §8's own wording, TileResource uses "heat" for the more precise per-tile mechanic, and the split is a deliberate scope-minimization choice, not an inconsistency to fix later. Put class scripts in res://data/ with class_name declarations and PascalCase names. Create one sample .tres of each so the classes are provably instantiable in the editor. No gameplay logic, no scenes, no art — resource class definitions only.

#### S0.3 — Audio bus setup

_Master/SFX/Music buses and volume settings, wired but silent — infrastructure ahead of any real sound asset._

**Session prompt:** Set up the Godot audio bus layout (Master, SFX, Music at minimum) and a Settings-menu-ready volume structure (per-bus exported values, persisted via ConfigFile once Phase 12.1 builds the actual Settings UI). No real audio files exist yet — use silent placeholder AudioStreamPlayer nodes wired to the correct bus so later sessions (Phase 12.2) only have to drop real clips in, not build the routing. See the Asset Audit's new Audio table for what actually needs sourcing before this can carry real sound.

#### S0.4 — Pause architecture *[UI Shell candidate]*

_The rule, not the UI — decided before any ticking/stateful system exists, specifically to avoid a late, expensive pause retrofit._

**Session prompt:** Before any gameplay system exists, decide and document HavenZ's pause convention: get_tree().paused is the single source of truth, and every node's process_mode must be set deliberately going forward, never left at the PROCESS_MODE_INHERIT default — PAUSABLE for anything that should freeze (zombie AI timers, noise decay/propagation ticks, card-resolution animations, the corpse/respawn flow), ALWAYS/WHEN_PAUSED for anything that must keep responding while paused (the pause menu itself, and session 4.2's gamepad cursor — input has to work to un-pause). Write this as a short, explicit convention in the project README/CLAUDE.md, not just this session's own memory, since every session from Phase 1 onward needs to follow it without re-deriving it. Flag it for promotion into the shared GODOT_LESSONS.md too — "decide the pause convention before any stateful system exists" is a general Godot lesson, not a HavenZ-specific one. This session establishes the rule only; no pause UI gets built yet.

#### S0.5 — Testing conventions

_The folder split and blast-radius rule from the Testing Strategy section, established before any test file exists — same reasoning as 0.4's pause convention: decide it before code accumulates against a different assumption._

**Session prompt:** Create res://scripts/tests/logic/, res://scripts/tests/ui/, and res://scripts/tests/integration/ now, before any test exists, so every session going forward has an obvious place to put one instead of everything landing in one flat folder that has to be sorted later. Document the blast-radius classification (cosmetic / structural scene edit / logic / cross-cutting) from the Testing Strategy section in the project README/CLAUDE.md, right alongside session 0.4's pause convention, plus the one-line `# Exercises: file.gd, file2.gd` depends-on header every test file created from here on must carry. Also note explicitly, in the same doc, that checkpoints (sessions 1.2, 9.1, 14.1-14.3) always run the full suite regardless of blast radius — this scoping rule is for iteration speed between checkpoints, not a substitute for them. This session establishes structure and documentation only — no real tests exist yet, since no gameplay code exists yet either; session 4.1 is the first session to actually populate logic/.

## PH.01 — Concept Validation

_Prove the specific hook — noise-driven zombie attraction interacting with the card-hand economy — with placeholder shapes and zero art, per Lifecycle lesson 1. This is the highest-risk, least-precedented system in the design; if it isn't compelling here, redesign before Phase 2, not after._

> **Input-scheme decision, made here so S1.1 has something to build against.** Baseline is mouse point-and-click: click a card to select it, click a tile to target/move. Gamepad is now first-class, not deferred — see the Input Scheme section for the full locked-in scheme (stick-driven virtual cursor, A/B/X-or-Y bindings, slider and scroll behavior) and which session builds each piece.

#### S1.1 — Gray-box the core loop

_ColorRect grid, a player square, a numeric heat value per tile, a minimal 5-card hand, one heat-seeking enemy square._

**Session prompt:** Build the smallest possible gray-box that proves HavenZ's specific hook, using only ColorRects and debug labels — no imported art. A grid of tiles the player square can step onto one at a time; a per-tile heat number that rises when the player takes a "loud" placeholder action and decays each turn, except decay pauses on a tile the player is actively generating heat in this turn (per the Noise System Design) — a fight in one spot should visibly compound, not just tick up and back down identically regardless of whether the player keeps acting there; a minimal hand of 5 abstract CardResources (one Stealth move, one Loud move, one Attack, one Loot, one Supply — text buttons are fine, no card-frame UI) that replenishes the hand on play, played via mouse click per this phase's input-scheme decision; and one enemy square whose move-toward-heat chance each turn scales with the target tile's heat value (a rough probability roll, not a hard threshold) within a fixed radius. Wrap heat/hand state in Dictionaries, not plain scalars, in any closures you use (GDScript lambdas capture by value). This is throwaway-resistant, not throwaway: route it through the CardResource/TileResource/EnemyResource classes from Phase 0.2 so it survives into Phase 2's reskin rather than being rewritten. No wall-blocking on heat yet — there are no walls. Also add one debug-only scalar simulating the planned Portable Radio System's card-play heat burst (the real system is sessions 10.5/10.6) — a simple multiplier applied on top of each card's heat value, stepped through a few fixed values standing in for its 5-tier-plus-Off design — so the volume-vs-heat tradeoff that system depends on gets a first feel-check alongside base heat tuning now, per that design doc's own explicit instruction, rather than waiting until Phase 10 to discover the curve doesn't work. Throwaway debug scaffolding only, not part of the real Phase 10 build.

#### S1.2 — Playtest & go/no-go *[Checkpoint]*

_Play the gray-box yourself (and ideally one other person). Decide before spending a single hour on art._

**Session prompt:** This is a decision gate, not a build session. Play the Phase 1.1 gray-box for real — several turns, deliberately making noise and deliberately staying quiet, and see if the tension between "chain plays fast" and "the zombie square is now coming for you" is actually interesting with nothing but colored squares and numbers on screen. If it isn't, that's Phase 1 doing its job — identify what's flat (the heat curve, the hand size, the enemy's aggro logic) and have Claude Code iterate on the gray-box itself before touching Phase 2. Do not proceed to art import while privately unsure the loop works. This checkpoint gets up to 3 attempts: play, identify what's flat, have Claude Code iterate, and re-check — up to 3 full rounds. If it's still not landing on the 3rd attempt, that's the real "no": stop and reconsider whether this specific hook (noise + card-hand tension) is the right concept at all, not just the current tuning of it. If attempts remain and the loop is close but not quite landing, this is also the cheapest point to try the GDD's new Card Synergy open question (Design Pillars section) — the gray-box's abstract categories are exactly what a synergy rule needs, and it's far cheaper to throw away a synergy experiment here than after Phase 4 builds real card logic around it.

## PH.02 — Art Pipeline Adoption

_Only after Phase 1 validates the hook, and only after the standalone PixelPipe tool exists and passes its own end-to-end checkpoint: configure it for HavenZ, run it against the real asset pack, and reskin the gray-box. This phase got much lighter once the pipeline itself moved out — HavenZ now consumes a tool instead of building one._

> **Provisional.** These five sessions describe what HavenZ needs to do at a conceptual level. Exact command names and config fields depend on how PixelPipe actually turns out — tighten these prompts once that roadmap has been executed.

#### S2.1 — Configure PixelPipe for HavenZ

_Write HavenZ's config, install the addon, lock the pixel-scale constant._

**Session prompt:** Before writing any config, open PixelPipe's own docs/ROADMAP.md and Handoff section and diff this phase's assumptions (config field names, command syntax, addon file layout) against what PixelPipe actually shipped with — correct any mismatch here rather than discovering it mid-session; this phase was written provisionally, before PixelPipe existed, specifically to be revisited this way. Then write HavenZ's pixelpipe.config.json: source pack path (the unzipped PostApocalypse_AssetPack_v1.1.2), res://art_source/ and res://art/ as output paths, haven-z/ as the target Godot project, the seed HavenZ_Field_Palette as the starting active palette, and ignore-glob patterns for the deprioritized assets from the Asset Audit (the full vehicle recolor matrix, the multi-stage gun-reload sheets). Install PixelPipe's addons/pixelpipe/ package into haven-z/addons/.

> **Corrected 2026-08-28, during the real S2.1 session.** This prompt originally asked for "one canonical screen-pixels-per-native-pixel scale factor" in `pixel_scale`, assuming PixelPipe would handle display upscaling. It doesn't: `pixel_scale` is purely an art-hygiene validator (`asset_validator.gd`) confirming every exported PNG's dimensions are a clean multiple of it — it never touches on-screen sizing, which is entirely Godot's `canvas_items`/`integer` stretch mode, already locked in S0.1. A real inventory of all 1,113 PNGs in the pack found them irregularly cropped to content bounds, not aligned to any shared grid — so `pixel_scale=1` is the only value that doesn't immediately fail validation across most of the pack. Set to `1` in the real config.

#### S2.2 — Real palette extraction & reconciliation

_Run PixelPipe's extraction against the real ~1,100-file pack — the seed palette gets superseded here._

**Session prompt:** Run PixelPipe's full-folder palette extraction against the real PostApocalypse_AssetPack_v1.1.2 (not a sample), then its reconciliation tool against the seed HavenZ_Field_Palette from planning. Review the diff report — expect new colors, including some of the "weird" ones worth fixing — and confirm whether the result fits Aseprite's 256-color Indexed cap or needs PixelPipe's quantization pass first. The output becomes HavenZ's real master palette; everything after this session (including any hand-drawn card art) targets it, not the seed sample.

#### S2.3 — Real pack conversion & sync

_The first real use of PixelPipe on real assets — produces HavenZ's actual res://art_source/ and res://art/._

**Session prompt:** Run PixelPipe's batch conversion against the real pack using the master palette from session 2.2, then its sync command to produce HavenZ's real res://art/ output. Spot-check a handful of results across categories (a character sheet, a building tile, a vehicle) to confirm dimensions and colors look right before treating this as done — this is PixelPipe's first real-world test, not just its own fixture-based one.

#### S2.4 — HavenZ palette tuning pass

_Use PixelPipe's remap shader/LUT generator to fix the pack's "weird tones," live, without re-exporting._

**Session prompt:** Using PixelPipe's palette-remap shader and LUT generator, define a "tuned" HavenZ palette variant addressing whichever tones from the Asset Audit or session 2.2's reconciliation report read as off — apply it live and iterate visually in the running game rather than re-running the export for every attempt. Treat any specific recolors as provisional until Phase 12 polish, when you decide whether to keep the shader permanently or bake the final chosen palette back into source via another PixelPipe conversion pass.

#### S2.5 — Reskin the validated gray-box *[Extraction candidate]*

_Swap ColorRects for real Character/Tiles art on the exact same logic from Phase 1 — proof the pipeline works on real gameplay code._

**Session prompt:** Replace the Phase 1.1 gray-box's ColorRect tiles and player square with the imported TileMap art and the Character/Main idle/run sheets, using the pixel-scale constant from session 2.1 — do not change the underlying movement, hand, or heat logic, only the visuals. While you're in the heat code, extend it from a flat per-tile decay into real propagation gated by TileResource.blocks_noise (nothing sets that flag true yet — no walls exist — so this is written now and exercised for real in Phase 3.1), using the starting parameters from the Noise System Design section: bleed 40% of a source tile's heat to each adjacent tile, ~15% at two tiles out, and pause decay (rather than decaying normally) on any tile the player is actively generating heat in this turn. Add inline comments at each non-obvious step in the propagation logic, since heat decay is exactly the kind of complex logic that needs them for a future human reader. Keep the propagation function's inputs/outputs generic (a value that rises, bleeds, decays, and is blocked by a tile flag) rather than heat-specific in its internals — see the Modular Systems section for why.

#### S2.6 — Colorblind accessibility check

_A cheap, natural addition given how much palette analysis already happened — currently missing from every accessibility mention so far._

**Session prompt:** Run the real master palette from session 2.2 (as tuned in 2.4) through a colorblind simulation (protanopia/deuteranopia/tritanopia) and check specifically whether the palette hues earmarked for the future heat ring/tint telegraph (Phase 12.5 — not built yet, so this checks the intended colors, not the rendered feature) and the HP/hazard-red visual language (Recommendations' "unified warm-red family" finding) stay distinguishable. If anything collapses together under simulation, feed a fix back through session 2.4's remap shader rather than waiting until polish — this is exactly the kind of check that's cheap now and expensive to discover after content is built against the wrong assumption. This session cannot fully close the question, though — session 12.5 re-runs this same simulation against the actual rendered ring and tile-tint once they're real on-screen elements, not palette swatches.

## PH.03 — Grid, Havens & World

_Walls that actually block noise and zombies, and enough real set-dressing that the map reads as HavenZ instead of a bare TileMap._

#### S3.1 — Haven placement & wall/entrance tiles *[Extraction candidate]*

_Home Haven + one other Haven; walls set blocks_zombie/blocks_noise, the first real test of Phase 2.5's propagation logic._

**Session prompt:** Place a Home Haven and one other Haven on the TileGrid using the Buildable wall art (res://art/Objects/Buildable/) and Buildings/Enterance tile art, per GDD §8.1: each Haven is a walled cluster of building tiles with an entrance tile, and its walls must set blocks_zombie and blocks_noise true on adjacent TileResources — this is the first time anything in the game actually exercises the noise-propagation blocking logic from session 2.5, so verify noise visibly stops at a Haven wall in the debug overlay. Walking onto the entrance tile should emit a signal (haven_entered) with a reference to which Haven — stub the Trade/Craft menu as a TODO for Phase 10, don't build it yet. Reserve one specific palette tint of the Enterance art exclusively for the Home Haven so it reads as distinct from other Havens.

#### S3.2 — World set-dressing & biome zones

_Non-functional Nature/Building/Vehicle props, using the pack's palette variants to mark distinct zones for free._

**Session prompt:** Populate the TileGrid with non-functional set-dressing from res://art/Objects/Nature/, Buildings/, and Vehicles/ so the map reads as a real post-apocalyptic town rather than a bare grid. Use the pack's existing palette variants (Green vs. Bleak-Yellow nature, beige vs. gray vs. dark buildings) to visually differentiate at least two map zones at zero additional art cost — this can double later as a cheap way to signal Supply Request difficulty tiers by region. None of this session's props need gameplay logic; this is purely visual.

## PH.04 — Card Engine Core

_Harden the gray-box's quick-and-dirty hand-handling from Phase 1 into the real Deck/Hand/UI/resolution system everything else plugs into._

> **Extraction candidate.** Deck/Hand/Discard + the play/drop resolution branch (S4.1 and S4.4) is the skeleton of basically any deckbuilder, not just a tile-tactics zombie game. Keep its API in terms of CardResource, not HavenZ card categories, so it's a clean lift into a standalone module the moment a second card game is worth building. See the Modular Systems section for the "prove it twice" rule this still follows.

#### S4.1 — Deck / hand / draw-pile data *[Extraction candidate]*

_Generalizes the gray-box's 5-card hand into a real Deck class with draw/discard piles and hand-replenish-on-play._

**Session prompt:** Generalize the Phase 1.1 gray-box's minimal hand-of-5 into a real Deck class managing draw pile, hand, and discard pile arrays of CardResource, with hand-replenish-on-play logic (playing or dropping a card draws a replacement up to hand size). This is pure data/logic in res://scripts/deck/ — no Control nodes, no card art on screen yet; that's session 4.3. Write a real test proving draw/play/discard/replenish work with an arbitrary deck, not just the 5 gray-box cards, before committing — this is the first test file in the project, so put it where session 0.5's convention says it belongs: res://scripts/tests/logic/deck_test.gd, with a `# Exercises: deck.gd` depends-on header at the top, not an ad hoc scratch check that sets no pattern for later sessions to follow.

#### S4.2 — Gamepad virtual cursor system *[UI Shell candidate]*

_The input foundation every later gamepad-specific session (card play/drop, sliders, scrolling) builds on._

**Session prompt:** Build the gamepad virtual cursor: one analog stick drives an on-screen cursor position, with sensitivity, deadzone, and independent per-axis inversion as exported settings (surfaced as real UI in session 12.1, not just code constants). A button fires a simulated left-click event, B fires a simulated back/cancel event, both routed through the same click/back signals a mouse would emit — every later Control-based UI (Hand UI, menus) should be unable to tell whether a click came from the mouse or the gamepad cursor. This is pure input plumbing; no game-specific UI gets built in this session.

#### S4.3 — Hand UI

_Anchored, Container-based hand fan, with gamepad D-pad quick-switch between cards. Programmer-art card panel — no card-frame art exists in the pack._

**Session prompt:** Build the on-screen hand display using Godot Control nodes only — no hardcoded positions or sizes: an HBoxContainer-based fan of card slots anchored to the bottom of the viewport, each slot showing a CardResource's name/category/noise_cost. Since the asset pack has no dedicated card-frame art (see Asset Audit), build a simple programmer-art card panel (StyleBoxFlat or a plain bordered Panel) rather than waiting on new art. Wire it to the Deck class from session 4.1 and the cursor system from session 4.2 so the hand updates live when cards are drawn and D-pad left/right moves focus between cards (the same focus state a mouse hover would set — downstream code shouldn't need to know which input method set it), replacing the gray-box's text-button placeholder. Every piece of card text goes through tr() against the localization CSV from session 0.1, not a literal string, from this session onward.

#### S4.4 — Play/drop resolution branch *[Extraction candidate]*

_The core resolution pipeline every card effect hangs off of, plus the locked-in play/drop control scheme and the real turn-end rule._

**Session prompt:** Implement the real play/drop branch per the locked-in control scheme: PC left-click plays the focused/targeted card, right-click drops it; gamepad A plays, X or Y drops (pick one during this session and record the choice in the Input Scheme section). A dropped card always resolves via the same fixed, non-player-chosen logic for where it lands — the exact rule is a numbers/balance detail to tune later, not this session's job to finalize; just make the hook deterministic. Mark the landing tile as Pickable (the same tag session 5.3's Looting cards target) so recovering a dropped card later requires playing an Action card on that tile, exactly like picking up any naturally-spawned loot — no separate pickup mechanic, per the GDD's own re-salvage note. Playing triggers hand-replenish; effect resolution should call apply_effect(card, target_tile) — for this session that can still be a stub that prints/logs, since the actual Attack/Loot/Move/Supply effects are separate Phase 5-6 sessions. Also implement the turn-end rule now, since it's structural: a player's turn ends automatically once no card remaining in hand is legally playable (e.g., only Scrap cards left, or an Action/Movement card whose cost/target can't currently be met) — not a fixed one-card-per-turn count. Implement "is anything in hand playable" as its own reusable function; Phase 6.1's Food/Water cards extend a turn by granting extra plays, and Phase 7.1's zombie turn fires once this check goes false. If you use closures for any part of this branch, wrap shared state in a Dictionary/Array, not a plain scalar var — GDScript lambdas capture by value.

## PH.05 — Action & Movement Cards

_One card per category, wired to real effects — the minimum needed for a complete vertical slice, not the full roster (that's Phase 11)._

#### S5.1 — Movement cards — Stealth & Loud

_1-tile silent moves vs. 2-3 tile noisy moves._

**Session prompt:** Implement the Movement card category from GDD §10.5–10.6: Stealth cards move the player 1 tile with zero heat generated, Loud cards move 2-3 tiles and add heat to the destination tile at +1 per tile moved (the Noise System Design's starting value — using the propagation system from Phase 2.5/3.1). Wire both into the play/drop branch from session 4.4. Add one sample .tres of each ("Careful Step" stealth, "Sprint" loud) so the category works end-to-end — full roster buildout is Phase 11, not here.

#### S5.2 — Melee Attack cards

_Bat-swing attack targeting an adjacent tile, via a reusable Damageable pattern._

**Session prompt:** Implement melee Attack cards from GDD §10.1 using the Character/Main Punch animation and the Pickable Bat art. Attacking should target an adjacent tile, deal damage to whatever's there, and generate heat at +3 (Combat, the Noise System Design's loudest starting category). Damage resolution should target a generic "Damageable" interface/method so the Phase 7 zombie and any future destructible objects can both implement it without rework. Ranged weapons (Pistol/Shotgun) are Phase 11 content, not this session — there's nothing to shoot at yet beyond Phase 7's single zombie type.

#### S5.3 — Looting, Trap & Distraction cards

_Three effects, one shared "affect a target tile without moving" helper._

**Session prompt:** Implement Looting cards (GDD §10.2) that pick up items from Pickable-tagged tiles into the player's supply pool and generate heat at +2 (Salvage, per the Noise System Design — "rummaging/prying") — this same Looting action is also how a previously player-dropped card gets re-salvaged from session 4.4's drop-landing tile, except it returns straight to the draw pile rather than the supply pool, since it's the original card, not new loot; Trap cards (§10.3) that place a hazard on a tile (tire/barrel art) triggering on zombie entry, generating little-to-no heat since placing one is meant to be stealthy (the design doc has no exact value for this — pick something low, like 0-1, and flag it for tuning); and Distraction cards (§10.4) that spawn heat at a target tile without the player moving there (Cardboard/Barrel art) — a Distraction's entire purpose is to be loud, so its heat value should be comparable to or higher than Combat's +3, not the design doc's unspecified default; flag the exact number for tuning too. These three share the same "affect a target tile without moving" pattern — implement that shared targeting helper once, then the three effects on top of it. One card per category is enough for this slice.

## PH.06 — Supply, Requests & Crafting

_The "return/craft" leg of the core loop — matches GDD §6.2's sub-loop exactly._

#### S6.1 — Supply cards

_Food/Water/Medical/Scrap, consumed-on-use. Water uses the Asset Audit's placeholder icon._

**Session prompt:** Implement Supply cards per GDD §10.7–10.10: Food and Water cards are destroyed on use and grant +1 Action or +1 Movement play respectively for the rest of the turn; Medical cards restore HP (wire to the HP heart UI); Scrap cards do nothing on their own but feed session 6.3's crafting — for now they're a distinct, non-playable-for-effect category sitting in hand as intended dead weight. These +1 Action/+1 Movement grants are exactly what lets session 4.4's turn-end check stay false longer, so a well-stocked, lucky hand can chain several plays before a turn actually ends — verify that interaction here, not just that the +1 grants apply. Per the Noise System Design's "Dominion model" framing, this dilution effect (more Food/Water in the deck means better action economy but worse odds of drawing an actual Action/Movement card on any given draw) is the intended balancing mechanism — no hard cap on Food/Water count is needed if the math is doing its job, and a leaner, sharper late-run deck as Supply cards get consumed is a desirable emergent curve, not something to flatten. Since that tension only reads if deck composition is visible, consider whether the Hand UI (session 4.3) or a small supply-ratio indicator makes the tradeoff legible rather than felt as vague bad luck — a lightweight addition, not a hard requirement this session. Use the placeholder Water icon from the Asset Audit table and comment that it needs the real commissioned asset before ship.

#### S6.2 — Supply Request loop

_Home Haven request generation, fulfillment tracking, delivery → next request._

**Session prompt:** Implement the Supply Request tracker from GDD §8: Home Haven generates a request (a small combination of specific supply card types + quantities), tracks which held supply cards satisfy it, and — on the player reaching the Home Haven entrance tile with the request fulfilled — ends the run, clears the request, and issues the next, larger one. Make request size/composition a data-driven table, not hardcoded if/else, since this is the primary progression driver (§8) and Phase 10.2 will scale it. Give the request a real on-screen presence too, not just backend tracking: the Asset Audit flagged this as having no dedicated art, so build the placeholder board/ticket visual it recommends — reuse the UI/Crafting cell art as the frame — showing the current request's required card types/quantities and live fulfillment progress. This placeholder frame is the actual MVP presentation, not a stand-in for a later session; a bespoke bulletin-board asset is optional post-MVP polish, not a blocking gap.

#### S6.3 — Crafting sub-loop

_Spend Supply/Scrap cards for stronger cards, using the pack's dedicated Crafting UI art._

**Session prompt:** Implement the Crafting sub-loop from GDD §6.2 using the UI/Crafting art (Crafting-cell, Crafting_Arrow, Crafting_Plus/Equal, Crafting_Scrollbox): a Control-based menu, opened at any Haven, where the player spends leftover Supply/Scrap cards to craft strictly stronger Action/Movement/Supply cards. On gamepad, D-pad up/down scrolls the recipe list using session 4.2's cursor system's click/back plumbing — reuse that convention rather than inventing a separate scroll input here. Define the recipe table as data, not hardcoded logic, so Phase 11's full roster can add recipes without touching this script again.

## PH.07 — Zombies & Combat

_One enemy type only — Zombie_Small — reacting to real heat probabilistically, plus the damage/death pipeline and the off-screen persistence that keeps left tiles from going permanently quiet. Zombie variety is horizontal content and waits for Phase 11 per Lifecycle lesson 3._

#### S7.1 — Base zombie & noise pathing *[Extraction candidate]*

_Zombie_Small following heat, blocked by walls, a reusable pathing function, and generating its own heat once engaged so encounters can snowball._

**Session prompt:** Implement the base Zombie using Zombie_Small art (idle/walk/attack/death), with pathing driven by the heat system per the Noise System Design: each turn, roll a pull chance against the heat value of tiles within aggro radius that the zombie has a path to (respecting blocks_zombie walls) — higher heat means both a higher probability of being pulled and a larger effective pull radius, not a hard binary threshold; below a low floor, idle/wander instead. Once a zombie is engaged (moving toward or attacking the player), have its own actions write heat back into the same per-tile system, adding zombie to that tile's this_turn_origins set per session 0.2's model — this is what makes zombie-to-zombie noise chaining happen for free: a second zombie's pull roll doesn't care whether the heat it's reacting to came from the player or another zombie, so one engagement can cascade into a bigger fight without any horde-specific scripting. Trigger the zombie's move once per completed player turn — per session 4.4's rule, that's when the player's hand has no legally playable card left, not a fixed clock. Keep the pathing function isolated so Phase 11's Zombie_Axe/Big/Bat can reuse it with different stats rather than duplicating it — but do not build those types now, only Small.

#### S7.2 — Combat resolution & death trigger

_HP hearts wired to real damage, player_died signal with deck+position payload._

**Session prompt:** Wire player HP (res://art/UI/HP/ hearts) to zombie attacks and player Attack cards, implementing the "Damageable" pattern stubbed in session 5.2 on both the player and the Zombie_Small from session 7.1. When the player takes too much consecutive damage per GDD §6.4, fire a player_died signal carrying the player's current deck and position — don't implement what happens on death yet (that's Phase 8), just get the signal firing at the right moment with the right payload.

#### S7.3 — Off-screen tile persistence & ambient repopulation *[Extraction candidate]*

_No tile is ever permanently "solved" — prevents clearing a room and camping it forever, without adding a hidden clock._

**Session prompt:** Per the Noise System Design's Section 3: tiles the player has left keep decaying heat at the normal per-turn rate (not instantly zeroed), and while a left tile's heat is still above 0, it keeps rolling for reduced-frequency zombie pull using session 7.1's same probability logic. Once a tile's heat fully decays to 0, apply a slow flat ambient-repopulation chance per turn (a small, constant probability a zombie wanders in) so the tile is meaningfully safer once quiet but never permanently cleared. Hard constraint from the design doc, worth repeating because it's easy to get wrong: do not key any of this off "turns since the player left" — that's a hidden timer wearing a different name, exactly the thing this whole system replaced. Keep it strictly a function of (a) residual heat and (b) the flat ambient rate. Don't wire this to the corpse system yet — that's session 8.3, once corpses exist to reference it.

## PH.08 — Death & Corpse Recovery

_Completes the vertical slice: the roguelike heartbeat of persistent corpses, a weaker-but-inheriting new scavenger, and decay that punishes ignoring old bodies._

#### S8.1 — Corpse marker *[Extraction candidate]*

_Persistent, non-overwriting corpses holding the dead deck._

**Session prompt:** On the player_died signal from session 7.2, spawn a persistent Corpse (CorpseResource from session 0.2) at the death tile holding the player's full deck at time of death, and represent it on the map as a Dead Sprite marker per GDD §8. Corpses must not overwrite each other if the player dies again before recovering an earlier one — store them in a list/autoload, not a single-slot variable.

#### S8.2 — Respawn & card inheritance *[Extraction candidate]*

_New Scavenger, weighted 1-card inheritance, data-driven tiering._

**Session prompt:** On player death, respawn the player at Home Haven as a "New Scavenger" with a lower-tier starting deck, and have the new scavenger inherit exactly 1 card randomly selected from the dead body's deck, weighted toward Action/Movement cards over Supply cards, per GDD §8. Keep the starting-deck tiering and inheritance-weighting as data (an exported table or resource), not magic numbers buried in the function.

#### S8.3 — Corpse decay & recovery *[Extraction candidate]*

_1 card lost per subsequent death, expiry at zero, a directional indicator reusing existing art._

**Session prompt:** Implement corpse decay and recovery per GDD §8: every death after the first removes 1 random card from every other still-unrecovered corpse's remaining deck, and a corpse is removed from the map once its deck reaches zero cards. Add a simple on-screen directional indicator (reuse/rotate the Crafting_Arrow sprite — no new art needed, per the Asset Audit) pointing toward the nearest unrecovered corpse. Walking onto a corpse tile recovers its remaining deck into the player's draw pile. Wire the corpse's tile into session 7.3's off-screen persistence: as long as the corpse sits unrecovered, its tile keeps accumulating retrieval risk via the same residual-heat/ambient-repopulation logic every other left tile uses — per the Noise System Design, this is what makes "go back for my old deck" a live, rising-risk decision instead of a free action, without adding any corpse-specific timer.

#### S8.4 — Camera follow finalization

_Make the automatic follow-cam feel good before Phase 9 judges the loop on it too._

**Session prompt:** Finalize the follow-camera behavior established back in session 1.1: smoothing/lerp speed, lookahead in the player's facing/movement direction, and edge-case behavior at Haven walls and map boundaries. Follow-cam only — no player-controlled pan/zoom is planned for this game; this session is about the automatic behavior feeling good, not adding manual control. Do this before Phase 9 so a janky camera doesn't confound the playtest's read on the actual game feel.

#### S8.5 — Pause system (core + minimal UI) *[UI Shell candidate]*

_Built now, as part of the vertical slice, specifically so it gets tested against real zombie AI, noise ticks, and the corpse/respawn flow while the codebase is still small enough to fix cleanly._

**Session prompt:** Build the real pause menu now rather than waiting for Phase 12's polish pass — building pause late, after AI/state-machine code has already accumulated without pause-awareness, is exactly the sequencing that has caused expensive retrofits and hard-to-track scene-loading/NPC/state-machine bugs on past projects. Apply session 0.4's process_mode convention across everything that exists so far: zombie pathing, noise decay/propagation, and the corpse/respawn flow must all actually freeze on pause and resume cleanly, not just visually stop. Trigger it on the gamepad Menu/Start button and an equivalent PC key (Escape) — B is reserved for cancel/back per the Input Scheme. Minimal UI only: Resume and a placeholder Quit — a real Settings screen and Main Menu don't exist until Phase 12, so don't build links to screens that aren't real yet; session 12.3 comes back and wires those up properly. Explicitly test pausing mid-zombie-move, mid-noise-tick, and mid-death-sequence before calling this done — those are the exact failure categories to catch now.

## PH.09 — Vertical-Slice Go/No-Go

_Lifecycle lesson 4: negative signal about core-loop feel is non-negotiable to act on here, even if it means reworking Phases 5-8, before a single hour goes into more content. Recruit 3 people external to the primary developer ahead of this phase so the vertical slice gets judged on more than solo signal — see session 9.1._

#### S9.1 — Play the full loop & decide *[Checkpoint]*

_Leave Home Haven → scavenge → get noticed → fight or flee → return/craft → die-and-recover. Several full runs, run both solo and by 3 people external to the primary developer. Up to 3 attempts to pass._

**Session prompt:** This is a decision gate, not a build session. Recruit 3 people external to the primary developer — friends, a Discord, an itch.io private link, the same channels session 14.1 later uses at scale — to play the vertical slice alongside your own runs; this is the first point real outside signal enters the process, rather than waiting until Phase 14.1. This gate gets up to 3 attempts: play, identify the specific system(s) falling short (card economy / noise pacing / death-recovery feel), have Claude Code rework them, and re-run this checkpoint — up to 3 full rounds total. If it's still not landing on the 3rd attempt, that's the real "no": treat it as license to reconsider something fundamental in the design, not just re-tune numbers again. Play the complete vertical slice across several full runs, including at least 2 deaths, at least 1 corpse recovery, and at least one deliberate attempt to clear a room and camp there. Judge specifically: does the card economy (movement/action/supply tradeoffs) feel meaningful turn to turn; does heat-driven zombie pursuit feel fair and readable even with no telegraph UI yet; does dying and recovering your own corpse feel like a real setback-with-a-path-back, not just a reset; does leaving a loud tile and coming back later feel meaningfully different from camping it, per session 7.3's off-screen persistence; whether hands can get stuck holding mostly unplayable Scrap cards, ending turns abruptly with no real action taken — the Supply/Scrap dilution math should create tension, not just dead turns; and any death-location exploit — e.g. dying deliberately near Home Haven to minimize corpse-retrieval risk, or any other way of gaming corpse decay/off-screen persistence rather than experiencing it as the intended risk. Note anything camera-related too (disorienting cuts, lookahead that's too aggressive or too passive, a wall case that reads badly) for session 9.2. Also deliberately pause and resume mid-zombie-chase and mid-death-sequence a few times per run — session 8.5's pause system was built specifically to be caught and fixed here, while the codebase is still small, rather than discovered after Phase 11's full roster exists. Alongside the playtest itself, run the full automated test suite from res://scripts/tests/ — per the Testing Strategy section, checkpoints don't get blast-radius scoping, specifically because this is the backstop that catches a case where an earlier session's cosmetic-vs-logic call was wrong. If any of these feel wrong, treat it as a real finding and have Claude Code rework the specific Phase 5-8 system before moving on — this is the substantial revision pass the roadmap explicitly budgeted for, not something to defer to Phase 14's tuning-only pass.

#### S9.2 — Camera improvements from playtest feedback

_Only has content if session 9.1 actually surfaced a specific camera complaint._

**Session prompt:** Revisit the camera based on what session 9.1's playtest actually found. If it surfaced something specific — a disorienting cut, lookahead that's too aggressive or too passive, a Haven-wall case that reads badly — fix that specific thing. If nothing camera-related came up, this session is a no-op; don't tune the camera without a real complaint driving it. Either way, log the outcome in SESSION_LOG.md's no-op column from session 0.1 — a genuinely empty session here is the plan working as intended, not a missed estimate, and the metrics rollup in 14.4 needs that distinction on record rather than inferred later.

## PH.10 — Haven Network & Progression

_Horizontal expansion begins here, only after Phase 9 clears: non-Home Havens become useful, the difficulty curve gets its own group of independently-tunable scalars, a run-level day/night pressure layer sits on top of the per-tile heat system, and an opt-in Portable Radio (10.5–10.7) turns volume into its own player-controlled heat/richness tradeoff, built out to a real music/event roster in 10.7._

#### S10.1 — Trade/Craft Haven menu

_The only interaction non-Home Havens support — nothing more._

**Session prompt:** Build the Trade/Craft menu that opens on entering a non-Home Haven (haven_entered signal from session 3.1), using the same Crafting UI art and recipe-table pattern from session 6.3 (including its D-pad scroll convention) plus a simple card-for-card trade panel. This is the only interaction non-Home Havens support per GDD §8.1 — don't add anything beyond trade and craft.

#### S10.2 — Difficulty ramp

_One shared difficulty value drives both request sizing and (once Phase 11 adds them) zombie-tier unlocks._

**Session prompt:** Implement the difficulty curve from GDD §6.1: Supply Request size/composition scales up as the player's crafted card power increases, and scales back down after repeated deaths. Drive it from its own scalar within a small RunDifficulty group of independently-tunable values (not one shared number) — Request-sizing gets its own scalar here; Phase 10.4's day/night pressure and Phase 11.4's zombie-tier unlocks each get their own scalar in the same group once they exist. Each should have its own bounds/rate so it can be tuned in isolation, while still reading as one coherent difficulty to the player.

#### S10.3 — Starting-loadout progression

_Closes the roguelike loop — verified across 2-3 completed runs._

**Session prompt:** Implement permanent starting-loadout improvements on successful Supply Request delivery, per GDD §6.1: each completed run should upgrade the New Scavenger's starting deck tier from session 8.2 by an amount proportional to how many runs have been completed. Verify end-to-end by completing 2-3 requests in a test run and confirming the next scavenger starts stronger.

#### S10.4 — Day/night pressure layer

_A run-level pacing layer above per-tile heat — a "circle closing in" effect with a spatial, not a literal, countdown._

**Session prompt:** Implement the day/night layer from the Noise System Design Section 4, sitting above session 2.5/7.1's per-tile heat system rather than replacing it: night increases zombie density and spawn radius globally but asymmetrically — lowest near Home Haven, highest at the map's outer edges, tightening inward as the phase progresses — giving the player a legible spatial reason to route decisions ("head back before the ring closes") rather than a flat danger multiplier. Also accelerate session 7.3's ambient-repopulation rate during night, so both systems reinforce the same "move toward Haven" message through different mechanisms. Drive both from their own scalar within the RunDifficulty group session 10.2 established — tuned independently from Request-sizing's scalar, not literally sharing its number, while still living in the same group rather than a separate parallel system. Anchor the cadence to real elapsed run time, not turn count, tying it directly to GDD §4's own 20-30 minute session-length target: the sun starts setting around the 20-minute mark, and the zombie spawn ring should have tightened to nearly reach Home Haven by around the 30-minute mark — giving a player who's running long a legible, felt signal that they're past the intended session length, not just an arbitrary difficulty ramp. The exact interpolation curve between those two anchor points is still a Phase 14 tuning question; the two endpoints themselves are locked in now.

#### S10.5 — Portable Radio: access & heat-burst core

_Free, menu-based, always-on utility — no turn cost, no card/inventory slot — that turns volume into a direct heat/richness tradeoff using the existing heat model, not a separate system._

**Session prompt:** Build the Portable Radio's access and core mechanical hook, per HavenZ_Radio_System_Summary.md: a free menu interaction available on any run, opened the same way the pause menu is (session 0.4/8.5's process_mode convention applies here too, since this menu must stay reachable without costing a turn) — no card, no inventory slot, no turn cost to open or adjust. Expose 5 discrete volume tiers plus Off as the only states — not a continuous slider, a stepped selector — the exact gamepad binding (D-pad step-through vs. hold-and-tap, reusing session 12.1's slider-focus-hold input-switch pattern if it fits) is undecided; pick one this session and record it in the Input Scheme section. Wire the active tier into session 4.4's play/drop resolution: every card play adds an additional heat burst on top of the card's own noise_cost, scaled by the active tier, through the exact same per-tile TileResource.heat write session 2.5/7.1 already does — adding player to that tile's this_turn_origins set like any other player action, not a parallel data path. Off must produce zero radio heat burst. Treat Off as a legitimate, distinct playstyle in both UI copy and underlying design — not a grayed-out or "worse" bottom rung of the same dial, per the source doc's explicit design intent. Session 1.1 already validated a debug-only version of this heat-scaling concept early; this is the real, non-debug build. Session 10.6 builds the event system this same tier selection also gates — this session only needs the tier state to exist and be readable.

#### S10.6 — Radio events: distress calls, supply drops & moment-of-silence *[Extraction candidate]*

_One shared, extensible event system, gated by whether the radio is on, presented through the corpse system's existing marker grammar rather than new UI._

**Session prompt:** Build the event half of the Portable Radio, per HavenZ_Radio_System_Summary.md. New data-driven RadioEventResource (event_type enum [DistressCall, SupplyDrop, MomentOfSilence — extensible, more types addable later without touching this session's code], required_hint_tier, sound_cue, marker_duration, loot_despawn_delay — despawn timing kept as its own separate value from marker duration, per the doc's explicit instruction, never derived from it) in res://data/, matching the CardResource/TileResource/EnemyResource/CorpseResource pattern from session 0.2. A single event timer, randomized within a bound range (bounds are an open tuning item, see below), ticks only while session 10.5's radio is on any tier above Off, pauses entirely at Off, and resets on the player_died signal from session 7.2/8.1 rather than continuing to accumulate through a death. On fire, the event does not resolve immediately — it resolves at the start of the player's next turn, per session 4.4's turn structure. Volume tiers are nested for hint richness, not frequency: a higher tier receives every hint a lower tier would plus additional higher-tier hints about the same event pool — the timer's fire rate itself never changes with volume. Confirm explicitly before calling this done that it is not a reintroduction of the removed turn-clock: it's opt-in (the player chooses to run it via volume), it only ever grants opportunities, never applies a penalty or countdown pressure on its own, and it fully stops the moment the radio goes to Off.Presentation reuses existing systems rather than building new ones: on fire, play a short announcement sound cue (new SFX — see the Asset Audit's Audio table) and drop a nav marker using the exact same visual grammar as session 8.3's corpse-direction compass (the Crafting_Arrow-based indicator, no new art). The marker expires first as the closing-window warning; any loot tied to the event despawns some time after that, in case the player was nearly there — two separate timers, not one.Three things the source doc names but doesn't fully specify, to resolve this session rather than leave implicit: Moment-of-silence needs an actual fallen scavenger to reference — wire it to session 8.1's Corpse marker / session 8.2's respawn and decide the exact selection rule (most recent death? a specific still-unrecovered corpse?). Supply-drop's relationship to session 6.2's Supply Request tracker is undecided — whether drop loot can satisfy an active Request directly or is bonus-only outside that loop. Distress-call has a marker and a sound cue in the source doc but no stated mechanical payload at all — define one (a rescuable loot cache consistent with GDD §11's no-NPC-dialogue restriction is a reasonable default, but this session's call to make, not assumed here). Four open tuning items, explicitly deferred to Phase 14 balance passes, not resolved here: per-tier heat multipliers, the event timer's range bounds, hint-density thresholds per tier, and the marker-vs-loot despawn gap — use clearly-named exported constants for all four so Phase 14.2 can find and tune them without touching logic.Before calling this done, run a handful of real salvage-run loops with the radio at each volume tier, including Off, and confirm three things end-to-end: the heat burst from session 10.5 integrates cleanly with existing heat pacing (Phases 2.5/7.1) without breaking the difficulty curve from session 10.2; all three event types actually fire, announce, and resolve correctly across those runs, not just in isolation; and — the actual design goal — that choosing a volume tier produces a genuinely different, felt tradeoff during a real run, not just a cosmetic setting. This mechanical verification matters more than the amount of audio content behind it: a handful of sourced SFX cues per the Asset Audit's Audio table, plus 3 real test songs to confirm music actually mixes cleanly with those cues and with volume-tier switching, is enough for this pass. The risk here is the system's interaction with core gameplay, not the song count — full station-scale music content is session 10.7's job, not this one's.

#### S10.7 — Radio full buildout: music stations & extended events *[Extraction candidate]*

_Scale the Radio from its MVP core (10.5/10.6) to the real full build: a minimum of 3 distinct music stations at roughly 1 hour of real looped content each, plus additional event types beyond the initial three — this phase's second, larger-scale verification pass, per session 10.6's testing being MVP-scale only._

**Session prompt:** Now that 10.5/10.6's Radio core and initial event set are verified against 3 test songs, build out the real Radio: a minimum of 3 distinct music stations (thematically distinct — e.g. a calm/ambient station, a driving/upbeat station, a talk/distress-broadcast station, or whatever tone variety fits the GDD's setting), each with roughly 1 hour of real looped content, selectable independently from volume tier (station choice and volume are separate dials, not the same one). Extend the RadioEventResource event_type enum from session 10.6 with additional event types beyond the initial DistressCall/SupplyDrop/MomentOfSilence set — 10.6 built the enum extensible specifically for this. Before calling this done, run the same end-to-end verification 10.6 did, but at full scale over longer real sessions: confirm switching stations and the larger event roster doesn't destabilize heat pacing or event timing, and that the added content variety doesn't quietly flatten the felt tradeoff of choosing a volume tier into background noise. This is the second, full-scale testing point 10.6's MVP-scale check couldn't cover.

## PH.11 — Full Card & Zombie Roster

_Content, not new systems: fill every hook from Phases 5-7 with the full roster proposed below, and add the zombie variety deferred since Phase 7._

#### S11.1 — Action card roster

_Attacks, Looting, Traps, Distractions — full .tres set, no new logic._

**Session prompt:** Build out the full Action card roster (Attacks, Looting, Traps, Distractions) as .tres CardResources, using the set proposed in the Card Roster section: Bat Swing / Pistol Shot / Shotgun Blast / Improvised Rifle for Attacks; Quick Grab / Ransack Container / Siphon Vehicle for Looting; Tire Trap / Barrel Trap / Wire Snare for Traps; Throw Cardboard / Rev Engine / Fire Barrel for Distractions. Wire ranged weapons to consume Scrap-tier ammo cards on play. Every card must use an existing effect hook from Phase 5, not new logic.

#### S11.2 — Movement card roster

_Stealth and Loud rosters, tile-type-gated where it matters._

**Session prompt:** Build out the full Movement card roster (Stealth: Careful Step, Vault Window, Ladder Climb; Loud: Sprint, Smash Through Door, Motorcycle Dash) as .tres CardResources using the existing Stealth/Loud effect hooks from session 5.1. Vault Window, Ladder Climb, and Smash Through Door should each require the target tile to have the matching Window/Ladder/boarded-Door art tile — verify each requires its specific tile type before firing.

#### S11.3 — Supply roster & recipes

_Full Food/Medical/Scrap set, plus the recipe table._

**Session prompt:** Build out the full Supply card roster and crafting recipe table (Canned Food/Soup for Food, Bandage/First Aid Kit for Medical, Scrap Metal/Ammo Components/Vehicle Parts for Scrap) as .tres resources feeding the crafting system from session 6.3. First Aid Kit reuses the Bandage world sprite per the Asset Audit. This is also the session that closes the Water/Purified Water art gap the Asset Audit flagged as High priority and "not shippable as-is": draw both tiers (world sprite + inventory icon) now, in Indexed color mode against the master palette per pipeline recommendation P1, rather than carrying the placeholder icon further — nothing later in the roadmap owns this, so it has to happen here or it ships unresolved.

#### S11.4 — Zombie variety

_Zombie_Axe (telegraphed ranged), Zombie_Big (tank), and the Bat creature — renamed to avoid clashing with the Bat weapon._

**Session prompt:** Add Zombie_Axe (thrown-axe ranged attack with a visible wind-up/telegraph frame before the axe lands) and Zombie_Big (slow, high-HP melee tank) by extending the base Zombie from session 7.1 with an EnemyResource per type, not by copy-pasting the script. Also stand up the Bat creature from res://art/Character/Bat/ as a fast, low-HP flier — rename it internally (e.g. "MutantBat" or "Swarmer") to avoid confusion with the unrelated Pickable Bat melee weapon. Wire all three into their own scalar within session 10.2's RunDifficulty group (not a single shared value) so each unlocks at its own tunable threshold.

## PH.12 — Menus, Settings & Polish

_The GDD's own SWOT-driven accessibility ask, feel polish, and the save/load + main menu shell that makes it a real build._

#### S12.1 — Difficulty / accessibility settings *[UI Shell candidate]*

_Directly answers GDD §14.5's own SWOT recommendation, plus the real gamepad slider behavior and the cursor settings session 4.2 deferred here._

**Session prompt:** Add a Settings menu exposing at least one real difficulty/accessibility toggle — e.g. request-size scaling rate or zombie aggro radius — per GDD §14.5's own recommendation to "add an explicit difficulty/accessibility setting from the start." Also expose session 4.2's gamepad cursor sensitivity, deadzone, and per-axis inversion as real sliders here. Build the slider-focus-hold behavior as a reusable Control component, not a one-off: on gamepad, holding A while the cursor is over a slider switches stick input from moving the cursor to adjusting that slider's value directly; releasing A returns to normal cursor control. Every slider added in any later session (including these settings themselves) should reuse this component rather than reimplementing the hold-to-adjust behavior. Persist all choices via ConfigFile so they survive a restart. Before calling this session done, this is the first point where every piece of the locked-in gamepad scheme exists at once (cursor, A/B, X-or-Y drop, D-pad, and now sliders) — do one deliberate end-to-end pass exercising all of it back to back, since nothing later in the plan tests the complete scheme internally before Phase 14.1 hands it to external playtesters.

#### S12.2 — Audio/VFX pass

_Muzzle flash and SFX hooks, plus a dedicated heat-event audio cue — general feel polish. The heat/alert telegraph's visual layers are session 12.5, a dedicated system per the Noise System Design._

**Session prompt:** Add juice: muzzle-flash/fire VFX for ranged Attack cards, and simple SFX hooks (footsteps, hits, card play/draw) — stub audio files as TODOs if none are sourced yet, per the Asset Audit's Audio table. Also add an on-screen combo flasher — a small counter/flourish that appears when a turn chains multiple plays (per session 4.4's turn-end rule and the Food/Water plays-extension from 6.1) — giving the "momentum is a resource" design pillar (GDD §3) a visible on-screen payoff instead of being purely felt. Also add a distinct SFX cue triggered on any heat-generating action, scaled or varied by magnitude if a cheap way to do so is available (e.g. a louder/lower cue for Combat vs. a subtler one for Stealth's near-zero case) — this is the piece the Noise System Design's accessibility question flagged as needed but unowned: session 12.5's ring/tint telegraph is purely visual, so this cue is what gives an audio-only player something to react to. This is feel-polish only; the heat ring/tile-tint telegraph system that replaces the Phase 1-3 debug overlay is scoped separately as session 12.5, since it's substantial enough (two rendering systems, two hard accessibility requirements) to deserve its own session rather than being folded in here.

#### S12.3 — Main menu & save/load *[UI Shell candidate]*

_Play/Load/Save/Settings/Quit, wired to ConfigFile/JSON persistence — never a saved Resource._

**Session prompt:** Build the Main Menu (Play/Load/Save/Settings/Quit) and wire Save/Load to plain ConfigFile or hand-rolled JSON for the player's current deck, corpse list, and run-difficulty state from Phase 10 — serialize CardResource/CorpseResource data into dictionaries first, don't call ResourceSaver on a live Resource and load it back with ResourceLoader.load(). Loading a saved .tres with an embedded script executes that script, which is a real, documented code-execution vector, not just a style preference. All menu text goes through tr() per session 0.1's localization setup. Also go back to session 8.5's pause menu — built early, before either Settings (12.1) or this Main Menu existed — and wire its Settings button to the real screen and add a proper Quit-to-Main-Menu option, replacing whatever placeholder it shipped with. This is the last structural UI session before final playtesting begins.

#### S12.4 — First-run tutorial / onboarding

_Teaching the noise/telegraph hook to a first-time player — currently the GDD's biggest untaught mechanic._

**Session prompt:** Design and build a lightweight first-run onboarding pass: the GDD's own SWOT (§14.4) calls "legible core tension" HavenZ's strongest differentiator, but legibility to a new player requires teaching it once, not just telegraphing it well during play. A scripted first Supply Run with contextual one-line prompts the first time the player makes noise, the first time a zombie notices them, and the first time they die and see their corpse marker is enough for MVP — don't build a full tutorial level or skippable-cutscene system. Also decide explicitly whether a first-time gamepad player needs a control prompt, not just a mechanic prompt — the hold-A-to-adjust slider gesture from session 12.1 in particular isn't discoverable by trial and error the way click-to-play is; a single contextual hint the first time a slider is focused on gamepad is enough if you decide it's needed, but make that a decision, not a default. Route every prompt string through tr().

#### S12.5 — Diegetic heat display (ring + tile tint)

_Replaces the debug overlay as the shipped version of HavenZ's core legibility promise — two systems, no numeric HUD, both independently sufficient._

**Session prompt:** Build the two-layer diegetic display from the Noise System Design Section 6. Primary layer: on any heat-generating action, spawn a short pooled AnimatedSprite2D/Node2D ring animation (a few Aseprite frames — expanding, fading outline, from the Asset Audit's ring-sprite gap) centered on the source tile, radius-scaled to match that action's actual bleed radius from session 2.5, then despawn/return to pool — perfect information about how far a given noise actually traveled, at the moment it happens. Secondary layer: a persistent TileMap overlay or per-cell modulate tint on tiles with heat above 0, alpha-scaled to the tile's current heat value (a subtle warm tint reading as "disturbed ground," not a UI element — no new art needed), fading as heat decays, so a player can glance at a room and gauge risk without an event needing to have just fired. Both layers read the same heat data the spawn/pull logic from session 7.1 already uses — don't build a parallel data source. Reuse existing zombie alert/aggro animation states and wildlife-startle-equivalent cues where available as supporting confirmation, not replacements for the two primary layers. Two hard requirements, not optional polish: (1) the ring and the tile tint each need an independent on/off toggle in Settings (session 12.1) — a player must be able to disable either without losing the other; (2) each must be independently sufficient — a player who disables one must still play effectively using only the other, so don't design either as a dependency of the other, even though they should reinforce each other cleanly when both are on. Before calling this done, re-run session 2.6's colorblind simulation against the actual rendered ring color and tile-tint hue now that they're real on-screen elements rather than palette swatches — confirm nothing collapses together under protanopia/deuteranopia/tritanopia now that there's an actual feature to check, not just an intended palette.

## PH.13 — Marketing / Devlog Track

_Lifecycle lesson 5: this runs in parallel starting once Phase 9 confirms the vertical slice actually works, not at Phase 3 (before the hook exists) and not after Phase 12. Claude Code can draft words; you handle the actual account/page creation yourself._

#### S13.0 — Refresh market research *[Parallel track]*

_GDD §14's research was compiled early in planning; by the time Phase 13 actually starts (after Phase 9), real calendar time has passed and the genre landscape can have shifted._

**Session prompt:** Before drafting anything in 13.1-13.4, do a lightweight refresh of GDD §14's market research: check whether the named comps (Slay the Spire 2, Balatro, Monster Train 1/2, Wildfrost, Fights in Tight Spaces, Into the Breach, No More Noise, Project Zomboid, Vault of the Void, Griftlands) have had major updates, sequels, or review-score shifts since §14 was compiled, and scan for any new direct comps that have shipped in the tile-tactics/noise-mechanic space since then. This isn't a full SWOT rewrite — it's a sanity check that the differentiation angles 13.2/13.4 lean on (especially the No More Noise/Project Zomboid contrast §14.5 calls out by name) are still accurate before they go into real marketing copy. Update GDD §14 directly if anything material changed; note in SESSION_LOG.md if nothing did.

#### S13.1 — Start the devlog now *[Parallel track]*

_Begin publishing once the vertical slice is validated — around Phase 9, not at Phase 3 (world dressing only, no hook yet) and not at the end._

**Session prompt:** Draft the text for a first devlog post based on what's actually built and validated so far — the noise-driven scavenging loop, death and corpse-recovery, and the world's look — now that Phase 9's go/no-go has confirmed the core loop actually works, rather than screenshotting an environment before there's a real hook to show — plain, specific, screenshot-ready language, not marketing fluff. This is a writing task Claude Code can genuinely help with; actually posting it, and setting up whatever devlog/wishlist page it lives on, is on you. Repeat roughly every few phases rather than saving it all for the end — Balatro and Dave the Diver's pre-launch wishlist momentum both came from a long visible build-up, not a launch-week reveal.

#### S13.2 — Steam page & press-kit copy *[Parallel track]*

_Draft the words once the loop is presentable (after Phase 10); you own the actual Steam Partner setup._

**Session prompt:** Once Phase 10's Haven network makes a run feel complete, draft Steam store-page copy, a short key-art/capsule brief, and a one-page press kit doc from the GDD's actual pillars and market positioning (§3, §14) — grounded in what's actually built, not aspirational features. Explicitly work in §14.5's sharpest differentiation note, not just a general pointer to §14: distinguish HavenZ by name from No More Noise (proved the noise-danger hook has interest but under-executed it) and Project Zomboid (owns "zombie survival sandbox" mindshare broadly) — session 13.0's refreshed research is what confirms this framing is still accurate before it goes into real copy. Creating the Steam Partner account, the store page itself, and any pricing/legal decisions are yours to do outside Claude Code. Also revisit localization scope here: once devlog engagement and any early wishlist/Steam-page geography data exist, use that real signal — not a guess made back in session 0.1 — to decide whether a specific locale's demand justifies actually translating strings.csv. The session 0.1 infrastructure makes this a translation-content task at that point, not an engineering one.

#### S13.3 — Steamworks integration stub *[Parallel track]*

_The code-side half of going on Steam — the account/App ID side is yours, and has real lead time._

**Session prompt:** Once you have a Steamworks App ID (the account/fee/review process is yours, outside Claude Code, and worth starting early — it isn't instant), wire in a minimal GodotSteam (or equivalent) integration: SteamAPI init/shutdown, one placeholder achievement fired on first successful Supply Request delivery, and a stub for cloud-save sync pointed at the same ConfigFile/JSON save data from Phase 12.3. This doesn't need to be feature-complete — it needs to exist early enough that "add Steam integration" isn't a last-minute scramble before the Next Fest build.

#### S13.4 — Steam Deck marketing angle *[Tentative]*

_Contingent, not committed — only runs if the cheap Deck-legibility check from the Input Scheme section actually confirms viability._

**Session prompt:** This session is tentative: it only runs if the cheap Steam Deck verification already noted in the Input Scheme section (windowed-resolution testing at Deck's 1280×800/16:10 on the dev PC) confirms UI legibility holds up and Deck's default trackpad-as-mouse input is acceptable with zero extra code. If it passes, draft Deck-specific marketing copy alongside session 13.2's Steam page work — a "Great on Deck" store-page callout, screenshots captured at Deck's resolution, and a line in the press kit. If the check instead surfaces real legibility problems, this session doesn't run at all — don't draft marketing copy for a compatibility claim that isn't true yet. Exists so the Deck opportunity the SWOT flags doesn't quietly fall through the cracks, without committing real session time to it up front.

## PH.14 — Playtest & Ship

_Get real outside signal, tune only — the substantial rework already happened at Phase 9 — then package a clean export for the Next Fest demo._

#### S14.1 — External playtest round *[Checkpoint]*

_Phase 9's vertical slice already got signal from 3 external playtesters; this is the second, larger round — against the full Phase 11 roster — before the numbers get locked in._

**Session prompt:** This is a recruiting-and-listening task, not a coding session. Get the full Phase 11 build in front of a handful of people who aren't you — friends, a Discord, an itch.io private link — and collect structured feedback specifically on card economy feel, noise/telegraph clarity, and death-recovery satisfaction, the same three things Phase 9's internal checkpoint judged. Write down what they actually did and where they got confused or stuck, not just their opinions — that's what session 14.2 tunes against. Budget real calendar time for this; it can't be compressed into a single sitting the way the Phase 9 solo checkpoint could.

#### S14.2 — Playtest & balance pass

_Numbers and telegraphing clarity, informed by session 14.1's outside feedback — not new systems, that decision already happened at Phase 9._

**Session prompt:** Run a full playtest pass across several complete runs with the full Phase 11 roster and zombie variety in place, tuning noise-decay rate, request sizing, and zombie stat numbers against both your own runs and session 14.1's external feedback. Per GDD §14.5's SWOT finding, prioritize balance/telegraphing clarity over adding content — if something feels unfair or illegible, fix the tell or the numbers, not by adding a new system (that call was already made at Phase 9). Log every numeric change and why, since these are the exported/named constants from the start, not magic numbers, so they should already be easy to find and tune.

#### S14.3 — Demo packaging

_Windows export preset, clean-boot verification, freeze feature work._

**Session prompt:** Set up Godot export presets for a Windows Steam demo build, verify the game boots clean from a fresh export (not just in-editor) — per Engineering Lesson E4, headless/editor testing alone doesn't prove this — and package what's needed for a Steam Next Fest page per GDD §17 (Winter Next Fest target, bug-free build as success criterion #1). Before freezing feature work, run the full test suite per the Testing Strategy section's checkpoint rule — this is a ship gate, not day-to-day iteration, so it doesn't get blast-radius scoping either. This session is packaging/export only — freeze feature work before starting it.

#### S14.4 — Retrospective & metrics rollup

_Close the loop this roadmap's whole planned-vs-actual tracking exists for — feed the real numbers back into the shared learning system._

**Session prompt:** Roll up session 0.1's SESSION_LOG.md metrics table into a short retrospective: total planned sessions (56 as of this roadmap's v13 revision — but re-derive this from SESSION_LOG.md's own running tally rather than trusting a number written here, since the plan has grown on nearly every revision and this figure will be stale again by the time this session actually runs) vs. actual, which phases ran closest to plan and which blew past it, and why. Promote whatever's genuinely general-use (not HavenZ-specific) into the shared cross-project learning system at C:\Users\17cor\OneDrive\Documents\Godot\dev-notes\ — append to PENDING_LESSONS.md for anything lesson-shaped, and specifically flag findings relevant to TIMELINE_PITFALLS.md, since that file's estimates currently come from a 26-game external postmortem review, not a real Claude-Code-built project's actual numbers. This is what makes the next roadmap's planned session counts a calibrated guess instead of a fresh one.

## POST.01 — Post-Launch

_Work deliberately left for after the Next Fest demo ships — not urgent enough to risk the ship-critical Phase 14 sessions, but real enough not to lose track of._

#### POST.1 — Extract the UI Shell *[UI Shell extraction]*

_Moved off the pre-ship critical path. Sessions 0.4/4.2/8.5/12.1/12.3 were already built extractable-by-design throughout — this session is the actual pull-into-its-own-repo work, done once there's real post-launch time rather than squeezed in right around the Next Fest ship. Likely undercounted as a single session: defining a generic settings-row interface, a serialization interface, and scaffolding a new repo is realistically several sessions' worth of work — budget accordingly rather than being surprised._

**Session prompt:** Now that HavenZ has shipped and there's real post-launch time to invest in it, pull that code — Main Menu, Settings screen, pause system, save/load, and gamepad virtual cursor (sessions 0.4, 4.2, 8.5, 12.1, 12.3) — into its own standalone Godot addon repo, mirroring how PixelPipe's Godot-side pieces are packaged, sibling location (e.g. C:\Users\17cor\OneDrive\Documents\ next to HavenZ/PixelPipe/Sheepshead), its own docs/ROADMAP.md and docs/LESSONS.md per the established convention. Generalize deliberately as you go: settings become configurable rows (a game passes in its own toggles/sliders), save/load becomes a serialization interface (a game passes in what to serialize, the module never knows about CardResource or CorpseResource specifically), pause keeps the process_mode convention but drops any HavenZ-specific freeze logic. This is the Tier 2 payoff — extracted right after one real proof, not before (unlike PixelPipe) and not after waiting for a second game (unlike the Tier 3 gameplay-system candidates). This exists to serve whatever project comes after HavenZ, the same role PixelPipe plays — HavenZ itself keeps using its original in-tree code and does not switch to depending on the extracted copy.

## FIELD NOTES — Design Recommendations

_Grounded in the current GDD text and the actual asset-pack contents — not invented scope. Art-specific gaps now live in the Asset Audit above; these are broader design calls._

**01 — Scrub the two leftover timer phrases**

`§2.2` "under time pressure" and `§3` "punished by the turn clock" read as remnants of a removed countdown mechanic. Nothing in `§8` or `§12` specifies a clock — Noise is the only pressure system actually designed. Reword both lines to name Noise explicitly so the GDD can't be misread as a spec for a timer that no longer exists.

**02 — The Hunger meter doesn't match the GDD's Food/Water model**

`UI/Hunger/` is a continuously-depleting meter, but `§10.7–10.8` describes Food/Water as one-shot consumed cards. Either hide the Hunger UI for MVP, or repurpose its bar visual for a Home Haven "supply stock" meter — a genuinely continuous quantity that fits the Future System in `§9` ("Room within the Haven... decorating") better than forcing an unplanned survival mechanic.

**03 — The Buildable wall/gate system is a Future System asset, not an MVP one**

`Objects/Buildable/Wooden/` and `Reinforced/` are a fully-modeled, animated wall-and-gate construction kit — but `§11` explicitly excludes Haven building from MVP. Park it now as the ready-made art backbone for the "Haven upgrades" Future System in `§9`.

**04 — Three zombie tiers already map to a natural difficulty curve**

Zombie_Small (fast/weak), Zombie_Axe (ranged/telegraphed/medium), Zombie_Big (slow/tank) are a clean early/mid/late unlock progression with zero new art required — wired directly into Phase 10.2/11.4's shared difficulty value.

**05 — Two "Bat"s will collide in code and conversation**

`Objects/Pickable/Bat.png` is a melee weapon; `Character/Bat/` is an unrelated flying creature. Rename the creature internally (e.g. "MutantBat" or "Swarmer" — already specified in Phase 11.4) the moment it's introduced.

**06 — Recolor variants are free zone variety**

Vehicles ship in 6 colors × 3 wear states, buildings in 4 tones, nature in 5 palettes — all pre-drawn. Assigning a palette variant per map region or per Supply Request difficulty tier (Phase 3.2) gives visually distinct zones at zero additional art cost.

**07 — The Helmet skin is a free progression reward, not dead weight**

No armor system exists in the GDD, but rather than ignore `Character/Helmet/` entirely, tie it to Phase 10.3's starting-loadout progression as a purely cosmetic unlock for a later scavenger tier — zero new code, a visible sign of progress.

**08 — §15/§16 correction (v15)**

§15 (Marketing Strategy & Tools) is not blank — it has table-formatted content that an earlier review's docx/pdf parse missed; verify directly against the current GDD rather than trusting this note. §16's earlier mislabeling (duplicated as a second §17 in an older draft) has already been corrected in the current GDD. No owning session needed here — this recommendation previously flagged a gap that doesn't actually exist.

**09 — Corpse system: room for more emotional weight (open idea, not committed)**

Recovering a corpse currently returns cards and nothing else — no sense of *how* that scavenger died. A one-line death summary on the corpse marker (e.g. "Died to 2× Zombie_Small, turn 14") could sharpen the roguelike stakes the corpse system already exists to create, and session 7.2's death signal already carries enough payload to build it from. Deliberately not scheduling a session for this now — flagging it as something worth revisiting once Phase 8 is real and there's an actual corpse system to react to, not a decision to force ahead of time. Open to other framings too (a short in-world icon set for cause-of-death, a simple stat line, etc.) — this is a direction, not a spec.

## §10 — Card Roster Proposal

_GDD §10 lists categories only ("Need Buildout"). Below is a concrete first-pass roster, built entirely from art that already exists in PostApocalypse_AssetPack_v1.1.2 — this is what Phase 11 implements, on top of the one-card-per-category minimum built in Phase 5-6._

§10.1 — Action Cards: Attacks

| Card | Effect | Asset used | Note |
| --- | --- | --- | --- |
| Bat Swing | Melee, adjacent tile, low noise, no ammo | Pickable/Bat.png | Starter attack card, always available |
| Pistol Shot | Ranged, medium noise/damage, consumes 1 ammo | Guns/Pistol/ | Ammo = Bullet-box Scrap-tier card |
| Shotgun Blast | Ranged, high noise/damage, short range, consumes 1 shell | Guns/Shotgun/ | Loudest attack in the roster — high risk/reward |
| Improvised Rifle | Ranged, mid-tier upgrade between Pistol and Shotgun | Guns/Gun/, Pickable/Gun.png | Crafted upgrade, not a starting card |

§10.2 — Action Cards: Looting

| Card | Effect | Asset used | Note |
| --- | --- | --- | --- |
| Quick Grab | Loot one item from current tile, low noise | Objects/Pickable/ | Baseline loot action |
| Ransack Container | Higher yield, higher noise, one-turn delay | Objects/Container/ (12 variants) | Container color/state can hint reward tier |
| Siphon Vehicle | Scrap/fuel yield from a wrecked car tile | Vehicles/Normal/Car_6_Scrap | The pack already has a purpose-built "Scrap" car variant |

§10.3 — Action Cards: Traps

| Card | Effect | Asset used | Note |
| --- | --- | --- | --- |
| Tire Trap | Immobilize a zombie for N turns | Objects/2-Tires_* | Cheap, low-impact starter trap |
| Barrel Trap | Delayed area damage, big noise payoff | Objects/Barrel_red_* | Pairs well with Fire Barrel distraction below |
| Wire Snare | Silent single-target snare | Tiles/Wire-Fence/ | Quietest trap — rewards Stealth-deck builds |

§10.4 — Action Cards: Distractions

| Card | Effect | Asset used | Note |
| --- | --- | --- | --- |
| Throw Cardboard | Small noise decoy at a target tile | Objects/Cardboard_1.png | Cheapest, weakest decoy |
| Rev Engine | Large noise decoy at range, no line-of-sight needed | Objects/Vehicles/Normal/ | Interact with any parked car on the map |
| Fire Barrel | Noise + delayed area danger, visual set-piece | Objects/Barrel_red_* | Shares an asset with Barrel Trap — reuse, not duplicate, the ignite effect |

§10.5 — Movement Cards: Stealth

| Card | Effect | Asset used | Note |
| --- | --- | --- | --- |
| Careful Step | 1 tile, zero noise | Character/Main/Idle | Baseline stealth move |
| Vault Window | Silent shortcut through a Window tile | Objects/Windows/ (open/broken variants) | Requires matching tile type — see S11.2 |
| Ladder Climb | Silent vertical route, bypasses street-level zombies | Buildings/Ladder_Balcony_Metal_1 | Requires a Balcony/Ladder tile |

§10.6 — Movement Cards: Loud

| Card | Effect | Asset used | Note |
| --- | --- | --- | --- |
| Sprint | 2-3 tiles, high noise | Character/Main/Run | Baseline loud move |
| Smash Through Door | Break a boarded door for a fast route, loud | Buildings/Door_3, Door_6 (boarded) | Requires a boarded-door tile |
| Motorcycle Dash | Big movement burst, very loud, late-game set piece | Vehicles/Normal/Car_9_Motorcycle | Crafted/rare card, not a starter |

§10.7–10.9 — Supply Cards: Food, Water, Medical

| Card | Effect | Asset used | Note |
| --- | --- | --- | --- |
| Canned Food | +1 Action play, destroyed on use | Pickable/Canned-food.png | Common tier |
| Canned Soup | +2 Action plays, destroyed on use | Pickable/Canned-soup.png | Rarer tier |
| Water Bottle | +1 Movement play, destroyed on use | — see Asset Audit, High priority | Needs the commissioned/hand-drawn asset |
| Purified Water | +2 Movement plays, destroyed on use | — see Asset Audit, High priority | Rarer tier, same art gap |
| Bandage | Small HP restore | Pickable/Bandage.png | Common tier |
| First Aid Kit | Large HP restore | Icon_First-Aid-Kit_* (icon only) | Reuses Bandage world sprite per Asset Audit |

§10.10 — Supply Cards: Scrap

| Card | Effect | Asset used | Note |
| --- | --- | --- | --- |
| Scrap Metal | Generic crafting material | Metal-Plates.png, Iron-beam.png, Gray-brick_Debris.png | Feeds most recipes |
| Ammo Components | Crafting material specifically for ranged Attack cards | Bullet-box_*, Ammo-crate_* | 3 color tiers already exist for rarity |
| Vehicle Parts | Rare, high-value crafting material for top-tier upgrades | Vehicles/Normal/Car_6_Scrap | Reinforces Siphon Vehicle's theme |

Sources: HavenZ GDD.docx (most recent version only) · PostApocalypse_AssetPack_v1.1.2.zip (24-sprite seed sample; full extraction happens for real in Phase 2.2 via PixelPipe) · haven-z/project.godot (Godot 4.6, unmodified template) · HavenZ_Roadmap_Briefing_1.md (26-game lifecycle briefing) · Sheepshead project memories (Godot/Claude Code engineering lessons) · PixelPipe (companion standalone-pipeline roadmap, built before HavenZ dev starts, own clock) · self-directed gap review (audio, tutorial, playtesting, localization, backup, colorblind, Steamworks, session log, input scheme) · self-directed timeline/budget SWOT · locked-in gamepad/turn-structure decisions · pause-architecture-timing lesson from prior projects · UI Shell extraction-tier analysis · HavenZ_Noise_System_Design.md (evaluated and folded in, v11) · full roadmap self-audit and correction pass (v12) · TESTING_STRATEGY.md at the shared Godot dev-notes folder (evaluated and folded in, v13) · HavenZ_Radio_System_Summary.md (evaluated and folded in, v14) · self-directed critique pass + author dispositions on each finding (v15-v18) · Compiled 2026-08-06, v18.
