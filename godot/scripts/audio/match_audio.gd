extends Node
## Original synthesized match cues. No recorded or third-party samples.
const RATE := 22050
const COOLDOWN := {
	"construction": 0.0,
	"unit_ready": 0.0,
	"low_power": 0.0,
	"under_attack": 8.0,
	"superweapon": 1.2,
	"ack_alliance": 0.2,
	"ack_republic": 0.2,
	"ack_gia": 0.2
}
var history: Array[String] = []
var _left: Dictionary = {}
var _players: Dictionary = {}
var _streams: Dictionary = {}

func _ready() -> void:
	_apply_saved_volume()
	for id in COOLDOWN.keys():
		var player := AudioStreamPlayer.new()
		player.name = "Cue_" + id
		player.bus = "Master"
		add_child(player)
		_players[id] = player
		_streams[id] = stream_for(id)

func reset_cues() -> void:
	_left.clear()

func cue(id: String) -> void:
	var key := id
	if id == "ack":
		key = "ack_" + _faction()
	if not _streams.has(key):
		return
	if float(_left.get(key, 0.0)) > 0.0:
		return
	_left[key] = float(COOLDOWN[key])
	history.append(key)
	var player: AudioStreamPlayer = _players[key]
	player.stream = _streams[key]
	player.play()

func _faction() -> String:
	var host = get_parent()
	if host != null and host.get("army_choices") != null:
		return preload("res://scripts/economy/army_rules.gd").faction(str(host.army_choices[0]))
	return "alliance"

func _process(delta: float) -> void:
	for key in _left.keys():
		_left[key] = maxf(0.0, float(_left[key]) - delta)

func _apply_saved_volume() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		return
	var volume := clampf(float(config.get_value("audio", "volume", 80.0)), 0.0, 100.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume / 100.0, 0.0001)))
	AudioServer.set_bus_mute(0, volume <= 0.0)

static func stream_for(id: String) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	match id:
		"construction":
			samples = _phrase([[523.25, 0.11], [659.25, 0.11], [783.99, 0.2]], "sine", 0.42)
		"unit_ready":
			samples = _phrase([[987.77, 0.06], [1318.51, 0.12]], "sine", 0.38)
		"low_power":
			samples = _phrase([[196.0, 0.16], [130.81, 0.28]], "square", 0.22)
		"under_attack":
			samples = _phrase([[146.83, 0.09], [0.0, 0.06], [146.83, 0.16]], "square", 0.28)
		"superweapon":
			samples = _phrase([[440.0, 0.1], [587.33, 0.1], [440.0, 0.1], [698.46, 0.22]], "sine", 0.4)
		"ack_alliance":
			samples = _phrase([[880.0, 0.05], [1174.66, 0.1]], "sine", 0.34)
		"ack_republic":
			samples = _phrase([[220.0, 0.07], [277.18, 0.13]], "triangle", 0.4)
		"ack_gia":
			samples = _pluck()
		_:
			samples = _phrase([[440.0, 0.1]], "sine", 0.2)
	return _wav(samples)

static func _phrase(notes: Array, shape: String, gain: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for note in notes:
		var freq := float(note[0])
		var seconds := float(note[1])
		if freq <= 1.0:
			out.append_array(_silence(seconds))
		else:
			out.append_array(_voice(freq, seconds, shape, gain))
	return out

static func _silence(seconds: float) -> PackedFloat32Array:
	var count := maxi(1, int(RATE * seconds))
	var out := PackedFloat32Array()
	out.resize(count)
	return out

static func _voice(freq: float, seconds: float, shape: String, gain: float) -> PackedFloat32Array:
	var count := maxi(1, int(RATE * seconds))
	var out := PackedFloat32Array()
	out.resize(count)
	for i in count:
		var t := float(i) / float(RATE)
		var env := 1.0
		if t < 0.012:
			env = t / 0.012
		var remain := seconds - t
		if remain < 0.028:
			env *= maxf(0.0, remain / 0.028)
		var cycle := fmod(freq * t, 1.0)
		var sample := sin(cycle * TAU)
		if shape == "square":
			sample = 1.0 if cycle < 0.5 else -1.0
		elif shape == "triangle":
			sample = 4.0 * absf(cycle - 0.5) - 1.0
		out[i] = sample * env * gain
	return out

static func _pluck() -> PackedFloat32Array:
	var seconds := 0.18
	var count := int(RATE * seconds)
	var out := PackedFloat32Array()
	out.resize(count)
	var state := 214013
	for i in count:
		state = int((state * 1103515245 + 12345) & 2147483647)
		var noise := float(state % 2000) / 1000.0 - 1.0
		var t := float(i) / float(RATE)
		var env := 1.0 - t / seconds
		out[i] = (noise * 0.28 + sin(TAU * 520.0 * t) * 0.45) * env
	return out

static func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var value := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		bytes[i * 2] = value & 255
		bytes[i * 2 + 1] = (value >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	return stream
