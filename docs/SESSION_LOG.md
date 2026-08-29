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
| 1 | 1.1 | build | 1 | 6 | 6 sittings | no |
| 1 | 1.2 | checkpoint | 1 | 1 | 1 sitting | no |
| 2 | 2.1 | build | 1 | 1 | 1 sitting | no |
| 2 | 2.2 | build | 1 | 1 | 1 sitting | no |
| 2 | 2.3 | build | 1 | 1 | 1 sitting | no |
| 2 | 2.5 | build | 1 | 1 | 1 sitting | no |
| 2 | 2.6 | build | 1 | 1 | 1 sitting | no |
| 3 | 3.1 | build | 1 | 1 | 1 sitting | no |
| 3 | 3.2 | build | 1 | 1 | 1 sitting | no |

## Entries

### S3.2 — World set-dressing & biome zones

**Shipped:** 10 fixed, non-functional decoration props from `res://art/Objects/{Nature,Buildings,
Vehicles}/`, purely visual per this session's own scope — no `TileResource` field touched, no
movement/noise interaction. A new `_zone_for_coord()` splits the map diagonally (Home Haven
top-right, the other Haven bottom-left, so a tile's `x - y` sign alone says which corner it's
nearer) into GREEN/BLEAK_YELLOW zones, reusing the same two tints S3.1 already reserved for each
Haven's entrance — matched with a real tree/bush/grass/HVAC prop from each zone's actual pack
folder (`Nature/Green` vs `Nature/Bleak-Yellow`, `Buildings/HVAC_Overgrown_Green` vs
`_Bleak-Yellow`), plus one zone-neutral vehicle wreck per side (`Car_9_Blue_Motorcycle_Side`,
`Car_6_Blue_Scrap`) for flavor. Coordinates are hand-picked and fixed, same "no level-design
tooling yet" reasoning S3.1 used for the Haven rectangles — not randomized, so the layout stays
exactly reproducible.

**Corrected against the real asset pack, not the roadmap's literal text:** the session prompt
names "beige vs. gray vs. dark buildings" as the Buildings-side zone variant, but no such 3-way
building-shell tint actually exists in the pack (confirmed by searching the full asset tree).
Substituted the real per-zone-tinted asset that does exist instead —
`HVAC_Overgrown_{Green,Bleak-Yellow}` — the same "correct provisional/imprecise roadmap text
against the real asset shape" pattern S2.1 already established for `pixel_scale`/`ignore_globs`.

**Verified headlessly** (throwaway script, deleted after use): exactly 10 dressing entries, none
colliding with either Haven's footprint or the player/enemy start coordinates, no duplicate
coordinates, every prop's chosen art genuinely matches what `_zone_for_coord()` computes for its
coordinate (checked programmatically, not just by hand-arithmetic), no dressing tile's
`TileResource` flags were touched, and the existing loot-avoids-walls behavior (S3.1) still holds
as a regression check. Then did a real-GPU screenshot capture (same technique as S3.1/PixelPipe's
D.2) and confirmed by eye: the green-zone and bleak-zone props are clearly, correctly distinct in
color at actual render scale, and the scrap-car wreck (initially looked like a rock pile at a
glance) is a real, correctly-rendered crushed-metal design once zoomed in, not a broken sprite.

**Stubbed / deferred:** exactly the 10 props above, no procedural/random dressing generation
(would need real level-design tooling, out of scope for a fixed 10x8 gray-box grid). Vehicles
only ship in their single kept color (Blue) per S2.1's Asset Audit deprioritization of the full
recolor matrix — no color-based zone signal from vehicles, only from Nature/Buildings props.

**Next:** Phase 4 (Deck / Hand / Play-Drop Systems), starting S4.1, per the roadmap.

### S3.1 — Haven placement & wall/entrance tiles

**Shipped:** a Home Haven (top-right, x6-9/y0-2) and one other Haven (bottom-left, x0-3/y5-7) per
GDD §8.1 — fixed 4x3 rectangles, hand-placed (no level-design tooling exists yet, same as the
terrain grid itself). New `data/HavenResource.gd` (id/display_name/is_home — deliberately small;
layout is placement data owned by the scene, not the resource). Walls use S2.3's real Buildable
art (`Wooden-wall_Horizontal/Vertical` + 4 corner-connector pieces, corner-to-position mapping
inferred from filenames since the pack documents nothing more specific — flagged for a visual
spot-check, done via a real-GPU screenshot capture this same session: layout reads correctly, no
mismatched corners). The entrance uses `Enterance_Green.tscn`, reserved exclusively for the Home
Haven per this session's own ask; the other Haven uses `Enterance_Bleak-Yellow.tscn` — confirmed
via a real pixel diff that the two tints genuinely differ (71 of 837 opaque pixels, swapping a
green foliage accent for a yellow-tan one), not just two copies of the same file under different
names. New `haven_entered(haven: HavenResource)` signal fires the instant the player's move lands
on an entrance tile; `_on_haven_entered` stubs the reaction with a `TODO(Phase 10)` per this
session's explicit "don't build the menu yet" scope.

