## Editor dock for D.6: bulk-duplicate a selected group of existing sprites
## into a new, permanent variant set with one or more color remaps baked
## directly into the copies -- for cases where a runtime shader (D.2)
## isn't wanted. One-shot permanent generation, no ongoing per-frame cost,
## so unlike D.4 it needs no ledger (there's nothing "still live" to track
## once the files are written) -- but still requires a Preview pass before
## Create Duplicates, per Build Guideline 03.
##
## Pipeline on Create: C.6's duplicate_and_remap.lua (copy + recolor) ->
## pixelpipe_sync.py (C.3's export + C.5's localization CSV step, both
## already wired together by C.4) -> D.1's SpriteFrames import for each new
## asset. The first two run off the main thread in one background Thread;
## D.1's import runs back on the main thread via call_deferred() (Build
## Guideline 08 -- this dock reacts to Aseprite CLI completion).
@tool
extends Control

const LutGen = preload("res://addons/pixelpipe/palette_lut_generator.gd")
const SpriteFramesImporter = preload("res://addons/pixelpipe/sprite_frames_importer.gd")
const COMMON_LUA_PATH := "res://scripts/aseprite_common.lua"
const DUP_LUA_PATH := "res://scripts/duplicate_and_remap.lua"
const SYNC_PY_PATH := "res://scripts/pixelpipe_sync.py"
const DUP_JOBS_PATH := "res://addons/pixelpipe/_dup_jobs.tmp.json"
const DEFAULT_PATTERN := "{name}_variant_{n}"

## Points at HavenZ's own config -- see palette_table_dock.gd's
## same field for why this isn't auto-discovered.
@export var config_path := "res://pixelpipe.config.json"
## Full path, NOT a bare "python" -- confirmed against the real engine that
## OS.execute("python", ...) resolves to the Windows Store's App Execution
## Alias stub (exit 9009, "Python was not found...") even on a machine
## where "python" resolves correctly in an interactive shell. Same reason
## pixelpipe.config.json's aseprite_executable is a full path rather than
## relying on PATH -- @export so a different machine/project can override
## it, same pattern as config_path above.
@export var python_executable := "C:/Users/17cor/AppData/Local/Programs/Python/Python312/python.exe"

var _palette: PackedColorArray = PackedColorArray()
var _manifest: Dictionary = {}
var _asset_list: ItemList
var _swatch_grid: GridContainer
var _swatch_group := ButtonGroup.new()
var _selected_from_index := -1
var _to_picker: ColorPickerButton
var _pairs: Array = []  # [{from: Color, to: Color}]
var _pairs_list: VBoxContainer
var _pattern_edit: LineEdit
var _preview_list: VBoxContainer
var _status_label: Label
var _confirm_dialog: ConfirmationDialog
var _create_button: Button
var _bake_thread: Thread
var _pending_new_assets: Array = []  # [{dest_res_json: String}] once export finishes


func _ready() -> void:
	_build_ui()
	_reload_palette()
	_reload_manifest()


func _exit_tree() -> void:
	if _bake_thread and _bake_thread.is_started():
		_bake_thread.wait_to_finish()


func _build_ui() -> void:
	custom_minimum_size = Vector2(260, 0)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(root)

	var title := Label.new()
	title.text = "PixelPipe — Duplicate & Recolor"
	root.add_child(title)

	var asset_label := Label.new()
	asset_label.text = "Assets to duplicate (multi-select):"
	root.add_child(asset_label)

	_asset_list = ItemList.new()
	_asset_list.select_mode = ItemList.SELECT_MULTI
	_asset_list.custom_minimum_size = Vector2(0, 80)
	root.add_child(_asset_list)

	var reload_manifest_button := Button.new()
	reload_manifest_button.text = "Reload Asset List"
	reload_manifest_button.pressed.connect(_reload_manifest)
	root.add_child(reload_manifest_button)

	root.add_child(HSeparator.new())

	var from_label := Label.new()
	from_label.text = "From (click a palette color):"
	root.add_child(from_label)

	_swatch_grid = GridContainer.new()
	root.add_child(_swatch_grid)

	var to_label := Label.new()
	to_label.text = "To:"
	root.add_child(to_label)

	_to_picker = ColorPickerButton.new()
	_to_picker.color = Color.WHITE
	_to_picker.custom_minimum_size = Vector2(0, 28)
	root.add_child(_to_picker)

	var add_pair_button := Button.new()
	add_pair_button.text = "Add Pair"
	add_pair_button.pressed.connect(_on_add_pair_pressed)
	root.add_child(add_pair_button)

	var pairs_label := Label.new()
	pairs_label.text = "Pairs to apply:"
	root.add_child(pairs_label)

	_pairs_list = VBoxContainer.new()
	root.add_child(_pairs_list)

	root.add_child(HSeparator.new())

	var pattern_label := Label.new()
	pattern_label.text = "Naming pattern ({name}, {n}):"
	root.add_child(pattern_label)

	_pattern_edit = LineEdit.new()
	_pattern_edit.text = DEFAULT_PATTERN
	root.add_child(_pattern_edit)

	var preview_button := Button.new()
	preview_button.text = "Preview"
	preview_button.pressed.connect(_on_preview_pressed)
	root.add_child(preview_button)

	_preview_list = VBoxContainer.new()
	root.add_child(_preview_list)

	_create_button = Button.new()
	_create_button.text = "Create Duplicates"
	_create_button.pressed.connect(_on_create_pressed)
	root.add_child(_create_button)

	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.title = "Create these duplicates?"
	_confirm_dialog.confirmed.connect(_on_create_confirmed)
	add_child(_confirm_dialog)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(_status_label)


