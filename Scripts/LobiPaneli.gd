extends Control
class_name LobiPaneli

var lobi_verisi = {}
var is_updating = false
var benim_secilen_medeniyetim = ""

@onready var sohbet_gecmisi = %SohbetGecmisi
@onready var sohbet_girdisi = %SohbetGirdisi
@onready var gonder_btn = %GonderBtn

# --- MEDENİYET BİLGİSİ ---
var medeniyet_bilgileri = {
	"Osmanlı": {
		"hikaye": "Asya ile Avrupa'nın kucaklaştığı topraklarda doğan, devasa Şahi toplarıyla aşılmaz denilen surları yerle bir eden yenilmez bir imparatorluk. Yeniçerilerin ayak sesleri ve mehterin ritmi, savaş meydanlarında düşmanların kalbine korku salar. Sadece kılıçla değil, kurdukları muazzam ticaret ağları ve adalet sistemiyle de kıtalara hükmederler. Onlar için fetih, sadece toprak almak değil, nizam-ı alemi sağlamaktır.",
		"bonus": "🟢 [color=green][b]Topçu Bataryaları:[/b][/color] Savaşlarda atılan zarlar asla 1 gelmez (Her zaman 2, 3, 4, 5 veya 6 atarlar)."
	},
	"Mısır": {
		"hikaye": "Kavurucu çöllerin ortasında, Nil Nehri'nin can verdiği topraklarda yükselen altın çağın mimarları. Tanrı-kralların (Firavunların) emriyle sonsuzluğa uzanan devasa piramitler ve anıtlar, onların zamana ve kum fırtınalarına nasıl meydan okuduğunun en büyük kanıtıdır. Ölümün sadece bir başlangıç olduğuna inanan bu kadim halk, binalarını taşla değil, ebediyet arzusuyla inşa eder.",
		"bonus": "🟢 [color=green][b]Antik Mimari:[/b][/color] Tüm taş ocakları tur sonlarında +1 fazladan Taş üretir."
	},
	"Venedik": {
		"hikaye": "Akdeniz'in hırçın dalgalarına hükmeden tüccar prensler ve denizlerin mutlak hakimleri. Kılıçtan ziyade altının, entrikanın ve donanmanın gücüne inanan bu tüccar cumhuriyeti, paranın kokusunu ufukların ötesinden bile alır. Paralı askerleri ve muazzam kalyonlarıyla, tek bir damla kan dökmeden bile krallıkları dize getirebilecek devasa bir ekonomik güce sahiptirler.",
		"bonus": "🟢 [color=green][b]Tüccar Krallar:[/b][/color] Ticaret Merkezinde 1 Altın almak için 5 yerine sadece 4 kaynak öderler."
	},
	"Bizans": {
		"hikaye": "Bin yıllık Roma İmparatorluğu'nun kadim mirasını omuzlarında taşıyan, diplomasi ve entrikanın efsanevi başkenti. Yıkılmaz denilen Theodosius surlarının ardında, düşmanlarına dost görünürken en ölümcül zehri altın kadehlerde sunarlar. Askeri kaba kuvvetten ziyade, zekice kurgulanmış ittifaklar, kışkırtmalar ve siyasi manevralarla hayatta kalıp, rakiplerini birbirine kırdırırlar.",
		"bonus": "🟢 [color=green][b]Saray Entrikaları:[/b][/color] Savaşlarda attıkları 1 ve 2 zarları rakibin gücünü %50 düşürür."
	},
	"Moğol": {
		"hikaye": "Bozkırların sert ve dondurucu rüzgarıyla at süren, girdikleri her toprağı şimşek hızıyla fetheden durdurulamaz göçebe orduları. Şehir surlarının arkasına saklanmayı reddeden, uçsuz bucaksız çim arazilerde özgürce yaşayan bu savaşçılar; at üstündeki üstün okçuluk yetenekleri ve korkunç hızlarıyla tüm dünyaya boyun eğdirmiştir. Onlar için durmak, ölmek demektir.",
		"bonus": "🟢 [color=green][b]Göçebe Sürüleri:[/b][/color] Tüm tarlalar tur sonlarında +1 fazladan Yiyecek üretir."
	},
	"Viking": {
		"hikaye": "Kuzeyin dondurucu soğuğundan, karanlık fiyortlardan kopup gelen; dalgaların, fırtınaların ve ganimetin korkusuz efendileri. Onlar için savaşmak sadece bir mecburiyet değil, aynı zamanda Valhalla'ya ulaşmak için girilen onurlu bir yoldur. Ejderha başlı uzun gemileriyle sislerin içinden aniden belirir, acımasızca yağmalar ve arkalarında sadece yanan kaleler bırakırlar.",
		"bonus": "🟢 [color=green][b]Kuzeyin Gazabı:[/b][/color] Her başarılı savaşın ardından 5 altın kazanırlar."
	}
}

