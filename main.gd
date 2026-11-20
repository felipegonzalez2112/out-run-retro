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
const TRAFFIC_COLORS = ["#48b8d0", "#f2c14e", "#72b36b", "#a56cc1"]
const TRAFFIC_LANES = [-0.62, -0.22, 0.22, 0.62]
const MAX_TRAFFIC_CARS = 5
const MAX_SPEED = 240.0
const TOUCH_BUTTON_RADIUS = 42.0

var road_scroll = 0.0
var curve_phase = 0.0
var player_lateral_position = 0.0
var game_speed = 0.35
var score = 0.0
var traffic_cars = []
var traffic_spawn_timer = 1.0
var collision_cooldown = 0.0
var collision_flash = 0.0
var active_touches = {}


func _ready():
	randomize()


func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			_set_touch_action(event.index, event.position)
		else:
			active_touches.erase(event.index)
		queue_redraw()
	elif event is InputEventScreenDrag:
		_set_touch_action(event.index, event.position)
		queue_redraw()


func _process(delta):
	_update_player(delta)
	_update_traffic(delta)
	road_scroll = fposmod(road_scroll + delta * ROAD_SCROLL_SPEED * (0.25 + game_speed), float(ROAD_SEGMENT_COUNT))
	curve_phase = fposmod(curve_phase + delta * ROAD_CURVE_SPEED, TAU)
	score += delta * game_speed * 180.0
	collision_cooldown = maxf(0.0, collision_cooldown - delta)
	collision_flash = maxf(0.0, collision_flash - delta)
	queue_redraw()


func _update_player(delta):
	var steering = 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or _is_touch_action_active("left"):
		steering -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or _is_touch_action_active("right"):
		steering += 1.0
	player_lateral_position = clampf(player_lateral_position + steering * delta * 1.15, -1.0, 1.0)

	var accelerating = Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or _is_touch_action_active("accelerate")
	var braking = Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or _is_touch_action_active("brake")
	if accelerating:
		game_speed = move_toward(game_speed, 1.0, delta * 0.38)
	elif braking:
		game_speed = move_toward(game_speed, 0.0, delta * 0.72)
	else:
		game_speed = move_toward(game_speed, 0.35, delta * 0.06)

	# Circular por fuera de la calzada reduce la velocidad.
	if absf(player_lateral_position) > 0.78:
		game_speed = move_toward(game_speed, 0.2, delta * 0.7)


func _update_traffic(delta):
	traffic_spawn_timer -= delta
	if traffic_spawn_timer <= 0.0 and traffic_cars.size() < MAX_TRAFFIC_CARS:
		_spawn_traffic_car()
		traffic_spawn_timer = randf_range(1.35, 2.1)

	for car_index in range(traffic_cars.size() - 1, -1, -1):
		var traffic_car = traffic_cars[car_index]
		traffic_car["depth"] += delta * (0.055 + game_speed * 0.2)
		var depth = traffic_car["depth"]
		var player_lane = player_lateral_position * 0.77
		var traffic_lane = traffic_car["lane"] * 0.82

		if depth >= 0.84 and absf(traffic_lane - player_lane) < 0.19 and collision_cooldown <= 0.0:
			game_speed = maxf(0.15, game_speed * 0.45)
			score = maxf(0.0, score - 250.0)
			collision_cooldown = 1.0
			collision_flash = 0.45
			traffic_cars.remove_at(car_index)
			continue

		if depth > 1.12:
			traffic_cars.remove_at(car_index)
		else:
			traffic_cars[car_index] = traffic_car


func _spawn_traffic_car():
	var lane_index = randi_range(0, TRAFFIC_LANES.size() - 1)
	var color_index = randi_range(0, TRAFFIC_COLORS.size() - 1)
	traffic_cars.append({
		"depth": 0.0,
		"lane": TRAFFIC_LANES[lane_index],
		"color": Color(TRAFFIC_COLORS[color_index])
	})


func _is_touch_action_active(action):
	return active_touches.values().has(action)


func _touch_control_centers(screen_size):
	var radius = minf(screen_size.x * 0.035, TOUCH_BUTTON_RADIUS)
	var y = screen_size.y - radius * 1.45
	return {
		"left": Vector2(radius * 1.35, y),
		"right": Vector2(radius * 3.65, y),
		"brake": Vector2(screen_size.x - radius * 3.65, y),
		"accelerate": Vector2(screen_size.x - radius * 1.35, y)
	}


func _set_touch_action(touch_index, position):
	var screen_size = get_viewport_rect().size
	var centers = _touch_control_centers(screen_size)
	var radius = minf(screen_size.x * 0.035, TOUCH_BUTTON_RADIUS)
	for action in centers:
		if centers[action].distance_to(position) <= radius * 1.15:
			active_touches[touch_index] = action
			return
	active_touches.erase(touch_index)


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
	_draw_traffic(screen_size, horizon)
	_draw_player_car(screen_size)
	_draw_hud(screen_size)
	_draw_touch_controls(screen_size)
	_draw_collision_flash(screen_size)


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


