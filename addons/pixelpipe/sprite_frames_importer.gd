## Builds a Godot SpriteFrames resource -- and, where slice data is present,
## Area2D/CollisionShape2D nodes -- from one of C.3's exported Aseprite
## sheet+JSON pairs (scripts/export_sheet.py, Aseprite --format json-array).
##
## json_path must be a res:// path to the exported .json; the sheet PNG is
## resolved from meta.image relative to the same folder and loaded via
## load(), so it must already be imported by the Godot editor (open the
## project once after a pixelpipe sync so the .import files exist).
@tool
class_name PixelPipeSpriteFramesImporter
extends RefCounted

const DEFAULT_ANIMATION_NAME := "default"
const SHARED_PALETTE_MATERIAL_PATH := "res://addons/pixelpipe/shared_palette_material.tres"
const MANIFEST_FILENAME := "asset_manifest.json"


## Rebuilds every exported JSON found (recursively) under folder into a sibling
## .tscn. Returns how many succeeded. Shared by both driver wrappers --
## import_sprite_frames.gd (EditorScript, File > Run convenience inside an
## already-open editor) and import_sprite_frames_headless.gd (plain SceneTree,
## for `godot --headless --script`, no editor session needed at all -- see
## that file's header comment for why this doesn't actually require one,
## despite EditorScript's own hard CLI restriction).
static func run_for_folder(folder: String) -> int:
	var count := 0
	for json_path in _find_json_files(folder):
		if import_one(json_path):
			count += 1
	return count


## Rebuilds a single exported JSON's scene + saves it as a sibling .tscn.
## Returns true on success.
static func import_one(json_path: String) -> bool:
	var scene_root := build_scene(json_path)
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


static func _find_json_files(folder: String) -> Array[String]:
	var results: Array[String] = []
	for entry in ResourceLoader.list_directory(folder):
		if entry.ends_with("/"):
			results.append_array(_find_json_files(folder.path_join(entry)))
		elif entry.ends_with(".json") and entry != MANIFEST_FILENAME:
			results.append(folder.path_join(entry))
	return results


## One animation per Aseprite Tag. A source with no Tags at all gets a
## single "default" animation covering every frame, forward.
static func build_sprite_frames(json_path: String) -> SpriteFrames:
	var data := _read_json(json_path)
	if data.is_empty():
		return null

	var frame_entries: Array = data.get("frames", [])
	var sheet_texture := _load_sheet_texture(json_path, data)
	if sheet_texture == null:
		return null

	var frame_textures: Array[AtlasTexture] = []
	var frame_durations: Array[float] = []
	for entry in frame_entries:
		var rect: Dictionary = entry["frame"]
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet_texture
		atlas.region = Rect2(rect["x"], rect["y"], rect["w"], rect["h"])
		frame_textures.append(atlas)
		# Aseprite gives per-frame duration in ms. Animation speed is fixed
		# at 1.0 fps below so this seconds value is used as-is per frame,
		# rather than needing every frame to share one uniform duration.
		frame_durations.append(float(entry.get("duration", 100)) / 1000.0)

	var sprite_frames := SpriteFrames.new()
	if sprite_frames.has_animation(DEFAULT_ANIMATION_NAME):
		sprite_frames.remove_animation(DEFAULT_ANIMATION_NAME)

	var tags: Array = data.get("meta", {}).get("frameTags", [])
	if tags.is_empty():
		_add_animation(sprite_frames, DEFAULT_ANIMATION_NAME, frame_textures, frame_durations, 0, frame_textures.size() - 1, "forward")
	else:
		for tag in tags:
			_add_animation(sprite_frames, String(tag["name"]), frame_textures, frame_durations, int(tag["from"]), int(tag["to"]), String(tag["direction"]))

	return sprite_frames


## One Area2D (named after the slice) + a RectangleShape2D CollisionShape2D
## per Aseprite Slice, positioned/sized from the slice's first key. Slices
## with per-frame animated bounds (more than one key) are supported only by
## their first key -- a warning is pushed for anyone relying on the rest.
static func build_slice_areas(json_path: String) -> Array[Area2D]:
	var data := _read_json(json_path)
	var areas: Array[Area2D] = []
	if data.is_empty():
		return areas

	var slices: Array = data.get("meta", {}).get("slices", [])
	for slice in slices:
		var keys: Array = slice.get("keys", [])
		if keys.is_empty():
			continue
		if keys.size() > 1:
			push_warning("PixelPipe: slice '%s' in %s has %d keys (animated bounds) -- only the first key is used, per-frame slice bounds aren't supported yet" % [slice.get("name", "?"), json_path, keys.size()])

		var bounds: Dictionary = keys[0]["bounds"]
		var area := Area2D.new()
		area.name = String(slice["name"])

		var rect_shape := RectangleShape2D.new()
		rect_shape.size = Vector2(bounds["w"], bounds["h"])

		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		shape.shape = rect_shape
		shape.position = Vector2(bounds["x"], bounds["y"]) + rect_shape.size / 2.0
		area.add_child(shape)

		areas.append(area)

	return areas


