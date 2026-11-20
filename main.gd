
extends Node2D

# Colores del paisaje
const SKY_COLOR = Color("#42b5e8")
const SKY_TOP_COLOR = Color("#29469b")
const SKY_GLOW_COLOR = Color("#ffe1a1")
const HORIZON_COLOR = Color("#f7a34b")

func _draw():
	var screen_size = get_viewport_rect().size
	var horizon = screen_size.y * 0.48
	var sky_middle = horizon * 0.72

	# Degradado azul: del tono profundo de arriba al celeste del centro.
	draw_polygon(
		PackedVector2Array([
			Vector2(0, 0),
			Vector2(screen_size.x, 0),
			Vector2(screen_size.x, sky_middle),
			Vector2(0, sky_middle)
		]),
		PackedColorArray([
			SKY_TOP_COLOR,
			SKY_TOP_COLOR,
			SKY_COLOR,
			SKY_COLOR
		])
	)

	# Resplandor cálido que prepara el horizonte del atardecer.
	draw_polygon(
		PackedVector2Array([
			Vector2(0, sky_middle),
			Vector2(screen_size.x, sky_middle),
			Vector2(screen_size.x, horizon),
			Vector2(0, horizon)
		]),
		PackedColorArray([
			SKY_COLOR,
			SKY_COLOR,
			SKY_GLOW_COLOR,
			SKY_GLOW_COLOR
		])
	)

	# Franja cálida del horizonte
	draw_rect(
		Rect2(0, horizon, screen_size.x, 35),
		HORIZON_COLOR
	)
