# Baut 30s-Ambience-Loops: Raumrauschen + Brummen + die kurzen ElevenLabs-Geraeusche zufaellig verteilt
import random, subprocess
CFG = {
    "subway": (50, 0.03, 600, 0.04),  # theme: (hum Hz, hum vol, noise lowpass, noise vol)
    "pool":   (0,   0.0,  900, 0.05),
    "mall":   (120, 0.02, 600, 0.04),
    "office": (120, 0.05, 400, 0.04),
    "school": (0,   0.0,  700, 0.03),
    "crown":  (55,  0.03, 300, 0.05),
    "hospital": (60, 0.03, 500, 0.03),
    "home":   (50,  0.02, 400, 0.03),
    "meadow": (0,   0.0,  2500, 0.02),
}
import sys
only = sys.argv[1:]
for th, (hz, hv, lp, nv) in CFG.items():
    if only and th not in only: continue
    rnd = random.Random(th)
    srcs = [f"tools/audio_raw/amb_{th}.mp3", f"tools/audio_raw/amb2_{th}.mp3"]
    inputs = ["-f", "lavfi", "-i", f"anoisesrc=color=brown:amplitude={nv}:duration=30", ]
    filt = ["[0]lowpass=f=%d[n]" % lp]
    mix = ["[n]"]
    k = 1
    if hv > 0:
        inputs += ["-f", "lavfi", "-i", f"sine=frequency={hz}:duration=30"]
        filt.append(f"[{k}]volume={hv}[h]"); mix.append("[h]"); k += 1
    for i in range(10):
        inputs += ["-i", srcs[i % 2]]
        d = rnd.randint(0, 27000)
        filt.append(f"[{k}]volume={rnd.uniform(0.25,0.6):.2f},adelay={d}|{d},apad=whole_dur=30[s{i}]")
        mix.append(f"[s{i}]"); k += 1
    filt.append("".join(mix) + f"amix=inputs={len(mix)}:normalize=0,atrim=0:30,afade=t=in:d=1,afade=t=out:st=29:d=1[o]")
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y"] + inputs + ["-filter_complex", ";".join(filt), "-map", "[o]", "-ac", "2", "-c:a", "libvorbis", "-q:a", "4", f"assets/amb/{th}.ogg"], check=True)
    print(th, "ok")
