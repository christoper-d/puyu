shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Dither & Quantization
uniform float color_depth : hint_range(8.0, 64.0, 1.0) = 32.0;
uniform float dither_amount : hint_range(0.0, 1.0, 0.01) = 0.40;

// Analog Film Grain
uniform float grain_amount : hint_range(0.0, 0.15, 0.005) = 0.030;
uniform float grain_speed : hint_range(0.0, 30.0, 1.0) = 12.0;

// Andean Atmosphere Color Grading
uniform vec3 tint_color : source_color = vec3(0.85, 0.90, 0.97);
uniform float tint_strength : hint_range(0.0, 1.0, 0.05) = 0.18;
uniform float contrast : hint_range(0.5, 2.0, 0.02) = 1.06;
uniform float saturation : hint_range(0.0, 1.5, 0.05) = 0.80;

// Bayer 4x4 ordered dithering matrix
const mat4 BAYER_4X4 = mat4(
	vec4( 0.0,  8.0,  2.0, 10.0) / 16.0,
	vec4(12.0,  4.0, 14.0,  6.0) / 16.0,
	vec4( 3.0, 11.0,  1.0,  9.0) / 16.0,
	vec4(15.0,  7.0, 13.0,  5.0) / 16.0
);

float pseudo_random(vec2 uv, float seed) {
	return fract(sin(dot(uv + vec2(seed * 0.123), vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec4 raw_color = texture(screen_texture, SCREEN_UV);
	vec3 col = raw_color.rgb;

	// 1. Analog CRT / sensor noise (Silent Hill style grain)
	float t = floor(TIME * grain_speed);
	float noise = (pseudo_random(SCREEN_UV, t) - 0.5) * 2.0;
	col += noise * grain_amount;

	// 2. Andean mountain color grading: contrast and desaturation
	col = pow(max(col, vec3(0.0)), vec3(contrast));
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(lum), col, saturation);
	col = mix(col, col * tint_color, tint_strength);

	// 3. Ordered Bayer dithering
	ivec2 coord = ivec2(FRAGCOORD.xy) % 4;
	float dither = BAYER_4X4[coord.x][coord.y] - 0.5;
	col += (dither * dither_amount) / color_depth;

	// 4. Color depth quantization (16-bit VRAM simulation)
	col = floor(col * color_depth + 0.5) / color_depth;
	col = clamp(col, 0.0, 1.0);

	COLOR = vec4(col, raw_color.a);
}