func _draw_traffic(screen_size, horizon):
	for traffic_car in traffic_cars:
		var depth = float(traffic_car["depth"])
		var road_depth = depth * depth
		var base_y = lerpf(horizon + 8.0, screen_size.y * 0.92, road_depth)
		var road_center = _road_center_x(road_depth, screen_size.x)
		var road_half_width = _road_half_width(road_depth, screen_size.x)
		var center_x = road_center + float(traffic_car["lane"]) * road_half_width * 0.82
		var car_width = lerpf(screen_size.x * 0.012, screen_size.x * 0.09, depth)
		var car_height = car_width * 0.74
		_draw_traffic_car(center_x, base_y, car_width, car_height, traffic_car["color"])


func _draw_traffic_car(center_x, base_y, car_width, car_height, body_color):
	var top_y = base_y - car_height
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(center_x - car_width * 0.50, base_y),
			Vector2(center_x - car_width * 0.43, top_y + car_height * 0.32),
			Vector2(center_x - car_width * 0.25, top_y),
			Vector2(center_x + car_width * 0.25, top_y),
			Vector2(center_x + car_width * 0.43, top_y + car_height * 0.32),
			Vector2(center_x + car_width * 0.50, base_y)
		]),
		body_color
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(center_x - car_width * 0.20, top_y + car_height * 0.08),
			Vector2(center_x + car_width * 0.20, top_y + car_height * 0.08),
			Vector2(center_x + car_width * 0.32, top_y + car_height * 0.34),
			Vector2(center_x - car_width * 0.32, top_y + car_height * 0.34)
		]),
		CAR_WINDOW_COLOR
	)
	var light_size = maxf(2.0, car_width * 0.10)
	draw_rect(Rect2(center_x - car_width * 0.38, base_y - car_height * 0.22, light_size, light_size), CAR_LIGHT_COLOR)
	draw_rect(Rect2(center_x + car_width * 0.28, base_y - car_height * 0.22, light_size, light_size), CAR_LIGHT_COLOR)


func _draw_hud(screen_size):
	var font = ThemeDB.fallback_font
	var text_color = Color("#fff4cf")
	var score_text = "PUNTOS %07d" % int(score)
	var speed_text = "%03d KM/H" % int(game_speed * MAX_SPEED)

	draw_rect(Rect2(12, 12, 250, 42), Color(0.08, 0.09, 0.16, 0.72))
	draw_rect(Rect2(screen_size.x - 220, 12, 208, 42), Color(0.08, 0.09, 0.16, 0.72))
	draw_string(font, Vector2(24, 40), score_text, HORIZONTAL_ALIGNMENT_LEFT, 230, 22, text_color)
	draw_string(font, Vector2(screen_size.x - 22, 40), speed_text, HORIZONTAL_ALIGNMENT_RIGHT, 190, 22, text_color)
	draw_string(
		font,
		Vector2(screen_size.x * 0.5 - 155, 40),
		"OUTRUN RETRO",
		HORIZONTAL_ALIGNMENT_CENTER,
		310,
		22,
		Color("#ffdc89")
	)
	draw_string(
		font,
		Vector2(screen_size.x * 0.5 - 270, 70),
		"A/D o flechas: girar     W/S o flechas: acelerar/frenar",
		HORIZONTAL_ALIGNMENT_CENTER,
		540,
		15,
		text_color
	)


func _draw_touch_controls(screen_size):
	var radius = minf(screen_size.x * 0.035, TOUCH_BUTTON_RADIUS)
	var centers = _touch_control_centers(screen_size)
	var labels = {"left": "L", "right": "R", "brake": "B", "accelerate": "G"}
	var font = ThemeDB.fallback_font

	for action in centers:
		var is_pressed = _is_touch_action_active(action)
		var fill = Color(0.10, 0.10, 0.16, 0.68) if is_pressed else Color(0.10, 0.10, 0.16, 0.40)
		draw_circle(centers[action], radius, fill)
		draw_arc(centers[action], radius, 0.0, TAU, 32, Color(1.0, 0.9, 0.65, 0.75), 2.0)
		draw_string(
			font,
			Vector2(centers[action].x - radius, centers[action].y + 8),
			labels[action],
			HORIZONTAL_ALIGNMENT_CENTER,
			radius * 2.0,
			20,
			Color("#fff4cf")
		)


func _draw_collision_flash(screen_size):
	if collision_flash <= 0.0:
		return
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.85, 0.08, 0.08, collision_flash * 0.35))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(screen_size.x * 0.5 - 100, screen_size.y * 0.36),
		"CHOQUE!",
		HORIZONTAL_ALIGNMENT_CENTER,
		200,
		36,
		Color("#fff4cf")
	)


func _draw_player_car(screen_size):
	var car_width = screen_size.x * 0.115
	var car_height = screen_size.y * 0.18
	var car_center_x = screen_size.x * 0.5 + player_lateral_position * screen_size.x * 0.34
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
