extends TileMapLayer

const ANIMATION_DURATION = 2

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var world_pos = get_global_mouse_position()
		var local_pos = to_local(world_pos)
		var cell = local_to_map(local_pos)
		print(cell)
		play_tile_animation_once(cell)

func play_tile_animation_once(cell: Vector2i):
	# Заменяем на анимированный тайл (2.png)
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
