
extends Node2D

# Colores del paisaje
const SKY_COLOR = Color("#42b5e8")
const HORIZON_COLOR = Color("#f7a34b")

func _draw():
	var screen_size = get_viewport_rect().size
	var horizon = screen_size.y * 0.48

	# Cielo
	draw_rect(
		Rect2(0, 0, screen_size.x, horizon),
		SKY_COLOR
	)

	# Franja cálida del horizonte
	draw_rect(
		Rect2(0, horizon, screen_size.x, 35),
		HORIZON_COLOR
	)
