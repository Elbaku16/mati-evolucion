extends Node

# ═══════════════════════════════════════════════════════════════
#  MÚSICA MANAGER — Autoload singleton
#  Agrega en Project Settings > Autoload:
#    nombre: MusicaManager   ruta: res://scripts/musica_manager.gd
#
#  Pistas esperadas en assets/sonidos/:
#    musica_fondo.mp3         ← ya existe (exploración genérica)
#    musica_mundo1.ogg        ← planeta verde (calma, naturaleza)
#    musica_mundo2.ogg        ← planeta hielo (misterio, frío)
#    musica_mundo3.ogg        ← planeta hongos (mágico, fantasía)
#    musica_desafio.ogg       ← durante operaciones matemáticas
#    musica_victoria.ogg      ← al completar sección / mundo
#    musica_mapa.ogg          ← pantalla de selección de mundos
# ═══════════════════════════════════════════════════════════════

const PISTAS = {
	"fondo"    : "res://assets/sonidos/musica_fondo.mp3",
	"mundo1"   : "res://assets/sonidos/musica_mundo1.ogg",
	"mundo2"   : "res://assets/sonidos/musica_mundo2.ogg",
	"mundo3"   : "res://assets/sonidos/musica_mundo3.ogg",
	"desafio"  : "res://assets/sonidos/musica_desafio.ogg",
	"victoria" : "res://assets/sonidos/musica_victoria.ogg",
	"mapa"     : "res://assets/sonidos/musica_mapa.ogg",
}

const VOL_NORMAL  : float = 0.0    # dB
const VOL_SILENCIO: float = -80.0
const FADE_TIME   : float = 1.2    # segundos de crossfade

var _player_a : AudioStreamPlayer = null
var _player_b : AudioStreamPlayer = null
var _activo   : AudioStreamPlayer = null   # el que suena ahora
var _pista_actual : String = ""
var _volumen_base : float = VOL_NORMAL

func _ready() -> void:
	_player_a = AudioStreamPlayer.new()
	_player_b = AudioStreamPlayer.new()
	_player_a.bus = "Master"
	_player_b.bus = "Master"
	add_child(_player_a)
	add_child(_player_b)
	_activo = _player_a

# ─────────────────────────────────────────────────────────────
#  API PÚBLICA
# ─────────────────────────────────────────────────────────────

## Reproducir una pista con crossfade suave.
## pista_id: "fondo" | "mundo1" | "mundo2" | "mundo3" | "desafio" | "victoria" | "mapa"
func reproducir(pista_id: String, loop: bool = true) -> void:
	if pista_id == _pista_actual:
		return   # ya está sonando

	var ruta : String = PISTAS.get(pista_id, PISTAS["fondo"])
	if not ResourceLoader.exists(ruta):
		# Fallback: usar musica_fondo.mp3 si la pista no existe aún
		ruta = PISTAS["fondo"]
		if not ResourceLoader.exists(ruta):
			return

	var stream = load(ruta)
	if stream == null:
		return

	# Configurar loop si el stream lo soporta
	if stream is AudioStreamMP3:
		stream.loop = loop
	elif stream is AudioStreamOggVorbis:
		stream.loop = loop

	_pista_actual = pista_id

	# Player inactivo toma la nueva pista
	var siguiente : AudioStreamPlayer = _player_b if _activo == _player_a else _player_a
	siguiente.stream          = stream
	siguiente.volume_db       = VOL_SILENCIO
	siguiente.play()

	# Crossfade
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_activo,   "volume_db", VOL_SILENCIO,   FADE_TIME)
	tw.tween_property(siguiente, "volume_db", _volumen_base,  FADE_TIME)
	tw.chain().tween_callback(func():
		_activo.stop()
		_activo = siguiente
	)

## Detener música con fade out
func detener() -> void:
	_pista_actual = ""
	var tw := create_tween()
	tw.tween_property(_activo, "volume_db", VOL_SILENCIO, FADE_TIME)
	tw.chain().tween_callback(func(): _activo.stop())

## Ajustar volumen global (0.0 = mudo, 1.0 = completo)
func set_volumen(valor: float) -> void:
	_volumen_base = linear_to_db(clamp(valor, 0.0, 1.0))
	if _activo.playing:
		_activo.volume_db = _volumen_base

## Pausar / reanudar sin perder la posición
func pausar() -> void:
	if _activo.playing:
		_activo.stream_paused = true

func reanudar() -> void:
	if _activo.stream_paused:
		_activo.stream_paused = false

# ─────────────────────────────────────────────────────────────
#  ATAJOS POR ESCENA — llamar desde _ready() de cada escena
# ─────────────────────────────────────────────────────────────
func musica_explorar_mundo(numero: int) -> void:
	match numero:
		1: reproducir("mundo1")
		2: reproducir("mundo2")
		3: reproducir("mundo3")
		_: reproducir("fondo")

func musica_desafio() -> void:
	reproducir("desafio")

func musica_victoria() -> void:
	reproducir("victoria", false)   # no loopear victoria

func musica_mapa() -> void:
	reproducir("mapa")
