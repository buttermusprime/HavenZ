## Headless alternative to import_sprite_frames.gd's File > Run workflow:
##
##   godot --headless --path <project> --script res://addons/pixelpipe/import_sprite_frames_headless.gd [-- --root=res://art]
##
## import_sprite_frames.gd extends EditorScript purely for File > Run
## convenience inside an already-open editor -- EditorScript itself has a
## hard restriction (confirmed against the real engine, D.1) that it cannot
## be run or instantiated outside a live interactive editor session, no CLI
## path at all. But PixelPipeSpriteFramesImporter's actual logic (building a
## SpriteFrames resource, an AnimatedSprite2D, Area2D slices, and saving the
## packed scene via ResourceSaver) is plain RefCounted/Resource work with no
## editor-only API calls anywhere in it -- confirmed for real (HavenZ's S2.5,
## 2026-08-29) by calling the exact same run_for_folder() from a plain
## SceneTree --script instead, with a real project's real synced art, not a
## synthetic fixture. It works identically, no editor process involved.
##
## Precondition unchanged from the EditorScript version: every sheet PNG
## still needs a .import file before load() can resolve it, which still
## requires one `godot --headless --editor --quit` pass after a fresh sync
## (see this repo's own README Troubleshooting section) -- that headless
## *editor* pass is a genuinely different thing from running an EditorScript,
## and is unaffected by this file's existence.
extends SceneTree

const SpriteFramesImporter = preload("res://addons/pixelpipe/sprite_frames_importer.gd")

const DEFAULT_ROOT := "res://art"


func _initialize() -> void:
	var root := DEFAULT_ROOT
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--root="):
			root = arg.substr(len("--root="))

	var count := SpriteFramesImporter.run_for_folder(root)
	print("PixelPipe: rebuilt %d SpriteFrames scene(s) under %s" % [count, root])
	quit(0)
