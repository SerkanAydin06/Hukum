extends Node

const PORT = 7777
const DEFAULT_IP = "127.0.0.1"
const MAX_PLAYERS = 6

var son_baglanti_mesaji = ""
var son_lobi_verisi = {} 
var peer = ENetMultiplayerPeer.new()
var ortak_sifre = 0
# Sunucunun belirlediği ortak tohum: tüm oyuncularda destelerin aynı sırayla karışmasını sağlar
var oyun_tohumu: int = 0

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game() -> bool:
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		push_warning("Sunucu kurulamadı: %s" % error)
		baglantiyi_kapat()
		return false
	multiplayer.multiplayer_peer = peer

	randomize()
	ortak_sifre = randi()
	print("Sunucu kuruldu! Port: ", PORT)
	return true

func join_game(ip_address: String) -> bool:
	if ip_address == "": ip_address = DEFAULT_IP
	var error = peer.create_client(ip_address, PORT)
	if error != OK:
		push_warning("Sunucuya bağlanılamadı: %s" % error)
		baglantiyi_kapat()
		return false
	multiplayer.multiplayer_peer = peer
	print("Sunucuya bağlanılıyor: ", ip_address)
	return true

# Bağlantı Durumu Sinyalleri
func _on_player_connected(id): print("Bağlanan ID: ", id)
func _on_player_disconnected(id): print("Kopan ID: ", id)
func _on_connected_ok(): print("Sunucuya başarıyla bağlandık!")
func _on_connected_fail(): print("Bağlantı reddedildi!")
func _on_server_disconnected():
	son_baglanti_mesaji = "Sunucu bağlantısı kesildi. Yeni bir oda kurabilir veya tekrar bağlanabilirsiniz."
	get_tree().paused = false
	baglantiyi_kapat()
	get_tree().change_scene_to_file("res://AnaMenu.tscn")

func reset_network():
	baglantiyi_kapat()

func baglantiyi_kapat():
	son_lobi_verisi.clear()
	oyun_tohumu = 0
	ortak_sifre = 0
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		
	peer = ENetMultiplayerPeer.new()

