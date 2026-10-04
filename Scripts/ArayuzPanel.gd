extends Node
class_name ArayuzPanel

var arayuz: Node
var ana: Node
var aktif_sekme = "insa"

func baslat(_arayuz):
	arayuz = _arayuz
	ana = arayuz.ana
	call_deferred("_paneli_hazirla")

func _paneli_hazirla():
	if arayuz.savas_deste_btn and arayuz.insa_deste_btn:
		arayuz.savas_deste_btn.pressed.connect(func(): sekme_degistir("savas"))
		arayuz.insa_deste_btn.pressed.connect(func(): sekme_degistir("insa"))
		sekme_degistir("insa")

func yukari_cik():
	pass

func zorla_asagi_indir():
	ana.kart_insa_modu_aktif = false 
	ana.secili_kart_index = -1 
	if ana.harita: ana.harita.queue_redraw()
	
	# İnşa ve Savaş panellerindeki seçimleri temizle
	if arayuz.insa_kart_eli_konteyner:
		_secimleri_temizle(arayuz.insa_kart_eli_konteyner)
	if arayuz.savas_kart_eli_konteyner:
		_secimleri_temizle(arayuz.savas_kart_eli_konteyner)
		
	ana.deste._kart_gorsellerini_guncelle()

func _secimleri_temizle(konteyner):
	for wrapper in konteyner.get_children():
		var asil_kart = _asil_karti_bul(wrapper)
		if asil_kart != null and "secili_mi" in asil_kart:
			asil_kart.secili_mi = false

func sekme_degistir(sekme: String):
	aktif_sekme = sekme
	
	# Butonların basılı kalma durumlarını güncelle
	if arayuz.insa_deste_btn: arayuz.insa_deste_btn.set_pressed_no_signal(sekme == "insa")
	if arayuz.savas_deste_btn: arayuz.savas_deste_btn.set_pressed_no_signal(sekme == "savas")
	
	# Hangi sekmedeysek o açık olacak, diğeri KESİNLİKLE gizlenecek
	var insa_aktif = (sekme == "insa")
	var savas_aktif = (sekme == "savas")
	
	# Panellerin görünürlüğü
	if arayuz.insa_destesi_panel:
		arayuz.insa_destesi_panel.visible = insa_aktif
	if arayuz.savas_destesi_panel:
		arayuz.savas_destesi_panel.visible = savas_aktif
		
	# Kart konteynerlerinin görünürlüğü
	if arayuz.insa_kart_eli_konteyner:
		arayuz.insa_kart_eli_konteyner.visible = insa_aktif
	if arayuz.savas_kart_eli_konteyner:
		arayuz.savas_kart_eli_konteyner.visible = savas_aktif
		
	eldeki_kartlari_filtrele()

func eldeki_kartlari_filtrele():
	# Kartlar artık kendi özel panellerinde (Insa / Savas) ayrı ayrı çizildiği için
	# burada ekstra filtrelemeye gerek kalmadı, DesteYonetici her iki konteyneri besliyor.
	pass

func _asil_karti_bul(wrapper):
	if "kategori" in wrapper and wrapper.kategori != null: return wrapper
	for ic in wrapper.get_children():
		if "kategori" in ic and ic.kategori != null: return ic
	return null
