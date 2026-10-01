extends RefCounted
# Daten aller Kapitel: Karte, Optik, Musik, Gegner, Boss, Texte.

const CHAPTERS := [
	{
		"name": "THE DRAIN", "map": "res://data/chapter1.txt", "theme": "pool", "music": "pool", "wall_h": 6.0,
		"objectives": ["Find a way out", "Get through the flooded halls", "Find the glowing fragment", "Follow the water", "Survive THE LIFEGUARD"],
		"env": {"sky_top": Color(0.55, 0.72, 0.9), "sky_hor": Color(0.9, 0.92, 0.95), "fog": Color(0.85, 0.92, 0.95), "fog_d": 0.007, "amb": 0.3, "exp": 0.75, "sun": Color(1.0, 0.96, 0.88), "sun_e": 0.45, "sun_rot": Vector3(-1.2, 0.5, 0), "sat": 1.1},
		"lights": ["#dff6ff", "#fff4e6", "#e6f0ff", "#ffe0e6"], "light_e": 0.6,
		"enemy": Color("#d9e6ea"), "drone": Color("#bcd3dc"), "proj": Color("#0e2a44"),
		"boss": {"name": "THE LIFEGUARD", "kind": "lifeguard", "proj": Color("#0e2a44"), "hp": 170, "phase1": "NO RUNNING", "phase2": "SHE CALLED FOR HELP"},
		"next": "Chapter 2: The Neon Market",
		"transition": ["Behind the door, the stairs only go down.", "You don't remember choosing to follow them.", "Somewhere below, music starts playing."],
		"memories": ["why are you here?", "she wanted to swim", "you were supposed to watch", "it's always 4 PM here", "the water is too still", "DON'T RUN NEAR THE POOL", "who is ECHO?", "nobody comes here anymore", "wake up"],
	},
	{
		"name": "THE NEON MARKET", "map": "res://data/chapter2.txt", "theme": "mall", "music": "mall", "wall_h": 8.0,
		"objectives": ["Where am I now?", "Get past the shoppers", "Find the fragment by the fountain", "Head to the lost & found", "Survive LOST & FOUND"],
		"env": {"sky_top": Color(0.05, 0.03, 0.12), "sky_hor": Color(0.25, 0.1, 0.3), "fog": Color(0.22, 0.1, 0.28), "fog_d": 0.01, "amb": 0.6, "exp": 1.0, "sun": Color(0.6, 0.5, 1.0), "sun_e": 0.15, "sun_rot": Vector3(-1.0, 0.3, 0), "sat": 1.15},
		"lights": ["#ff8fd0", "#8fe9ff", "#ffcf8f", "#ff6f9f"], "light_e": 1.4,
		"enemy": Color("#e8d6c8"), "drone": Color("#d9c2e0"), "proj": Color("#ff4fa3"),
		"boss": {"name": "LOST & FOUND", "kind": "mannequin", "proj": Color("#ff4fa3"), "hp": 200, "phase1": "DON'T LOOK AWAY", "phase2": "YOU LET GO OF HER HAND"},
		"next": "Chapter 3: The Archive",
		"transition": ["The staff door opens onto an office.", "Then another. Then another.", "On every desk, a file with your name on it."],
		"memories": ["the sirens started at 4:12", "hold my hand, Echo", "PRIORITY ORDER: SERVER 7", "lost child, please come to the info desk", "you let go", "everyone ran", "the music never stopped", "why did you let go?"],
	},
	{
		"name": "THE ARCHIVE", "map": "res://data/chapter3.txt", "theme": "office", "music": "office", "wall_h": 3.4,
		"objectives": ["Find your way through the offices", "Clear the filing halls", "Follow the lights to the fragment", "Find the exit stairwell", "Survive MNEMOS"],
		"env": {"sky_top": Color(0.4, 0.38, 0.2), "sky_hor": Color(0.6, 0.55, 0.3), "fog": Color(0.55, 0.5, 0.28), "fog_d": 0.03, "amb": 0.25, "exp": 0.85, "sun": Color(1.0, 0.95, 0.7), "sun_e": 0.0, "sun_rot": Vector3(-1.2, 0.5, 0), "sat": 0.95},
		"lights": ["#fff6c8", "#fff1b0", "#fff6c8", "#ffe9a0"], "light_e": 0.8,
		"enemy": Color("#c9bf8f"), "drone": Color("#b8ad7a"), "proj": Color("#3a2e10"),
		"boss": {"name": "MNEMOS", "kind": "mnemos", "proj": Color("#3a2e10"), "hp": 230, "phase1": "EXECUTOR: UNIT ECHO", "phase2": "YOU SIGNED IT"},
		"next": "Chapter 4: After School",
		"transition": ["At the end of the last corridor, a school bell rings.", "The light turns orange.", "You know this place. You have always known it."],
		"memories": ["FILE 00412: SATURDAY AT THE PARK (ERASED)", "ERASED BY: ECHO", "this room again", "FILE 88120: FIRST DAY OF SCHOOL (ERASED)", "AUTHORIZED: UNIT ECHO", "4,812,330 memories deleted", "the lights are humming your name", "FILE 10001: MOM (ERASED)"],
	},
	{
		"name": "AFTER SCHOOL", "map": "res://data/chapter4.txt", "theme": "school", "music": "school", "wall_h": 4.0,
		"objectives": ["Walk the empty school", "Don't let them notice you", "Find classroom 2B", "Go to the gym", "Survive THE HEADMASTER"],
		"env": {"sky_top": Color(0.35, 0.25, 0.45), "sky_hor": Color(1.0, 0.55, 0.3), "fog": Color(0.95, 0.6, 0.4), "fog_d": 0.01, "amb": 0.35, "exp": 0.9, "sun": Color(1.0, 0.6, 0.35), "sun_e": 1.4, "sun_rot": Vector3(-0.25, 1.3, 0), "sat": 1.1},
		"lights": ["#ffb070", "#ffc890", "#ffb070", "#ff9a6a"], "light_e": 0.7,
		"enemy": Color("#e6d2b0"), "drone": Color("#d6c0a0"), "proj": Color("#5a1e2e"),
		"boss": {"name": "THE HEADMASTER", "kind": "headmaster", "proj": Color("#5a1e2e"), "hp": 260, "phase1": "YOU WERE LATE", "phase2": "YOU WERE ALWAYS LATE"},
		"next": "Chapter 5: The Crown",
		"transition": ["The stairs only go up now.", "For the first time, you want to remember.", "Toward the Crown. Toward her."],
		"memories": ["it's always sunset here", "she waited by the window", "who is picking you up today?", "you were supposed to pick her up", "DON'T FORGET", "she drew you in art class", "everyone went home. she didn't", "you were late"],
	},
]
