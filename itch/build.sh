#!/bin/sh
# Baut die ZIP fuer itch.io. Alle Dev-Funktionen (BOSS TEST) werden dabei entfernt.
cd "$(dirname "$0")/.." && mkdir -p dist/build && rm -f dist/neon-dodge.zip
python3 - <<'PY'
import re
s = open("index.html").read()
s = re.sub(r"//DEV_START.*?//DEV_END\n", "", s, flags=re.S)
s = "\n".join(l for l in s.split("\n") if "//DEV" not in l)
open("dist/build/index.html", "w").write(s)
PY
zip -j dist/neon-dodge.zip dist/build/index.html