var medeniyet_basliklari = {
	"Osmanlı": { "isim": "Osmanlı İmparatorluğu", "lakap": "Topların ve Fetihlerin Efendileri" },
	"Mısır": { "isim": "Antik Mısır Krallığı", "lakap": "Nil'in Ebedi Mirasçıları" },
	"Venedik": { "isim": "Venedik Cumhuriyeti", "lakap": "Deniz Ticareti Ustaları" },
	"Bizans": { "isim": "Doğu Roma İmparatorluğu", "lakap": "Entrika ve İhtişamın Varisleri" },
	"Moğol": { "isim": "Moğol İmparatorluğu", "lakap": "Bozkırın Durdurulamaz Süvarileri" },
	"Viking": { "isim": "Viking Klanları", "lakap": "Kuzey Denizlerinin Yağmacıları" }
}

var med_dosya_isimleri = {
	"Osmanlı": "osmanli", "Mısır": "misir", "Venedik": "venedik",
	"Bizans": "bizans", "Moğol": "mogol", "Viking": "viking"
}

var oyuncu_renk_kodlari = {
	"Kirmizi": Color.RED, "Mavi": Color.BLUE, "Yesil": Color.GREEN,
	"Sari": Color.YELLOW, "Mor": Color.PURPLE, "CamGobegi": Color.CYAN
}

var secilebilir_renkler = [
	"Kirmizi", "Mavi", "Yesil", "Sari", "Mor", "CamGobegi"
]

# --- DÜĞÜM BAĞLANTILARI ---
@onready var oyuncu_vbox = %OyuncuVBox 
@onready var med_buton_kutusu = %MedeniyetButonlariKutusu 
@onready var hikaye_yazisi = %HikayeYazisi
@onready var bonus_yazisi = %BonusYazisi
@onready var hazir_btn = %HazirBtn
@onready var baslat_btn = %BaslatBtn
@onready var iptal_btn = %IptalBtn
@onready var lobiden_cik_btn = %LobidenCikBtn
@onready var baslik_hikaye = %BaslikHikaye
@onready var alt_baslik_hikaye = %AltBaslikHikaye

func _ready():
	# 1. TEMEL UI BAĞLANTILARI
	if hazir_btn: hazir_btn.pressed.connect(_hazir_butonuna_basildi)
	if iptal_btn: iptal_btn.pressed.connect(_hazir_butonuna_basildi)
	if baslat_btn: baslat_btn.pressed.connect(_oyunu_baslat_istegi)
	if lobiden_cik_btn: lobiden_cik_btn.pressed.connect(_lobiden_cik_basildi)
	
	if gonder_btn: gonder_btn.pressed.connect(_mesaj_gonder)
	if sohbet_girdisi: sohbet_girdisi.text_submitted.connect(func(_txt): _mesaj_gonder())
	
	for kart in med_buton_kutusu.get_children():
		if not kart.medeniyet_secildi.is_connected(_medeniyet_bayragina_tiklandi):
			kart.medeniyet_secildi.connect(_medeniyet_bayragina_tiklandi)
	
	for slot in oyuncu_vbox.get_children():
		if slot.has_signal("renk_secildi") and not slot.renk_secildi.is_connected(_renk_sec):
			slot.renk_secildi.connect(_renk_sec)

		# Multiplayer sinyalleri
	if not multiplayer.peer_connected.is_connected(_oyuncu_baglandi):
		multiplayer.peer_connected.connect(_oyuncu_baglandi)

	if not multiplayer.peer_disconnected.is_connected(_oyuncu_ayrildi):
		multiplayer.peer_disconnected.connect(_oyuncu_ayrildi)

	# Ayrı sahne açıldığı için lobiyi doğrudan başlat
	call_deferred("_lobiyi_baslat")
	
