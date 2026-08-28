@tool
extends EditorPlugin

const PaletteTableDockScript = preload("res://addons/pixelpipe/palette_table_dock.gd")
const DuplicateRecolorDockScript = preload("res://addons/pixelpipe/duplicate_recolor_dock.gd")

var _palette_table_dock: Control
var _duplicate_recolor_dock: Control


func _enter_tree() -> void:
	_palette_table_dock = PaletteTableDockScript.new()
	_palette_table_dock.name = "PixelPipe Palette"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _palette_table_dock)

	_duplicate_recolor_dock = DuplicateRecolorDockScript.new()
	_duplicate_recolor_dock.name = "PixelPipe Duplicate"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _duplicate_recolor_dock)


func _exit_tree() -> void:
	if _palette_table_dock:
		remove_control_from_docks(_palette_table_dock)
		_palette_table_dock.queue_free()
		_palette_table_dock = null
	if _duplicate_recolor_dock:
		remove_control_from_docks(_duplicate_recolor_dock)
		_duplicate_recolor_dock.queue_free()
		_duplicate_recolor_dock = null
