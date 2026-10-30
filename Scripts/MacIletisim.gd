extends Node
class_name MacIletisim

# Maç içi sohbet ve oyuncular arası kaynak takası. İkisi de sunucudan geçer:
# sunucu göndereni, kaynakları ve sırayı doğrular, sonucu herkese aynı sırayla yayınlar.

const KAYNAKLAR = ["odun", "tas", "yiyecek", "altin"]
const KAYNAK_ADLARI = {"odun": "Odun", "tas": "Taş", "yiyecek": "Yiyecek", "altin": "Altın"}
const EN_COK_MIKTAR = 30
const TEKLIF_SURESI := 30.0
const SOHBET_ARALIGI := 0.6

var ana
var _son_mesaj := {}         # sunucu: peer -> son mesaj zamanı (ms)
var _teklif := {}            # sunucu: bekleyen tek teklif
var _teklif_sayaci := 0
var _gelen_teklif := {}      # istemci: ekrandaki teklif

func _ready():
	ana = get_parent()
	var girdi = ana.get_node_or_null("%MacSohbetGirdisi")
	if girdi:
		girdi.visible = false
		girdi.text_submitted.connect(_sohbet_gonder)
	var takas_btn = ana.get_node_or_null("%TakasBtn")
	if takas_btn: takas_btn.pressed.connect(takas_penceresi_ac)
	var kabul = ana.get_node_or_null("%TakasKabulBtn")
	if kabul: kabul.pressed.connect(func(): _teklife_yanit(true))
	var red = ana.get_node_or_null("OyunArayuzu/TakasPaneli/MarginContainer/VBoxContainer/TakasRedBtn")
	if red: red.pressed.connect(func(): _teklife_yanit(false))

var _sohbet_ayarlandi := false

func _process(_delta: float):
	# Sohbet yalnızca birden çok insan oyuncu varken görünür (dönüşte oyuncular sonradan gelir).
	if not _sohbet_ayarlandi and not ana.oyuncular.is_empty():
		_sohbet_ayarlandi = true
		var girdi = ana.get_node_or_null("%MacSohbetGirdisi")
		if girdi: girdi.visible = _insan_sayisi() > 1
	if _teklif.is_empty() or multiplayer.multiplayer_peer == null or not multiplayer.is_server(): return
	# Teklif süresi dolunca veya sıra değişince düşer.
	if Time.get_ticks_msec() > _teklif["bitis"] or ana.aktif_sira != _teklif["sira"] or ana.tur_sayaci != _teklif["tur"] or ana.oyun_bitti:
		_teklifi_kapat("⌛ Takas teklifi zaman aşımına uğradı.")

func _insan_sayisi() -> int:
	return ana.oyuncular.size() - ana.yapay_zeka_oyunculari.size()

func _ben() -> String:
	return ana.oyuncular[ana.benim_indexim] if not ana.oyuncular.is_empty() else ""

func _gonderen_ismi() -> String:
	var peer = multiplayer.get_remote_sender_id()
	if peer == 0: peer = multiplayer.get_unique_id()
	var idx = ana.oyuncu_peer_idleri.find(peer)
	return ana.oyuncular[idx] if idx != -1 else ""

func _sunucuya(metod: StringName, args: Array):
	if multiplayer.is_server(): callv(metod, args)
	else: callv("rpc_id", [1, metod] + args)

# --- SOHBET ---
func _sohbet_gonder(metin: String):
	var girdi = ana.get_node_or_null("%MacSohbetGirdisi")
	if girdi:
		girdi.clear()
		girdi.release_focus()
	if metin.strip_edges().is_empty(): return
	_sunucuya(&"mac_sohbet_rpc", [metin])

