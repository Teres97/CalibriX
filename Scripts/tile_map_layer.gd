extends TileMapLayer
@export var unit: Node2D

const ANIMATION_DURATION = 2.3
const DEFAULT_TILE_SOURCE_ID = 24  # Например, для 1.png
const HIGHLIGHT_TILE_SOURCE_ID = 27  # Например, для 3.png
var last_hovered_cell: Vector2i = Vector2i(-999, -999)

func _process(delta):
	var mouse_world_pos = get_global_mouse_position()
	var local_pos = to_local(mouse_world_pos)
	var cell = local_to_map(local_pos)

	if cell != last_hovered_cell:
		# Снять подсветку с предыдущего
		if get_cell_source_id(last_hovered_cell) == HIGHLIGHT_TILE_SOURCE_ID:
			set_cell(last_hovered_cell, DEFAULT_TILE_SOURCE_ID, Vector2i(0, 0))
		# Подсветить текущий гекс
		if get_cell_source_id(cell) == DEFAULT_TILE_SOURCE_ID:
			set_cell(cell, HIGHLIGHT_TILE_SOURCE_ID, Vector2i(0, 0))
		last_hovered_cell = cell
		
		
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var world_pos = get_global_mouse_position()
		var local_pos = to_local(world_pos)
		var cell = local_to_map(local_pos)
		if unit != null:
			unit.move_unit_to_cell(cell)
			print(cell)
			play_tile_animation_once(cell)

func play_tile_animation_once(cell: Vector2i):
	# Заменяем на анимированный тайл (2.png)
	if get_cell_source_id(cell) == 27:
		set_cell(cell, 23, Vector2i(0, 0))  # 1 — это ID AnimatedTile

		# Создаём таймер, чтобы вернуть обычный тайл после проигрывания
		var timer := Timer.new()
		timer.wait_time = ANIMATION_DURATION
		timer.one_shot = true
		add_child(timer)
		timer.start()

		# Когда таймер сработает — вернуть обычный тайл
		timer.timeout.connect(func():
			set_cell(cell, 25, Vector2i(0, 0))
			timer.queue_free()
	)
