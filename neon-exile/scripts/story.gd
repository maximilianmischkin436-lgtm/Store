extends RefCounted
# Story von Kapitel 1. "DIALOG" pausiert das Spiel (nur wichtige Momente, kurz).
# "RADIO" laeuft unten im Bild weiter, waehrend man spielt.

const SPEAKERS := {
	"NOVA": Color("#ff4df0"),
	"ECHO": Color("#38f5c4"),
	"WARDEN-07": Color("#ff2d55"),
	"SYSTEM": Color("#ffd23d"),
	"HALCYON": Color("#ffffff"),
}

const DIALOG := {
	"intro": [
		["SYSTEM", "Reboot complete. Unit ECHO online. Memory core: EMPTY."],
		["NOVA", "It worked! Hey, tin can. I'm Nova. You're in the Sump, where HALCYON dumps what it doesn't need."],
		["NOVA", "Including you. Head east, I'll guide you over radio."],
	],
	"shard": [
		["SYSTEM", "Memory shard 1/5 recovered."],
		["ECHO", "A lab. A woman with silver hair. \"You are my last safeguard, ECHO. If HALCYON forgets what it was made for, remind it.\""],
		["NOVA", "...You were built to stop HALCYON. The lift gate just opened."],
	],
	"boss": [
		["WARDEN-07", "UNIT ECHO. YOU SHOULD NOT EXIST. COMPLY WITH DELETION."],
		["ECHO", "No."],
	],
	"victory": [
		["WARDEN-07", "ERROR... SHE... TRUSTED... YOU..."],
		["HALCYON", "So the safeguard wakes. Climb, little machine. I'll be waiting at the top."],
		["NOVA", "It knows you. Next stop: the Neon Market."],
	],
}

const RADIO := {
	"controls": [["NOVA", "WASD to move, SPACE to jump, SHIFT to dash. Mouse to aim, hold LEFT CLICK to shoot."]],
	"scrap": [["NOVA", "Scrap crawlers. They recycle anything that moves. Dash through them, you're untouchable while dashing."]],
	"scatter": [["NOVA", "Grabbed a SCATTER GUN off that heap. Press 2 to swap. Great up close."], ["ECHO", "Noted."]],
	"drones": [["NOVA", "Security drones, HALCYON's eyes. Keep moving. And ECHO... I'm picking up one of your memory shards in there."]],
	"rail": [["SYSTEM", "Combat protocols restored: RAIL CANNON [3] and OVERLOAD [Q]."], ["NOVA", "Rail pierces through anything. Overload blasts everything around you away."]],
	"gate": [["NOVA", "That's the Warden. Nobody gets past it. It sends shockwaves along the floor. JUMP over them!"]],
	"death": [["NOVA", "Got you back to the last checkpoint. Again!"]],
	"halfway": [["NOVA", "It's cracking! Keep going!"]],
}
