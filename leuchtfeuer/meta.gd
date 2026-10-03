extends RefCounted
## Dauerhafter Fortschritt über alle Läufe: Glut, Schmiede-Upgrades, Rekorde.

const PATH := "user://leuchtfeuer.cfg"

## id: [Name, Beschreibung, Maximalstufe, Grundpreis]
const UPGRADES := {
	"start_scrap": ["Vorräte", "+40 Schrott zu Beginn", 10, 12],
	"start_oil": ["Ölreserve", "+50 Öl zu Beginn", 10, 12],
	"tower_hp": ["Turmmauern", "Turm +20 % Lebenspunkte", 10, 18],
	"light": ["Turmlinse", "Turmlicht reicht +0,3 Felder weiter", 10, 20],
	"burn": ["Brennglas", "Licht verbrennt Wucherer 20 % stärker", 10, 22],
	"pulse": ["Lichtstoß", "Lichtstoß +25 % Schaden", 10, 20],
	"guard": ["Wachausbildung", "Wachen +15 % Schaden", 10, 20],
	"bhp": ["Robuste Bauten", "Gebäude +20 % Lebenspunkte", 10, 16],
	"growth": ["Fruchtbarkeit", "Bevölkerung wächst 20 % schneller", 10, 14],
	"prod": ["Fleiß", "Alle Erträge +10 %", 10, 25],
	"air": ["Späherkunst", "+2 Atemluft bei Erkundungen", 3, 15],
	"glut": ["Glutsucher", "+15 % Glut aus allen Quellen", 10, 30],
	"u_beacon": ["Plan: Leuchtmast", "Schaltet den Leuchtmast frei", 1, 40],
	"u_forge": ["Plan: Glutofen", "Schaltet den Glutofen frei (Glut im Leerlauf)", 1, 70],
	"u_mortar": ["Plan: Feuerkanone", "Schaltet die Feuerkanone frei (Flächenschaden)", 1, 55],
	"cards4": ["Weitsicht", "Wähle aus 4 statt 3 Karten", 1, 60],
	"reroll": ["Neu mischen", "1 Neumischen der Karten pro Nacht", 1, 45],
}

var glut := 0
var lvl := {}
var best_night := 0
var runs := 0
var total_kills := 0

func load_data() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	glut = cf.get_value("meta", "glut", 0)
	lvl = cf.get_value("meta", "lvl", {})
	best_night = cf.get_value("meta", "best_night", 0)
	runs = cf.get_value("meta", "runs", 0)
	total_kills = cf.get_value("meta", "kills", 0)

func save_data() -> void:
	var cf := ConfigFile.new()
	cf.set_value("meta", "glut", glut)
	cf.set_value("meta", "lvl", lvl)
	cf.set_value("meta", "best_night", best_night)
	cf.set_value("meta", "runs", runs)
	cf.set_value("meta", "kills", total_kills)
	cf.save(PATH)

func level(id: String) -> int:
	return lvl.get(id, 0)

func cost(id: String) -> int:
	return int(UPGRADES[id][3] * 3 * pow(1.55, level(id)))

func can_buy(id: String) -> bool:
	return level(id) < UPGRADES[id][2] and glut >= cost(id)

func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	glut -= cost(id)
	lvl[id] = level(id) + 1
	save_data()
	return true
