// grayscale.gdshader
// Argode v2: グレースケール効果
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	
	// 輝度計算（人間の視覚特性に基づいた重み付け）
	float luminance = dot(original.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grayscale = vec3(luminance);
	
	// 強度に応じてオリジナルとグレースケールをミックス
	COLOR = vec4(mix(original.rgb, grayscale, intensity), original.a);
}