extends Node

var savas_aktif = false
var sonuc_gosteriliyor = false
var savas_hedef_turu = ""
var savas_tipi = "normal"
var savas_piyon_saldiran = -1
var savas_piyon_savunan = -1
var savas_bina_koordinat = Vector2i(-1, -1)
var savas_ozel_saldiran = "" 
var savas_ozel_savunucu = "" 
var savas_eli_paneli
var savas_eli_hbox
var secilen_savas_kartlari = {}   # yalnızca sunucuda dolar; kartlar açılana kadar gizlidir
var secilen_savas_idxleri = {}
var secilen_benim_idxler = []
var secilen_benim_kartlar = []
var secilen_benim_nodelar: Array = []
var kendi_kilitledi_mi: bool = false
var benim_slot_on_eki: String = ""
var medeniyet_savas_bonuslari = {
	"Osmanlı": "🔥 Topçu Bataryaları: Zarlar asla 1 gelmez!",
	"Bizans": "🏛️ Saray Entrikaları: 1 veya 2 zarında rakibin toplam gücü %50 azalır.",
	"Viking": "🪙 Kuzeyin Gazabı: Kazanılan savaş başına +5 Altın."
}
@onready var ana = get_parent()

# --- SAVAŞ KARTLARI RESİM EŞLEŞTİRME SÖZLÜĞÜ ---
var savas_resimleri = {
	"Piyade": "piyade", "Ağır Zırhlı Piyade": "agirpiyade", "Mızraklı Asker": "mizrakli",
	"Kısa Yaylı": "okcu", "Arbaletçi": "arbaletci", "Uzun Yaylı": "uzunyayli",
	"Hafif Süvari": "hafifsuvari", "Ağır Süvari": "agirsuvari", "Zırhlı Sipahi": "zirhlisipahi",
	"Koçbaşı": "kocbasi", "Mancınık": "mancinik", "Büyük İskender": "iskender",
	"Fatih Sultan Mehmet": "fatih", "Hannibal Barca": "hannibal", "Cengiz Han": "cengiz",
	"Ragnar Lodbrok": "lodbrok", "Leonidas": "leonidas", "Belisarius": "belisarius",
	"Thutmose III": "thutmose", "Selahaddin Eyyubi": "selahaddin", "Enrico Dandolo": "dandolo"
}

var son_savas_paneli
var savas_eli_konteyner
var insa_eli_konteyner 
var onayla_atak_btn
var onayla_defans_btn
var benim_onayla_btn
var atak_zar_at_btn
var defans_zar_at_btn
var son_kartlar_dict: Dictionary = {}
var zar_saldiran_deger: int = -1
var zar_savunan_deger: int = -1
var saldiran_kart_gucu_hesap: int = 0
var savunan_kart_gucu_hesap: int = 0

func _ready():
	call_deferred("_baslangicta_gizle")

func _baslangicta_gizle():
	var panel = get_node_or_null("../ArayuzYonetici")
	if panel:
		var s_paneli = panel.get_node_or_null("%SavasEliPaneli")
		if s_paneli: s_paneli.visible = false

func _referanslari_al():
	if not ana or not ana.arayuz: return
	
	son_savas_paneli = ana.arayuz.get_node_or_null("%SonSavasPaneli")
	savas_eli_konteyner = ana.arayuz.savas_kart_eli_konteyner
	insa_eli_konteyner = ana.arayuz.insa_kart_eli_konteyner
	
	savas_eli_paneli = ana.arayuz.get_node_or_null("%SavasEliPaneli")
	savas_eli_hbox = ana.arayuz.get_node_or_null("%SavasEli")
	
	# 🟢 DEĞİŞTİ: İki ayrı buton
	onayla_atak_btn = ana.arayuz.get_node_or_null("%SecilenKartlariOnaylaAtak")
	onayla_defans_btn = ana.arayuz.get_node_or_null("%SecilenKartlariOnaylaDefans")
	
	if onayla_atak_btn and not onayla_atak_btn.pressed.is_connected(_onayla_basildi):
		onayla_atak_btn.pressed.connect(_onayla_basildi)
	if onayla_defans_btn and not onayla_defans_btn.pressed.is_connected(_onayla_basildi):
		onayla_defans_btn.pressed.connect(_onayla_basildi)
	
	atak_zar_at_btn = ana.arayuz.get_node_or_null("%AtakZarAt")
	defans_zar_at_btn = ana.arayuz.get_node_or_null("%DefansZarAt")

	if atak_zar_at_btn and not atak_zar_at_btn.pressed.is_connected(_zar_at_basildi):
		atak_zar_at_btn.pressed.connect(_zar_at_basildi.bind(true))
	if defans_zar_at_btn and not defans_zar_at_btn.pressed.is_connected(_zar_at_basildi):
		defans_zar_at_btn.pressed.connect(_zar_at_basildi.bind(false))
	
func savas_panelini_guncelle():
	_referanslari_al()
	_paneli_tam_sifirla() 
	_isim_ve_medeniyet_guncelle()
	
	secilen_savas_kartlari.clear()
	secilen_savas_idxleri.clear()
	secilen_benim_idxler.clear()
	secilen_benim_kartlar.clear()
	secilen_benim_nodelar.clear()
	kendi_kilitledi_mi = false
	son_kartlar_dict.clear()
	benim_slot_on_eki = "OyuncuKart" if _ben_saldiran_miyim() else "RakipKart"
	
	_slot_tiklama_baglantilarini_kur()
	
	# 🟢 YENİ: Sadece kendi rolüme ait butonu göster, diğerini gizle
	var ben_saldiran = _ben_saldiran_miyim()
	benim_onayla_btn = onayla_atak_btn if ben_saldiran else onayla_defans_btn
	
	if onayla_atak_btn: onayla_atak_btn.visible = ben_saldiran
	if onayla_defans_btn: onayla_defans_btn.visible = _ben_savasta_miyim() and not ben_saldiran
	
	if benim_onayla_btn:
		benim_onayla_btn.disabled = false
		if benim_onayla_btn is Button:
			benim_onayla_btn.text = tr("KARTLARI KİLİTLE")
	
	var atak_guc_lbl = ana.arayuz.get_node_or_null("%SecilenKartGucAtak")
	if atak_guc_lbl: atak_guc_lbl.text = tr("Kartlar Seçiliyor...")
	
	var defans_guc_lbl = ana.arayuz.get_node_or_null("%SecilenKartGucDefans")
	if defans_guc_lbl: defans_guc_lbl.text = tr("Kartlar Seçiliyor...")
	
	if son_savas_paneli: son_savas_paneli.visible = true
	
	if ana.arayuz.alt_orta_panel: ana.arayuz.alt_orta_panel.visible = false
	if savas_eli_paneli: savas_eli_paneli.visible = _ben_savasta_miyim()
	
	zar_saldiran_deger = -1
	zar_savunan_deger = -1
	if atak_zar_at_btn: atak_zar_at_btn.visible = false
	if defans_zar_at_btn: defans_zar_at_btn.visible = false
	
	var atak_zar_sonuc_lbl = ana.arayuz.get_node_or_null("%AtakZarSonucu")
	if atak_zar_sonuc_lbl: atak_zar_sonuc_lbl.text = "-"
	var defans_zar_sonuc_lbl = ana.arayuz.get_node_or_null("%DefansZarSonucu")
	if defans_zar_sonuc_lbl: defans_zar_sonuc_lbl.text = "-"
	
	_savas_elini_doldur()

