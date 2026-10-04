shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float brightness : hint_range(0.0, 1.5, 0.01) = 0.58;
uniform float flicker_amount : hint_range(0.0, 0.25, 0.01) = 0.07;
uniform float flicker_speed : hint_range(0.0, 3.0, 0.01) = 0.42;

float random_value(vec2 coordinate) {
	return fract(sin(dot(coordinate, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 light = texture(TEXTURE, UV);

	// One random phase per roughly 40-pixel region keeps nearby glow pixels
	// together, so individual lamps breathe instead of sparkling pixel by pixel.
	vec2 cell = floor(UV * vec2(48.0, 27.0));
	float seed = random_value(cell);
	float phase = seed * 6.283185;
	float speed_variation = mix(0.72, 1.28, seed);
	float pulse = sin(TIME * flicker_speed * speed_variation + phase);
	float intensity = brightness * (1.0 + pulse * flicker_amount);

	COLOR = vec4(light.rgb * intensity, light.a * intensity);
}
