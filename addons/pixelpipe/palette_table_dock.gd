## F.3: replaces D.2's and D.5's separate two-picker docks with one dock --
## one row per active palette color, four editable-ish columns (original is
## read-only): applied color, glow color, glow intensity, plus a glow-link
## indicator/re-link action. Every cell edit updates the shared material's
## LUT immediately (F.1's palette_unified.gdshader) and writes one entry to
## the audit log (F.2's audit_log.gd) -- no Apply button, no ledger, no bake.
##
## Copy/Paste is a single pair of toolbar buttons operating on one "active
## slot," not a Copy/Paste pair per cell -- clicking any Original, Applied,
## or Glow Color cell marks that row+column as active, shown with a
## highlighted border around the cell and a status label naming it. The
## toolbar buttons always act on whatever's currently active. A row that's
## momentarily hidden by the "Show only modified rows" filter can still be
## the active slot -- Copy/Paste read/write the dock's own in-memory arrays
## (_palette/_applied/_glow), not the widget, so this works even when that
## row isn't currently built.
##
## Original is selectable/copyable but never itself editable -- it's the
## shader's fixed match key for that palette index (palette_unified.gdshader
## looks pixels up against it; changing it would desync the LUT from actual
## pixel data). Pasting while Original is the active slot is a shortcut for
## "set this row's Applied color" (the color that overwrites Original) --
## see _paste_active().
##
## Commit timing: a ColorPickerButton's `color_changed` signal fires
## continuously while dragging a slider inside the popup (potentially
## dozens of times for one logical color pick) -- committing on every tick
## would spam the audit log and re-save the material dozens of times for a
## single user action. Committed on `popup_closed` instead, comparing
## against the color this dock already had for that cell -- one audit entry
## per actual pick, matching "on any cell edit" at the level a human means
## it, not at the level the signal fires it.
##
## Usability plan for a full palette (up to 256 rows, B.3's quantization
## cap), resolved as part of this session per the roadmap's own open
## question: a scrollable flat table (every row always exists, real and
## simple) plus a "Show only modified rows" filter checkbox to keep a large,
## mostly-identity palette usable without needing virtualized scrolling --
## a dev tool doesn't need more than that.
@tool
extends Control

const LutGen = preload("res://addons/pixelpipe/palette_lut_generator.gd")
const AuditLog = preload("res://addons/pixelpipe/audit_log.gd")
const SHARED_MATERIAL_PATH := "res://addons/pixelpipe/shared_palette_material.tres"
const MAX_INTENSITY := 4.0

enum SlotKind { ORIGINAL, APPLIED, GLOW }
const SLOT_KIND_NAMES := {SlotKind.ORIGINAL: "Original", SlotKind.APPLIED: "Applied", SlotKind.GLOW: "Glow"}
const HEADER_COLUMN_COUNT := 5  ## Original / Applied / Glow Color / Glow Link / Glow Intensity -- the first 5 children of _rows_grid, see _build_ui().

## Points at HavenZ's own config, repointed from PixelPipe's test-fixtures
## default -- see PixelPipe's docs/LESSONS.md for why this isn't auto-discovered.
@export var config_path := "res://pixelpipe.config.json"

var _palette: PackedColorArray = PackedColorArray()
var _applied: PackedColorArray = PackedColorArray()
var _glow: PackedColorArray = PackedColorArray()
var _intensities: PackedFloat32Array = PackedFloat32Array()
var _rows: Array = []

var _status_label: Label
var _rows_grid: GridContainer
var _filter_checkbox: CheckBox
var _active_label: Label

## -1 = no slot selected yet. Identifies a logical (row, column) pair, not
## a widget -- stays valid across a _rebuild_rows() (filter toggle, reload)
## even though the actual Control for that cell gets freed and recreated.
var _active_index := -1
var _active_kind: int = SlotKind.APPLIED


func _ready() -> void:
	_build_ui()
	_reload_palette()


