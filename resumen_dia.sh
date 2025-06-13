#!/bin/bash
USER_LOCAL="markmur88"
VOICE_FILE="$HOME/Notas/voz_seleccionada"
VOICE=$( [ -f "$VOICE_FILE" ] && cat "$VOICE_FILE" || echo "es" )
LOG_AUDIO_DIR="$HOME/Notas/logs"
mkdir -p "$LOG_AUDIO_DIR"
echo "📦 Resumen total del proyecto"
echo "🕒 $(TZ="America/Bogota" date +"%Y-%m-%d %H:%M:%S")"
echo
echo "📝 Notas acumuladas:"
NOTAS=( $(find "$HOME/Notas/texto" -type f -name "*.txt" | sort) )
for file in "${NOTAS[@]}"; do
    FECHA=$(TZ="America/Bogota" date -r "$file" +"%Y-%m-%d %H:%M:%S")
    echo "🗒 $file ($FECHA)"
    cat "$file"
done
echo
echo "🎤 Audios acumulados:"
AUDIOS=( $(find "$HOME/Notas/audio" -type f -name "voz_*.wav" | sort) )
for aud in "${AUDIOS[@]}"; do
    echo "$aud"
done

MENSAJE="📦 Resumen total del proyecto ($(TZ=\"America/Bogota\" date +\"%Y-%m-%d %H:%M:%S\"))
📝 Notas: ${#NOTAS[@]}
🎤 Audios: ${#AUDIOS[@]}"

/home/$USER_LOCAL/Notas/enviar_telegram.sh "$MENSAJE"

TMP_WAV="/tmp/resumen_total_$$.wav"
espeak -v "$VOICE" "$MENSAJE" --stdout > "$TMP_WAV"
aplay "$TMP_WAV"

DEST_WAV="$LOG_AUDIO_DIR/resumen_total_$(date +%Y-%m-%d_%H-%M-%S).wav"
mv "$TMP_WAV" "$DEST_WAV"
echo "$DEST_WAV" >> "$LOG_AUDIO_DIR/resumen_total_audio.log"
