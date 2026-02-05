extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("enter")
		body.set_can_orbit(true, self)
		body.canOrbit = true
		body.enterOrbit()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.set_can_orbit(false, self)