@rpc("any_peer", "call_remote", "reliable")
func mac_sohbet_rpc(metin: String):
	if not multiplayer.is_server(): return
	var isim = _gonderen_ismi()
	if isim == "" or ana.bot_mu(isim) or isim in ana.ayrilan_oyuncular: return
	var peer = ana.oyuncu_peer_id(isim)
	var simdi = Time.get_ticks_msec()
	if simdi - _son_mesaj.get(peer, -100000) < int(SOHBET_ARALIGI * 1000): return
	_son_mesaj[peer] = simdi
	var temiz = metin.strip_edges().replace("\n", " ").left(200)
	if temiz.is_empty(): return
	mac_sohbet_yayin_rpc.rpc(isim, temiz)

@rpc("authority", "call_local", "reliable")
func mac_sohbet_yayin_rpc(isim: String, metin: String):
	if isim not in ana.oyuncular: return
	ana.arayuz.olay_yaz("💬 %s: %s" % [ana.arayuz.renkli_isim(isim), metin.replace("[", "[lb]")])

# --- TAKAS: TEKLİF PENCERESİ ---
func takas_penceresi_ac():
	var menu = ana.oyun_menusu
	var ben = _ben()
	menu._temizle("TAKAS")
	if ana.aktif_sira != ana.benim_indexim or not ana.ilk_tur_bitti or ana.savas.savas_aktif:
		menu._metin("Takas teklifini yalnızca kendi turunda, savaş yokken yapabilirsin. Teklif AP harcamaz.")
		menu._buton("Kapat", menu.perde.hide)
		menu.perde.show()
		return
	var hedefler = ana.oyuncular.filter(func(o): return o != ben and o not in ana.ayrilan_oyuncular)
	if hedefler.is_empty():
		menu._metin("Takas yapılacak başka hükümdar yok.")
		menu._buton("Kapat", menu.perde.hide)
		menu.perde.show()
		return
	menu._metin("Bir hükümdara kaynak takası öner. Kabul ederse takas hemen gerçekleşir; teklif 30 saniye veya tur sonuna kadar geçerlidir.")
	var hedef = _secici("TakasHedef", hedefler)
	var ver = _kaynak_satiri("Veriyorum", "TakasVer")
	var al = _kaynak_satiri("İstiyorum", "TakasAl")
	al[0].select(1)
	menu._buton("Teklif et", func():
		var h = hedefler[hedef.selected]
		var vt = KAYNAKLAR[ver[0].selected]
		var at = KAYNAKLAR[al[0].selected]
		menu.perde.hide()
		takas_teklif_et(h, vt, int(ver[1].value), at, int(al[1].value))).theme_type_variation = &"HukumPrimary"
	menu._buton("Vazgeç", menu.perde.hide)
	menu.perde.show()

func _secici(ad: String, secenekler: Array) -> OptionButton:
	var secici = OptionButton.new()
	secici.name = ad
	secici.custom_minimum_size.y = 44
	for s in secenekler: secici.add_item(str(s))
	ana.oyun_menusu.satirlar.add_child(secici)
	return secici

func _kaynak_satiri(etiket: String, ad: String) -> Array:
	var satir = HBoxContainer.new()
	satir.name = ad
	satir.add_theme_constant_override("separation", 12)
	var yazi = Label.new()
	yazi.text = etiket
	yazi.custom_minimum_size.x = 140
	yazi.add_theme_font_size_override("font_size", 20)
	satir.add_child(yazi)
	var tur = OptionButton.new()
	tur.name = "Tur"
	tur.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tur.custom_minimum_size.y = 44
	for k in KAYNAKLAR: tur.add_item(KAYNAK_ADLARI[k])
	satir.add_child(tur)
	var miktar = SpinBox.new()
	miktar.name = "Miktar"
	miktar.min_value = 1
	miktar.max_value = EN_COK_MIKTAR
	miktar.value = 2
	miktar.custom_minimum_size = Vector2(120, 44)
	satir.add_child(miktar)
	ana.oyun_menusu.satirlar.add_child(satir)
	return [tur, miktar]

func takas_teklif_et(hedef: String, ver_tur: String, ver_miktar: int, al_tur: String, al_miktar: int):
	_sunucuya(&"takas_teklif_rpc", [hedef, ver_tur, ver_miktar, al_tur, al_miktar])

