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

## Dual meaning by category, per the Noise System Design doc's starting values (session 5.1
## made this real): for every non-Move category, a FLAT heat amount added once when the card
## resolves (Attack +3, Loot +2; Trap/Distraction have no doc-specified value yet, flagged for
## Phase 1 tuning). For MOVE_STEALTH/MOVE_LOUD specifically, this is instead a PER-TILE rate —
## the real heat charged is `noise_cost * tiles actually moved` (0 for Stealth, +1/tile for
## Loud) computed in GrayBox.apply_effect(), not applied via the generic flat-heat path every
## other category uses.
@export var noise_cost: float = 0.0

## Effect payload — shape is undecided until Phase 1/4 build real card resolution.
@export var effect_data: Dictionary = {}

## Max tile range for a movement card. The card picks how FAR you can go (and how much that
## costs, per noise_cost's per-tile rate above); the player still picks WHICH direction and
## exactly how far up to that cap by clicking a tile after playing it — baking the direction
## into the card too made movement feel bad in practice (a bad hand of cards could leave you
## unable to go the direction you actually needed, e.g. only "South" cards while fleeing
## something to the north; confirmed directly across several real playtest sittings in S1.1).
## Only meaningful when category is a MOVE_* type; zero for every other category. Session 5.1
## made MOVE_STEALTH a real, distinct category for the first time (GDD §10.5): a fixed 1-tile
## range with noise_cost 0, vs. MOVE_LOUD's (§10.6) 2-3 tile range at noise_cost's real +1/tile.
@export var move_range: int = 0
