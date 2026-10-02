# Liminal Level Generator (Godot 4.3+)

Procedural liminal spaces in two calls: a **layout generator** and a **3D builder**. From the game *Neon Exile*.

```gdscript
var rows := LiminalLevelGen.generate(seed, "rooms", 3, true)   # style: "rooms" | "halls" | "pool"
var level := LiminalLevelBuilder.new()
add_child(level)
level.build(rows)
$Player.global_position = level.start_position
$Player.add_to_group("door_openers")     # doors swing open for this node
level.fell_into_pit.connect(_on_fell)    # pool style: bottomless pits
level.reached_exit.connect(_on_exit)
```

## Layout characters
`#` wall · `.` floor · `P` start · `E` exit · `o` swing door · `W` window wall · `Y` outside yard (open sky) · `V` bottomless pit · `k`/`K` side-room centre

You can also write the text maps by hand and pass them to `build()`.

## Styles
- **rooms** – narrow corridor with zig-zag chicanes, classrooms/offices left and right, doors, connecting doors between rooms, windows looking onto a schoolyard.
- **halls** – low halls with partitions, alcoves and dead ends.
- **pool** – halls with bottomless pools and narrow walkways.

## Builder options (export vars)
`cell` (3 m), `wall_height`, `wall_material`, `floor_material`, `ceiling_material`, `round_corners`, `guide_arrows`, `furniture`, `door_color`.
After `build()`: `start_position`, `exit_position`, `side_rooms`, `seats` (free chairs for seated NPCs).

## Performance
Walls/floors/ceilings are merged into strips, all corner pillars are one `MultiMesh`, few lights.

## Demo
`demo/demo.tscn` – R new seed, 1/2/3 switch style, walk with WASD. Touch the glowing door to get the next level.

License: see `LICENSE.txt`.
