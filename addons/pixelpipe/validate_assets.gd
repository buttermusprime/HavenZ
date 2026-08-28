## Runnable checkpoint (File > Run in the Godot editor) that validates every
## exported PNG under a project's art_path against dimensions/import-preset/
## palette-compliance. Read-only end to end. All real logic lives in
## asset_validator.gd (RefCounted, headlessly testable) -- this file only
## exists as the File > Run entry point, same thin-driver split as D.1's
## import_sprite_frames.gd.
##
## F.2: no longer also checks ship-readiness against a bake ledger --
## baking no longer exists as a concept in this tool (Build Guideline 07).
@tool
extends EditorScript

const AssetValidator = preload("res://addons/pixelpipe/asset_validator.gd")

const DEFAULT_CONFIG_PATH := "res://pixelpipe.config.json"


func _run() -> void:
	var ok := AssetValidator.run_asset_validation(DEFAULT_CONFIG_PATH)
	if ok:
		print("PixelPipe: validation PASSED -- clean to ship.")
	else:
		print("PixelPipe: validation FAILED -- see issues above.")
