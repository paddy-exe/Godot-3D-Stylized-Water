shader_type spatial;

uniform vec4 surface_color : hint_color; 

uniform float beer_factor = 0.1;
uniform float absorption_strength = 0.1;



void fragment() {
	vec4 screen_tex = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	vec3 underwater_color = screen_tex.rgb * surface_color.rgb;
	
	//ALBEDO = surface_color.rgb;
	
	//ALBEDO = underwater_color;
	
	// depth calculation
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	depth = depth * 2.0 - 1.0;
	depth = PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
	depth = depth + VERTEX.z;
	depth = exp(-depth * beer_factor);
	depth = 1.0 - depth;
	
	vec3 absorption_color = vec3(1.0, 1.0, 1.0) - surface_color.rgb;
	float absorption_val = 1.0 - exp2(-absorption_strength * depth);
	vec3 subtractive_color = absorption_color * absorption_val;
	
	//ALBEDO = subtractive_color;
	
	vec3 absorbed_color = screen_tex.rgb - subtractive_color;
	
	ALBEDO = absorbed_color + surface_color.rgb;
	ALPHA = surface_color.a;
	
	
	
}



