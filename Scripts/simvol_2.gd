extends Sprite2D

func _ready():
	animate_loop()
	
func animate_loop() -> void:
	while true:
		var tween = create_tween()

		# Исходная позиция
		var start_pos = position

		# 1. Подъём на 100 пикселей вверх за 5 сек
		tween.tween_property(self, "position", start_pos - Vector2(0, 50), 10.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		# 2. Опускание обратно за 5 сек
		tween.tween_property(self, "position", start_pos, 10.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await  tween.finished