func _lobiyi_baslat() -> void:
	if multiplayer.multiplayer_peer == null:
		push_error("Lobi açıldı fakat aktif multiplayer bağlantısı bulunamadı!")
		return

	is_updating = false
	lobi_verisi.clear()
	benim_secilen_medeniyetim = ""

	# Oyunu başlatma butonunu yalnızca sunucu görür
	baslat_btn.visible = multiplayer.is_server()

	var benim_id := multiplayer.get_unique_id()

	# Önce kendimizi lobiye ekle
	_oyuncu_baglandi(benim_id)

	if multiplayer.is_server():
		# Sunucuda bulunan diğer oyuncuları ekle
		for oyuncu_id in multiplayer.get_peers():
			_oyuncu_baglandi(oyuncu_id)
	else:
		# İstemci sunucudaki mevcut lobi verilerini ister
		var baglanti_durumu := multiplayer.multiplayer_peer.get_connection_status()

		if baglanti_durumu == MultiplayerPeer.CONNECTION_CONNECTED:
			sunucudan_veri_iste_rpc.rpc_id(1)
		else:
			push_error("Lobi açıldı ancak sunucu bağlantısı hazır değil!")

	bilgi_panelini_guncelle("")
	lobi_arayuzunu_ciz()

func _lobiden_cik_basildi():
	# 1. Ağı ve portları tamamen kapat (YENİ)
	Network.baglantiyi_kapat()
	
	# 2. Lobi verilerini ve seçimleri temizle
	lobi_verisi.clear()
	benim_secilen_medeniyetim = ""
	if sohbet_gecmisi: sohbet_gecmisi.text = ""
	
	# 3. Ana Menü Sahnesine Geçiş Yap (Sahnenin adını kendi projene göre kontrol et)
	get_tree().change_scene_to_file("res://AnaMenu.tscn")

# --- SOHBET SİSTEMİ ---

func _mesaj_gonder():
	if not sohbet_girdisi: return
	
	var metin = sohbet_girdisi.text.strip_edges()
	if metin == "": return
	
	sohbet_girdisi.text = ""
	
	var my_id = multiplayer.get_unique_id()
	sohbet_mesaji_al_rpc.rpc(my_id, metin)

@rpc("any_peer", "call_local", "reliable")
func sohbet_mesaji_al_rpc(gonderen_id: int, mesaj: String):
	var gonderen = multiplayer.get_remote_sender_id()
	if gonderen == 0: gonderen = multiplayer.get_unique_id()
	if gonderen_id != gonderen or not sohbet_gecmisi: return
	
	# 🟢 DEĞİŞİKLİK: Ağdan gelen gerçek profil ismini kullanıyoruz
	var oyuncu_ismi = "Oyuncu " + str(gonderen_id).left(4)
	if lobi_verisi.has(gonderen_id) and lobi_verisi[gonderen_id].get("isim", "") != "":
		oyuncu_ismi = lobi_verisi[gonderen_id]["isim"]
	
	var renk_html = "white"
	
	if lobi_verisi.has(gonderen_id) and lobi_verisi[gonderen_id]["renk"] != "":
		var renk_ismi = lobi_verisi[gonderen_id]["renk"]
		if oyuncu_renk_kodlari.has(renk_ismi):
			renk_html = oyuncu_renk_kodlari[renk_ismi].to_html(false)
			
	var bb_metin = "[color=#%s][b]%s:[/b][/color] %s\n" % [renk_html, oyuncu_ismi, mesaj]
	sohbet_gecmisi.append_text(bb_metin)

