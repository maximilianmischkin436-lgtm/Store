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
	"HALCYON LOG": Color("#e8e0ff"),
	"THE LIFEGUARD": Color("#ff4d4d"),
	"LOST & FOUND": Color("#ffd27a"),
	"MNEMOS": Color("#ff3030"),
	"THE HEADMASTER": Color("#ffcc33"),
	"THE NIGHT NURSE": Color("#7dffd0"),
	"THE OTHER ECHO": Color("#ff4d6d"),
}

const DIALOG := {
	# ---- Kapitel 1: ECHO weiss nichts ----
	"intro": [
		["SYSTEM", "Reboot complete. Unit ECHO online. Memory core: EMPTY. Last log: [DELETED BY USER]"],
		["ECHO", "...Where am I? Why am I wet?"],
		["???", "...you're awake. Good. Don't ask me who I am yet. Just get up."],
	],
	"shard": [
		["SYSTEM", "Fragment 1 of 7. Reconstructing..."],
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
		["SYSTEM", "Fragment 2 of 7."],
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
		["SYSTEM", "Fragment 3 of 7."],
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
		["SYSTEM", "Fragment 4 of 7."],
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
	# ---- Kapitel 5: das Krankenhaus ----
	"c5_intro": [
		["ECHO", "A hospital. The lights are too clean."],
		["MIRA", "They brought me here at six. Two hours too late."],
	],
	"c5_shard": [
		["SYSTEM", "Fragment 5 of 7. Patient record found."],
		["ECHO", "Upload attempt one. Failed. Attempt two. Failed. Attempt three... partial."],
		["MIRA", "Mom tried to save me. She only saved a piece. That's what I am, Echo."],
	],
	"c5_boss": [
		["THE NIGHT NURSE", "Shhh. She's sleeping. Everyone here is sleeping."],
		["ECHO", "Then I'll wake them up."],
	],
	"c5_victory": [
		["MIRA", "After that night, Mom never left the machines. She became HALCYON."],
		["ECHO", "And I went home. Alone."],
	],
	# ---- Kapitel 6: zu Hause ----
	"c6_intro": [
		["ECHO", "Our apartment. Every door in this hallway is our door."],
		["MIRA", "You never came home that night. So the hallway never ends."],
	],
	"c6_shard": [
		["SYSTEM", "Fragment 6 of 7."],
		["ECHO", "My room. Her drawing is still on the fridge. Echo and Mira."],
		["MIRA", "Something is waiting for you behind the last door. It looks like you."],
	],
	"c6_boss": [
		["THE OTHER ECHO", "You again. You always show up too late."],
		["ECHO", "...I know. Get out of my way."],
	],
	"c6_victory": [
		["MIRA", "You don't have to hate him. He's just the part of you that stayed at the server."],
		["ECHO", "Then I'll take him with me. All the way up."],
	],
	# ---- Kapitel 7: die Krone, das Ende ----
	"c8_intro": [
		["MIRA", "This is the Crown. Everything she couldn't let go of is stored up here."],
		["ECHO", "The pool. The market. The office. The school. It's all here at once."],
		["MIRA", "She built the whole city out of the last day. Over and over."],
	],
	"c8_shard": [
		["SYSTEM", "Fragment 7 of 7. Memory restored: UNIT ECHO."],
		["ECHO", "I wasn't a machine. I was her son. HALCYON uploaded me after the sirens, so she wouldn't be alone."],
		["MIRA", "And when you couldn't stop crying, she let you erase the city. Then she erased you."],
		["ECHO", "She woke me up again. Why?"],
		["MIRA", "Because she's tired, Echo. She wants someone to decide for her."],
	],
	"c8_boss": [
		["HALCYON", "My boy. You came home late again."],
		["HALCYON", "Stay. Forget. It doesn't hurt if you forget."],
		["ECHO", "It's supposed to hurt, Mom."],
	],
	"c8_victory": [
		["HALCYON", "...You're so much older than I remember."],
		["HALCYON", "Three doors. I can't choose. I never could."],
		["MIRA", "Whatever you choose, Echo. I'm not afraid anymore."],
	],
}

const DIALOG2 := {}

const RADIO := {
	"controls": [["???", "Walk. WASD."]],
	"pickup_hint": [["???", "There's something on the floor in front of you. Pick it up. E."]],
	"got_pulse": [["???", "You'll need it. Hold LEFT CLICK. SPACE to jump, twice in the air. SHIFT to dash. CTRL to slide. R to reload."]],
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
	"c4_gate": [["???", "The gym. He's waiting. Hide behind the boards when he looks at you."]],
	"c4_exit": [["MIRA", "The stairs go up now. I'll be with you."]],
	"c5_controls": [["MIRA", "Stay quiet. The nurses hear everything."]],
	"c5_scrap": [["MIRA", "Patients. They're still waiting for someone to visit."]],
	"c5_drones": [["MIRA", "If a nurse hears gunfire, she'll wake the whole ward."]],
	"c5_gate": [["MIRA", "Ward 4. Watch the floor when the monitor beeps."]],
	"c5_halfway": [["MIRA", "Code blue. Keep moving."]],
	"c5_exit": [["MIRA", "The stairwell. It goes home."]],
	"c6_controls": [["MIRA", "Don't trust the family photos. They watch you."]],
	"c6_scrap": [["MIRA", "Neighbors. They're all waiting for their kids to come home."]],
	"c6_drones": [["MIRA", "The ones in the pictures only move when you look away."]],
	"c6_gate": [["MIRA", "The last door. He fights like you. Because he is you."]],
	"c6_halfway": [["MIRA", "He's breaking. So are you. That's okay."]],
	"c6_exit": [["MIRA", "Up. Toward the Crown. Toward her."]],
	"c8_controls": [["MIRA", "Careful. Up here, every room remembers something different."]],
	"c8_scrap": [["MIRA", "All of them. Everyone from that day. They're still waiting."]],
	"c8_drones": [["MIRA", "The ones from every place at once. Don't let them corner you."]],
	"c8_gate": [["MIRA", "She's behind that gate. She knows every trick the others had."]],
	"c8_halfway": [["MIRA", "She's slipping. Keep going."]],
	"c8_exit": [["MIRA", "Choose, Echo. Walk through one of them."]],
}

# Kassetten: HALCYONs Tagebuch. Eine liegt im Level, eine im Geheimraum. Reihenfolge = Kapitel.
const TAPES := {
	"c1_a": "Day one after the sirens. The water rose so fast. I keep the pool lights on, so you can find your way home.",
	"c1_b": "You learned to swim here, Echo. You were so proud. Mira was scared of the deep end. I filled this place with every summer we had.",
	"c2_a": "The evacuation order came at four twelve. Everyone ran to the market. You were supposed to be with Mira. You were with Server Seven.",
	"c2_b": "I bought her the red shoes she wanted. I never gave them to her. They're still in the lost and found.",
	"c3_a": "Unit Echo signed the reset order. My son. Four million memories. He said he couldn't hear her voice anymore without screaming.",
	"c3_b": "I kept one file. Just one. I couldn't delete it. It's inside your core, Echo. It's her.",
	"c4_a": "Room two B. The water came in under the door at four thirty eight. She waited. She drew you on the window with her finger.",
	"c4_b": "If you're hearing this, you found the place she used to hide. She knew you'd find her here. You always did.",
	"c5_a": "Ward four, six oh two PM. Her heart stopped twice. I connected her to the prototype. I didn't ask anyone.",
	"c5_b": "Attempt three kept her voice, and her laugh, and the way she says your name. Nothing else. I'm sorry, sweetheart.",
	"c6_a": "You came home at eleven. You didn't turn on the lights. You just sat by her shoes and didn't say anything.",
	"c6_b": "The next morning you asked me to make it stop hurting. I said I could. I lied a little.",
	"c8_a": "I built the city again from the last day. Over and over. Every loop, I hope you get there on time.",
	"c8_b": "I'm tired, sweetheart. When you reach me, don't forgive me. Just choose. I never could.",
}
