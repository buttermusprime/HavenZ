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
