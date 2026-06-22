extends InputComponent
class_name BossAIComponent
## Drives boss movement and attack patterns (radial burst, aimed spread, spiral).
## Fires bullets by calling entity.shootComponent.shoot() directly — never sets shoot_pressed.
## All difficulty values are computed once in _ready() from RunState.sector_t() so they
## never compound across sector reloads.

@export var entity: LivingEntity

@export_group("Timing")
@export var activation_delay: float = 1.5
@export var attack_cooldown: float = 3.5
@export var attack_cooldown_min: float = 1.2

@export_group("Movement")
@export var preferred_distance: float = 400.0
@export var strafe_speed: float = 0.8

@export_group("Radial Burst")
@export var radial_bullet_count: int = 12
@export var radial_bullet_count_max: int = 20

@export_group("Aimed Spread")
@export var spread_bullet_count: int = 5
@export var spread_bullet_count_max: int = 9
@export var spread_angle_deg: float = 50.0

@export_group("Spiral")
@export var spiral_bullet_count: int = 24
@export var spiral_bullet_count_max: int = 48
@export var spiral_interval: float = 0.07

var _activation_timer: float = 0.0
var _attack_timer: float = 0.0
var _pattern_index: int = 0

var _spiral_remaining: int = 0
var _spiral_angle: float = 0.0
var _spiral_timer: float = 0.0

var _strafe_sign: float = 1.0
var _strafe_switch_timer: float = 0.0

var _eff_attack_cooldown: float = 3.5
var _eff_radial_count: int = 12
var _eff_spread_count: int = 5
var _eff_spiral_count: int = 24


func _ready() -> void:
	_activation_timer = activation_delay
	_attack_timer = activation_delay + 0.5
	var t := RunState.sector_t()
	var tf := RunState.threat_factor()
	_eff_attack_cooldown = lerpf(attack_cooldown, attack_cooldown_min, t) / tf
	_eff_radial_count = int(round(lerpf(float(radial_bullet_count), float(radial_bullet_count_max), t)))
	_eff_spread_count = int(round(lerpf(float(spread_bullet_count), float(spread_bullet_count_max), t)))
	_eff_spiral_count = int(round(lerpf(float(spiral_bullet_count), float(spiral_bullet_count_max), t)))
	_strafe_sign = 1.0 if randf() > 0.5 else -1.0
	_strafe_switch_timer = randf_range(2.0, 4.5)


func _process(delta: float) -> void:
	if not entity:
		return
	shoot_pressed = false

	_activation_timer -= delta
	if _activation_timer > 0.0:
		move_vector = Vector2.ZERO
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		move_vector = Vector2.ZERO
		return

	_update_movement(player, delta)

	if _spiral_remaining > 0:
		_spiral_timer -= delta
		if _spiral_timer <= 0.0:
			_spiral_timer = spiral_interval
			_spiral_remaining -= 1
			if entity.shootComponent:
				entity.shootComponent.shoot(Vector2.RIGHT.rotated(_spiral_angle))
			_spiral_angle += (TAU * 2.5) / float(_eff_spiral_count)
		return

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = _eff_attack_cooldown
		_fire_pattern(_pattern_index)
		_pattern_index = (_pattern_index + 1) % 3


func _update_movement(player: Node2D, delta: float) -> void:
	var to_player := player.global_position - entity.global_position
	var dist := to_player.length()
	aim_direction = to_player.normalized() if dist > 1.0 else Vector2.RIGHT

	var approach := Vector2.ZERO
	if dist > preferred_distance * 1.2:
		approach = aim_direction
	elif dist < preferred_distance * 0.8:
		approach = -aim_direction

	_strafe_switch_timer -= delta
	if _strafe_switch_timer <= 0.0:
		_strafe_sign = -_strafe_sign
		_strafe_switch_timer = randf_range(2.0, 4.5)

	var strafe_dir := aim_direction.rotated(PI * 0.5) * _strafe_sign
	var desired := approach + strafe_dir * strafe_speed
	move_vector = desired.normalized() if desired.length() > 0.1 else Vector2.ZERO


func _fire_pattern(pattern: int) -> void:
	if not entity.shootComponent:
		return
	match pattern:
		0:  # Radial burst — ring of bullets outward
			for i in _eff_radial_count:
				var angle := TAU * float(i) / float(_eff_radial_count)
				entity.shootComponent.shoot(Vector2.RIGHT.rotated(angle))
		1:  # Aimed spread — fan toward the player
			var half_arc := deg_to_rad(spread_angle_deg * 0.5)
			for i in _eff_spread_count:
				var t_val := float(i) / float(max(_eff_spread_count - 1, 1))
				var dir := aim_direction.rotated(lerpf(-half_arc, half_arc, t_val))
				entity.shootComponent.shoot(dir)
		2:  # Spiral — multi-frame rotating stream
			_spiral_remaining = _eff_spiral_count
			_spiral_angle = randf() * TAU
			_spiral_timer = 0.0
