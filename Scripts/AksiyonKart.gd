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
	if ana.aktif_sira != ana.benim_indexim or ana.aktif_oyuncu_aksiyon_hakki <= 0: return
	
	var kart = ana.deste.el[idx]
	var tur = kart.get("tur", "")
	var kaynak = "altin" # Varsayılan kaynak
	
	# 🟢 2. DEĞİŞİKLİK: Kart türüne göre spesifik kaynak belirleme
	if tur in ["oduncu_kampi", "up_oduncu"]:
		kaynak = "odun"
	elif tur in ["tas_ocagi", "up_tas"]:
		kaynak = "tas"
	elif tur in ["tarla", "up_tarla"]:
		kaynak = "yiyecek"
	elif tur == "ticaret_merkezi":
		kaynak = "altin"
	elif kart.get("hedef") == "savas":
		kaynak = "yiyecek" # Savaş/Asker kartları feda edilirse asker erzağı (yiyecek) gelir
		
	# Mevcut RPC yapını bozmamak için sadece türü gönderiyoruz
	aksiyon.karti_feda_et_rpc.rpc(ana.oyuncular[ana.benim_indexim], kaynak)
	
	ana.deste.karti_elden_at(idx)
	ana.secili_kart_index = -1
	ana.kart_insa_modu_aktif = false # Modu temizle
	ana.harita.queue_redraw()
	
	var emoji = "🪙" if kaynak == "altin" else "🌲" if kaynak == "odun" else "🪨" if kaynak == "tas" else "🌾"
	ana.arayuz.olay_yaz("[color=gold]♻️ Kart dönüştürüldü! Kazanılan: 1 %s %s[/color]" % [emoji, kaynak.to_upper()])
	ana.arayuz.arayuzu_guncelle()

func _secili_karti_direkt_kullan():
	var kart = ana.deste.el[ana.secili_kart_index]
	aksiyon.aksiyon_karti_kullan_rpc.rpc(ana.oyuncular[ana.benim_indexim], kart["tur"])
	
	ana.deste.el.remove_at(ana.secili_kart_index)
	ana.secili_kart_index = -1
	ana.kart_insa_modu_aktif = false
	
	ana.harita.queue_redraw()
