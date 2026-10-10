# Liminal VHS Shader Pack (Godot 4.3+)

Drop-in screen and model effects for liminal / analog-horror games — taken straight from the game *Neon Exile*.

## What's inside
| File | What it does |
|---|---|
| `addons/liminal_vhs/vhs_filter.gdshader` | Full-screen VHS: scanlines, chroma bleed, tracking band, noise, vignette, glitch input. One `strength` slider (0–1). |
| `addons/liminal_vhs/liminal_shell.gdshader` | Model overlay (next pass): cold fresnel rim, crawling scanlines, flicker, and an occasional **displaced double image** — makes anything feel "not quite right". |
| `addons/liminal_vhs/liminal_fx.gd` | `LiminalFX` node: VHS on/off, **memory flashback** (white flash + text), **hallucination** (world snaps to "real" daylight for a few seconds, monsters vanish), glitch bursts, `apply_shell()` helper. |
| `demo/` | Walkable pool-room demo. Keys: 1 VHS, 2 flashback, 3 hallucination, 4 glitch, 5/6 strength. |

Works with **Compatibility, Mobile and Forward+** renderers.

## Quick start
```gdscript
var fx := LiminalFX.new()
add_child(fx)
fx.set_vhs(true, 0.25)                 # subtle tape look
fx.flashback("you were there")         # memory flash
fx.hallucinate($WorldEnvironment.environment, 4.0)
LiminalFX.apply_shell($Monster, Color(1, 0.4, 0.3), 1.2)
```
Put monsters in the group **`liminal_hide`** and they disappear while the hallucination lasts.

## Tips
- `strength` 0.15–0.3 looks like a clean VHS rip, 0.6+ is a damaged tape.
- Call `fx.glitch(0.4)` on hits, jump scares or scene changes.
- The shell works on skinned characters too (it is applied as `next_pass`).

License: see `LICENSE.txt` (commercial use OK, no redistribution of the assets themselves).
