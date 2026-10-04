shader_type canvas_item;
render_mode unshaded;

uniform vec2 oval_merkezi = vec2(0.5, 0.5);

/*
V3 ince çerçeve için ayarlanmıştır.
Maske, çerçevenin altına girerek boşluk oluşmasını engeller.
*/
uniform vec2 oval_yaricapi = vec2(0.143, 0.175);

uniform float kenar_yumusakligi : hint_range(0.001, 0.02) = 0.004;

void fragment() {
	vec4 portre = texture(TEXTURE, UV);

	vec2 oval_konumu = (
		UV - oval_merkezi
	) / oval_yaricapi;

	float oval_uzakligi = length(oval_konumu);

	float oval_maske = 1.0 - smoothstep(
		1.0 - kenar_yumusakligi,
		1.0,
		oval_uzakligi
	);

	portre.a *= oval_maske;

	COLOR = portre;
}