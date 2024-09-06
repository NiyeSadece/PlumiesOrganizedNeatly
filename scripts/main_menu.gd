extends Control

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")

func _on_levels_pressed():
	get_tree().change_scene_to_file("res://scenes/level_selector.tscn")

func _on_exit_pressed():
	get_tree().quit()
