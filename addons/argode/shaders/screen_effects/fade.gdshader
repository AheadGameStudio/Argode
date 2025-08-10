// fade.gdshader
// Argode v2: フェード効果
shader_type canvas_item;

uniform float fade_amount : hint_range(0.0, 1.0) = 1.0;
uniform vec4 fade_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	
	// フェード効果を適用
	COLOR = mix(fade_color, original, fade_amount);
}