# Horror AI Kit (Godot 4.3+)

Three horror enemies/setpieces from the game *Neon Exile*, ready to drop into any 3D project.

| Script | What it does |
|---|---|
| `HorrorWatcher` | Patrols between points with a **visible light cone**. Line-of-sight check, alert meter (faster when close), cone turns red, then `spotted(target)`. Can't be hurt – shots only make it suspicious. `ignore_target` callable for e.g. *"inspectors ignore you when you have a ticket"*. |
| `HorrorChaser` | Something that is **always right behind you**: rubber-band speed (slower than a sprint, but catches up when you're far away), twitchy motion, red glow, optional looping footsteps. `caught(target)`. |
| `StretchingCorridor` | A corridor whose **exit door keeps running away** for N seconds, then finally lets you reach it. Builds its own geometry. `door_reached`. Perfect together with `HorrorChaser`. |

All three come with a simple default body, or put your own model into a child node named **`Visual`** (it will be rotated to face the movement direction).

## Quick start
```gdscript
var w := HorrorWatcher.new()
w.patrol = [Vector3(-9, 0, -3), Vector3(9, 0, -3)]
w.target = $Player
w.spotted.connect(func(_t): get_tree().reload_current_scene())
add_child(w)

var corridor := StretchingCorridor.new()
corridor.target = $Player
add_child(corridor); corridor.start()
var chaser := HorrorChaser.new()
chaser.target = $Player
chaser.caught.connect(func(_t): print("caught"))
add_child(chaser); chaser.start()
```
Line-of-sight uses physics layer 1 for walls.

## Demo
`demo/demo.tscn`: **1** stealth room with two watchers, **2** the stretching corridor chase (hold Shift to run).

License: see `LICENSE.txt`.
