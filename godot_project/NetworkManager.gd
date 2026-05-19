extends Node

var is_multiplayer: bool = false
var peers: Dictionary = {} # peer_id: { "ram": int, "is_host": bool }
var current_host_id: int = 1

func _ready() -> void:
	# Simule edilmis ag sinyalleri (Normalde multiplayer_api kullanılır)
	pass

# 1. P2P Handshake (RAM tabanlı Host Secimi)
func perform_ram_handshake(new_peer_id: int) -> void:
	var my_ram = OS.get_static_memory_peak_usage()

	# Mock data for demonstration
	peers[multiplayer.get_unique_id()] = { "ram": my_ram, "is_host": false }
	peers[new_peer_id] = { "ram": my_ram + randi_range(-500000, 500000), "is_host": false }

	_elect_new_host()

func _elect_new_host() -> void:
	var highest_ram = -1
	var candidate_id = -1

	for pid in peers.keys():
		peers[pid]["is_host"] = false
		if peers[pid]["ram"] > highest_ram:
			highest_ram = peers[pid]["ram"]
			candidate_id = pid

	if candidate_id != -1:
		peers[candidate_id]["is_host"] = true
		current_host_id = candidate_id
		print("Yeni Host Secildi. Peer ID: ", candidate_id, " | RAM: ", highest_ram)

# 2. Host Migration (Sunucu Gocu)
func _on_peer_disconnected(id: int) -> void:
	if peers.has(id):
		peers.erase(id)

	if id == current_host_id:
		print("Host baglantiyi kesti! Kesintisiz gecis (Host Migration) baslatiliyor...")
		# Oyunu gecici olarak durdur (oyuncular hissetmez)
		get_tree().paused = true

		# Yeni host sec
		_elect_new_host()

		# State Sync: Kalan en yuksek RAM'li cihaz yeni host olarak map state'ini broadcastler
		if current_host_id == multiplayer.get_unique_id():
			print("Ben yeni Host oldum! State senkronizasyonu yapiyorum...")
			_broadcast_state()

		get_tree().paused = false

func _broadcast_state() -> void:
	# Tum dusman pozisyonlari ve oyun suresi (Arena.gd vb.) diger client'lara p2p gonderilir
	pass
