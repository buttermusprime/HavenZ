class_name HavenResource
extends Resource

## A physical, walled Haven per GDD §8.1 -- identity only. Layout (origin/size/entrance
## position) is placement data owned by whatever builds the map (session 3.1's gray-box-style
## hardcoded layout today; real level data later), not this resource, so it can stay this small.

@export var id: String = ""
@export var display_name: String = ""
## True for exactly one Haven per run -- the Home Haven issues Supply Requests and is the
## return point; other Havens only offer Trade/Craft (both menus stubbed until Phase 10).
@export var is_home: bool = false
