extends CanvasLayer

## Session 4.2 -- gamepad virtual cursor, the input foundation the roadmap's Input Scheme
## decision calls for (mouse = PC baseline, one analog stick drives a virtual cursor on
## gamepad). Pure input plumbing per this session's own scope: no game-specific UI is built
## here, and every click/hover this pushes goes through a REAL InputEventMouseButton/
## InputEventMouseMotion via Viewport.push_input() -- confirmed in this project's own Sheepshead
## history (see the shared PENDING_LESSONS.md) that push_input() genuinely drives Godot's real
## GUI hit-testing/hover pipeline, not a bespoke click/back signal a later Control would need
## special-case wiring to understand. Deliberately no class_name (this is an autoload; a
## class_name matching an autoload's own registered name makes Godot refuse to load the script
## entirely -- hit exactly this bug once already on AudioSettings, session 0.3).
##
## Must survive pause: session 0.4's own CLAUDE.md convention names this system by name as a
## PROCESS_MODE_ALWAYS example ("input has to keep working in order to un-pause at all") -- set
## in _ready(), not left at the PAUSABLE-by-inheritance default.
##
## The on-screen reticle is a procedurally generated placeholder dot (no cursor art exists
## anywhere in the asset pack), not designed UI -- swap it for real art whenever one shows up,
## nothing else here depends on its shape.

const CONFIG_PATH := "user://settings.cfg"
const CONFIG_SECTION := "gamepad_cursor"
const JOYPAD_DEVICE := 0
const RETICLE_RADIUS := 3.5
const RETICLE_TEXTURE_SIZE := 9

## Pixels/second of cursor movement at full stick deflection. Exported now, surfaced as a real
## Settings slider in session 12.1 -- same "build the plumbing before the screen" pattern
## AudioSettings (session 0.3) already established for volume.
@export var sensitivity: float = 220.0
## Raw stick magnitude below this is ignored entirely, so drift/noise near center never nudges
## the cursor.
@export_range(0.0, 0.9) var deadzone: float = 0.2
@export var invert_x: bool = false
@export var invert_y: bool = false

var cursor_position: Vector2 = Vector2.ZERO
@onready var visual: Sprite2D = $Visual

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visual.texture = _make_reticle_texture()
	load_settings()
	cursor_position = get_viewport().get_visible_rect().size / 2.0
	_update_visual()

func _process(delta: float) -> void:
	visual.visible = Input.get_connected_joypads().size() > 0
	if not visual.visible:
		return
	var raw := Vector2(
		Input.get_joy_axis(JOYPAD_DEVICE, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(JOYPAD_DEVICE, JOY_AXIS_LEFT_Y),
	)
	var motion := _compute_motion(raw, deadzone, sensitivity, invert_x, invert_y, delta)
	if motion == Vector2.ZERO:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	cursor_position = (cursor_position + motion).clamp(Vector2.ZERO, viewport_size)
	_update_visual()
	_push_motion_event(motion)

## Pure math, deliberately factored out of _process() so it's testable without a real/simulated
## joypad device -- everything else in this script is I/O glue around this one function.
## Rescales past the deadzone edge (rather than a naive "clamp below deadzone to 0, otherwise
## pass the raw value through") so the response starts at 0 right at the boundary instead of
## jumping discontinuously the instant the stick crosses it.
static func _compute_motion(
	raw: Vector2, dead_zone: float, sens: float, inv_x: bool, inv_y: bool, delta_time: float,
) -> Vector2:
	var magnitude := raw.length()
	if magnitude < dead_zone or magnitude == 0.0:
		return Vector2.ZERO
	var rescaled := raw.normalized() * ((magnitude - dead_zone) / (1.0 - dead_zone))
	if inv_x:
		rescaled.x = -rescaled.x
	if inv_y:
		rescaled.y = -rescaled.y
	return rescaled * sens * delta_time

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventJoypadButton):
		return
	if event.button_index == JOY_BUTTON_A:
		_push_click(MOUSE_BUTTON_LEFT, event.pressed)
	elif event.button_index == JOY_BUTTON_B:
		_push_click(MOUSE_BUTTON_RIGHT, event.pressed)

## A -> a real left-click, B -> a real right-click -- not a bespoke click/back pair, per the
## session's own explicit ask that downstream Control code be unable to tell the difference.
## Right-click already carries "the secondary/cancel-ish action" meaning in this project's own
## locked mouse scheme (session 4.4 wires left-click=play, right-click=drop), so B reuses that
## existing meaning instead of inventing a parallel gamepad-only one.
func _push_click(button: MouseButton, pressed: bool) -> void:
	var mb := InputEventMouseButton.new()
	mb.button_index = button
	mb.pressed = pressed
	mb.position = cursor_position
	mb.global_position = cursor_position
	get_viewport().push_input(mb)

func _push_motion_event(relative: Vector2) -> void:
	var mm := InputEventMouseMotion.new()
	mm.position = cursor_position
	mm.global_position = cursor_position
	mm.relative = relative
	get_viewport().push_input(mm)

func _update_visual() -> void:
	visual.position = cursor_position

func _make_reticle_texture() -> ImageTexture:
	var img := Image.create(RETICLE_TEXTURE_SIZE, RETICLE_TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var center := Vector2(RETICLE_TEXTURE_SIZE - 1, RETICLE_TEXTURE_SIZE - 1) / 2.0
	for y in range(RETICLE_TEXTURE_SIZE):
		for x in range(RETICLE_TEXTURE_SIZE):
			if Vector2(x, y).distance_to(center) <= RETICLE_RADIUS:
				img.set_pixel(x, y, Color(1, 1, 1, 0.85))
	return ImageTexture.create_from_image(img)

func set_sensitivity(value: float) -> void:
	sensitivity = maxf(1.0, value)
	save_settings()

func set_deadzone(value: float) -> void:
	deadzone = clampf(value, 0.0, 0.9)
	save_settings()

func set_invert_x(value: bool) -> void:
	invert_x = value
	save_settings()

func set_invert_y(value: bool) -> void:
	invert_y = value
	save_settings()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		sensitivity = config.get_value(CONFIG_SECTION, "sensitivity", sensitivity)
		deadzone = config.get_value(CONFIG_SECTION, "deadzone", deadzone)
		invert_x = config.get_value(CONFIG_SECTION, "invert_x", invert_x)
		invert_y = config.get_value(CONFIG_SECTION, "invert_y", invert_y)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(CONFIG_SECTION, "sensitivity", sensitivity)
	config.set_value(CONFIG_SECTION, "deadzone", deadzone)
	config.set_value(CONFIG_SECTION, "invert_x", invert_x)
	config.set_value(CONFIG_SECTION, "invert_y", invert_y)
	config.save(CONFIG_PATH)
