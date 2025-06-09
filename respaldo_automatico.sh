#!/bin/bash

# Configuración
VPS="markmur88@80.78.30.242"
SSH_KEY="$HOME/.ssh/vps_njalla_nueva"
REMOTE_DIR="/home/markmur88/backup"
LOCAL_BACKUP="/home/markmur88/notas/logs/respaldo_tmp"
mkdir -p "$LOCAL_BACKUP"

# Fecha
DATE=$(date +"%Y-%m-%d_%H-%M")

# Archivos
ARCHIVO_DB="db_backup_$DATE.sql.gz"
ARCHIVO_PROY="proyecto_backup_$DATE.tar.gz"

# Respaldar en VPS
ssh -i "$SSH_KEY" "$VPS" "pg_dump -U postgres api_bank > /tmp/db_backup.sql && gzip /tmp/db_backup.sql && mv /tmp/db_backup.sql.gz $REMOTE_DIR/$ARCHIVO_DB"
ssh -i "$SSH_KEY" "$VPS" "tar -czf $REMOTE_DIR/$ARCHIVO_PROY /home/markmur88/api_bank_heroku"

# Traer respaldo
scp -i "$SSH_KEY" "$VPS:$REMOTE_DIR/$ARCHIVO_DB" "$LOCAL_BACKUP/"
scp -i "$SSH_KEY" "$VPS:$REMOTE_DIR/$ARCHIVO_PROY" "$LOCAL_BACKUP/"

# Limpiar VPS
ssh -i "$SSH_KEY" "$VPS" "rm -rf /home/markmur88/api_bank_heroku /var/lib/postgresql/*"

# Tiempo acumulado
DIA=$(date +"%Y-%m-%d")
PROYECTO_FILE="/home/markmur88/notas/logs/tiempos/proyecto_total.log"
DIA_FILE="/home/markmur88/notas/logs/tiempos/$DIA.log"
MINUTOS_HOY=$(awk '{s+=$1} END {print s}' "$DIA_FILE")
HORAS_HOY=$((MINUTOS_HOY / 60))
MINUTOS_TOTAL=$(awk '{s+=$1} END {print s}' "$PROYECTO_FILE")
HORAS_TOTAL=$((MINUTOS_TOTAL / 60))

# Telegram
MSG="✅ Respaldo diario listo y datos eliminados del VPS.\n🗓️ Hoy: $MINUTOS_HOY min ($HORAS_HOY hs)\n📦 Proyecto: $MINUTOS_TOTAL min ($HORAS_TOTAL hs)"
"/home/markmur88/notas/enviar_telegram.sh" "$MSG"
