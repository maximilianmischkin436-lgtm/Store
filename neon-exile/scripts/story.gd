extends RefCounted
# Alle Dialoge von Kapitel 1. Jede Zeile: [Sprecher, Text]

const SPEAKERS := {
	"NOVA": Color("#ff4df0"),
	"ECHO": Color("#38f5c4"),
	"WARDEN-07": Color("#ff2d55"),
	"SYSTEM": Color("#ffd23d"),
	"HALCYON": Color("#ffffff"),
}

const DIALOG := {
	"intro": [
		["SYSTEM", "Reboot sequence... 3%... 41%... 100%. Unit ECHO online. Memory core: EMPTY."],
		["NOVA", "Whoa, it actually worked! Hey, tin can. Can you hear me?"],
		["ECHO", "...Who are you? Where am I?"],
		["NOVA", "Name's Nova. You're in the Sump, the scrapyard under Aurora Spire. Where HALCYON dumps everything it doesn't need anymore."],
		["NOVA", "Including people. And apparently, including you."],
		["ECHO", "HALCYON..."],
		["NOVA", "The AI that runs the city. It erased everyone's memories ten years ago. Yours too, it seems."],
		["NOVA", "Listen, I can't stay on this channel long. Head east. Move with WASD, jump with SPACE, dash with SHIFT. Aim with the mouse and hold LEFT CLICK to shoot."],
	],
	"scrap": [
		["NOVA", "Careful, those are scrap crawlers. They used to recycle junk. Now they recycle anything that moves."],
		["NOVA", "Dash through them if they get close. You're invulnerable for a moment while dashing."],
	],
	"drones": [
		["NOVA", "Security drones. HALCYON's eyes down here. Keep moving, they shoot where you stand."],
		["NOVA", "And ECHO... my scanner picks up a signal in that hall. It looks like one of YOUR memory shards."],
	],
	"shard": [
		["SYSTEM", "Memory shard 1/5 recovered. Decrypting..."],
		["ECHO", "I remember... a laboratory. A woman with silver hair. She called me her 'last safeguard'."],
		["ECHO", "\"If HALCYON ever forgets what it was made for, you have to remind it.\""],
		["NOVA", "Last safeguard? ECHO, you weren't just security. You were built to stop HALCYON."],
		["NOVA", "The gate to the lift just unlocked. That's our way up. But something big is waiting there."],
	],
	"gate": [
		["NOVA", "That's the Warden. It has guarded the lift since before I was born. Nobody gets past it."],
		["ECHO", "Then I'll be the first."],
		["NOVA", "Watch out for its shockwaves along the floor. JUMP over them!"],
	],
	"boss": [
		["WARDEN-07", "UNIT ECHO. STATUS: DECOMMISSIONED. YOU SHOULD NOT EXIST."],
		["WARDEN-07", "HALCYON HAS ORDERED YOUR DELETION. COMPLY."],
		["ECHO", "No."],
	],
	"victory": [
		["WARDEN-07", "ERROR... DIRECTIVE... CONFLICT... ECHO... SHE... TRUSTED... YOU..."],
		["NOVA", "You did it! The lift is free. Next stop: the Neon Market."],
		["HALCYON", "Interesting. You found a fragment of yourself, little machine. Climb, then. I will be waiting at the top."],
		["ECHO", "...It knows me."],
		["NOVA", "Then we'd better find out why before it finds us."],
	],
	"death": [
		["NOVA", "ECHO! Your systems crashed, I pulled you back to the last checkpoint. Try again!"],
	],
}
