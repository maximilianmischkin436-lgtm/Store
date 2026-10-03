"""Lädt Musik und Soundeffekte und wandelt sie in kompakte MP3s."""
import glob, os, re, subprocess, urllib.request
MAP = {"RkCYZaaIHBS39tlL9cDa": "calm", "Ai9usOk1YmEGzwh7GLvp": "tense", "LPSNdlGYuxKbDSMuru6o": "night",
 "FgpCFk8XAI3W3RIsakVn": "wind", "PoSiLmzU9IRIxL4VC0iB": "bell", "Abm3ITypyyIiOYGNWcgL": "build",
 "rslYuuLQZq4BuETABzWc": "click", "tSCjQmZHush49p3EY1ur": "growl", "NbpFGiEKmbbgHfMG7cHE": "flame",
 "qrFFvuR3d7KRCKstgHCR": "alarm", "UGgtUYNcxuDtsWM8eGJz": "heart", "cF5c85CqoCfh01jZoIyJ": "sting",
 "XE0jDhMsAxsabuPGz8B3": "strike", "NuqFHbmhMKXgEYqzAp3x": "win", "yr289CjQ4bZ7pmfsLvEp": "lose"}
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
txt = ""
for f in glob.glob("/root/.claude/projects/-home-user-Store/*/tool-results/*") + glob.glob("/root/.claude/projects/-home-user-Store/*.jsonl"):
    try: txt += open(f, errors="ignore").read()
    except Exception: pass
urls = {}
for m in re.finditer(r'https://storage\.googleapis\.com/[^"\s\\]*content_generation/([A-Za-z0-9]+)/[A-Za-z0-9]+/content\.(?:mp3|wav)\?[^"\s\\]*', txt):
    urls[m.group(1)] = m.group(0)
for sid, name in MAP.items():
    dst = os.path.join(OUT, name + ".mp3")
    if os.path.exists(dst): continue
    if sid not in urls: print("missing", name); continue
    raw = "/tmp/claude-0/" + name + ".raw"
    open(raw, "wb").write(urllib.request.urlopen(urls[sid], timeout=120).read())
    br = "96k" if name in ("calm", "tense", "night") else "80k"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", raw, "-ac", "2", "-ar", "44100", "-b:a", br, dst], check=True)
    print("ok", name, os.path.getsize(dst) // 1024, "KB")
