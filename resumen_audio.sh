#!/bin/bash
USER_LOCAL="markmur88"
VOICE_FILE="$HOME/Notas/voz_seleccionada"
VOICE=$( [ -f "$VOICE_FILE" ] && cat "$VOICE_FILE" || echo "es" )
echo "🔊 Generando resumen por voz"
ULTIMO_RESUMEN=$(find "$HOME/Notas/texto" -type f -name "*.txt" -exec stat --format="%Y %n" {} \; 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
if [ -n "$ULTIMO_RESUMEN" ]; then
    RESUMEN=$(cat "$ULTIMO_RESUMEN")
    FECHA_RESUMEN=$(TZ="America/Bogota" date -r "$ULTIMO_RESUMEN" +"%Y-%m-%d %H:%M:%S")
else
    RESUMEN="No hay notas recientes."
    FECHA_RESUMEN=$(TZ="America/Bogota" date +"%Y-%m-%d %H:%M:%S")
fi
MENSAJE="📝 Resumen de la nota ($FECHA_RESUMEN):
$RESUMEN"
/home/$USER_LOCAL/Notas/enviar_telegram.sh "$MENSAJE"
TMP_WAV="/tmp/resumen_voz_$$.wav"
espeak -v "$VOICE" "$MENSAJE" --stdout > "$TMP_WAV"
aplay "$TMP_WAV"
LOG_AUDIO_DIR="$HOME/Notas/logs"
mkdir -p "$LOG_AUDIO_DIR"
AUDIO_LOG="$LOG_AUDIO_DIR/resumen_audio.log"
DEST_WAV="$LOG_AUDIO_DIR/resumen_voz_$(date +%Y-%m-%d_%H-%M-%S).wav"
mv "$TMP_WAV" "$DEST_WAV"
echo "$DEST_WAV" >> "$AUDIO_LOG"