func _sistem_mesaji(mesaj: String):
	if sohbet_gecmisi:
		sohbet_gecmisi.append_text("[color=gray][i]" + mesaj + "[/i][/color]\n")

func _renk_sec(renk:String):
	if is_updating: return
	var my_id = multiplayer.get_unique_id()
	if !lobi_verisi.has(my_id): return
	if lobi_verisi[my_id]["hazir_mi"]: return

	for id in lobi_verisi:
		if id == my_id: continue
		if lobi_verisi[id]["renk"] == renk: return

	lobi_verisi[my_id]["renk"] = renk

	lobi_bilgisi_gonder_rpc.rpc(
		my_id,
		Global.oyuncu_ismi,
		renk,
		lobi_verisi[my_id]["medeniyet"],
		false,
		Global.profil_no
	)

@rpc("any_peer", "call_remote", "reliable")
func sunucudan_veri_iste_rpc():
	if multiplayer.is_server():
		var isteyen_id = multiplayer.get_remote_sender_id()
		for peer in lobi_verisi:
			lobi_bilgisi_gonder_rpc.rpc_id(
				isteyen_id, 
				peer, 
				lobi_verisi[peer].get("isim", "Oyuncu"), 
				lobi_verisi[peer]["renk"], 
				lobi_verisi[peer]["medeniyet"], 
				lobi_verisi[peer]["hazir_mi"],
				lobi_verisi[peer].get("profil_no", 1)
			)

func _medeniyet_bayragina_tiklandi(med_ismi: String):
	if multiplayer.multiplayer_peer == null:
		return
	for kart in med_buton_kutusu.get_children():
		if kart.medeniyet == med_ismi: kart.secili_yap()
		else: kart.secimi_kaldir()
			
	if is_updating: return
	var my_id = multiplayer.get_unique_id()
	if not lobi_verisi.has(my_id): return
	if lobi_verisi[my_id].get("hazir_mi", false): return 
	
	benim_secilen_medeniyetim = med_ismi
	bilgi_panelini_guncelle(med_ismi)
	
	var r = lobi_verisi[my_id]["renk"]
	# 🟢 PARAMETRE GÜNCELLEME: İsmi ekledik
	lobi_bilgisi_gonder_rpc.rpc(my_id, Global.oyuncu_ismi, r, benim_secilen_medeniyetim, false, Global.profil_no)

func bilgi_panelini_guncelle(med: String):
	if medeniyet_bilgileri.has(med):
		baslik_hikaye.text = medeniyet_basliklari[med]["isim"]
		alt_baslik_hikaye.text = medeniyet_basliklari[med]["lakap"]
		hikaye_yazisi.text = "[i]" + medeniyet_bilgileri[med]["hikaye"] + "[/i]"
		bonus_yazisi.text = medeniyet_bilgileri[med]["bonus"]

	else:
		baslik_hikaye.text = "Medeniyet Seçilmedi"
		alt_baslik_hikaye.text = "Lütfen bir flama seçerek ilerleyin"
		hikaye_yazisi.text = ""
		bonus_yazisi.text = ""

func _hazir_butonuna_basildi():
	var my_id = multiplayer.get_unique_id()
	if not lobi_verisi.has(my_id): return
	
	if not lobi_verisi[my_id]["hazir_mi"]:
		for id in lobi_verisi:
			if id != my_id:
				if lobi_verisi[id]["medeniyet"] == benim_secilen_medeniyetim:
					_sistem_mesaji("❌ HATA: Seçtiğiniz medeniyet başka bir oyuncu tarafından alınmış!")
					hazir_btn.modulate = Color.RED
					await get_tree().create_timer(1.5).timeout
					if is_instance_valid(hazir_btn): hazir_btn.modulate = Color.WHITE
					hazir_btn.button_pressed = false 
					return
					
	lobi_verisi[my_id]["hazir_mi"] = !lobi_verisi[my_id]["hazir_mi"]
	
	if lobi_verisi[my_id]["hazir_mi"]: hazir_btn.modulate = Color.GREEN
	else: hazir_btn.modulate = Color.WHITE
		
	var r = lobi_verisi[my_id]["renk"]
	# 🟢 PARAMETRE GÜNCELLEME: İsmi ekledik
	lobi_bilgisi_gonder_rpc.rpc(my_id, Global.oyuncu_ismi, r, benim_secilen_medeniyetim, lobi_verisi[my_id]["hazir_mi"], Global.profil_no)

