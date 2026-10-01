#!/bin/bash
# Bearbeitet die Roh-Stimmen (tools/voice_raw) je nach Sprecher und schreibt assets/voice/*.ogg
#  MIRA / ???  : lauter, leiser Raumhall
#  ECHO        : liminal: leer klingender Raum, etwas tiefer, leicht gedaempft
#  Bosse       : deutlich tiefer, grosser hallender Raum, wie aus einem leeren Gebaeude
#  HALCYON     : weich, kaum tiefer, sehr weiter Hall (wie eine Erinnerung)
#  SYSTEM      : Lautsprecher-Klang
cd "$(dirname "$0")/.."
mkdir -p assets/voice
while read key who; do
  in="tools/voice_raw/$key.mp3"; [ -f "$in" ] || continue
  case "$who" in
    "MIRA"|"???")  f="highpass=f=120,aecho=0.8:0.6:45|90:0.25|0.15,loudnorm=I=-12:TP=-1" ;;
    "ECHO")        f="asetrate=44100*0.96,aresample=44100,atempo=1.04,lowpass=f=7000,aecho=0.8:0.75:70|140|260:0.35|0.25|0.15,loudnorm=I=-15:TP=-1" ;;
    "HALCYON")     f="asetrate=44100*0.94,aresample=44100,atempo=1.064,aecho=0.8:0.85:150|300|600|900:0.45|0.35|0.25|0.15,loudnorm=I=-15:TP=-1" ;;
    "TAPE")        f="asetrate=44100*0.97,aresample=44100,atempo=1.03,highpass=f=200,lowpass=f=4500,aecho=0.8:0.6:40:0.2,loudnorm=I=-14:TP=-1" ;;
    "SYSTEM")      f="highpass=f=300,lowpass=f=3400,aecho=0.8:0.5:30:0.2,loudnorm=I=-16:TP=-1" ;;
    *)             f="asetrate=44100*0.82,aresample=44100,atempo=1.22,lowpass=f=5500,aecho=0.8:0.9:120|260|520|1000:0.5|0.4|0.3|0.2,loudnorm=I=-14:TP=-1" ;;
  esac
  ffmpeg -nostdin -loglevel error -y -i "$in" -af "$f,apad=pad_dur=0.6" -c:a libvorbis -q:a 3 "assets/voice/$key.ogg"
done < tools/voice_speakers.txt
