// tint.gdshader
// Argode v2: 色調調整効果
shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float tint_intensity : hint_range(0.0, 1.0) = 0.5;
uniform int blend_mode : hint_range(0, 3) = 0; // 0=Mix, 1=Add, 2=Multiply, 3=Overlay

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	vec4 final_color;
	
	// ブレンドモードに応じて処理
	if (blend_mode == 0) {
		// Mix
		final_color = mix(original, tint_color, tint_intensity);
	} else if (blend_mode == 1) {
		// Add
		final_color = original + (tint_color * tint_intensity);
	} else if (blend_mode == 2) {
		// Multiply
		final_color = original * mix(vec4(1.0), tint_color, tint_intensity);
	} else {
		// Overlay
		vec3 overlay = mix(
			2.0 * original.rgb * tint_color.rgb,
			1.0 - 2.0 * (1.0 - original.rgb) * (1.0 - tint_color.rgb),
			step(0.5, original.rgb)
		);
		final_color = vec4(mix(original.rgb, overlay, tint_intensity), original.a);
	}
	
	COLOR = final_color;
}