@rpc("any_peer", "call_local", "reliable")
func lobi_bilgisi_gonder_rpc(peer_id: int, isim: String, renk: String, medeniyet: String, hazir_mi: bool, profil_no: int):   # 🟢 YENİ PARAM
	var gonderen = multiplayer.get_remote_sender_id()
	if gonderen == 0: gonderen = multiplayer.get_unique_id()
	if not lobi_istegi_gecerli_mi(gonderen, peer_id, isim, renk, medeniyet, hazir_mi, profil_no): return
	if not lobi_verisi.has(peer_id):
		lobi_verisi[peer_id] = {"ilk_mesaj_gosterildi": false}
		
	lobi_verisi[peer_id]["isim"] = isim
	lobi_verisi[peer_id]["renk"] = renk
	lobi_verisi[peer_id]["medeniyet"] = medeniyet
	lobi_verisi[peer_id]["hazir_mi"] = hazir_mi
	lobi_verisi[peer_id]["profil_no"] = profil_no   # 🟢 YENİ
	
	if not lobi_verisi[peer_id].get("ilk_mesaj_gosterildi", false) and peer_id != multiplayer.get_unique_id():
		_sistem_mesaji(isim + " lobiye katıldı.")
		lobi_verisi[peer_id]["ilk_mesaj_gosterildi"] = true
		
	lobi_arayuzunu_ciz()

func lobi_istegi_gecerli_mi(gonderen: int, peer_id: int, isim: String, renk: String, medeniyet: String, hazir_mi: bool, profil_no: int) -> bool:
	if peer_id <= 0 or (gonderen != 1 and gonderen != peer_id): return false
	if isim.strip_edges().is_empty() or isim.length() > 16 or "[" in isim or "]" in isim: return false
	if renk != "" and renk not in secilebilir_renkler: return false
	if medeniyet != "" and not medeniyet_bilgileri.has(medeniyet): return false
	if hazir_mi and (renk == "" or medeniyet == ""): return false
	return profil_no >= 1 and profil_no <= 8

func _oyuncu_baglandi(id: int):
	if not lobi_verisi.has(id):
		var bs_med = ""
		var bs_renk = ""
		# Başkasıysa "Bağlanıyor..." diyoruz, çünkü henüz ismini bilmiyoruz
		var bs_isim = Global.oyuncu_ismi if id == multiplayer.get_unique_id() else "Bağlanıyor..."
			
		lobi_verisi[id] = {"isim": bs_isim, "renk": bs_renk, "medeniyet": bs_med, "hazir_mi": false, "ilk_mesaj_gosterildi": false, "profil_no": (Global.profil_no if id == multiplayer.get_unique_id() else 1)}
		lobi_arayuzunu_ciz()
		
		# Kendi ismimizi anında ağa bildiriyoruz
		if id == multiplayer.get_unique_id():
			# Kendi ekranımızda "Lobiye katıldın" yazsın ve bayrağı kapatsın
			_sistem_mesaji("Lobiye katıldın.")
			lobi_verisi[id]["ilk_mesaj_gosterildi"] = true
			
			if multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				lobi_bilgisi_gonder_rpc.rpc(id, Global.oyuncu_ismi, bs_renk, bs_med, false, Global.profil_no)
		
		if multiplayer.is_server():
			for peer in lobi_verisi:
				if multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
					lobi_bilgisi_gonder_rpc.rpc(peer, lobi_verisi[peer].get("isim", "Oyuncu"), lobi_verisi[peer]["renk"], lobi_verisi[peer]["medeniyet"], lobi_verisi[peer]["hazir_mi"], lobi_verisi[peer].get("profil_no", 1))

