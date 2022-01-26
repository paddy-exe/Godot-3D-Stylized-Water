shader_type spatial;
render_mode cull_disabled;

uniform vec4 surface_color : hint_color; 

uniform float beer_factor = 0.1;
uniform float absorption_strength = 0.1;

// NORMALS
uniform sampler2D flowmap : hint_black;
uniform float _UJump : hint_range(0, 0.25) = 0.25;
uniform float _VJump : hint_range(0, 0.25) = 0.25;
uniform float _Tiling = 1.0;
uniform float _Speed = 1.0; 
uniform float _Flow_Strength = 1.0;
uniform float _Flow_Offset : hint_range(-0.5, 0.5) = 0.0;

uniform float _HeightScale_Constant = 0.25;
uniform float _HeightScaleModulated = 0.9;
uniform sampler2D _DerivHeightMap : hint_black;

//Normalmap
uniform sampler2D _NormalMap : hint_normal;
uniform vec3 uv1_scale;

vec3 UnpackDerivativeHeight (vec4 textureData) {
	vec3 dh = textureData.agb;
	dh.xy = dh.xy * 2.0 - 1.0;
	return dh;
}

vec3 flowUVW (vec2 uv, vec2 flowVector, vec2 jump, 
		float flowOffset, float tiling, float time, bool flowB) {
	float phaseOffset = flowB ? 0.5 : 0.0;
	// Sawtooth/Zic-Zack pattern of time by using fract
	float progress = fract(time + phaseOffset);
	vec3 uvw;
	uvw.xy = uv - flowVector * (progress + flowOffset);
	uvw.xy *= tiling;
	uvw.xy += tiling;
	
	uvw.xy += (time - progress) * jump;
	uvw.z = 1.0 - abs(1.0 - 2.0* progress);
	return uvw;
}


void vertex() {
	UV=UV*uv1_scale.xy;
}


void fragment() {
	vec4 screen_tex = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	vec3 underwater_color = screen_tex.rgb * surface_color.rgb;
	
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
	
	vec3 absorbed_color = screen_tex.rgb - subtractive_color;
	
	
	
	// Distortion water implementation
	vec3 flow = texture(flowmap, UV).rgb;
	flow.xy = flow.xy * 2.0 - 1.0;
	flow *= _Flow_Strength;
	
	float noise = texture(flowmap, UV).a;
	float time = TIME * _Speed + noise;
	vec2 jump = vec2(_UJump, _VJump);
	
	// switching between two distorted textures to exclude black parts
	vec3 uvwA = flowUVW(UV, flow.xy, jump, _Flow_Offset, _Tiling, time, false);
	vec3 uvwB = flowUVW(UV, flow.xy, jump, _Flow_Offset, _Tiling, time, true);
	
	
	float finalHeightScale = flow.z * _HeightScaleModulated + _HeightScale_Constant;
	
	vec3 dhA = UnpackDerivativeHeight(texture(_DerivHeightMap, uvwA.xy)) * (uvwA.z * finalHeightScale);
	vec3 dhB = UnpackDerivativeHeight(texture(_DerivHeightMap, uvwB.xy)) * (uvwB.z * finalHeightScale);
	
	NORMAL = normalize(vec3(-(dhA.xy + dhB.xy), 1.0));
	
	
	// Final colors for ALBEDO and ALPHA
	ALBEDO = absorbed_color + surface_color.rgb;
	ALPHA = surface_color.a;
}
