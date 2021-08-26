shader_type spatial;
render_mode specular_phong, cull_disabled, unshaded, blend_mix;

uniform float _distance;
uniform float refraction_speed;
uniform float refraction_scale;
uniform float roughness = 0.1;
uniform sampler2D refraction_noise;
uniform sampler2D normalmap: hint_normal;

uniform vec4 shallow_color: hint_color;
uniform vec4 deep_color: hint_color;


varying flat vec3 vert_color;

//foam
uniform float edge_scale = 0.25;
uniform float foam_amount = 1.0;
uniform float foam_cutoff = 4.8;
uniform float foam_speed = 1.0;
uniform float foam_scale = 1.0;
uniform vec4 foam_color: hint_color;
uniform sampler2D foam_noise;
uniform float near = 0.1;
uniform float far = 100f;

float calc_depth_fade(float depth, mat4 inv_projection_matrix, vec2 screen_uv, 
						vec4 fragcoord, float __distance, vec3 vertex) {

	vec4 upos = inv_projection_matrix * vec4(screen_uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);

	
	float scene_depth = upos.a;
	
	float screen_depth = fragcoord.z;
	
	float depth_fade = (scene_depth - screen_depth) / __distance;
	
	// Saturation
	depth_fade = clamp(depth_fade, 0.0, 1.0);
	
	return depth_fade;
}

float rim(float depth) {
	depth = 2f * depth - 1f;
	return near * far / (far + depth * (near - far));
}

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void vertex() {
	vert_color = COLOR.rgb;
}

void fragment() {
	
	float time = TIME * refraction_speed;
	
	float z_depth = rim(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float z_pos = rim(FRAGCOORD.z);
	float diff = (z_depth - z_pos)/_distance;
	
	diff = clamp(diff, 0.0,1.0);
	
	vec4 fade_color = mix(shallow_color, deep_color, diff);
	
	vec3 transparent_fade = mix(vert_color.rgb, fade_color.rgb, fade_color.a);
	
	// refraction
	vec3 noise_uv = texture(refraction_noise, UV + time).rgb;
	
	noise_uv *= refraction_scale;
	
	float noise_value = noise_uv.r;
	
	vec2 uv_movement = UV * 4f;
	uv_movement += TIME * refraction_speed * 4f;
	
	vec2 displacement = vec2(noise_value * 0.1);
	diff += displacement.x * 70f;
	
	vec4 col = mix(foam_color, vec4(transparent_fade, 1.0), step(edge_scale, diff));
	
	vec4 alpha = texture(SCREEN_TEXTURE, SCREEN_UV + displacement);
	
	
	//foam	
	float foam_time = TIME * foam_speed;
	
	vec3 foam_uv = texture(foam_noise, UV + foam_time).rgb;
	foam_uv *= foam_scale;
	
	float foam = rim(foam_amount) * 0.5;
	foam *= foam_cutoff;
	
	foam = step(foam, foam_uv.r);
	foam *= foam_color.a;
	
	vec3 foam_water = mix(transparent_fade, foam_color.rgb, foam);
	
	
	float fin = 0.0;
	if (noise_value > 0.0 && noise_value < 0.4) fin = 0.1;
	if (noise_value > 0.4 && noise_value < 0.8) fin = 0.0;
	if (noise_value > 0.8) fin = 1f;

	float fresnel = fresnel(foam * foam_amount * 9.0, NORMAL, VIEW);
	
	col.rgb = mix(col.rgb, foam_water, fresnel);
	
	ALBEDO = vec3(fin) + mix(alpha.rgb, col.rgb, fade_color.a);
	
	ALPHA = mix(vert_color.r, fade_color.a, fade_color.a);
	//NORMALMAP = texture(normalmap, uv_movement).rgb;
	ROUGHNESS = roughness;
}

