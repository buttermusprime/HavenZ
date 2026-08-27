extends Node2D

## Phase 1 gray-box (session 1.1): proves the noise/heat + card-hand tension hook with nothing
## but ColorRects and debug labels before any art or full systems exist. Routed through the real
## CardResource/TileResource/EnemyResource classes from session 0.2 so this survives Phase 2's
## reskin rather than being thrown away and rewritten.

const GRID_WIDTH := 10
const GRID_HEIGHT := 8
const TILE_SIZE := 24
const HEAT_DECAY_RATE := 1.0
const HEAT_DISPLAY_MAX := 10.0
## Heat value at which a nearby zombie's pull chance is ~certain. Rough gray-box tuning value,
## not from the Noise System Design doc (which only specifies starting per-card noise_cost).
const ENEMY_PULL_HEAT_SCALE := 8.0

## Debug-only stand-in for the Portable Radio System's card-play heat burst (real system:
## sessions 10.5/10.6). Index 0 = Off (baseline, no burst); 1-5 stand in for its 5 volume tiers.
## Values are a first guess for feel-checking the volume-vs-heat tradeoff now, per that system's
## own design doc, not a committed curve — retune freely during S1.2 playtesting.
const RADIO_MULTIPLIERS: Array[float] = [1.0, 1.2, 1.5, 2.0, 2.5, 3.0]

const MOVE_CATEGORIES := [CardResource.Category.MOVE_STEALTH, CardResource.Category.MOVE_LOUD]

const CARD_POOL_PATHS: Array[String] = [
	"res://data/gray_box_cards/stealth_move.tres",
	"res://data/gray_box_cards/loud_move.tres",
	"res://data/gray_box_cards/attack.tres",
	"res://data/gray_box_cards/loot.tres",
	"res://data/gray_box_cards/supply.tres",
]

const ENEMY_RESOURCE_PATH := "res://data/samples/enemy_walker_basic.tres"

@onready var grid_visual: Node2D = $GridVisual
@onready var player_visual: ColorRect = $PlayerVisual
@onready var enemy_visual: ColorRect = $EnemyVisual
@onready var turn_label: Label = $HUD/Root/TurnLabel
@onready var radio_label: Label = $HUD/Root/RadioLabel
@onready var status_label: Label = $HUD/Root/StatusLabel
@onready var hand_container: HBoxContainer = $HUD/Root/HandContainer

var tiles: Dictionary = {}  # Vector2i -> TileResource
var tile_views: Dictionary = {}  # Vector2i -> {rect: ColorRect, label: Label}
var card_pool: Array[CardResource] = []
var hand: Array[CardResource] = []
var enemy_resource: EnemyResource

var player_pos: Vector2i
var enemy_pos: Vector2i
var selected_card_index: int = -1
var turn_number: int = 1
var radio_tier_index: int = 0

func _ready() -> void:
	randomize()
	_load_card_pool()
	enemy_resource = load(ENEMY_RESOURCE_PATH)
	player_pos = Vector2i(5, 4)
	enemy_pos = Vector2i(0, 0)
	_build_grid()
	_render_visual_positions()
	for i in range(card_pool.size()):
		hand.append(card_pool[i])
	_render_hand()
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
	for path in CARD_POOL_PATHS:
		card_pool.append(load(path))

func _build_grid() -> void:
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var coord := Vector2i(x, y)
			tiles[coord] = TileResource.new()

			var rect := ColorRect.new()
			rect.size = Vector2(TILE_SIZE - 2, TILE_SIZE - 2)
			rect.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			rect.color = Color(0.15, 0.15, 0.18)
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

func _on_tile_gui_input(event: InputEvent, coord: Vector2i) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_play_selected_card_on_tile(coord)

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
		selected_card_index = i
		status_label.text = "%s selected — click an adjacent tile to move there." % card.display_name
		return
	_apply_card_heat(card, player_pos)
	_consume_played_card(i)
	_end_turn()

func _try_play_selected_card_on_tile(coord: Vector2i) -> void:
	if selected_card_index == -1:
		status_label.text = "Select a move card first, then click an adjacent tile."
		return
	var dist := absi(coord.x - player_pos.x) + absi(coord.y - player_pos.y)
	if dist != 1:
		status_label.text = "Pick a tile orthogonally adjacent to the player."
		return
	var card := hand[selected_card_index]
	player_pos = coord
	_apply_card_heat(card, player_pos)
	_consume_played_card(selected_card_index)
	selected_card_index = -1
	_end_turn()

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
	_render_hand()

func _end_turn() -> void:
	_enemy_turn()
	_decay_tiles()
	turn_number += 1
	_update_hud()
	_redraw_tiles()
	_render_visual_positions()

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
		var t := clampf(tile.heat / HEAT_DISPLAY_MAX, 0.0, 1.0)
		view.rect.color = Color(0.15 + 0.7 * t, 0.15, 0.18)
		view.label.text = "%.1f" % tile.heat

func _render_visual_positions() -> void:
	var origin := grid_visual.position
	player_visual.size = Vector2(TILE_SIZE - 4, TILE_SIZE - 4)
	enemy_visual.size = Vector2(TILE_SIZE - 4, TILE_SIZE - 4)
	player_visual.position = origin + Vector2(player_pos) * TILE_SIZE + Vector2(2, 2)
	enemy_visual.position = origin + Vector2(enemy_pos) * TILE_SIZE + Vector2(2, 2)

func _update_hud() -> void:
	turn_label.text = "Turn %d" % turn_number
	var tier_name := "Off" if radio_tier_index == 0 else "Tier %d" % radio_tier_index
	radio_label.text = "Radio: %s (x%.1f)  [press 0-5]" % [tier_name, RADIO_MULTIPLIERS[radio_tier_index]]
