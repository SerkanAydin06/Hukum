extends Node

signal durum_degisti(mesaj: String, hata: bool)
signal lobi_degisti
signal gecikme_degisti(ms: int)
signal mac_sona_erdi(kazanan: String)

const PORT := 7777
const DEFAULT_IP := "127.0.0.1"
const MAX_PLAYERS := 6
const VALIDATOR = preload("res://Scripts/PardexBiletDogrulayici.gd")
const REPORTER = preload("res://Scripts/PardexSunucuRaporlayici.gd")

var son_baglanti_mesaji := ""
var son_lobi_verisi := {}
var peer = ENetMultiplayerPeer.new()
var ortak_sifre := 0
var oyun_tohumu: int = 0
var merkezi_mod := false
var dedicated_mode := false
var resmi_mod := false
var oturum_asamasi := "offline"
var oda_kodu := ""
var oda_sahibi_id := 1
var merkezi_lobi := {}
var sunucu_adresi := ""
var gecikme_ms := -1
var _onayli := {}
var _mac_kimlikleri := {}
var _bekleyen := {}
var _hazir_sahneler := []
var _match_id := ""
var _online_url := ""
var _server_token := ""
var _ping_sayaci := 0.0
var _baglanti_suresi := 0.0
var _sonuc_bildiriliyor := false
var _boot_port := 8766
var alistirma_rakip_sayisi := 0   # tek oyunculu alıştırmadaki yapay zekâ rakip sayısı
var ogretici_modu := false        # bir sonraki tek oyunculu maç öğreticiyle açılır

func _ready():
	_donus_yukle()
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	if PardexBridge.dedicated or "--hukum-server" in OS.get_cmdline_user_args():
		_boot.call_deferred()

func host_game(port: int = PORT) -> bool:
	baglantiyi_kapat()
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS - 1)
	if error != OK: return false
	multiplayer.multiplayer_peer = peer
	ortak_sifre = randi()
	oturum_asamasi = "lobby"
	sunucu_adresi = "UDP %d" % port
	return true

func join_game(ip_address: String, port: int = PORT) -> bool:
	baglantiyi_kapat()
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(DEFAULT_IP if ip_address.is_empty() else ip_address, port)
	if error != OK: return false
	multiplayer.multiplayer_peer = peer
	oturum_asamasi = "connecting"
	sunucu_adresi = "%s:%d" % [ip_address, port]
	_son_hedef = {"tur": "enet", "adres": DEFAULT_IP if ip_address.is_empty() else ip_address, "port": port}
	return true

func ozel_sunucuya_katil(url: String) -> bool:
	if not PardexBridge.valid_url(url): return false
	baglantiyi_kapat()
	return _ws_baglan(url, false)

func pardex_oyununa_katil() -> bool:
	if not PardexBridge.should_auto_enter_lobby(): return false
	# Oda bileti baglantiyi_kapat sırasında temizlenmemeli.
	_ag_temizle()
	return _ws_baglan(PardexBridge.game_server_url, true)

func _ws_baglan(url: String, official: bool) -> bool:
	peer = WebSocketMultiplayerPeer.new()
	if peer.create_client(url) != OK:
		_ag_temizle()
		return false
	merkezi_mod = true
	resmi_mod = official
	oturum_asamasi = "connecting"
	sunucu_adresi = url
	_son_hedef = {"tur": "pardex" if official else "ws", "adres": url, "port": 0}
	multiplayer.multiplayer_peer = peer
	durum_degisti.emit("Oyun sunucusuna bağlanılıyor…", false)
	return true

