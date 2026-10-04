shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float brightness : hint_range(0.0, 1.5, 0.01) = 0.48;
uniform float motion_speed : hint_range(0.0, 2.0, 0.01) = 0.28;
uniform float horizontal_motion : hint_range(0.0, 0.005, 0.0001) = 0.0012;
uniform float shimmer_amount : hint_range(0.0, 0.25, 0.01) = 0.06;

void fragment() {
	vec2 moved_uv = UV;
	float time = TIME * motion_speed;

	float broad_wave = sin(UV.y * 6.283185 * 38.0 + time);
	float fine_wave = sin(UV.y * 6.283185 * 71.0 - time * 1.43) * 0.38;
	moved_uv.x += (broad_wave + fine_wave) * horizontal_motion;

	vec4 reflection = texture(TEXTURE, moved_uv);
	float shimmer = sin(
		TIME * 0.55 + UV.x * 6.283185 * 8.0 + UV.y * 6.283185 * 5.0
	);
	float intensity = brightness * (1.0 + shimmer * shimmer_amount);

	COLOR = vec4(
		reflection.rgb * intensity,
		reflection.a * intensity
	);
}
