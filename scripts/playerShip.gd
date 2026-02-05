extends RigidBody2D

# =========================
# 1. ENUMS / CONSTANTS
# =========================

enum MotionMode {
	NEWTONIAN,
	CINEMATIC_ORBIT,
	DOCKING,
	UNDOCKING,
	DOCKED
}

enum EngineTrails {
	CW,
	CCW,
	EQUAL
}

# =========================
# 2. EXPORTED CONFIG (TUNABLE)
# =========================

@export var thrust_force := 500.0
@export var torque_force := 500.0
@export var desired_orbit_speed := 300

@export var trail_lengthR := 200
@export var trail_lengthL := 200

@export var debug_scale := 60

# =========================
# 3. INTERNAL TUNING (NOT EXPORTED)
# =========================

var angular_stiffness := 1.5
var angular_blend := 3.0
var orbit_blend := 100.0

# =========================
# 4. STATE
# =========================

var motion_mode: MotionMode = MotionMode.NEWTONIAN
var currTrailState: EngineTrails = EngineTrails.EQUAL
var newTrailState := currTrailState
var canInput := true
var dockRadius := 12
var undockRadius := 200
var canOrbit := false
var currOrbitZone: Area2D = null

# =========================
# 5. NODE REFERENCES
# =========================

@onready var thrusterTrailRight: Line2D = $thrusterTrailRight
@onready var thrusterTrailLeft: Line2D = $thrusterTrailLeft
@onready var thrusterRight: Marker2D = $thrusterRight
@onready var thrusterLeft: Marker2D = $thrusterLeft
@onready var planet: Area2D = null

# =========================
# 6. LIFECYCLE CALLBACKS
# =========================

func _ready() -> void:
	set_motion_mode(MotionMode.NEWTONIAN)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if motion_mode == MotionMode.UNDOCKING:
		var to_planet = planet.global_position - global_position
		var radial = (-to_planet).normalized()
		var undocking_speed := 60.0
		# 3. Rotate to face planet
		var target_angle = radial.angle() + PI / 2
		var angle_error = wrapf(target_angle - rotation, -PI, PI)

		state.angular_velocity = lerp(
			state.angular_velocity,
			angle_error * 2.0,
			3.0 * state.step
		)
		state.linear_velocity = state.linear_velocity.lerp(
			radial * undocking_speed,
			2.0 * state.step
		)
		if to_planet.length() >= undockRadius:
			state.linear_velocity = Vector2.ZERO
			state.angular_velocity = 0.0
			set_motion_mode(MotionMode.NEWTONIAN) # or left dock area
		
	if motion_mode == MotionMode.DOCKING:
		var to_planet = planet.global_position - global_position
		var radial = to_planet.normalized()

		# 1. Kill tangential velocity
		var radial_vel = state.linear_velocity.dot(radial)
		state.linear_velocity = radial * radial_vel

		# 2. Controlled inward motion
		var docking_speed := 90.0
		state.linear_velocity = state.linear_velocity.lerp(
			radial * docking_speed,
			2.0 * state.step
		)

		# 3. Rotate to face planet
		var target_angle = radial.angle() + PI / 2
		var angle_error = wrapf(target_angle - rotation, -PI, PI)

		state.angular_velocity = lerp(
			state.angular_velocity,
			angle_error * 2.0,
			3.0 * state.step
		)
		
		if to_planet.length() <= dockRadius:
			state.linear_velocity = Vector2.ZERO
			state.angular_velocity = 0.0
			set_motion_mode(MotionMode.DOCKED) # or LANDED
			
	if motion_mode == MotionMode.CINEMATIC_ORBIT:
		#set_orbit_trails(engineTrails.CW)
		newTrailState = EngineTrails.CW
		var to_planet = (planet.global_position - global_position)
		var radial = to_planet.normalized()
		var tangent = radial.rotated(-PI / 2)
		if state.linear_velocity.dot(tangent) < 0:
			#print("CCW")
			newTrailState = EngineTrails.CCW
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
		#print("THRUSTER R: remove point - ",thrusterTrailRight.points.size()," points rem - trail_lengthR=", trail_lengthR)
	while thrusterTrailLeft.points.size() > trail_lengthL:
		thrusterTrailLeft.remove_point(0)
		#print("THRUSTER L: remove point - ",thrusterTrailLeft.points.size()," points rem - trail_lengthL=", trail_lengthL)
	
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


# =========================
# 7. STATE TRANSITIONS
# =========================

func set_motion_mode(new_mode: MotionMode) -> void:
	if motion_mode == new_mode:
		return

	motion_mode = new_mode

	if motion_mode == MotionMode.NEWTONIAN:
		canInput = true
		currTrailState = EngineTrails.EQUAL
		set_orbit_trails(currTrailState)
	if motion_mode == MotionMode.CINEMATIC_ORBIT:
		canInput = false
	if motion_mode == MotionMode.DOCKING:
		canInput = false
		currTrailState = EngineTrails.EQUAL
	if motion_mode == MotionMode.DOCKED:
		canInput = false
		currTrailState = EngineTrails.EQUAL
		angular_velocity = 0.0
	if motion_mode == MotionMode.UNDOCKING:
		canInput = false
		currTrailState = EngineTrails.EQUAL
		sleeping = false


# =========================
# 8. HELPERS / UTILITIES
# =========================
func set_orbit_trails(state) -> void:
	if state == EngineTrails.CCW:
		trail_lengthL = 80
		trail_lengthR = 100
	elif state == EngineTrails.CW:
		trail_lengthR = 80
		trail_lengthL = 100
	elif state == EngineTrails.EQUAL:
		trail_lengthL = 100
		trail_lengthR = 100

func set_can_orbit(value: bool, zone: Area2D) -> void:
	canOrbit = value
	currOrbitZone = zone if value else null

func enterOrbit() -> void:
	if currOrbitZone == null:
		return

	planet = currOrbitZone.get_parent()
	set_motion_mode(MotionMode.CINEMATIC_ORBIT)