func _boot():
	_boot_port = int(_arg("--port=", _arg("--pardex-port=", OS.get_environment("PORT"))))
	if _boot_port <= 0: _boot_port = 8766
	var official = PardexBridge.dedicated
	_online_url = _arg("--pardex-online-server=", OS.get_environment("PARDEX_ONLINE_SERVER_URL"))
	_server_token = OS.get_environment("PARDEX_GAME_SERVER_TOKEN").strip_edges()
	if official and (not PardexBridge.valid_url(_online_url) or _server_token.length() < 32):
		push_error("PARDEX sunucu doğrulama ayarları eksik.")
		get_tree().quit(2)
		return
	if not merkezi_sunucu_baslat(_boot_port, official):
		push_error("HÜKÜM WebSocket sunucusu başlatılamadı.")
		get_tree().quit(2)
		return
	if official: _raporla("game_server_hello", {"game_protocol": PardexBridge.NET_PROTOCOL})

func merkezi_sunucu_baslat(port: int, official := false) -> bool:
	_ag_temizle()
	_boot_port = port
	peer = WebSocketMultiplayerPeer.new()
	if peer.create_server(port, "0.0.0.0") != OK: return false
	multiplayer.multiplayer_peer = peer
	merkezi_mod = true
	dedicated_mode = true
	resmi_mod = official
	oturum_asamasi = "lobby"
	oda_sahibi_id = 0
	sunucu_adresi = "WebSocket %d" % port
	get_tree().change_scene_to_file.call_deferred("res://LobiPaneli.tscn")
	print("HUKUM_SERVER_READY port=%d official=%s" % [port, official])
	return true

func _arg(prefix: String, fallback := "") -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with(prefix): return value.trim_prefix(prefix).strip_edges()
	return fallback

func _process(delta: float):
	if oturum_asamasi == "connecting":
		_baglanti_suresi += delta
		if _baglanti_suresi > 22.0:
			son_baglanti_mesaji = "Sunucu yanıt vermedi. Adresi kontrol edip tekrar dene."
			baglantiyi_kapat()
			durum_degisti.emit(son_baglanti_mesaji, true)
	if merkezi_mod and not dedicated_mode and oturum_asamasi in ["lobby", "game", "loading"]:
		_ping_sayaci += delta
		if _ping_sayaci >= 3.0:
			_ping_sayaci = 0.0
			ping_istegi_rpc.rpc_id(1, Time.get_ticks_msec())

func _on_player_connected(id: int):
	if dedicated_mode:
		if multiplayer.get_peers().size() > MAX_PLAYERS * 2:
			_reddet(id)
			return
		# Ham bağlantı, lobi koltuğu veya oyun kimliği oluşturmaz.
		get_tree().create_timer(20.0).timeout.connect(func():
			if dedicated_mode and not _onayli.has(id): _reddet(id))

func _on_connected_ok():
	if geri_donuyor:
		durum_degisti.emit("Sunucuya bağlanıldı · maça dönülüyor…", false)
		geri_katil_rpc.rpc_id(1, str(donus_kaydi.get("anahtar", "")))
		return
	if not merkezi_mod:
		oturum_asamasi = "lobby"
		return
	durum_degisti.emit("Sunucuya bağlanıldı · giriş doğrulanıyor…", false)
	if resmi_mod:
		kayit_istegi_rpc.rpc_id(1, PardexBridge.NET_PROTOCOL, Global.oyuncu_ismi, Global.profil_no,
			PardexBridge.session_code, PardexBridge.player_id, PardexBridge.match_id, PardexBridge.launch_ticket)
		PardexBridge.consume_launch_ticket()
	else:
		kayit_istegi_rpc.rpc_id(1, PardexBridge.NET_PROTOCOL, Global.oyuncu_ismi, Global.profil_no)

func _on_connected_fail():
	son_baglanti_mesaji = "Bağlantı kurulamadı. Sunucu adresini ve bağlantını kontrol et."
	baglantiyi_kapat()
	durum_degisti.emit(son_baglanti_mesaji, true)

