extends Node2D

@onready var hex_map: TileMapLayer = $Node2D/TileMapLayer
@onready var bullfinch_scene: PackedScene = preload("res://Scenes/bullfinch.tscn")
@onready var stork_scene: PackedScene = preload("res://Scenes/stork.tscn")
@onready var sparrow_scene: PackedScene = preload("res://Scenes/sparrow.tscn")
@onready var dex_diger_scene: PackedScene = preload("res://Scenes/dex_diger.tscn")
@onready var win_scene: PackedScene = preload("res://Scenes/win.tscn")
@onready var lose_scene: PackedScene = preload("res://Scenes/lose.tscn")
@onready var pause_menu: Node2D = $Menu
@onready var pause_button: Button = $Pause

# --- соседи для offset координат (Horizontal Offset) ---
const HEX_DIRECTIONS_EVEN := [
	Vector2i(+1,  0), Vector2i(0, +1), Vector2i(-1, +1),
	Vector2i(-1,  0), Vector2i(-1, -1), Vector2i(0, -1),
]
const HEX_DIRECTIONS_ODD := [
	Vector2i(+1,  0), Vector2i(+1, +1), Vector2i(0, +1),
	Vector2i(-1,  0), Vector2i(0, -1), Vector2i(+1, -1),
]

# ID тайлов
const DEFAULT_TILE_SOURCE_ID := 1
const HIGHLIGHT_TILE_SOURCE_ID := 5
const ANIMATED_TILE_SOURCE_ID := 10

# юниты
var bullfinch_instance: Node2D
var dex_digern_instance: Node2D
var stork_instance: Node2D
var sparrow_instance: Node2D
var selected_unit: Node2D


var player_units: Array[Node2D] = []
var enemy_units: Array[Node2D] = []

# чей ход
var is_turn: bool = true

# --- INIT ---
func _ready() -> void:
	pause_button.pressed.connect(_on_pause_pressed)
	pause_menu.visible = false   # меню скрыто по умолчанию
	spawn_units()
	show_highlight(2)


func spawn_units() -> void:
	bullfinch_instance = spawn_unit(bullfinch_scene, Vector2i(0, 0), 1, 10)
	var label_bullfinch: Label = bullfinch_instance.get_node_or_null("Counter")
	if label_bullfinch:
		label_bullfinch.add_theme_color_override("font_color", Color.DARK_BLUE)
		label_bullfinch.text = "1"
	player_units.append(bullfinch_instance)

	stork_instance = spawn_unit(stork_scene, Vector2i(1, 0), 1.2, 10)
	var label_stork: Label = stork_instance.get_node_or_null("Counter")
	if label_stork:
		label_stork.add_theme_color_override("font_color", Color.DARK_BLUE)
		label_stork.text = "1"
	player_units.append(stork_instance)
		
	sparrow_instance = spawn_unit(sparrow_scene, Vector2i(-1, 0), 1, 10)
	var label_sparrow: Label = sparrow_instance.get_node_or_null("Counter")
	if label_sparrow:
		label_sparrow.add_theme_color_override("font_color", Color.DARK_BLUE)
		label_sparrow.text = "1"
	player_units.append(sparrow_instance)
	selected_unit = bullfinch_instance
	
	dex_digern_instance = spawn_unit(dex_diger_scene, Vector2i(0, -1), 1.5, 10)
	var label_dex_digern: Label = dex_digern_instance.get_node_or_null("Counter")
	if label_dex_digern:
		label_dex_digern.add_theme_color_override("font_color", Color.FIREBRICK)
		label_dex_digern.text = "1"
	enemy_units.append(dex_digern_instance)

func spawn_unit(scene: PackedScene, cell: Vector2i, scale: float = 0.25, y_offset: float = 20.0) -> Node2D:
	var instance: Node2D = scene.instantiate()
	instance.scale = Vector2(scale, scale)
	add_child(instance)

	var pos := hex_map.map_to_local(cell)
	instance.global_position = hex_map.to_global(pos) - Vector2(0, y_offset)
	return instance