func _slot_tiklama_baglantilarini_kur():
	if not ana.arayuz: return
	for i in range(1, 8):
		var slot = ana.arayuz.get_node_or_null("%" + benim_slot_on_eki + str(i))
		if slot:
			slot.mouse_filter = Control.MOUSE_FILTER_STOP   # tıklanabilir olsun
			if not slot.gui_input.is_connected(_slot_gui_input):
				slot.gui_input.connect(_slot_gui_input.bind(i))

func _slot_gui_input(event: InputEvent, slot_index: int):
	if kendi_kilitledi_mi: return   # kilitlendiyse dokunma
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	
	var dizi_index = slot_index - 1
	if dizi_index < 0 or dizi_index >= secilen_benim_kartlar.size():
		return   # o slot zaten boş
	
	_karti_iptal_et(dizi_index)

func _karti_iptal_et(dizi_index: int):
	var kart_ui_node = secilen_benim_nodelar[dizi_index]
	
	secilen_benim_kartlar.remove_at(dizi_index)
	secilen_benim_idxler.remove_at(dizi_index)
	secilen_benim_nodelar.remove_at(dizi_index)
	
	if is_instance_valid(kart_ui_node):
		kart_ui_node.visible = true   # elimize geri dön
	
	_oyuncu_slotlarini_guncelle()
	ana.arayuz.olay_yaz(tr("↩️ Kart geri alındı."))

func savas_taraflari() -> Array:
	var saldiran = savas_ozel_saldiran
	if savas_piyon_saldiran >= 0 and savas_piyon_saldiran < ana.piyonlar.size():
		saldiran = ana.piyonlar[savas_piyon_saldiran]["sahip"]
	var savunan = savas_ozel_savunucu
	if savas_hedef_turu == "bina" and ana.binalar_verisi.has(savas_bina_koordinat):
		savunan = ana.binalar_verisi[savas_bina_koordinat]["sahip"]
	elif savas_hedef_turu == "piyon" and savas_piyon_savunan >= 0 and savas_piyon_savunan < ana.piyonlar.size():
		savunan = ana.piyonlar[savas_piyon_savunan]["sahip"]
	return [saldiran, ana.koruyucu_efendi(savunan)]

func _ben_savasta_miyim() -> bool:
	return ana.oyuncular[ana.benim_indexim] in savas_taraflari()

func savunma_gucu(koor: Vector2i) -> int:
	var biyom = ana.harita.kesfedilen_hexler.get(koor, "")
	var guc = 5 if biyom == "dag" else 2 if biyom == "orman" else 0
	var bina = ana.binalar_verisi.get(koor, {})
	if not bina.is_empty():
		guc += 3 + (bina.get("seviye", 1) - 1) * 2 if bina["tur"] == "sehir_merkezi" else 1
	return guc

func _ben_saldiran_miyim() -> bool:
	var ben = ana.oyuncular[ana.benim_indexim]
	var saldiran_isim = savas_ozel_saldiran if savas_piyon_saldiran == -1 else ana.piyonlar[savas_piyon_saldiran]["sahip"]
	return ben == saldiran_isim

func _savas_elini_doldur():
	if not _ben_savasta_miyim(): return
	if not savas_eli_hbox:
		print("❌ HATA: %SavasEli bulunamadı! Node ismini/unique name'ini kontrol et.")
		return
	
	for c in savas_eli_hbox.get_children():
		c.queue_free()
	
	var kart_sahnesi = ana.deste.kart_sahnesi
	if not kart_sahnesi:
		print("❌ HATA: Kart sahnesi (DesteYonetici.kart_sahnesi) bulunamadı!")
		return
	
	for i in range(ana.deste.el.size()):
		var kart = ana.deste.el[i]
		if kart.get("hedef", "") == "savas":
			var kart_ui = kart_sahnesi.instantiate()
			savas_eli_hbox.add_child(kart_ui)
			kart_ui.karti_doldur(kart, i)
			kart_ui.dogrudan_savas_modu = true   # 🟢 Tek tıkla yerleştirme aktif

func _kart_texture_getir(kart: Dictionary) -> Texture2D:
	var orj_isim = kart.get("isim", kart.get("tur", ""))
	if orj_isim == "Standart Birlik" or kart.get("tur") == "standart": return null
		
	var dosya_adi = savas_resimleri.get(orj_isim, "")
	if dosya_adi != "":
		var klasor = "komutanlar" if kart.get("tur") == "komutan" else "askerler"
		var yol = "res://Assets/Resimler/%s/%s.png" % [klasor, dosya_adi]
		var yedek_yol = "res://Assets/Resimler/askerler/%s.png" % dosya_adi
		
		if ResourceLoader.exists(yol): return load(yol)
		elif ResourceLoader.exists(yedek_yol): return load(yedek_yol)
	return null

func savas_kart_sec_ve_yerlestir(kart: Dictionary, idx: int, kart_ui_node: Node):
	if not savas_aktif or not _ben_savasta_miyim() or kendi_kilitledi_mi: return
	if idx < 0 or idx >= ana.deste.el.size() or idx in secilen_benim_idxler: return
	if kart != ana.deste.el[idx] or kart.get("hedef") != "savas": return
	if secilen_benim_kartlar.size() >= 7:
		ana.arayuz.olay_yaz(tr("En fazla 7 kart seçebilirsin."))
		return
	
	# 🟢 YENİ: Kuşatma birimleri (Koçbaşı, Mancınık) sadece bina/şehir saldırısında kullanılabilir
	var tur = kart.get("tur", "")
	if (tur == "kocbasi" or tur == "mancinik") and (savas_hedef_turu != "bina" or not _ben_saldiran_miyim()):
		ana.arayuz.olay_yaz(tr("⚠️ [color=orange]%s yalnızca şehir veya bina saldırılarında kullanılabilir![/color]") % tr(kart.get("isim", "Bu birim")))
		return
	
	secilen_benim_kartlar.append(kart)
	secilen_benim_idxler.append(idx)
	secilen_benim_nodelar.append(kart_ui_node)
	if kart_ui_node:
		kart_ui_node.visible = false
	_oyuncu_slotlarini_guncelle()

