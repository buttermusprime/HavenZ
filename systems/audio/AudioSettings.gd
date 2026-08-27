extends Node

const CONFIG_PATH := "user://settings.cfg"
const CONFIG_SECTION := "audio"

## Linear 0..1 per bus, matching a typical Settings-menu slider. Converted to dB when
## applied to AudioServer. No Settings UI exists yet (that's session 12.1) — this is the
## persistence/apply layer built ahead of it, per the same "build the plumbing before the
## screen" pattern as session 0.1's localization stub.
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0

func _ready() -> void:
	load_settings()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume("Master", master_volume)
	save_settings()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume("SFX", sfx_volume)
	save_settings()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume("Music", music_volume)
	save_settings()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		master_volume = config.get_value(CONFIG_SECTION, "master_volume", master_volume)
		sfx_volume = config.get_value(CONFIG_SECTION, "sfx_volume", sfx_volume)
		music_volume = config.get_value(CONFIG_SECTION, "music_volume", music_volume)
	_apply_bus_volume("Master", master_volume)
	_apply_bus_volume("SFX", sfx_volume)
	_apply_bus_volume("Music", music_volume)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(CONFIG_SECTION, "master_volume", master_volume)
	config.set_value(CONFIG_SECTION, "sfx_volume", sfx_volume)
	config.set_value(CONFIG_SECTION, "music_volume", music_volume)
	config.save(CONFIG_PATH)

func _apply_bus_volume(bus_name: String, linear_volume: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		push_warning("AudioSettings: no bus named '%s' in the current bus layout." % bus_name)
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear_volume))
