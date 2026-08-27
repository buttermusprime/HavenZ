# HavenZ — Project Conventions

Standing rules every session works under, established ahead of the code that needs them so
nothing gets built against an implicit assumption that has to be retrofitted later. See
`docs/ROADMAP.md` for the session plan and `docs/SESSION_LOG.md` for what's actually shipped.

## Pause convention (established S0.4)

`get_tree().paused` is the single source of truth for whether the game is paused. Every node's
`process_mode` must be set **deliberately**, going forward — never leave it at the
`PROCESS_MODE_INHERIT` default and assume it'll do the right thing.

- **`PROCESS_MODE_PAUSABLE`** — anything that should freeze on pause: zombie AI timers, noise
  decay/propagation ticks, card-resolution animations, the corpse/respawn flow. This is what most
  gameplay nodes want.
- **`PROCESS_MODE_ALWAYS`** (or `PROCESS_MODE_WHEN_PAUSED` for something that should *only* run
  while paused) — anything that must keep responding while the game is paused: the pause menu
  itself, and the gamepad virtual cursor (input has to keep working in order to un-pause at all).

Why this is decided now, before any stateful system exists: retrofitting pause-awareness onto
AI/timers/state-machines that were written without it in mind is expensive, hard-to-track rework,
not a one-session addition — confirmed by direct prior-project experience (see
`docs/LESSONS.md`/the shared `PENDING_LESSONS.md` entry this was flagged into). Session 8.5
builds a real (if UI-minimal) pause menu during the vertical slice specifically so it gets tested
against real AI/state-machine code while the codebase is still small enough to fix cleanly.
Session 12.3 only wires that already-working menu up to Settings/Main Menu once those exist.

**This session establishes the rule only — no pause menu or pause-triggering input exists yet.**
Every session from Phase 1 onward that adds a ticking/stateful node must set its `process_mode`
explicitly per the table above, not leave it at the default.

## Testing conventions (established S0.5)

Folded in from the shared `TESTING_STRATEGY.md` (`Godot/dev-notes/`, GODOT_LESSONS.md #30). The
problem it solves: without an explicit rule, a session defaults to "when in doubt, re-run
everything," which is safe but wastes time on changes that structurally can't touch the rules
engine. This is about skipping *irrelevant* tests, not skipping verification.

**Suite layout — split by layer, not one flat folder:**

- `res://scripts/tests/logic/` — pure rule/data logic, zero UI dependency.
- `res://scripts/tests/ui/` — click-path/interaction tests.
- `res://scripts/tests/integration/` — full-flow/end-to-end checkpoints.

**Depends-on header — required on every test file:** a one-line `# Exercises: file.gd, file2.gd`
comment at the top naming what it covers. Before running tests after an edit, cross-reference the
session's actual changed files (`git diff --name-only`) against these headers — only run matches,
plus anything in `integration/` if the edit was structural or cross-cutting. Cheap to maintain,
turns "which tests cover my change" into a grep instead of a memory exercise.

**Classify the edit by blast radius before choosing what to run:**

| Edit type | What it looks like in HavenZ | What to actually verify |
| --- | --- | --- |
| Cosmetic | StyleBox/tint/alpha tweaks, anchor/position changes — no nodes added/removed, no signal rewiring | A visual spot-check only. Cannot affect pure-logic tests — running them is pure waste. |
| Structural scene edit | Node changes inside a scene, any `%UniqueName` target change | Only the tests that touch that specific scene — genuinely can break something, but the blast radius is still local. |
| Logic | Heat propagation, zombie pathing, play/drop resolution, corpse decay, any pure-rule change | Tests for that system, plus anything that depends on it per the header convention above. |
| Cross-cutting | `CardResource`/`TileResource`/`EnemyResource`/`CorpseResource` schema changes, any autoload | The full suite — this is the one case where broad re-testing is actually correct, not just cautious. |

**How to tell cosmetic from structural mechanically, not by eyeballing intent:** `.tscn` is a text
format — a `git diff` that only touches property values (`position =`, `offset_*=`, `color =`,
`theme_override_*=`) is cosmetic; one that adds/removes a `[node]` or `[connection]` block, or
changes a `unique_name_in_owner` flag, is structural.

**What this does not replace.** Blast-radius scoping is for day-to-day iteration speed between
checkpoints, not a substitute for them. Checkpoints — sessions 1.2, 9.1, 14.1-14.3 — always run
the full suite regardless of how cosmetic recent edits looked, as the backstop that catches a case
where the blast-radius classification itself was wrong.

**This session establishes structure and documentation only — no real tests exist yet**, since no
gameplay code exists yet either. Session 4.1 is the first session to actually populate `logic/`.