func _oyuncu_slotlarini_guncelle():
	if not ana.arayuz: return
	var slot_on_eki = "OyuncuKart" if _ben_saldiran_miyim() else "RakipKart"
	for i in range(1, 8):
		var slot = ana.arayuz.get_node_or_null("%" + slot_on_eki + str(i))
		if slot and slot is TextureRect:
			if i - 1 < secilen_benim_kartlar.size():
				var kart = secilen_benim_kartlar[i - 1]
				var tex = _kart_texture_getir(kart)
				slot.texture = tex
				_slot_bilgi_etiketi_guncelle(slot, kart)   # 🟢 YENİ
			else:
				slot.texture = null
				var lbl = slot.get_node_or_null("BilgiEtiketi")
				if lbl: lbl.visible = false

func _slot_bilgi_etiketi_guncelle(slot: TextureRect, kart: Dictionary):
	var lbl = slot.get_node_or_null("BilgiEtiketi")
	if not lbl:
		lbl = Label.new()
		lbl.name = "BilgiEtiketi"
		lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.add_theme_constant_override("outline_size", 3)
		slot.add_child(lbl)
	
	var isim = tr(kart.get("isim", "Birlik"))
	var guc_str = tr("Komutan") if kart.get("tur") == "komutan" else str(kart.get("guc", 0))
	lbl.text = tr("%s (Güç: %s)") % [isim, guc_str]
	lbl.visible = true

func _onayla_basildi():
	if not savas_aktif or not _ben_savasta_miyim() or kendi_kilitledi_mi: return
	kendi_kilitledi_mi = true
	if benim_onayla_btn:
		benim_onayla_btn.disabled = true
		if benim_onayla_btn is Button:
			benim_onayla_btn.text = tr("RAKİP BEKLENİYOR...")
	
		
	var ben = ana.oyuncular[ana.benim_indexim]
	ana.istek("aksiyon", "savas_hamlesi_yap_rpc", [ben, secilen_benim_kartlar, secilen_benim_idxler])

# Sunucu, bir tarafın kartlarını kilitlediğini (kartları açıklamadan) duyurur.
@rpc("authority", "call_local", "reliable")
func taraf_kilitlendi_rpc(saldiran_mi: bool):
	if not savas_aktif: return
	var lbl_ismi = "%SecilenKartGucAtak" if saldiran_mi else "%SecilenKartGucDefans"
	var lbl = ana.arayuz.get_node_or_null(lbl_ismi)
	if lbl: lbl.text = tr("Kartlar Seçildi")

func rakip_kartlari_goster(kartlar_dict: Dictionary):
	# Spectators and participants see both canonical hands after reveal.
	var taraflar = savas_taraflari()
	for taraf in range(2):
		var prefix = "OyuncuKart" if taraf == 0 else "RakipKart"
		var kartlar = kartlar_dict.get(taraflar[taraf], [])
		for i in range(1, 8):
			var slot = ana.arayuz.get_node_or_null("%" + prefix + str(i))
			if not slot is TextureRect: continue
			if i <= kartlar.size():
				slot.texture = _kart_texture_getir(kartlar[i - 1])
				_slot_bilgi_etiketi_guncelle(slot, kartlar[i - 1])
			else:
				slot.texture = null
				var label = slot.get_node_or_null("BilgiEtiketi")
				if label: label.visible = false
	ana.arayuz.olay_yaz(tr("⚔️ Her iki tarafın kartları açıldı!"))

# ==========================================
# 🟢 SAVAŞ ÇÖZÜMLEME
# ==========================================

func _kart_gucu_topla(kartlar: Array) -> int:
	var toplam = 0
	for k in kartlar:
		toplam += k.get("guc", 0)
	return toplam

func _kart_gucu_hesapla(taraf_kartlar: Array, rakip_kartlar: Array, taraf_saldiran_mi: bool) -> int:
	var toplam = 0.0
	
	for k in taraf_kartlar:
		toplam += k.get("guc", 0)
	
	for k in taraf_kartlar:
		var b = k.get("bonus", {})
		if typeof(b) != TYPE_DICTIONARY or b.is_empty(): continue
		var tip = b.get("tip", "")
		
		match tip:
			"pozisyon":   # 🟢 GERİ EKLENDİ: Kısa Yaylı
				var kosul = b.get("kosul", "")
				if (kosul == "savunma" and not taraf_saldiran_mi) or (kosul == "saldiri" and taraf_saldiran_mi):
					toplam += b.get("miktar", 0)
					
			"her_karta_ekle_bina_saldiri":   # Fatih
				if savas_hedef_turu == "bina" and taraf_saldiran_mi:
					toplam += b.get("miktar", 0) * taraf_kartlar.size()
					
			"her_karta_ekle_savunma":   # Leonidas
				if not taraf_saldiran_mi:
					toplam += b.get("miktar", 0) * taraf_kartlar.size()
					
			"kart_turu_bonus":   # Cengiz Han, Ragnar Lodbrok
				var hedef_tur = b.get("hedef", "")
				var miktar = b.get("miktar", 0)
				for k2 in taraf_kartlar:
					if k2.get("tur","") == hedef_tur:
						toplam += miktar
						
			"az_kartla":   # Belisarius
				if taraf_kartlar.size() < rakip_kartlar.size():
					toplam += b.get("miktar", 0)
					
			"sart_hedef_turu":   # Thutmose
				if savas_hedef_turu == b.get("deger", ""):
					toplam += b.get("miktar", 0)
					
			"sart_savas_tipi":   # Dandolo
				if savas_tipi == b.get("deger", ""):
					toplam += b.get("miktar", 0)
	
	for rk in rakip_kartlar:
		var b = rk.get("bonus", {})
		if typeof(b) == TYPE_DICTIONARY and b.get("tip", "") == "dusur":
			var hedef_tur = b.get("hedef", "")
			var miktar = b.get("miktar", 0)
			for k in taraf_kartlar:
				if k.get("tur", "") == hedef_tur:
					toplam -= miktar
	
	# İskender: en son uygulanır (toplamı çarpar)
	for k in taraf_kartlar:
		var b = k.get("bonus", {})
		if typeof(b) == TYPE_DICTIONARY and b.get("tip", "") == "carpan_yuzde_saldiri" and taraf_saldiran_mi:
			toplam *= (1.0 + b.get("miktar", 0) / 100.0)
	
	return max(0, int(round(toplam)))