func _reload_palette() -> void:
	var config := _load_config()
	if config.is_empty():
		return
	var palette_field: String = config.get("palette_path", "")
	if palette_field.is_empty():
		return
	var palette_path := config_path.get_base_dir().path_join(palette_field)
	_palette = LutGen.read_gpl(palette_path)
	_rebuild_swatch_grid()


func _rebuild_swatch_grid() -> void:
	for child in _swatch_grid.get_children():
		child.queue_free()
	var n := _palette.size()
	if n == 0:
		return
	_swatch_grid.columns = max(1, ceili(sqrt(n)))
	for i in range(n):
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(28, 28)
		swatch.toggle_mode = true
		swatch.button_group = _swatch_group
		swatch.tooltip_text = _palette[i].to_html(false)
		var style := StyleBoxFlat.new()
		style.bg_color = _palette[i]
		swatch.add_theme_stylebox_override("normal", style)
		swatch.add_theme_stylebox_override("hover", style)
		swatch.add_theme_stylebox_override("pressed", style)
		swatch.pressed.connect(_on_swatch_pressed.bind(i))
		_swatch_grid.add_child(swatch)


func _on_swatch_pressed(index: int) -> void:
	_selected_from_index = index


func _on_add_pair_pressed() -> void:
	if _selected_from_index < 0:
		_set_status("Pick a 'from' palette color first.")
		return
	_pairs.append({"from": _palette[_selected_from_index], "to": _to_picker.color})
	_refresh_pairs_list()
	_set_status("Added pair %s -> %s." % [_palette[_selected_from_index].to_html(false), _to_picker.color.to_html(false)])


func _refresh_pairs_list() -> void:
	for child in _pairs_list.get_children():
		child.queue_free()
	for i in range(_pairs.size()):
		var pair: Dictionary = _pairs[i]
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = "%s -> %s" % [pair["from"].to_html(false), pair["to"].to_html(false)]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var remove_button := Button.new()
		remove_button.text = "Remove"
		remove_button.pressed.connect(_on_remove_pair_pressed.bind(i))
		row.add_child(remove_button)
		_pairs_list.add_child(row)


func _on_remove_pair_pressed(index: int) -> void:
	_pairs.remove_at(index)
	_refresh_pairs_list()


func _reload_manifest() -> void:
	var config := _load_config()
	if config.is_empty():
		_set_status("Could not read config at %s" % config_path)
		return
	var art_field: String = config.get("art_path", "")
	if art_field.is_empty():
		_set_status("Config has no art_path")
		return
	var manifest_path := config_path.get_base_dir().path_join(art_field).path_join("asset_manifest.json")
	if not FileAccess.file_exists(manifest_path):
		_set_status("No asset_manifest.json at %s yet -- run a sync first." % manifest_path)
		_manifest = {}
	else:
		var file := FileAccess.open(manifest_path, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text())
		_manifest = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
		_set_status("Loaded %d asset(s) from %s." % [_manifest.size(), manifest_path])

	_asset_list.clear()
	for key in _manifest.keys():
		_asset_list.add_item(key)