func _build_ui() -> void:
	custom_minimum_size = Vector2(420, 0)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(root)

	var title := Label.new()
	title.text = "PixelPipe — Palette"
	root.add_child(title)

	var toolbar := HBoxContainer.new()
	root.add_child(toolbar)

	var reload_button := Button.new()
	reload_button.text = "Reload Palette"
	reload_button.pressed.connect(_reload_palette)
	toolbar.add_child(reload_button)

	_filter_checkbox = CheckBox.new()
	_filter_checkbox.text = "Show only modified rows"
	_filter_checkbox.toggled.connect(func(_pressed: bool): _rebuild_rows())
	toolbar.add_child(_filter_checkbox)

	var clipboard_bar := HBoxContainer.new()
	root.add_child(clipboard_bar)

	var copy_button := Button.new()
	copy_button.text = "Copy"
	copy_button.tooltip_text = "Copy the active color slot to the clipboard."
	# Without this, HBoxContainer stretches every child to match the
	# tallest sibling -- if the active-slot label next to it ever needs two
	# lines, these buttons would silently stretch to match instead of
	# staying a normal button height.
	copy_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	copy_button.pressed.connect(_copy_active)
	clipboard_bar.add_child(copy_button)

	var paste_button := Button.new()
	paste_button.text = "Paste"
	paste_button.tooltip_text = "Paste the clipboard's hex color into the active color slot."
	paste_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	paste_button.pressed.connect(_paste_active)
	clipboard_bar.add_child(paste_button)

	_active_label = Label.new()
	_active_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_active_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_active_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clipboard_bar.add_child(_active_label)
	_update_active_label()

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 240)
	root.add_child(scroll)

	# Header labels are the first HEADER_COLUMN_COUNT children of this SAME
	# GridContainer, not a separate one -- two independent GridContainers
	# never share column widths in Godot, so a header row built separately
	# drifts out of alignment the moment any data cell (the SpinBox's
	# arrows, the "Linked" pill) is wider than its header label.
	_rows_grid = GridContainer.new()
	_rows_grid.columns = HEADER_COLUMN_COUNT
	scroll.add_child(_rows_grid)

	var header_tooltips := {
		"Original": "The exact pixel color this row matches -- fixed, never editable.",
		"Applied": "The color that replaces Original at render time.",
		"Glow Color": "The HDR-emissive color added on top of Applied (additive, see Glow Intensity). Independent of Applied unless linked.",
		"Glow Link": "Linked: Glow Color automatically follows Applied Color. \"Re-link\": an explicit Glow Color edit broke that link -- click to resume following Applied.",
		"Glow Intensity": "0 = not emissive. Needs an HDR 2D viewport + WorldEnvironment Glow + BG_CANVAS to actually bloom.",
	}
	for text in ["Original", "Applied", "Glow Color", "Glow Link", "Glow Intensity"]:
		var label := Label.new()
		label.text = text
		label.tooltip_text = header_tooltips[text]
		_rows_grid.add_child(label)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(_status_label)


func _reload_palette() -> void:
	var config := _load_config()
	if config.is_empty():
		_set_status("Could not read config at %s" % config_path)
		return

	var palette_field: String = config.get("palette_path", "")
	if palette_field.is_empty():
		_set_status("Config has no palette_path")
		return

	var palette_path := config_path.get_base_dir().path_join(palette_field)
	_palette = LutGen.read_gpl(palette_path)

	var mat := _load_shared_material()
	var current_lut: Texture2D = mat.get_shader_parameter("lut_texture") if mat != null else null
	var state := LutGen.read_unified_lut(current_lut, _palette, MAX_INTENSITY)
	_applied = state["applied"]
	_glow = state["glow"]
	_intensities = state["intensities"]

	_rebuild_rows()

	if _palette.is_empty():
		_set_status("No colors loaded from %s" % palette_path)
	else:
		_set_status("Loaded %d color(s) from %s." % [_palette.size(), palette_path])


func _rebuild_rows() -> void:
	# Skip the first HEADER_COLUMN_COUNT children -- those are the header
	# labels, which live in this same GridContainer (see _build_ui()) and
	# must never be freed here.
	var children := _rows_grid.get_children()
	for i in range(HEADER_COLUMN_COUNT, children.size()):
		children[i].queue_free()
	_rows.clear()
	_rows.resize(_palette.size())

	var shown := 0
	for i in range(_palette.size()):
		if _filter_checkbox.button_pressed and not _is_modified(i):
			continue
		_build_row(i)
		shown += 1

	if shown == 0:
		var empty := Label.new()
		empty.text = "(no modified colors)" if _filter_checkbox.button_pressed else "(no palette loaded)"
		_rows_grid.add_child(empty)


func _is_modified(index: int) -> bool:
	if not _applied[index].is_equal_approx(_palette[index]):
		return true
	if _intensities[index] > 0.0:
		return true
	if not LutGen.is_glow_linked(_palette[index]):
		return true
	return false


