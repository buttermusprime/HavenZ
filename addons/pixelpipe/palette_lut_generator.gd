## Builds the LUT texture palette_unified.gdshader reads, and a small GIMP
## .gpl reader so the Godot side can load the same palette files the Python
## scripts (scripts/palette_io.py) already produce/consume.
@tool
class_name PixelPipeLutGenerator
extends RefCounted

## F.1: per-index glow-color link state lives here, not in the LUT texture
## itself -- a linked index's glow color is derived (mirrors the applied
## color) rather than independently authored, so it needs its own bit of
## state to distinguish "never touched, still tracking" from "explicitly
## set to the same color on purpose, no longer tracking." Keyed by the
## palette's ORIGINAL color (stable across LUT rebuilds and rebases),
## default true (linked) for any index not present in the file -- matches
## the spec's "glow color defaults to and live-tracks the applied color
## until explicitly overridden" behavior without needing to pre-populate
## every palette index up front.
const GLOW_LINK_STATE_PATH := "res://addons/pixelpipe/glow_link_state.json"


## Parses a GIMP .gpl file (the same format scripts/palette_io.py
## reads/writes: "GIMP Palette" header, optional Name:/Columns: lines, "#"
## comments, then "R G B name" rows) into an ordered PackedColorArray. Row
## order is preserved -- that order is the palette's canonical index order
## the LUT and the shader both key off of.
static func read_gpl(path: String) -> PackedColorArray:
	var colors := PackedColorArray()
	if not FileAccess.file_exists(path):
		push_error("PixelPipe: palette file not found: %s" % path)
		return colors

	var file := FileAccess.open(path, FileAccess.READ)
	var line_num := 0
	while not file.eof_reached():
		var line := file.get_line()
		line_num += 1
		if line_num == 1:
			continue  # "GIMP Palette" header, not validated -- read_palette_colors() on the Python side doesn't strictly validate it either.
		var trimmed := line.strip_edges()
		if trimmed.is_empty() or trimmed.begins_with("#") or trimmed.begins_with("Name:") or trimmed.begins_with("Columns:"):
			continue
		var parts := trimmed.split(" ", false)
		if parts.size() < 3:
			push_warning("PixelPipe: skipping malformed .gpl line %d in %s: '%s'" % [line_num, path, line])
			continue
		var r := parts[0].to_int()
		var g := parts[1].to_int()
		var b := parts[2].to_int()
		colors.append(Color(r / 255.0, g / 255.0, b / 255.0))
	return colors


## Builds the (N, 4) LUT image palette_unified.gdshader reads (F.1, merging
## D.2's remap LUT and D.5's glow LUT into one): row 0 = original palette
## color (match key), row 1 = applied/remap color, row 2 = glow color,
## row 3 = packed glow intensity (intensity/max_intensity in every channel,
## same packing convention D.5 used). All four arrays must be the same
## non-zero length. All rows are stored as raw sRGB bytes -- unlike D.5's
## old standalone glow LUT, nothing here is pre-converted to linear; the
## shader itself decides raw-vs-linear per pixel based on which
## interpretation of row 0 actually matched (see palette_unified.gdshader's
## header comment).
static func build_unified_lut_texture(original_colors: PackedColorArray, applied_colors: PackedColorArray, glow_colors: PackedColorArray, intensities: PackedFloat32Array, max_intensity: float) -> ImageTexture:
	var n := original_colors.size()
	if applied_colors.size() != n or glow_colors.size() != n or intensities.size() != n:
		push_error("PixelPipe: original (%d), applied (%d), glow (%d), and intensity (%d) arrays must all be the same length" % [n, applied_colors.size(), glow_colors.size(), intensities.size()])
		return null
	if n == 0:
		push_error("PixelPipe: cannot build a LUT texture from an empty palette")
		return null
	if max_intensity <= 0.0:
		push_error("PixelPipe: max_intensity must be positive (got %f)" % max_intensity)
		return null

	var image := Image.create(n, 4, false, Image.FORMAT_RGB8)
	for i in range(n):
		image.set_pixel(i, 0, original_colors[i])
		image.set_pixel(i, 1, applied_colors[i])
		image.set_pixel(i, 2, glow_colors[i])
		var packed := clampf(intensities[i] / max_intensity, 0.0, 1.0)
		image.set_pixel(i, 3, Color(packed, packed, packed))

	return ImageTexture.create_from_image(image)


## Reads a unified LUT texture (built by build_unified_lut_texture) back
## into its three per-index editable arrays -- the "rebuild from all
## currently-active state, not just the newest pick" pattern D.4 had to
## learn the hard way for D.2's dock, needed here so updating one dock's
## slice of the LUT (e.g. the glow dock changing one intensity) doesn't
## silently discard the other dock's already-applied colors. Falls back to
## an identity/no-op default (applied = original, glow = original,
## intensity 0) when current_lut is null or its dimensions don't match
## palette_colors -- the same "materialless/freshly-built" case D.2's dock
## already had to handle.
static func read_unified_lut(current_lut: Texture2D, palette_colors: PackedColorArray, max_intensity: float) -> Dictionary:
	var n := palette_colors.size()
	var applied := palette_colors.duplicate()
	var glow := palette_colors.duplicate()
	var intensities := PackedFloat32Array()
	intensities.resize(n)
	intensities.fill(0.0)

	if current_lut != null:
		var img := current_lut.get_image()
		if img.get_width() == n and img.get_height() == 4:
			for i in range(n):
				applied[i] = img.get_pixel(i, 1)
				glow[i] = img.get_pixel(i, 2)
				intensities[i] = img.get_pixel(i, 3).r * max_intensity

	return {"applied": applied, "glow": glow, "intensities": intensities}


## Reads the glow-color link-state JSON, defaulting to an empty map (every
## index absent = linked) when the file doesn't exist yet.
static func read_link_state(path: String = GLOW_LINK_STATE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	if text.strip_edges().is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("PixelPipe: %s does not contain a JSON object, refusing to touch it" % path)
		return {}
	return parsed


## True (linked) unless this exact original color has an explicit "false"
## entry -- absence means linked by default, per this spec's "defaults to
## AND live-tracks the applied color until explicitly overridden" rule.
static func is_glow_linked(original_color: Color, path: String = GLOW_LINK_STATE_PATH) -> bool:
	var state := read_link_state(path)
	var key := original_color.to_html(false)
	if not state.has(key):
		return true
	return bool(state[key])


static func set_glow_linked(original_color: Color, linked: bool, path: String = GLOW_LINK_STATE_PATH) -> void:
	var state := read_link_state(path)
	state[original_color.to_html(false)] = linked
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("PixelPipe: could not write %s (error %d)" % [path, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(state, "\t"))