## Computes each selected asset's [{key, source_abs, dest_res}], with
## naming-pattern collision avoidance (an existing file at the computed
## path bumps {n} up rather than silently overwriting it).
func _compute_plan() -> Array:
	var plan := []
	var pattern := _pattern_edit.text
	if pattern.is_empty():
		pattern = DEFAULT_PATTERN
	for idx in _asset_list.get_selected_items():
		var key: String = _asset_list.get_item_text(idx)
		var source_abs: String = _manifest.get(key, "")
		if source_abs.is_empty():
			continue
		var source_res := ProjectSettings.localize_path(source_abs)
		var dir := source_res.get_base_dir()
		var stem := source_res.get_file().get_basename()  # exact source casing preserved -- Guideline 10
		var dest_res := ""
		var n := 1
		while n <= 1000:
			var candidate_name: String = pattern.replace("{name}", stem).replace("{n}", str(n)) + ".aseprite"
			var candidate := dir.path_join(candidate_name)
			if not FileAccess.file_exists(candidate):
				dest_res = candidate
				break
			n += 1
		if dest_res.is_empty():
			push_error("PixelPipe: could not find a non-colliding name for %s after 1000 tries" % key)
			continue
		plan.append({"key": key, "source_abs": source_abs, "dest_res": dest_res})
	return plan


func _on_preview_pressed() -> void:
	for child in _preview_list.get_children():
		child.queue_free()

	if _asset_list.get_selected_items().is_empty():
		_set_status("Select at least one asset first.")
		return
	if _pairs.is_empty():
		_set_status("Add at least one from/to color pair first.")
		return

	var plan := _compute_plan()
	for entry in plan:
		var label := Label.new()
		label.text = "%s -> %s (%d pair(s))" % [entry["key"], entry["dest_res"], _pairs.size()]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_preview_list.add_child(label)
	_set_status("Preview: %d file(s) would be created. Nothing written yet." % plan.size())


func _on_create_pressed() -> void:
	if _asset_list.get_selected_items().is_empty():
		_set_status("Select at least one asset first.")
		return
	if _pairs.is_empty():
		_set_status("Add at least one from/to color pair first.")
		return

	var plan := _compute_plan()
	var lines := PackedStringArray()
	for entry in plan:
		lines.append("%s -> %s" % [entry["key"], entry["dest_res"]])
	_confirm_dialog.dialog_text = "This will create %d new .aseprite file(s), export them, and build SpriteFrames scenes:\n\n%s" % [plan.size(), "\n".join(lines)]
	_confirm_dialog.popup_centered()


func _on_create_confirmed() -> void:
	var plan := _compute_plan()
	if plan.is_empty():
		_set_status("Nothing to create.")
		return

	var jobs := []
	var rgb_pairs := []
	for pair in _pairs:
		rgb_pairs.append({"from": _color_to_rgb_array(pair["from"]), "to": _color_to_rgb_array(pair["to"])})
	for entry in plan:
		jobs.append({
			"source": entry["source_abs"],
			"dest": ProjectSettings.globalize_path(entry["dest_res"]),
			"pairs": rgb_pairs,
		})

	var jobs_file := FileAccess.open(DUP_JOBS_PATH, FileAccess.WRITE)
	if jobs_file == null:
		_set_status("Could not write jobs file (error %d)" % FileAccess.get_open_error())
		return
	jobs_file.store_string(JSON.stringify(jobs, "\t"))
	jobs_file.close()

	var config := _load_config()
	var aseprite_exe: String = config.get("aseprite_executable", "")
	if aseprite_exe.is_empty():
		_set_status("Config is missing aseprite_executable.")
		return

	_pending_new_assets = plan
	_set_status("Creating %d duplicate(s)..." % plan.size())
	_create_button.disabled = true

	var jobs_abs := ProjectSettings.globalize_path(DUP_JOBS_PATH)
	var common_abs := ProjectSettings.globalize_path(COMMON_LUA_PATH)
	var dup_lua_abs := ProjectSettings.globalize_path(DUP_LUA_PATH)
	var sync_py_abs := ProjectSettings.globalize_path(SYNC_PY_PATH)
	var config_abs := ProjectSettings.globalize_path(config_path)

	_bake_thread = Thread.new()
	_bake_thread.start(_worker.bind(aseprite_exe, jobs_abs, common_abs, dup_lua_abs, sync_py_abs, config_abs))


## Runs off the main thread (Guideline 08): Aseprite duplicate+remap, then
## the Python sync orchestrator (C.3 export + C.5 localization, already
## chained together by C.4) -- both purely subprocess calls, no node/UI
## access here.
func _worker(aseprite_exe: String, jobs_abs: String, common_abs: String, dup_lua_abs: String, sync_py_abs: String, config_abs: String) -> void:
	var dup_output := []
	var dup_exit := OS.execute(aseprite_exe, [
		"-b",
		"--script-param", "jobs=%s" % jobs_abs,
		"--script-param", "common=%s" % common_abs,
		"--script", dup_lua_abs,
	], dup_output, true)

	var sync_output := []
	var sync_exit := -1
	if dup_exit == 0:
		sync_exit = OS.execute(python_executable, [sync_py_abs, "--config", config_abs], sync_output, true)

	call_deferred("_on_worker_done", dup_exit, "\n".join(dup_output), sync_exit, "\n".join(sync_output))


