extends RigidBody2D

@export var trail_lengthR := 200
@export var trail_lengthL := 200
#@export var trail_fade := 0.0
@onready var thrusterTrailRight: Line2D = $thrusterTrailRight
@onready var thrusterTrailLeft: Line2D = $thrusterTrailLeft
@onready var thrusterRight: Marker2D = $thrusterRight
@onready var thrusterLeft: Marker2D = $thrusterLeft
@onready var canInput := true
@export var thrust_force := 500.0
@export var torque_force := 500.0
@export var debug_scale := 60
@onready var planet: StaticBody2D = $"../planet"
var angular_stiffness := 1.5
var angular_blend := 3
enum MotionMode {
	NEWTONIAN,
	CINEMATIC_ORBIT
}
enum engineTrails {
	CW,
	CCW,
	EQUAL
}
var currTrailState := engineTrails.EQUAL
var newTrailState := currTrailState
var motion_mode := MotionMode.NEWTONIAN
@export var desired_orbit_speed := 300
var orbit_blend := 100


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if motion_mode == MotionMode.CINEMATIC_ORBIT:
		#set_orbit_trails(engineTrails.CW)
		newTrailState = engineTrails.CW
		var to_planet = (planet.global_position - global_position)
		var radial = to_planet.normalized()
		var tangent = radial.rotated(-PI / 2)
		if state.linear_velocity.dot(tangent) < 0:
			#print("CCW")
			newTrailState = engineTrails.CCW
			tangent = -tangent
		if newTrailState != currTrailState:
			currTrailState = newTrailState
			set_orbit_trails(currTrailState)
		var target_velocity = tangent * desired_orbit_speed
		# Convert velocity to local space
		#var local_velocity = to_local(global_position + linear_velocity)
		state.linear_velocity = state.linear_velocity.lerp(
			target_velocity,
			orbit_blend * state.step
		)
		
		var target_angle = tangent.angle() + PI / 2
		var angle_error = wrapf(target_angle - rotation, -PI, PI)

		state.angular_velocity = lerp(
			state.angular_velocity,
			angle_error * angular_stiffness,
			angular_blend * state.step
		)
		
	else:
		pass

func _physics_process(delta: float) -> void:
	# add current position
	thrusterTrailRight.add_point(thrusterRight.global_position)
	thrusterTrailLeft.add_point(thrusterLeft.global_position)
	#print(thrusterRight.global_position)
	# limit length
	while thrusterTrailRight.points.size() > trail_lengthR:
		thrusterTrailRight.remove_point(0)
		print("THRUSTER R: remove point - ",thrusterTrailRight.points.size()," points rem - trail_lengthR=", trail_lengthR)
	while thrusterTrailLeft.points.size() > trail_lengthL:
		thrusterTrailLeft.remove_point(0)
		print("THRUSTER L: remove point - ",thrusterTrailLeft.points.size()," points rem - trail_lengthL=", trail_lengthL)

	#print(thrusterTrailRight.points.size())
	# fade
	#thrusterTrailRight.default_color = Color(0.49, 0.693, 0.921, 0.4)
	#thrusterTrailLeft.default_color = Color(0.49, 0.693, 0.921, 0.4)

	#print(linear_velocity.length())
	#queue_redraw()
	
	#print("L: ",trail_lengthL," R: ",trail_lengthR)
	
	if canInput:
		# Rotation
		if Input.is_action_pressed("rotLeft"):
			#print("left")
			apply_torque(-torque_force)

		if Input.is_action_pressed("rotRight"):
			#print("right")
			apply_torque(torque_force)

		# Forward thrust
		if Input.is_action_pressed("thrust"):
			#var forward := Vector2.RIGHT.rotated(rotation)
			var forward = -transform.y
			#print(forward)
			apply_force(forward * thrust_force)


func set_motion_mode(new_mode: MotionMode) -> void:
	if motion_mode == new_mode:
		return

	motion_mode = new_mode

	if motion_mode == MotionMode.NEWTONIAN:
		canInput = true
		currTrailState = engineTrails.EQUAL
		set_orbit_trails(currTrailState)
	if motion_mode == MotionMode.CINEMATIC_ORBIT:
		canInput = false


func set_orbit_trails(state) -> void:
	if state == engineTrails.CCW:
		trail_lengthL = 150
		trail_lengthR = 200
	elif state == engineTrails.CW:
		trail_lengthR = 150
		trail_lengthL = 200
	elif state == engineTrails.EQUAL:
		trail_lengthL = 200
		trail_lengthR = 200

#func _draw():
	#if not planet:
		#return
#
	#var to_planet = (planet.global_position - global_position)
	#var radial = to_planet.normalized() 
	#var tangent = radial.rotated(-PI / 2)
#
	##print(to_planet)
#
	## Convert velocity to local space
	##var local_velocity = to_local(global_position + linear_velocity) 
	#var local_velocity2 = linear_velocity.rotated(-global_rotation)
	#var local_radial = radial.rotated(-global_rotation)
	#var local_tangent = tangent.rotated(-global_rotation)	
	##print(local_velocity2," - ",local_radial," - ", local_tangent)
#
#
	#draw_line(Vector2.ZERO, local_radial * debug_scale, Color.RED, 2)
	#draw_line(Vector2.ZERO, local_tangent * debug_scale, Color.GREEN, 2)
	##draw_line(Vector2.ZERO, local_velocity, Color.BLUE, 2)
	#draw_line(Vector2.ZERO, local_velocity2, Color.CYAN, 2)