# --- TAKAS: SUNUCU ---
@rpc("any_peer", "call_remote", "reliable")
func takas_teklif_rpc(hedef: String, ver_tur: String, ver_miktar: int, al_tur: String, al_miktar: int):
	if not multiplayer.is_server(): return
	var gonderen = _gonderen_ismi()
	var hata = _teklif_hatasi(gonderen, hedef, ver_tur, ver_miktar, al_tur, al_miktar)
	if hata != "":
		_bildir(gonderen, "❌ " + hata)
		return
	_teklif_sayaci += 1
	_teklif = {"id": _teklif_sayaci, "veren": gonderen, "alan": hedef, "ver_tur": ver_tur, "ver_miktar": ver_miktar,
		"al_tur": al_tur, "al_miktar": al_miktar, "sira": ana.aktif_sira, "tur": ana.tur_sayaci,
		"bitis": Time.get_ticks_msec() + int(TEKLIF_SURESI * 1000)}
	if ana.bot_mu(hedef):
		_takasi_sonuclandir(_bot_kabul_eder_mi(hedef))
		return
	_bildir(gonderen, "📨 Takas teklifin %s hükümdarına iletildi." % hedef)
	var peer = ana.oyuncu_peer_id(hedef)
	var metin = "%s sana %d %s veriyor,\nkarşılığında %d %s istiyor." % [gonderen, ver_miktar, KAYNAK_ADLARI[ver_tur], al_miktar, KAYNAK_ADLARI[al_tur]]
	if peer == multiplayer.get_unique_id(): takas_teklifi_goster_rpc(_teklif["id"], metin)
	else: takas_teklifi_goster_rpc.rpc_id(peer, _teklif["id"], metin)

func _teklif_hatasi(gonderen: String, hedef: String, ver_tur: String, ver_miktar: int, al_tur: String, al_miktar: int) -> String:
	if gonderen == "" or ana.oyun_bitti: return "Takas şu an yapılamaz."
	if ana.aktif_sira >= ana.oyuncular.size() or ana.oyuncular[ana.aktif_sira] != gonderen or not ana.ilk_tur_bitti or ana.savas.savas_aktif:
		return "Takas teklifini yalnızca kendi turunda, savaş yokken yapabilirsin."
	if not _teklif.is_empty(): return "Önceki teklifin yanıt bekliyor."
	if hedef == gonderen or hedef not in ana.oyuncular or hedef in ana.ayrilan_oyuncular: return "Geçersiz takas hedefi."
	if ver_tur not in KAYNAKLAR or al_tur not in KAYNAKLAR or ver_tur == al_tur: return "Farklı iki kaynak seçmelisin."
	if ver_miktar < 1 or al_miktar < 1 or ver_miktar > EN_COK_MIKTAR or al_miktar > EN_COK_MIKTAR: return "Miktar 1 ile %d arasında olmalı." % EN_COK_MIKTAR
	if ana.oyuncu_kaynaklari[gonderen][ver_tur] < ver_miktar: return "Teklif ettiğin kadar %s yok." % KAYNAK_ADLARI[ver_tur]
	return ""

func _bot_kabul_eder_mi(bot: String) -> bool:
	var k = ana.oyuncu_kaynaklari[bot]
	return _teklif["ver_miktar"] >= _teklif["al_miktar"] and k[_teklif["al_tur"]] >= _teklif["al_miktar"] + 2

@rpc("any_peer", "call_remote", "reliable")
func takas_yanit_rpc(teklif_id: int, kabul: bool):
	if not multiplayer.is_server() or _teklif.is_empty() or _teklif["id"] != teklif_id: return
	if _gonderen_ismi() != _teklif["alan"]: return
	_takasi_sonuclandir(kabul)

