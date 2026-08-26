class_name TileResource
extends Resource

enum HeatOrigin {
	PLAYER,
	ZOMBIE,
	WILDLIFE,
	RADIO,
	OTHER,
}

@export var walkable: bool = true
@export var blocks_zombie: bool = false
@export var blocks_noise: bool = false

## Single current value. Only ever changes by addition (a rise from an action or bleed
## from a neighbor) or subtraction (decay) — never wholesale overwritten by a new source.
@export var heat: float = 0.0

## Which HeatOrigin values touched this tile during the current turn — not how much each
## contributed, just which sources landed here. A single last-origin tag can't survive
## player/zombie/radio heat all landing on one tile in the same turn once Phase 10 exists,
## and session 12.2's audio cue needs to know all of them, not just whichever wrote last.
## Runtime-only turn state, not authored per-tile data, so it isn't @export'd; cleared at
## the start of every new turn. Dictionary keys give set membership with no native Set type.
var this_turn_origins: Dictionary = {}

func add_heat_origin(origin: HeatOrigin) -> void:
	this_turn_origins[origin] = true

func clear_turn_origins() -> void:
	this_turn_origins.clear()