## Convenience wrapper: an AnimatedSprite2D (defaulting to the first Tag's
## animation, in the order Aseprite exported them) plus one child Area2D per
## slice, as a plain Node2D the caller can pack into a PackedScene and save
## as a .tscn.
static func build_scene(json_path: String) -> Node2D:
	var data := _read_json(json_path)
	if data.is_empty():
		return null

	var sprite_frames := build_sprite_frames(json_path)
	if sprite_frames == null:
		return null

	var root := Node2D.new()
	root.name = json_path.get_file().get_basename().validate_node_name()

	var sprite := AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.sprite_frames = sprite_frames
	# AnimatedSprite2D.centered defaults to true in Godot 4.6 (verified
	# against the real engine), which draws each frame offset by
	# -texture_size/2 from the node's local origin. build_slice_areas()
	# below positions Area2D shapes assuming pixel (0,0) of a frame sits at
	# local (0,0) -- the same top-left-origin coordinate space Aseprite's
	# own slice bounds are authored in -- so centering must be turned off
	# here or every slice-derived shape silently lands offset by half the
	# sprite's size. Confirmed as a real bug via manual editor testing: a
	# hitbox meant to sit centered on an 8x8 sprite showed up shifted
	# down-and-right, overlapping only the bottom-right quadrant.
	sprite.centered = false
	# Deliberately NOT sprite_frames.get_animation_names()[0] -- that method
	# returns names alphabetically sorted, not in Tag/export order, which
	# silently picked the wrong "default" animation (confirmed against the
	# real engine: a source tagged ["walk", "idle"] in that export order
	# defaulted to "idle" via get_animation_names(), not "walk").
	sprite.animation = _first_animation_name(data)
	# Every pixelpipe-managed sprite references one shared ShaderMaterial
	# instance by default (F.1's palette_unified.gdshader, merging D.2's
	# remap and D.5's glow into a single pass), not a unique material per
	# sprite -- this is what makes a project-wide color remap a single dock
	# action instead of per-sprite work, avoids fragmenting Godot's 2D
	# batching, and resolves the single-material-slot conflict D.5 flagged
	# but didn't fix (remap and glow are now always both available on every
	# sprite, no manual second-material assignment). Guarded rather than
	# required: a project that has run D.1 before ever running F.1 (out of
	# the intended session order) still gets a working, materialless sprite
	# instead of a load error.
	if ResourceLoader.exists(SHARED_PALETTE_MATERIAL_PATH):
		sprite.material = load(SHARED_PALETTE_MATERIAL_PATH)
	root.add_child(sprite)
	sprite.owner = root

	for area in build_slice_areas(json_path):
		root.add_child(area)
		area.owner = root
		for child in area.get_children():
			child.owner = root

	return root


static func _add_animation(sprite_frames: SpriteFrames, anim_name: String, frame_textures: Array[AtlasTexture], frame_durations: Array[float], from_idx: int, to_idx: int, direction: String) -> void:
	var order := _frame_order(from_idx, to_idx, direction)
	sprite_frames.add_animation(anim_name)
	sprite_frames.set_animation_speed(anim_name, 1.0)  # a no-op multiplier -- per-frame durations below are already real seconds
	# Aseprite's export JSON carries no loop/repeat field for a Tag (verified
	# against 1.3.18.1-x64: the Lua Tag object has no "repeat" property
	# either), so looping is a deliberate default here, not a parsed value.
	sprite_frames.set_animation_loop(anim_name, true)
	for idx in order:
		sprite_frames.add_frame(anim_name, frame_textures[idx], frame_durations[idx])


## Expands an Aseprite Tag's from/to range + playback direction into the
## actual ordered frame-index sequence, since Godot's SpriteFrames has no
## built-in ping-pong playback mode -- pingpong/pingpong_reverse are baked in
## as real repeated frames instead. Matches Aseprite's documented tag
## playback patterns (e.g. a 4-frame pingpong tag 0..3 plays 0,1,2,3,2,1
## before looping) -- derived from Aseprite's own docs, not confirmed against
## its interactive playback preview since batch/CLI export has no such view.
static func _frame_order(from_idx: int, to_idx: int, direction: String) -> Array[int]:
	var forward: Array[int] = []
	for i in range(from_idx, to_idx + 1):
		forward.append(i)

	match direction:
		"forward":
			return forward
		"reverse":
			var order := forward.duplicate()
			order.reverse()
			return order
		"pingpong":
			var order := forward.duplicate()
			for i in range(forward.size() - 2, 0, -1):
				order.append(forward[i])
			return order
		"pingpong_reverse":
			var order := forward.duplicate()
			order.reverse()
			for i in range(order.size() - 2, 0, -1):
				order.append(order[i])
			return order
		_:
			push_warning("PixelPipe: unrecognized Aseprite tag direction '%s', treating as forward" % direction)
			return forward


static func _first_animation_name(data: Dictionary) -> String:
	var tags: Array = data.get("meta", {}).get("frameTags", [])
	if tags.is_empty():
		return DEFAULT_ANIMATION_NAME
	return String(tags[0]["name"])


static func _read_json(json_path: String) -> Dictionary:
	if not FileAccess.file_exists(json_path):
		push_error("PixelPipe: exported JSON not found: %s" % json_path)
		return {}
	var file := FileAccess.open(json_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("PixelPipe: malformed export JSON (not an object): %s" % json_path)
		return {}
	return parsed


static func _load_sheet_texture(json_path: String, data: Dictionary) -> Texture2D:
	var image_name: String = data.get("meta", {}).get("image", "")
	if image_name.is_empty():
		push_error("PixelPipe: exported JSON has no meta.image: %s" % json_path)
		return null
	var sheet_path := json_path.get_base_dir().path_join(image_name)
	if not ResourceLoader.exists(sheet_path):
		push_error("PixelPipe: sheet texture not imported yet: %s (open the Godot editor once after syncing so it gets a .import file)" % sheet_path)
		return null
	return load(sheet_path)
