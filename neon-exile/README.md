# Neon Exile

Ein **First-Person** Action-RPG im Neon-Sci-Fi-Stil, gebaut mit **Godot 4.3**.
(Die alte 2D-Version liegt noch als `main.tscn` im Projekt.)
Aktueller Stand: **Kapitel 1 "The Sump"** ist komplett spielbar (Story, 2 Gegnertypen, Speicherfragment, Boss WARDEN-07).

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
| Shift | Dash (kurz unverwundbar) |
| E / Enter / Klick | Dialog weiter, nach dem Tod neu starten |
| 1 / 2 / 3 oder Mausrad | Waffe wechseln (Pulse, Scatter, Rail) |
| Q | Fähigkeit OVERLOAD (Schockwelle) |
| Esc | Maus freigeben (Klick fängt sie wieder) |

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
