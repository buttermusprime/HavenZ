class_name CardResource
extends Resource

enum Category {
	ATTACK,
	LOOT,
	TRAP,
	DISTRACTION,
	MOVE_STEALTH,
	MOVE_LOUD,
	SUPPLY_FOOD,
	SUPPLY_WATER,
	SUPPLY_MEDICAL,
	SUPPLY_SCRAP,
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var category: Category = Category.ATTACK

## Heat this card adds to its target/origin tile when played (same value GDD §8 calls
## "noise_cost" — see TileResource.heat for the per-tile mechanic this feeds).
## Starting values from the Noise System Design doc: Attack +3, Loot +2, MoveLoud +1/tile,
## MoveStealth +0. Trap and Distraction have no doc-specified value yet; Trap defaults
## low/near-zero and Distraction defaults high here, both flagged for Phase 1 tuning.
@export var noise_cost: float = 0.0

## Effect payload — shape is undecided until Phase 1/4 build real card resolution.
@export var effect_data: Dictionary = {}

## Direction and tile count for a movement card, baked into the card itself rather than chosen
## after playing it — per the design, deciding WHICH movement card to play (not where to click
## afterward) is the actual tactical choice. Only meaningful when category is a MOVE_* type; zero
## for every other category. Stealth vs. loud movement is no longer a per-card distinction (the
## debug radio dial in the S1.1 gray-box already governs how loud the player is being), so
## MOVE_STEALTH is currently unused rather than removed from the enum.
@export var move_direction: Vector2i = Vector2i.ZERO
@export var move_distance: int = 0
