#!/bin/bash

# Configuración
VOICE_FILE="$HOME/Notas/voz_seleccionada"
VOICE_SETTING="$(cat "$VOICE_FILE" 2>/dev/null)"

# Detección del motor de voz
if [[ "$VOICE_SETTING" == gtts:* ]]; then
    TTS_ENGINE="gtts"
    TTS_LANG="${VOICE_SETTING#gtts:}"
elif [ -n "$VOICE_SETTING" ]; then
    TTS_ENGINE="espeak"
    TTS_VOICE="$VOICE_SETTING"
else
    TTS_ENGINE="espeak"
    TTS_VOICE="es"
fi

# Leer el texto desde el archivo
TEXTO="$(cat "$HOME/Notas/texto_a_leer.txt")"

# Verificación
if [ -z "$TEXTO" ]; then
    echo "⚠️ El archivo de texto está vacío."
    exit 1
fi

# Leer en voz alta el texto
TMP_AUDIO="/tmp/lector_voz_$$"

case "$TTS_ENGINE" in
    gtts)
        gtts-cli --lang "$TTS_LANG" "$TEXTO" --output "${TMP_AUDIO}.mp3"
        if command -v mpg123 >/dev/null; then
            mpg123 -q "${TMP_AUDIO}.mp3"
        elif command -v ffmpeg >/dev/null && command -v play >/dev/null; then
            ffmpeg -loglevel quiet -i "${TMP_AUDIO}.mp3" "${TMP_AUDIO}.wav"
            play "${TMP_AUDIO}.wav" tempo 0.8
            rm -f "${TMP_AUDIO}.wav"
        fi
        rm -f "${TMP_AUDIO}.mp3"
        ;;
    espeak)
        espeak -v "$TTS_VOICE" -s 140 "$TEXTO"
        ;;
esac
