extends Node2D

## Emitted the instant the player's move lands exactly on a Haven's entrance tile. Phase 10 owns
## the real Trade/Craft menu -- this session only proves the entrance actually detects the player
## and identifies which Haven, per its own explicit "stub the menu, don't build it" scope.
signal haven_entered(haven: HavenResource)

## Phase 1 gray-box (session 1.1, multiple build sittings): proves the noise/heat + card-hand
## tension hook with nothing but ColorRects and debug labels before any art or full systems
## exist. Routed through the real CardResource/TileResource/EnemyResource classes from session
## 0.2 so this survives Phase 2's reskin rather than being thrown away.
##
## Reskinned in session 2.5 with S2.2/S2.3's real master palette and converted art: real tile
## art under the existing per-tile heat/highlight overlay (now semi-transparent, same logic as
## before), a real AnimatedSprite2D for the player. The enemy square stays a ColorRect --
## nothing in this session's own scope asked for reskinning it, and the roster/zombie-art
## mapping is later phase work. Same-session addition: heat decay is now real ring-based
## bleed/propagation (Noise System Design's starting parameters), not a flat per-tile value.
##
## Attack/Loot/Food/Water resolve instantly on click. A movement card is different: it sets a
## RANGE (and its noise cost), and the player then clicks any reachable tile -- including
## diagonals -- to actually move there. An earlier version baked a fixed direction into the card
## itself, which felt bad in play -- a run of unlucky draws could leave you with no way to go the
## direction you actually needed. Range-then-pick keeps "which movement card to play" a real
## tradeoff (further costs more noise) without ever locking out a direction.
##
## Reachability uses true (Euclidean) distance, unrounded, not a step count -- a diagonal step is
## sqrt(2) away, not 1, so diagonal movement can't out-cover orthogonal movement for the same
## range value; a range-2 card cannot reach a tile that's actually 2.83 away just because it's
## only 2 steps out on each axis. This produces a circular reachable area rather than a square
## (which is what naively counting steps in any of 8 directions -- Chebyshev distance -- would
## give). Only the noise-cost CHARGE for a move rounds distance down, not the range check itself.
##
## Deliberately NOT built here (real design/systems work for later sessions, not gray-box scope):
## - Variable turn length ("ends when no legal play" + Supply-card turn extension) - session 4.4.
##   This gray-box uses a simpler fixed ACTIONS_PER_TURN instead, just to make turn boundaries
##   legible for playtesting; the real rule replaces this constant later, not extends it.
## - A real loot/economy system (Supply Request tracking, etc.) - Phase 6. The loot tiles here are
##   a bare "something is worth walking to" signal, not the real system.
## - Directional facing / ranged combat - not asked for anywhere in the roadmap; Attack instead
##   auto-targets an adjacent zombie, which is enough to test the hook without a facing mechanic.

const GRID_WIDTH := 10
const GRID_HEIGHT := 8
## Real logical tile size (the actual 16px unit locked in S0.1's viewport math), not the
## arbitrary 24px placeholder S1.1's gray-box used before real art existed.
const TILE_SIZE := 16
const HEAT_DECAY_RATE := 1.0
const HEAT_DISPLAY_MAX := 10.0

## Real floor tile art (S2.2's master palette, S2.3's real conversion) — one plain-grass cell
## from the Green biome sheet, picked by eye as a flat, undecorated tile with no path/edge
## marking baked in. Real per-biome tile variety is Phase 3.2 scope, not this session's.
const TILE_TEXTURE_PATH := "res://art/Tiles/Background_Green_TileSet.png"
const TILE_ATLAS_COORD := Vector2i(0, 0)

## Adjacency bleed fractions per the Noise System Design section's starting parameters: 40% of
## a source tile's OWN current heat radiates to every tile 1 ring out, ~15% at 2 rings out.
## "Ring" here is Chebyshev distance (max(|dx|,|dy|)) — the standard tile-grid meaning of "N
## tiles out" (all 8 immediately-surrounding tiles, diagonals included, are ring 1) — distinct
## from the true/Euclidean distance the movement system uses for its circular range check,
## which answers a different question (how far can I walk) than this one (how many grid steps
## away is this neighbor).
const HEAT_BLEED_RING_1_FRACTION := 0.40
const HEAT_BLEED_RING_2_FRACTION := 0.15
const HEAT_BLEED_MAX_RING := 2
## Heat value at which a nearby zombie's pull chance is ~certain. Rough gray-box tuning value,
## not from the Noise System Design doc (which only specifies starting per-card noise_cost).
const ENEMY_PULL_HEAT_SCALE := 8.0

const ATTACK_DAMAGE := 1
const LOOT_TILE_COUNT := 3
const HAND_SIZE := 6

## Fixed actions-per-turn for gray-box legibility only -- see the header comment above.
const ACTIONS_PER_TURN := 2

