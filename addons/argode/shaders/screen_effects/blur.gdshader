// blur.gdshader
// Argode v2: ガウシアンブラー効果
shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 1.0;
uniform vec2 blur_direction = vec2(1.0, 1.0);
uniform bool high_quality = false;

void fragment() {
	vec2 pixel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
	vec2 blur_offset = pixel_size * blur_amount * blur_direction;
	
	vec4 color = vec4(0.0);
	
	if (high_quality) {
		// 高品質ガウシアンブラー（9サンプル）
		float weights[9] = float[](0.05, 0.09, 0.12, 0.15, 0.16, 0.15, 0.12, 0.09, 0.05);
		vec2 offsets[9] = vec2[](
			vec2(-4.0, 0.0), vec2(-3.0, 0.0), vec2(-2.0, 0.0), vec2(-1.0, 0.0),
			vec2(0.0, 0.0),
			vec2(1.0, 0.0), vec2(2.0, 0.0), vec2(3.0, 0.0), vec2(4.0, 0.0)
		);
		
		for (int i = 0; i < 9; i++) {
			vec2 sample_uv = UV + offsets[i] * blur_offset;
			color += texture(TEXTURE, sample_uv) * weights[i];
		}
	} else {
		// 高速ブラー（5サンプル）
		float weights[5] = float[](0.1, 0.2, 0.4, 0.2, 0.1);
		vec2 offsets[5] = vec2[](
			vec2(-2.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 0.0), 
			vec2(1.0, 0.0), vec2(2.0, 0.0)
		);
		
		for (int i = 0; i < 5; i++) {
			vec2 sample_uv = UV + offsets[i] * blur_offset;
			color += texture(TEXTURE, sample_uv) * weights[i];
		}
	}
	
	COLOR = color;
}