func _on_server_disconnected():
	son_baglanti_mesaji = "Sunucu bağlantısı kesildi. Yeni bir oda kurabilir veya tekrar bağlanabilirsiniz."
	get_tree().paused = false
	if oturum_asamasi == "game" and not donus_kaydi.is_empty():
		# Beklenmedik kopma maçtan ayrılmak sayılmaz: PARDEX'e ayrılma bildirilmez.
		son_baglanti_mesaji = "Maç bağlantısı koptu. Sunucu açıksa ana menüden \"Maça Dön\" ile kaldığın yere dönebilirsin."
		_ag_temizle()
	else:
		baglantiyi_kapat()
	get_tree().change_scene_to_file.call_deferred("res://AnaMenu.tscn")

@rpc("any_peer", "call_remote", "reliable")
func kayit_istegi_rpc(protocol: int, isim: String, avatar: int, code := "", user_id := "", match_id := "", ticket := ""):
	if not dedicated_mode or not multiplayer.is_server(): return
	var id = multiplayer.get_remote_sender_id()
	if id <= 1 or _onayli.has(id) or _bekleyen.has(id): return
	if protocol != PardexBridge.NET_PROTOCOL or oturum_asamasi != "lobby" or _onayli.size() + _bekleyen.size() >= MAX_PLAYERS or not _profil_gecerli(isim, avatar):
		_reddet(id)
		return
	if not resmi_mod:
		_kabul_et(id, isim, avatar, "", "host" if oda_sahibi_id == 0 else "client")
		return
	if code.length() != 5 or user_id.is_empty() or match_id.is_empty() or ticket.is_empty():
		_reddet(id)
		return
	if not _match_id.is_empty() and (match_id != _match_id or code != oda_kodu):
		_reddet(id)
		return
	for data in _onayli.values():
		if data["user_id"] == user_id:
			_reddet(id)
			return
	var validator = VALIDATOR.new()
	add_child(validator)
	_bekleyen[id] = {"isim": isim, "avatar": avatar, "user_id": user_id, "code": code, "match_id": match_id, "validator": validator, "role": ""}
	validator.verified.connect(_bilet_dogrulandi.bind(id))
	validator.admitted.connect(_kabul_dogrulandi.bind(id))
	validator.failed.connect(func(_message): _reddet(id))
	validator.begin(_online_url, PardexBridge.GAME_ID, match_id, ticket)

func _bilet_eslesiyor(payload: Dictionary, pending: Dictionary) -> bool:
	return str(payload.get("game_id", "")) == PardexBridge.GAME_ID and str(payload.get("match_id", "")) == pending["match_id"] and str(payload.get("room_code", "")) == pending["code"] and str(payload.get("user_id", "")) == pending["user_id"]

func _bilet_dogrulandi(payload: Dictionary, id: int):
	if not _bekleyen.has(id): return
	var p = _bekleyen[id]
	if not _bilet_eslesiyor(payload, p) or str(payload.get("role", "")) not in ["host", "client"]:
		_reddet(id)
		return
	if not _match_id.is_empty() and (p["match_id"] != _match_id or p["code"] != oda_kodu):
		_reddet(id)
		return
	# Aynı odada doğrulaması devam eden oyuncular aynı kimliği alamaz.
	for other in _onayli.values():
		if other["user_id"] == p["user_id"]:
			_reddet(id)
			return
	for other_id in _bekleyen:
		var other = _bekleyen[other_id]
		if other_id != id and other["user_id"] == p["user_id"] and not other["role"].is_empty():
			_reddet(id)
			return
	_match_id = p["match_id"]
	oda_kodu = p["code"]
	p["role"] = str(payload["role"])
	p["validator"].confirm_admission()

func _kabul_dogrulandi(payload: Dictionary, id: int):
	if not _bekleyen.has(id): return
	var p = _bekleyen[id]
	if not _bilet_eslesiyor(payload, p) or str(payload.get("role", "")) != p["role"] or oturum_asamasi != "lobby":
		_reddet(id)
		return
	for other in _onayli.values():
		if other["user_id"] == p["user_id"]:
			_reddet(id)
			return
	_bekleyen.erase(id)
	_kabul_et(id, p["isim"], p["avatar"], p["user_id"], p["role"])

