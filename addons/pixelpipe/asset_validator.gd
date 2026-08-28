## Dimension/import-preset/palette-compliance checks for exported PNGs. Pure
## logic, no EditorScript/UI dependency, so it's testable headlessly -- the
## runnable driver is validate_assets.gd (File > Run), same split as
## palette_lut_generator.gd vs. the dock scripts that call it.
##
## F.2: the ship-readiness check against D.4's live-remap ledger is gone --
## baking no longer exists as a concept in this tool (Build Guideline 07),
## so there's nothing left to be "un-baked" and therefore nothing to block
## shipping on.
@tool
class_name PixelPipeAssetValidator
extends RefCounted

const LutGen = preload("res://addons/pixelpipe/palette_lut_generator.gd")

## Godot 4's Texture importer CompressMode enum: 0=Lossless, 3=VRAM
## Uncompressed -- both avoid the lossy-compression artifacts on hard pixel
## edges PIXEL_ART_GUIDELINES.md #2 calls out.
const COMPLIANT_COMPRESS_MODES := [0, 3]


## Recursively finds every *.png under root using ResourceLoader.list_directory,
## not DirAccess -- PNG is a recognized/importable extension (unlike the
## .aseprite fixture-scanning case D.4's dock had to use DirAccess for, see
## GODOT_LESSONS.md #5a), and D.3's own roadmap prompt calls this out
## explicitly.
static func find_png_files(root: String) -> Array[String]:
	var results: Array[String] = []
	for entry in ResourceLoader.list_directory(root):
		if entry.ends_with("/"):
			results.append_array(find_png_files(root.path_join(entry)))
		elif entry.get_extension().to_lower() == "png":
			results.append(root.path_join(entry))
	return results


## Checks one exported PNG's dimensions, import preset, and palette
## compliance. palette_lookup is a Dictionary keyed by Color.to_html(false)
## hex strings (build once per folder run, not per file). Returns a list of
## human-readable issue strings; empty means fully compliant.
static func validate_png(png_path: String, palette_lookup: Dictionary, pixel_scale: int) -> Array[String]:
	var issues: Array[String] = []

	# Image.load() prints a "will not work on export" engine warning -- expected
	# and harmless here: this validator only ever runs in-editor (File > Run)
	# against exported source-tree PNGs, never inside a shipped build.
	var image := Image.new()
	var load_err := image.load(png_path)
	if load_err != OK:
		issues.append("could not load PNG (error %d)" % load_err)
		return issues

	var w := image.get_width()
	var h := image.get_height()
	if pixel_scale > 0 and (w % pixel_scale != 0 or h % pixel_scale != 0):
		issues.append("dimensions %dx%d are not a clean multiple of pixel_scale=%d" % [w, h, pixel_scale])

	var import_path := png_path + ".import"
	if not FileAccess.file_exists(import_path):
		issues.append("no .import file yet -- needs an editor filesystem scan/re-import (see GODOT_LESSONS.md #5)")
	else:
		var cfg := ConfigFile.new()
		var cfg_err := cfg.load(import_path)
		if cfg_err != OK:
			issues.append("could not read .import file (error %d)" % cfg_err)
		else:
			var mipmaps_on: bool = cfg.get_value("params", "mipmaps/generate", false)
			if mipmaps_on:
				issues.append("mipmaps/generate is true, expected false (no-mipmap preset)")
			var compress_mode: int = cfg.get_value("params", "compress/mode", -1)
			if not COMPLIANT_COMPRESS_MODES.has(compress_mode):
				issues.append("compress/mode=%d, expected Lossless(0) or VRAM Uncompressed(3)" % compress_mode)

	# Palette compliance -- skip fully-transparent pixels. Exact-hex match:
	# both the palette (built from 8-bit .gpl rows) and these pixels (8-bit
	# PNG samples) are the same quantization, so no nearest-match guessing is
	# needed or wanted (see docs/LESSONS.md's C.6 "no silent nearest-match"
	# convention, applied here too).
	if not palette_lookup.is_empty():
		var offenders := {}
		for y in range(h):
			for x in range(w):
				var px := image.get_pixel(x, y)
				if px.a == 0.0:
					continue
				var key := px.to_html(false)
				if not palette_lookup.has(key):
					offenders[key] = offenders.get(key, 0) + 1
		if not offenders.is_empty():
			var parts: Array[String] = []
			for key in offenders:
				parts.append("#%s (%d px)" % [key, offenders[key]])
			issues.append("off-palette color(s): %s" % ", ".join(parts))

	return issues


