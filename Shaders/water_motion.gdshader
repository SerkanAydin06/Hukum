shader_type canvas_item;
render_mode unshaded;

uniform sampler2D water_mask : filter_linear, repeat_disable;

uniform float wave_strength : hint_range(0.0, 0.005, 0.0001) = 0.0011;
uniform float wave_speed : hint_range(0.0, 2.0, 0.01) = 0.40;
uniform float wave_scale : hint_range(10.0, 150.0, 1.0) = 72.0;
uniform float shimmer_amount : hint_range(0.0, 0.1, 0.001) = 0.018;

uniform vec4 shimmer_color : source_color =
	vec4(0.62, 0.43, 0.22, 1.0);

varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	vec2 uv = UV;

	// Maskenin kırmızı kanalı yeterlidir.
	float mask = texture(water_mask, uv).r;

	// Birbirinden farklı üç yumuşak dalga.
	float horizontal_wave =
		sin(uv.x * wave_scale + TIME * wave_speed);

	float vertical_wave =
		sin(uv.y * wave_scale * 0.55
		- TIME * wave_speed * 0.73);

	float diagonal_wave =
		sin((uv.x + uv.y) * wave_scale * 0.42
		+ TIME * wave_speed * 0.45);

	vec2 movement = vec2(
		horizontal_wave + diagonal_wave * 0.35,
		vertical_wave + diagonal_wave * 0.25
	);

	// Hareket yalnızca beyaz maskeli alanda uygulanır.
	vec2 distorted_uv = uv + movement * wave_strength * mask;

	// Görsel sınırının dışından örnek alınmasını önler.
	distorted_uv = clamp(
		distorted_uv,
		vec2(0.001),
		vec2(0.999)
	);

	vec4 original_color = texture(TEXTURE, uv);
	vec4 water_color = texture(TEXTURE, distorted_uv);

	// Hafif gün batımı yansıması.
	float shimmer =
		(horizontal_wave * 0.5 + 0.5)
		* (vertical_wave * 0.5 + 0.5)
		* shimmer_amount
		* mask;

	water_color.rgb += shimmer_color.rgb * shimmer;

	// Orijinal deniz ile hareketli denizi biraz karıştırır.
	water_color.rgb = mix(
		original_color.rgb,
		water_color.rgb,
		0.85
	);

	// Siyah maskeli alanlar tamamen şeffaf kalır.
	COLOR = vec4(
		water_color.rgb,
		original_color.a * mask
	) * vertex_tint;
}