func _kabul_et(id: int, isim: String, avatar: int, user_id: String, role: String):
	_onayli[id] = {"user_id": user_id}
	merkezi_lobi[id] = {"isim": isim, "renk": "", "medeniyet": "", "hazir_mi": false, "profil_no": avatar}
	if role == "host" and oda_sahibi_id == 0: oda_sahibi_id = id
	kabul_rpc.rpc_id(id, oda_sahibi_id, oda_kodu)
	_lobiyi_yayinla()

@rpc("authority", "call_remote", "reliable")
func kabul_rpc(owner: int, code: String):
	if not merkezi_mod or dedicated_mode or oturum_asamasi != "connecting": return
	oda_sahibi_id = owner
	oda_kodu = code
	oturum_asamasi = "lobby"
	_baglanti_suresi = 0.0
	durum_degisti.emit("Giriş doğrulandı · lobi hazır.", false)
	get_tree().change_scene_to_file.call_deferred("res://LobiPaneli.tscn")

func _profil_gecerli(isim: String, avatar: int) -> bool:
	return not isim.strip_edges().is_empty() and isim.length() <= 16 and not "[" in isim and not "]" in isim and not "\n" in isim and avatar >= 1 and avatar <= 8

@rpc("any_peer", "call_remote", "reliable")
func lobi_guncelle_rpc(isim: String, renk: String, medeniyet: String, hazir: bool, avatar: int):
	if not dedicated_mode or oturum_asamasi != "lobby": return
	var id = multiplayer.get_remote_sender_id()
	if not _onayli.has(id) or not _profil_gecerli(isim, avatar): return
	if renk != "" and renk not in ["Kirmizi", "Mavi", "Yesil", "Sari", "Mor", "CamGobegi"]: return
	if medeniyet != "" and medeniyet not in ["Osmanlı", "Mısır", "Venedik", "Bizans", "Moğol", "Viking"]: return
	if hazir and (renk.is_empty() or medeniyet.is_empty()): return
	for other_id in merkezi_lobi:
		if id == other_id: continue
		var v = merkezi_lobi[other_id]
		if (not renk.is_empty() and renk == v["renk"]) or (not medeniyet.is_empty() and medeniyet == v["medeniyet"]):
			istek_hatasi_rpc.rpc_id(id, "Bu renk veya medeniyet başka bir oyuncu tarafından seçildi.")
			_lobiyi_yayinla()
			return
	merkezi_lobi[id] = {"isim": isim, "renk": renk, "medeniyet": medeniyet, "hazir_mi": hazir, "profil_no": avatar}
	_lobiyi_yayinla()

@rpc("authority", "call_remote", "reliable")
func istek_hatasi_rpc(message: String):
	durum_degisti.emit(message.left(300), true)

func _lobiyi_yayinla():
	for id in _onayli:
		lobi_snapshot_rpc.rpc_id(id, merkezi_lobi, oda_sahibi_id)
	lobi_degisti.emit()

@rpc("authority", "call_remote", "reliable")
func lobi_snapshot_rpc(snapshot: Dictionary, owner: int):
	if not merkezi_mod: return
	merkezi_lobi = snapshot.duplicate(true)
	oda_sahibi_id = owner
	lobi_degisti.emit()

func lobi_kurucusu_mu() -> bool:
	return multiplayer.get_unique_id() == oda_sahibi_id if merkezi_mod else multiplayer.is_server()

@rpc("any_peer", "call_remote", "reliable")
func maci_baslat_rpc():
	if not dedicated_mode or oturum_asamasi != "lobby" or multiplayer.get_remote_sender_id() != oda_sahibi_id: return
	if merkezi_lobi.size() < 2:
		istek_hatasi_rpc.rpc_id(oda_sahibi_id, "Maç için en az iki oyuncu gerekli.")
		return
	for v in merkezi_lobi.values():
		if not v["hazir_mi"]: return
	_mac_kimlikleri = _onayli.duplicate(true)
	# Maç sırasında yeni bağlantılar yalnızca geçerli dönüş anahtarıyla kabul edilir.
	maca_gec_rpc.rpc(merkezi_lobi, randi())
	if resmi_mod: _raporla("game_server_started")

