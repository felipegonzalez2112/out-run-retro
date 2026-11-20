extends Node2D

# Colores del cielo y el atardecer
const SKY_COLOR = Color("#42b5e8")
const SKY_TOP_COLOR = Color("#29469b")
const SKY_GLOW_COLOR = Color("#ffe1a1")
const HORIZON_COLOR = Color("#f7a34b")
const SUN_TOP_COLOR = Color("#fff3a6")
const SUN_BOTTOM_COLOR = Color("#ff824d")
const SUN_STRIP_COUNT = 11

# Colores del paisaje y la carretera
const MOUNTAIN_FAR_COLOR = Color("#8879ae")
const MOUNTAIN_NEAR_COLOR = Color("#5a4b78")
const GROUND_COLOR = Color("#4e7049")
const ROAD_EDGE_LIGHT = Color("#f6d99a")
const ROAD_EDGE_DARK = Color("#cf5549")
const ROAD_COLOR_A = Color("#353746")
const ROAD_COLOR_B = Color("#3d3d4b")
const ROAD_MARKER_COLOR = Color("#fff0c2")
const ROAD_SEGMENT_COUNT = 48
const ROAD_SCROLL_SPEED = 7.0
const ROAD_CURVE_SPEED = 0.22
const ROAD_CURVE_AMPLITUDE = 0.14

# Colores del auto
const CAR_BODY_COLOR = Color("#d82f32")
const CAR_HIGHLIGHT_COLOR = Color("#ff6652")
const CAR_WINDOW_COLOR = Color("#263e57")
const CAR_TIRE_COLOR = Color("#20202b")
const CAR_LIGHT_COLOR = Color("#ffe689")

var road_scroll = 0.0
var curve_phase = 0.0


func _process(delta):
	# El patrón de la carretera y las curvas avanzan continuamente.
	road_scroll = fposmod(road_scroll + delta * ROAD_SCROLL_SPEED, ROAD_SEGMENT_COUNT)
	curve_phase = fposmod(curve_phase + delta * ROAD_CURVE_SPEED, TAU)
	queue_redraw()


func _draw():
	var screen_size = get_viewport_rect().size
	var horizon = screen_size.y * 0.48
	var sky_middle = horizon * 0.72

	_draw_sky(screen_size, horizon, sky_middle)
	_draw_sun(screen_size, horizon)

	# Brillo cálido detrás de las montañas.
	draw_rect(
		Rect2(0, horizon, screen_size.x, screen_size.y * 0.055),
		HORIZON_COLOR
	)
	draw_rect(
		Rect2(
			0,
			horizon + screen_size.y * 0.055,
			screen_size.x,
			screen_size.y - horizon - screen_size.y * 0.055
		),
		GROUND_COLOR
	)

	_draw_mountains(screen_size, horizon)
	_draw_road(screen_size, horizon)
	_draw_player_car(screen_size)


func _draw_sky(screen_size, horizon, sky_middle):
	# Degradado azul: tono profundo arriba y celeste hacia el centro.
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

	# Resplandor claro al pie del cielo.
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


func _draw_sun(screen_size, horizon):
	var sun_radius = minf(screen_size.y * 0.12, 72.0)
	var sun_center = Vector2(screen_size.x * 0.76, horizon - sun_radius * 0.9)
	var strip_spacing = sun_radius * 1.68 / float(SUN_STRIP_COUNT - 1)

	for strip_index in range(SUN_STRIP_COUNT):
		var color_ratio = float(strip_index) / float(SUN_STRIP_COUNT - 1)
		var vertical_offset = (float(strip_index) - (SUN_STRIP_COUNT - 1) / 2.0) * strip_spacing
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


func _draw_mountains(screen_size, horizon):
	var base_y = minf(horizon + screen_size.y * 0.055, screen_size.y)

	var far_peaks = PackedVector2Array([
		Vector2(0, horizon + 18),
		Vector2(screen_size.x * 0.11, horizon - 28),
		Vector2(screen_size.x * 0.23, horizon + 12),
		Vector2(screen_size.x * 0.38, horizon - 84),
		Vector2(screen_size.x * 0.50, horizon - 22),
		Vector2(screen_size.x * 0.63, horizon - 60),
		Vector2(screen_size.x * 0.74, horizon + 8),
		Vector2(screen_size.x * 0.87, horizon - 90),
		Vector2(screen_size.x, horizon + 24)
	])
	_draw_mountain_layer(far_peaks, base_y, screen_size, MOUNTAIN_FAR_COLOR)

	var near_peaks = PackedVector2Array([
		Vector2(0, horizon + 27),
		Vector2(screen_size.x * 0.13, horizon + 8),
		Vector2(screen_size.x * 0.25, horizon - 26),
		Vector2(screen_size.x * 0.37, horizon + 21),
		Vector2(screen_size.x * 0.51, horizon - 38),
		Vector2(screen_size.x * 0.65, horizon + 17),
		Vector2(screen_size.x * 0.78, horizon - 12),
		Vector2(screen_size.x * 0.90, horizon + 15),
		Vector2(screen_size.x, horizon + 20)
	])
	_draw_mountain_layer(near_peaks, base_y, screen_size, MOUNTAIN_NEAR_COLOR)


func _draw_mountain_layer(peaks, base_y, screen_size, color):
	var points = PackedVector2Array([Vector2(0, base_y)])
	for peak in peaks:
		points.append(peak)
	points.append(Vector2(screen_size.x, base_y))
	points.append(Vector2(screen_size.x, screen_size.y))
	points.append(Vector2(0, screen_size.y))
	draw_colored_polygon(points, color)


