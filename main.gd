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
const GROUND_COLOR_A = Color("#248a65")
const GROUND_COLOR_B = Color("#147256")
const ROAD_EDGE_LIGHT = Color("#fff0ba")
const ROAD_EDGE_DARK = Color("#ef5c55")
const ROAD_COLOR_A = Color("#36364c")
const ROAD_COLOR_B = Color("#2a2c40")
const ROAD_MARKER_COLOR = Color("#fff7d6")
const PALM_LEAF_COLOR = Color("#173f47")
const PALM_HIGHLIGHT_COLOR = Color("#276654")
const PALM_TRUNK_COLOR = Color("#633d38")
const ROAD_SEGMENT_COUNT = 72
const ROAD_CURVE_SPEED = 0.14
const ROAD_CURVE_AMPLITUDE = 0.19

# Colores del auto
const CAR_BODY_COLOR = Color("#d82f32")
const CAR_HIGHLIGHT_COLOR = Color("#ff6652")
const CAR_WINDOW_COLOR = Color("#263e57")
const CAR_TIRE_COLOR = Color("#20202b")
const CAR_LIGHT_COLOR = Color("#ffe689")
const TRAFFIC_COLORS = ["#48b8d0", "#f2c14e", "#72b36b", "#a56cc1"]
const TRAFFIC_LANES = [-0.62, -0.22, 0.22, 0.62]
const MAX_TRAFFIC_CARS = 5
const MAX_SPEED = 300.0
const TOUCH_BUTTON_RADIUS = 42.0

var road_distance = 0.0
var curve_phase = 0.0
var player_lateral_position = 0.0
var game_speed = 0.52
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
	road_distance = fposmod(road_distance + delta * lerpf(0.11, 0.64, game_speed), 1.0)
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
		game_speed = move_toward(game_speed, 1.0, delta * 0.62)
	elif braking:
		game_speed = move_toward(game_speed, 0.0, delta * 1.05)
	else:
		game_speed = move_toward(game_speed, 0.52, delta * 0.12)

	# Circular por fuera de la calzada reduce la velocidad.
	if absf(player_lateral_position) > 0.78:
		game_speed = move_toward(game_speed, 0.22, delta * 0.9)


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
	draw_rect(Rect2(0, horizon + screen_size.y * 0.055, screen_size.x, screen_size.y - horizon), GROUND_COLOR_A)

	_draw_mountains(screen_size, horizon)
	_draw_road(screen_size, horizon)
	_draw_roadside_palms(screen_size, horizon)
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
	var first_segment = int(ceil((1.0 - road_distance) * ROAD_SEGMENT_COUNT)) % ROAD_SEGMENT_COUNT

	# Los segmentos se ordenan de horizonte a cámara. La profundidad cambia cada
	# cuadro, por eso el patrón se acerca al jugador en vez de solo alternar color.
	for draw_index in range(ROAD_SEGMENT_COUNT):
		var world_segment = (first_segment + draw_index) % ROAD_SEGMENT_COUNT
		var depth_top = fposmod(float(world_segment) / ROAD_SEGMENT_COUNT + road_distance, 1.0)
		var depth_bottom = 1.0 if draw_index == ROAD_SEGMENT_COUNT - 1 else fposmod(float(world_segment + 1) / ROAD_SEGMENT_COUNT + road_distance, 1.0)
		_draw_road_segment(screen_size, horizon, depth_top, depth_bottom, world_segment)


func _draw_road_segment(screen_size, horizon, depth_top, depth_bottom, world_segment):
	var perspective_top = pow(depth_top, 2.15)
	var perspective_bottom = pow(depth_bottom, 2.15)
	var y_top = lerpf(horizon, screen_size.y, perspective_top)
	var y_bottom = lerpf(horizon, screen_size.y, perspective_bottom)
	var center_top = _road_center_x(depth_top, screen_size.x)
	var center_bottom = _road_center_x(depth_bottom, screen_size.x)
	var half_width_top = _road_half_width(depth_top, screen_size.x)
	var half_width_bottom = _road_half_width(depth_bottom, screen_size.x)
	var edge_top = lerpf(2.0, screen_size.x * 0.029, perspective_top)
	var edge_bottom = lerpf(2.0, screen_size.x * 0.029, perspective_bottom)
	var stripe_group = int(floor(float(world_segment) / 3.0))
	var edge_color = ROAD_EDGE_LIGHT if stripe_group % 2 == 0 else ROAD_EDGE_DARK
	var grass_color = GROUND_COLOR_A if stripe_group % 2 == 0 else GROUND_COLOR_B
	var road_color = ROAD_COLOR_A if int(floor(float(world_segment) / 2.0)) % 2 == 0 else ROAD_COLOR_B

	# Franjas de césped y de borde: mantienen el contraste al subir la velocidad.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0, y_top), Vector2(screen_size.x, y_top),
			Vector2(screen_size.x, y_bottom), Vector2(0, y_bottom)
		]),
		grass_color
	)
	_draw_road_quad(center_top, center_bottom, half_width_top + edge_top, half_width_bottom + edge_bottom, y_top, y_bottom, edge_color)
	_draw_road_quad(center_top, center_bottom, half_width_top, half_width_bottom, y_top, y_bottom, road_color)

	if world_segment % 12 < 6:
		_draw_road_quad(
			center_top, center_bottom,
			half_width_top * 0.018, half_width_bottom * 0.018,
			y_top, y_bottom, ROAD_MARKER_COLOR
		)