## Debug-only stand-in for the Portable Radio System's card-play heat burst (real system:
## sessions 10.5/10.6), doubling here as the player's general stealth dial per playtest feedback.
## Index 0 = Off (quietest, baseline 1.0x); 1-5 stand in for its 5 volume tiers, each louder.
const RADIO_MULTIPLIERS: Array[float] = [1.0, 1.2, 1.5, 2.0, 2.5, 3.0]

## MOVE_STEALTH is defined on CardResource but unused here -- see the header comment.
const MOVE_CATEGORIES := [CardResource.Category.MOVE_LOUD]

const MOVE_RANGES: Array[int] = [1, 2, 3]
## Heat per tile actually moved, before the radio-dial multiplier -- moving further is louder.
## Charged for the distance the player actually picks, not a card's max range.
const BASE_MOVE_NOISE := 0.5

## Session 3.1 -- GDD §8.1's Home Haven + one other Haven: fixed rectangles, hand-placed. No
## level-design tooling exists yet, so this is hardcoded the same way the terrain grid itself
## still is; a real map-authoring system is later scope. Sizes/positions chosen to sit clear of
## the fixed player start (5,4), the fixed enemy spawn (0,0), and each other on this 10x8 grid.
const HOME_HAVEN_ORIGIN := Vector2i(6, 0)
const HOME_HAVEN_SIZE := Vector2i(4, 3)
## Local offset within the rectangle (not a world coord) -- bottom wall, facing the open map
## toward the player's start rather than a corner, so it reads as an obvious front door.
const HOME_HAVEN_ENTRANCE_OFFSET := Vector2i(1, 2)

const OTHER_HAVEN_ORIGIN := Vector2i(0, 5)
const OTHER_HAVEN_SIZE := Vector2i(4, 3)
const OTHER_HAVEN_ENTRANCE_OFFSET := Vector2i(2, 0)  # top wall, facing north into the open map

## Real Buildable wall art (S2.3's conversion), Wooden variant -- GDD §8.1 draws no distinction
## between wall materials at MVP, so this is a default pick, not a design decision. Each path
## points at S2.4's headlessly-generated per-asset scene (Node2D + AnimatedSprite2D,
## centered=false), the same convention S2.5 used for the player sprite, since these are
## irregularly-cropped standalone sprites, not a shared grid-aligned tileset atlas like the
## floor art in _build_terrain(). Corner-piece assignment (which of the 4 connector filenames is
## the top-left vs top-right vs bottom-left vs bottom-right corner) is inferred from each
## filename's own "Left-side/Right-side" + "connects Right/Left & Down/Up" wording -- the asset
## pack documents nothing more specific than that, so this is worth a visual spot-check once it
## actually renders, same as every other pack-art assumption made so far in this project.
const WALL_DIR := "res://art/Objects/Buildable/Wooden/"
const WALL_SCENE_HORIZONTAL := WALL_DIR + "Wooden-wall_Horizontal.tscn"
const WALL_SCENE_VERTICAL := WALL_DIR + "Wooden-wall_Vertical.tscn"
const WALL_SCENE_TOP_LEFT := WALL_DIR + "Wooden-wall_Left-side_Right&Down-connect.tscn"
const WALL_SCENE_TOP_RIGHT := WALL_DIR + "Wooden-wall_Right-side_Left&Down-connect.tscn"
const WALL_SCENE_BOTTOM_LEFT := WALL_DIR + "Wooden-wall_Left-side_Right&Up-connect.tscn"
const WALL_SCENE_BOTTOM_RIGHT := WALL_DIR + "Wooden-wall_Right-side_Left&Up-connect.tscn"

## Reserves the Green tint EXCLUSIVELY for the Home Haven's entrance, per this session's own
## explicit ask, so it reads as distinct from every other Haven at a glance -- Bleak-Yellow for
## the one other Haven placed here, deliberately different from Green rather than another
## greenish tint, for the same reason. Also happens to reuse the same Green/Bleak-Yellow zone
## naming Phase 3.2's biome-dressing session will use, though that's a naming coincidence this
## session doesn't act on (no biome-zone system exists yet).
const HOME_HAVEN_ENTRANCE_SCENE := "res://art/Objects/Buildings/Enterance_Green.tscn"
const OTHER_HAVEN_ENTRANCE_SCENE := "res://art/Objects/Buildings/Enterance_Bleak-Yellow.tscn"

## Session 3.2 -- non-functional world set-dressing from Nature/Buildings/Vehicles, purely
## visual per the session's own explicit scope (no TileResource flags touched, nothing here
## blocks movement/noise). Uses a diagonal split (Home Haven top-right, the other Haven
## bottom-left) rather than real per-tile distance math -- x-y's sign alone already reads as
## "which corner a tile is nearer," and this session's own prompt notes the split can later
## double as a cheap way to signal Supply Request difficulty tiers by region (Phase 6), so it's
## kept as a real, reusable function rather than only implicit in a hardcoded coordinate list.
## The roadmap's own text names "beige vs. gray vs. dark buildings" as the Buildings-side
## variant, but the actual pack has no such 3-way building-shell tint -- substituted the real
## per-zone-tinted asset that does exist (HVAC_Overgrown_Green/Bleak-Yellow/Dark-Green), the
## same "correct provisional text against the real asset shape" pattern S2.1 already used.
enum Zone { GREEN, BLEAK_YELLOW }

