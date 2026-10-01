# Neon Exile

Ein 2D-Action-RPG im Neon-Sci-Fi-Stil, gebaut mit **Godot 4.3**.
Aktueller Stand: **Kapitel 1 "The Sump"** ist komplett spielbar (Story, 2 Gegnertypen, Speicherfragment, Boss WARDEN-07).

## Spielen / Testen
1. Godot 4.3 (Standard-Version, nicht .NET) kostenlos laden: https://godotengine.org/download
2. Godot starten → **Import** → Ordner `neon-exile` wählen → `project.godot` öffnen.
3. Oben rechts auf **▶ (Play)** klicken oder F5 drücken.

## Steuerung
| Taste | Aktion |
|---|---|
| WASD / Pfeiltasten | Bewegen |
| Maus | Zielen |
| Linksklick (oder J) halten | Schießen |
| Leertaste / Shift | Dash (kurz unverwundbar) |
| E / Enter / Klick | Dialog weiter, nach dem Tod neu starten |

## Aufbau
- `main.tscn` / `scripts/main.gd` – Spielablauf, Kugeln, Effekte, Story-Trigger
- `scripts/player.gd` – ECHO (Spieler)
- `scripts/enemy.gd` – Crawler und Drohnen
- `scripts/boss.gd` – WARDEN-07 (3 Phasen)
- `scripts/level.gd` + `data/chapter1.txt` – Karte als Text (`#` Wand, `D` Tür, `G` Tor, `c`/`d` Gegner, `S` Fragment, `B` Boss, `1`–`5` Story-Trigger)
- `scripts/story.gd` – alle Dialoge
- `scripts/dialog.gd`, `scripts/hud.gd` – Oberfläche
- `tests/autotest.tscn` – automatischer Durchlauf von Kapitel 1 (für Entwicklung)
- `docs/STORY.md` – Story und Plan für das ganze Spiel
