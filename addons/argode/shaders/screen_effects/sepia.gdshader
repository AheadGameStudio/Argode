// sepia.gdshader
// Argode v2: セピア調効果
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	
	// セピア変換行列
	vec3 sepia;
	sepia.r = dot(original.rgb, vec3(0.393, 0.769, 0.189));
	sepia.g = dot(original.rgb, vec3(0.349, 0.686, 0.168));
	sepia.b = dot(original.rgb, vec3(0.272, 0.534, 0.131));
	
	// 強度に応じてオリジナルとセピアをミックス
	COLOR = vec4(mix(original.rgb, sepia, intensity), original.a);
}