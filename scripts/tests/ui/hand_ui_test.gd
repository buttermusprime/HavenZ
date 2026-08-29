# Exercises: res://scenes/hand_ui/HandUI.gd, res://scenes/hand_ui/CardSlot.gd
# Session 4.4 update: play_requested/drop_requested replaced the old card_slot_pressed signal.
extends SceneTree

## Third test file (deck_test.gd in logic/, gamepad_cursor_test.gd was the first in ui/) -- same
## run pattern: plain SceneTree script, godot --headless --script <path>, PASS/FAIL per check.

var failures := 0

func _check(name: String, ok: bool) -> void:
	if ok:
		print("PASS: ", name)
	else:
		print("FAIL: ", name)
		failures += 1

func _make_cards(count: int) -> Array[CardResource]:
	var cards: Array[CardResource] = []
	for i in range(count):
		var card := CardResource.new()
		card.id = "test_card_%d" % i
		card.display_name = "CARD_ATTACK"
		cards.append(card)
	return cards

## Real, confirmed `--script`-mode limitation (not a bug in this project's own code): Godot's
## project-configured `locale/translations` setting names the CSV's SOURCE path
## (res://localization/strings.csv), which `--script` mode fails to load at all -- confirmed via
## a direct load() call returning null with the exact same "Failed loading resource" error the
## boot log already shows, even immediately after a fully clean cache wipe and reimport (ruling
## out stale-cache staleness). The COMPILED .translation output loads and resolves correctly by
## its own real path, in both --headless and real-GPU-window modes alike, so this is specific to
## resolving a csv_translation-imported resource by its source path in this run mode, not
## anything wrong with the CSV content or its import. Manually registering the compiled
## translation directly is the workaround for THIS TEST HARNESS only -- a real windowed game
## boot (this project's actual shipping path) goes through Godot's normal engine-level automatic
## translation registration, which this finding has no reason to doubt.
func _load_test_translations() -> void:
	var compiled: Translation = load("res://localization/strings.en.translation")
	if compiled:
		TranslationServer.add_translation(compiled)

func _initialize() -> void:
	_load_test_translations()
	var deck := Deck.new(_make_cards(8), 5)
	var hand_ui: HBoxContainer = load("res://scenes/hand_ui/HandUI.tscn").instantiate()
	get_root().add_child(hand_ui)
	# A node this script itself add_child()s to get_root() during _initialize() isn't
	# guaranteed is_inside_tree() (or even get_tree()-valid) the instant add_child() returns --
	# this project's own established pre-4.3 pattern for exactly this. HandUI.refresh()'s own
	# internal frame-wait handles later add_child()s it does to ITSELF once hand_ui is properly
	# in-tree; this first one is ours to wait out.
	await process_frame
	# setup() awaits refresh()'s own internal frame-wait, so awaiting it here is a precise
	# synchronization point rather than guessing how many process_frame ticks are "enough."
	await hand_ui.setup(deck)

	_check("HandUI builds exactly one CardSlot per hand card", hand_ui.get_child_count() == deck.hand.size())

	var first_slot: Button = hand_ui.get_child(0)
	var first_name_label: Label = first_slot.get_node("%NameLabel")
	_check(
		"a card slot's name label resolves the real translation, not the raw key",
		first_name_label.text == tr("CARD_ATTACK"),
	)
	_check(
		"the translated text is real display text, not the untranslated key itself",
		first_name_label.text != "CARD_ATTACK",
	)

	_check("the first slot has initial focus after setup()", first_slot.has_focus())

	# --- Mouse hover and D-pad focus converge on the same real Control focus state ---
	hand_ui.get_child(2).emit_signal("mouse_entered")
	_check("mouse_entered on a slot grabs real Control focus (unifies hover and focus)", hand_ui.get_child(2).has_focus())

	# _shift_focus() is exactly what _unhandled_input() calls once hand_focus_next/prev fires --
	# exercising it directly here avoids needing to fabricate a real joypad D-pad event that
	# Input's own action-pressed state would recognize.
	hand_ui._shift_focus(1)
	_check("hand_focus_next moves focus to the next slot (index 2 -> 3)", hand_ui.get_child(3).has_focus())

	hand_ui._focus_index(0)
	hand_ui._shift_focus(-1)
	_check(
		"hand_focus_prev from index 0 wraps around to the last slot instead of erroring",
		hand_ui.get_child(hand_ui.get_child_count() - 1).has_focus(),
	)

	# --- Real click routing, path 1: a click landing DIRECTLY on a slot (CardSlot's own
	# gui_input signal handler, NOT an overridden _gui_input() -- that was tried first and
	# found to silently break Button's native click processing, since Control's _gui_input has
	# no GDScript-visible base implementation a script override can chain to via `super.`)
	# fires that slot's play_requested/drop_requested with ITS index ---
	var played := [-1]
	var dropped := [-1]
	hand_ui.card_play_requested.connect(func(i): played[0] = i)
	hand_ui.card_drop_requested.connect(func(i): dropped[0] = i)

	var left_click := InputEventMouseButton.new()
	left_click.button_index = MOUSE_BUTTON_LEFT
	left_click.pressed = true
	hand_ui.get_child(1)._on_gui_input(left_click)
	_check("a direct left-click on slot 1 emits card_play_requested(1)", played[0] == 1)

	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	hand_ui.get_child(3)._on_gui_input(right_click)
	_check("a direct right-click on slot 3 emits card_drop_requested(3)", dropped[0] == 3)

	# --- Real click routing, path 2: a click that lands on NEITHER a slot nor the hand-focus
	# actions reaches HandUI's own _unhandled_input(), which applies it to whatever currently
	# has focus -- exactly the "left-click plays the FOCUSED card" wording, not "whatever's
	# under the cursor," and exactly what a click missing every slot (or a gamepad A/Y press
	# while the virtual cursor sits elsewhere) looks like in practice. ---
	played[0] = -1
	hand_ui._focus_index(2)
	hand_ui._unhandled_input(left_click)
	_check("a click that misses every slot plays whichever slot currently has focus (2)", played[0] == 2)

	# --- refresh() rebuilds cleanly after a real Deck mutation (what session 4.4 will trigger) ---
	deck.play_card(0)
	await hand_ui.refresh()
	_check("refresh() still shows exactly hand_size slots after a real play_card()", hand_ui.get_child_count() == deck.hand.size())

	print("")
	if failures == 0:
		print("ALL CHECKS PASSED")
	else:
		print(failures, " CHECK(S) FAILED")
	quit(1 if failures > 0 else 0)
