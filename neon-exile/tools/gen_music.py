# Erzeugt zwei einfache Synthwave-Loops als WAV (keine fremden Dateien noetig).
# Aufruf: python3 tools/gen_music.py
import math, random, struct, wave

SR = 22050

def note(n):  # MIDI -> Hz
    return 440.0 * 2 ** ((n - 69) / 12)

def saw(p):
    return 2.0 * (p - math.floor(p + 0.5))

def sq(p):
    return 1.0 if (p % 1.0) < 0.5 else -1.0

def render(path, bpm, chords, bars, lead_pat, dark=False):
    beat = 60.0 / bpm
    step = beat / 4  # 16tel
    total = int(SR * step * 16 * bars)
    out = [0.0] * total
    rnd = random.Random(1)
    for bar in range(bars):
        root = chords[bar % len(chords)]
        triad = [root, root + (3 if dark or root % 2 == 0 else 4), root + 7]
        for s in range(16):
            t0 = int(SR * step * (bar * 16 + s))
            # Bass: Achtel, Oktave wechselnd
            if s % 2 == 0:
                f = note(root - 24 + (12 if s % 4 == 2 else 0))
                for i in range(int(SR * step * 1.8)):
                    if t0 + i >= total: break
                    env = math.exp(-i / (SR * 0.18))
                    out[t0 + i] += 0.22 * env * saw(f * i / SR)
            # Arpeggio
            f = note(triad[(s + bar) % 3] + 12 + (12 if s % 8 >= 4 else 0))
            for i in range(int(SR * step)):
                if t0 + i >= total: break
                env = math.exp(-i / (SR * 0.06))
                out[t0 + i] += 0.07 * env * sq(f * i / SR)
            # Lead (nur in manchen Takten)
            if lead_pat[(bar * 16 + s) % len(lead_pat)] and bar % 4 >= 2:
                f = note(triad[s % 3] + 24)
                for i in range(int(SR * step * 2)):
                    if t0 + i >= total: break
                    env = math.exp(-i / (SR * 0.25))
                    vib = 1 + 0.004 * math.sin(i / SR * 30)
                    out[t0 + i] += 0.05 * env * saw(f * vib * i / SR)
            # Kick auf jedem Viertel
            if s % 4 == 0:
                for i in range(int(SR * 0.2)):
                    if t0 + i >= total: break
                    env = math.exp(-i / (SR * 0.05))
                    fk = 50 + 90 * math.exp(-i / (SR * 0.02))
                    out[t0 + i] += 0.45 * env * math.sin(2 * math.pi * fk * i / SR)
            # Snare auf 2 und 4, Hi-Hat auf Achteln
            if s % 8 == 4:
                for i in range(int(SR * 0.15)):
                    if t0 + i >= total: break
                    out[t0 + i] += 0.18 * math.exp(-i / (SR * 0.04)) * (rnd.random() * 2 - 1)
            if s % 2 == 1 or dark:
                for i in range(int(SR * 0.03)):
                    if t0 + i >= total: break
                    out[t0 + i] += 0.05 * math.exp(-i / (SR * 0.008)) * (rnd.random() * 2 - 1)
        # Pad (ganzer Takt, leise)
        t0 = int(SR * step * bar * 16)
        n = int(SR * step * 16)
        for i in range(n):
            if t0 + i >= total: break
            env = min(1, i / (SR * 0.3)) * min(1, (n - i) / (SR * 0.3))
            v = sum(saw(note(x) * i / SR * (1 + d)) for x in triad for d in (-0.003, 0.003))
            out[t0 + i] += 0.012 * env * v
    peak = max(abs(x) for x in out) or 1
    with wave.open(path, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(x / peak * 0.85 * 32767)) for x in out))

pat = [1,0,0,1, 0,0,1,0, 1,0,0,0, 1,0,1,0]
render("assets/music/explore.wav", 100, [57, 53, 48, 55], 8, pat)          # Am F C G
render("assets/music/boss.wav", 138, [52, 52, 48, 50], 8, [1,0,1,0]*4, dark=True)   # Em Em C D