func _build_row(index: int) -> void:
	var original := _palette[index]

	var original_button := _make_original_button(index, original)
	_rows_grid.add_child(original_button)

	var applied_picker := ColorPickerButton.new()
	applied_picker.color = _applied[index]
	# Left at width 0 (auto), ColorPickerButton collapses to a
	# near-invisible sliver in a GridContainer column -- match the Original
	# column's size exactly so the swatch is actually visible.
	applied_picker.custom_minimum_size = Vector2(60, 24)
	applied_picker.pressed.connect(func(): _set_active_slot(index, SlotKind.APPLIED))
	applied_picker.popup_closed.connect(func(): _commit_applied_color(index, applied_picker.color))
	var applied_container := _make_slot_container(applied_picker)
	_rows_grid.add_child(applied_container)

	var glow_picker := ColorPickerButton.new()
	glow_picker.color = _glow[index]
	glow_picker.custom_minimum_size = Vector2(60, 24)
	glow_picker.pressed.connect(func(): _set_active_slot(index, SlotKind.GLOW))
	glow_picker.popup_closed.connect(func(): _commit_glow_color(index, glow_picker.color))
	var glow_container := _make_slot_container(glow_picker)
	_rows_grid.add_child(glow_container)

	var link_button := Button.new()
	link_button.pressed.connect(_on_relink_pressed.bind(index))
	_rows_grid.add_child(link_button)

	var intensity_spin := SpinBox.new()
	intensity_spin.min_value = 0.0
	intensity_spin.max_value = MAX_INTENSITY
	intensity_spin.step = 0.1
	intensity_spin.value = _intensities[index]
	intensity_spin.value_changed.connect(func(v: float): _commit_intensity(index, v))
	_rows_grid.add_child(intensity_spin)

	_rows[index] = {
		"original_button": original_button,
		"applied_picker": applied_picker,
		"applied_container": applied_container,
		"glow_picker": glow_picker,
		"glow_container": glow_container,
		"link_button": link_button,
		"intensity_spin": intensity_spin,
	}
	_update_link_indicator(index)

	# Rebuilt rows (filter toggle, reload) get fresh Controls -- re-apply the
	# active-slot highlight if this row+column is the one currently active.
	if index == _active_index:
		_apply_slot_highlight(index, _active_kind, true)


## Original is selectable/copyable (see the header comment on why it's
## never itself editable) -- a plain Button rather than a PanelContainer+
## Label so it gets click detection for free, same `pressed` signal pattern
## as the Applied/Glow pickers.
func _make_original_button(index: int, color: Color) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(60, 24)
	btn.tooltip_text = color.to_html(false)
	btn.text = color.to_html(false)
	btn.pressed.connect(func(): _set_active_slot(index, SlotKind.ORIGINAL))
	_style_swatch_button(btn, color, false)
	return btn