@rpc("authority", "call_local", "reliable")
func maca_gec_rpc(snapshot: Dictionary, seed_value: int):
	if not merkezi_mod: return
	son_lobi_verisi = snapshot.duplicate(true)
	oyun_tohumu = seed_value
	oturum_asamasi = "loading"
	_hazir_sahneler.clear()
	get_tree().change_scene_to_file.call_deferred("res://AnaOyun.tscn")

@rpc("any_peer", "call_local", "reliable")
func sahne_hazir_rpc():
	if not dedicated_mode or oturum_asamasi != "loading": return
	var id = multiplayer.get_remote_sender_id()
	if id == 0: id = 1
	if id != 1 and not _onayli.has(id): return
	if id not in _hazir_sahneler: _hazir_sahneler.append(id)
	if _hazir_sahneler.size() == _onayli.size() + 1: mac_hazir_rpc.rpc()

@rpc("authority", "call_local", "reliable")
func mac_hazir_rpc():
	oturum_asamasi = "game"
	durum_degisti.emit("Tüm oyuncular hazır · maç başladı.", false)

@rpc("any_peer", "call_remote", "reliable")
func merkezi_sohbet_rpc(metin: String):
	if not dedicated_mode or oturum_asamasi != "lobby": return
	var id = multiplayer.get_remote_sender_id()
	if not _onayli.has(id): return
	var clean = metin.strip_edges().left(300)
	if not clean.is_empty(): sohbet_yayin_rpc.rpc(merkezi_lobi[id]["isim"], clean)

@rpc("authority", "call_local", "reliable")
func sohbet_yayin_rpc(isim: String, metin: String):
	var scene = get_tree().current_scene
	if is_instance_valid(scene) and scene.has_method("_sistem_mesaji"):
		scene._sistem_mesaji(isim.replace("[", "[lb]") + ": " + metin.replace("[", "[lb]"))

@rpc("any_peer", "call_remote", "unreliable")
func ping_istegi_rpc(ticks: int):
	var id = multiplayer.get_remote_sender_id()
	if dedicated_mode and _onayli.has(id): pong_rpc.rpc_id(id, ticks)

@rpc("authority", "call_remote", "unreliable")
func pong_rpc(ticks: int):
	gecikme_ms = maxi(0, Time.get_ticks_msec() - ticks)
	gecikme_degisti.emit(gecikme_ms)

func _reddet(id: int):
	if _bekleyen.has(id):
		var v = _bekleyen[id]["validator"]
		_bekleyen.erase(id)
		if is_instance_valid(v): v.cancel()
	if dedicated_mode and multiplayer.multiplayer_peer != null and id in multiplayer.get_peers(): peer.disconnect_peer(id)

func _on_player_disconnected(id: int):
	if not dedicated_mode: return
	_reddet(id)
	_onayli.erase(id)
	merkezi_lobi.erase(id)
	_hazir_sahneler.erase(id)
	if oda_sahibi_id == id:
		var ids = _onayli.keys()
		ids.sort()
		oda_sahibi_id = ids[0] if not ids.is_empty() else 0
	if oturum_asamasi == "lobby": _lobiyi_yayinla()
	elif _onayli.is_empty():
		if resmi_mod: _raporla("game_server_ended", {}, {"reason": "abandoned"})
		else: _sunucuyu_yenile.call_deferred()
	elif oturum_asamasi == "loading" and _hazir_sahneler.size() == _onayli.size() + 1:
		mac_hazir_rpc.rpc()
	if _onayli.is_empty() and _bekleyen.is_empty() and oturum_asamasi == "lobby":
		_match_id = ""
		oda_kodu = ""

