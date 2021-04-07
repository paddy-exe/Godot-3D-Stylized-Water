shader_type spatial;

render_mode depth_draw_always, cull_disabled, unshaded;

uniform float beer_law_factor = 2.0;
uniform float _distance = 0.0;

uniform vec4 shallow_water: hint_color;
uniform vec4 deep_water: hint_color;

// movement
uniform float refraction_speed = 0.0;
uniform float refraction_scale = 1.0;
uniform float refraction_strength = 1.0;

uniform sampler2D gradient_noise;

vec3 movement(float time, float speed, float scale, sampler2D noise_uv, vec2 uv) {
	
	vec2 uv_movement = uv;
	uv_movement += speed * (time * vec2(1.0, 1.0));
	
	vec4 tex = texture(noise_uv, uv_movement);
	//uv_tex += speed * time;
	tex *= scale;
	
	return tex;
}

float calc_depth_fade(sampler2D depth_tex, vec2 screen_uv, mat4 projection_matrix, 
						vec4 fragcoord, float beer_factor, float __distance, vec3 vertex) {
	
	float scene_depth = textureLod(depth_tex, screen_uv, 0.0).r;

	scene_depth = scene_depth * 2.0 - 1.0;
	scene_depth = projection_matrix[3][2] / (scene_depth + projection_matrix[2][2]);
	scene_depth = scene_depth + vertex.z; // z is negative
	
	// beers law
	scene_depth = exp(-scene_depth * beer_factor);
	
	float screen_depth = fragcoord.z;
	
	float depth_fade = (scene_depth - screen_depth) / __distance;
	
	depth_fade = clamp(depth_fade, 0.0, 1.0);
	
	return depth_fade;
}

void fragment() {
	float depth_fade = calc_depth_fade(DEPTH_TEXTURE, SCREEN_UV, PROJECTION_MATRIX,
									FRAGCOORD, beer_law_factor, _distance, VERTEX);
	
	vec4 gradient = mix(shallow_water, deep_water, depth_fade);
	
	ALBEDO = gradient.rgb;
}