func _bonus_aciklama_olustur(taraf_kartlar: Array, rakip_kartlar: Array, taraf_saldiran_mi: bool, taraf_isim: String) -> String:
	var satirlar = []
	
	# 🟢 YENİ: Medeniyet bonusu EN ÜSTTE, farklı renkte
	var med = ana.medeniyetler_verisi.get(taraf_isim, "")
	if medeniyet_savas_bonuslari.has(med):
		satirlar.append("[color=cyan]%s[/color]" % tr(medeniyet_savas_bonuslari[med]))
	
	for k in taraf_kartlar:
		var b = k.get("bonus", {})
		if typeof(b) != TYPE_DICTIONARY or b.is_empty(): continue
		var tip = b.get("tip", "")
		var isim = k.get("isim", "")
		var miktar = b.get("miktar", 0)
		
		match tip:
			"pozisyon":   # 🟢 GERİ EKLENDİ: Kısa Yaylı
				var kosul = b.get("kosul", "")
				if (kosul == "savunma" and not taraf_saldiran_mi) or (kosul == "saldiri" and taraf_saldiran_mi):
					satirlar.append(tr("🏹 %s: Pozisyon bonusu +%d") % [isim, miktar])
			"her_karta_ekle_bina_saldiri":
				if savas_hedef_turu == "bina" and taraf_saldiran_mi:
					satirlar.append(tr("👑 %s: Her karta +%d (toplam +%d)") % [isim, miktar, miktar * taraf_kartlar.size()])
			"her_karta_ekle_savunma":
				if not taraf_saldiran_mi:
					satirlar.append(tr("👑 %s: Her karta +%d (toplam +%d)") % [isim, miktar, miktar * taraf_kartlar.size()])
			"kart_turu_bonus":
				var hedef_tur = b.get("hedef", "")
				var sayac = 0
				for k2 in taraf_kartlar:
					if k2.get("tur","") == hedef_tur: sayac += 1
				if sayac > 0:
					satirlar.append(tr("👑 %s: %s bonusu +%d (toplam +%d)") % [isim, tr(hedef_tur.capitalize()), miktar, miktar*sayac])
			"az_kartla":
				if taraf_kartlar.size() < rakip_kartlar.size():
					satirlar.append(tr("👑 %s: Az kartla savaşma bonusu +%d") % [isim, miktar])
			"sart_hedef_turu":
				if savas_hedef_turu == b.get("deger", ""):
					satirlar.append(tr("👑 %s: Koşul sağlandı, +%d") % [isim, miktar])
			"sart_savas_tipi":
				if savas_tipi == b.get("deger", ""):
					satirlar.append(tr("👑 %s: Koşul sağlandı, +%d") % [isim, miktar])
			"carpan_yuzde_saldiri":
				if taraf_saldiran_mi:
					satirlar.append(tr("👑 %s: Saldırıda toplam güç %%%d artıyor") % [isim, miktar])
			"zar_ekle_sartli":
				var kosul = b.get("kosul", "")
				var rol_uygun = (kosul == "saldiri" and taraf_saldiran_mi) or (kosul == "savunma" and not taraf_saldiran_mi)
				var hedef_sart = b.get("hedef_turu_sart", "")
				var hedef_uygun = hedef_sart == "" or hedef_sart == savas_hedef_turu
				if rol_uygun and hedef_uygun:
					satirlar.append(tr("🎲 %s: Zara +%d") % [isim, miktar])
	
	for rk in rakip_kartlar:
		var b = rk.get("bonus", {})
		if typeof(b) == TYPE_DICTIONARY and b.get("tip", "") == "dusur":
			var hedef_tur = b.get("hedef", "")
			var miktar2 = b.get("miktar", 0)
			var etkilenen = 0
			for k in taraf_kartlar:
				if k.get("tur", "") == hedef_tur: etkilenen += 1
			if etkilenen > 0:
				satirlar.append("[color=red]⚠️ %s (rakip): %s birliklerine -%d (toplam -%d)[/color]" % [rk.get("isim",""), hedef_tur.capitalize(), miktar2, miktar2*etkilenen])
	
	if satirlar.is_empty():
		return tr("Aktif bonus yok")
	return "\n".join(satirlar)

# İki Bizans bonusu da aynı, azaltılmamış toplamlar üzerinden hesaplanır.
func medeniyet_guc_bonuslari(sal_toplam: int, sav_toplam: int, sal_isim: String, sav_isim: String, sal_zar: int, sav_zar: int) -> Array:
	var sal_son = sal_toplam
	var sav_son = sav_toplam
	if ana.medeniyetler_verisi.get(sal_isim, "") == "Bizans" and sal_zar in [1, 2]:
		sav_son = int(ceil(sav_toplam / 2.0))
	if ana.medeniyetler_verisi.get(sav_isim, "") == "Bizans" and sav_zar in [1, 2]:
		sal_son = int(ceil(sal_toplam / 2.0))
	return [sal_son, sav_son]