func maci_sonuclandir(kazanan: String):
	if not dedicated_mode or oturum_asamasi == "finished": return
	oturum_asamasi = "finished"
	mac_sona_erdi.emit(kazanan)
	if not resmi_mod: return
	var game = get_tree().current_scene
	var results = []
	var winner_user = ""
	for i in range(game.oyuncular.size()):
		var name_value = game.oyuncular[i]
		var user_id = _mac_kimlikleri.get(game.oyuncu_peer_idleri[i], {}).get("user_id", "")
		if name_value == kazanan: winner_user = user_id
		results.append({"user_id": user_id, "name": name_value, "score": game.puan_hesapla(name_value), "winner": name_value == kazanan})
	_raporla("game_server_ended", {}, {"reason": "victory", "winner_user_id": winner_user, "winner_name": kazanan, "players": results})

func _raporla(kind: String, extra := {}, result := {}):
	if kind == "game_server_ended" and _sonuc_bildiriliyor: return
	if kind == "game_server_ended": _sonuc_bildiriliyor = true
	var reporter = REPORTER.new()
	reporter.message_type = kind
	reporter.extra = extra
	add_child(reporter)
	if kind == "game_server_ended":
		reporter.succeeded.connect(func(_payload):
			await get_tree().create_timer(3.0).timeout
			_sonuc_bildiriliyor = false
			_sunucuyu_yenile())
	reporter.failed.connect(func(_message): push_warning("PARDEX sunucu bildirimi reddedildi; oturum korunuyor."))
	reporter.begin(_online_url, _server_token, PardexBridge.GAME_ID, _match_id, oda_kodu, result)

func _sunucuyu_yenile():
	var official = resmi_mod
	merkezi_sunucu_baslat(_boot_port, official)

func reset_network():
	baglantiyi_kapat()

func baglantiyi_kapat():
	if resmi_mod and not dedicated_mode:
		var link = get_node_or_null("/root/PardexLink")
		if link: link.leave_match()
	_ag_temizle()

# Yerel ağ maçında sahnesini yüklemiş istemciler (Network her zaman ağaçta
# olduğundan sunucunun oyun sahnesi henüz yüklenmemiş olsa da bildirim kaybolmaz).
var oyun_hazir_peerleri := {}

@rpc("any_peer", "call_remote", "reliable")
func oyun_sahnesi_hazir_rpc():
	if multiplayer.is_server() and not merkezi_mod:
		oyun_hazir_peerleri[multiplayer.get_remote_sender_id()] = true

# --- MAÇA GERİ DÖNÜŞ ---
# Sunucu maç başında her oyuncuya gizli bir dönüş anahtarı gönderir. Bağlantısı
# beklenmedik şekilde kopan oyuncu aynı sunucuya bu anahtarla bağlanıp koltuğuna döner.
const DONUS_DOSYASI := "user://mac_donusu.cfg"
var donus_kaydi := {}
var geri_donuyor := false
var donus_bekliyor := false   # istemci: oyun sahnesi sunucunun durum görüntüsünü bekliyor
var _son_hedef := {}

@rpc("authority", "call_remote", "reliable")
func donus_anahtari_rpc(anahtar: String, isim: String):
	if multiplayer.is_server() or anahtar.length() < 16 or _son_hedef.is_empty(): return
	donus_kaydi = _son_hedef.duplicate()
	donus_kaydi["anahtar"] = anahtar
	donus_kaydi["isim"] = isim
	_donus_kaydet()

func donus_kaydini_sil():
	donus_kaydi.clear()
	geri_donuyor = false
	donus_bekliyor = false
	var dosya = ConfigFile.new()
	dosya.save(DONUS_DOSYASI)

func _donus_kaydet():
	var dosya = ConfigFile.new()
	for key in donus_kaydi: dosya.set_value("donus", key, donus_kaydi[key])
	dosya.save(DONUS_DOSYASI)

