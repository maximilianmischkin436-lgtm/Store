# Neue, abwechslungsreiche Karten fuer alle Kapitel (ausser der Wiese).
# Aufbau bleibt: Startraum A -> Tuer D -> Raum B (Kampf) -> Tuer D -> Raum C (Ereignis + Splitter) -> Tor G -> Boss-Arena D
# Aber: jeder Raum hat eine eigene Form (L/T-Anbauten, Nebenraeume) und ein eigenes Innenmuster.
# Der Hauptweg (Zeilen 12-17) bleibt immer frei. Aufruf: python3 tools/gen_maps2.py
import random, subprocess
W, H = 98, 30

def gen(ch, seed, widths, style, crawlers, drones):
    rnd = random.Random(seed)
    g = [['#'] * W for _ in range(H)]
    def rect(x1, y1, x2, y2, c='.'):
        for y in range(max(2, y1), min(H - 2, y2 + 1)):
            for x in range(max(2, x1), min(W - 2, x2 + 1)):
                g[y][x] = c
    # Raumgrenzen aus den Breiten
    xs = [2]
    for wdt in widths:
        xs.append(xs[-1] + wdt)
    rooms = []
    for i in range(4):
        x1 = xs[i] + (0 if i == 0 else 2)
        x2 = xs[i + 1] - 1 if i < 3 else W - 3
        hgt = rnd.randint(7, 12)
        y1, y2 = 14 - hgt, 15 + hgt
        if i == 0: y1, y2 = 8, 21
        rect(x1, y1, x2, y2)
        rooms.append([x1, max(2, y1), x2, min(H - 3, y2)])
        # Anbauten fuer L/T-Formen
        if i in (1, 2) and x2 - x1 > 10:
            for _ in range(rnd.randint(1, 2)):
                ax = rnd.randint(x1, x2 - 6); aw = rnd.randint(5, 9)
                if rnd.random() < 0.5: rect(ax, 2, min(x2, ax + aw), y1)
                else: rect(ax, y2, min(x2, ax + aw), H - 3)
    # Gaenge zwischen den Raeumen (Zeilen 13-16) mit Tueren/Tor
    for i in range(3):
        a, b = rooms[i], rooms[i + 1]
        rect(a[2] + 1, 13, b[0] - 1, 16)
        col = a[2] + 1
        for y in range(13, 17):
            g[y][col] = 'D' if i < 2 else 'G'
    # Innenmuster pro Stil (nur Raeume B, C und Arena)
    def pillar(x, y, w=2, h=2):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                if 12 <= yy <= 17: return
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                if g[yy][xx] == '.': g[yy][xx] = '#'
    for i, r in enumerate(rooms[1:], 1):
        x1, y1, x2, y2 = r
        st = 'arena' if i == 3 else style[i - 1]
        if st == 'grid':
            for x in range(x1 + 3, x2 - 2, 5):
                for y in range(y1 + 2, y2 - 1, 5): pillar(x, y)
        elif st == 'rows':
            for x in range(x1 + 4, x2 - 3, 6):
                for y in list(range(y1 + 1, 11)) + list(range(19, y2)):
                    if g[y][x] == '.' and rnd.random() < 0.85: g[y][x] = '#'
        elif st == 'maze':
            for _ in range(10):
                x = rnd.randint(x1 + 2, x2 - 6); y = rnd.choice([rnd.randint(y1 + 1, 10), rnd.randint(19, max(19, y2 - 1))])
                if rnd.random() < 0.5: pillar(x, y, rnd.randint(3, 6), 1)
                else: pillar(x, y, 1, rnd.randint(2, 4))
        elif st == 'ring':
            cx, cy = (x1 + x2) // 2, 14
            for a in range(0, 360, 30):
                import math
                x = int(cx + math.cos(math.radians(a)) * min(8, (x2 - x1) // 3)); y = int(cy + math.sin(math.radians(a)) * 6)
                pillar(x, y)
        elif st == 'scatter':
            for _ in range(8):
                pillar(rnd.randint(x1 + 2, x2 - 3), rnd.randint(y1 + 1, y2 - 2), rnd.randint(1, 3), rnd.randint(1, 3))
        elif st == 'arena':
            for _ in range(4):
                pillar(rnd.randint(x1 + 4, x2 - 5), rnd.choice([rnd.randint(y1 + 2, 9), rnd.randint(20, max(20, y2 - 3))]))
    A, B, C, D = rooms
    g[14][A[0] + 4] = 'P'; g[14][A[0] + 6] = '1'
    for y in range(13, 17):
        g[y][B[0] + 1] = '2'; g[y][C[0] + 1] = '3'; g[y][C[2] + 2] = '4'; g[y][D[0] + 2] = '5'
    def free(r):
        for _ in range(500):
            x = rnd.randint(r[0] + 2, r[2] - 2); y = rnd.randint(r[1] + 1, r[3] - 1)
            if g[y][x] == '.' and abs(x - r[0]) > 3: return x, y
        return r[0] + 4, 14
    for _ in range(crawlers):
        x, y = free(B); g[y][x] = 'c'
    for _ in range(3):
        x, y = free(C); g[y][x] = 'c'
    for _ in range(drones):
        x, y = free(C); g[y][x] = 'd'
    g[15][(C[0] + C[2]) // 2] = 'S'
    g[14][(D[0] + D[2]) // 2 + 2] = 'B'
    open(f'data/chapter{ch}.txt', 'w').write('\n'.join(''.join(r) for r in g) + '\n')

# Kapitel: Breiten der Raeume A,B,C (D = Rest), Innenmuster fuer B und C
gen(1, 11, [14, 30, 22], ['scatter', 'ring'], 7, 4)      # Pool: Becken-Inseln, runde Halle
gen(2, 22, [13, 34, 20], ['rows', 'grid'], 8, 5)         # Mall: Ladenzeilen, Saeulenhalle
gen(3, 33, [12, 28, 26], ['maze', 'grid'], 8, 5)         # Archiv: Trennwand-Labyrinth
gen(4, 44, [14, 26, 24], ['rows', 'maze'], 7, 5)         # Schule: Bankreihen, Flure
gen(5, 55, [12, 30, 24], ['grid', 'rows'], 8, 6)         # Krankenhaus: Bettenreihen
gen(6, 66, [13, 24, 30], ['maze', 'scatter'], 8, 6)      # Zuhause: verwinkelt
gen(8, 88, [14, 28, 24], ['ring', 'scatter'], 9, 6)      # Krone
subprocess.run(['python3', 'tools/carve_secrets.py'])
