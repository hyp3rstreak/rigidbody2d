extends CanvasLayer

@onready var player_ship: RigidBody2D = $"../playerShip"
@onready var orbit_btn: Button = $HBoxContainer/VBoxContainer/orbitBtn
@onready var dock_btn: Button = $HBoxContainer/VBoxContainer/dockBtn
@onready var undock_btn: Button = $HBoxContainer/VBoxContainer/undockBtn


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dock_btn.disabled = true
	undock_btn.disabled = true
	orbit_btn.disabled = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# ORBIT BUTTON
func _on_orbit_btn_pressed() -> void:
	if player_ship.canOrbit:
		print("canOrbit")
		if player_ship.motion_mode == player_ship.MotionMode.NEWTONIAN:
			player_ship.set_motion_mode(player_ship.MotionMode.CINEMATIC_ORBIT)
		elif player_ship.motion_mode == player_ship.MotionMode.CINEMATIC_ORBIT:
			player_ship.set_motion_mode(player_ship.MotionMode.NEWTONIAN)
		dock_btn.disabled = false
		undock_btn.disabled = true
		orbit_btn.disabled = false
		

# DOCK BUTTON
func _on_dock_btn_pressed() -> void:
	if player_ship.motion_mode == player_ship.MotionMode.CINEMATIC_ORBIT:
		player_ship.set_motion_mode(player_ship.MotionMode.DOCKING)
	dock_btn.disabled = true
	undock_btn.disabled = false
	orbit_btn.disabled = true

# UNDOCK BUTTON
func _on_undock_btn_pressed() -> void:
	if player_ship.motion_mode == player_ship.MotionMode.DOCKED:
		player_ship.set_motion_mode(player_ship.MotionMode.UNDOCKING)
	dock_btn.disabled = true
	undock_btn.disabled = true
	orbit_btn.disabled = false
