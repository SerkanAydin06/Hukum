shader_type canvas_item;
render_mode unshaded;

uniform float speed : hint_range(0.0, 2.0, 0.01) = 0.32;
uniform float horizontal_strength : hint_range(0.0, 0.04, 0.001) = 0.010;
uniform float vertical_strength : hint_range(0.0, 0.03, 0.001) = 0.005;
uniform float fold_frequency : hint_range(0.5, 5.0, 0.1) = 1.8;

void fragment() {
	vec2 moved_uv = UV;

	// The cloth begins after the transparent left margin.
	// Keep the leather loops pinned and increase motion toward the free edge.
	float free_edge = smoothstep(0.14, 0.88, UV.x);
	float phase = TIME * speed * 6.283185;

	float broad_fold = sin(
		UV.y * 6.283185 * fold_frequency + phase
	);
	float small_fold = sin(
		UV.y * 6.283185 * (fold_frequency * 2.35) - phase * 1.27
	) * 0.30;

	moved_uv.x -= (broad_fold + small_fold) * horizontal_strength * free_edge;
	moved_uv.y += sin(
		UV.x * 6.283185 * 1.45 - phase * 0.72
	) * vertical_strength * free_edge;

	COLOR = texture(TEXTURE, moved_uv);
}