**Made `blocks_zombie`/`walkable` real for the first time** (both existed on `TileResource` since
S0.2 but nothing ever read either field): wall tiles are `walkable=false`/`blocks_zombie=true`/
`blocks_noise=true`; the entrance tile is `walkable=true` but still `blocks_zombie=true` (GDD
§8.1's "safe because walls physically stop zombies" applies to the entrance too — only the
*player* gets through) and still `blocks_noise=true` (noise blocking stays uniform around the
whole perimeter rather than leaking through the one gap). `_get_valid_move_tiles()` now excludes
non-walkable destinations, and `_place_loot_tiles()` now excludes them from its candidate pool too
(a real latent bug that would've let a loot tile spawn permanently unreachable on a wall the
moment any wall existed). `_step_toward()` (enemy pathing) now tries its preferred axis, falls
back to the other axis if a wall blocks it, and simply doesn't move if both are blocked — still
not real pathfinding (Phase 7.1's job), but `blocks_zombie` is no longer inert data, the same
class of gap this project has flagged before (PixelPipe's `ignore_globs` went unconsumed for a
full session before anyone noticed).

**Real bug found and fixed, caught by writing the verification checks rather than assumed
correct:** a straight-line movement card could hop clean over a 1-tile-thick wall onto a walkable
tile beyond it, since only the destination's own `walkable` flag was ever checked, not the path.
Fixed with a small Bresenham line-walk (`_tiles_along_line`/`_path_crosses_wall`) that rejects a
destination if any tile strictly between the player and it is non-walkable. **A second, more
significant bug found the same way, in the heat-bleed system S2.5 shipped:** S2.5's own code
comment had explicitly flagged "no real walls exist until Phase 3.1, so there's nothing to get
wrong yet, revisit once that session actually exercises blocks_noise for real" — and it was right
to flag it. `_compute_heat_bleed()` only ever checked the FINAL target tile's `blocks_noise`, not
anything between source and target, so heat placed just outside a Haven's wall bled straight
through it into the interior tile immediately behind at ring 2, identical to the just-fixed
movement bug. Fixed by reusing the same Bresenham helper (`_bleed_path_blocked`) to check the
whole line, not just the endpoint. Verified directly: heat from a tile outside the home haven's
wall no longer reaches the interior tile behind it, while an equivalent open-field tile at the
same ring distance still receives bleed normally — the session's own explicit "verify noise
visibly stops at a Haven wall" ask, now actually true rather than accidentally true only because
no test had exercised the gap yet.

**Verified headlessly** (throwaway script, deleted after use, per this project's established
pre-4.1 convention): Haven tile flags (wall vs. entrance vs. interior) correct at every checked
coordinate; entrance registers the right `HavenResource` with the right `is_home`; no loot tile
ever lands on a wall; a wall tile is never a valid movement destination; the wall-crossing bug
above, confirmed fixed; zombie pathing rejects a wall-blocked step; both heat-bleed bugs above,
confirmed fixed (blocked through a wall, still bleeds normally in the open). Hit two real GDScript
gotchas along the way, both already-known project lessons re-confirmed rather than new: a script
referencing a `class_name` created outside the editor needs one `--headless --editor --quit` pass
before `--script` mode can resolve it (this session's `HavenResource` was created via a plain file
write, never opened in-editor); and reading a freshly-`add_child()`ed node's state inside a
`SceneTree`-script's `_initialize()` needs an `await process_frame` first, since `_ready()` hasn't
necessarily run yet — this script is the `SceneTree` itself, so the fix is bare `await
process_frame`, not `await get_tree().process_frame` (no `get_tree()` from here). Then did a real
non-headless, real-GPU screenshot capture (same technique as PixelPipe's D.2 session) specifically
to spot-check the inferred wall-corner-art mapping and the two entrance tints — both confirmed
correct by eye and by a pixel diff, not just assumed from the filenames.

**docs/ROADMAP.md:** found a real, substantial addition already sitting in the working tree when
this session started — a new "Session Status & Progress" table (START.00) and a v19 changelog
entry, evidently from another concurrent session per this project's documented pattern of parallel
sessions developing the same roadmap independently. Content was accurate as of S2.6 and not in any
conflict with this session's own work, so kept it rather than discarding it, and updated the S3.1
row/summary counts/the "Next" pointer to reflect this session's own completion rather than leaving
it stale.

**Stubbed / deferred:** Trade/Craft menu (Phase 10, explicitly out of scope — see the TODO
comment). Haven interior tiles are plain floor, no dressing (Phase 3.2's explicit job). The
heat-bleed fix is a straight-line check, not full line-of-sight — a wall exactly one tile off the
direct line between source and target could still be "seen past" at ring 2; flagged, not solved,
same "worth revisiting if a session actually needs it" spirit as the gap this session just closed.

**Next:** S3.2 (world set-dressing & biome zones) per the roadmap.

### S2.6 — Colorblind accessibility check

Ran the real 141-color master palette (S2.2) through protanopia/deuteranopia/tritanopia
simulation (Machado/Viénot-style 100%-severity matrices, applied directly to sRGB) via a
throwaway Python script — full pairwise distance data written to
`palette/HavenZ_Colorblind_Check.{md,json}` for future re-use rather than left as a one-off.

**Named-group check (hazard-red family, HP/vitality, undead-related) — clean.** No pair within or
across these groups collapses under any simulation beyond what's already close under normal
vision (Brick Shadow/Deep Rust, 11.3 apart originally, is the closest in-family pair and stays
proportionally close, not closer, post-simulation).

**Two real cross-palette findings, both forward-looking, neither actionable today:** (1) HP
Shadow collapses with an unnamed reconciled pack color `(127,63,70)` under protanopia (29.2 →
10.0), and HP Red similarly with `(168,105,90)` under deuteranopia (26.3 → 9.2) — both unnamed
colors came in through S2.2's reconciliation, not a deliberate choice. Not actionable now since no
HP-colored UI exists yet (the gray-box HP display is a plain `Label`); flagged as the first
suspects to re-check once Phase 4/6/12 builds real HP-colored UI. (2) Sickly Green (explicitly the
zombie-identification color per the palette doc) collapses against several neutral tones (Warm
Highlight, Parchment Shadow, Bat Fur, a handful of unnamed pack grays/tans) across all three
simulation types — again not actionable since no zombie sprite and conflicting-tone UI panel share
a frame yet; re-check once they do.

**Heat ring/tint (Phase 12.5): nothing to check yet** — no hue is assigned to that display
because it isn't built. Per the roadmap's own text, 12.5 re-runs this same check against the real
rendered colors once they exist.

**Not flagged:** 40-60 additional full-palette collapses per simulation type, almost all between
generic reconciled background/scenery tones never intended to be distinguished from each other —
expected, not actionable. Full list in the JSON if a specific pair ever needs checking.

**No palette edit made.** Two concrete re-check pointers left for whichever future session first
renders HP-colored UI or a zombie-adjacent scene using the flagged neutral tones — if either comes
back bad in context, the fix path is S2.4's remap shader (still deferred, not yet built), not
re-touching source art.

**Next:** Phase 2 (Art Pipeline Adoption) is now fully closed out — S2.4 (palette tuning) remains
explicitly deferred until real HP/zombie UI exists to check the two pointers above against, or
Phase 3 (Grid, Havens & World, starting S3.1) per the roadmap.

### S2.5 — Reskin the validated gray-box

**Visuals (no gameplay logic touched):** real tile art (`Background_Green_TileSet.png`, one
plain-grass atlas cell picked by eye) now renders via a real `TileSet`/`TileMapLayer` built at
runtime in a new `_build_terrain()`, sitting behind the existing per-tile heat/highlight overlay
`ColorRect`s — those are now semi-transparent (`OVERLAY_ALPHA = 0.55`) instead of fully opaque, so
the real art shows through; the heat-tint color math itself is unchanged except for explicitly
carrying alpha through (`Color(r,g,b)`'s 3-arg constructor silently defaults to opaque, which
would have clobbered the new transparency the instant any tile's heat rose above 0 — caught before
it shipped). `PlayerVisual` is now a real instanced scene
(`art/Character/Main/Idle/Character_down_idle-Sheet6.tscn`, S2.5's headless-import output) with its
`AnimatedSprite2D` explicitly `.play()`ed in `_ready()` — `build_scene()` selects the animation but
never starts it. `TILE_SIZE` changed from the gray-box's arbitrary 24px placeholder to the real
16px logical unit locked in S0.1; `GridVisual`'s position re-centered for the new grid pixel size.
Enemy square deliberately left as a plain `ColorRect` — nothing in this session's scope asked for
reskinning it.

**Logic (the one thing this session was explicitly allowed to extend):** heat decay is now real
ring-based propagation per the Noise System Design's starting parameters — 40% of a source tile's
own current heat bleeds to every tile 1 ring out, ~15% at 2 rings out (Chebyshev distance, the
standard tile-grid meaning of "N tiles out" — deliberately different from the movement system's
Euclidean range check, which answers a different question). Bleeding does NOT deplete the source
(heat is a telegraph signal, not a moved resource). Gated by `TileResource.blocks_noise` on the
*target* tile (a source keeps generating heat even if walled off; a neighbor past that wall just
never receives it) — no walls exist until Phase 3.1, so this path is unexercised in practice today,
written and verified against a synthetic flag now per the roadmap's explicit ask. Kept generic in
shape per the Modular Systems section (only the `tile.heat` field access and the two fraction
constants are heat-specific) without extracting it into a separate file yet — same "tag now,
extract on the second real use" pattern already established elsewhere in this project.
`_decay_tiles()` renamed to `_propagate_and_decay_tiles()`, split into two passes (compute every
bleed delta from one heat snapshot, then apply bleed, then decay) so a tile's bleed contribution
can never depend on dictionary iteration order.

**Real bug caught immediately by the standard headless editor pass, before any functional
testing:** `var target_coord := source_coord + Vector2i(dx, dy)` failed to parse — `source_coord`
comes from an untyped `Dictionary`'s `.keys()`, so it's `Variant` to the static parser even though
it's always a `Vector2i` at runtime, the same family of inference gap as the already-known
untyped-array-indexing gotcha. Fixed with an explicit `: Vector2i` type instead of `:=`.

**Verified headlessly** (throwaway script, deleted after use, per this project's established S1.1+
precedent — no committed test file yet): terrain has exactly 80 used cells; the player sprite has
6 real frames and reports `is_playing() == true`; overlay alpha is 0.55, not the old opaque 1.0;
heat-bleed math is exactly right (a 10.0-heat tile bleeds 4.0 to every ring-1 neighbor — orthogonal
AND diagonal, confirming the Chebyshev ring logic — and 1.5 to ring-2, nothing to ring-3); flagging
a ring-1 neighbor `blocks_noise = true` correctly zeroes its own delta while leaving others intact;
the source tile's own heat is unchanged after computing deltas (confirms non-depletion); and full
existing movement/card-play regression still works end to end (selecting a real move card from the
hand, computing valid tiles, and actually moving there all behave identically to before).

**Next:** Phase 2 (Art Pipeline Adoption) is now functionally complete for the gray-box's own
needs — S2.4 (palette tuning) can be revisited now that real art actually renders somewhere, or
Phase 2.6 (colorblind check) / Phase 3 (Grid, Havens & World) per the roadmap.

### S2.4 assessed, deferred — and a real capability unlock found while investigating why

S2.4 ("apply it live and iterate visually in the running game") has no running game with real
art in it yet — the gray-box still renders `ColorRect`s, and nothing had imported any of S2.3's
new art into a scene. Checked for objectively "weird" colors anyway (saturation outliers against
the pack's established muted family): the top candidates all traced to legitimate, intentional
content — fire/muzzle-flash frames and "Red"/"Orange" autumn-toned nature variants (no matching
named biome in the GDD yet, a content-scope question, not a color-mistake one) — nothing read as
an actual error. User chose to defer S2.4 rather than force a decision without real rendered art
to look at.

**While investigating that blocker, found a real capability unlock in PixelPipe itself:** D.1's
long-standing finding ("`EditorScript` can't run outside a live interactive editor, no CLI path
exists") turned out to have been over-applied — that's true of the *wrapper* file
(`import_sprite_frames.gd`), but the actual `SpriteFrames`-building logic lived in a separate
`RefCounted` class with zero editor-only API calls. Extracted the shared logic and added
`import_sprite_frames_headless.gd` (plain `SceneTree`, `godot --headless --script`) in PixelPipe's
repo — confirmed for real against HavenZ's own synced art, not just PixelPipe's synthetic
fixtures. **Ran it for real: all 761 of S2.3's exported assets now have a real `SpriteFrames`-backed
`.tscn` scene under `res://art/`, built with zero live-editor time.** This removes what S2.3 had
flagged as an open, editor-time-gated item. Logged as a general Godot lesson in the shared
`PENDING_LESSONS.md`, not just here — it applies to any project that assumed an `EditorScript`'s
restriction extends to logic it merely happens to contain.

**Real, more significant gap surfaced by actually building all 761 scenes and checking their
content, not just their existence:** every single one of the 761 exported assets has exactly 1
frame — confirmed concretely on `Character_down_idle-Sheet6.png` (78×16, cleanly 6 frames at
13px each) that the pipeline has **no grid-slicing step anywhere** — Phase C.2's conversion and
Phase C.3's export both treat every source PNG as one whole static frame, sheet-suffix filename
or not. An `AnimatedSprite2D` built from an "idle-and-run-Sheet6" source today would show all 6
walk-cycle poses squashed side-by-side into one static frame, not a real animation. Non-animated
single-pose assets (icons, tiles, static objects) are unaffected. **Not fixed this session** — this
is a real, undecided pipeline design question (how should frame count/dimensions be determined:
filename convention, explicit metadata, Aseprite's own spritesheet-import grid-slice feature?),
not a quick patch, and needs a decision before S2.5 can use any multi-pose Character sheet for
real animation. Flagged to the user rather than guessed at.

**Sheet-slicing gap resolved, same sitting.** Confirmed the real convention against the pack
(264/268 real "-SheetN.png" files divide their width evenly by N, a horizontal strip — the 4
exceptions have a stale frame count baked into their own filename, a pre-existing pack data issue,
not a parsing bug) and fixed it directly in PixelPipe's `convert_indexed.lua` — full detail in
that repo's own `docs/LESSONS.md`. Found and fixed a second real Aseprite Lua bug along the way:
`Sprite:newCel()` copies its `Image` argument at call time rather than keeping a live reference,
so every frame must be fully painted before `newCel` is called, not after (the first slicing
attempt produced 6 frames that all rendered identically, traced to exactly this). Re-ran the
entire pipeline from scratch — conversion, sync, `.import` generation, and the new headless
SpriteFrames rebuild — and verified for real: `Character_down_idle-Sheet6` now has 6 genuine,
pixel-perfect distinct frames; the 4 known-mismatched files correctly fall back to 1 frame with a
warning; a plain non-sheet vehicle asset is unaffected.

**Next:** S2.5 (reskin the gray-box) can proceed for real — every real animated Character sheet
and every static Object/Tile asset are both correctly represented now.

### S2.3 — Real pack conversion & sync

Ran PixelPipe's real Aseprite-CLI batch conversion against the full real pack, using S2.2's
141-color master palette and `convert_indexed.lua`'s own (previously undocumented in the
README, but real and working) `--script-param ignore=...` flag — passed the same 15 patterns
from `pixelpipe.config.json`'s `ignore_globs` directly, since the Python-side wiring for that
field is still the separately-flagged gap. **761 converted, 352 skipped (ignored), 0 errors.**
Then ran `pixelpipe_sync.py`, exporting all 761 to `res://art/` (sheets, per-asset JSON,
`asset_manifest.json`) — clean, 0 errors.

**Real bug found during the roadmap's own required spot-check (a character sheet, a building
tile, a vehicle) — not a hypothetical, this is PixelPipe's first real-world test just as the
roadmap anticipated:** the character sheet (`Character_side-left_death2-Sheet7.png`) exported
completely blank — 0 opaque pixels out of 2,352, despite the original having real content.
Traced to a genuine PixelPipe bug: this source PNG is itself palette-mode (`P` in Pillow), and
Aseprite opens it preserving `ColorMode.INDEXED` rather than always RGB — `convert_indexed.lua`
called `app.pixelColor.rgbaA/R/G/B()` unconditionally, which silently misreads a raw indexed
pixel value (a palette index) as if it were packed RGBA, reading alpha=0 for everything, no
error anywhere in the chain. **116 of the pack's 1,113 real PNGs are palette-mode** — a
non-trivial fraction, not a one-off. Fixed directly in PixelPipe's own repo (`5201b8c`): force
`app.command.ChangePixelFormat{format="rgb"}` right after opening each source sprite if it
isn't already RGB — confirmed via a real Aseprite CLI session that this recovers real pixel data
(colorMode 2→0, 0→931 real opaque pixels) and is a no-op on already-RGB sources (verified against
the vehicle sample, identical results before/after). Re-ran the full conversion and re-synced
from scratch after the fix; wrote a verification pass checking all 88 kept converted files that
trace back to a palette-mode source (28 of the 116 were correctly among the ignored 352) — **zero
still blank.**

**Final spot-check, all three categories clean:** character sheet (147×16, 931 opaque px, was
the blank one — now fixed), building tile (`Objects/Buildings/Roof-hole_1_Gray.png`, 13×15, 114
opaque px), vehicle (`Car_1_Blue.png`, 25×37, 698 opaque px) — dimensions match source exactly in
all three, and every opaque pixel in all three lands exactly on the 141-color master palette,
zero off-palette pixels.

**Shipped:** `haven-z/art_source/` (761 real `.aseprite` files, first real content) and
`haven-z/art/` (761 exported PNG+JSON pairs + `asset_manifest.json`) — both real, not fixtures.
Deleted the throwaway debug Lua/Python scripts and raw conversion/sync logs used to diagnose the
bug; the fix itself lives in PixelPipe's repo, not copied into HavenZ.

**Next:** no new HavenZ `SpriteFrames` scenes were built yet — D.1's `import_sprite_frames.gd` is
an `EditorScript` and genuinely cannot run outside a live interactive editor (confirmed by
PixelPipe's own D.1 session), so building real scenes from this export is deferred to whichever
future gameplay session first needs a specific asset, not done wholesale here. S2.4 (HavenZ
palette tuning pass via the remap shader/LUT) per the roadmap.

### S2.2 — Real palette extraction & reconciliation

Ran PixelPipe's real full-folder extraction against the actual 1,113-file `PostApocalypse_AssetPack_v1.1.2`
(not a sample) via `extract_palette.py --config`: **263 unique colors** at exact-match quantization —
already over Aseprite's 256-color Indexed cap on its own, confirming this session's own "does it fit,
or does it need quantization" question was a real one, not a formality.

Reconciled against the S2.1 seed `HavenZ_Field_Palette` (40 colors): **0 exact matches, 139
near-matches (all within the 16.0 threshold, mostly single-digit RGB distance — anti-aliasing/dither
noise around each seed color, not evidence the seed was wrong), 124 genuinely new colors.** Zero
exact matches makes sense once you look at the near-match distances — the seed's flat "true" colors
generally aren't literally present as pack pixels (real sprites are full of AA blending), so
`quantize_step=1` extraction never counted them as identical; PixelPipe's own nearest-color-match
conversion (C.2) already absorbs all 139 near-matches into their closest master neighbor
automatically, so nothing here needed manual re-mapping.

**Real, concrete proof the `ignore_globs` gap (flagged as a background task during S2.1) actually
matters, not just in theory:** cross-referenced all 124 new colors' source file lists against the
same ignore-glob patterns already sitting inert in `pixelpipe.config.json`. 23 of them are sourced
*exclusively* from deprioritized-asset files — most visibly `(11, 8, 61)`, a jarring saturated
navy that doesn't belong anywhere near this palette's muted family, traced to
`Puddles-And-Water-Anim`'s rain/downspout animation frames (already flagged in the Asset Audit as
"ignore or deprioritize"). Since the tool can't filter these out itself yet, filtered them out by
hand for this session's own new-color set (20 further colors are only *partially* attributable to
deprioritized files and were correctly kept, since they're still needed for the surviving content
that shares them).

**Master palette adopted:** `haven-z/palette/HavenZ_Field_Palette.gpl` overwritten in place (same
config path, so nothing downstream needs to change) — 40 original seed colors + 101 real
hand-filtered new colors = **141 total**, comfortably under the 256 cap. **No quantization pass
needed.** Verified via PixelPipe's own `read_gpl()` (parses clean, correct named/unnamed split) and
a real headless Godot run (palette table dock reports "Loaded 141 color(s)"). Kept
`HavenZ_Extracted.{json,gpl}` and `HavenZ_Reconciliation.json`/`_Report.md` alongside it in
`palette/` as the paper trail for how the 141 were arrived at; deleted the intermediate
`HavenZ_Master_Proposed.gpl` once folded into the real file.

**Next:** S2.3 — real pack conversion & sync (produces HavenZ's actual `res://art_source/` and
`res://art/` for the first time).

### S2.1 — Configure PixelPipe for HavenZ

### S2.1 — Configure PixelPipe for HavenZ

Per this session's own provisional-text instruction, opened PixelPipe's real `README.md`/`docs/ROADMAP.md`
before writing anything, and found real mismatches against what this roadmap assumed:

- **`pixel_scale` is not a display-scale multiplier.** The roadmap's own S2.1 text described "one
  canonical screen-pixels-per-native-pixel scale factor" — but PixelPipe's actual `pixel_scale`
  field is a narrower art-hygiene check (`asset_validator.gd`): every exported PNG's dimensions
  must be a clean multiple of it. It never touches on-screen sizing — that's entirely Godot's
  `canvas_items`/`integer` stretch mode, already locked in S0.1, unaffected by this tool. Inventoried
  real dimensions across all 1,113 PNGs in `PostApocalypse_AssetPack_v1.1.2` (Python/Pillow) and found
  them irregularly cropped to content bounds — `(15,15)`, `(39,20)`, `(7,8)`, `(147,16)` sheets, etc. —
  not aligned to any shared grid, so **`pixel_scale=1`** is the only honest value (anything higher
  would fail validation on most of the pack immediately). The 16px "logical tile" used for the
  viewport/camera grid (S0.1) is a separate, already-solved concept and doesn't come from this field.
- **`ignore_globs` is validated but never actually consumed anywhere in PixelPipe v1** — confirmed
  by reading `extract_palette.py`, `convert_indexed.lua`, and `pixelpipe_sync.py`: the field exists in
  the config schema (so a config naming it validates fine) but no script filters anything against it.
  Flagged as a separate task rather than patched here (touching PixelPipe's own pipeline scripts is
  out of scope for a HavenZ config session) — see the flagged background task. Populated HavenZ's
  `ignore_globs` with the real intended patterns anyway (Asset Audit's deprioritized groups: gun
  reload/racking sheets, `UI/Hunger/`, rain/puddle weather animation, the full vehicle recolor
  matrix minus one canonical color per car) so it's ready the moment that gap is closed — currently
  inert, not yet actually filtering S2.2's real extraction.
- **Two hardcoded `test_fixtures/` paths the README's own quickstart doesn't mention**, beyond the two
  dock `@export var config_path` fields it does call out: `validate_assets.gd`'s
  `DEFAULT_CONFIG_PATH` and `import_sprite_frames.gd`'s `DEFAULT_ROOT` were both still pointing at
  PixelPipe's own test fixtures. Repointed both (`res://pixelpipe.config.json`, `res://art`) in
  HavenZ's copy of the addon.

**Shipped:**
- `haven-z/pixelpipe.config.json` — real config, validated clean via PixelPipe's own
  `pixelpipe_config.py`. `source_packs` points at the now-unzipped
  `../PostApocalypse_AssetPack_v1.1.2` (HavenZ root, sibling to `haven-z/`); `art_source_path`/
  `art_path` are `art_source`/`art` inside the Godot project; `localization_output_dir` reuses
  S0.1's existing `localization/` folder so PixelPipe's generated `display_names.csv` lands
  alongside `strings.csv`; `selectable_asset_globs` left empty for now — no real card-art asset
  keys exist to mark yet, that's Phase 11 scope.
- `haven-z/palette/HavenZ_Field_Palette.gpl` — the 40-color seed palette from this roadmap's own
  START.03 section, written out as a real GIMP-palette file for the first time (previously only
  documented as hex values in the roadmap text). This is explicitly the *seed*, not final — S2.2's
  real full-pack extraction supersedes it.
- `haven-z/addons/pixelpipe/` — PixelPipe's addon package copied in, `.uid` cache files stripped
  (let Godot regenerate its own fresh UIDs for this project rather than carrying over PixelPipe's),
  `live_remaps.json` reset to `[]` (the copied file initially carried over 3 real audit-log entries
  from PixelPipe's own Phase F testing — not HavenZ's history). Enabled in `project.godot` under a
  new `[editor_plugins]` section.
- Unzipped `PostApocalypse_AssetPack_v1.1.2.zip` to a sibling folder at the HavenZ project root
  (1,113 PNGs) — this is the real `source_packs` target; the zip itself is left untouched.

**Unblocked, same sitting:** the user closed the open editor; ran `godot --headless --editor --quit`
once to confirm the install. Plugin registered all 4 global classes (`PixelPipeAssetValidator`,
`PixelPipeAuditLog`, `PixelPipeLutGenerator`, `PixelPipeSpriteFramesImporter`), the palette table
dock loaded all 40 colors from the real `HavenZ_Field_Palette.gpl`, and the duplicate-recolor dock
correctly reported no `asset_manifest.json` yet (expected — no sync has run). **One real bug found
and fixed:** stripping the copied addon's `.uid` sidecar files (done to avoid carrying over
PixelPipe's own project-specific UID cache) wasn't quite enough — `shared_palette_material.tres`'s
`ext_resource` header has the shader's UID baked directly into the resource text, not just via the
sidecar, so it kept pointing at PixelPipe's stale `uid://kl036wpq7h62` even after Godot regenerated
a fresh `uid://o6arbiuo62fp` for the local `palette_unified.gdshader`. Godot degraded gracefully
(fell back to the text path, not a hard failure) but logged a warning on every load. Fixed by hand-
editing the `.tres`'s `ext_resource` line to the new UID; re-ran headless and confirmed the warning
is gone, only the two expected PixelPipe log lines remain. Worth remembering for any future
addon-copy-across-projects: sidecar `.uid` files aren't the only place a UID reference lives —
`.tres`/`.tscn` files can embed one directly in an `ext_resource` header too.

**S2.1 complete.** Committed locally (not yet pushed — ask before pushing).

**Next:** S2.2 (real palette extraction & reconciliation against the full ~1,100-file pack, which
is what actually supersedes this seed palette).

### S1.2 — Playtest & go/no-go: PASS

The user played the gray-box for real (through sitting 6's diagonal-range fix) and confirmed the
noise/card-hand tension works — a genuine "go" on the first attempt, not one of the checkpoint's
up-to-3 iterate-and-recheck rounds. Phase 1 (Concept Validation) is closed. Phase 2 (Art Pipeline
Adoption) begins with S2.1.

**Next:** S2.1 — configure PixelPipe for HavenZ.

### S1.1 (sitting 6) — fix: flooring the distance before the range check let corners cheat

Sitting 5's implementation had a real bug the user caught immediately from a screenshot: flooring
the true distance and THEN comparing to range let tiles that are actually farther than the range
sneak in — a range-2 card's screenshot showed the full 5x5-minus-center square highlighted
(24 tiles), including the (±2,±2) corners at true distance 2.83, because `floori(2.83) == 2`
passed the `<= 2` check. That's exactly the square-not-circle shape sitting 5 was supposed to
prevent, and the corners genuinely are farther away than the card's stated range allows.

Fix: split the single floored-distance helper into two. `_true_distance()` (unrounded) is now
what the range membership check uses — a tile only counts as reachable if its real, un-floored
distance is `<= range`, full stop. `_floored_distance()` still exists but is now used only for
the noise-cost charge (so a diagonal move's cost stays a clean multiple of `BASE_MOVE_NOISE`
instead of a fractional value) — flooring never again loosens what counts as "in range."

**Verified headlessly** against the exact reported bug: a range-2 card's valid-tile count dropped
from the buggy 24 to a correct 12; the reported corner (true distance 2.83) and its immediate
neighbor (2.24) are both now excluded; a legitimate diagonal 1-step (1.41) and an orthogonal
2-step exactly at the cap (2.0) both remain included; and every tile in the resulting set was
swept to confirm none exceeds true distance 2.

**Next:** hand back for another play pass.

### S1.1 (sitting 5) — diagonal movement, floored-distance range (circular, not square)

Direct request, still S1.1: movement range should include diagonals, using a normalized
(Euclidean) distance rounded down, so the reachable area is circular/diamond-shaped rather than a
square that lets diagonal movement out-cover orthogonal movement for the same range.

- New `_floored_distance(a, b)` helper: `floori(sqrt(dx² + dy²))` between two tile coordinates —
  true distance, not a step count. A diagonal step is `sqrt(2) ≈ 1.41` away, not 1.
- `_get_valid_move_tiles()` rewritten from "walk the 4 orthogonal rays" to "scan the full
  `(2*range+1)²` bounding box, keep any tile with floored distance `<= range`" — this naturally
  produces the circular shape (a range-3 card's valid set excludes its own bounding box's corners,
  e.g. `(3,3)` is true distance 4.24, floors to 4, correctly excluded even though it's only 3
  steps away on each axis).
- Heat cost for a move now uses the same floored distance instead of the old Manhattan-distance
  sum, so a 1-tile diagonal hop costs the same as a 1-tile orthogonal hop (both floor to distance
  1), not double.
- Attack/Loot/Food/Water, the action economy, and enemy AI are all unaffected.

**Verified headlessly:** confirmed via `floori()` (verified to exist in Godot 4.6 first) that a
diagonal 1-step and a diagonal 2-step (true distance 2.83, floors to 2) are both reachable with a
range-2 card, an orthogonal 3-step is correctly excluded, every tile in a card's valid set
satisfies `floored_distance <= range` (the actual "not a square" invariant), and a diagonal move
charges heat for distance 1, not 2.

**Next:** hand back for another play pass.

### S1.1 (sitting 4) — movement is a range, player picks the tile

The direction-baked-into-the-card design from sitting 3 didn't land in play: "movement being that
tied to card draw feels crappy." Root problem — locking a movement card to one fixed direction
means a run of bad draws can leave you unable to go the way you actually need to, which is a much
worse failure mode than not having quite enough range. Fixed by decoupling direction from the
card entirely:

- `CardResource.move_direction`/`move_distance` replaced with a single `move_range: int`. The
  card only decides how far (and how much noise that costs); the player picks which of the 4
  cardinal directions, and exactly how far up to that cap, by clicking a tile after playing it.
- Move-card pool shrank from 12 (4 directions x 3 distances) to 3 (`Move x1/x2/x3`, one per
  range) — direction is free again, so the combinatorial spread was no longer buying anything.
- Reintroduced the select-card-then-click-a-tile flow (removed in sitting 3) specifically for
  movement: `_get_valid_move_tiles()` walks all 4 orthogonal rays out to the card's range,
  stopping at the grid edge, and highlights every tile along the way — not just the endpoint — so
  a range-3 card can still be played for a cheaper 1-tile hop when that's the better call. Heat is
  charged for the distance actually picked, not the card's max range.
- Attack/Loot/Food/Water are unaffected — they still resolve instantly in place.

**Verified headlessly:** card pool is 7 (4 fixed + 3 range cards), a range-3 card's valid-tile set
is exactly the 12 tiles across its 4 rays (confirmed a 3-tiles-away tile is included and a
4-tiles-away tile is not), picking a nearer tile than the card's max range moves there and charges
heat only for that distance (0.5 for 1 tile, not 1.5 for the card's full range-3 cost), and
clicking a tile outside the valid set is rejected without moving the player or consuming the card.

**Next:** hand back for another play pass.

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
