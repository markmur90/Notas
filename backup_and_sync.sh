#!/bin/bash

# === CONFIGURACIÓN ===
USER_LOCAL="markmur88"
DIR_PROYECTO_H2="/home/$USER_LOCAL/api_bank_h2"
DIR_PROYECTO_HK="/home/$USER_LOCAL/api_bank_heroku"
DIR_PROYECTO_SC="/home/$USER_LOCAL/scripts"
DIR_PROYECTO_SM="/home/$USER_LOCAL/Simulador"
DIR_PROYECTO_NT="/home/$USER_LOCAL/Notas"
DIR_BACKUP="/home/$USER_LOCAL/backup/vps"
DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
DB_HOST="localhost"
DB_PORT="5432"
VPS_USER="markmur88"
VPS_IP="80.78.30.242"
VPS_PORT="22"
SSH_KEY="/home/$USER_LOCAL/.ssh/vps_njalla_nueva"
DIR_REMOTO_HK="/home/$VPS_USER/api_bank_heroku"
DIR_REMOTO_H2="/home/$VPS_USER/api_bank_h2"
DIR_REMOTO_SC="/home/$VPS_USER/scripts"
DIR_REMOTO_SM="/home/$VPS_USER/Simulador"

FECHA=$(date +%Y-%m-%d)
HORA_BOGOTA_TEXTO=$(TZ="America/Bogota" date +"%H:%M")

mkdir -p "$DIR_BACKUP"
pg_dump -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" "$DB_NAME" > "$DIR_BACKUP/db_backup_$FECHA.sql"
tar -czf "$DIR_BACKUP/proyecto_backup_KH_$FECHA.tar.gz" -C "$DIR_PROYECTO_HK" .
tar -czf "$DIR_BACKUP/proyecto_backup_2H_$FECHA.tar.gz" -C "$DIR_PROYECTO_H2" .
tar -czf "$DIR_BACKUP/proyecto_backup_SC_$FECHA.tar.gz" -C "$DIR_PROYECTO_SC" .
tar -czf "$DIR_BACKUP/proyecto_backup_SM_$FECHA.tar.gz" -C "$DIR_PROYECTO_SM" .
tar -czf "$DIR_BACKUP/proyecto_backup_NT_$FECHA.tar.gz" -C "$DIR_PROYECTO_NT" .

# Función para dividir archivos mayores de 49MB
split_file() {
    local file=$1
    local prefix=$2
    local size=49M
    split -b "$size" "$file" "$prefix"
}

# Función para enviar archivos a Telegram
send_to_telegram() {
    local file=$1
    local chat_id=$2
    local token=$3
    curl -s -F document=@"$file" "https://api.telegram.org/bot$token/sendDocument?chat_id=$chat_id"
}

# Configuración de Telegram
TELEGRAM_TOKEN="7881009139:AAH1mokuP0AjmCbd_tN3VJIxVkG7Fq95j5o"
TELEGRAM_CHAT_ID="769077177"

# Procesar y enviar archivos
for file in "$DIR_BACKUP"/*.tar.gz; do
    if [ -f "$file" ]; then
        size=$(stat -c%s "$file")
        if [ "$size" -gt 51200000 ]; then  # 51200000 bytes = 49 MB
            split_file "$file" "$DIR_BACKUP/split_"
            for part in "$DIR_BACKUP/split_"*; do
                send_to_telegram "$part" "$TELEGRAM_CHAT_ID" "$TELEGRAM_TOKEN"
                if [ $? -ne 0 ]; then
                    echo "Error al enviar $part a Telegram"
                    exit 1
                fi
            done
        else
            send_to_telegram "$file" "$TELEGRAM_CHAT_ID" "$TELEGRAM_TOKEN"
            if [ $? -ne 0 ]; then
                echo "Error al enviar $file a Telegram"
                exit 1
            fi
        fi
    fi
done

echo "✅ Respaldo y sincronización completados el $FECHA"

# Tiempo acumulado según Bogotá
DIA=$(TZ="America/Bogota" date +"%Y-%m-%d")
LOG_DIR="/home/$USER_LOCAL/Notas/logs"
PROYECTO_FILE="$LOG_DIR/tiempo_total.log"
DIA_FILE="$LOG_DIR/tiempo_dia.log"
mkdir -p "$LOG_DIR"
touch "$PROYECTO_FILE" "$DIA_FILE"

MINUTOS_HOY=$(awk '{s+=$1} END {print s+0}' "$DIA_FILE")
MINUTOS_TOTAL=$(awk '{s+=$1} END {print s+0}' "$PROYECTO_FILE")

format_time() {
    printf "%02d horas y %02d minutos" "$(( $1 / 60 ))" "$(( $1 % 60 ))"
}

HORAS_HOY=$(format_time "$MINUTOS_HOY")
HORAS_TOTAL=$(format_time "$MINUTOS_TOTAL")

MSG="✅ Respaldo diario listo del VPS.
🗓️ Hoy: $MINUTOS_HOY min ($HORAS_HOY)
📦 Proyecto: $MINUTOS_TOTAL min ($HORAS_TOTAL)"

"/home/$USER_LOCAL/Notas/enviar_telegram.sh" "$MSG"