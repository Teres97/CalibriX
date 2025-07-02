extends Node2D

@onready var hex_map = $Node2D/TileMapLayer
@onready var bullfinch_scene = preload("res://Scenes/bullfinch.tscn")
@onready var lizard_black_scene = preload("res://Scenes/warrior_lizard_black.tscn")
@onready var lizard_green_scene = preload("res://Scenes/warrior_lizard_green.tscn")

var HEX_DIRECTIONS_EVEN = [
	Vector2i(+1,  0), Vector2i(+1, +1), Vector2i(0, +1),
	Vector2i(-1,  0), Vector2i(0, -1), Vector2i(+1, -1),
]
var HEX_DIRECTIONS_ODD = [
	Vector2i(+1,  0), Vector2i(0, +1), Vector2i(-1, +1),
	Vector2i(-1,  0), Vector2i(-1, -1), Vector2i(0, -1),
]

const DEFAULT_TILE_SOURCE_ID = 24
const HIGHLIGHT_TILE_SOURCE_ID = 27
const ANIMATED_TILE_SOURCE_ID = 23

var bullfinch_instance: Node2D
var lizard_green_instance: Node2D
var lizard_black_instance: Node2D
var selected_unit: Node2D
var turn: bool

func _ready():
	var start_cell = Vector2i(-5, -1)
	bullfinch_instance = spawn_unit(bullfinch_scene,start_cell,0.25,20)
	start_cell = Vector2i(1, 0)
	selected_unit = bullfinch_instance
	lizard_black_instance = spawn_unit(lizard_black_scene,start_cell,0.15,20)
	start_cell = Vector2i(0, -1)
	lizard_green_instance = spawn_unit(lizard_green_scene,start_cell,0.15,20)
	turn = true
	
	
func spawn_unit(scene: PackedScene, cell: Vector2i, scale: float = 0.25, y_offset: float = 20.0) -> Node2D:
	var instance = scene.instantiate()
	instance.scale = Vector2(scale, scale)
	add_child(instance)

	var pos = hex_map.map_to_local(cell)
	instance.global_position = hex_map.to_global(pos) - Vector2(0, y_offset)
	return instance
	
func move_unit_to_cell(cell: Vector2i):
	if not selected_unit:
		return
		
	var global_pos = hex_map.to_global(hex_map.map_to_local(cell))
	var other_unit = get_unit_at_position(cell)
	show_default_cell(4)
	if hex_map.get_cell_source_id(cell) < 23:
		print(hex_map.get_cell_source_id(cell))
		return
	await get_tree().create_timer(0.2).timeout
	var sprite := selected_unit.get_node("AnimatedSprite2D")
	if sprite:
		sprite.play("bullfinch_fly")
	var tween = create_tween()
	turn = false
	tween.tween_property(selected_unit, "global_position", global_pos- Vector2(0,20), 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if sprite:
		sprite.play("idle")
	if other_unit != null:
		other_unit.queue_free()
		if sprite:
			sprite.play("bullfinch_explosion")
		var timer = Timer.new()
		timer.wait_time = 2.0
		timer.one_shot = true
		add_child(timer)
		timer.start()

		timer.timeout.connect(func ():

			selected_unit.queue_free()
			timer.queue_free()
			turn = true
		)
	else:
		turn = true
	hex_map.set_cell(cell, 24, Vector2i(0,0))

func get_unit_at_position(pos: Vector2i) -> Node2D:
	for child in get_children():
		if child is Node2D:
			var child_cell = hex_map.local_to_map(hex_map.to_local(child.global_position))
			if child_cell == pos:
				return child
	return null

func get_turn() -> bool:
	return turn

func get_reachable_cells(start_cell: Vector2i, max_distance: int = 4) -> Array:
	var visited := {}
	var directions
	var frontier := [start_cell]
	visited[start_cell] = true

	for i in range(max_distance):
		var next_frontier := []
		for cell in frontier:
			if cell.y % 2 == 0:
				directions = HEX_DIRECTIONS_EVEN
			else:
				directions = HEX_DIRECTIONS_ODD
			for dir in directions:
				var neighbor = cell + dir
				if visited.has(neighbor):
					continue
				if has_tile_at(neighbor):
					visited[neighbor] = true
					next_frontier.append(neighbor)
		frontier = next_frontier

	return visited.keys()

func has_tile_at(cell: Vector2i) -> bool:
	return hex_map.get_cell_source_id(cell) != -1

func show_default_cell(MAX_DISTANCE: int):
	var start_cell = hex_map.local_to_map(hex_map.to_local(selected_unit.global_position))
	var reachable = get_reachable_cells(start_cell, MAX_DISTANCE)

	for cell in reachable:
		hex_map.set_cell(cell, DEFAULT_TILE_SOURCE_ID, Vector2i(0, 0))
	
func show_highlight(MAX_DISTANCE: int):

	var start_cell = hex_map.local_to_map(hex_map.to_local(selected_unit.global_position))
	var reachable = get_reachable_cells(start_cell, MAX_DISTANCE)

	for cell in reachable:
		hex_map.set_cell(cell, ANIMATED_TILE_SOURCE_ID, Vector2i(0, 0))

func _on_button_pressed() -> void:
	selected_unit = bullfinch_instance
	show_highlight(4)
