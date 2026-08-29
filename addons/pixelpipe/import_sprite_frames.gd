## Thin driver: run from the Godot editor (File > Run) to (re)build a
## SpriteFrames-backed scene for every exported Aseprite JSON under a folder.
## All real logic lives in PixelPipeSpriteFramesImporter.run_for_folder()
## (RefCounted, shared with import_sprite_frames_headless.gd below -- see that
## file for why a live editor isn't actually required for this anymore).
@tool
extends EditorScript

const SpriteFramesImporter = preload("res://addons/pixelpipe/sprite_frames_importer.gd")

const DEFAULT_ROOT := "res://art"


func _run() -> void:
	var count := SpriteFramesImporter.run_for_folder(DEFAULT_ROOT)
	print("PixelPipe: rebuilt %d SpriteFrames scene(s) under %s" % [count, DEFAULT_ROOT])