def ambient(path, secs, chords):
    # Langsame, schwebende Akkordflaechen mit Glockentoenen und kuenstlichem Hall
    total = int(SR * secs)
    out = [0.0] * total
    seg = total // len(chords)
    rnd = random.Random(3)
    for ci, ch in enumerate(chords):
        t0 = ci * seg
        for i in range(seg + SR * 2):
            if t0 + i >= total: break
            env = min(1, i / (SR * 2.5)) * min(1, max(0, (seg + SR * 2 - i)) / (SR * 2.5))
            v = 0.0
            for n in ch:
                f = note(n)
                v += math.sin(2 * math.pi * f * i / SR + 0.3 * math.sin(i / SR * 0.7)) * 0.5
                v += math.sin(2 * math.pi * f * 2.003 * i / SR) * 0.12
            out[t0 + i] += 0.05 * env * v
        # Glocken
        for k in range(6):
            tb = t0 + rnd.randint(0, seg - 1)
            f = note(rnd.choice(ch) + 24)
            for i in range(int(SR * 3)):
                if tb + i >= total: break
                out[tb + i] += 0.06 * math.exp(-i / (SR * 0.9)) * math.sin(2 * math.pi * f * i / SR)
    # einfacher Hall (mehrere Echos)
    for d, g in [(0.13, 0.35), (0.29, 0.25), (0.47, 0.18), (0.71, 0.12)]:
        ds = int(SR * d)
        for i in range(total - 1, ds, -1):
            out[i] += out[i - ds] * g
    peak = max(abs(x) for x in out) or 1
    with wave.open(path, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(x / peak * 0.8 * 32767)) for x in out))

def pool(path, secs):
    # Poolrooms-Ambience: tiefes Brummen der Lueftung, Wassertropfen mit langem Hall, ferne Spieluhr
    total = int(SR * secs)
    out = [0.0] * total
    rnd = random.Random(5)
    for i in range(total):
        t = i / SR
        out[i] += 0.05 * math.sin(2 * math.pi * 60 * t) + 0.03 * math.sin(2 * math.pi * 120.4 * t)
        out[i] += 0.02 * (rnd.random() * 2 - 1) * (0.6 + 0.4 * math.sin(t * 0.3))
    for k in range(int(secs * 0.8)):
        tb = rnd.randint(0, total - SR)
        f = rnd.uniform(900, 1600)
        for i in range(int(SR * 0.25)):
            if tb + i >= total: break
            ff = f * (1 + 2.5 * math.exp(-i / (SR * 0.01)))
            out[tb + i] += 0.12 * math.exp(-i / (SR * 0.04)) * math.sin(2 * math.pi * ff * i / SR)
    melody = [72, 76, 79, 76, 74, 71, 72, 67]
    for k, n in enumerate(melody * 2):
        tb = int(SR * (6 + k * 1.6))
        f = note(n)
        for i in range(int(SR * 2.5)):
            if tb + i >= total: break
            out[tb + i] += 0.05 * math.exp(-i / (SR * 0.7)) * (math.sin(2 * math.pi * f * i / SR) + 0.3 * math.sin(2 * math.pi * f * 3 * i / SR))
    for d, g in [(0.11, 0.45), (0.23, 0.35), (0.41, 0.28), (0.67, 0.2), (1.03, 0.14)]:
        ds = int(SR * d)
        for i in range(total - 1, ds, -1):
            out[i] += out[i - ds] * g
    peak = max(abs(x) for x in out) or 1
    with wave.open(path, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(x / peak * 0.8 * 32767)) for x in out))

pool("assets/music/pool.wav", 40)
ambient("assets/music/dream.wav", 48, [[57, 60, 64, 71], [53, 57, 60, 67], [48, 55, 59, 64], [55, 59, 62, 66]])
print("ok")
