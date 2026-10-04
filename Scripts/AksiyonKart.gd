extends Node
class_name AksiyonKart

var aksiyon: Node
var ana: Node

func baslat(_aksiyon):
	aksiyon = _aksiyon
	ana = aksiyon.ana

func kart_kullan(idx):
	if ana.aktif_sira != ana.benim_indexim or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	
	var kart = ana.deste.el[idx]
	ana.secili_kart_index = idx
	ana.secili_piyon_index = -1
	
	# 🟢 DEĞİŞİKLİK: Kullan butonuna basıldığında kartın modunu aktif et
	if kart.get("hedef") == "harita" or kart.get("hedef") == "kendi_binasi":
		ana.kart_insa_modu_aktif = true
		ana.arayuz.olay_yaz("[color=yellow]➔ Hedefi seçmek için haritaya tıklayın.[/color]")
		
		# 🟢 BU SATIRI EKLİYORUZ (Yorum satırından çıkardık):
		aksiyon.insa_modul._kurulabilir_hexleri_hesapla(kart)
	else:
		# Eğer hedef harita değilse (savaş veya direkt etki eden bir kartsa) anında kullan
		ana.kart_insa_modu_aktif = false 
		_secili_karti_direkt_kullan()
	
	ana.harita.queue_redraw()
	ana.arayuz.arayuzu_guncelle()

func kart_cope_at(idx):
	if ana.aktif_sira != ana.benim_indexim: return
	
	ana.deste.karti_elden_at(idx)
	ana.secili_kart_index = -1
	ana.kart_insa_modu_aktif = false # İşlem iptal olduğu için harita modunu kapat
	
	ana.harita.queue_redraw()
	ana.arayuz.arayuzu_guncelle()

func karti_kaynaga_cevir(idx):
	if ana.aktif_sira != ana.benim_indexim or ana.aktif_oyuncu_aksiyon_hakki <= 0 or ana.savas.savas_aktif: return
	if idx < 0 or idx >= ana.deste.el.size(): return
	var kart = ana.deste.el[idx]
	var kaynak = "odun"
	if kart.get("hedef") == "savas": kaynak = "altin"
	elif kart.get("tur") == "ticaret_merkezi": kaynak = ["odun", "tas", "yiyecek"].pick_random()
	elif kart.get("tur") in ["tarla", "gelismis_sulama"]: kaynak = "yiyecek"
	elif kart.get("tur") in ["tas_ocagi", "derin_damarlar"]: kaynak = "tas"
	aksiyon.karti_feda_et_rpc.rpc(ana.oyuncular[ana.benim_indexim], kaynak, idx)
	ana.secili_kart_index = -1
	ana.kart_insa_modu_aktif = false
	ana.kurulabilir_hexler.clear()
	ana.harita.queue_redraw()
	ana.arayuz.arayuzu_guncelle()

func _secili_karti_direkt_kullan():
	var kart = ana.deste.el[ana.secili_kart_index]
	aksiyon.aksiyon_karti_kullan_rpc.rpc(ana.oyuncular[ana.benim_indexim], kart["tur"], ana.secili_kart_index)
	
	ana.secili_kart_index = -1
	ana.kart_insa_modu_aktif = false
	
	ana.harita.queue_redraw()

