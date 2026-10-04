shader_type canvas_item;
render_mode unshaded;

uniform float movement_pixels : hint_range(0.0, 300.0, 1.0) = 150.0;
uniform float cycle_seconds : hint_range(10.0, 300.0, 1.0) = 90.0;

varying vec4 canvas_tint;

void vertex() {
	canvas_tint = COLOR;
}

void fragment() {
	float phase = TIME * (6.28318530718 / cycle_seconds);
	float pixel_offset = sin(phase) * movement_pixels;

	vec2 shifted_uv = UV;
	shifted_uv.x += pixel_offset * TEXTURE_PIXEL_SIZE.x;

	vec4 cloud_color = vec4(0.0);

	if (shifted_uv.x >= 0.0 && shifted_uv.x <= 1.0) {
		cloud_color = texture(TEXTURE, shifted_uv);
	}

	COLOR = cloud_color * canvas_tint;
}