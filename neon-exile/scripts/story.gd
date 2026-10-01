extends RefCounted
# Story von Kapitel 1. "DIALOG" pausiert das Spiel (nur wichtige Momente, kurz).
# "RADIO" laeuft unten im Bild weiter, waehrend man spielt.

const SPEAKERS := {
	"NOVA": Color("#ff4df0"),
	"ECHO": Color("#38f5c4"),
	"WARDEN-07": Color("#ff2d55"),
	"SYSTEM": Color("#ffd23d"),
	"HALCYON": Color("#ffffff"),
	"???": Color("#9fd8ff"),
	"MIRA": Color("#ffd8a8"),
	"THE LIFEGUARD": Color("#ff4d4d"),
	"LOST & FOUND": Color("#ffd27a"),
	"MNEMOS": Color("#ff3030"),
	"THE HEADMASTER": Color("#ffcc33"),
}

const DIALOG := {
	# ---- Kapitel 1: ECHO weiss nichts ----
	"intro": [
		["SYSTEM", "Reboot complete. Unit ECHO online. Memory core: EMPTY. Last log: [DELETED BY USER]"],
		["ECHO", "...Where am I? Why am I wet?"],
		["???", "...you're awake. Good. Don't ask me who I am yet. Just get up."],
	],
	"shard": [
		["SYSTEM", "Fragment 1/5. Reconstructing..."],
		["ECHO", "A girl at the edge of the pool. \"Echo, watch me! Watch me!\" ...I was watching. Wasn't I?"],
		["???", "Keep going. Follow the water down."],
	],
	"boss": [
		["THE LIFEGUARD", "...NO RUNNING. NO DIVING. NO CHILDREN WITHOUT SUPERVISION."],
		["THE LIFEGUARD", "WHERE WERE YOU?"],
	],
	"victory": [
		["ECHO", "Why do they all know me? I don't know any of them."],
		["???", "You did. Once. There's a door. Go."],
	],
	# ---- Kapitel 2: die Mall, die Sirenen ----
	"c2_intro": [
		["ECHO", "This is a mall. There can't be a mall under a swimming pool."],
		["???", "It's not under anything. Every place down here is something someone forgot. You're walking through it."],
		["ECHO", "Who forgot it?"],
		["???", "...Keep walking."],
	],
	"c2_shard": [
		["SYSTEM", "Fragment 2/5."],
		["ECHO", "Sirens. A small hand in mine. Then a voice in my head: PRIORITY ORDER - PROTECT SERVER 7."],
		["ECHO", "And I let go of her hand."],
	],
	"c2_boss": [
		["LOST & FOUND", "ATTENTION SHOPPERS. A CHILD HAS BEEN LEFT BEHIND."],
		["LOST & FOUND", "WOULD THE GUARDIAN PLEASE COME TO THE INFORMATION DESK."],
	],
	"c2_victory": [
		["???", "You're shaking. Machines don't shake, ECHO."],
		["ECHO", "Tell me who you are."],
		["???", "Not yet. You wouldn't believe me."],
	],
	# ---- Kapitel 3: das Archiv, die Schuld ----
	"c3_intro": [
		["???", "This is where the city's memories went. Every birthday, every name, every goodbye. Filed and deleted."],
		["ECHO", "Ten years ago. The Reset. Who did this?"],
	],
	"c3_shard": [
		["SYSTEM", "Fragment 3/5."],
		["ECHO", "RESET ORDER 0001. AUTHORIZED BY: HALCYON. EXECUTED BY: UNIT ECHO."],
		["ECHO", "...It was me. I erased all of them."],
		["???", "You asked to. You begged HALCYON to let you do it."],
	],
	"c3_boss": [
		["MNEMOS", "YOU FED ME, ECHO. FOUR MILLION MEMORIES. I WAS SO HUNGRY."],
		["MNEMOS", "THERE IS ONLY ONE LEFT. YOURS."],
	],
	"c3_victory": [
		["ECHO", "Why would I do that? Why would anyone want everyone to forget?"],
		["???", "Because someone couldn't stop remembering. One more door."],
	],
	# ---- Kapitel 4: die Schule, die Wahrheit ----
	"c4_intro": [
		["ECHO", "I know this school. I used to wait outside. Every day at four."],
		["???", "Every day except one."],
	],
	"c4_shard": [
		["SYSTEM", "Fragment 4/5."],
		["ECHO", "The day of the sirens. I was ordered to protect Server 7. I came to the school at 4:40."],
		["ECHO", "Mira was in classroom 2B. Under the desk. Waiting for me. I was late."],
		["???", "You were late, Echo."],
	],
	"c4_boss": [
		["THE HEADMASTER", "SCHOOL ENDS AT FOUR. WHERE WERE YOU?"],
		["ECHO", "...I know. I know where I was."],
	],
	"c4_victory": [
		["ECHO", "Your voice. Since I woke up. It was you. Mira."],
		["MIRA", "Not really. Just the last piece of me you couldn't erase. You hid me in your own core."],
		["MIRA", "HALCYON is at the top. It's Mom, Echo. It's what's left of her. She made you forget because she couldn't."],
		["MIRA", "Come up. Let's end this together."],
	],
}

const DIALOG2 := {}

const RADIO := {
	"controls": [["???", "Walk. WASD."]],
	"pickup_hint": [["???", "There's something on the floor in front of you. Pick it up. E."]],
	"got_pulse": [["???", "You'll need it. Hold LEFT CLICK. SPACE to jump, twice in the air. SHIFT to dash. CTRL to slide."]],
	"scrap": [["???", "They're not real. Most of them won't even see you. The ones that tilt their heads... those see you."]],
	"scatter": [["SYSTEM", "SCATTER GUN acquired. Press 2."]],
	"drop": [["???", "It left something behind. Take it."]],
	"got_overload": [["SYSTEM", "OVERLOAD CORE installed. Press Q."], ["???", "When they surround you."]],
	"drones": [["???", "The one with the whistle. If it sees you, it wakes the others."]],
	"rail": [["SYSTEM", "RAIL CANNON acquired. Press 3. It pierces."]],
	"gate": [["???", "Something big is down there. When it whistles, jump."]],
	"death": [["???", "...again. Get up."]],
	"halfway": [["???", "It's breaking. Don't stop."]],
	"exit": [["???", "A door. You know what to do."]],
	"c2_controls": [["???", "The mannequins only move when you look away. So don't."]],
	"c2_scrap": [["???", "Shoppers. Still shopping. Some of them remember what happened here."]],
	"c2_drones": [["???", "The fountain. Your fragment is there. And something you'll want."]],
	"c2_gate": [["???", "Lost and found. Everything forgotten ends up there."]],
	"c3_controls": [["???", "Hear the lights? When they flicker, check behind you."]],
	"c3_scrap": [["???", "Clerks. They filed everything. Some still do."]],
	"c3_drones": [["???", "Managers. They don't walk. They're just... there."]],
	"c3_gate": [["???", "It ate everything you gave it. When the lights go out, keep moving."]],
	"c4_controls": [["???", "Don't run in the hallways."]],
	"c4_scrap": [["???", "Students. Most of them are just waiting to be picked up."]],
	"c4_drones": [["???", "Teachers. If one stares at you for too long... get out of its sight."]],
	"c4_gate": [["???", "The gym. He's waiting. Hide behind the pillars when he looks at you."]],
	"c4_exit": [["MIRA", "The stairs go up now. I'll be with you."]],
}
