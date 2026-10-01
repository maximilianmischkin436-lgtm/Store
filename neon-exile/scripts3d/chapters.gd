extends RefCounted
# Daten aller Kapitel: Karte, Optik, Musik, Gegner, Boss, Texte.

const CHAPTERS := [
	{
		"name": "THE DRAIN", "map": "res://data/chapter1.txt", "theme": "pool", "music": "pool", "wall_h": 6.0,
		"objectives": ["Find a way out of the Drain", "Get through the flooded halls", "Recover the memory shard", "Reach the lift", "Defeat WARDEN-07"],
		"env": {"sky_top": Color(0.55, 0.72, 0.9), "sky_hor": Color(0.9, 0.92, 0.95), "fog": Color(0.85, 0.92, 0.95), "fog_d": 0.007, "amb": 0.3, "exp": 0.75, "sun": Color(1.0, 0.96, 0.88), "sun_e": 0.45, "sun_rot": Vector3(-1.2, 0.5, 0), "sat": 1.1},
		"lights": ["#dff6ff", "#fff4e6", "#e6f0ff", "#ffe0e6"], "light_e": 0.6,
		"enemy": Color("#d9e6ea"), "drone": Color("#bcd3dc"), "proj": Color("#0e2a44"),
		"boss": {"name": "WARDEN-07", "body": Color("#dfe9ec"), "eye": Color("#38c9ff"), "proj": Color("#0e2a44"), "hp": 160},
		"next": "Chapter 2: The Neon Market",
		"transition": ["Behind the door, the stairs only go down.", "The water follows you, step by step.", "Somewhere below, music starts playing."],
		"memories": ["do you remember this place?", "you learned to swim here", "SHE was waiting by the edge", "it's always 4 PM here", "the water is warm", "don't run near the pool", "MIRA", "nobody comes here anymore", "wake up, ECHO"],
	},
	{
		"name": "THE NEON MARKET", "map": "res://data/chapter2.txt", "theme": "mall", "music": "mall", "wall_h": 8.0,
		"objectives": ["Explore the closed mall", "Get past the shoppers", "Find the shard by the fountain", "Head to the food court", "Defeat MAMMON"],
		"env": {"sky_top": Color(0.05, 0.03, 0.12), "sky_hor": Color(0.25, 0.1, 0.3), "fog": Color(0.22, 0.1, 0.28), "fog_d": 0.01, "amb": 0.6, "exp": 1.0, "sun": Color(0.6, 0.5, 1.0), "sun_e": 0.15, "sun_rot": Vector3(-1.0, 0.3, 0), "sat": 1.15},
		"lights": ["#ff8fd0", "#8fe9ff", "#ffcf8f", "#ff6f9f"], "light_e": 1.4,
		"enemy": Color("#e8d6c8"), "drone": Color("#d9c2e0"), "proj": Color("#ff4fa3"),
		"boss": {"name": "MAMMON", "body": Color("#ffd27a"), "eye": Color("#ff4fa3"), "proj": Color("#ff4fa3"), "hp": 210},
		"next": "Chapter 3: The Archive",
		"transition": ["The staff door opens onto an office.", "Then another. Then another.", "The mall music fades into a hum."],
		"memories": ["the mall closed at 9", "we used to come here on Saturdays", "SHE bought you a balloon", "lost child, please come to the info desk", "everything is 50% off forever", "do you hear the fountain?", "MIRA, don't run on the escalator", "the music never stops"],
	},
	{
		"name": "THE ARCHIVE", "map": "res://data/chapter3.txt", "theme": "office", "music": "office", "wall_h": 3.4,
		"objectives": ["Find your way through the Archive", "Clear the filing halls", "Follow the lights to the shard", "Find the exit stairwell", "Defeat MNEMOS"],
		"env": {"sky_top": Color(0.4, 0.38, 0.2), "sky_hor": Color(0.6, 0.55, 0.3), "fog": Color(0.55, 0.5, 0.28), "fog_d": 0.03, "amb": 0.25, "exp": 0.85, "sun": Color(1.0, 0.95, 0.7), "sun_e": 0.0, "sun_rot": Vector3(-1.2, 0.5, 0), "sat": 0.95},
		"lights": ["#fff6c8", "#fff1b0", "#fff6c8", "#ffe9a0"], "light_e": 0.8,
		"enemy": Color("#c9bf8f"), "drone": Color("#b8ad7a"), "proj": Color("#3a2e10"),
		"boss": {"name": "MNEMOS", "body": Color("#d8cc90"), "eye": Color("#ff3030"), "proj": Color("#3a2e10"), "hp": 250},
		"next": "Chapter 4: After School",
		"transition": ["At the end of the last corridor, a school bell rings.", "The light turns orange.", "You've been here before. You were smaller then."],
		"memories": ["FILE 00412: SATURDAY AT THE PARK (ERASED)", "this room again", "you've been walking for hours", "did you hear that?", "FILE 88120: FIRST DAY OF SCHOOL (ERASED)", "the lights are humming your name", "no exit", "FILE 10001: MOM (ERASED)"],
	},
	{
		"name": "AFTER SCHOOL", "map": "res://data/chapter4.txt", "theme": "school", "music": "school", "wall_h": 4.0,
		"objectives": ["Walk the empty school", "Get past the hall monitors", "Find Mira's classroom", "Go to the gym", "Defeat THE HEADMASTER"],
		"env": {"sky_top": Color(0.35, 0.25, 0.45), "sky_hor": Color(1.0, 0.55, 0.3), "fog": Color(0.95, 0.6, 0.4), "fog_d": 0.01, "amb": 0.35, "exp": 0.9, "sun": Color(1.0, 0.6, 0.35), "sun_e": 1.4, "sun_rot": Vector3(-0.25, 1.3, 0), "sat": 1.1},
		"lights": ["#ffb070", "#ffc890", "#ffb070", "#ff9a6a"], "light_e": 0.7,
		"enemy": Color("#e6d2b0"), "drone": Color("#d6c0a0"), "proj": Color("#5a1e2e"),
		"boss": {"name": "THE HEADMASTER", "body": Color("#c8b49a"), "eye": Color("#ffcc33"), "proj": Color("#5a1e2e"), "hp": 290},
		"next": "Chapter 5: The Crown",
		"transition": ["The stairs only go up now.", "Toward the Crown.", "Toward her."],
		"memories": ["it's always sunset here", "Mira sat by the window", "the bell never rings anymore", "who is picking you up today?", "DON'T FORGET YOUR HOMEWORK", "she drew you in art class", "everyone went home", "you were her best friend"],
	},
]