## A swatch button's "color" and its active-slot highlight both live in the
## same StyleBoxFlat (a Button only has one stylebox per state), so
## re-highlighting means rebuilding the whole style, background included --
## unlike Applied/Glow's picker, which keeps its own color and only needs a
## separate wrapper container's border touched.
func _style_swatch_button(btn: Button, color: Color, active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_border_width_all(2)
	style.border_color = Color(0.16, 0.55, 0.5) if active else Color(0, 0, 0, 0)
	style.set_corner_radius_all(4)
	for state in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(state, style)


## Wraps a color-picker cell in a PanelContainer used purely as an
## active-slot highlight border (see _style_slot_container) -- starts
## unhighlighted; _build_row re-applies the highlight after a rebuild if
## this cell happens to be the currently active one.
func _make_slot_container(picker: ColorPickerButton) -> PanelContainer:
	var container := PanelContainer.new()
	container.custom_minimum_size = picker.custom_minimum_size
	container.add_child(picker)
	_style_slot_container(container, false)
	return container


func _style_slot_container(container: PanelContainer, active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_border_width_all(2)
	style.border_color = Color(0.16, 0.55, 0.5) if active else Color(0, 0, 0, 0)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(2)
	container.add_theme_stylebox_override("panel", style)


## Marks one row's Original, Applied, or Glow Color cell as the "active
## slot" the toolbar's Copy/Paste buttons act on -- called when any of the
## three is clicked. Un-highlights whatever was active before (if that row
## is still built; a filter toggle may have freed it, which is fine,
## there's nothing to un-highlight).
func _set_active_slot(index: int, kind: int) -> void:
	if _active_index >= 0 and _active_index < _rows.size() and _rows[_active_index] != null:
		_apply_slot_highlight(_active_index, _active_kind, false)

	_active_index = index
	_active_kind = kind

	if index < _rows.size() and _rows[index] != null:
		_apply_slot_highlight(index, kind, true)

	_update_active_label()


func _apply_slot_highlight(index: int, kind: int, active: bool) -> void:
	var row: Dictionary = _rows[index]
	match kind:
		SlotKind.ORIGINAL:
			var btn: Button = row.get("original_button")
			if btn:
				_style_swatch_button(btn, _palette[index], active)
		SlotKind.GLOW:
			var container: PanelContainer = row.get("glow_container")
			if container:
				_style_slot_container(container, active)
		_:
			var container: PanelContainer = row.get("applied_container")
			if container:
				_style_slot_container(container, active)


func _update_active_label() -> void:
	if _active_index < 0 or _active_index >= _palette.size():
		_active_label.text = "Active: (none — click a color to select)"
		return
	_active_label.text = "Active: %s · #%s" % [SLOT_KIND_NAMES[_active_kind], _palette[_active_index].to_html(false)]


## Copies the active slot's CURRENT color -- read from the dock's own
## in-memory arrays (the source of truth this dock already maintains, and
## for Original the only place it's ever stored), not the widget, so this
## still works if that row is momentarily hidden by the "Show only
## modified rows" filter.
func _copy_active() -> void:
	if _active_index < 0:
		_set_status("No color slot selected -- click a color swatch first.")
		return
	var color: Color
	match _active_kind:
		SlotKind.ORIGINAL:
			color = _palette[_active_index]
		SlotKind.GLOW:
			color = _glow[_active_index]
		_:
			color = _applied[_active_index]
	DisplayServer.clipboard_set(color.to_html(false))
	_set_status("Copied #%s from %s · #%s." % [color.to_html(false), SLOT_KIND_NAMES[_active_kind], _palette[_active_index].to_html(false)])


## Pastes the clipboard's hex color into the active slot -- same OS
## clipboard (DisplayServer.clipboard_set/get, plain hex via
## Color.to_html(false)/Color.html()) as before, just routed through
## whichever cell is currently active instead of a per-cell button. Pasting
## into a Glow Color slot unlinks that index, same as any other explicit
## glow-color edit. Pasting while Original is active writes into Applied
## instead -- Original can never be overwritten (see the header comment),
## so "paste to Original" means "set the color that overwrites it."
func _paste_active() -> void:
	if _active_index < 0:
		_set_status("No color slot selected -- click a color swatch first.")
		return
	var text := DisplayServer.clipboard_get()
	if not Color.html_is_valid(text):
		_set_status("Clipboard has no valid hex color ('%s')" % text)
		return
	var color := Color.html(text)

	var effective_kind: int = SlotKind.APPLIED if _active_kind == SlotKind.ORIGINAL else _active_kind

	if _active_index < _rows.size() and _rows[_active_index] != null:
		var key := "glow_picker" if effective_kind == SlotKind.GLOW else "applied_picker"
		_rows[_active_index][key].color = color

	if effective_kind == SlotKind.GLOW:
		_commit_glow_color(_active_index, color)
	else:
		_commit_applied_color(_active_index, color)


func _update_link_indicator(index: int) -> void:
	var btn: Button = _rows[index]["link_button"]
	if LutGen.is_glow_linked(_palette[index]):
		btn.text = "Linked"
		btn.disabled = true
		btn.tooltip_text = "Glow Color automatically matches Applied Color. Edit Glow Color directly to give this row its own independent glow hue."
	else:
		btn.text = "Re-link"
		btn.disabled = false
		btn.tooltip_text = "Glow Color has its own independent value (an explicit edit broke the link). Click to make it follow Applied Color again."


## Applying a new color at index cascades into that index's glow color IF
## still linked (LutGen.is_glow_linked) -- an unlinked index's independent
## glow color is left untouched, per F.1's spec.
func _commit_applied_color(index: int, new_color: Color) -> void:
	var old_color := _applied[index]
	if old_color.is_equal_approx(new_color):
		return

	_applied[index] = new_color
	var cascaded := false
	if LutGen.is_glow_linked(_palette[index]):
		_glow[index] = new_color
		cascaded = true
		# Guarded: this index's row might not be currently built (e.g. the
		# "Show only modified rows" filter hid it before a toolbar Paste
		# committed here) -- the in-memory _glow array above is always the
		# source of truth regardless; only the live widget update is
		# conditional.
		if index < _rows.size() and _rows[index] != null:
			_rows[index]["glow_picker"].color = new_color

	if not _save_material():
		return

	var scope := {"type": "project", "path": "res://"}
	AuditLog.record_change(AuditLog.FIELD_APPLIED_COLOR, _palette[index], old_color.to_html(false), new_color.to_html(false), scope)
	_set_status("Applied #%s -> %s%s" % [_palette[index].to_html(false), new_color.to_html(false), " (glow cascaded, still linked)" if cascaded else ""])


## An explicit glow-color edit (or paste) always unlinks that index, per
## F.1's spec -- even if the newly-picked color happens to match the
## applied color exactly, this is a deliberate user action, not a passive
## default, so it unlinks anyway.
func _commit_glow_color(index: int, new_color: Color) -> void:
	var old_color := _glow[index]
	var was_linked := LutGen.is_glow_linked(_palette[index])
	if old_color.is_equal_approx(new_color) and not was_linked:
		return

	_glow[index] = new_color
	if not _save_material():
		return

	var scope := {"type": "project", "path": "res://"}
	AuditLog.record_change(AuditLog.FIELD_GLOW_COLOR, _palette[index], old_color.to_html(false), new_color.to_html(false), scope)

	if was_linked:
		LutGen.set_glow_linked(_palette[index], false)
		AuditLog.record_change(AuditLog.FIELD_GLOW_LINK, _palette[index], "true", "false", scope)
		_update_link_indicator(index)

	_set_status("Glow color #%s -> %s (unlinked)" % [_palette[index].to_html(false), new_color.to_html(false)])


func _commit_intensity(index: int, new_value: float) -> void:
	var old_value := _intensities[index]
	if is_equal_approx(old_value, new_value):
		return

	_intensities[index] = new_value
	if not _save_material():
		return

	var scope := {"type": "project", "path": "res://"}
	AuditLog.record_change(AuditLog.FIELD_GLOW_INTENSITY, _palette[index], str(old_value), str(new_value), scope)
	_set_status("Glow intensity #%s -> %.2f" % [_palette[index].to_html(false), new_value])


func _on_relink_pressed(index: int) -> void:
	if LutGen.is_glow_linked(_palette[index]):
		return

	var old_glow := _glow[index]
	_glow[index] = _applied[index]
	_rows[index]["glow_picker"].color = _applied[index]

	if not _save_material():
		return

	LutGen.set_glow_linked(_palette[index], true)
	var scope := {"type": "project", "path": "res://"}
	if not old_glow.is_equal_approx(_applied[index]):
		AuditLog.record_change(AuditLog.FIELD_GLOW_COLOR, _palette[index], old_glow.to_html(false), _applied[index].to_html(false), scope)
	AuditLog.record_change(AuditLog.FIELD_GLOW_LINK, _palette[index], "false", "true", scope)

	_update_link_indicator(index)
	_set_status("Re-linked glow color for #%s" % _palette[index].to_html(false))


func _save_material() -> bool:
	var mat := _load_shared_material()
	if mat == null:
		_set_status("Could not load shared palette material at %s" % SHARED_MATERIAL_PATH)
		return false

	var lut := LutGen.build_unified_lut_texture(_palette, _applied, _glow, _intensities, MAX_INTENSITY)
	if lut == null:
		_set_status("Failed to build the shared material's LUT -- see Output panel.")
		return false

	mat.set_shader_parameter("lut_texture", lut)
	mat.set_shader_parameter("palette_size", _palette.size())
	mat.set_shader_parameter("max_intensity", MAX_INTENSITY)
	if ResourceSaver.save(mat, SHARED_MATERIAL_PATH) != OK:
		_set_status("Applied live, but failed to save the material to disk.")
		return false
	return true


func _load_config() -> Dictionary:
	if not FileAccess.file_exists(config_path):
		return {}
	var file := FileAccess.open(config_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _load_shared_material() -> ShaderMaterial:
	if not ResourceLoader.exists(SHARED_MATERIAL_PATH):
		return null
	return load(SHARED_MATERIAL_PATH)


func _set_status(text: String) -> void:
	_status_label.text = text
	print("PixelPipe (palette table dock): %s" % text)