func _on_worker_done(dup_exit: int, dup_output: String, sync_exit: int, sync_output: String) -> void:
	if _bake_thread:
		_bake_thread.wait_to_finish()
		_bake_thread = null
	_create_button.disabled = false

	print("PixelPipe (duplicate-recolor): duplicate_and_remap exited %d\n%s" % [dup_exit, dup_output])
	if dup_exit != 0:
		_set_status("Duplicate/remap FAILED (exit %d) -- nothing exported or imported. See Output panel." % dup_exit)
		return

	print("PixelPipe (duplicate-recolor): sync exited %d\n%s" % [sync_exit, sync_output])
	if sync_exit != 0:
		_set_status("Duplicates created, but export/sync FAILED (exit %d) -- run pixelpipe sync manually. See Output panel." % sync_exit)
		return

	# Best-effort: the freshly-exported PNGs won't have a .import file yet
	# (Godot only generates one after its own filesystem scan notices the
	# file), which build_scene() needs to load the sheet texture -- see
	# sprite_frames_importer.gd's own error message. A real EditorPlugin
	# dock (unlike D.1's standalone batch script) has EditorInterface
	# available and can request a scan directly, but this can't be verified
	# from this project's usual headless/--script test harness (confirmed:
	# EditorInterface isn't functional outside a live editor process) --
	# flagged as a real-editor-only check, same as several other pieces
	# this session. Guarded so a failure here degrades to the same "0
	# imported, told what to do" message instead of crashing.
	if Engine.is_editor_hint():
		var fs = EditorInterface.get_resource_filesystem()
		if fs:
			fs.scan()

	var imported := 0
	for entry in _pending_new_assets:
		var dest_res: String = entry["dest_res"]
		var json_path := dest_res.get_basename() + ".json"
		# json_path is still under art_source's layout; the exported JSON
		# lives under art_path instead, mirroring the same relative path.
		var art_json := _art_source_path_to_art_path(json_path)
		if art_json.is_empty() or not FileAccess.file_exists(art_json):
			push_warning("PixelPipe: expected export JSON not found for %s (looked at %s)" % [dest_res, art_json])
			continue
		var scene_root := SpriteFramesImporter.build_scene(art_json)
		if scene_root == null:
			continue
		var packed := PackedScene.new()
		packed.pack(scene_root)
		var out_path := art_json.get_basename() + ".tscn"
		if ResourceSaver.save(packed, out_path) == OK:
			imported += 1

	var created := _pending_new_assets.size()
	_pending_new_assets = []
	if imported < created:
		_set_status("Created %d duplicate(s) and exported them, but only built %d/%d SpriteFrames scene(s) -- the rest need a fresh PNG import (.import file) before this dock can read their texture. Do NOT click Create Duplicates again (that makes a new copy, not a retry) -- instead open addons/pixelpipe/import_sprite_frames.gd and run it (File > Run) once the FileSystem dock shows the new PNGs imported. See Output panel for which asset(s)." % [created, imported, created])
	else:
		_set_status("Created %d duplicate(s) and built %d SpriteFrames scene(s)." % [created, imported])
	_on_preview_pressed()  # refresh so the preview list doesn't show stale (now-collidable) names


func _art_source_path_to_art_path(art_source_json_res: String) -> String:
	var config := _load_config()
	var art_source_field: String = config.get("art_source_path", "")
	var art_field: String = config.get("art_path", "")
	if art_source_field.is_empty() or art_field.is_empty():
		return ""
	var art_source_root := config_path.get_base_dir().path_join(art_source_field)
	var art_root := config_path.get_base_dir().path_join(art_field)
	if not art_source_json_res.begins_with(art_source_root):
		return ""
	var rel := art_source_json_res.substr(art_source_root.length())
	return art_root + rel


func _color_to_rgb_array(color: Color) -> Array:
	return [roundi(color.r * 255.0), roundi(color.g * 255.0), roundi(color.b * 255.0)]


func _load_config() -> Dictionary:
	if not FileAccess.file_exists(config_path):
		return {}
	var file := FileAccess.open(config_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _set_status(text: String) -> void:
	_status_label.text = text
	print("PixelPipe (duplicate-recolor dock): %s" % text)
