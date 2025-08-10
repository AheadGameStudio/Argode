// flash.gdshader
// Argode v2: スクリーンフラッシュ効果
shader_type canvas_item;

uniform float flash_intensity : hint_range(0.0, 1.0) = 1.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_time : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	
	// フラッシュ効果を適用
	float flash_amount = flash_intensity * flash_time;
	
	// フラッシュ色を適用（アルファ値は全体の不透明度を制御）
	COLOR = vec4(flash_color.rgb, flash_amount);
}