## Runs validate_png over every PNG under art_root. Returns {png_path:
## Array[String]} entries only for files with at least one issue.
static func validate_folder(art_root: String, palette_colors: PackedColorArray, pixel_scale: int) -> Dictionary:
	var palette_lookup := {}
	for c in palette_colors:
		palette_lookup[c.to_html(false)] = true

	var report := {}
	for png_path in find_png_files(art_root):
		var issues := validate_png(png_path, palette_lookup, pixel_scale)
		if not issues.is_empty():
			report[png_path] = issues
	return report


## Project-wide default-filter check. Godot 4's texture importer carries no
## per-file filter/flags key at all (confirmed empirically against a real
## exported .import file -- Godot 3 had flags/filter, Godot 4 moved texture
## filtering to a runtime CanvasItem property with this project setting as
## its default), so "Nearest filter" is only checkable here, once, not
## per-PNG. Returns an empty string when compliant.
static func check_default_filter() -> String:
	var mode: int = ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter", 0)
	if mode != 0:
		return "rendering/textures/canvas_textures/default_texture_filter=%d, expected 0 (Nearest)" % mode
	return ""


## Dimension/import-preset/palette-compliance mode against config_path,
## printing results as it goes. Returns true only if everything passed. This
## is the whole implementation behind validate_assets.gd's File > Run entry
## point -- kept here on a RefCounted class (not the EditorScript itself) so
## it's testable headlessly by direct instantiation/static call, same split
## D.1 already established (sprite_frames_importer.gd vs.
## import_sprite_frames.gd) after confirming EditorScript "can only be
## instantiated by editor" -- no CLI/headless path can `.new()` one
## (GODOT_LESSONS.md #13a).
static func run_asset_validation(config_path: String) -> bool:
	var config := _load_config(config_path)
	if config.is_empty():
		push_error("PixelPipe: could not read config at %s" % config_path)
		return false

	var art_field: String = config.get("art_path", "")
	var palette_field: String = config.get("palette_path", "")
	var pixel_scale: int = config.get("pixel_scale", 0)
	if art_field.is_empty() or palette_field.is_empty() or pixel_scale <= 0:
		push_error("PixelPipe: config missing art_path/palette_path/pixel_scale")
		return false

	var art_root := config_path.get_base_dir().path_join(art_field)
	var palette_path := config_path.get_base_dir().path_join(palette_field)
	var palette_colors := LutGen.read_gpl(palette_path)

	print("--- PixelPipe asset validation: %s (pixel_scale=%d, palette=%d color(s)) ---" % [art_root, pixel_scale, palette_colors.size()])

	var filter_issue := check_default_filter()
	if not filter_issue.is_empty():
		print("  [project setting] %s" % filter_issue)

	var report := validate_folder(art_root, palette_colors, pixel_scale)
	for png_path in report:
		print("  %s:" % png_path)
		for issue in report[png_path]:
			print("    - %s" % issue)

	var ok := report.is_empty() and filter_issue.is_empty()
	if ok:
		print("  all PNG(s) compliant.")
	return ok


static func _load_config(config_path: String) -> Dictionary:
	if not FileAccess.file_exists(config_path):
		return {}
	var file := FileAccess.open(config_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
