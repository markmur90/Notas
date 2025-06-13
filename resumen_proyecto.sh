#!/bin/bash
USER_LOCAL="markmur88"
VOICE_FILE="$HOME/Notas/voz_seleccionada"
VOICE=$( [ -f "$VOICE_FILE" ] && cat "$VOICE_FILE" || echo "es" )
LOG_AUDIO_DIR="$HOME/Notas/logs"
mkdir -p "$LOG_AUDIO_DIR"

NOW_BOGOTA=$(TZ="America/Bogota" date +"%Y-%m-%d %H:%M:%S")

echo "📦 Resumen total del proyecto"
echo "🕒 $NOW_BOGOTA"
echo

echo "📝 Notas acumuladas:"
NOTAS=( $(find "/home/$USER_LOCAL/Notas/texto" -type f -name "nota_texto.txt" | sort) )
for file in "${NOTAS[@]}"; do
    FECHA=$(TZ="America/Bogota" date -r "$file" +"%Y-%m-%d %H:%M:%S")
    echo "🗒 $file ($FECHA)"
    cat "$file"
done
echo

echo "🎤 Audios grabados:"
AUDIOS=( $(find "/home/$USER_LOCAL/Notas/audio" -type f -name "voz_*.wav" | sort) )
for aud in "${AUDIOS[@]}"; do
    echo "$aud"
done
echo

echo "📦 Tareas Pendientes:"
PEND=( $(find "/home/$USER_LOCAL/Notas" -type f -name "pending.txt") )
for file in "${PEND[@]}"; do
    echo "📝 $file"
    cat "$file"
done
echo

echo "📦 Tareas Completas:"
COMP=( $(find "/home/$USER_LOCAL/Notas" -type f -name "complete.txt") )
for file in "${COMP[@]}"; do
    echo "📝 $file"
    cat "$file"
done
echo

MENSAJE="📦 Resumen total ($NOW_BOGOTA)
📝 Notas: ${#NOTAS[@]}
🎤 Audios: ${#AUDIOS[@]}
📌 Pendientes: ${#PEND[@]}
✅ Completas: ${#COMP[@]}"

/home/$USER_LOCAL/Notas/enviar_telegram.sh "$MENSAJE"

TMP_WAV="/tmp/resumen_total_$$.wav"
espeak -v "$VOICE" "$MENSAJE" --stdout > "$TMP_WAV"
aplay "$TMP_WAV"

DEST_WAV="$LOG_AUDIO_DIR/resumen_total_$(date +%Y-%m-%d_%H-%M-%S).wav"
mv "$TMP_WAV" "$DEST_WAV"
echo "$DEST_WAV" >> "$LOG_AUDIO_DIR/resumen_total_audio.log"
