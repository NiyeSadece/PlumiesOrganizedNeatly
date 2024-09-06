extends Control

func _ready():
	for i in range(1, 34):
		var button_name = "Level %d" % i
		var button = get_node("GridContainer/%s" % button_name)
		button.connect("pressed", Callable(self, "_on_level_button_pressed").bind(i))


func _on_level_button_pressed(level_number: int):
	GameManager.load_level(level_number)


func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
