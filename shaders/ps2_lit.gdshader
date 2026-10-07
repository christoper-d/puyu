shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;

// Visuals
uniform vec4 albedo_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.95;

// PS2 Geometry Jitter
uniform bool jitter_enabled = true;
uniform float jitter_resolution : hint_range(64.0, 640.0, 1.0) = 280.0;
uniform float jitter_strength : hint_range(0.0, 1.0, 0.05) = 1.0;

void vertex() {
	if (jitter_enabled && jitter_strength > 0.001) {
		vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
		if (abs(clip.w) > 0.0001) {
			vec2 ndc = clip.xy / clip.w;
			vec2 snapped_ndc = floor(ndc * jitter_resolution + 0.5) / jitter_resolution;
			vec2 offset = (snapped_ndc - ndc) * jitter_strength;
			clip.xy += offset * clip.w;
			POSITION = clip;
		}
	}
}

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	ALBEDO = albedo_color.rgb * tex.rgb;
	ROUGHNESS = roughness_val;
	SPECULAR = 0.0;
}
