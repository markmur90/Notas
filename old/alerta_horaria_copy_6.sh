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
LOG_ALERTAS="$LOG_DIR/alertas_horas.log"
LOG_TOTAL="$LOG_DIR/tiempo_total.log"
LOG_DIA="$LOG_DIR/tiempo_dia.log"
LOG_FECHA="$LOG_DIR/ultima_fecha.log"
LOG_AUDIO="$LOG_DIR/audio_contador.log"
LOG_VOZ="$LOG_DIR/voz.log"
LOG_SESSION_START="$LOG_DIR/session_start_ts.log"
LOG_LAST_TS="$LOG_DIR/ultima_alerta_ts.log"

source ~/notas_env/bin/activate

# === Configuración de voz ===
VOICE_FILE="$HOME/Notas/voz_seleccionada"
select_voice() {
    if ! command -v espeak >/dev/null; then
        echo "❌ 'espeak' no está instalado." >&2
        exit 1
    fi
    mapfile -t VOICES < <(
        espeak --voices | awk 'NR>1 {print $5}' | sed 's:.*/::' | sort -u
    )
    while true; do
        echo "Selecciona la voz para las alertas:"
        PS3="Número de opción: "
        select V in "${VOICES[@]}"; do
            if [ -n "$V" ]; then
                espeak -v "$V" "Esta es la voz $V"
                read -rp "¿Usar esta voz? [s/n]: " RESP
                if [[ $RESP =~ ^[sS]$ ]]; then
                    VOICE="$V"
                    echo "$VOICE" > "$VOICE_FILE"
                    return
                else
                    break
                fi
            else
                echo "Opción inválida"
            fi
        done
    done
}
if [[ $1 == --config-voice ]]; then
    select_voice
    exit 0
fi
if [ -f "$VOICE_FILE" ]; then
    VOICE="$(cat "$VOICE_FILE")"
else
    for MB in es1 es2 es3 es4; do
        if [ -d "/usr/share/mbrola/$MB" ]; then
            VOICE="mb-$MB"
            echo "$VOICE" > "$VOICE_FILE"
            break
        fi
    done
    [ -z "$VOICE" ] && select_voice
fi

# === Telegram ===
TG_TOKEN="7881009139:AAH1mokuP0AjmCbd_tN3VJIxVkG7Fq95j5o"
TG_CHAT_ID="769077177"
HORA_BOGOTA=$(TZ="America/Bogota" date +"%Y-%m-%d %H:%M:%S")
HORA_BOGOTA_TEXTO=$(TZ="America/Bogota" date +"%H:%M")
HORA_BERLIN=$(date +"%Y-%m-%d %H:%M:%S")

# Registrar inicio de sesión si no existe o está vacío
if [ ! -s "$LOG_SESSION_START" ]; then
    date +%s > "$LOG_SESSION_START"
fi

SESSION_START=$(cat "$LOG_SESSION_START")
LAST_TS=$(cat "$LOG_LAST_TS" 2>/dev/null || echo "$SESSION_START")
NOW=$(date +%s)

# Calcular delta desde la última alerta o desde inicio si > 1h
DELTA_MIN=$(( (NOW - LAST_TS) / 60 ))
if [ "$DELTA_MIN" -gt 60 ]; then
    DELTA_MIN=$(( (NOW - SESSION_START) / 60 ))
    DESDE="desde el inicio"
else
    DESDE="desde tu última notificación"
fi

[ $DELTA_MIN -lt 0 ] && DELTA_MIN=0

# Inicializar logs si no existen
[ ! -f "$LOG_TOTAL" ] && echo "0" > "$LOG_TOTAL"
[ ! -f "$LOG_DIA" ] && echo "0" > "$LOG_DIA"
[ ! -f "$LOG_AUDIO" ] && echo "0" > "$LOG_AUDIO"

# Leer y limpiar contadores
TOTAL=$(cat "$LOG_TOTAL" 2>/dev/null || echo 0)
AUDIO_CONT=$(cat "$LOG_AUDIO" 2>/dev/null || echo 0)
TOTAL=${TOTAL//[^0-9]/}
AUDIO_CONT=${AUDIO_CONT//[^0-9]/}

# Actualizar contadores
TOTAL=$((TOTAL + DELTA_MIN))
DIA=$(( (NOW - SESSION_START) / 60 ))
AUDIO_CONT=$((AUDIO_CONT + 1))

echo "$TOTAL" > "$LOG_TOTAL"
echo "$DIA" > "$LOG_DIA"
echo "$AUDIO_CONT" > "$LOG_AUDIO"
echo "$NOW" > "$LOG_LAST_TS"

# Formateo de horas
format_time() {
    printf "%02d horas y %02d minutos" "$(($1 / 60))" "$(($1 % 60))"
}



# === Leer pendientes ===
PENDIENTES_FILE="$HOME/Notas/pending.txt"
[ ! -f "$PENDIENTES_FILE" ] && touch "$PENDIENTES_FILE"
PENDIENTES=$(cat "$PENDIENTES_FILE")
[ -z "$PENDIENTES" ] && PENDIENTES="(sin pendientes)"

# Calcular delta desde la última alerta o desde inicio si > 1h
DELTA_MIN=$(( (NOW - LAST_TS) / 60 ))
if [ "$DELTA_MIN" -ge 60 ]; then
    DESDE="desde el inicio"
else
    DESDE="desde tu última notificación"
fi

# === Mensaje de audio ===
TEXTO_BASE="Hola bebe, son las $HORA_BOGOTA_TEXTO. Hoy llevamos trabajando $(format_time $DIA)."

# Si hay pendientes y ha pasado al menos 1 hora, incluirlos
if [ "$PENDIENTES" != "(sin pendientes)" ] && [ "$DELTA_MIN" -ge 60 ]; then
    TEXTO="$TEXTO_BASE Recuerda revisar tus pendientes: $PENDIENTES. ¡Sigue así, tú puedes!"
else
    TEXTO="$TEXTO_BASE ¡Estás haciendo un trabajo increíble! 💖"
fi

# Reproducir texto
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
    espeak -v "$VOICE" -s 140 "$TEXTO" --stdout | aplay 2>> "$LOG_VOZ"
else
    echo "❌ No se encontró un método de síntesis de voz" >> "$LOG_VOZ"
fi