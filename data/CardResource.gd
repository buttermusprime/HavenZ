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
