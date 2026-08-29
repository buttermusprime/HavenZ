extends Button

## Session 4.3 -- one programmer-art card slot inside HandUI's fan (no card-frame art exists
## anywhere in the pack, per the Asset Audit -- StyleBoxFlat panel instead of waiting on new
## art). A real Button, not a plain Panel, deliberately: it provides the focus/hover/click
## plumbing session 4.4's play/drop branch builds directly on top of.
##
## mouse_entered grabs focus so mouse hover and D-pad/gamepad focus converge onto the exact same
## underlying Control focus state -- Godot's own "focus" theme override then drives ONE shared
## highlight visual for both input methods, per the session's own explicit "downstream code
## shouldn't need to know which input method set it" requirement.
##
## Session 4.4 -- play_requested/drop_requested added via the `gui_input` SIGNAL rather than
## Button's own native `pressed` signal, which only ever fires for a LEFT click. A first attempt
## overrode the _gui_input() virtual method directly, calling super._gui_input() to try to keep
## Button's native press/hover visual state working -- that doesn't work: Control's _gui_input
## has no GDScript-visible base implementation to call via `super.`, so a script that overrides
## the METHOD replaces the engine's own native click/hover processing entirely rather than
## chaining to it (confirmed the hard way: it silently broke Button's own click handling).
## Connecting to the `gui_input` SIGNAL instead is a pure notification -- Button's native
## processing runs completely unaffected, exactly like the tile ColorRects' own
## `gui_input.connect(...)` pattern already established back in session 1.1. This only fires
## when a click lands DIRECTLY on this slot; HandUI's own top-level _unhandled_input() handles a
## click that lands anywhere else on screen, applying it to whichever slot currently has focus
## instead.

signal play_requested
signal drop_requested

## Category -> localization key. Lives here (UI presentation), not on CardResource/Deck --
## CardResource's own enum is already HavenZ-specific, but Deck must stay generic, so this
## mapping belongs with whichever layer actually renders it, not the data classes.
const CATEGORY_KEYS := {
	CardResource.Category.ATTACK: "CATEGORY_ATTACK",
	CardResource.Category.LOOT: "CATEGORY_LOOT",
	CardResource.Category.TRAP: "CATEGORY_TRAP",
	CardResource.Category.DISTRACTION: "CATEGORY_DISTRACTION",
	CardResource.Category.MOVE_STEALTH: "CATEGORY_MOVE_STEALTH",
	CardResource.Category.MOVE_LOUD: "CATEGORY_MOVE_LOUD",
	CardResource.Category.SUPPLY_FOOD: "CATEGORY_SUPPLY_FOOD",
	CardResource.Category.SUPPLY_WATER: "CATEGORY_SUPPLY_WATER",
	CardResource.Category.SUPPLY_MEDICAL: "CATEGORY_SUPPLY_MEDICAL",
	CardResource.Category.SUPPLY_SCRAP: "CATEGORY_SUPPLY_SCRAP",
}

var card: CardResource

func _ready() -> void:
	mouse_entered.connect(grab_focus)
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		play_requested.emit()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		drop_requested.emit()

## card.display_name is a localization KEY (e.g. "CARD_ATTACK"), not literal display text --
## every piece of card text goes through tr(), per session 4.3's explicit rule, so a raw English
## string never reaches the screen directly. .format() is a documented no-op on any string with
## no matching {0} placeholder, so calling it unconditionally here is safe for every card even
## though only a couple of translation values actually use {0} -- no per-category special case
## needed for whether a given card's name/noise text happens to interpolate anything.
##
## Session 5.1 -- noise_cost means something different for the two Move categories than for
## everything else (a per-tile RATE, not a flat amount -- see CardResource.noise_cost's own
## comment), so the noise label branches on category rather than always showing the raw number:
## a flat "0.0" on Sprint would misleadingly imply it's silent, when its real cost scales with
## however far the player ends up moving.
##
## Resolves its Label children via get_node() rather than cached @onready vars, on purpose:
## HandUI.refresh() calls setup() on a slot the very same frame it's add_child()ed, before this
## node's own _ready() is guaranteed to have run (the same "add_child() doesn't mean _ready() ran
## yet" timing this project has hit before in test harnesses -- this time inside real game code).
## get_node() walks the actual scene structure, which instantiate() already built regardless of
## whether _ready() notifications have fired, so it works correctly at any call time; an @onready
## var specifically would still read null in that same window.
func setup(new_card: CardResource) -> void:
	card = new_card
	%NameLabel.text = tr(card.display_name).format([card.move_range])
	%CategoryLabel.text = tr(CATEGORY_KEYS.get(card.category, ""))
	var is_move := card.category in [CardResource.Category.MOVE_STEALTH, CardResource.Category.MOVE_LOUD]
	var noise_key := "CARD_NOISE_LABEL_PER_TILE" if is_move else "CARD_NOISE_LABEL"
	%NoiseLabel.text = tr(noise_key).format([card.noise_cost])
