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

# Lista de todos los logs
LOG_FILES=(
  "$LOG_ALERTAS"
  "$LOG_TOTAL"
  "$LOG_DIA"
  "$LOG_FECHA"
  "$LOG_AUDIO"
  "$LOG_VOZ"
  "$LOG_SESSION_START"
  "$LOG_LAST_TS"
)

# Crear cada archivo si no existe
for file in "${LOG_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    touch "$file"
  fi
done


source ~/notas_env/bin/activate



# === Configuración de voz ===
# Se guarda la elección del usuario en un archivo para
# no preguntar en cada ejecución.
VOICE_FILE="$HOME/Notas/voz_seleccionada"

select_voice() {
    if ! command -v espeak >/dev/null; then
        echo "❌ 'espeak' no está instalado." >&2
        exit 1
    fi

    # Extraer las voces disponibles en formato utilizable por "espeak".
    # El comando "espeak --voices" muestra varias columnas; la ruta del
    # archivo de voz se encuentra en la quinta. Quitamos la ruta y dejamos
    # solo el nombre del archivo (por ejemplo "es", "en", "mb-es1").
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

# Permitir configurar la voz manualmente con --config-voice
if [[ $1 == --config-voice ]]; then
    select_voice
    exit 0
fi

if [ -f "$VOICE_FILE" ]; then
    VOICE="$(cat "$VOICE_FILE")"
else
    # Proponer la primera voz MBROLA disponible
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

# Registrar inicio de sesión si no existe
[ ! -f "$LOG_SESSION_START" ] && date +%s > "$LOG_SESSION_START"
[ ! -f "$LOG_LAST_TS" ] && cat "$LOG_SESSION_START" > "$LOG_LAST_TS"
SESSION_START=$(cat "$LOG_SESSION_START")
LAST_TS=$(cat "$LOG_LAST_TS")
NOW=$(date +%s)
DELTA_MIN=$(( (NOW - LAST_TS) / 60 ))
[ $DELTA_MIN -lt 0 ] && DELTA_MIN=0

# Inicializar logs si no existen
[ ! -f "$LOG_TOTAL" ] && echo "0" > "$LOG_TOTAL"
[ ! -f "$LOG_DIA" ] && echo "0" > "$LOG_DIA"
[ ! -f "$LOG_AUDIO" ] && echo "0" > "$LOG_AUDIO"


# Leer y limpiar contadores
TOTAL=$(cat "$LOG_TOTAL" 2>/dev/null || echo 0)
DIA=$(cat "$LOG_DIA" 2>/dev/null || echo 0)
AUDIO_CONT=$(cat "$LOG_AUDIO" 2>/dev/null || echo 0)
TOTAL=${TOTAL//[^0-9]/}
DIA=${DIA//[^0-9]/}
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

# === Construir mensaje completo ===
MENSAJE="🌎 Bogotá: $HORA_BOGOTA
🕰️ Berlín: $HORA_BERLIN
📦 Hoy: $(format_time $TOTAL)

📌 Pendientes:
$PENDIENTES"

# Notificación local
if [ -n "$DISPLAY" ] && command -v notify-send >/dev/null; then
    notify-send "⏰ Alerta Horaria" "$MENSAJE"
else
    echo "🔕 Entorno gráfico no disponible, omitiendo notificación" >> "$LOG_ALERTAS"
fi

# Rotación simple de alertas
[ "$(wc -l < "$LOG_ALERTAS")" -gt 1000 ] && tail -n 500 "$LOG_ALERTAS" > "$LOG_ALERTAS.tmp" && mv "$LOG_ALERTAS.tmp" "$LOG_ALERTAS"

# Mensaje a reproducir y enviar
# TEXTO="Son las... $HORA_BOGOTA_TEXTO.... MI AMOR!!!,... llevamos trabajando hoy hasta el momento: $(format_time $DIA)."
# === Mensaje de voz ===
TEXTO_BASE="Son las $(TZ="America/Bogota" date +"%H:%M"). Tiempo trabajando $(format_time $TOTAL)."

if [ "$PENDIENTES" != "(sin pendientes)" ] && [ "$((DIA % 30))" -eq 0 ]; then
    TEXTO="$TEXTO_BASE Recuerda revisar tus pendientes: $PENDIENTES."
else
    TEXTO="$TEXTO_BASE ¡Hasta luego!"
fi

if command -v gtts-cli >/dev/null && command -v mpg123 >/dev/null; then
    TMP_MP3="/tmp/voz_$$.mp3"
    TMP_WAV="/tmp/voz_$$.wav"
    if gtts-cli --lang es "$TEXTO" --output "$TMP_MP3" 2>> "$LOG_VOZ"; then
        if command -v ffmpeg >/dev/null && command -v play >/dev/null; then
            ffmpeg -loglevel quiet -i "$TMP_MP3" "$TMP_WAV"
            play "$TMP_WAV" tempo 1.5 2>> "$LOG_VOZ"
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

# Telegram
curl -s -X POST https://api.telegram.org/bot$TG_TOKEN/sendMessage \
    -d chat_id="$TG_CHAT_ID" -d text="$MENSAJE" \
    >> "$LOG_DIR/telegram.log" 2>&1


