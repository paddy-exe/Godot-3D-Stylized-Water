shader_type spatial;
render_mode depth_draw_alpha_prepass;

// standard stuff -> can be deleted later
uniform float _Metallic : hint_range(0.0, 1.0) = 0.0;
uniform float _Smoothness : hint_range(0.0, 1.0) = 0.0;


uniform sampler2D texture_albedo : hint_albedo;
uniform vec4 _Color : hint_color = vec4(1.0);
uniform sampler2D flowmap : hint_black;
uniform float _UJump : hint_range(0, 0.25) = 0.25;
uniform float _VJump : hint_range(0, 0.25) = 0.25;
uniform float _Tiling = 1.0;
uniform float _Speed = 1.0; 
uniform float _Flow_Strength = 1.0;
uniform float _Flow_Offset : hint_range(-0.5, 0.5) = 0.0;

const float _HeightScale = 1.0;
uniform float _HeightScaleModulated = 0.75;
uniform sampler2D _DerivHeightMap : hint_black;

//Normalmap
uniform sampler2D _NormalMap : hint_normal;

uniform vec3 uv1_scale;

// alpha
uniform float alpha : hint_range(0.0, 1.0) = 0.0;
uniform float beer_factor : hint_range(-5.0, 5.0) = 0.0;


// finding the depth
vec3 ColorBelowWater(sampler2D depth_tex, vec2 screen_uv, mat4 proj_matrix, vec3 vertex, float beer_fac) {
	// depth calculation
	float depth = texture(depth_tex, screen_uv).r;
	depth = depth * 2.0 - 1.0;
	depth = proj_matrix[3][2] / (depth + proj_matrix[2][2]);
	depth = depth + vertex.z;
	depth = exp(-depth * beer_fac);
	depth = 1.0 - depth;
	return vec3(0.0);
}


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
	
	vec3 flow = texture(flowmap, UV).rgb;
	flow.xy = flow.xy * 2.0 - 1.0;
	flow *= _Flow_Strength;
	
	float noise = texture(flowmap, UV).a;
	float time = TIME * _Speed + noise;
	vec2 jump = vec2(_UJump, _VJump);
	
	// switching between two distorted textures to exclude black parts
	vec3 uvwA = flowUVW(UV, flow.xy, jump, _Flow_Offset, _Tiling, time, false);
	vec3 uvwB = flowUVW(UV, flow.xy, jump, _Flow_Offset, _Tiling, time, true);
	
	vec4 texA = texture(texture_albedo, uvwA.xy) * uvwA.z;
	vec4 texB = texture(texture_albedo, uvwB.xy) * uvwB.z;
	
	vec4 c = (texA + texB) * _Color;
	
	float finalHeightScale = flow.z * _HeightScaleModulated + _HeightScale;
	
	vec3 dhA = UnpackDerivativeHeight(texture(_DerivHeightMap, uvwA.xy)) * (uvwA.z * finalHeightScale);
	vec3 dhB = UnpackDerivativeHeight(texture(_DerivHeightMap, uvwB.xy)) * (uvwB.z * finalHeightScale);
	
	NORMAL = normalize(vec3(-(dhA.xy + dhB.xy), 1.0));
	
	
	ALBEDO = c.rgb;
	
	// refraction
	ALBEDO = ColorBelowWater(DEPTH_TEXTURE, SCREEN_UV, PROJECTION_MATRIX, VERTEX, beer_factor);
	ALPHA = alpha;
	METALLIC = _Metallic;
	ROUGHNESS = _Smoothness;
}
