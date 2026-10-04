shader_type canvas_item;
render_mode unshaded, blend_add;

uniform float brightness : hint_range(0.0, 1.5, 0.01) = 0.72;
uniform float flicker_amount : hint_range(0.0, 0.30, 0.01) = 0.10;
uniform float flicker_speed : hint_range(0.0, 4.0, 0.01) = 1.10;

void fragment() {
	vec4 glow = texture(TEXTURE, UV);
	float time = TIME * flicker_speed;

	// Several gentle waves produce irregular firelight without hard jumps.
	float variation = (
		sin(time * 1.00)
		+ sin(time * 1.73 + 1.40) * 0.45
		+ sin(time * 2.41 + 0.35) * 0.22
	) / 1.67;

	float intensity = brightness * (1.0 + variation * flicker_amount);
	COLOR = vec4(glow.rgb * intensity, glow.a * intensity);
}