func savas_cozumle(kartlar_dict: Dictionary, zar_saldiran: int, zar_savunan: int):
	if not savas_aktif or sonuc_gosteriliyor: return
	# --- 1. TARAFLARI BELİRLE ---
	var saldiran_isim = savas_ozel_saldiran if savas_piyon_saldiran == -1 else ana.piyonlar[savas_piyon_saldiran]["sahip"]

	var orjinal_savunucu = ""
	match savas_hedef_turu:
		"bina":
			if ana.binalar_verisi.has(savas_bina_koordinat):
				orjinal_savunucu = ana.binalar_verisi[savas_bina_koordinat]["sahip"]
			else:
				orjinal_savunucu = savas_ozel_savunucu
		"piyon":
			if savas_piyon_savunan != -1 and savas_piyon_savunan < ana.piyonlar.size():
				orjinal_savunucu = ana.piyonlar[savas_piyon_savunan]["sahip"]
			else:
				orjinal_savunucu = savas_ozel_savunucu
		"isyan_soyut":
			orjinal_savunucu = savas_ozel_savunucu

	# Efendi koruması: savunan aslında bir vasalsa, gerçekte savaşan onun efendisidir
	var savunan_isim = ana.koruyucu_efendi(orjinal_savunucu)

	# --- 2. GÜÇ HESAPLA (Kart Gücü + Zar) ---
	var saldiran_kartlar_c = kartlar_dict.get(saldiran_isim, [])
	var savunan_kartlar_c = kartlar_dict.get(savunan_isim, [])
	
	var saldiran_kart_gucu = _kart_gucu_hesapla(saldiran_kartlar_c, savunan_kartlar_c, true)
	var savunan_kart_gucu = _kart_gucu_hesapla(savunan_kartlar_c, saldiran_kartlar_c, false)

	var saldiran_zar_bonus = _zar_bonusu_hesapla(saldiran_kartlar_c, true)      # 🟢 YENİ
	var savunan_zar_bonus = _zar_bonusu_hesapla(savunan_kartlar_c, false)        # 🟢 YENİ
	
	var saldiran_toplam = saldiran_kart_gucu + zar_saldiran + saldiran_zar_bonus   # 🟢 DEĞİŞTİ
	var savunan_toplam = savunan_kart_gucu + zar_savunan + savunan_zar_bonus + savunma_gucu(savas_bina_koordinat)       # 🟢 DEĞİŞTİ
	
	var bonuslu = medeniyet_guc_bonuslari(saldiran_toplam, savunan_toplam, saldiran_isim, savunan_isim, zar_saldiran, zar_savunan)
	saldiran_toplam = bonuslu[0]
	savunan_toplam = bonuslu[1]
	# Eşitlikte savunan kazanır (savunma avantajı)
	var saldiran_kazandi = saldiran_toplam > savunan_toplam

	# --- 3. PANELİ GÜNCELLE (Güç ve Zar Gösterimi) ---
	_savas_sonuc_panelini_guncelle(saldiran_kart_gucu, savunan_kart_gucu, zar_saldiran, zar_savunan, saldiran_toplam, savunan_toplam)

	# --- 4. SONUCU UYGULA ---
	match savas_hedef_turu:
		"piyon":
			_sonucu_uygula_piyon(saldiran_kazandi, saldiran_isim, orjinal_savunucu)
		"bina":
			_sonucu_uygula_bina(saldiran_kazandi, saldiran_isim, orjinal_savunucu)
		"isyan_soyut":
			_sonucu_uygula_isyan(saldiran_kazandi, saldiran_isim, orjinal_savunucu)
	
	# 🟢 YENİ: Savaş puanı güncelle (kazanan +1, kaybeden -1, çarpan zaten skor_guncelle'de uygulanıyor)
	if not ana.savas_puanlari.has(saldiran_isim): ana.savas_puanlari[saldiran_isim] = 0
	if not ana.savas_puanlari.has(savunan_isim): ana.savas_puanlari[savunan_isim] = 0
	
	if saldiran_kazandi:
		ana.savas_puanlari[saldiran_isim] += 1
		ana.savas_puanlari[savunan_isim] -= 1
	else:
		ana.savas_puanlari[savunan_isim] += 1
		ana.savas_puanlari[saldiran_isim] -= 1
	
	var kazanan = saldiran_isim if saldiran_kazandi else savunan_isim
	if ana.medeniyetler_verisi.get(kazanan, "") == "Viking":
		ana.oyuncu_kaynaklari[kazanan]["altin"] += 5
		ana.arayuz.olay_yaz(tr("🪙 %s, Kuzeyin Gazabı ile 5 Altın kazandı.") % ana.arayuz.renkli_isim(kazanan))
	sonuc_gosteriliyor = true
	ana.arayuz.arayuzu_guncelle()
	
	# --- 5. TEMİZLİK ---
	savas_aktif = false
	ana.harita.gorus_haritasini_guncelle()
	ana.harita.queue_redraw()

	await get_tree().create_timer(4.0).timeout
	if son_savas_paneli:
		son_savas_paneli.visible = false
	
	# 🟢 YENİ: Normal alt panele geri dön
	if ana.arayuz.alt_orta_panel: ana.arayuz.alt_orta_panel.visible = true
	if savas_eli_paneli: savas_eli_paneli.visible = false
	sonuc_gosteriliyor = false
	ana.arayuz.arayuzu_guncelle()

# Savaştaki bir oyuncu oyundan ayrılırsa savaşı sonuçsuz kapatır
func savasi_iptal_et():
	if not savas_aktif: return
	ana.aksiyon._savas_kartlarini_iade_et(son_kartlar_dict)
	savas_aktif = false
	secilen_savas_kartlari.clear()
	secilen_savas_idxleri.clear()
	son_kartlar_dict.clear()
	kendi_kilitledi_mi = false
	secilen_benim_idxler.clear()
	secilen_benim_kartlar.clear()
	zar_saldiran_deger = -1
	zar_savunan_deger = -1
	if son_savas_paneli: son_savas_paneli.visible = false
	if ana.arayuz.alt_orta_panel: ana.arayuz.alt_orta_panel.visible = true
	if savas_eli_paneli: savas_eli_paneli.visible = false
	ana.arayuz.olay_yaz(tr("[color=gray]⚔️ Savaş, taraflardan biri ayrıldığı için iptal edildi.[/color]"))
	ana.arayuz.arayuzu_guncelle()

func _zar_bonusu_hesapla(taraf_kartlar: Array, taraf_saldiran_mi: bool) -> int:
	var bonus = 0
	for k in taraf_kartlar:
		var b = k.get("bonus", {})
		if typeof(b) != TYPE_DICTIONARY or b.get("tip","") != "zar_ekle_sartli": continue
		
		var kosul = b.get("kosul", "")
		var rol_uygun = (kosul == "saldiri" and taraf_saldiran_mi) or (kosul == "savunma" and not taraf_saldiran_mi)
		if not rol_uygun: continue
		
		var hedef_sart = b.get("hedef_turu_sart", "")
		if hedef_sart != "" and hedef_sart != savas_hedef_turu: continue
		
		bonus += b.get("miktar", 0)
	return bonus

# --- HEX SAHİPLİĞİ ORTAK KURALI ---
func _hex_sahiplik_guncelle(hedef_koor: Vector2i, saldiran_isim: String) -> bool:   # 🟢 DEĞİŞTİ: artık bool dönüyor
	if ana.hex_dosta_komsu_mu(hedef_koor, saldiran_isim):
		ana.kontrol_edilen_hexler[hedef_koor] = saldiran_isim
		ana.arayuz.olay_yaz(tr("🚩 %s, (%d, %d) bölgesini topraklarına kattı!") % [ana.arayuz.renkli_isim(saldiran_isim), hedef_koor.x, hedef_koor.y])
		return true
	else:
		ana.kontrol_edilen_hexler.erase(hedef_koor)
		ana.arayuz.olay_yaz(tr("⚪ (%d, %d) bölgesi artık kimsenin hakimiyetinde değil (komşu olmadığı için ele geçirilemedi).") % [hedef_koor.x, hedef_koor.y])
		return false

