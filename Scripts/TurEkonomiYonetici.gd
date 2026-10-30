extends Node
class_name TurEkonomiYonetici

@onready var ana = get_parent() as AnaOyun

# Bir oyuncunun binalarının tur başı ham üretimi (vergi öncesi). Tek kaynak: her yer bunu kullanır.
const SEHIR_ALTINI := 1

func bina_uretimi(isim: String) -> Dictionary:
	var u = {"odun": 0, "tas": 0, "yiyecek": 0, "altin": 0}
	for koor in ana.binalar_verisi:
		var b = ana.binalar_verisi[koor]
		if b["sahip"] != isim: continue
		var lvl = b.get("seviye", 1)
		var med = ana.medeniyetler_verisi.get(isim, "")
		match b["tur"]:
			"sehir_merkezi":
				u["altin"] += SEHIR_ALTINI   # vergi geliri: savaş kartlarına erişim için düzenli altın
				var biyom = ana.harita.kesfedilen_hexler.get(koor, "")
				if biyom == "cim": u["yiyecek"] += lvl
				elif biyom == "orman": u["odun"] += lvl
				elif biyom == "dag": u["tas"] += lvl
			"tarla": u["yiyecek"] += lvl + (1 if med == "Moğol" else 0)
			"oduncu_kampi": u["odun"] += lvl
			"tas_ocagi": u["tas"] += lvl + (1 if med == "Mısır" else 0)
	return u

func _oyuncu_net_uretimini_hesapla(isim: String) -> Dictionary:
	var net_u = {"odun": 0, "tas": 0, "yiyecek": 0, "altin": 0}
	var ham_u = bina_uretimi(isim)
	var kesinti_u = {"odun": 0, "tas": 0, "yiyecek": 0, "altin": 0}   # 🟢 YENİ
	
	var efendim = ana.efendiler.get(isim, "")
	for k in ham_u:
		if ham_u[k] > 0:
			if efendim != "":
				var kesinti = int(ham_u[k] / 2)   # 🟢 YENİ
				kesinti_u[k] = kesinti              # 🟢 YENİ
				net_u[k] += (ham_u[k] - kesinti)
			else:
				net_u[k] += ham_u[k]
				
	for v in ana.efendiler:
		if ana.efendiler[v] == isim:
			var v_ham = bina_uretimi(v)
			for k in v_ham:
				if v_ham[k] > 0:
					net_u[k] += int(v_ham[k] / 2)
					
	return {"net": net_u, "ham": ham_u, "kesinti": kesinti_u}   # 🟢 DEĞİŞTİ: artık 3 parçalı dict

func ticaret_maliyeti(isim: String) -> int:
	return 4 if ana.medeniyetler_verisi.get(isim, "") == "Venedik" else 5

func _kaynak_sat(k_turu: String):
	# 🟢 AP kontrolü kaldırıldı, artık sadece sıra bende mi diye bakıyoruz
	if ana.aktif_sira != ana.benim_indexim:
		ana.arayuz.olay_yaz(tr("[color=light_coral]❌ Sadece kendi sıranızda ticaret yapabilirsiniz![/color]"))
		return
		
	var k_isim = ana.oyuncular[ana.benim_indexim]
	var maliyet = ticaret_maliyeti(k_isim)
	if ana.oyuncu_kaynaklari[k_isim][k_turu] >= maliyet:
		ana.istek("tur_ekonomi", "ticaret_yap_rpc", [k_isim, k_turu])
	else:
		var n = Global.kaynak_adi(k_turu)
		ana.arayuz.olay_yaz(tr("[color=light_coral]❌ Yetersiz kaynak! Altın alabilmek için en az %d %s gerekli.[/color]") % [maliyet, n])

func ticaret_yap_rpc(oyuncu_ismi, k_turu):
	if not ana.rpc_sirada_mi(oyuncu_ismi): return
	var maliyet = ticaret_maliyeti(oyuncu_ismi)
	if not (k_turu in ["odun", "tas", "yiyecek"]) or ana.oyuncu_kaynaklari[oyuncu_ismi][k_turu] < maliyet: return
	var pazar_var = false
	for bina in ana.binalar_verisi.values():
		if bina["sahip"] == oyuncu_ismi and bina["tur"] == "ticaret_merkezi": pazar_var = true
	if not pazar_var: return
	# 🟢 AP eksiltme satırı (ana.aktif_oyuncu_aksiyon_hakki -= 1) tamamen silindi!
	ana.oyuncu_kaynaklari[oyuncu_ismi][k_turu] -= maliyet
	ana.oyuncu_kaynaklari[oyuncu_ismi]["altin"] += 1
	var emoji = "🌲" if k_turu == "odun" else "🪨" if k_turu == "tas" else "🌾"
	ana.arayuz.olay_yaz(tr("⚖️ %s, tüccarlara %d %s %s vererek [color=gold]1 🪙 Altın[/color] kazandı.") % [ana.arayuz.renkli_isim(oyuncu_ismi), maliyet, emoji, k_turu.to_upper()])
	ana.arayuz.arayuzu_guncelle()
	ana.islem_kabul = true