func _takasi_sonuclandir(kabul: bool):
	var t = _teklif
	_teklif = {}
	var veren = t["veren"]
	var alan = t["alan"]
	if not kabul:
		takas_sonucu_rpc.rpc(veren, alan, "", 0, "", 0)
		return
	var kv = ana.oyuncu_kaynaklari[veren]
	var ka = ana.oyuncu_kaynaklari[alan]
	if kv[t["ver_tur"]] < t["ver_miktar"] or ka[t["al_tur"]] < t["al_miktar"]:
		takas_sonucu_rpc.rpc(veren, alan, "", -1, "", 0)
		return
	takas_sonucu_rpc.rpc(veren, alan, t["ver_tur"], t["ver_miktar"], t["al_tur"], t["al_miktar"])

func _teklifi_kapat(mesaj: String):
	var t = _teklif
	_teklif = {}
	var peer = ana.oyuncu_peer_id(t["alan"])
	if peer == multiplayer.get_unique_id(): takas_teklifi_kapat_rpc()
	elif peer > 0 and peer in multiplayer.get_peers(): takas_teklifi_kapat_rpc.rpc_id(peer)
	_bildir(t["veren"], mesaj)

# Yalnızca ilgili oyuncunun ekranına sistem mesajı.
func _bildir(isim: String, mesaj: String):
	var peer = ana.oyuncu_peer_id(isim)
	if peer == multiplayer.get_unique_id(): bildirim_rpc(mesaj)
	elif peer > 0 and peer in multiplayer.get_peers(): bildirim_rpc.rpc_id(peer, mesaj)

# --- TAKAS: HERKES ---
@rpc("authority", "call_local", "reliable")
func takas_sonucu_rpc(veren: String, alan: String, ver_tur: String, ver_miktar: int, al_tur: String, al_miktar: int):
	if veren not in ana.oyuncular or alan not in ana.oyuncular: return
	takas_teklifi_kapat_rpc()
	if ver_miktar == 0:
		ana.arayuz.olay_yaz("[color=light_coral]🤝 %s, %s hükümdarının takas teklifini reddetti.[/color]" % [ana.arayuz.renkli_isim(alan), ana.arayuz.renkli_isim(veren)])
		return
	if ver_miktar < 0:
		ana.arayuz.olay_yaz("[color=light_coral]🤝 Takas gerçekleşmedi: kaynaklar artık yetmiyor.[/color]")
		return
	ana.oyuncu_kaynaklari[veren][ver_tur] -= ver_miktar
	ana.oyuncu_kaynaklari[alan][ver_tur] += ver_miktar
	ana.oyuncu_kaynaklari[alan][al_tur] -= al_miktar
	ana.oyuncu_kaynaklari[veren][al_tur] += al_miktar
	SesYoneticisi.efekt_cal("kart_cek")
	ana.arayuz.olay_yaz("🤝 [color=gold]Takas:[/color] %s %d %s verdi, %s %d %s verdi." % [ana.arayuz.renkli_isim(veren), ver_miktar, KAYNAK_ADLARI[ver_tur], ana.arayuz.renkli_isim(alan), al_miktar, KAYNAK_ADLARI[al_tur]])
	ana.arayuz.arayuzu_guncelle()

@rpc("authority", "call_remote", "reliable")
func takas_teklifi_goster_rpc(teklif_id: int, metin: String):
	_gelen_teklif = {"id": teklif_id}
	var panel = ana.get_node_or_null("%TakasPaneli")
	var yazi = ana.get_node_or_null("%TakasMetni")
	if yazi: yazi.text = "TAKAS TEKLİFİ\n" + metin.left(200)
	if panel: panel.show()
	SesYoneticisi.efekt_cal("sira_sende")

@rpc("authority", "call_remote", "reliable")
func takas_teklifi_kapat_rpc():
	_gelen_teklif = {}
	var panel = ana.get_node_or_null("%TakasPaneli")
	if panel: panel.hide()

@rpc("authority", "call_remote", "reliable")
func bildirim_rpc(mesaj: String):
	ana.arayuz.olay_yaz("[color=orange]%s[/color]" % mesaj.left(200))

func _teklife_yanit(kabul: bool):
	if _gelen_teklif.is_empty(): return
	var id = _gelen_teklif["id"]
	takas_teklifi_kapat_rpc()
	_sunucuya(&"takas_yanit_rpc", [id, kabul])