func _road_center_x(depth, screen_width):
	var horizon_bend = sin(curve_phase) * ROAD_CURVE_AMPLITUDE
	var near_bend = sin(curve_phase * 0.54 + 1.15) * ROAD_CURVE_AMPLITUDE * 0.34
	var bend = lerpf(horizon_bend, near_bend, pow(depth, 1.65))
	return screen_width * (0.5 + bend)


func _road_half_width(depth, screen_width):
	var perspective = pow(depth, 1.28)
	return lerpf(screen_width * 0.018, screen_width * 0.49, perspective)


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


func _draw_roadside_palms(screen_size, horizon):
	# Pocos objetos grandes venden más la profundidad que muchos sprites pequeños.
	for palm_index in range(12):
		var world_depth = fposmod(float(palm_index) * 0.173 + road_distance * 0.93, 1.0)
		var side = -1.0 if palm_index % 2 == 0 else 1.0
		_draw_palm(screen_size, horizon, world_depth, side, palm_index)


func _draw_palm(screen_size, horizon, depth, side, palm_index):
	var perspective = pow(depth, 2.0)
	var base_y = lerpf(horizon + 13.0, screen_size.y * 0.98, perspective)
	var road_center = _road_center_x(depth, screen_size.x)
	var road_half_width = _road_half_width(depth, screen_size.x)
	var roadside_gap = lerpf(screen_size.x * 0.035, screen_size.x * 0.21, perspective)
	var base_x = road_center + side * (road_half_width + roadside_gap)
	var tree_height = lerpf(8.0, screen_size.y * 0.34, pow(depth, 1.3))
	var crown_center = Vector2(base_x - side * tree_height * 0.08, base_y - tree_height)
	var trunk_width = maxf(2.0, tree_height * 0.105)
	var lean = side * (0.15 + sin(float(palm_index) * 1.7) * 0.06)

	# Tronco ancho y ligeramente inclinado.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(base_x - trunk_width * 0.5, base_y),
			Vector2(base_x + trunk_width * 0.5, base_y),
			Vector2(crown_center.x + trunk_width * 0.32 + lean * tree_height, crown_center.y + tree_height * 0.12),
			Vector2(crown_center.x - trunk_width * 0.32 + lean * tree_height, crown_center.y + tree_height * 0.12)
		]),
		PALM_TRUNK_COLOR
	)

	# Hojas en abanico. A distancia se reducen a una silueta sin costo de texturas.
	var leaf_count = 7
	for leaf_index in range(leaf_count):
		var angle = lerpf(-2.72, -0.42, float(leaf_index) / float(leaf_count - 1))
		var leaf_length = tree_height * (0.33 + (leaf_index % 2) * 0.05)
		var tip = crown_center + Vector2(cos(angle), sin(angle)) * leaf_length
		var leaf_color = PALM_HIGHLIGHT_COLOR if leaf_index % 2 == 0 else PALM_LEAF_COLOR
		draw_colored_polygon(
			PackedVector2Array([
				crown_center,
				crown_center + Vector2(cos(angle - 0.15), sin(angle - 0.15)) * leaf_length * 0.28,
				tip,
				crown_center + Vector2(cos(angle + 0.15), sin(angle + 0.15)) * leaf_length * 0.28
			]),
			leaf_color
		)