func _zone_for_coord(coord: Vector2i) -> Zone:
	return Zone.GREEN if (coord.x - coord.y) >= 0 else Zone.BLEAK_YELLOW

## Hand-picked, fixed coordinates -- same "no level-design tooling yet" reasoning as the Haven
## rectangles, not randomized, so this stays exactly reproducible for verification/spot-checks.
## Every coordinate here is confirmed clear of both Haven footprints, the player start (5,4),
## and the enemy spawn (0,0), and each entry's own zone-appropriate art was picked to match what
## _zone_for_coord() would say about that coordinate (double-checked headlessly, not just by
## hand -- see the session's own verification script).
const WORLD_DRESSING: Array[Dictionary] = [
	{"coord": Vector2i(5, 0), "scene": "res://art/Objects/Nature/Green/Tree_2_Spruce-Sparse_Green.tscn"},
	{"coord": Vector2i(5, 1), "scene": "res://art/Objects/Buildings/HVAC_Overgrown_Green.tscn"},
	{"coord": Vector2i(4, 3), "scene": "res://art/Objects/Nature/Green/Bush_1_Green.tscn"},
	{"coord": Vector2i(9, 4), "scene": "res://art/Objects/Nature/Green/Grass_3_Green.tscn"},
	{"coord": Vector2i(8, 4), "scene": "res://art/Objects/Vehicles/Normal/Car_9_Motorcycle/Car_9_Blue_Motorcycle_Side.tscn"},
	{"coord": Vector2i(0, 1), "scene": "res://art/Objects/Nature/Bleak-Yellow/Tree_2_Spruce-Sparse_Bleak-Yellow.tscn"},
	{"coord": Vector2i(1, 3), "scene": "res://art/Objects/Buildings/HVAC_Overgrown_Bleak-Yellow.tscn"},
	{"coord": Vector2i(4, 6), "scene": "res://art/Objects/Nature/Bleak-Yellow/Bush_1_Bleak-Yellow.tscn"},
	{"coord": Vector2i(0, 4), "scene": "res://art/Objects/Nature/Bleak-Yellow/Grass_3_Bleak-Yellow.tscn"},
	{"coord": Vector2i(6, 7), "scene": "res://art/Objects/Vehicles/Normal/Car_6_Scrap/Car_6_Blue_Scrap.tscn"},
]

const FIXED_CARD_POOL_PATHS: Array[String] = [
	"res://data/gray_box_cards/attack.tres",
	"res://data/gray_box_cards/loot.tres",
	"res://data/gray_box_cards/supply_food.tres",
	"res://data/gray_box_cards/supply_water.tres",
]

const ENEMY_RESOURCE_PATH := "res://data/samples/enemy_walker_basic.tres"

## Semi-transparent so the real tile art built in _build_terrain() shows through underneath --
## this overlay's own color logic (heat tint / highlight / loot marker) is otherwise unchanged
## from the pre-reskin gray-box; only the alpha and the presence of real art beneath it are new.
const OVERLAY_ALPHA := 0.55
const LOOT_COLOR := Color(0.12, 0.26, 0.14, OVERLAY_ALPHA)
const NORMAL_COLOR := Color(0.15, 0.15, 0.18, OVERLAY_ALPHA)
const HIGHLIGHT_COLOR := Color(0.85, 0.75, 0.2, OVERLAY_ALPHA)

@onready var grid_visual: Node2D = $GridVisual
@onready var player_visual: Node2D = $PlayerVisual
@onready var player_sprite: AnimatedSprite2D = $PlayerVisual/AnimatedSprite2D
@onready var enemy_visual: ColorRect = $EnemyVisual
@onready var turn_label: Label = $HUD/Root/TurnLabel
@onready var stats_label: Label = $HUD/Root/StatsLabel
@onready var status_label: Label = $HUD/Root/StatusLabel
@onready var hand_container: HBoxContainer = $HUD/Root/HandScroll/HandContainer

var tiles: Dictionary = {}  # Vector2i -> TileResource
var tile_views: Dictionary = {}  # Vector2i -> {rect: ColorRect, label: Label}
var loot_tiles: Dictionary = {}  # Vector2i -> true
var haven_entrances: Dictionary = {}  # Vector2i -> HavenResource
var card_pool: Array[CardResource] = []
var hand: Array[CardResource] = []
var enemy_resource: EnemyResource

var player_pos: Vector2i
var enemy_pos: Vector2i
var enemy_spawn_pos: Vector2i
var enemy_current_hp: int
var salvage_count: int = 0
var turn_number: int = 1
var radio_tier_index: int = 0
var actions_remaining: int = ACTIONS_PER_TURN
var selected_card_index: int = -1

