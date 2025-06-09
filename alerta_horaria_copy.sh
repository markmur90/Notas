#!/bin/bash

# === PATH completo para cron ===
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# === Evitar ejecuciones simultáneas ===
PIDFILE="/tmp/alerta_horaria.pid"
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "Ya se está ejecutando. Abortando."
    exit 1
fi
echo $$ > "$PIDFILE"
trap "rm -f $PIDFILE" EXIT

# === Entorno para audio desde cron ===
export DISPLAY=:0
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# === Rutas de logs ===
LOG_DIR="$HOME/notas/logs"
mkdir -p "$LOG_DIR"
LOG_ALERTAS="$LOG_DIR/alertas_horas.log"
LOG_TOTAL="$LOG_DIR/tiempo_total.log"
LOG_DIA="$LOG_DIR/tiempo_dia.log"
LOG_FECHA="$LOG_DIR/ultima_fecha.log"
LOG_AUDIO="$LOG_DIR/audio_contador.log"
LOG_VOZ="$LOG_DIR/voz.log"

# === Telegram ===
TG_TOKEN="7881009139:AAH1mokuP0AjmCbd_tN3VJIxVkG7Fq95j5o"
TG_CHAT_ID="769077177"

HORA_ACTUAL=$(date +"%Y-%m-%d %H:%M:%S")
DIA_HOY=$(date +"%Y-%m-%d")

# Reinicio diario
if [ ! -f "$LOG_FECHA" ] || [ "$DIA_HOY" != "$(cat "$LOG_FECHA")" ]; then
    echo "0" > "$LOG_DIA"
    echo "$DIA_HOY" > "$LOG_FECHA"
    echo "0" > "$LOG_AUDIO"
fi

# Inicializar logs si no existen
[ ! -f "$LOG_TOTAL" ] && echo "0" > "$LOG_TOTAL"
[ ! -f "$LOG_DIA"   ] && echo "0" > "$LOG_DIA"
[ ! -f "$LOG_AUDIO" ] && echo "0" > "$LOG_AUDIO"

# Leer y limpiar contadores
TOTAL=$(<"$LOG_TOTAL"  2>/dev/null || echo 0)
DIA=$(<"$LOG_DIA"      2>/dev/null || echo 0)
AUDIO_CONT=$(<"$LOG_AUDIO" 2>/dev/null || echo 0)
TOTAL=${TOTAL//[^0-9]/}
DIA=${DIA//[^0-9]/}
AUDIO_CONT=${AUDIO_CONT//[^0-9]/}

# Incrementos
TOTAL=$((TOTAL + 5))
DIA=$((DIA + 5))
AUDIO_CONT=$((AUDIO_CONT + 1))

printf "%d" "$TOTAL" > "$LOG_TOTAL"
printf "%d" "$DIA"   > "$LOG_DIA"
printf "%d" "$AUDIO_CONT" > "$LOG_AUDIO"

# Formateo de horas
format_time() {
    printf "%02d horas y %02d minutos" "$(($1 / 60))" "$(($1 % 60))"
}

MENSAJE="⏰ $HORA_ACTUAL
📊 Hoy: $(format_time "$DIA")
📦 Proyecto: $(format_time "$TOTAL")"

# Notificación local (Zenity o notify-send)
send_notify() {
    local title=$1
    local msg=$2
    if command -v zenity >/dev/null; then
        zenity --notification --text="${title}\n${msg}" &
    elif [ -n "$DISPLAY" ] && command -v notify-send >/dev/null; then
        notify-send "$title" "$msg"
    else
        echo "🔕 Entorno gráfico no disponible, omitiendo notificación" >> "$LOG_ALERTAS"
    fi
}

send_notify "⏰ Alerta Horaria" "$MENSAJE"
echo -e "$MENSAJE\n" >> "$LOG_ALERTAS"

# Rotación simple de alertas
if [ "$(wc -l < "$LOG_ALERTAS")" -gt 1000 ]; then
    tail -n 500 "$LOG_ALERTAS" > "$LOG_ALERTAS.tmp"
    mv "$LOG_ALERTAS.tmp" "$LOG_ALERTAS"
fi

# # Alerta hablada y Telegram cada 15 minutos
# if (( AUDIO_CONT % 3 == 0 )); then
#     TEXTO="Alerta horaria. Tiempo trabajado hoy: $(format_time "$DIA"). Tiempo total del proyecto: $(format_time "$TOTAL")."
#     # Rutas absolutas y comprobación
#     ESPEAK_CMD=$(command -v espeak || echo "/usr/bin/espeak")
#     APLAY_CMD=$(command -v aplay   || echo "/usr/bin/aplay")
#     if [ -x "$ESPEAK_CMD" ] && [ -x "$APLAY_CMD" ]; then
#         "$ESPEAK_CMD" -v es "$TEXTO" --stdout \
#           | "$APLAY_CMD" -D default 2>> "$LOG_VOZ"
#     fi

#     # Envío a Telegram
#     curl -s -X POST https://api.telegram.org/bot"$TG_TOKEN"/sendMessage \
#         -d chat_id="$TG_CHAT_ID" -d text="$TEXTO" \
#         >> "$LOG_DIR/telegram.log" 2>&1
# fi


# Alerta hablada y Telegram en cada ejecución
TEXTO="Son las $HORA_BOGOTA_TEXTO en Bogotá. Pendientes: $PENDIENTES."
# Audio con log de errores
if command -v espeak >/dev/null && command -v aplay >/dev/null; then
    espeak -v es "$TEXTO" --stdout | aplay 2>> "$LOG_VOZ"
fi

# Telegram
curl -s -X POST https://api.telegram.org/bot$TG_TOKEN/sendMessage \
    -d chat_id="$TG_CHAT_ID" -d text="$TEXTO" \
    >> "$LOG_DIR/telegram.log" 2>&1