func _draw_road(screen_size, horizon):
	for segment_index in range(ROAD_SEGMENT_COUNT):
		var depth_top = pow(float(segment_index) / ROAD_SEGMENT_COUNT, 2.0)
		var depth_bottom = pow(float(segment_index + 1) / ROAD_SEGMENT_COUNT, 2.0)
		var y_top = lerpf(horizon, screen_size.y, depth_top)
		var y_bottom = lerpf(horizon, screen_size.y, depth_bottom)
		var center_top = _road_center_x(depth_top, screen_size.x)
		var center_bottom = _road_center_x(depth_bottom, screen_size.x)
		var half_width_top = _road_half_width(depth_top, screen_size.x)
		var half_width_bottom = _road_half_width(depth_bottom, screen_size.x)
		var edge_top = lerpf(2.0, screen_size.x * 0.022, depth_top)
		var edge_bottom = lerpf(2.0, screen_size.x * 0.022, depth_bottom)
		var moving_index = segment_index + int(road_scroll)
		var edge_group = int(floor(float(moving_index) / 6.0))
		var edge_color = ROAD_EDGE_LIGHT if edge_group % 2 == 0 else ROAD_EDGE_DARK
		var road_group = int(floor(float(moving_index) / 3.0))
		var road_color = ROAD_COLOR_A if road_group % 2 == 0 else ROAD_COLOR_B

		_draw_road_quad(
			center_top, center_bottom,
			half_width_top + edge_top, half_width_bottom + edge_bottom,
			y_top, y_bottom, edge_color
		)
		_draw_road_quad(
			center_top, center_bottom,
			half_width_top, half_width_bottom,
			y_top, y_bottom, road_color
		)

		# Línea discontinua central que también se estrecha con la perspectiva.
		if moving_index % 8 < 4:
			_draw_road_quad(
				center_top, center_bottom,
				half_width_top * 0.018, half_width_bottom * 0.018,
				y_top, y_bottom, ROAD_MARKER_COLOR
			)


func _road_center_x(depth, screen_width):
	var curve_depth = 1.0 - depth
	var bend = sin(curve_phase + curve_depth * 2.4)
	return screen_width * 0.5 + bend * screen_width * ROAD_CURVE_AMPLITUDE * curve_depth


func _road_half_width(depth, screen_width):
	var perspective = pow(depth, 1.15)
	return lerpf(screen_width * 0.025, screen_width * 0.44, perspective)


func _draw_road_quad(center_top, center_bottom, half_top, half_bottom, y_top, y_bottom, color):
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(center_top - half_top, y_top),
			Vector2(center_top + half_top, y_top),
			Vector2(center_bottom + half_bottom, y_bottom),
			Vector2(center_bottom - half_bottom, y_bottom)
		]),
		color
	)


func _draw_player_car(screen_size):
	var car_width = screen_size.x * 0.115
	var car_height = screen_size.y * 0.18
	var car_center_x = screen_size.x * 0.5
	var car_bottom = screen_size.y * 0.965
	var car_top = car_bottom - car_height

	# Sombra y ruedas, detrás de la carrocería.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(car_center_x - car_width * 0.48, car_bottom - car_height * 0.06),
			Vector2(car_center_x - car_width * 0.34, car_bottom - car_height * 0.16),
			Vector2(car_center_x + car_width * 0.34, car_bottom - car_height * 0.16),
			Vector2(car_center_x + car_width * 0.48, car_bottom - car_height * 0.06)
		]),
		Color("#262334")
	)
	draw_rect(
		Rect2(car_center_x - car_width * 0.48, car_top + car_height * 0.48, car_width * 0.14, car_height * 0.34),
		CAR_TIRE_COLOR
	)
	draw_rect(
		Rect2(car_center_x + car_width * 0.34, car_top + car_height * 0.48, car_width * 0.14, car_height * 0.34),
		CAR_TIRE_COLOR
	)

	# Silueta trasera del deportivo.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(car_center_x - car_width * 0.48, car_bottom),
			Vector2(car_center_x - car_width * 0.43, car_top + car_height * 0.54),
			Vector2(car_center_x - car_width * 0.32, car_top + car_height * 0.25),
			Vector2(car_center_x - car_width * 0.20, car_top + car_height * 0.10),
			Vector2(car_center_x + car_width * 0.20, car_top + car_height * 0.10),
			Vector2(car_center_x + car_width * 0.32, car_top + car_height * 0.25),
			Vector2(car_center_x + car_width * 0.43, car_top + car_height * 0.54),
			Vector2(car_center_x + car_width * 0.48, car_bottom)
		]),
		CAR_BODY_COLOR
	)

	# Luneta, brillo y luces traseras.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(car_center_x - car_width * 0.18, car_top + car_height * 0.15),
			Vector2(car_center_x + car_width * 0.18, car_top + car_height * 0.15),
			Vector2(car_center_x + car_width * 0.29, car_top + car_height * 0.42),
			Vector2(car_center_x - car_width * 0.29, car_top + car_height * 0.42)
		]),
		CAR_WINDOW_COLOR
	)
	draw_rect(
		Rect2(car_center_x - car_width * 0.38, car_top + car_height * 0.62, car_width * 0.18, car_height * 0.07),
		CAR_LIGHT_COLOR
	)
	draw_rect(
		Rect2(car_center_x + car_width * 0.20, car_top + car_height * 0.62, car_width * 0.18, car_height * 0.07),
		CAR_LIGHT_COLOR
	)
	draw_rect(
		Rect2(car_center_x - car_width * 0.20, car_top + car_height * 0.55, car_width * 0.40, car_height * 0.035),
		CAR_HIGHLIGHT_COLOR
	)
