#!/bin/bash

# === CONFIGURACIÓN ===
USER_LOCAL="markmur88"
DIR_PROYECTO="/home/$USER_LOCAL/api_bank_h2"
DIR_BACKUP="/home/$USER_LOCAL/backup/zip"
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

# === CREAR RESPALDO ===
FECHA=$(date +%Y-%m-%d_%H-%M-%S)
mkdir -p "$DIR_BACKUP"
pg_dump -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" "$DB_NAME" > "$DIR_BACKUP/db_backup_$FECHA.sql"
tar -czf "$DIR_BACKUP/proyecto_backup_$FECHA.tar.gz" -C "$DIR_PROYECTO" .

# === SINCRONIZAR CON VPS ===
scp -i "$SSH_KEY" -P "$VPS_PORT" "$DIR_BACKUP/db_backup_$FECHA.sql" "$VPS_USER@$VPS_IP:$DIR_REMOTO/"
scp -i "$SSH_KEY" -P "$VPS_PORT" "$DIR_BACKUP/proyecto_backup_$FECHA.tar.gz" "$VPS_USER@$VPS_IP:$DIR_REMOTO/"

# === ELIMINAR DATOS LOCALES ===
# rm -rf "$DIR_PROYECTO"/*
# rm -f "$DIR_BACKUP/db_backup_$FECHA.sql" "$DIR_BACKUP/proyecto_backup_$FECHA.tar.gz"

echo "✅ Respaldo y sincronización completados el $FECHA"
