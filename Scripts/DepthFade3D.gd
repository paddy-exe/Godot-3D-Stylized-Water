#DepthFade3D.gd
tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeDepthFade3D

func _get_name():
	return "DepthFade3D"

func _get_category():
	return "Depth"

func _get_description():
	return "DepthFade VisualShader node for depth-fading in e.g. water"

#func _get_return_icon_type():
#	return VisualShaderNode.PORT_TYPE_VECTOR
	
func _get_input_port_count():
	return 7

func _get_input_port_name(port):
	match port:
		0:
			return "depth_texture"
		1:
			return "screen_uv"
		2:
			return "projection_matrix"
		3:
			return "fragcoord"
		4:
			return "vertex"
		5:
			return "beerFactor"
		6:
			return "Distance"

func _get_input_port_type(port):
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_SAMPLER
		1:
			return VisualShaderNode.PORT_TYPE_VECTOR
		2:
			return VisualShaderNode.PORT_TYPE_TRANSFORM
		3:
			return VisualShaderNode.PORT_TYPE_VECTOR
		4:
			return VisualShaderNode.PORT_TYPE_VECTOR
		5:
			return VisualShaderNode.PORT_TYPE_SCALAR
		6:
			return VisualShaderNode.PORT_TYPE_SCALAR

func _get_output_port_count():
	return 1

func _get_output_port_name(port):
	return "depth_fade"

func _get_output_port_type(port):
	return VisualShaderNode.PORT_TYPE_SCALAR

func _get_global_code(mode):
	return """
	
		float calc_depth_fade(sampler2D depth_tex, vec2 screen_uv, mat4 projection_matrix, 
						vec3 fragcoord, vec3 vertex, float beerFactor, float Distance) {
	
			float scene_depth = textureLod(depth_tex, screen_uv, 0.0).r;
			
			scene_depth = scene_depth * 2.0 - 1.0;
			scene_depth = projection_matrix[3][2] / (scene_depth + projection_matrix[2][2]);
			scene_depth = scene_depth + vertex.z; // z is negative
			
			// beers law
			scene_depth = exp(-scene_depth * beerFactor);
			
			float screen_depth = fragcoord.z;
			
			float depth_fade = (scene_depth - screen_depth) / Distance;
			
			depth_fade = clamp(depth_fade, 0.0, 1.0);
			
			return depth_fade;
		}
	
		
	"""

func _get_code(input_vars, output_vars, mode, type):
	return "%s = calc_depth_fade(%s, %s.xy, %s, %s, %s, %s, %s);" % [output_vars[0], input_vars[0], input_vars[1], input_vars[2], input_vars[3], input_vars[4], input_vars[5], input_vars[6]]

