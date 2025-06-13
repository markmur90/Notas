#!/bin/bash
PIDFILE="/tmp/alerta_horaria.pid"
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    exit 1
fi
echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

export DISPLAY=:0
XDG_RUNTIME_DIR="/run/user/$(id -u)"
export XDG_RUNTIME_DIR

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
for file in "$LOG_ALERTAS" "$LOG_TOTAL" "$LOG_DIA" "$LOG_FECHA" "$LOG_AUDIO" "$LOG_VOZ" "$LOG_SESSION_START" "$LOG_LAST_TS"; do
  [ ! -f "$file" ] && echo "" > "$file"
done

source ~/notas_env/bin/activate
VOICE_FILE="$HOME/Notas/voz_seleccionada"
VOICE_SETTING="$(cat "$VOICE_FILE" 2>/dev/null)"

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

TG_TOKEN="7881009139:AAH1mokuP0AjmCbd_tN3VJIxVkG7Fq95j5o"
TG_CHAT_ID="769077177"

# Fechas y reinicio diario según Bogotá (sin segundos)
CURRENT_DATE_BOGOTA=$(TZ="America/Bogota" date +"%Y-%m-%d")
LAST_DATE=$(cat "$LOG_FECHA" 2>/dev/null || echo "")
NOW=$(date +%s)
if [ "$CURRENT_DATE_BOGOTA" != "$LAST_DATE" ]; then
    echo "$CURRENT_DATE_BOGOTA" > "$LOG_FECHA"
    echo "0" > "$LOG_DIA"
    echo "$NOW" > "$LOG_SESSION_START"
    echo "$NOW" > "$LOG_LAST_TS"
fi

SESSION_START=$(cat "$LOG_SESSION_START")
LAST_TS=$(cat "$LOG_LAST_TS")
DELTA_MIN=$(( (NOW - LAST_TS) / 60 ))
[ $DELTA_MIN -lt 0 ] && DELTA_MIN=0

[ ! -f "$LOG_TOTAL" ] && echo "0" > "$LOG_TOTAL"
[ ! -f "$LOG_DIA" ] && echo "0" > "$LOG_DIA"
[ ! -f "$LOG_AUDIO" ] && echo "0" > "$LOG_AUDIO"

TOTAL=$(cat "$LOG_TOTAL")
DIA=$(cat "$LOG_DIA")
AUDIO_CONT=$(cat "$LOG_AUDIO")

TOTAL=$((TOTAL + DELTA_MIN))
DIA=$((DIA + DELTA_MIN))
AUDIO_CONT=$((AUDIO_CONT + 1))

echo "$TOTAL" > "$LOG_TOTAL"
echo "$DIA" > "$LOG_DIA"
echo "$AUDIO_CONT" > "$LOG_AUDIO"
echo "$NOW" > "$LOG_LAST_TS"

format_time(){ printf "%02d horas y %02d minutos" "$(( $1/60 ))" "$(( $1%60 ))"; }

PEND_FILE="$HOME/Notas/pending.txt"
[ ! -f "$PEND_FILE" ] && touch "$PEND_FILE"
PENDIENTES=$(<"$PEND_FILE")
[ -z "$PENDIENTES" ] && PENDIENTES="(sin pendientes)"

# Sin segundos en la hora
HORA_BOGOTA=$(TZ="America/Bogota" date +"%Y-%m-%d %H:%M")
HORA_BERLIN=$(date +"%Y-%m-%d %H:%M")

MENSAJE="Hora actual: $HORA_BOGOTA
Hora Berlín: $HORA_BERLIN
Transcurrido Hoy: $(format_time $DIA)
Transcurrido Total: $(format_time $TOTAL)

Lista de Pendientes:
$PENDIENTES"

if [ -n "$DISPLAY" ] && command -v notify-send >/dev/null; then
    notify-send "⏰ Alerta Horaria" "$MENSAJE"
else
    echo "🔕 Entorno gráfico no disponible" >> "$LOG_ALERTAS"
fi

TEXTO_BASE="Son las $(TZ="America/Bogota" date +"%H:%M"). Tiempo $(format_time $DIA)."

if [ "$PENDIENTES" != "(sin pendientes)" ] && [ "$((DIA % 30))" -eq 0 ]; then
    TEXTO="$TEXTO_BASE Recuerda revisar tus pendientes: $PENDIENTES."
else
    TEXTO="$TEXTO_BASE ¡Hasta luego!"
fi

TMP_AUDIO="/tmp/alerta_voz_$$"
case "$TTS_ENGINE" in
    gtts)
        gtts-cli --lang "$TTS_LANG" "$TEXTO" --output "${TMP_AUDIO}.mp3" 2>>"$LOG_VOZ"
        if command -v mpg123 >/dev/null; then
            mpg123 -q "${TMP_AUDIO}.mp3"
        elif command -v ffmpeg >/dev/null && command -v play >/dev/null; then
            ffmpeg -loglevel quiet -i "${TMP_AUDIO}.mp3" "${TMP_AUDIO}.wav"
            play "${TMP_AUDIO}.wav" tempo 1.5
            rm -f "${TMP_AUDIO}.wav"
        fi
        rm -f "${TMP_AUDIO}.mp3"
        ;;
    espeak)
        espeak -v "$TTS_VOICE" -s 200 "$TEXTO" --stdout > "${TMP_AUDIO}.wav" 2>>"$LOG_VOZ"
        aplay "${TMP_AUDIO}.wav"
        rm -f "${TMP_AUDIO}.wav"
        ;;
esac

ARCH_WAV="$LOG_DIR/alerta_voz_$(date +%Y-%m-%d_%H-%M).wav"
mv "/tmp/alerta_voz_$$."* "$ARCH_WAV" 2>/dev/null
[ -f "$ARCH_WAV" ] && echo "$ARCH_WAV" >> "$LOG_VOZ"

curl -s -X POST https://api.telegram.org/bot$TG_TOKEN/sendMessage \
     -d chat_id="$TG_CHAT_ID" -d text="$MENSAJE" \
     >> "$LOG_DIR/telegram.log" 2>&1
