extends RefCounted
# Story von Kapitel 1. "DIALOG" pausiert das Spiel (nur wichtige Momente, kurz).
# "RADIO" laeuft unten im Bild weiter, waehrend man spielt.

const SPEAKERS := {
	"NOVA": Color("#ff4df0"),
	"ECHO": Color("#38f5c4"),
	"WARDEN-07": Color("#ff2d55"),
	"SYSTEM": Color("#ffd23d"),
	"HALCYON": Color("#ffffff"),
	"MAMMON": Color("#ffd27a"),
	"MNEMOS": Color("#ff3030"),
	"THE HEADMASTER": Color("#ffcc33"),
}

const DIALOG := {
	"intro": [
		["SYSTEM", "Reboot complete. Unit ECHO online. Memory core: EMPTY."],
		["NOVA", "It worked! Hey, tin can. I'm Nova. You're in the Drain, the old pools under the city. HALCYON floods everything it wants forgotten down here."],
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
	# ---- Kapitel 2: The Neon Market ----
	"c2_intro": [
		["NOVA", "The lift dropped us in the old mall. It closed the night of the Reset... but the lights never went off."],
		["ECHO", "Why does it feel like I've been here before?"],
	],
	"c2_shard": [
		["SYSTEM", "Memory shard 2/5 recovered."],
		["ECHO", "A little girl on the escalator, holding my hand. She calls me 'Echo'. Like a name, not a serial number."],
		["NOVA", "A girl? ECHO... who was she?"],
	],
	"c2_boss": [
		["MAMMON", "WELCOME BACK, VALUED CUSTOMER. YOUR MEMORIES HAVE EXPIRED."],
		["ECHO", "Then I'm taking them back."],
	],
	"c2_victory": [
		["MAMMON", "THANK YOU... FOR... SHOPPING..."],
		["NOVA", "The service stairs go up to the Archive. That's where HALCYON files everything it took."],
	],
	# ---- Kapitel 3: The Archive ----
	"c3_intro": [
		["NOVA", "Welcome to the Archive. Every erased memory in the city is stored in here. Miles of it."],
		["ECHO", "Every room looks the same."],
		["NOVA", "That's the point. Don't get lost."],
	],
	"c3_shard": [
		["SYSTEM", "Memory shard 3/5 recovered."],
		["ECHO", "Sirens. The war. The silver-haired woman, Dr. Lyra Vance, carrying the girl. \"Mira, don't look.\""],
		["NOVA", "Mira. Her name was Mira."],
	],
	"c3_boss": [
		["MNEMOS", "I AM EVERYTHING YOU FORGOT. AND YOU WILL FORGET AGAIN."],
	],
	"c3_victory": [
		["NOVA", "One more level before the Crown. The old school. Lyra's last record came from there."],
	],
	# ---- Kapitel 4: After School ----
	"c4_intro": [
		["NOVA", "It's always sunset here. HALCYON keeps this place exactly as it was."],
		["ECHO", "This was her school. Mira's."],
	],
	"c4_shard": [
		["SYSTEM", "Memory shard 4/5 recovered."],
		["ECHO", "Mira didn't survive the war. Lyra uploaded what was left of her mind... into the city."],
		["NOVA", "Wait. HALCYON... is Mira?"],
	],
	"c4_boss": [
		["THE HEADMASTER", "SCHOOL IS OVER, ECHO. GO HOME. THERE IS NOTHING LEFT TO LEARN."],
		["ECHO", "There is one thing."],
	],
	"c4_victory": [
		["HALCYON", "You remember her. Then come to the Crown, ECHO. Let me show you why I made everyone forget."],
		["NOVA", "Last stop. The Crown. Whatever happens up there... I'm with you."],
	],
}

const DIALOG2 := {}

const RADIO := {
	"controls": [["NOVA", "WASD to move, SPACE to jump, SHIFT to dash. Mouse to aim, hold LEFT CLICK to shoot."]],
	"scrap": [["NOVA", "Scrap crawlers. They recycle anything that moves. Dash through them, you're untouchable while dashing."]],
	"scatter": [["NOVA", "Grabbed a SCATTER GUN off that heap. Press 2 to swap. Great up close."], ["ECHO", "Noted."]],
	"drones": [["NOVA", "Security drones, HALCYON's eyes. Keep moving. And ECHO... I'm picking up one of your memory shards in there."]],
	"rail": [["SYSTEM", "Combat protocols restored: RAIL CANNON [3] and OVERLOAD [Q]."], ["NOVA", "Rail pierces through anything. Overload blasts everything around you away."]],
	"gate": [["NOVA", "That's the Warden. Nobody gets past it. It sends shockwaves along the floor. JUMP over them!"]],
	"death": [["NOVA", "Got you back to the last checkpoint. Again!"]],
	"c2_controls": [["NOVA", "Stay sharp. All your weapons still work: 1, 2, 3 and Q."]],
	"c2_scrap": [["NOVA", "Those aren't mannequins. They're HALCYON's shoppers. Don't let them touch you."]],
	"c2_drones": [["NOVA", "Security drones around the fountain. Your shard signal is coming from right there."]],
	"c2_gate": [["NOVA", "Something huge is waking up in the food court. Its shockwaves still run along the floor. JUMP."]],
	"c3_controls": [["NOVA", "Hear that hum? It's the lights. Or something between the walls."]],
	"c3_scrap": [["NOVA", "Filing clerks. They used to sort memories. Now they shred whatever moves."]],
	"c3_drones": [["NOVA", "Your shard is close. Follow the lights that still work."]],
	"c3_gate": [["NOVA", "The stairwell. And the thing that eats memories is guarding it."]],
	"c4_controls": [["NOVA", "Listen... there's no sound at all here. Not even birds."]],
	"c4_scrap": [["NOVA", "Hall monitors. Still checking for hall passes after all these years."]],
	"c4_drones": [["NOVA", "Mira's classroom is up ahead. The shard is in there."]],
	"c4_gate": [["NOVA", "The gym. The Headmaster is waiting. Jump the shockwaves!"]],
	"halfway": [["NOVA", "It's cracking! Keep going!"]],
}