func _ready() -> void:
	randomize()
	haven_entered.connect(_on_haven_entered)
	_load_card_pool()
	enemy_resource = load(ENEMY_RESOURCE_PATH)
	enemy_current_hp = enemy_resource.max_hp
	player_pos = Vector2i(5, 4)
	enemy_pos = Vector2i(0, 0)
	enemy_spawn_pos = enemy_pos
	_build_terrain()
	_build_grid()
	_build_havens()
	_build_world_dressing()
	_place_loot_tiles()
	_render_visual_positions()
	# Purely visual (idling in place) -- build_scene() selects the sheet's only real tag/
	# animation but never calls play() itself, so nothing animates until something does.
	player_sprite.play()
	for i in range(HAND_SIZE):
		hand.append(card_pool[randi() % card_pool.size()])
	_render_hand()
	_redraw_tiles()
	_update_hud()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	var key_to_tier := {
		KEY_0: 0, KEY_1: 1, KEY_2: 2, KEY_3: 3, KEY_4: 4, KEY_5: 5,
	}
	if key_to_tier.has(event.keycode):
		radio_tier_index = key_to_tier[event.keycode]
		_update_hud()

func _load_card_pool() -> void:
	for path in FIXED_CARD_POOL_PATHS:
		card_pool.append(load(path))
	for r in MOVE_RANGES:
		var card := CardResource.new()
		card.id = "gb_move_range_%d" % r
		card.display_name = "Move x%d" % r
		card.category = CardResource.Category.MOVE_LOUD
		card.move_range = r
		card.noise_cost = r * BASE_MOVE_NOISE
		card_pool.append(card)

## Real tile art underneath the existing heat/highlight overlay (built by _build_grid() below) --
## a plain, uniform floor across the whole grid. Real per-tile terrain variety (walls, biome
## mixing) is Phase 3.1/3.2 scope; this session only proves the pipeline's real art renders
## correctly at the real 16px scale, without touching any movement/hand/heat logic.
func _build_terrain() -> void:
	var texture: Texture2D = load(TILE_TEXTURE_PATH)
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = texture
	atlas_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	atlas_source.create_tile(TILE_ATLAS_COORD)
	var source_id := tile_set.add_source(atlas_source)

	var tile_map := TileMapLayer.new()
	tile_map.tile_set = tile_set
	grid_visual.add_child(tile_map)
	grid_visual.move_child(tile_map, 0)  # behind every per-tile overlay ColorRect built next
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			tile_map.set_cell(Vector2i(x, y), source_id, TILE_ATLAS_COORD)

func _build_grid() -> void:
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var coord := Vector2i(x, y)
			tiles[coord] = TileResource.new()

			var rect := ColorRect.new()
			rect.size = Vector2(TILE_SIZE - 2, TILE_SIZE - 2)
			rect.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			rect.color = NORMAL_COLOR
			grid_visual.add_child(rect)

			var label := Label.new()
			label.position = Vector2.ZERO
			label.size = rect.size
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 8)
			label.text = "0"
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rect.add_child(label)

			# gui_input's bound coord comes from Callable.bind(), not a captured loop variable -
			# GDScript lambdas/closures capture by value at creation time, which would otherwise
			# make every tile's callback see the loop's *final* coord.
			rect.gui_input.connect(_on_tile_gui_input.bind(coord))
			tile_views[coord] = {"rect": rect, "label": label}

## Session 3.1 -- builds the Home Haven + one other Haven per GDD §8.1: a walled rectangle of
## tiles with a single entrance gap. Must run after _build_grid() (needs every TileResource to
## already exist) and before _place_loot_tiles() (loot must never land on an unwalkable wall
## tile) and _redraw_tiles().
func _build_havens() -> void:
	_build_one_haven(
		"home", "Home Haven", true,
		HOME_HAVEN_ORIGIN, HOME_HAVEN_SIZE, HOME_HAVEN_ENTRANCE_OFFSET, HOME_HAVEN_ENTRANCE_SCENE,
	)
	_build_one_haven(
		"other", "Unaffiliated Haven", false,
		OTHER_HAVEN_ORIGIN, OTHER_HAVEN_SIZE, OTHER_HAVEN_ENTRANCE_OFFSET, OTHER_HAVEN_ENTRANCE_SCENE,
	)

