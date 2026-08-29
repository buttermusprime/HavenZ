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
## Deliberately generic about WHAT a play/drop actually DOES: emits card_play_requested(index)/
## card_drop_requested(index) and leaves the caller (GrayBox's own real resolution branch) to
## decide what that means, the same separation-of-concerns Deck itself already follows.
##
## Session 4.4 -- two ways a play/drop request reaches here, both converging on the same two
## signals: (1) a click landing DIRECTLY on a CardSlot fires that slot's own play_requested/
## drop_requested (session 4.4's CardSlot.gd change), relayed below with its index; (2) a click
## landing anywhere ELSE on screen (nothing under the cursor claimed it, so it reached this
## script's own _unhandled_input()) is treated as acting on whichever slot currently has real
## Control focus -- matching the locked-in scheme's literal wording, "left-click plays the
## FOCUSED/targeted card," not merely "whatever the cursor happened to be over." Gamepad A/Y
## need zero special-case code here: session 4.2's cursor already pushes real
## InputEventMouseButton events through the same Viewport.push_input() pipeline, so they
## naturally take path (1) or (2) depending on where the virtual cursor is sitting, exactly like
## a real mouse click would.
signal card_play_requested(index: int)
signal card_drop_requested(index: int)

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
		slot.play_requested.connect(_on_slot_play_requested.bind(i))
		slot.drop_requested.connect(_on_slot_drop_requested.bind(i))
	await get_tree().process_frame
	_focus_index(clampi(previous_focus, 0, get_child_count() - 1))

func _on_slot_play_requested(index: int) -> void:
	card_play_requested.emit(index)

func _on_slot_drop_requested(index: int) -> void:
	card_drop_requested.emit(index)

## -1 when the hand is empty or nothing has focus (e.g. focus hasn't been granted yet) --
## callers must check for -1, not assume 0 is always a safe fallback index.
func _focused_index() -> int:
	for i in range(get_child_count()):
		if get_child(i).has_focus():
			return i
	return -1

func _focus_index(index: int) -> void:
	if index >= 0 and index < get_child_count():
		get_child(index).grab_focus()

## D-pad quick-switch (see the two new project actions in the class comment above) and, per
## session 4.4, a click landing anywhere OUTSIDE any specific CardSlot -- Godot's own GUI hit-
## testing already consumes a click that lands directly ON a slot (a Button with the default
## mouse_filter=STOP) before it would ever reach _unhandled_input, so this only ever fires for
## the "missed every slot" case; CardSlot.gd's own _gui_input() override handles a direct hit.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("hand_focus_prev"):
		_shift_focus(-1)
	elif event.is_action_pressed("hand_focus_next"):
		_shift_focus(1)
	elif event is InputEventMouseButton and event.pressed:
		var focused := _focused_index()
		if focused == -1:
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			card_play_requested.emit(focused)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			card_drop_requested.emit(focused)

func _shift_focus(direction: int) -> void:
	var count := get_child_count()
	if count == 0:
		return
	_focus_index(wrapi(_focused_index() + direction, 0, count))