func _tur_butonuna_basildi():
	if ana.aktif_sira == ana.benim_indexim:
		if not ana.sehir_merkezleri[ana.oyuncular[ana.benim_indexim]]: return
		
		# 🟢 YENİ KONTROL: İnşa ve Savaş kartlarını ayrı ayrı sayıyoruz (Her biri max 7 olabilir)
		var insa_sayisi = 0
		var savas_sayisi = 0
		
		for kart in ana.deste.el:
			if kart.get("hedef") == "savas":
				savas_sayisi += 1
			else:
				insa_sayisi += 1
				
		if insa_sayisi > 7 or savas_sayisi > 7:
			ana.arayuz.olay_yaz(tr("[color=light_coral]❌ Elindeki İnşa (%d/7) veya Savaş (%d/7) kartı sınırı aşıldı! Fazlalıkları çöpe atmalısın.[/color]") % [insa_sayisi, savas_sayisi])
			return
			
		ana.istek("tur_ekonomi", "sirayi_degistir_rpc", [])

func sirayi_degistir_rpc():
	if not ana.rpc_sirada_mi(): return
	if not ana.sehir_merkezleri.get(ana.rpc_gonderen_ismi(), false): return
	turu_bitir()
	ana.islem_kabul = true

# Aktif oyuncunun turunu kapatır (üretim/vergi) ve sırayı oyundan ayrılmamış bir sonraki oyuncuya verir
func turu_bitir():
	var bitiren_oyuncu = ana.oyuncular[ana.aktif_sira]
	
	if ana.ilk_tur_bitti or ana.sehir_merkezleri.get(bitiren_oyuncu, false):
		var uretim = bina_uretimi(bitiren_oyuncu)
		var efendisi = ana.efendiler.get(bitiren_oyuncu, "")
		var vergi_logu = ""
		
		for k in uretim:
			var kazanilan = uretim[k]
			if kazanilan > 0:
				if efendisi != "":
					var vergi = int(kazanilan / 2) 
					ana.oyuncu_kaynaklari[bitiren_oyuncu][k] += (kazanilan - vergi)
					ana.oyuncu_kaynaklari[efendisi][k] += vergi
					if vergi > 0:
						vergi_logu += "%d %s, " % [vergi, Global.kaynak_adi(k).to_upper()]
						ana.odenen_vergiler[bitiren_oyuncu][k] += vergi 
				else:
					ana.oyuncu_kaynaklari[bitiren_oyuncu][k] += kazanilan
					
		if efendisi != "" and vergi_logu != "":
			ana.arayuz.olay_yaz(tr("👑 [color=orange]Vasal Vergisi:[/color] %s, efendisine %s ödedi.") % [ana.arayuz.renkli_isim(bitiren_oyuncu), vergi_logu])

	for _adim in range(ana.oyuncular.size()):
		ana.aktif_sira = (ana.aktif_sira + 1) % ana.oyuncular.size()
		if ana.aktif_sira == 0:
			ana.ilk_tur_bitti = true
			ana.tur_sayaci += 1
		if not ana.oyuncular[ana.aktif_sira] in ana.ayrilan_oyuncular: break
		
	var aktif_oyuncu_ismi = ana.oyuncular[ana.aktif_sira]
	if ana.aktif_sira == ana.benim_indexim and ana.oyuncular.size() > 1: SesYoneticisi.efekt_cal("sira_sende")
	ana.secili_kart_index = -1
	ana.kart_insa_modu_aktif = false
	ana.kurulabilir_hexler.clear()
	ana.secili_piyon_index = -1
	ana.aktif_oyuncu_aksiyon_hakki = 3 if ana.ilk_tur_bitti else 0
	
	if ana.ilk_tur_bitti:
		ana.arayuz.olay_yaz(tr("[color=yellow]➔ TUR %d:[/color] Sıra %s oyuncusunda! (⚡3 AP yenilendi)") % [ana.tur_sayaci, ana.arayuz.renkli_isim(aktif_oyuncu_ismi)])
	else:
		ana.arayuz.olay_yaz(tr("[color=yellow]➔ TUR %d:[/color] Sıra %s oyuncusunda! Şehrini kur.") % [ana.tur_sayaci, ana.arayuz.renkli_isim(aktif_oyuncu_ismi)])
		
	ana.arayuz.arayuzu_guncelle()
	ana.harita.queue_redraw()
