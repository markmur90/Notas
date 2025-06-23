#!/bin/bash

# === CONFIGURACIÓN ===
USER_LOCAL="markmur88"
DIR_PROYECTO="/home/$USER_LOCAL/api_bank_h2"
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
DIR_REMOTO="/home/$VPS_USER/api_bank_heroku"
DIR_REMOTO_H2="/home/$VPS_USER/api_bank_h2"
DIR_REMOTO_SCR="/home/$VPS_USER/scripts"
DIR_REMOTO_SIM="/home/$VPS_USER/Simulador"

FECHA=$(date +%Y-%m-%d__%H)
HORA_BOGOTA_TEXTO=$(TZ="America/Bogota" date +"%H:%M")

mkdir -p "$DIR_BACKUP"
pg_dump -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" "$DB_NAME" > "$DIR_BACKUP/db_backup_$FECHA.sql"
tar -czf "$DIR_BACKUP/proyecto_backup_$FECHA.tar.gz" -C "$DIR_PROYECTO" .

scp -i "$SSH_KEY" -P "$VPS_PORT" "$DIR_BACKUP/db_backup_HK_$FECHA.sql" "$VPS_USER@$VPS_IP:$DIR_REMOTO/"
scp -i "$SSH_KEY" -P "$VPS_PORT" "$DIR_BACKUP/proyecto_backup_HK_$FECHA.tar.gz" "$VPS_USER@$VPS_IP:$DIR_REMOTO/"
scp -i "$SSH_KEY" -P "$VPS_PORT" "$DIR_BACKUP/proyecto_backup_H2_$FECHA.tar.gz" "$VPS_USER@$VPS_IP:$DIR_REMOTO_H2/"
scp -i "$SSH_KEY" -P "$VPS_PORT" "$DIR_BACKUP/proyecto_backup_SC_$FECHA.tar.gz" "$VPS_USER@$VPS_IP:$DIR_REMOTO_SCR/"
scp -i "$SSH_KEY" -P "$VPS_PORT" "$DIR_BACKUP/proyecto_backup_SM_$FECHA.tar.gz" "$VPS_USER@$VPS_IP:$DIR_REMOTO_SIM/"

echo "✅ Respaldo y sincronización completados el $FECHA"

# Tiempo acumulado según Bogotá
DIA=$(TZ="America/Bogota" date +"%Y-%m-%d")
LOG_DIR="/home/$USER_LOCAL/Notas/logs"
PROYECTO_FILE="$LOG_DIR/proyecto_total.log"
DIA_FILE="$LOG_DIR/$DIA.log"
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
