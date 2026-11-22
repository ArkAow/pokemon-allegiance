class_name Balance
extends RefCounted

const STAT_KEYS: Array[String] = ["hp", "atk", "def", "speAtk", "speDef", "spd"]
const STAT_LABELS := {
	"hp": "PV", "atk": "Attaque", "def": "Défense",
	"speAtk": "Att. Spé", "speDef": "Déf. Spé", "spd": "Vitesse",
}

const MAX_LEVEL := 100
const MAX_DEPLOYED := 10

const BOARD_COLS := 7
const BOARD_ROWS := 8
const PLAYER_ROW_START := 4

const HP_MULT := 2.5
const BASIC_ATTACK_RATIO := 0.5
const ARMOR_SCALE := 100.0
const ENERGY_PER_ATTACK := 10.0
const ENERGY_ON_HIT_TAKEN := 4.0
const BATTLE_TIME_LIMIT := 75.0

const EXP_PER_ENEMY_LEVEL := 5
const EXP_BASE_PER_ENEMY := 5

static func calc_stat(key: String, base: int, iv: int, level: int) -> int:
	var core: int = floori((2.0 * base + iv) * level / 100.0)
	if key == "hp":
		return core + level + 10
	return core + 5


static func exp_to_next(level: int) -> int:
	return 3 * level * level + 3 * level + 1
