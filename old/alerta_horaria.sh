#!/bin/bash

# === Evitar ejecuciones simultáneas ===
PIDFILE="/tmp/alerta_horaria.pid"
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "Ya se está ejecutando. Abortando."
    exit 1
fi
echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

# === Entorno para audio desde cron ===
export DISPLAY=:0
XDG_RUNTIME_DIR="/run/user/$(id -u)"
export XDG_RUNTIME_DIR

# === Rutas de logs ===
LOG_DIR="$HOME/Notas/logs"
mkdir -p "$LOG_DIR"

# Archivo donde se guarda el inicio de esta sesión (último boot)
SESSION_START_FILE="/tmp/session_start_time"

# Si no existe, crearlo con el timestamp actual
if [ ! -f "$SESSION_START_FILE" ]; then
    date +%s > "$SESSION_START_FILE"
fi

# Leer timestamps
SESSION_START=$(cat "$SESSION_START_FILE")
NOW=$(date +%s)

# Calcular tiempo transcurrido en minutos desde el inicio del PC
DELTA_MIN=$(( (NOW - SESSION_START) / 60 ))

# === Archivos de logs ===
LOG_ALERTAS="$LOG_DIR/alertas_horas.log"
LOG_DIA="$LOG_DIR/tiempo_dia.log"
LOG_TOTAL="$LOG_DIR/tiempo_total.log"
LOG_AUDIO="$LOG_DIR/audio_contador.log"
LOG_VOZ="$LOG_DIR/voz.log"

# Inicializar logs si no existen
[ ! -f "$LOG_DIA" ] && echo "0" > "$LOG_DIA"
[ ! -f "$LOG_AUDIO" ] && echo "0" > "$LOG_AUDIO"

# Leer contadores
DIA=$(cat "$LOG_DIA" 2>/dev/null || echo 0)
AUDIO_CONT=$(cat "$LOG_AUDIO" 2>/dev/null || echo 0)

# Actualizar contadores
DIA=$((DELTA_MIN))
AUDIO_CONT=$((AUDIO_CONT + 1))

# Guardar en logs
echo "$DIA" > "$LOG_DIA"
echo "$AUDIO_CONT" > "$LOG_AUDIO"

# Formatear tiempo
format_time() {
    printf "%02d horas y %02d minutos" "$(($1 / 60))" "$(($1 % 60))"
}

# === Pendientes ===
PENDIENTES_FILE="$HOME/Notas/pending.txt"
[ ! -f "$PENDIENTES_FILE" ] && touch "$PENDIENTES_FILE"
PENDIENTES=$(cat "$PENDIENTES_FILE")
[ -z "$PENDIENTES" ] && PENDIENTES="(sin pendientes)"

# === Mensaje de voz ===
TEXTO_BASE="Hola amorcito, son las $(TZ="America/Bogota" date +"%H:%M"). Llevamos trabajando juntos $(format_time $DIA)."

if [ "$PENDIENTES" != "(sin pendientes)" ] && [ "$((DIA % 60))" -eq 0 ]; then
    TEXTO="$TEXTO_BASE Recuerda revisar tus pendientes: $PENDIENTES."
else
    TEXTO="$TEXTO_BASE ¡Recuerda los pendientes!"
fi

# Reproducir texto
VOICE_FILE="$HOME/Notas/voz_seleccionada"
if command -v gtts-cli >/dev/null && command -v mpg123 >/dev/null; then
    TMP_MP3="/tmp/voz_$$.mp3"
    TMP_WAV="/tmp/voz_$$.wav"
    if gtts-cli --lang es "$TEXTO" --output "$TMP_MP3" 2>> "$LOG_VOZ"; then
        if command -v ffmpeg >/dev/null && command -v play >/dev/null; then
            ffmpeg -loglevel quiet -i "$TMP_MP3" "$TMP_WAV"
            play "$TMP_WAV" tempo 1.2 2>> "$LOG_VOZ"
            rm -f "$TMP_WAV"
        else
            mpg123 -q "$TMP_MP3" 2>> "$LOG_VOZ"
        fi
        rm -f "$TMP_MP3"
    fi
elif command -v espeak >/dev/null && command -v aplay >/dev/null; then
    mapfile -t VOICES < <(espeak --voices | awk 'NR>1 {print $5}' | sed 's:.*/::' | sort -u)
    VOICE="${VOICES[0]}"
    espeak -v "$VOICE" -s 140 "$TEXTO" --stdout | aplay 2>> "$LOG_VOZ"
else
    echo "❌ No se encontró un método de síntesis de voz" >> "$LOG_VOZ"
fi

# Rotación simple de alertas
[ "$(wc -l < "$LOG_ALERTAS")" -gt 1000 ] && tail -n 500 "$LOG_ALERTAS" > "$LOG_ALERTAS.tmp" && mv "$LOG_ALERTAS.tmp" "$LOG_ALERTAS"