shader_type spatial;
uniform sampler2D texture_albedo : hint_albedo;
uniform vec4 _Color : hint_color = vec4(1.0);
uniform sampler2D flowmap : hint_black;
uniform float _UJump : hint_range(0, 0.25) = 0.25;
uniform float _VJump : hint_range(0, 0.25) = 0.25;
uniform float _Tiling = 1.0;
uniform float _Speed = 1.0; 
uniform float _Flow_Strength = 1.0;
uniform float _Flow_Offset : hint_range(-0.5, 0.5) = 0.0;
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
	
	vec2 flowVector = texture(flowmap, UV).rg * 2.0 - 1.0;
	flowVector *= _Flow_Strength;
	float noise = texture(flowmap, UV).a;
	float time = TIME * _Speed + noise;
	vec2 jump = vec2(_UJump, _VJump);
	
	// switching between two distorted textures to exclude black parts
	vec3 uvwA = flowUVW(UV, flowVector, jump, _Flow_Offset, _Tiling, time, false);
	vec3 uvwB = flowUVW(UV, flowVector, jump, _Flow_Offset, _Tiling, time, true);
	
	vec4 texA = texture(texture_albedo, uvwA.xy) * uvwA.z;
	vec4 texB = texture(texture_albedo, uvwB.xy) * uvwB.z;
	
	vec4 c = (texA + texB) * _Color;
	
	
	vec3 normalA = texture(_NormalMap, uvwA.xy).rgb * uvwA.z;
	vec3 normalB = texture(_NormalMap, uvwB.xy).rgb * uvwB.z;
	NORMAL = normalize(normalA + normalB);
	
	
	ALBEDO = c.rgb;
}
