extends Button

## Session 4.3 -- one programmer-art card slot inside HandUI's fan (no card-frame art exists
## anywhere in the pack, per the Asset Audit -- StyleBoxFlat panel instead of waiting on new
## art). A real Button, not a plain Panel, deliberately: it already provides the focus/hover/
## click plumbing session 4.4's play/drop branch will build directly on top of, so this session
## only wires display + focus visuals, not what a press actually DOES.
##
## mouse_entered grabs focus so mouse hover and D-pad/gamepad focus converge onto the exact same
## underlying Control focus state -- Godot's own "focus" theme override then drives ONE shared
## highlight visual for both input methods, per the session's own explicit "downstream code
## shouldn't need to know which input method set it" requirement.

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

## card.display_name is a localization KEY (e.g. "CARD_ATTACK"), not literal display text --
## every piece of card text goes through tr(), per this session's own explicit rule, so a raw
## English string never reaches the screen directly. .format() is a documented no-op on any
## string with no matching {0} placeholder, so calling it unconditionally here is safe for every
## non-move card too (their translated text simply has no {0} to replace) -- avoids a special
## case for the one category (MOVE_LOUD) whose display text needs its own move_range value.
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
	%NoiseLabel.text = tr("CARD_NOISE_LABEL").format([card.noise_cost])
