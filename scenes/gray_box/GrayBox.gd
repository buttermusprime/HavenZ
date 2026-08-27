extends Node2D

## Phase 1 gray-box (session 1.1, iterated per session 1.2 playtest feedback): proves the
## noise/heat + card-hand tension hook with nothing but ColorRects and debug labels before any
## art or full systems exist. Routed through the real CardResource/TileResource/EnemyResource
## classes from session 0.2 so this survives Phase 2's reskin rather than being thrown away.
##
## Every card resolves the instant it's clicked -- there is no separate "select, then click a
## tile to target" step. A movement card bakes in its own direction+distance (see CardResource's
## move_direction/move_distance), so choosing WHICH card to play is the tactical decision, not
## where to click afterward. Stealth vs. loud is no longer a per-movement-card distinction either:
## the debug radio dial already controls how loud the player is being, for every card, not just
## movement, so a separate "Stealth Move" card would just duplicate that.
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
const TILE_SIZE := 24
const HEAT_DECAY_RATE := 1.0
const HEAT_DISPLAY_MAX := 10.0
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

const MOVE_DIRECTIONS: Dictionary = {
	"North": Vector2i(0, -1),
	"South": Vector2i(0, 1),
	"East": Vector2i(1, 0),
	"West": Vector2i(-1, 0),
}
const MOVE_DISTANCES: Array[int] = [1, 2, 3]
## Heat per tile of movement, before the radio-dial multiplier -- moving further is louder.
const BASE_MOVE_NOISE := 0.5

const FIXED_CARD_POOL_PATHS: Array[String] = [
	"res://data/gray_box_cards/attack.tres",
	"res://data/gray_box_cards/loot.tres",
	"res://data/gray_box_cards/supply_food.tres",
	"res://data/gray_box_cards/supply_water.tres",
]

const ENEMY_RESOURCE_PATH := "res://data/samples/enemy_walker_basic.tres"

const LOOT_COLOR := Color(0.12, 0.26, 0.14)
const NORMAL_COLOR := Color(0.15, 0.15, 0.18)

@onready var grid_visual: Node2D = $GridVisual
@onready var player_visual: ColorRect = $PlayerVisual
@onready var enemy_visual: ColorRect = $EnemyVisual
@onready var turn_label: Label = $HUD/Root/TurnLabel
@onready var stats_label: Label = $HUD/Root/StatsLabel
@onready var status_label: Label = $HUD/Root/StatusLabel
@onready var hand_container: HBoxContainer = $HUD/Root/HandScroll/HandContainer

var tiles: Dictionary = {}  # Vector2i -> TileResource
var tile_views: Dictionary = {}  # Vector2i -> {rect: ColorRect, label: Label}
var loot_tiles: Dictionary = {}  # Vector2i -> true
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

func _ready() -> void:
	randomize()
	_load_card_pool()
	enemy_resource = load(ENEMY_RESOURCE_PATH)
	enemy_current_hp = enemy_resource.max_hp
	player_pos = Vector2i(5, 4)
	enemy_pos = Vector2i(0, 0)
	enemy_spawn_pos = enemy_pos
	_build_grid()
	_place_loot_tiles()
	_render_visual_positions()
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
	for dir_name in MOVE_DIRECTIONS:
		var dir_vec: Vector2i = MOVE_DIRECTIONS[dir_name]
		for distance in MOVE_DISTANCES:
			var card := CardResource.new()
			card.id = "gb_move_%s_%d" % [String(dir_name).to_lower(), distance]
			card.display_name = "%s x%d" % [dir_name, distance]
			card.category = CardResource.Category.MOVE_LOUD
			card.move_direction = dir_vec
			card.move_distance = distance
			card.noise_cost = distance * BASE_MOVE_NOISE
			card_pool.append(card)

func _build_grid() -> void:
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var coord := Vector2i(x, y)
			tiles[coord] = TileResource.new()

			var rect := ColorRect.new()
			rect.size = Vector2(TILE_SIZE - 2, TILE_SIZE - 2)
			rect.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			rect.color = NORMAL_COLOR
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # purely visual now -- see header comment.
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

			tile_views[coord] = {"rect": rect, "label": label}

