
extends Node2D

# Colores del paisaje
const SKY_COLOR = Color("#42b5e8")
const SKY_TOP_COLOR = Color("#29469b")
const SKY_GLOW_COLOR = Color("#ffe1a1")
const HORIZON_COLOR = Color("#f7a34b")
const SUN_TOP_COLOR = Color("#fff3a6")
const SUN_BOTTOM_COLOR = Color("#ff824d")
const SUN_STRIP_COUNT = 11

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

	# Sol rayado, detrás de la franja del horizonte.
	var sun_radius = minf(screen_size.y * 0.12, 72.0)
	var sun_center = Vector2(screen_size.x * 0.76, horizon - sun_radius * 0.9)
	var sun_strip_spacing = sun_radius * 1.68 / float(SUN_STRIP_COUNT - 1)

	for strip_index in range(SUN_STRIP_COUNT):
		var color_ratio = float(strip_index) / float(SUN_STRIP_COUNT - 1)
		var vertical_offset = (float(strip_index) - (SUN_STRIP_COUNT - 1) / 2.0) * sun_strip_spacing
		var half_width = sqrt(sun_radius * sun_radius - vertical_offset * vertical_offset)
		var strip_color = SUN_TOP_COLOR.lerp(SUN_BOTTOM_COLOR, color_ratio)

		draw_rect(
			Rect2(
				sun_center.x - half_width,
				sun_center.y + vertical_offset,
				half_width * 2.0,
				5.0
			),
			strip_color
		)

	# Franja cálida del horizonte
	draw_rect(
		Rect2(0, horizon, screen_size.x, 35),
		HORIZON_COLOR
	)
