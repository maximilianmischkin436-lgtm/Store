# Schnitzt in jede Karte einen geheimen Raum: H = falsche Wand (begehbar), X = Geheimversteck
import random, sys
def carve(path, seed, prefer_x):
    g=[list(r) for r in open(path).read().strip().split('\n')]
    H,W=len(g),len(g[0])
    if any('H' in r for r in g): return 'schon vorhanden'
    rnd=random.Random(seed); best=None
    for y in range(2,H-2):
        for x in range(2,W-2):
            if g[y][x]!='#': continue
            for dx,dy in [(0,-1),(0,1),(-1,0),(1,0)]:
                if g[y-dy][x-dx]!='.': continue
                # Raum 5x4 hinter der Wand in Richtung (dx,dy)
                rw,rh=(5,4) if dx==0 else (4,5)
                if dx==0:
                    x0=x-2; y0=y+dy if dy>0 else y-rh
                else:
                    y0=y-2; x0=x+dx if dx>0 else x-rw
                ok=True
                for yy in range(y0-1,y0+rh+1):
                    for xx in range(x0-1,x0+rw+1):
                        if not(0<yy<H-1 and 0<xx<W-1) or (g[yy][xx]!='#' and (xx,yy)!=(x,y)): ok=False
                if not ok: continue
                score=-abs(x-prefer_x)+rnd.random()
                if best is None or score>best[0]: best=(score,x,y,x0,y0,rw,rh)
    if not best: return 'kein Platz'
    _,x,y,x0,y0,rw,rh=best
    for yy in range(y0,y0+rh):
        for xx in range(x0,x0+rw): g[yy][xx]='.'
    g[y][x]='H'; g[y0+rh//2][x0+rw//2]='X'
    open(path,'w').write('\n'.join(''.join(r) for r in g)+'\n')
    return f'Geheimraum bei {x},{y}'
for i,px in [(1,30),(2,20),(3,55),(4,30),(5,50),(6,40),(8,45)]:
    print(i, carve(f'data/chapter{i}.txt', i, px))