func _build_one_haven(
	id: String, display_name: String, is_home: bool,
	origin: Vector2i, size: Vector2i, entrance_offset: Vector2i, entrance_scene_path: String,
) -> void:
	var haven := HavenResource.new()
	haven.id = id
	haven.display_name = display_name
	haven.is_home = is_home
	var entrance_coord := origin + entrance_offset

	for x in range(size.x):
		for y in range(size.y):
			var local := Vector2i(x, y)
			var is_wall := x == 0 or x == size.x - 1 or y == 0 or y == size.y - 1
			if not is_wall:
				continue  # interior floor tile -- plain walkable ground, no special art yet (Phase 3.2 dressing)
			var coord := origin + local
			var tile: TileResource = tiles[coord]
			# The perimeter blocks noise all the way around, entrance included -- noise
			# physically leaking through the one gap in an otherwise sealed wall ring would be
			# an inconsistency this session has no reason to introduce, so only walkable/
			# blocks_zombie differ at the entrance tile, not blocks_noise.
			tile.blocks_noise = true
			if coord == entrance_coord:
				# The PLAYER's one way in; zombies still can't follow per GDD §8.1's own "safe
				# because walls physically stop zombies" framing -- blocks_zombie stays true
				# here too, only walkable flips for the player's benefit.
				tile.walkable = true
				tile.blocks_zombie = true
				_place_object_sprite(entrance_scene_path, coord)
				haven_entrances[coord] = haven
			else:
				tile.walkable = false
				tile.blocks_zombie = true
				_place_object_sprite(_wall_scene_for_position(local, size), coord)

## Which wall segment art fits a tile's LOCAL position within the haven rectangle (0,0 to
## size-1) -- see the WALL_SCENE_* constants' own comment for the corner-piece naming caveat.
func _wall_scene_for_position(local: Vector2i, size: Vector2i) -> String:
	var at_left := local.x == 0
	var at_right := local.x == size.x - 1
	var at_top := local.y == 0
	var at_bottom := local.y == size.y - 1
	if at_left and at_top:
		return WALL_SCENE_TOP_LEFT
	if at_right and at_top:
		return WALL_SCENE_TOP_RIGHT
	if at_left and at_bottom:
		return WALL_SCENE_BOTTOM_LEFT
	if at_right and at_bottom:
		return WALL_SCENE_BOTTOM_RIGHT
	if at_top or at_bottom:
		return WALL_SCENE_HORIZONTAL
	return WALL_SCENE_VERTICAL

## Top-left anchored at the tile's own world position, same convention _build_terrain()/
## _build_grid() use for every tile -- every S2.4-generated per-asset scene is centered=false
## for exactly this reason. Added to grid_visual after the per-tile overlay ColorRects, so wall/
## entrance art draws on top of the (semi-transparent) heat tint rather than being tinted itself.
func _place_object_sprite(scene_path: String, coord: Vector2i) -> void:
	var sprite: Node2D = load(scene_path).instantiate()
	sprite.position = Vector2(coord) * TILE_SIZE
	grid_visual.add_child(sprite)

## Session 3.2 -- scatters WORLD_DRESSING's fixed props on top of the grid. Purely visual: no
## TileResource field is touched, so none of these props affect movement, noise, or loot
## placement -- a decorative tree sitting on an otherwise-normal walkable tile still shows its
## real (possibly nonzero) heat label underneath it, unlike a Haven wall's permanently-blank
## label, since this tile's heat can genuinely change during play.
func _build_world_dressing() -> void:
	for entry in WORLD_DRESSING:
		_place_object_sprite(entry["scene"], entry["coord"])

func _place_loot_tiles() -> void:
	var needed := LOOT_TILE_COUNT - loot_tiles.size()
	if needed <= 0:
		return
	var candidates: Array[Vector2i] = []
	for coord in tiles.keys():
		var tile: TileResource = tiles[coord]
		if coord != player_pos and coord != enemy_pos and not loot_tiles.has(coord) and tile.walkable:
			candidates.append(coord)
	candidates.shuffle()
	for i in range(mini(needed, candidates.size())):
		loot_tiles[candidates[i]] = true

func _on_tile_gui_input(event: InputEvent, coord: Vector2i) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_move_to_tile(coord)

func _render_hand() -> void:
	for child in hand_container.get_children():
		child.queue_free()
	for i in range(hand.size()):
		var card := hand[i]
		var button := Button.new()
		button.text = "%s (%.1f)" % [card.display_name, card.noise_cost]
		button.toggle_mode = true
		button.button_pressed = (i == selected_card_index)
		button.pressed.connect(_on_card_pressed.bind(i))
		hand_container.add_child(button)

func _on_card_pressed(i: int) -> void:
	if i == selected_card_index:
		# Clicking the already-selected move card again cancels the selection.
		selected_card_index = -1
		_render_hand()
		_redraw_tiles()
		status_label.text = "Selection cancelled."
		return

	var card := hand[i]
	if card.category in MOVE_CATEGORIES:
		selected_card_index = i
		_render_hand()
		_redraw_tiles()
		status_label.text = "%s selected — click any highlighted tile up to %d away." % [card.display_name, card.move_range]
		return

	_resolve_card_in_place(card)
	_consume_played_card(i)
	_spend_action()

func _try_move_to_tile(coord: Vector2i) -> void:
	if selected_card_index == -1:
		status_label.text = "Select a movement card first, then click a highlighted tile."
		return
	var valid := _get_valid_move_tiles()
	if not (coord in valid):
		status_label.text = "That tile isn't reachable with the selected card."
		return
	var card := hand[selected_card_index]
	var distance := _floored_distance(player_pos, coord)
	player_pos = coord
	_apply_card_heat(card, player_pos, distance * BASE_MOVE_NOISE)
	_consume_played_card(selected_card_index)
	selected_card_index = -1
	if haven_entrances.has(coord):
		haven_entered.emit(haven_entrances[coord])
	_spend_action()

