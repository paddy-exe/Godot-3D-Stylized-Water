extends Spatial


func _process(delta):
	if $Camera.global_transform.origin.y < $WaterPlane.global_transform.origin.y:
		$UnderwaterEffect.visible = true
	else:
		$UnderwaterEffect.visible = false
