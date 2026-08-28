## Batch driver for PixelPipeSpriteFramesImporter: run from the Godot editor
## (File > Run, or set as the target of `godot --headless --editor --quit
## --script`) to (re)build a SpriteFrames-backed scene for every exported
## Aseprite JSON under a folder. Uses ResourceLoader.list_directory(), never
## DirAccess, so it also sees files written by an out-of-editor pixelpipe
## sync run without needing the editor to rescan first (see
## GODOT_LESSONS.md #1) -- though a fresh sync's new *files* still need one
## editor pass to pick up real .import metadata for the sheet PNGs (#5).
@tool
extends EditorScript

const SpriteFramesImporter = preload("res://addons/pixelpipe/sprite_frames_importer.gd")

const DEFAULT_ROOT := "res://art"
const MANIFEST_FILENAME := "asset_manifest.json"


func _run() -> void:
	var count := run_for_folder(DEFAULT_ROOT)
	print("PixelPipe: rebuilt %d SpriteFrames scene(s) under %s" % [count, DEFAULT_ROOT])


## Rebuilds every exported JSON found (recursively) under folder. Returns how
## many succeeded.
func run_for_folder(folder: String) -> int:
	var count := 0
	for json_path in _find_json_files(folder):
		if import_one(json_path):
			count += 1
	return count


## Rebuilds a single exported JSON's scene + saves it as a sibling .tscn.
## Returns true on success.
func import_one(json_path: String) -> bool:
	var scene_root := SpriteFramesImporter.build_scene(json_path)
	if scene_root == null:
		return false

	var packed := PackedScene.new()
	var pack_result := packed.pack(scene_root)
	if pack_result != OK:
		push_error("PixelPipe: failed to pack scene for %s (error %d)" % [json_path, pack_result])
		return false

	var out_path := json_path.get_basename() + ".tscn"
	var save_result := ResourceSaver.save(packed, out_path)
	if save_result != OK:
		push_error("PixelPipe: failed to save %s (error %d)" % [out_path, save_result])
		return false

	print("PixelPipe: %s -> %s" % [json_path, out_path])
	return true


func _find_json_files(folder: String) -> Array[String]:
	var results: Array[String] = []
	for entry in ResourceLoader.list_directory(folder):
		if entry.ends_with("/"):
			results.append_array(_find_json_files(folder.path_join(entry)))
		elif entry.ends_with(".json") and entry != MANIFEST_FILENAME:
			results.append(folder.path_join(entry))
	return results
