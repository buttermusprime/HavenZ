# Colorblind Accessibility Check — S2.6

Runs the real 141-color master palette (`HavenZ_Field_Palette.gpl`, adopted S2.2) through a
protanopia/deuteranopia/tritanopia simulation and checks whether any information-bearing color
identified elsewhere in the roadmap loses its distinctiveness. This checks the *palette*, not a
rendered feature — nothing in-game currently displays HP Red/Shadow or a heat ring/tint as a
composed UI element, so this is a forward-looking check per the roadmap's own S2.6 framing.

## Method

Each palette color's sRGB byte values were run through three fixed 100%-severity CVD matrices
(the Machado/Viénot-style approximation used by most common colorblind simulators), applied
directly to gamma-space RGB rather than a full linear-light pipeline — accurate enough for a
design-time distinguishability check, not a substitute for a certified accessibility tool.
Distance between two colors is plain Euclidean distance in 0-255 RGB space, computed both on the
original colors and on each simulated output. Full pairwise data (all three groups checked below,
plus every full-palette collapse found) is in the companion `HavenZ_Colorblind_Check.json`.

## Named groups explicitly called out by the roadmap

**Hazard-red family** (Rust Red, Brick Red, Brick Shadow, Deep Rust, Dark Brick — "one shared
warm-red family" per the Color Palette section) and **HP/vitality** (HP Red, HP Shadow): checked
all pairwise distances within and across these two groups under all three simulations. **No new
collapse.** The closest pair in the family, Brick Shadow vs. Deep Rust, is already only 11.3 apart
under normal vision (they're deliberately close — both read as "dark rust" on purpose) and stays
proportionally close under every simulation (8.8–9.9) rather than collapsing further. Every other
in-family and HP-vs-hazard-red pair stays well-separated (25+) under all three simulations.

**Undead-related** (Old Blood, Sickly Green, Bruise Mauve): Old Blood stays extremely distinct
from both Sickly Green and Bruise Mauve under every simulation (130+). Sickly Green vs. Bruise
Mauve narrows the most of the three (48.0 original → 27.3 under deuteranopia) but doesn't collapse
outright.

## Real cross-palette findings

A full pairwise scan of all 141 colors (flagging any pair that starts 25+ apart but lands under 12
apart post-simulation) surfaced two hits that touch a named, information-bearing color:

- **HP Shadow vs. an unnamed reconciled pack color `(127, 63, 70)`** — 29.2 apart normally, only
  10.0 apart under protanopia.
- **HP Red vs. an unnamed reconciled pack color `(168, 105, 90)`** — 26.3 apart normally, only
  9.2 apart under deuteranopia.

Both unnamed colors came in through S2.2's pack reconciliation (101 colors added beyond the
40-color seed) rather than being deliberately chosen — they're generic dark-reddish-brown pack
tones, not anything currently identified as belonging to a specific object category. **Not
actionable today**: nothing in the game currently renders HP Red/Shadow as a UI element (the
gray-box's HP display is a plain `Label`, no color-coding yet — that's Phase 4/6/12 scope), so
there's no actual on-screen pairing to conflict with yet. Worth a second look once real HP-colored
UI exists, and a candidate first place to check if a colorblind player ever reports "I can't tell
if that's a health bar or scenery."

**Sickly Green** (the color explicitly earmarked to visually identify zombies, and deliberately
shared with Leaf Highlight per the palette doc's own "what the sampling found" note) shows up in
several full-palette collapses across all three simulation types — against Warm Highlight and
Parchment Shadow under protanopia, against Bat Fur under tritanopia, and against a handful of
unnamed muted pack tones under both red-green simulations (full list in the JSON). None of these
are rendered together in any current scene, so again not actionable today, but worth re-checking
once zombie sprites and any UI panel using those neutral tones actually share a frame — a
colorblind player picking a zombie out from a background panel is exactly the failure mode this
check exists to catch.

## Heat ring/tint (Phase 12.5)

Not built yet — no specific hue has been assigned to the future diegetic heat display, so there's
nothing to simulate yet. Per the roadmap's own text, session 12.5 re-runs this exact check against
the real rendered ring/tint colors once they exist; this session's contribution is confirming the
*rest* of the palette's information-bearing colors are clean now, so 12.5 only needs to check the
new colors it introduces, not re-audit the whole palette from scratch.

## What was *not* flagged

The full-palette scan surfaced 40-60 additional collapsing pairs per simulation type beyond the
two above — almost all of them are between generic reconciled environmental/scenery tones (muted
grays, tans, and pinks pulled in during S2.2's pack reconciliation) that were never intended to be
told apart from each other in the first place — background variety, not information. Not listed
individually here; see the JSON if a specific pair needs checking later.

## Recommendation

No palette edit needed right now — every real collapse found sits on a color pairing that doesn't
exist on-screen together yet. Two forward pointers instead of a fix: (1) when Phase 4/6/12 builds
real HP-colored UI, re-check it against whatever pack-derived prop colors end up sharing that
scene, using the two unnamed hex values flagged above as the starting suspects; (2) when zombie
sprites and background scenery using Warm Highlight/Parchment Shadow/Bat Fur-adjacent tones share
a frame, re-check Sickly Green's distinguishability against them specifically. Both are cheap to
re-run — same script, same threshold — against whatever the real composition looks like at that
point, rather than fixed now against a hypothetical one. If either check comes back bad in
context, feed the fix through S2.4's remap shader (still deferred, not yet built) rather than
re-touching source art.