func _oyuncu_ayrildi(id: int):
	lobi_verisi.erase(id)
	lobi_arayuzunu_ciz()
	_sistem_mesaji("Bir oyuncu ayrıldı.")

func lobi_arayuzunu_ciz():
	if multiplayer.multiplayer_peer == null: return
		
	is_updating = true
	var herkes_hazir_mi = true
	var slotlar = oyuncu_vbox.get_children()
	
	var peer_idleri = lobi_verisi.keys()
	peer_idleri.sort()
	
	var my_id = multiplayer.get_unique_id()
	
	for i in range(slotlar.size()):
		var slot = slotlar[i]
		
		var profil_resmi = slot.get_node_or_null("%HukumdarResmi")
		var isim_lbl = slot.get_node_or_null("%OyuncuIsmi")
		var med_lbl = slot.get_node_or_null("%SeciliMedeniyetBaslik")
		var bayrak_resmi = slot.find_child("Bayrak", true, false)
		var durum_ikon = slot.find_child("HazirIkon", true, false)
		var renk_butonlari = slot.get_node_or_null("%RenkKutusu")
		
		if i < peer_idleri.size():
			var id = peer_idleri[i]
			var veri = lobi_verisi[id]
			var med = veri["medeniyet"]
			
			slot.modulate = Color.WHITE
			
			var ismin_rengi = oyuncu_renk_kodlari.get(veri["renk"], Color.WHITE)
			
			if isim_lbl: 
				isim_lbl.text = veri.get("isim", "Oyuncu " + str(id).left(4))
				isim_lbl.add_theme_color_override("font_color", ismin_rengi)
				
			if med_lbl: 
				med_lbl.text = med.to_upper() if med != "" else "-"
				med_lbl.add_theme_color_override("font_color", ismin_rengi)
			
			if profil_resmi:
				var p_no = veri.get("profil_no", 1)
				var yol = "res://Assets/Resimler/Profil%d.png" % p_no
				profil_resmi.texture = load(yol) if ResourceLoader.exists(yol) else null
					
			# 🟢 Bayrak Resmi Ataması (Medeniyete göre değişir)
			if bayrak_resmi:
				if med != "":
					var by_yolu = "res://Assets/Flamalar/" + med_dosya_isimleri.get(med, "") + "_flama.png"
					if ResourceLoader.exists(by_yolu): bayrak_resmi.texture = load(by_yolu)
					else: bayrak_resmi.texture = null
				else:
					bayrak_resmi.texture = null
				
			if durum_ikon:
				durum_ikon.modulate = Color.WHITE
				if veri["hazir_mi"]: durum_ikon.texture = load("res://Assets/Resimler/hazir.png")
				else: durum_ikon.texture = load("res://Assets/Resimler/hazirdegil.png")
				if not veri["hazir_mi"]: herkes_hazir_mi = false
					
			if renk_butonlari:
				if id == my_id:
					renk_butonlari.visible = true
					renk_butonlari.modulate = Color.WHITE
					
					for btn in renk_butonlari.get_children():
						btn.toggle_mode = true 
						var btn_renk = btn.name
						btn.disabled = false
						btn.scale = Vector2.ONE 
						btn.button_pressed = false 
						btn.modulate = Color.WHITE 
						
						if btn_renk == veri["renk"]: btn.button_pressed = true
							
						for pid in lobi_verisi:
							if pid != my_id and lobi_verisi[pid]["renk"] == btn_renk and btn_renk != "":
								btn.disabled = true
								btn.button_pressed = false
								btn.modulate = Color(0.35, 0.35, 0.35)
								
						if veri["hazir_mi"]:
							btn.disabled = true
							if btn_renk != veri["renk"]: btn.modulate = Color(0.5, 0.5, 0.5)
				else:
					renk_butonlari.visible = true
					renk_butonlari.modulate = Color(1, 1, 1, 0)
					for btn in renk_butonlari.get_children(): btn.disabled = true
		else:
			slot.modulate = Color(1, 1, 1, 0.3)
			if isim_lbl: 
				isim_lbl.text = "Açık"
				isim_lbl.add_theme_color_override("font_color", Color.WHITE) 
			if med_lbl: 
				med_lbl.text = "-"
				med_lbl.add_theme_color_override("font_color", Color.WHITE)
			if profil_resmi: profil_resmi.texture = null
			if bayrak_resmi: bayrak_resmi.texture = null
			if durum_ikon: 
				durum_ikon.texture = load("res://Assets/Resimler/hazirdegil.png")
				durum_ikon.modulate = Color(1, 1, 1, 0.4)
			if renk_butonlari: 
				renk_butonlari.visible = true
				renk_butonlari.modulate = Color(1, 1, 1, 0)
				for btn in renk_butonlari.get_children(): btn.disabled = true

	if baslat_btn:
		baslat_btn.disabled = not (herkes_hazir_mi and lobi_verisi.size() > 0)
		
	if hazir_btn and iptal_btn and lobi_verisi.has(my_id):
		var benim_verim = lobi_verisi[my_id]
		var secimler_tamam = (benim_verim["renk"] != "" and benim_verim["medeniyet"] != "")
		
		if benim_verim["hazir_mi"]:
			hazir_btn.visible = false
			iptal_btn.visible = true
			if lobiden_cik_btn: lobiden_cik_btn.disabled = true 
		else:
			iptal_btn.visible = false
			hazir_btn.visible = true
			hazir_btn.disabled = not secimler_tamam
			if lobiden_cik_btn: lobiden_cik_btn.disabled = false
		
	var my_data = lobi_verisi.get(my_id, {})
	var ben_hazir_durumdayim = my_data.get("hazir_mi", false)
	
	for kart in med_buton_kutusu.get_children():
		if kart.has_method("kilidi_ac"): kart.kilidi_ac()
		if ben_hazir_durumdayim and kart.medeniyet != my_data.get("medeniyet", ""):
			if kart.has_method("kilitle"): kart.kilitle()
				
		for id in lobi_verisi:
			if id == my_id: continue
			if lobi_verisi[id]["medeniyet"] == kart.medeniyet and kart.medeniyet != "":
				if kart.has_method("kilitle"): kart.kilitle()
				
		if ben_hazir_durumdayim and kart.medeniyet == my_data.get("medeniyet", ""):
			var flm = kart.get_node_or_null("Flama")
			if flm: flm.disabled = true

	is_updating = false