func _draw_traffic(screen_size, horizon):
	for traffic_car in traffic_cars:
		var depth = float(traffic_car["depth"])
		var road_depth = depth * depth
		var base_y = lerpf(horizon + 8.0, screen_size.y * 0.92, road_depth)
		var road_center = _road_center_x(depth, screen_size.x)
		var road_half_width = _road_half_width(depth, screen_size.x)
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

	draw_rect(Rect2(16, 16, 228, 36), Color(0.10, 0.08, 0.20, 0.8))
	draw_rect(Rect2(screen_size.x - 214, 16, 198, 36), Color(0.10, 0.08, 0.20, 0.8))
	draw_rect(Rect2(16, 52, 228 * game_speed, 4), Color("#ffcf63"))
	draw_string(font, Vector2(28, 40), score_text, HORIZONTAL_ALIGNMENT_LEFT, 210, 19, text_color)
	draw_string(font, Vector2(screen_size.x - 28, 40), speed_text, HORIZONTAL_ALIGNMENT_RIGHT, 174, 19, text_color)
	draw_string(
		font,
		Vector2(screen_size.x * 0.5 - 155, 42),
		"SUNSET RUN",
		HORIZONTAL_ALIGNMENT_CENTER,
		310,
		24,
		Color("#ffe08c")
	)
	draw_string(
		font,
		Vector2(screen_size.x * 0.5 - 270, 66),
		"FLECHAS / WASD   ·   TOCA LOS CONTROLES",
		HORIZONTAL_ALIGNMENT_CENTER,
		540,
		13,
		Color(1.0, 0.96, 0.84, 0.82)
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
	var car_width = screen_size.x * 0.165
	var car_height = screen_size.y * 0.245
	var road_center = _road_center_x(0.94, screen_size.x)
	var car_center_x = road_center + player_lateral_position * screen_size.x * 0.31
	var car_bottom = screen_size.y * 0.975
	var car_top = car_bottom - car_height
	var speed_shake = sin(road_distance * TAU * 28.0) * game_speed * 2.0
	car_center_x += speed_shake

	# Sombra proyectada, ruedas y alerón trasero.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(car_center_x - car_width * 0.57, car_bottom - car_height * 0.03),
			Vector2(car_center_x - car_width * 0.30, car_bottom - car_height * 0.12),
			Vector2(car_center_x + car_width * 0.30, car_bottom - car_height * 0.12),
			Vector2(car_center_x + car_width * 0.57, car_bottom - car_height * 0.03),
			Vector2(car_center_x + car_width * 0.30, car_bottom + car_height * 0.025),
			Vector2(car_center_x - car_width * 0.30, car_bottom + car_height * 0.025)
		]),
		Color(0.06, 0.05, 0.10, 0.58)
	)
	draw_rect(Rect2(car_center_x - car_width * 0.51, car_top + car_height * 0.52, car_width * 0.13, car_height * 0.35), CAR_TIRE_COLOR)
	draw_rect(Rect2(car_center_x + car_width * 0.38, car_top + car_height * 0.52, car_width * 0.13, car_height * 0.35), CAR_TIRE_COLOR)
	draw_rect(Rect2(car_center_x - car_width * 0.38, car_top + car_height * 0.45, car_width * 0.76, car_height * 0.06), Color("#4b2330"))
	draw_rect(Rect2(car_center_x - car_width * 0.45, car_top + car_height * 0.41, car_width * 0.12, car_height * 0.045), CAR_BODY_COLOR)
	draw_rect(Rect2(car_center_x + car_width * 0.33, car_top + car_height * 0.41, car_width * 0.12, car_height * 0.045), CAR_BODY_COLOR)

	# Carrocería ancha, con guardabarros y cintura baja.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(car_center_x - car_width * 0.50, car_bottom),
			Vector2(car_center_x - car_width * 0.47, car_top + car_height * 0.59),
			Vector2(car_center_x - car_width * 0.34, car_top + car_height * 0.37),
			Vector2(car_center_x - car_width * 0.20, car_top + car_height * 0.10),
			Vector2(car_center_x + car_width * 0.20, car_top + car_height * 0.10),
			Vector2(car_center_x + car_width * 0.34, car_top + car_height * 0.37),
			Vector2(car_center_x + car_width * 0.47, car_top + car_height * 0.59),
			Vector2(car_center_x + car_width * 0.50, car_bottom)
		]),
		CAR_BODY_COLOR
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(car_center_x - car_width * 0.48, car_bottom),
			Vector2(car_center_x - car_width * 0.43, car_top + car_height * 0.70),
			Vector2(car_center_x + car_width * 0.43, car_top + car_height * 0.70),
			Vector2(car_center_x + car_width * 0.48, car_bottom)
		]),
		Color("#ab2434")
	)

	# Luneta, nervio central y brillo de pintura.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(car_center_x - car_width * 0.19, car_top + car_height * 0.15),
			Vector2(car_center_x + car_width * 0.19, car_top + car_height * 0.15),
			Vector2(car_center_x + car_width * 0.30, car_top + car_height * 0.43),
			Vector2(car_center_x - car_width * 0.30, car_top + car_height * 0.43)
		]),
		CAR_WINDOW_COLOR
	)
	draw_line(Vector2(car_center_x, car_top + car_height * 0.16), Vector2(car_center_x, car_top + car_height * 0.92), CAR_HIGHLIGHT_COLOR, maxf(2.0, car_width * 0.025))
	draw_line(Vector2(car_center_x - car_width * 0.31, car_top + car_height * 0.53), Vector2(car_center_x + car_width * 0.31, car_top + car_height * 0.53), CAR_HIGHLIGHT_COLOR, maxf(2.0, car_width * 0.025))

	# Pilotos, matrícula y difusor oscuro.
	draw_rect(Rect2(car_center_x - car_width * 0.40, car_top + car_height * 0.66, car_width * 0.16, car_height * 0.075), CAR_LIGHT_COLOR)
	draw_rect(Rect2(car_center_x + car_width * 0.24, car_top + car_height * 0.66, car_width * 0.16, car_height * 0.075), CAR_LIGHT_COLOR)
	draw_rect(Rect2(car_center_x - car_width * 0.12, car_top + car_height * 0.72, car_width * 0.24, car_height * 0.07), Color("#f1dca2"))
	draw_rect(Rect2(car_center_x - car_width * 0.30, car_bottom - car_height * 0.08, car_width * 0.60, car_height * 0.045), Color("#272333"))
