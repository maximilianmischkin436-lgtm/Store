# Erzeugt die Karten fuer Kapitel 2-4 im gleichen Aufbau wie Kapitel 1:
# Startraum -> Tuer D -> Raum mit Nahkampfgegnern -> Tuer D -> Raum mit Drohnen + Fragment S -> Tor G -> Boss-Arena B
# Gaenge liegen immer in den Zeilen 13-16. Aufruf: python3 tools/gen_maps.py
import random

def gen(path, seed, rooms, crawlers, drones, extra_walls):
    rnd = random.Random(seed)
    W, H = 98, 30
    g = [['#'] * W for _ in range(H)]
    def room(x1, y1, x2, y2):
        for y in range(y1, y2 + 1):
            for x in range(x1, x2 + 1):
                g[y][x] = '.'
    A, B, C, D = rooms
    room(*A); room(A[2] + 1, 13, B[0] - 1, 16)
    room(*B); room(B[2] + 1, 13, C[0] - 1, 16)
    room(*C); room(C[2] + 1, 13, D[0] - 1, 16)
    room(*D)
    for y in range(13, 17):
        g[y][A[2] + 1] = 'D'; g[y][B[2] + 1] = 'D'; g[y][C[2] + 1] = 'G'
    g[14][A[0] + 4] = 'P'
    g[14][A[0] + 6] = '1'
    for y in range(13, 17):
        g[y][B[0] + 1] = '2'; g[y][C[0] + 1] = '3'; g[y][C[2] + 2] = '4'; g[y][D[0] + 2] = '5'
    def free(r):
        while True:
            x = rnd.randint(r[0] + 2, r[2] - 2); y = rnd.randint(r[1] + 2, r[3] - 2)
            if g[y][x] == '.' and not (12 <= y <= 17 and x < r[0] + 4):
                return x, y
    for _ in range(extra_walls):
        for r in (B, C, D):
            x, y = free(r)
            if 12 <= y <= 17 and r is D:
                continue
            for dx in (0, 1):
                for dy in (0, 1):
                    g[y + dy][x + dx] = '#'
    for _ in range(crawlers):
        x, y = free(B); g[y][x] = 'c'
    for _ in range(2):
        x, y = free(C); g[y][x] = 'c'
    for _ in range(drones):
        x, y = free(C); g[y][x] = 'd'
    g[15][(C[0] + C[2]) // 2] = 'S'
    g[14][(D[0] + D[2]) // 2 + 2] = 'B'
    open(path, 'w').write('\n'.join(''.join(r) for r in g) + '\n')

# Mall: lange, breite Hallen
gen('data/chapter2.txt', 2, [(2, 8, 14, 21), (16, 3, 44, 26), (47, 5, 66, 24), (70, 2, 95, 27)], 8, 5, 2)
# Archiv: viele kleine Saeulen = labyrinthartig
gen('data/chapter3.txt', 3, [(2, 9, 14, 20), (16, 2, 42, 27), (45, 3, 64, 26), (68, 3, 95, 26)], 9, 5, 9)
# Schule: lange Flure mit Klassenzimmern
gen('data/chapter4.txt', 4, [(2, 10, 14, 19), (16, 6, 44, 23), (47, 4, 65, 25), (69, 2, 95, 27)], 9, 6, 3)
print('ok')
