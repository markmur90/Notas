#!/bin/bash
FECHA=$(date '+%Y-%m-%d')
HORA=$(date '+%H-%M-%S')
DIR="$HOME/notas/audio/$FECHA"
mkdir -p "$DIR"
FILENAME="voz_$HORA.wav"

if arecord -l | grep -q 'card'; then
    echo "🎙 Grabando 60s... (Ctrl+C para cortar antes)"
    arecord -d 60 -f cd -t wav "$DIR/$FILENAME"
    echo "✅ Audio guardado en $DIR/$FILENAME"
else
    echo "❌ No se detecta dispositivo de audio. Aborta grabación." >> $HOME/notas/logs/audio.log
fi