extends Control

@onready var slot_scene = preload("res://scenes/slot.tscn")
@onready var empty_slot = preload("res://scenes/empty_slot.tscn")
@onready var grid_container = $TextureRect2/TextureRect/GridContainer
@onready var item_scene = preload("res://scenes/item.tscn")
@onready var col_count = grid_container.columns

var grid_array := []
var item_held = null
var current_slot = null
var can_place := false
var icon_anchor : Vector2

# List of predefined shapes to spawn
var shape_list = [7, 7, 11, 9, 16, 16, 17]  # Replace with your shape identifiers
var shape_index = 0  # Track the current index of the shape to spawn
var empty_spots = [0, 1, 6, 10, 17, 24, 27, 31, 38, 41, 42, 45, 48]

# Called when the node enters the scene tree for the first time.
func _ready():
	# Create slots
	for i in range(49):
		if i in empty_spots:
			create_empty_slot()
		else:
			create_slot()
	
	var item_spawn_positions := [
		Vector2(1500, 300),
		Vector2(500, 300),
		Vector2(1500, 600),
		Vector2(500, 600),
		Vector2(1500, 800),
		Vector2(500, 800),
		Vector2(1700, 300),
	]
	
	for i in shape_list:
		var new_item = item_scene.instantiate()
		add_child(new_item)
		new_item.load_item(i)  # Load different items based on the index
		new_item.position = item_spawn_positions[shape_index]  # Set their position outside the grid
		shape_index += 1
		new_item.selected = false



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if item_held:
		if Input.is_action_just_pressed("mouse_rightclick"):
			rotate_item()
		if Input.is_action_just_pressed("mouse_leftclick"):
			place_item()
	else:
		if Input.is_action_just_pressed("mouse_leftclick"):
			pick_item()

func create_slot():
	var new_slot = slot_scene.instantiate()
	new_slot.slot_ID = grid_array.size()
	grid_container.add_child(new_slot)
	grid_array.push_back(new_slot)
	new_slot.slot_entered.connect(_on_slot_mouse_entered)
	new_slot.slot_exited.connect(_on_slot_mouse_exited)

func create_empty_slot():
	var new_slot = empty_slot.instantiate()
	new_slot.slot_ID = grid_array.size()
	grid_container.add_child(new_slot)
	grid_array.push_back(new_slot)

func _on_slot_mouse_entered(a_Slot):
	icon_anchor = Vector2(1000, 1000)
	current_slot = a_Slot
	if item_held:
		check_slot_availability(current_slot)
		set_grids.call_deferred(current_slot)

func _on_slot_mouse_exited(a_Slot):
	clear_grid()

func check_slot_availability(a_Slot):
	for grid in item_held.item_grids:
		var grid_to_check = a_Slot.slot_ID + grid[0] + grid[1] * col_count
		var line_switch_check = a_Slot.slot_ID % col_count + grid[0]
		if line_switch_check < 0 or line_switch_check >= col_count:
			can_place = false
			return
		if grid_to_check < 0 or grid_to_check >= grid_array.size():
			can_place = false
			return
		if grid_array[grid_to_check].state == grid_array[grid_to_check].States.TAKEN:
			can_place = false
			return
		if grid_array[grid_to_check].state == grid_array[grid_to_check].States.OBSTACLE:
			can_place = false
			return
	can_place = true

func set_grids(a_Slot):
	for grid in item_held.item_grids:
		var grid_to_check = a_Slot.slot_ID + grid[0] + grid[1] * col_count
		var line_switch_check = a_Slot.slot_ID % col_count + grid[0]
		if grid_to_check < 0 or grid_to_check >= grid_array.size():
			continue
		if line_switch_check < 0 or line_switch_check >= col_count:
			continue
		if can_place:
			grid_array[grid_to_check].set_color(grid_array[grid_to_check].States.FREE)
			if grid[1] < icon_anchor.x: icon_anchor.x = grid[1]
			if grid[0] < icon_anchor.y: icon_anchor.y = grid[0]
		else:
			if grid_array[grid_to_check].has_method("set_color"):
				grid_array[grid_to_check].set_color(grid_array[grid_to_check].States.TAKEN)

func clear_grid():
	for grid in grid_array:
		if grid.has_method("set_color"):
			grid.set_color(grid.States.DEFAULT)
			

func rotate_item():
	item_held.rotate_item()
	clear_grid()
	if current_slot:
		_on_slot_mouse_entered(current_slot)

func place_item():
	if is_mouse_outside_grid():
		# If the mouse is outside the grid, place the item freely
		item_held.global_position = get_global_mouse_position()
		item_held.get_parent().remove_child(item_held)
		add_child(item_held)
		
		# Reset item anchor and grids, as it's no longer on the grid
		item_held.grid_anchor = null
		item_held = null
		clear_grid()
	else:
		var calculated_grid_id = current_slot.slot_ID + icon_anchor.x * col_count + icon_anchor.y
		item_held._snap_to(grid_array[calculated_grid_id].global_position)
	
		item_held.get_parent().remove_child(item_held)
		grid_container.add_child(item_held)
		item_held.global_position = get_global_mouse_position()
	
		item_held.grid_anchor = current_slot
		for grid in item_held.item_grids:
			var grid_to_check = current_slot.slot_ID + grid[0] + grid[1] * col_count
			grid_array[grid_to_check].state = grid_array[grid_to_check].States.TAKEN
			grid_array[grid_to_check].item_stored = item_held
		
		item_held = null
		clear_grid()
	
	if check_if_puzzle_solved():
		print("Puzzle Completed!")
		$TextureRect2/HBoxContainer/Next.visible = true

func check_if_puzzle_solved():
	for slot in grid_array:
		if slot.state != slot.States.TAKEN:
			if slot.state != slot.States.OBSTACLE:
				return false
	return true
	
func is_mouse_outside_grid() -> bool:
	var mouse_pos = get_global_mouse_position()
	var grid_rect = grid_container.get_global_rect()  # Get the bounds of the grid container
	return not grid_rect.has_point(mouse_pos)
	
func pick_item():
	if item_held:
		return
		
	var item_to_pick = get_item_under_mouse()
	if item_to_pick:
		item_held = item_to_pick
		item_held.selected = true
		add_child(item_held)
		item_held.global_position = get_global_mouse_position()
		return
		
	if current_slot and current_slot.item_stored:
		# Detach the item from the current slot
		item_held = current_slot.item_stored
		item_held.selected = true
		
		# Remove item from the grid and reset the slot
		for grid in item_held.item_grids:
			var grid_to_check = item_held.grid_anchor.slot_ID + grid[0] + grid[1] * col_count
			grid_array[grid_to_check].state = grid_array[grid_to_check].States.FREE
			grid_array[grid_to_check].item_stored = null
		
		item_held.get_parent().remove_child(item_held)
		add_child(item_held)
		item_held.global_position = get_global_mouse_position()

		# Reset the slot anchor
		item_held.grid_anchor = null

	
func get_item_under_mouse():
	for item in get_children():
		if item is Item and is_mouse_over_item(item):
			return item
	return null
	
func is_mouse_over_item(item: Node2D) -> bool:
	var texture_rect = item.get_node("Icon")
	if texture_rect:
		var global_rect = Rect2(item.global_position - texture_rect.size / 2, texture_rect.size)
		return global_rect.has_point(get_global_mouse_position())
	return false

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/level_selector.tscn")

func _on_restart_pressed():
	get_tree().change_scene_to_file("res://scenes/levels/level_28.tscn")

func _on_next_pressed():
	get_tree().change_scene_to_file("res://scenes/levels/level_29.tscn")

