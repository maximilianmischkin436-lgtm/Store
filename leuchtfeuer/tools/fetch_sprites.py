"""Lädt die generierten Sprites, stellt sie vor Magenta frei und schneidet sie zu."""
import glob, os, re, sys, urllib.request, io
from PIL import Image
import numpy as np

MAP = {
 "KkyND9ERYRODFfPqbItn": "tower", "Pr7ZRb7KDSPI4PCnRHQn": "hut", "LUh2ijicIdmjIXBVz3xl": "stone",
 "eGJulJCPNkw8IEpVf5uV": "pump", "zyQhFqdDA26SpAnifKvW": "yard", "bBrqrvzx0ju6g4zalDbz": "farm",
 "9RWfRUT6E83QGUNV3Nto": "lamp", "8QhLUQDREhojXnV8adZZ": "clinic", "DEZKYjGQh0Cr5eZq0G4I": "scout",
 "hiRirJfPBGwlbWS2jYkW": "lab", "lqZsPOW7vPd5NP5CA5v4": "green", "MDs0Ap4bZzIchOv9u5WN": "filter",
 "zL7RHTo0v9phvGO5vZqQ": "brew", "3Xg9c0AjvTsW1np00HNE": "beacon", "ViQ3chEQSs9h5OotR9ev": "water",
 "dUwIi86sU9iAPrsHDjk1": "guard", "Egeo1jvor7c4Zh3opfSx": "bunker", "S87fuceBNnDHmYaPXO9M": "cave",
 "xAUJ17UQCgOh2jAMhvcR": "person", "pFE9XR7EpH2NwtZ6uhe4": "creature",
 "jusDiJmVRnmHYKa1C2Kr": "tex_ground", "DujpCVenNJIW8ByacxY1": "tex_fungus",
 "KM2do382haq8uV6YUsRj": "ruin", "Yuafh8xOhlNC4N68hL70": "rock", "VZnWnf7tOgSZtAX8bl5G": "oil",
}
OUT = os.path.join(os.path.dirname(__file__), "..", "sprites")
txt = ""
for f in glob.glob("/root/.claude/projects/-home-user-Store/*/tool-results/*") + glob.glob("/root/.claude/projects/-home-user-Store/*.jsonl"):
    try: txt += open(f, errors="ignore").read()
    except Exception: pass
urls = {}
for m in re.finditer(r'https://storage\.googleapis\.com/[^"\s\\]*content_generation/([A-Za-z0-9]+)/[A-Za-z0-9]+/content\.png\?[^"\s\\]*', txt):
    urls[m.group(1)] = m.group(0)

def key(im):
    a = np.asarray(im.convert("RGB")).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    # Magenta-Abstand: hohe R und B, niedriges G
    mag = np.minimum(r, b) - g
    alpha = np.clip(1.0 - (mag - 60) / 80.0, 0, 1)
    # Farbsaum entfernen
    spill = np.clip(np.minimum(r, b) - g - 20, 0, None) * (alpha < 1)
    a[..., 0] -= spill * 0.6; a[..., 2] -= spill * 0.6
    rgba = np.dstack([np.clip(a, 0, 255), alpha * 255]).astype(np.uint8)
    im2 = Image.fromarray(rgba, "RGBA")
    bb = im2.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
    return im2.crop(bb) if bb else im2

missing = []
for sid, name in MAP.items():
    dst = os.path.join(OUT, name + ".png")
    if os.path.exists(dst) and "--force" not in sys.argv:
        continue
    if sid not in urls:
        missing.append(name); continue
    data = urllib.request.urlopen(urls[sid], timeout=60).read()
    im = Image.open(io.BytesIO(data))
    if name.startswith("tex_"):
        h = im.height
        im = im.crop(((im.width - h) // 2, 0, (im.width + h) // 2, h)).resize((512, 512), Image.LANCZOS).convert("RGB")
    else:
        im = key(im)
        im.thumbnail((320, 320), Image.LANCZOS)
    im.save(dst)
    print("ok", name, im.size)
print("missing:", missing)
