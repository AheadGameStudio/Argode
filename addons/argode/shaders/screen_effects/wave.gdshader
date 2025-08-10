// wave.gdshader
// Argode v2: 波形歪み効果
shader_type canvas_item;

uniform float wave_amplitude : hint_range(0.0, 0.1) = 0.02;
uniform float wave_frequency : hint_range(0.1, 10.0) = 2.0;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform vec2 wave_direction = vec2(1.0, 0.0);
uniform float time_offset : hint_range(0.0, 10.0) = 0.0;

void fragment() {
	// 時間とオフセットを考慮した波形計算
	float time_factor = (TIME + time_offset) * wave_speed;
	
	// 水平・垂直波形を組み合わせ
	vec2 wave_uv = UV;
	
	if (wave_direction.x > 0.0) {
		// 水平波（縦方向に歪み）
		wave_uv.y += sin(UV.x * wave_frequency * PI + time_factor) * wave_amplitude * wave_direction.x;
	}
	
	if (wave_direction.y > 0.0) {
		// 垂直波（横方向に歪み）
		wave_uv.x += sin(UV.y * wave_frequency * PI + time_factor) * wave_amplitude * wave_direction.y;
	}
	
	// UV境界チェック
	if (wave_uv.x < 0.0 || wave_uv.x > 1.0 || wave_uv.y < 0.0 || wave_uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		COLOR = texture(TEXTURE, wave_uv);
	}
}