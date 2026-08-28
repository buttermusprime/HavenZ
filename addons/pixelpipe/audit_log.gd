## F.2: a pure audit log of every applied-color/glow-color/glow-intensity/
## glow-link change, replacing D.4's previewing/marked_final bake-readiness
## ledger now that baking no longer exists as a concept in this tool (Build
## Guideline 07). Same checked-in file, addons/pixelpipe/live_remaps.json --
## its role changed, not its name -- but no state machine, no bake-
## eligibility semantics, nothing to gate. Append-only: every dock action
## that changes the shared material's LUT writes one entry here (old value
## -> new value, timestamped), purely for debugging/traceability/undo. No
## code anywhere reads this file to decide whether an action is allowed.
##
## Pure data logic, no Aseprite/node/UI dependency, so it's fully testable
## headlessly -- same shape as the ledger it replaces.
@tool
class_name PixelPipeAuditLog
extends RefCounted

const LOG_PATH := "res://addons/pixelpipe/live_remaps.json"

const FIELD_APPLIED_COLOR := "applied_color"
const FIELD_GLOW_COLOR := "glow_color"
const FIELD_GLOW_INTENSITY := "glow_intensity"
const FIELD_GLOW_LINK := "glow_link"


static func _read_json_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	if text.strip_edges().is_empty():
		return []
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("PixelPipe: %s does not contain a JSON array, refusing to touch it" % path)
		return []
	return parsed


static func _write_json_array(path: String, entries: Array) -> bool:
	var text := JSON.stringify(entries, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("PixelPipe: could not write %s (error %d)" % [path, FileAccess.get_open_error()])
		return false
	file.store_string(text)
	return true


static func read_log(path: String = LOG_PATH) -> Array:
	return _read_json_array(path)


## Appends one audit entry. field is one of the FIELD_* constants above.
## original_color identifies WHICH palette index changed (the stable match
## key, same identity LutGen keys glow-link state off of) -- old_value/
## new_value are the field's own before/after values, already stringified
## by the caller (a color's `to_html(false)`, an intensity's `str()`, a
## link flag's `str()`) so this function stays field-type-agnostic. scope
## currently only ever has the one real shape this project has actually
## built: {"type": "project", "path": "res://"} (the single shared
## material) -- see docs/LESSONS.md for why folder/material/scene-scoped
## entries aren't implemented yet despite being a documented possibility.
static func record_change(field: String, original_color: Color, old_value: String, new_value: String, scope: Dictionary, path: String = LOG_PATH) -> Dictionary:
	var entries := read_log(path)
	var entry := {
		"id": "change_%d_%04d" % [Time.get_unix_time_from_system(), randi() % 10000],
		"field": field,
		"original_color": original_color.to_html(false),
		"old_value": old_value,
		"new_value": new_value,
		"scope": scope,
		"timestamp": Time.get_datetime_string_from_system(true),
	}
	entries.append(entry)
	_write_json_array(path, entries)
	return entry
