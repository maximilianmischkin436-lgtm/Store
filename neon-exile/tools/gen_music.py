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
print("ok")
