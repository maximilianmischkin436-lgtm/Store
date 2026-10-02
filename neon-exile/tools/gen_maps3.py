# Engere Karten: Flure mit Raeumen links/rechts (Schule, Krankenhaus, Buero, Zuhause),
# kleinere Hallen fuer Pool, Mall, U-Bahn, Krone. Aufbau wie vorher:
# Startraum A -> Tuer D -> Abschnitt B -> Tuer D -> Abschnitt C (Ereignis + Splitter) -> Tor G -> Boss-Arena.
# Neue Zeichen:  W = Wand mit Fenster,  Y = Aussenbereich hinter Fenstern (nicht begehbar, offener Himmel)
#                k / K = Mitte eines Seitenraums (Tuer unten / oben) fuer Moebel und sitzende Figuren
# Aufruf: python3 tools/gen_maps3.py
import random, subprocess
W, H = 98, 30

def gen(ch, seed, widths, kind, crawlers, drones, windows=False):
    rnd = random.Random(seed)
    g = [['#'] * W for _ in range(H)]
    def rect(x1, y1, x2, y2, c='.'):
        for y in range(max(2, y1), min(H - 2, y2 + 1)):
            for x in range(max(2, x1), min(W - 2, x2 + 1)):
                g[y][x] = c
    rooms_style = kind in ('school', 'hospital', 'office', 'home')
    c0, c1 = (14, 15) if rooms_style else (13, 16)      # Flur-/Hauptweg-Zeilen
    xs = [2]
    for wdt in widths:
        xs.append(xs[-1] + wdt)
    rooms = []
    for i in range(4):
        x1 = xs[i] + (0 if i == 0 else 2)
        x2 = xs[i + 1] - 1 if i < 3 else W - 3
        if i == 0:
            y1, y2 = 12, 17
        elif i == 3:
            y1, y2 = 7, 22
        elif rooms_style:
            y1, y2 = c0, c1
        else:
            hgt = rnd.randint(3, 5)
            y1, y2 = c0 - hgt, c1 + hgt
        rect(x1, y1, x2, y2)
        rooms.append([x1, y1, x2, y2])
        if i in (1, 2) and rooms_style:
            # Seitenraeume entlang des Flurs: 4 tief, 3-5 breit, je eine Tuer zum Flur
            for side in (-1, 1):
                x = x1
                while x + 3 <= x2:
                    rw = rnd.randint(3, 5)
                    if x + rw - 1 > x2: rw = x2 - x + 1
                    if rw < 3: break
                    if side < 0:
                        ry1, ry2, wall_y = c0 - 5, c0 - 2, c0 - 1
                    else:
                        ry1, ry2, wall_y = c1 + 2, c1 + 5, c1 + 1
                    rect(x, ry1, x + rw - 1, ry2)
                    door_x = x + rnd.randint(0, rw - 1)
                    g[wall_y][door_x] = '.'
                    g[(ry1 + ry2) // 2][x + rw // 2] = 'k' if side < 0 else 'K'
                    if windows:
                        oy = ry1 - 1 if side < 0 else ry2 + 1
                        for xx in range(x, x + rw):
                            g[oy][xx] = 'W'
                    x += rw + 1
        elif i in (1, 2) and x2 - x1 > 10:
            for _ in range(rnd.randint(1, 2)):
                ax = rnd.randint(x1, x2 - 6); aw = rnd.randint(4, 7)
                if rnd.random() < 0.5: rect(ax, y1 - 3, min(x2, ax + aw), y1)
                else: rect(ax, y2, min(x2, ax + aw), y2 + 3)
    if windows:
        # Pausenhof hinter den Fenstern (oben und unten), nicht begehbar
        for y in list(range(2, c0 - 6)) + list(range(c1 + 7, H - 2)):
            for x in range(rooms[1][0], rooms[2][2] + 1):
                if g[y][x] == '#': g[y][x] = 'Y'
    # Gaenge zwischen den Abschnitten mit Tueren/Tor
    for i in range(3):
        a, b = rooms[i], rooms[i + 1]
        rect(a[2] + 1, c0, b[0] - 1, c1)
        col = a[2] + 1
        for y in range(c0, c1 + 1):
            g[y][col] = 'D' if i < 2 else 'G'
    def pillar(x, y, w=1, h=1):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                if c0 - 1 <= yy <= c1 + 1: return
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                if g[yy][xx] == '.': g[yy][xx] = '#'
    if not rooms_style:
        for r in rooms[1:3]:
            x1, y1, x2, y2 = r
            for x in range(x1 + 3, x2 - 2, 4):
                for y in (y1 + 1, y2 - 1):
                    if rnd.random() < 0.7: pillar(x, y)
    D = rooms[3]
    for _ in range(4):
        pillar(rnd.randint(D[0] + 4, D[2] - 5), rnd.choice([rnd.randint(D[1] + 1, 10), rnd.randint(19, D[3] - 1)]), 2, 2)
    A, B, C, Dd = rooms
    g[14][A[0] + 3] = 'P'; g[14][A[0] + 5] = '1'
    for y in range(c0, c1 + 1):
        g[y][B[0] + 1] = '2'; g[y][C[0] + 1] = '3'; g[y][C[2] + 2] = '4'; g[y][Dd[0] + 2] = '5'
    def free(r, corridor_ok=True):
        for _ in range(800):
            x = rnd.randint(r[0] + 2, r[2] - 2); y = rnd.randint(2, H - 3)
            if g[y][x] == '.' and abs(x - r[0]) > 3: return x, y
        return r[0] + 4, 14
    for _ in range(crawlers):
        x, y = free(B); g[y][x] = 'c'
    for _ in range(3):
        x, y = free(C); g[y][x] = 'c'
    for _ in range(drones):
        x, y = free(C); g[y][x] = 'd'
    g[c1][(C[0] + C[2]) // 2] = 'S'
    g[14][(Dd[0] + Dd[2]) // 2 + 2] = 'B'
    open(f'data/chapter{ch}.txt', 'w').write('\n'.join(''.join(r) for r in g) + '\n')

gen(1, 11, [12, 30, 22], 'pool', 7, 4)
gen(2, 22, [12, 32, 22], 'mall', 8, 5)
gen(3, 33, [11, 30, 26], 'office', 8, 5)
gen(4, 44, [12, 30, 26], 'school', 7, 5, windows=True)
gen(5, 55, [11, 30, 26], 'hospital', 8, 6)
gen(6, 66, [12, 28, 28], 'home', 8, 6)
gen(7, 77, [11, 30, 26], 'subway', 9, 6)
gen(9, 88, [13, 28, 24], 'crown', 9, 6)
subprocess.run(['python3', 'tools/carve_secrets.py'])
