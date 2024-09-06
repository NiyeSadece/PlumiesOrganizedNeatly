extends Node

class_name GManager

var current_level: int = 1

func _ready():
	pass

func load_level(level_number: int):
	current_level = level_number
	var scene_path = "res://scenes/levels/level_%02d.tscn" % current_level
	var level_scene = load(scene_path)
	get_tree().change_scene_to_packed(level_scene)

func go_to_next_level():
	load_level(current_level + 1)
