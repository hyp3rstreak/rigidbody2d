extends Camera2D

@export var max_lead_distance := 140.0
@export var lead_strength := 0.6
@export var lead_smoothing := 10.0

var lead_offset := Vector2.ZERO

func _physics_process(delta: float) -> void:
	var ship := get_parent() as RigidBody2D
	if ship == null:
		return

	# Camera stays locked to ship position
	global_position = ship.global_position

	var velocity := ship.linear_velocity
	var speed := velocity.length()

	var target_offset := Vector2.ZERO
	if speed > 1.0:
		target_offset = velocity.normalized() * min(speed * lead_strength, max_lead_distance)

	# Smooth ONLY the offset
	lead_offset = lead_offset.lerp(target_offset, delta * lead_smoothing)
	offset = lead_offset