func _on_haven_entered(haven: HavenResource) -> void:
	# TODO(Phase 10): open the real Trade/Craft menu here. This session only proves the
	# entrance detects the player and identifies which Haven, per its own explicit scope.
	status_label.text += "  Entered %s." % haven.display_name

## True (Euclidean) distance between two tiles, unrounded. A diagonal step is sqrt(2) away, not
## 1 -- this is the real distance used to decide what's IN RANGE, so diagonal movement can never
## reach farther than the card's range actually allows (flooring this before comparing would let
## e.g. a true-distance-2.83 corner sneak in under a range-2 cap -- it must not).
func _true_distance(a: Vector2i, b: Vector2i) -> float:
	var delta := b - a
	return sqrt(float(delta.x * delta.x + delta.y * delta.y))

## Same distance, rounded down to a whole tile count -- used only for the noise-cost charge, so
## a diagonal move's cost stays a clean multiple of BASE_MOVE_NOISE instead of an odd fraction.
## Never used for the range check itself; see _true_distance.
func _floored_distance(a: Vector2i, b: Vector2i) -> int:
	return floori(_true_distance(a, b))

## Bresenham's line algorithm -- every tile from `from` to `to` inclusive, in grid order. Used
## only to stop a movement card's straight-line hop from crossing a wall it should have to walk
## around instead (session 3.1's Haven walls are the first tiles with walkable=false) -- this is
## NOT a general line-of-sight/vision system, and doesn't touch enemy pathing (_step_toward) or
## the heat-bleed system's own separate, still-open diagonal-corner simplification from S2.5.
func _tiles_along_line(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var x0 := from.x
	var y0 := from.y
	var x1 := to.x
	var y1 := to.y
	var dx := absi(x1 - x0)
	var sx := 1 if x0 < x1 else -1
	var dy := -absi(y1 - y0)
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		result.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return result

## All tiles (including diagonals, no obstacles yet) within the selected card's move_range, using
## unrounded true distance so the reachable area is circular, not a square -- a range-2 card
## cannot reach a tile that's actually 2.83 tiles away just because two of its axes each moved by
## only 2. Every tile within range is a valid stop, not just the far edge, so a long-range card
## can still be played for a short, quieter hop if that's the better play.
func _get_valid_move_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if selected_card_index == -1:
		return result
	var card := hand[selected_card_index]
	if not (card.category in MOVE_CATEGORIES):
		return result
	var r := card.move_range
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			if dx == 0 and dy == 0:
				continue
			var coord := player_pos + Vector2i(dx, dy)
			if not tiles.has(coord):
				continue
			if _true_distance(player_pos, coord) > float(r):
				continue
			var target: TileResource = tiles[coord]
			if not target.walkable:
				continue
			if _path_crosses_wall(player_pos, coord):
				continue
			result.append(coord)
	return result

## True if any tile strictly between `from` and `to` (exclusive of both ends -- `to` itself is
## already checked separately as the destination) blocks movement. Without this, a long-range
## move card could hop straight over a 1-tile-thick Haven wall onto a walkable tile beyond it,
## which would make the wall meaningless for anything but the shortest cards.
func _path_crosses_wall(from: Vector2i, to: Vector2i) -> bool:
	var path := _tiles_along_line(from, to)
	for i in range(1, path.size() - 1):
		var coord: Vector2i = path[i]
		if tiles.has(coord) and not tiles[coord].walkable:
			return true
	return false

## Resolves a non-move card's effect at the player's current tile: Attack hits an adjacent
## zombie (no facing/direction needed since it just targets whichever of the 4 neighbors the
## zombie occupies), Loot claims a loot tile if the player is standing on one, everything else
## (Food/Water) is a heat-only placeholder until Phase 6's real economy exists.
func _resolve_card_in_place(card: CardResource) -> void:
	_apply_card_heat(card, player_pos, card.noise_cost)
	match card.category:
		CardResource.Category.ATTACK:
			_resolve_attack()
		CardResource.Category.LOOT:
			_resolve_loot()

func _resolve_attack() -> void:
	var dist := absi(enemy_pos.x - player_pos.x) + absi(enemy_pos.y - player_pos.y)
	if dist != 1:
		status_label.text += " No zombie adjacent — attack missed."
		return
	enemy_current_hp -= ATTACK_DAMAGE
	if enemy_current_hp <= 0:
		status_label.text += " Zombie destroyed! A new one appears elsewhere."
		enemy_pos = enemy_spawn_pos
		enemy_current_hp = enemy_resource.max_hp
	else:
		status_label.text += " Hit the zombie (%d/%d HP left)." % [enemy_current_hp, enemy_resource.max_hp]

func _resolve_loot() -> void:
	if loot_tiles.has(player_pos):
		loot_tiles.erase(player_pos)
		salvage_count += 1
		status_label.text += " Looted this tile! (+1 salvage)"
		_place_loot_tiles()
	else:
		status_label.text += " Nothing to loot here."

## noise_cost_override lets a movement card charge for the distance actually picked (which may be
## less than its max range) rather than the card's own noise_cost field, which represents the cap.
func _apply_card_heat(card: CardResource, coord: Vector2i, noise_cost_override: float) -> void:
	var tile: TileResource = tiles[coord]
	var multiplier := RADIO_MULTIPLIERS[radio_tier_index]
	var heat_delta := noise_cost_override * multiplier
	tile.heat += heat_delta
	tile.add_heat_origin(TileResource.HeatOrigin.PLAYER)
	status_label.text = "Played %s (+%.1f heat, radio x%.1f) at (%d,%d)." % [
		card.display_name, heat_delta, multiplier, coord.x, coord.y,
	]

func _consume_played_card(i: int) -> void:
	hand[i] = card_pool[randi() % card_pool.size()]

func _spend_action() -> void:
	actions_remaining -= 1
	if actions_remaining <= 0:
		_end_turn()
		actions_remaining = ACTIONS_PER_TURN
	_render_hand()
	_update_hud()
	_redraw_tiles()
	_render_visual_positions()

func _end_turn() -> void:
	status_label.text += "  -- Turn %d ends, zombie moves --" % turn_number
	_enemy_turn()
	_propagate_and_decay_tiles()
	turn_number += 1

func _enemy_turn() -> void:
	var radius := enemy_resource.noise_aggro_radius
	var best_coord := Vector2i.ZERO
	var best_heat := 0.0
	var found_target := false
	for coord in tiles.keys():
		var tile: TileResource = tiles[coord]
		if tile.heat <= 0.0:
			continue
		var dist := Vector2(coord - enemy_pos).length()
		if dist <= radius and tile.heat > best_heat:
			best_heat = tile.heat
			best_coord = coord
			found_target = true
	if not found_target:
		return
	var pull_chance := clampf(best_heat / ENEMY_PULL_HEAT_SCALE, 0.0, 1.0)
	if randf() < pull_chance:
		enemy_pos = _step_toward(enemy_pos, best_coord)

## Session 3.1: the first thing that ever sets blocks_zombie=true (Haven walls) needs to
## actually be enforced somewhere, or the flag is inert data -- same class of gap this project
## has explicitly flagged before (PixelPipe's own ignore_globs went unconsumed for a full
## session). Tries the preferred axis first (unchanged single-axis behavior from before this
## session), falls back to the other axis if a wall blocks it, and simply doesn't move if both
## are blocked -- still not real pathfinding (a zombie fully boxed in on two sides won't route
## around a corner), which is correctly Phase 7.1's job, not this session's.
func _step_toward(from: Vector2i, to: Vector2i) -> Vector2i:
	var delta := to - from
	var candidates: Array[Vector2i] = []
	if absi(delta.x) >= absi(delta.y):
		if delta.x != 0:
			candidates.append(from + Vector2i(signi(delta.x), 0))
		if delta.y != 0:
			candidates.append(from + Vector2i(0, signi(delta.y)))
	else:
		if delta.y != 0:
			candidates.append(from + Vector2i(0, signi(delta.y)))
		if delta.x != 0:
			candidates.append(from + Vector2i(signi(delta.x), 0))
	for candidate in candidates:
		if tiles.has(candidate) and not tiles[candidate].blocks_zombie:
			return candidate
	return from

## Per-turn heat update: bleed, then decay. Two passes over the whole grid, not one -- every
## tile's bleed contribution must come from the SAME starting snapshot of heat values, so a
## tile's own bleed amount can't depend on whether it happened to be visited before or after a
## neighbor in dictionary iteration order (which isn't a real rule, just an implementation
## accident waiting to happen if bleed and decay were folded into a single pass).
func _propagate_and_decay_tiles() -> void:
	var bleed_deltas := _compute_heat_bleed()
	for coord in bleed_deltas.keys():
		var tile: TileResource = tiles[coord]
		tile.heat += bleed_deltas[coord]
	for coord in tiles.keys():
		var tile: TileResource = tiles[coord]
		if tile.this_turn_origins.is_empty():
			tile.heat = maxf(0.0, tile.heat - HEAT_DECAY_RATE)
		tile.clear_turn_origins()

## Computes how much heat every tile should GAIN this turn from its neighbors' current heat,
## without mutating anything yet (see _propagate_and_decay_tiles for why). Generic in shape --
## "a value that bleeds to neighbors at a decaying fraction... blocked by a wall flag" (the
## Modular Systems section's own description of this pattern, for reuse beyond heat once a
## second real use case exists) -- only the field read (tile.heat) and the two fraction
## constants above are heat-specific; everything else is plain grid-ring math.
## Bleeding does NOT deplete the source tile: heat is a telegraph signal, not a finite resource
## being physically moved, so a hot tile keeps radiating at full strength every turn it stays
## hot rather than running out.
## True if the target tile, or any wall tile strictly between source and target, blocks noise --
## see the call site's comment in _compute_heat_bleed for why this replaced a target-only check.
func _bleed_path_blocked(source_coord: Vector2i, target_coord: Vector2i) -> bool:
	for coord in _tiles_along_line(source_coord, target_coord):
		if coord == source_coord:
			continue
		if tiles.has(coord) and tiles[coord].blocks_noise:
			return true
	return false

func _compute_heat_bleed() -> Dictionary:
	var deltas: Dictionary = {}  # Vector2i -> float, additive
	for source_coord in tiles.keys():
		var source: TileResource = tiles[source_coord]
		if source.heat <= 0.0:
			continue
		for dx in range(-HEAT_BLEED_MAX_RING, HEAT_BLEED_MAX_RING + 1):
			for dy in range(-HEAT_BLEED_MAX_RING, HEAT_BLEED_MAX_RING + 1):
				if dx == 0 and dy == 0:
					continue
				var ring := maxi(absi(dx), absi(dy))
				if ring > HEAT_BLEED_MAX_RING:
					continue
				# source_coord comes from an untyped Dictionary's .keys(), so it's a Variant to
				# the static parser even though it's always really a Vector2i at runtime --
				# an explicit type here sidesteps ":=" inference needing to prove that itself.
				var target_coord: Vector2i = source_coord + Vector2i(dx, dy)
				if not tiles.has(target_coord):
					continue
				# Session 3.1 exercised this for real for the first time (Haven walls) and found
				# the original target-only check wasn't enough: a 1-tile-thick wall let heat
				# bleed straight through to the un-walled tile immediately behind it at ring 2,
				# since only the FINAL target's own flag was ever checked, not anything between
				# source and target. Fixed by walking the straight line between them (the same
				# Bresenham helper the movement system uses for its own wall-crossing check) and
				# blocking if the target OR any wall tile strictly in between has blocks_noise.
				# Still not a full diagonal-corner-aware line-of-sight system -- a wall exactly
				# one tile off the direct line could still be "seen past" -- but this closes the
				# specific straight-through-a-wall leak this session's own layout would otherwise
				# hit immediately.
				if _bleed_path_blocked(source_coord, target_coord):
					continue
				var fraction := HEAT_BLEED_RING_1_FRACTION if ring == 1 else HEAT_BLEED_RING_2_FRACTION
				deltas[target_coord] = deltas.get(target_coord, 0.0) + source.heat * fraction
	return deltas

func _redraw_tiles() -> void:
	var highlighted := _get_valid_move_tiles()
	for coord in tile_views.keys():
		var tile: TileResource = tiles[coord]
		var view: Dictionary = tile_views[coord]
		if coord in highlighted:
			view.rect.color = HIGHLIGHT_COLOR
		else:
			var base := LOOT_COLOR if loot_tiles.has(coord) else NORMAL_COLOR
			var t := clampf(tile.heat / HEAT_DISPLAY_MAX, 0.0, 1.0)
			view.rect.color = Color(base.r + 0.7 * t, base.g, base.b, base.a)
		# Wall tiles are blocks_noise=true, so bleed can never reach them (S2.5's own bleed loop
		# skips any target with blocks_noise) and nothing can ever stand on one to apply heat
		# directly either (walkable=false) -- the label would just be a permanent, uninformative
		# "0.0" sitting next to (and, for the half-width Vertical piece, visibly beside) the real
		# wall sprite drawn on top of this tile, so it's left blank instead of misleadingly precise.
		view.label.text = "" if not tile.walkable else "%.1f" % tile.heat

func _render_visual_positions() -> void:
	var origin := grid_visual.position
	enemy_visual.size = Vector2(TILE_SIZE - 4, TILE_SIZE - 4)
	# Top-left anchored, same convention _build_terrain()/_build_grid() use for every tile --
	# the real sprite (AnimatedSprite2D.centered = false, set by PixelPipe's build_scene()) draws
	# from its own local (0,0) same as a tile does, so no extra inset/centering math is needed.
	player_visual.position = origin + Vector2(player_pos) * TILE_SIZE
	enemy_visual.position = origin + Vector2(enemy_pos) * TILE_SIZE + Vector2(2, 2)

func _update_hud() -> void:
	var tier_name := "Off" if radio_tier_index == 0 else "Tier %d" % radio_tier_index
	turn_label.text = "Turn %d  |  Radio: %s (x%.1f) [0-5]  |  Actions: %d/%d" % [
		turn_number, tier_name, RADIO_MULTIPLIERS[radio_tier_index], actions_remaining, ACTIONS_PER_TURN,
	]
	stats_label.text = "Salvage: %d  |  Zombie HP: %d/%d" % [
		salvage_count, enemy_current_hp, enemy_resource.max_hp,
	]
