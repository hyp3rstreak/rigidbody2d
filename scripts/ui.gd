extends CanvasLayer
enum MotionMode {
	NEWTONIAN,
	CINEMATIC_ORBIT
}
@onready var player_ship: RigidBody2D = $"../playerShip"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_toggled(toggled_on: bool) -> void:
	print(toggled_on)
	if toggled_on:
		player_ship.motion_mode = MotionMode.CINEMATIC_ORBIT
	else:
		player_ship.motion_mode = MotionMode.NEWTONIAN