# --- MOVEMENT ---
# --- MOVEMENT (по параболе) ---
func move_unit_to_cell_parabola(cell: Vector2i, duration: float = 1.0, height: float = 60.0) -> void:
	if not selected_unit:
		return

	clear_highlight()

	var start: Vector2 = selected_unit.global_position
	var target: Vector2 = hex_map.to_global(hex_map.map_to_local(cell)) - Vector2(0, 10)
	var other_unit := get_unit_at_position(cell)
	if other_unit in player_units:
		selected_unit = other_unit
		show_highlight(2)
		return
	var sprite := selected_unit.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.play("bullfinch_fly")

	is_turn = false
	var tween := create_tween()
	tween.tween_method(
		func(t: float):
			var pos: Vector2 = start.lerp(target, t) # линейная интерполяция
			# параболическая надбавка по Y: -4h*(t-0.5)^2 + h
			var offset_y := -4 * height * pow(t - 0.5, 2) + height
			pos.y -= offset_y
			selected_unit.global_position = pos
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	await tween.finished
	if sprite:
		sprite.play("idle")

	if other_unit and other_unit != selected_unit:
		handle_combat(selected_unit, other_unit)
	else:
		is_turn = true

	show_highlight(2)
	if not enemy_units.is_empty() and is_instance_valid(dex_digern_instance):
		await ai_turn(dex_digern_instance, 2)

func handle_combat(attacker: Node2D, defender: Node2D) -> void:
	defender.queue_free()
	var sprite := attacker.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.play("bullfinch_explosion")

	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	add_child(timer)
	timer.start()
	timer.timeout.connect(func ():
		attacker.queue_free()
		
		cleanup_units()
		
		timer.queue_free()
		is_turn = true
	)


func get_unit_at_position(cell: Vector2i) -> Node2D:
	for child in get_children():
		if child is Node2D and child is not Camera2D:
			var child_cell := hex_map.local_to_map(hex_map.to_local(child.global_position))
			if child_cell == cell:
				return child
	return null


# --- PATHFIND / REACHABLE CELLS ---
func get_reachable_cells(start_cell: Vector2i, max_distance: int = 2) -> Array[Vector2i]:
	var visited: Dictionary = {}
	var frontier: Array[Vector2i] = [start_cell]
	visited[start_cell] = true

	for i in range(max_distance):
		var next_frontier: Array[Vector2i] = []
		for cell in frontier:
			var directions
			if cell.y % 2 == 0:
				directions = HEX_DIRECTIONS_EVEN
			else:
				directions = HEX_DIRECTIONS_ODD

			for dir in directions:
				var neighbor: Vector2i = cell + dir
				if visited.has(neighbor):
					continue
				if has_tile_at(neighbor):
					visited[neighbor] = true
					next_frontier.append(neighbor)
		frontier = next_frontier

	var result: Array[Vector2i] = []
	for k in visited.keys():
		result.append(k as Vector2i)
	return result


func has_tile_at(cell: Vector2i) -> bool:
	return hex_map.get_cell_source_id(cell) != -1


# --- HIGHLIGHT ---
func show_highlight(max_distance: int) -> void:
	var start_cell: Vector2i = hex_map.local_to_map(hex_map.to_local(selected_unit.global_position))
	var reachable: Array[Vector2i] = get_reachable_cells(start_cell, max_distance)
	for cell in reachable:
		hex_map.set_cell(cell, ANIMATED_TILE_SOURCE_ID, Vector2i(0, 0))


func clear_highlight() -> void:
	var start_cell: Vector2i = hex_map.local_to_map(hex_map.to_local(selected_unit.global_position))
	var reachable: Array[Vector2i] = get_reachable_cells(start_cell, 20)
	for cell in reachable:
		hex_map.set_cell(cell, DEFAULT_TILE_SOURCE_ID, Vector2i(0, 0))


# --- TURN CONTROL ---
func get_turn() -> bool:
	return is_turn


# --- INPUT ---
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell: Vector2i = hex_map.local_to_map(get_global_mouse_position())
		var start_cell: Vector2i = hex_map.local_to_map(hex_map.to_local(selected_unit.global_position))
		var reachable: Array[Vector2i] = get_reachable_cells(start_cell, 2)

		if cell in reachable:
			move_unit_to_cell_parabola(cell)


func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var dq = b.x - a.x
	var dr = b.y - a.y
	return int((abs(dq) + abs(dr) + abs(dq + dr)) / 2)

func ai_turn(enemy: Node2D, radius: int = 2) -> void:
	if not enemy or not selected_unit:
		return

	var enemy_cell: Vector2i = hex_map.local_to_map(hex_map.to_local(enemy.global_position))
	var target_cell: Vector2i = hex_map.local_to_map(hex_map.to_local(selected_unit.global_position))

	# все клетки в радиусе врага
	var candidates: Array[Vector2i] = get_reachable_cells(enemy_cell, radius)

	# выбираем ближайшую к игроку
	var best_cell: Vector2i = enemy_cell
	var best_dist: int = hex_distance(enemy_cell, target_cell)

	for cell in candidates:
		var d = hex_distance(cell, target_cell)
		if d < best_dist:
			best_dist = d
			best_cell = cell

	if best_cell != enemy_cell:
		await move_ai_unit(enemy, best_cell)
	if best_cell == target_cell:
		handle_combat(selected_unit, enemy)
	clear_highlight()

func move_ai_unit(enemy: Node2D, cell: Vector2i) -> void:
	var start: Vector2 = enemy.global_position
	var target: Vector2 = hex_map.to_global(hex_map.map_to_local(cell)) - Vector2(0, 10)

	var tween := create_tween()
	tween.tween_property(enemy, "global_position", target, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	
func cleanup_units() -> void:
	player_units = player_units.filter(func(u): return is_instance_valid(u) and not u.is_queued_for_deletion())
	enemy_units  = enemy_units.filter(func(u): return is_instance_valid(u) and not u.is_queued_for_deletion())

	
func _on_pause_pressed() -> void:
	get_tree().paused = true
	pause_menu.visible = true
