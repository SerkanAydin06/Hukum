shader_type canvas_item;

// Inspector üzerinden anında değiştirebileceğin ayarlar
uniform float hiz = 3.0;          // Rüzgarın hızı (Zaman çarpanı)
uniform float frekans = 6.0;      // Dalgaların sıklığı
uniform float genlik = 0.03;      // Dalgalanma şiddeti
uniform bool ustten_asili = true; // Flama üstten mi yoksa soldan mı asılı?

void fragment() {
	vec2 hareketli_uv = UV;

	if (ustten_asili) {
		// Flama üstten direğe bağlıysa
		hareketli_uv.x += sin(TIME * hiz + UV.y * frekans) * genlik * UV.y;
	} else {
		// Flama soldan direğe bağlıysa
		hareketli_uv.y += sin(TIME * hiz + UV.x * frekans) * genlik * UV.x;
	}

	// 🟢 BEYAZ IŞIK/ÇİZGİ HATASINI ÇÖZEN KISIM:
	// Eğer dalgalanma resmin dışına taşıyorsa, o kısmı görünmez (şeffaf) yap
	if (hareketli_uv.x < 0.0 || hareketli_uv.x > 1.0 || hareketli_uv.y < 0.0 || hareketli_uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		COLOR = texture(TEXTURE, hareketli_uv);
	}
}