func _place_loot_tiles() -> void:
	var needed := LOOT_TILE_COUNT - loot_tiles.size()
	if needed <= 0:
		return
	var candidates: Array[Vector2i] = []
	for coord in tiles.keys():
		if coord != player_pos and coord != enemy_pos and not loot_tiles.has(coord):
			candidates.append(coord)
	candidates.shuffle()
	for i in range(mini(needed, candidates.size())):
		loot_tiles[candidates[i]] = true

func _render_hand() -> void:
	for child in hand_container.get_children():
		child.queue_free()
	for i in range(hand.size()):
		var card := hand[i]
		var button := Button.new()
		button.text = "%s (%.1f)" % [card.display_name, card.noise_cost]
		button.pressed.connect(_on_card_pressed.bind(i))
		hand_container.add_child(button)

func _on_card_pressed(i: int) -> void:
	var card := hand[i]
	if card.category in MOVE_CATEGORIES:
		_resolve_move(card)
	else:
		_resolve_card_in_place(card)
	_consume_played_card(i)
	_spend_action()

func _resolve_move(card: CardResource) -> void:
	var raw_target := player_pos + card.move_direction * card.move_distance
	var clamped := Vector2i(
		clampi(raw_target.x, 0, GRID_WIDTH - 1),
		clampi(raw_target.y, 0, GRID_HEIGHT - 1),
	)
	player_pos = clamped
	_apply_card_heat(card, player_pos)
	if clamped != raw_target:
		status_label.text += " Blocked by the grid edge — moved as far as possible."

## Resolves a non-move card's effect at the player's current tile: Attack hits an adjacent
## zombie (no facing/direction needed since it just targets whichever of the 4 neighbors the
## zombie occupies), Loot claims a loot tile if the player is standing on one, everything else
## (Food/Water) is a heat-only placeholder until Phase 6's real economy exists.
func _resolve_card_in_place(card: CardResource) -> void:
	_apply_card_heat(card, player_pos)
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

func _apply_card_heat(card: CardResource, coord: Vector2i) -> void:
	var tile: TileResource = tiles[coord]
	var multiplier := RADIO_MULTIPLIERS[radio_tier_index]
	var heat_delta := card.noise_cost * multiplier
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
	_decay_tiles()
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

func _step_toward(from: Vector2i, to: Vector2i) -> Vector2i:
	var delta := to - from
	var step := from
	if absi(delta.x) >= absi(delta.y) and delta.x != 0:
		step.x += signi(delta.x)
	elif delta.y != 0:
		step.y += signi(delta.y)
	return step

func _decay_tiles() -> void:
	for coord in tiles.keys():
		var tile: TileResource = tiles[coord]
		if tile.this_turn_origins.is_empty():
			tile.heat = maxf(0.0, tile.heat - HEAT_DECAY_RATE)
		tile.clear_turn_origins()

func _redraw_tiles() -> void:
	for coord in tile_views.keys():
		var tile: TileResource = tiles[coord]
		var view: Dictionary = tile_views[coord]
		var base := LOOT_COLOR if loot_tiles.has(coord) else NORMAL_COLOR
		var t := clampf(tile.heat / HEAT_DISPLAY_MAX, 0.0, 1.0)
		view.rect.color = Color(base.r + 0.7 * t, base.g, base.b)
		view.label.text = "%.1f" % tile.heat

func _render_visual_positions() -> void:
	var origin := grid_visual.position
	player_visual.size = Vector2(TILE_SIZE - 4, TILE_SIZE - 4)
	enemy_visual.size = Vector2(TILE_SIZE - 4, TILE_SIZE - 4)
	player_visual.position = origin + Vector2(player_pos) * TILE_SIZE + Vector2(2, 2)
	enemy_visual.position = origin + Vector2(enemy_pos) * TILE_SIZE + Vector2(2, 2)

func _update_hud() -> void:
	var tier_name := "Off" if radio_tier_index == 0 else "Tier %d" % radio_tier_index
	turn_label.text = "Turn %d  |  Radio: %s (x%.1f) [0-5]  |  Actions: %d/%d" % [
		turn_number, tier_name, RADIO_MULTIPLIERS[radio_tier_index], actions_remaining, ACTIONS_PER_TURN,
	]
	stats_label.text = "Salvage: %d  |  Zombie HP: %d/%d" % [
		salvage_count, enemy_current_hp, enemy_resource.max_hp,
	]
