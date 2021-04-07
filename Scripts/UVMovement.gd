#UVMovement.gd
tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeUVMovement

func _get_name():
	return "UVMovement"

func _get_category():
	return "UV"

func _get_description():
	return "Move, scale and tile textures with time"

func _get_return_icon_type():
	return VisualShaderNode.PORT_TYPE_VECTOR
	
func _get_input_port_count():
	return 4

func _get_input_port_name(port):
	match port:
		0:
			return "time"
		1:
			return "speed"
		2:
			return "scale"
		3:
			return "uv"

func _get_input_port_type(port):
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_SCALAR
		1:
			return VisualShaderNode.PORT_TYPE_SCALAR
		2:
			return VisualShaderNode.PORT_TYPE_SCALAR
		3:
			return VisualShaderNode.PORT_TYPE_VECTOR

func _get_output_port_count():
	return 1

func _get_output_port_name(port):
	return "UVMovement"

func _get_output_port_type(port):
	return VisualShaderNode.PORT_TYPE_VECTOR

func _get_global_code(mode):
	return """
	
		vec3 movement(vec2 _uv, float time, float speed) {
			vec2 uv = _uv;
			uv.xy += time * speed;
			return vec3(uv.x, uv.y, 0.0);
		}
	
		
	"""

func _get_code(input_vars, output_vars, mode, type):
	return "%s = movement(%s, %s, %s, %s);" % [output_vars[0], input_vars[0], input_vars[1], input_vars[2], input_vars[3]]