func _sonucu_uygula_piyon(saldiran_kazandi: bool, saldiran_isim: String, orjinal_savunucu: String):
	if saldiran_kazandi:
		ana.arayuz.olay_yaz(tr("⚔️ [color=lime]ZAFER![/color] %s savaşı kazandı!") % ana.arayuz.renkli_isim(saldiran_isim))
		_bolgedeki_dusmanlari_geri_cek(saldiran_isim)
		
		var ele_gecirildi = _hex_sahiplik_guncelle(savas_bina_koordinat, saldiran_isim)
		
		# 🟢 YENİ: Ele geçirildiyse saldıranın öncüsü fethedilen hex'e taşınır
		if ele_gecirildi and savas_piyon_saldiran != -1 and savas_piyon_saldiran < ana.piyonlar.size():
			ana.piyonlar[savas_piyon_saldiran]["koordinat"] = savas_bina_koordinat
			ana.arayuz.olay_yaz(tr("🏴 %s'in öncüsü fethedilen bölgeye yerleşti.") % ana.arayuz.renkli_isim(saldiran_isim))
	else:
		ana.arayuz.olay_yaz(tr("🛡️ [color=orange]SAVUNMA BAŞARILI![/color] %s saldırıyı püskürttü!") % ana.arayuz.renkli_isim(orjinal_savunucu))
		_piyonu_eve_isinla(savas_piyon_saldiran)

func _sonucu_uygula_bina(saldiran_kazandi: bool, saldiran_isim: String, orjinal_savunucu: String):
	var bina_var_mi = ana.binalar_verisi.has(savas_bina_koordinat)
	var sehir_merkezi_mi = bina_var_mi and ana.binalar_verisi[savas_bina_koordinat]["tur"] == "sehir_merkezi"

	if not saldiran_kazandi:
		ana.arayuz.olay_yaz(tr("🛡️ [color=orange]SAVUNMA BAŞARILI![/color] %s, %s'in saldırısını püskürttü!") % [ana.arayuz.renkli_isim(orjinal_savunucu), ana.arayuz.renkli_isim(saldiran_isim)])
		_piyonu_eve_isinla(savas_piyon_saldiran)
		return

	# --- Saldıran kazandı ---
	_bolgedeki_dusmanlari_geri_cek(saldiran_isim)

	match savas_tipi:
		"hukmet":
			if not ana.vasallik_gecerli_mi(orjinal_savunucu, saldiran_isim): return
			ana.efendiler[orjinal_savunucu] = saldiran_isim
			ana.arayuz.olay_yaz(tr("👑 [color=gold]HÜKÜMDARLIK KURULDU![/color] %s, %s'i vasalı yaptı!") % [ana.arayuz.renkli_isim(saldiran_isim), ana.arayuz.renkli_isim(orjinal_savunucu)])
			# 🟢 Şehir merkezi asla el değiştirmez, öncü de saldırdığı yerde kalır — burada hiçbir hex/piyon işlemi YOK (bilerek)

		"yagmala":
			var calinan_oran = 0.25
			var calinanlar = []
			for kaynak in ["odun", "tas", "yiyecek", "altin"]:
				var mevcut = ana.oyuncu_kaynaklari[orjinal_savunucu][kaynak]
				var miktar = int(ceil(mevcut * calinan_oran))
				ana.oyuncu_kaynaklari[orjinal_savunucu][kaynak] = mevcut - miktar
				ana.oyuncu_kaynaklari[saldiran_isim][kaynak] += miktar
				if miktar > 0: calinanlar.append("%d %s" % [miktar, Global.kaynak_adi(kaynak)])
			ana.arayuz.olay_yaz(tr("💰 [color=yellow]YAĞMALANDI![/color] %s, %s'ten şunları yağmaladı: %s") % [ana.arayuz.renkli_isim(saldiran_isim), ana.arayuz.renkli_isim(orjinal_savunucu), ", ".join(calinanlar)])
			
			# 🟢 GÜVENLİK: Şehir merkezi asla ele geçirilmez, sadece normal binalar için hex/piyon güncellenir
			if not sehir_merkezi_mi:
				var ele_gecirildi = _hex_sahiplik_guncelle(savas_bina_koordinat, saldiran_isim)
				if ele_gecirildi and savas_piyon_saldiran != -1 and savas_piyon_saldiran < ana.piyonlar.size():
					ana.piyonlar[savas_piyon_saldiran]["koordinat"] = savas_bina_koordinat

		"yikim":
			if sehir_merkezi_mi:
				ana.arayuz.olay_yaz(tr("[color=light_coral]❌ Şehir Merkezi yıkılamaz![/color]"))
				# 🟢 Şehir merkeziyse burada dur, hex/piyon işlemi YOK
			else:
				ana.binalar_verisi.erase(savas_bina_koordinat)
				ana.arayuz.olay_yaz(tr("🔥 [color=red]YIKILDI![/color] %s, %s'in yapısını yerle bir etti!") % [ana.arayuz.renkli_isim(saldiran_isim), ana.arayuz.renkli_isim(orjinal_savunucu)])
				
				var ele_gecirildi2 = _hex_sahiplik_guncelle(savas_bina_koordinat, saldiran_isim)
				if ele_gecirildi2 and savas_piyon_saldiran != -1 and savas_piyon_saldiran < ana.piyonlar.size():
					ana.piyonlar[savas_piyon_saldiran]["koordinat"] = savas_bina_koordinat

func _sonucu_uygula_isyan(saldiran_kazandi: bool, saldiran_isim: String, orjinal_savunucu: String):
	if saldiran_kazandi:
		ana.efendiler.erase(saldiran_isim)
		ana.arayuz.olay_yaz(tr("🔥 [color=lime]BAĞIMSIZLIK KAZANILDI![/color] %s artık %s'e bağlı değil!") % [ana.arayuz.renkli_isim(saldiran_isim), ana.arayuz.renkli_isim(orjinal_savunucu)])
	else:
		# İsyan bastırıldı: hazırlanan ordu kaynağı boşa gitti (ceza)
		for kaynak in ["odun", "tas", "yiyecek"]:
			ana.oyuncu_kaynaklari[saldiran_isim][kaynak] = max(0, ana.oyuncu_kaynaklari[saldiran_isim][kaynak] - 10)
		ana.arayuz.olay_yaz(tr("🛡️ [color=orange]İSYAN BASTIRILDI![/color] %s, efendisi %s'e karşı isyanında başarısız oldu.") % [ana.arayuz.renkli_isim(saldiran_isim), ana.arayuz.renkli_isim(orjinal_savunucu)])

