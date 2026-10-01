#!/bin/sh
# Baut die ZIP fuer itch.io (index.html muss im Root der ZIP liegen)
cd "$(dirname "$0")/.." && mkdir -p dist && rm -f dist/neon-dodge.zip && zip -j dist/neon-dodge.zip index.html
