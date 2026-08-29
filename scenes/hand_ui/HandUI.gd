extends HBoxContainer

## Session 4.3 -- real Deck-backed hand display, replacing the gray-box's old per-card Button
## placeholder built ad hoc in GrayBox.gd. Anchored to the bottom of the viewport (see the
## .tscn) and laid out entirely by this HBoxContainer -- no hardcoded card positions anywhere.
##
## D-pad quick-switch moves real Control focus between slots via two NEW dedicated project
## actions, hand_focus_prev/hand_focus_next (D-pad Left/Right only) -- deliberately NOT Godot's
## default ui_left/ui_right, which are ALSO bound to the left stick's X-axis (confirmed via
## InputMap.action_get_events()). Reusing ui_left/right here would mean aiming session 4.2's
## virtual cursor with the stick silently yanks hand focus on every nudge -- the roadmap's own
## Input Scheme keeps "stick drives the cursor" and "D-pad quick-switches the hand" as two
## genuinely separate interactions, and sharing an action would quietly merge them back into one.
##
## Deliberately generic about WHAT a press does: emits card_slot_pressed(index) and leaves the
## caller (GrayBox, today; session 4.4's real play/drop branch, going forward) to decide what
## that means, the same separation-of-concerns Deck itself already follows.

signal card_slot_pressed(index: int)

const CARD_SLOT_SCENE := preload("res://scenes/hand_ui/CardSlot.tscn")

var deck: Deck

func setup(new_deck: Deck) -> void:
	deck = new_deck
	await refresh()

## Rebuilds every card slot from deck.hand. Call after any change to the hand -- the initial
## deal triggers this once here; session 4.4's play/drop resolution will call it again after
## mutating the deck, which is the actual "hand updates live when cards are drawn" this session
## sets up but doesn't yet exercise (nothing mutates the hand until 4.4 exists).
##
## Awaits one process_frame before grabbing focus on the freshly-built slots: a node this script
## itself just add_child()ed is not guaranteed to be is_inside_tree() yet the instant add_child()
## returns (the same "add_child() doesn't mean ready/in-tree yet" timing this project has hit
## before in test harnesses -- here it's real game code, caught the same way, by actually running
## it rather than assuming). CardSlot.setup() itself doesn't need this -- it resolves its Labels
## via %UniqueName lookups, which the scene's owner-based unique-name table already has correct
## the instant instantiate() builds the subtree, regardless of _ready() timing.
func refresh() -> void:
	var previous_focus := _focused_index()
	# remove_child() (not just queue_free()) so get_child_count() reflects the change
	# immediately -- queue_free() alone defers actual removal to end-of-frame, which would
	# leave old and new slots coexisting in get_children() for the rest of this function.
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for i in range(deck.hand.size()):
		var slot := CARD_SLOT_SCENE.instantiate()
		add_child(slot)
		slot.setup(deck.hand[i])
		slot.pressed.connect(_on_slot_pressed.bind(i))
	await get_tree().process_frame
	_focus_index(clampi(previous_focus, 0, get_child_count() - 1))

func _on_slot_pressed(index: int) -> void:
	card_slot_pressed.emit(index)

func _focused_index() -> int:
	for i in range(get_child_count()):
		if get_child(i).has_focus():
			return i
	return 0

func _focus_index(index: int) -> void:
	if index >= 0 and index < get_child_count():
		get_child(index).grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("hand_focus_prev"):
		_shift_focus(-1)
	elif event.is_action_pressed("hand_focus_next"):
		_shift_focus(1)

func _shift_focus(direction: int) -> void:
	var count := get_child_count()
	if count == 0:
		return
	_focus_index(wrapi(_focused_index() + direction, 0, count))