func _savas_sonuc_panelini_guncelle(_sal_kart_gucu: int, _sav_kart_gucu: int, _zar_sal: int, _zar_sav: int, sal_toplam: int, sav_toplam: int):
	var atak_toplam_lbl = ana.arayuz.get_node_or_null("%AtakToplamGucLabel")      # 🟢 DÜZELTİLDİ
	if atak_toplam_lbl: atak_toplam_lbl.text = tr("Toplam Güç: %d") % sal_toplam
	
	var defans_toplam_lbl = ana.arayuz.get_node_or_null("%DefansToplamGucLabel")   # 🟢 DÜZELTİLDİ
	if defans_toplam_lbl: defans_toplam_lbl.text = tr("Toplam Güç: %d") % sav_toplam

func _isim_ve_medeniyet_guncelle():
	if not ana.arayuz: return
	
	var saldiran_isim = savas_ozel_saldiran if savas_piyon_saldiran == -1 else ana.piyonlar[savas_piyon_saldiran]["sahip"]
	
	var orjinal_savunucu = ""
	match savas_hedef_turu:
		"bina":
			if ana.binalar_verisi.has(savas_bina_koordinat):
				orjinal_savunucu = ana.binalar_verisi[savas_bina_koordinat]["sahip"]
			else:
				orjinal_savunucu = savas_ozel_savunucu
		"piyon":
			if savas_piyon_savunan != -1 and savas_piyon_savunan < ana.piyonlar.size():
				orjinal_savunucu = ana.piyonlar[savas_piyon_savunan]["sahip"]
			else:
				orjinal_savunucu = savas_ozel_savunucu
		"isyan_soyut":
			orjinal_savunucu = savas_ozel_savunucu
	
	var savunan_isim = ana.koruyucu_efendi(orjinal_savunucu)
	
	var atak_isim_lbl = ana.arayuz.get_node_or_null("%AtakIsim")
	if atak_isim_lbl: atak_isim_lbl.text = saldiran_isim
	
	var atak_med_lbl = ana.arayuz.get_node_or_null("%AtakMedeniyet")
	if atak_med_lbl: atak_med_lbl.text = ana.medeniyetler_verisi.get(saldiran_isim, "")
	
	var defans_isim_lbl = ana.arayuz.get_node_or_null("%DefansIsim")
	if defans_isim_lbl: defans_isim_lbl.text = savunan_isim
	
	var defans_med_lbl = ana.arayuz.get_node_or_null("%DefansMedeniyet")
	if defans_med_lbl: defans_med_lbl.text = ana.medeniyetler_verisi.get(savunan_isim, "")
	
	# 🟢 YENİ: Profil resimleri
	var atak_resim = ana.arayuz.get_node_or_null("%AtakResim")
	if atak_resim:
		var no1 = ana.oyuncu_profil_no.get(saldiran_isim, 1)
		var yol1 = "res://Assets/Resimler/Profil%d.png" % no1
		atak_resim.texture = load(yol1) if ResourceLoader.exists(yol1) else null
	
	var defans_resim = ana.arayuz.get_node_or_null("%DefansResim")
	if defans_resim:
		var no2 = ana.oyuncu_profil_no.get(savunan_isim, 1)
		var yol2 = "res://Assets/Resimler/Profil%d.png" % no2
		defans_resim.texture = load(yol2) if ResourceLoader.exists(yol2) else null

func _sehir_merkezi_konumu_bul(isim: String) -> Vector2i:
	for koor in ana.binalar_verisi:
		var b = ana.binalar_verisi[koor]
		if b["tur"] == "sehir_merkezi" and b["sahip"] == isim:
			return koor
	return Vector2i(-1, -1)

func _bolgedeki_dusmanlari_geri_cek(saldiran_isim: String):
	for i in range(ana.piyonlar.size()):
		var p = ana.piyonlar[i]
		if p["koordinat"] == savas_bina_koordinat and not ana.muttefik_mi(saldiran_isim, p["sahip"]):
			_piyonu_eve_isinla(i)

func _piyonu_eve_isinla(piyon_index: int):
	if piyon_index == -1 or piyon_index >= ana.piyonlar.size(): return
	var isim = ana.piyonlar[piyon_index]["sahip"]
	var ev_konumu = _sehir_merkezi_konumu_bul(isim)
	if ev_konumu != Vector2i(-1, -1):
		ana.piyonlar[piyon_index]["koordinat"] = ev_konumu
		ana.arayuz.olay_yaz(tr("🏃 %s'in öncüsü şehrine geri kaçtı!") % ana.arayuz.renkli_isim(isim))
	else:
		# Şehir merkezi bulunamadıysa (çok nadir durum) eski davranışa dön: piyonu sil
		ana.piyonlar.remove_at(piyon_index)

func zar_asamasini_baslat(kartlar_dict: Dictionary):
	son_kartlar_dict = kartlar_dict
	
	var saldiran_isim = savas_ozel_saldiran if savas_piyon_saldiran == -1 else ana.piyonlar[savas_piyon_saldiran]["sahip"]
	
	var orjinal_savunucu = ""
	match savas_hedef_turu:
		"bina":
			orjinal_savunucu = ana.binalar_verisi[savas_bina_koordinat]["sahip"] if ana.binalar_verisi.has(savas_bina_koordinat) else savas_ozel_savunucu
		"piyon":
			orjinal_savunucu = ana.piyonlar[savas_piyon_savunan]["sahip"] if (savas_piyon_savunan != -1 and savas_piyon_savunan < ana.piyonlar.size()) else savas_ozel_savunucu
		"isyan_soyut":
			orjinal_savunucu = savas_ozel_savunucu
	var savunan_isim = ana.koruyucu_efendi(orjinal_savunucu)
	
	# 🟢 DÜZELTİLDİ: Kartları önce al, gücü BONUSLARLA BİRLİKTE hesapla
	var saldiran_kartlar_z = kartlar_dict.get(saldiran_isim, [])
	var savunan_kartlar_z = kartlar_dict.get(savunan_isim, [])
	
	saldiran_kart_gucu_hesap = _kart_gucu_hesapla(saldiran_kartlar_z, savunan_kartlar_z, true)
	savunan_kart_gucu_hesap = _kart_gucu_hesapla(savunan_kartlar_z, saldiran_kartlar_z, false)
	
	var atak_guc_lbl = ana.arayuz.get_node_or_null("%SecilenKartGucAtak")
	if atak_guc_lbl: atak_guc_lbl.text = tr("Kart Gücü: %d") % saldiran_kart_gucu_hesap
	var defans_guc_lbl = ana.arayuz.get_node_or_null("%SecilenKartGucDefans")
	if defans_guc_lbl: defans_guc_lbl.text = tr("Kart Gücü: %d") % savunan_kart_gucu_hesap
	
	var atak_bonus_lbl = ana.arayuz.get_node_or_null("%AtakBonus")
	if atak_bonus_lbl: atak_bonus_lbl.text = Global.okunur_metin(_bonus_aciklama_olustur(saldiran_kartlar_z, savunan_kartlar_z, true, saldiran_isim))
	
	var defans_bonus_lbl = ana.arayuz.get_node_or_null("%DefansBonus")
	if defans_bonus_lbl: defans_bonus_lbl.text = Global.okunur_metin(_bonus_aciklama_olustur(savunan_kartlar_z, saldiran_kartlar_z, false, savunan_isim))
	
	var ben_saldiran = _ben_saldiran_miyim()
	if atak_zar_at_btn:
		atak_zar_at_btn.visible = ben_saldiran
		atak_zar_at_btn.disabled = false
	if defans_zar_at_btn:
		defans_zar_at_btn.visible = _ben_savasta_miyim() and not ben_saldiran
		defans_zar_at_btn.disabled = false

