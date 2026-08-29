# Exercises: res://systems/input/GamepadCursor.gd
extends SceneTree

## First test file in scripts/tests/ui/ -- click-path/interaction test per session 0.5's own
## folder split, since this exercises real Control hit-testing, not pure data logic like
## deck_test.gd (scripts/tests/logic/). Same run pattern deck_test.gd established: a plain
## SceneTree script, `godot --headless --script <path>`, PASS/FAIL printed per check.

var failures := 0

func _check(name: String, ok: bool) -> void:
	if ok:
		print("PASS: ", name)
	else:
		print("FAIL: ", name)
		failures += 1

func _initialize() -> void:
	await process_frame  # GamepadCursor is an autoload; let its own _ready() actually run first

	var cursor := get_root().get_node("GamepadCursor")
	_check("GamepadCursor autoload is present", cursor != null)
	_check(
		"GamepadCursor survives pause (PROCESS_MODE_ALWAYS, per session 0.4's own convention)",
		cursor.process_mode == Node.PROCESS_MODE_ALWAYS,
	)

	# --- Pure motion math (deliberately factored out of _process() for exactly this) ---
	var zero_below_deadzone: Vector2 = cursor._compute_motion(Vector2(0.1, 0.0), 0.2, 200.0, false, false, 1.0)
	_check("stick input below the deadzone produces zero motion", zero_below_deadzone == Vector2.ZERO)

	var moves_right: Vector2 = cursor._compute_motion(Vector2(1.0, 0.0), 0.2, 200.0, false, false, 1.0)
	_check("full-right stick input moves the cursor in +X with no Y drift", moves_right.x > 0.0 and is_zero_approx(moves_right.y))

	var inverted: Vector2 = cursor._compute_motion(Vector2(1.0, 0.0), 0.2, 200.0, true, false, 1.0)
	_check("invert_x flips the X sign without touching Y", inverted.x < 0.0 and is_zero_approx(inverted.y))

	var inverted_y: Vector2 = cursor._compute_motion(Vector2(0.0, 1.0), 0.2, 200.0, false, true, 1.0)
	_check("invert_y flips the Y sign independently of invert_x", inverted_y.y < 0.0)

	var at_full_deflection: Vector2 = cursor._compute_motion(Vector2(1.0, 0.0), 0.2, 200.0, false, false, 1.0)
	_check(
		"full deflection moves at (close to) the full sensitivity, not the raw pre-rescale value",
		at_full_deflection.x > 199.0 and at_full_deflection.x <= 200.01,
	)

	# --- Settings persistence round-trip ---
	cursor.set_sensitivity(333.0)
	cursor.set_deadzone(0.35)
	cursor.set_invert_x(true)
	cursor.set_invert_y(true)
	var reloaded_config := ConfigFile.new()
	reloaded_config.load(cursor.CONFIG_PATH)
	_check(
		"saved settings round-trip through the real ConfigFile on disk",
		reloaded_config.get_value(cursor.CONFIG_SECTION, "sensitivity") == 333.0
		and reloaded_config.get_value(cursor.CONFIG_SECTION, "deadzone") == 0.35
		and reloaded_config.get_value(cursor.CONFIG_SECTION, "invert_x") == true
		and reloaded_config.get_value(cursor.CONFIG_SECTION, "invert_y") == true,
	)
	# Restore defaults so this test doesn't leave the shared settings.cfg permanently mutated
	# for whichever session/session-log-checking-human opens the project next.
	cursor.set_sensitivity(220.0)
	cursor.set_deadzone(0.2)
	cursor.set_invert_x(false)
	cursor.set_invert_y(false)

	# --- Real click routing: A -> a genuine left-click a real Control actually receives ---
	var button := Button.new()
	button.position = Vector2(100, 100)
	button.size = Vector2(50, 20)
	get_root().add_child(button)
	await process_frame

	# Array, not a plain int -- GDScript lambdas capture outer locals by value, not reference
	# (this project's own well-documented E3 gotcha), so a bare `press_count += 1` inside the
	# lambda would only ever mutate the closure's own private copy.
	var press_count := [0]
	button.pressed.connect(func(): press_count[0] += 1)

	cursor.cursor_position = button.position + button.size / 2.0
	cursor._push_click(MOUSE_BUTTON_LEFT, true)
	await process_frame
	cursor._push_click(MOUSE_BUTTON_LEFT, false)
	await process_frame

	_check(
		"A's simulated left-click, routed through push_input(), fires a real Button's pressed signal",
		press_count[0] > 0,
	)
	button.queue_free()

	print("")
	if failures == 0:
		print("ALL CHECKS PASSED")
	else:
		print(failures, " CHECK(S) FAILED")
	quit(1 if failures > 0 else 0)
