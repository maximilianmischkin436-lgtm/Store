# Neon Exile

Ein **First-Person** Action-RPG im Neon-Sci-Fi-Stil, gebaut mit **Godot 4.3**.
(Die alte 2D-Version liegt noch als `main.tscn` im Projekt.)
Aktueller Stand: **Kapitel 1–4** sind spielbar (Poolrooms, 90er-Mall, Backrooms, Schule bei Sonnenuntergang), je mit Boss und Story. Im Hauptmenü unter **CHAPTERS** kann man jedes Kapitel direkt starten.

## Spielen / Testen
1. Godot 4.3 (Standard-Version, nicht .NET) kostenlos laden: https://godotengine.org/download
2. Godot starten → **Import** → Ordner `neon-exile` wählen → `project.godot` öffnen.
3. Oben rechts auf **▶ (Play)** klicken oder F5 drücken.

## Steuerung
| Taste | Aktion |
|---|---|
| WASD / Pfeiltasten | Bewegen |
| Maus | Umschauen / Zielen |
| Linksklick (oder J) halten | Schießen |
| Leertaste | Springen (über die Schockwellen des Bosses!) |
| Leertaste (in der Luft) | Doppelsprung |
| Shift | Dash (kurz unverwundbar) |
| Strg / C beim Laufen | Rutschen (Sprung aus dem Rutschen behält den Schwung) |
| E | Waffen und Gegenstände aufheben |
| E / Enter / Klick | Dialog weiter, nach dem Tod neu starten |
| 1 / 2 / 3 oder Mausrad | Waffe wechseln (Pulse, Scatter, Rail) |
| Q | Fähigkeit OVERLOAD (Schockwelle) |
| Esc | Pause (dort M = Hauptmenü, Fortschritt wird gespeichert) |

## Aufbau
- `game3d.tscn` / `scripts3d/` – die 3D-Version (Hauptszene): `main3d.gd`, `player3d.gd`, `enemy3d.gd`, `boss3d.gd`, `level3d.gd`, `hud3d.gd`
- `main.tscn` / `scripts/main.gd` – alte 2D-Version
- `scripts/player.gd` – ECHO (Spieler)
- `scripts/enemy.gd` – Crawler und Drohnen
- `scripts/boss.gd` – WARDEN-07 (3 Phasen)
- `scripts/level.gd` + `data/chapter1.txt` – Karte als Text (`#` Wand, `D` Tür, `G` Tor, `c`/`d` Gegner, `S` Fragment, `B` Boss, `1`–`5` Story-Trigger)
- `scripts/story.gd` – alle Dialoge
- `scripts/dialog.gd`, `scripts/hud.gd` – Oberfläche
- `tests/autotest.tscn` – automatischer Durchlauf von Kapitel 1 (für Entwicklung)
- `docs/STORY.md` – Story und Plan für das ganze Spiel

## Menü, Speichern, Einstellungen
- Hauptmenü mit **Continue / New Game / Settings / Quit**.
- Fortschritt wird automatisch an 3 Punkten gespeichert (Schrottplatz geschafft, Fragment geholt, Kapitel fertig).
- Einstellungen: Maus-Empfindlichkeit, Musik- und Soundlautstärke, Vollbild.

## Credits
- 3D-Modelle (Waffen, Drohne) und Soundeffekte: **Kenney – Starter Kit FPS** (MIT-Lizenz, siehe `assets/kenney/LICENSE-Kenney-Starter-Kit-FPS.md`).
- Weitere Modelle (Ghettoblaster, Spielzeugauto, Sessel, Sofa): Khronos glTF Sample Assets, siehe `assets/khronos/CREDITS.md`.
- Gegner (HOLLOW, WATCHER) und Bosse sind selbst aus Grundformen gebaut.
- Musik: selbst erzeugt mit `tools/gen_music.py`.

## Kapitel
| # | Ort | Boss |
|---|---|---|
| 1 | The Drain – Poolrooms | WARDEN-07 |
| 2 | The Neon Market – leere 90er-Mall bei Nacht | MAMMON |
| 3 | The Archive – Backrooms | MNEMOS |
| 4 | After School – Schule bei Sonnenuntergang | THE HEADMASTER |

Karten für Kapitel 2–4 erzeugt `tools/gen_maps.py`, die Musik `tools/gen_music.py`.
Automatischer Test eines Kapitels: `godot --path . res://tests/autotest3d.tscn -- 3`