func _donus_yukle():
	var dosya = ConfigFile.new()
	if dosya.load(DONUS_DOSYASI) != OK or not dosya.has_section("donus"): return
	for key in dosya.get_section_keys("donus"): donus_kaydi[key] = dosya.get_value("donus", key)
	if str(donus_kaydi.get("anahtar", "")).length() < 16: donus_kaydi.clear()

func maca_donulebilir_mi() -> bool:
	return not donus_kaydi.is_empty() and oturum_asamasi == "offline"

func maca_geri_don() -> bool:
	if not maca_donulebilir_mi(): return false
	var kayit = donus_kaydi.duplicate()
	var ok = false
	match str(kayit.get("tur", "")):
		"enet": ok = join_game(str(kayit["adres"]), int(kayit["port"]))
		"ws":
			baglantiyi_kapat()
			ok = PardexBridge.valid_url(str(kayit["adres"])) and _ws_baglan(str(kayit["adres"]), false)
		"pardex":
			_ag_temizle()
			ok = PardexBridge.valid_url(str(kayit["adres"])) and _ws_baglan(str(kayit["adres"]), true)
	donus_kaydi = kayit
	geri_donuyor = ok
	return ok

# Sunucu: dönüş anahtarını oyun sahnesine doğrulatır ve koltuğu ayırır.
@rpc("any_peer", "call_remote", "reliable")
func geri_katil_rpc(anahtar: String):
	if not multiplayer.is_server(): return
	var id = multiplayer.get_remote_sender_id()
	var game = get_tree().current_scene
	var oyunda = oturum_asamasi == "game" and is_instance_valid(game) and game.has_method("donus_rezerve_et")
	var eski_peer = game.donus_rezerve_et(id, anahtar) if oyunda else -1
	if eski_peer == -1:
		geri_katilim_red_rpc.rpc_id(id, "Bu maça dönülemiyor: maç bitmiş, koltuk dolu veya sunucu yeniden başlamış.")
		get_tree().create_timer(1.0).timeout.connect(func():
			if multiplayer.multiplayer_peer != null and id in multiplayer.get_peers(): multiplayer.multiplayer_peer.disconnect_peer(id))
		return
	if dedicated_mode:
		var kimlik = _mac_kimlikleri.get(eski_peer, {"user_id": ""})
		_mac_kimlikleri[id] = kimlik
		_onayli[id] = kimlik
	geri_katilim_kabul_rpc.rpc_id(id)

@rpc("authority", "call_remote", "reliable")
func geri_katilim_kabul_rpc():
	if not geri_donuyor: return
	geri_donuyor = false
	donus_bekliyor = true
	oturum_asamasi = "game"
	_baglanti_suresi = 0.0
	durum_degisti.emit("Maça dönülüyor…", false)
	get_tree().change_scene_to_file.call_deferred("res://AnaOyun.tscn")

@rpc("authority", "call_remote", "reliable")
func geri_katilim_red_rpc(mesaj: String):
	donus_kaydini_sil()
	son_baglanti_mesaji = mesaj.left(300)
	_ag_temizle()
	durum_degisti.emit(son_baglanti_mesaji, true)

func _ag_temizle():
	geri_donuyor = false
	oyun_hazir_peerleri.clear()
	for p in _bekleyen.values():
		var validator = p.get("validator")
		if is_instance_valid(validator): validator.cancel()
	_bekleyen.clear()
	_onayli.clear()
	_mac_kimlikleri.clear()
	merkezi_lobi.clear()
	son_lobi_verisi.clear()
	_hazir_sahneler.clear()
	_match_id = ""
	oda_kodu = ""
	oda_sahibi_id = 1
	oturum_asamasi = "offline"
	merkezi_mod = false
	dedicated_mode = false
	resmi_mod = false
	oyun_tohumu = 0
	ortak_sifre = 0
	_baglanti_suresi = 0.0
	_ping_sayaci = 0.0
	gecikme_ms = -1
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	peer = ENetMultiplayerPeer.new()