func _oyunu_baslat_istegi():
	if multiplayer.is_server():
		# Aynı anda seçim yapan iki oyuncu aynı rengi/medeniyeti alabiliyordu: son kez sunucuda kontrol et
		var renkler = []
		var medeniyetler = []
		for id in lobi_verisi:
			var v = lobi_verisi[id]
			if not lobi_istegi_gecerli_mi(1, id, v.get("isim", ""), v.get("renk", ""), v.get("medeniyet", ""), true, v.get("profil_no", 1)) or not v.get("hazir_mi", false):
				_sistem_mesaji("❌ Herkes renk ve medeniyet seçip hazır olmalı!")
				return
			if v["renk"] in renkler or v["medeniyet"] in medeniyetler:
				_sistem_mesaji("❌ İki oyuncu aynı rengi veya medeniyeti seçmiş! Biri değiştirmeli.")
				return
			renkler.append(v["renk"])
			medeniyetler.append(v["medeniyet"])
		# Oyun başladıktan sonra yeni oyuncu bağlanamasın
		if multiplayer.multiplayer_peer: multiplayer.multiplayer_peer.refuse_new_connections = true
		randomize()
		oyuna_gecis_yap_rpc.rpc(lobi_verisi, randi())

@rpc("authority", "call_local", "reliable")
func oyuna_gecis_yap_rpc(son_lobi_verisi: Dictionary, tohum: int = 0):
	Network.son_lobi_verisi = son_lobi_verisi
	Network.oyun_tohumu = tohum
	get_tree().change_scene_to_file("res://AnaOyun.tscn")