func _zar_at_basildi(saldiran_mi: bool):
	if not savas_aktif or not _ben_savasta_miyim(): return
	if saldiran_mi != _ben_saldiran_miyim(): return   # sadece kendi rolüne ait butona basabilir
	
	if saldiran_mi:
		if atak_zar_at_btn: atak_zar_at_btn.disabled = true
	else:
		if defans_zar_at_btn: defans_zar_at_btn.disabled = true
	
	ana.istek("savas", "zar_at_istegi_rpc", [saldiran_mi])   # 🟢 Sadece sunucuya istek gönderilir, zar burada atılmaz

func zar_at_istegi_rpc(saldiran_mi: bool):
	if not multiplayer.is_server() or not savas_aktif or son_kartlar_dict.size() != 2: return
	# Her taraf yalnızca bir kez zar atabilir (aksi halde savaş birden fazla kez çözülür)
	if saldiran_mi and zar_saldiran_deger != -1: return
	if not saldiran_mi and zar_savunan_deger != -1: return
	
	var ilgili_isim = savas_ozel_saldiran if savas_piyon_saldiran == -1 else ana.piyonlar[savas_piyon_saldiran]["sahip"]
	if not saldiran_mi:
		var orjinal_sav = savas_ozel_savunucu
		if savas_hedef_turu == "bina" and ana.binalar_verisi.has(savas_bina_koordinat):
			orjinal_sav = ana.binalar_verisi[savas_bina_koordinat]["sahip"]
		elif savas_hedef_turu == "piyon" and savas_piyon_savunan != -1 and savas_piyon_savunan < ana.piyonlar.size():
			orjinal_sav = ana.piyonlar[savas_piyon_savunan]["sahip"]
		ilgili_isim = ana.koruyucu_efendi(orjinal_sav)
	
	if ana.rpc_gonderen_ismi() != ilgili_isim: return   # başkasının yerine zar atılamaz

	var med = ana.medeniyetler_verisi.get(ilgili_isim, "")
	var deger = randi_range(1, 6)
	if med == "Osmanlı":
		while deger == 1:   # 🟢 Osmanlı bonusu: zar asla 1 gelmez
			deger = randi_range(1, 6)
	
	zar_sonucu_yayinla_rpc.rpc(saldiran_mi, deger)

@rpc("authority", "call_local", "reliable")
func zar_sonucu_yayinla_rpc(saldiran_mi: bool, deger: int):
	SesYoneticisi.efekt_cal("zar")
	if saldiran_mi:
		zar_saldiran_deger = deger
		var lbl = ana.arayuz.get_node_or_null("%AtakZarSonucu")
		if lbl: lbl.text = str(deger)
	else:
		zar_savunan_deger = deger
		var lbl2 = ana.arayuz.get_node_or_null("%DefansZarSonucu")
		if lbl2: lbl2.text = str(deger)
	
	# Sahnedeki AtakZarSonucu / DefansZarSonucu etiketleri sonucu gösterir.
	# Artık var olmayan zar resimlerine veya var olmayan TextureRect düğümlerine erişilmez.

	# 🟢 İkisi de zar attıysa çözümlemeyi başlat (sadece sunucu tetikler)
	if zar_saldiran_deger != -1 and zar_savunan_deger != -1 and multiplayer.is_server():
		ana.aksiyon.savas_cozumle_rpc.rpc(son_kartlar_dict, zar_saldiran_deger, zar_savunan_deger)

func _paneli_tam_sifirla():
	if not ana.arayuz: return
	
	for i in range(1, 8):
		var o_slot = ana.arayuz.get_node_or_null("%OyuncuKart" + str(i))
		if o_slot and o_slot is TextureRect:
			o_slot.texture = null
			var lbl_o = o_slot.get_node_or_null("BilgiEtiketi")   # 🟢 DÜZELTİLDİ (HataYazisi -> BilgiEtiketi)
			if lbl_o: lbl_o.visible = false
		
		var r_slot = ana.arayuz.get_node_or_null("%RakipKart" + str(i))
		if r_slot and r_slot is TextureRect:
			r_slot.texture = null
			var lbl_r = r_slot.get_node_or_null("BilgiEtiketi")   # 🟢 DÜZELTİLDİ (HataYazisi -> BilgiEtiketi)
			if lbl_r: lbl_r.visible = false
	
	# 🟢 Zar resimlerini ve sonuç yazılarını temizle
	var oyuncu_zar = ana.arayuz.get_node_or_null("%OyuncuZar")
	if oyuncu_zar: oyuncu_zar.texture = null
	
	var defans_zar = ana.arayuz.get_node_or_null("%DefansZar")
	if defans_zar: defans_zar.texture = null
	
	var atak_zar_sonuc = ana.arayuz.get_node_or_null("%AtakZarSonucu")
	if atak_zar_sonuc: atak_zar_sonuc.text = "-"
	
	var defans_zar_sonuc = ana.arayuz.get_node_or_null("%DefansZarSonucu")
	if defans_zar_sonuc: defans_zar_sonuc.text = "-"
	
	# 🟢 Toplam güç yazılarını temizle
	var atak_toplam = ana.arayuz.get_node_or_null("%AtakToplamGucLabel")
	if atak_toplam: atak_toplam.text = ""
	
	var defans_toplam = ana.arayuz.get_node_or_null("%DefansToplamGucLabel")
	if defans_toplam: defans_toplam.text = ""
	
	var atak_bonus = ana.arayuz.get_node_or_null("%AtakBonus")
	if atak_bonus: atak_bonus.text = ""
	
	var defans_bonus = ana.arayuz.get_node_or_null("%DefansBonus")
	if defans_bonus: defans_bonus.text = ""
