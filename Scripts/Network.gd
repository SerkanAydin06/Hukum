extends Node

const PORT = 7777
const DEFAULT_IP = "127.0.0.1"
const MAX_PLAYERS = 6

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

func host_game():
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		print("Sunucu kurulamadı: ", error)
		return
	multiplayer.multiplayer_peer = peer
	
	randomize()
	ortak_sifre = randi()
	print("Sunucu kuruldu! Port: ", PORT)

func join_game(ip_address: String):
	if ip_address == "": ip_address = DEFAULT_IP
	var error = peer.create_client(ip_address, PORT)
	if error != OK:
		print("Sunucuya bağlanılamadı: ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("Sunucuya bağlanılıyor: ", ip_address)

# Bağlantı Durumu Sinyalleri
func _on_player_connected(id): print("Bağlanan ID: ", id)
func _on_player_disconnected(id): print("Kopan ID: ", id)
func _on_connected_ok(): print("Sunucuya başarıyla bağlandık!")
func _on_connected_fail(): print("Bağlantı reddedildi!")
func _on_server_disconnected():
	print("Sunucu ile bağlantı kesildi!")
	baglantiyi_kapat()
	get_tree().change_scene_to_file("res://AnaMenu.tscn")

func reset_network():
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		peer.close()
	multiplayer.multiplayer_peer = null
	peer = ENetMultiplayerPeer.new()

func baglantiyi_kapat():
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		
	peer = ENetMultiplayerPeer.new()
