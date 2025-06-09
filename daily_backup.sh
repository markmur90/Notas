#!/bin/bash

# === CONFIGURACIÓN ===
REMOTE_USER="markmur88"
REMOTE_IP="80.78.30.242"
SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"
REMOTE_PROJECT="/home/markmur88/api_bank_heroku"
BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
REMOTE_TMP="/tmp/$BACKUP_NAME"
LOCAL_BACKUP="/home/markmur88/backup/zip/$BACKUP_NAME"

# === GENERAR BACKUP EN EL VPS ===
echo "📦 Generando backup remoto..."
ssh -i "$SSH_KEY" -p 22 "$REMOTE_USER@$REMOTE_IP" "
    pg_dump -U postgres -F c -f /tmp/db.backup &&
    tar -czf '$REMOTE_TMP' /tmp/db.backup '$REMOTE_PROJECT'
"

# === DESCARGAR Y LIMPIAR ===
echo "⬇️ Descargando respaldo y limpiando VPS..."
scp -i "$SSH_KEY" -P 22 "$REMOTE_USER@$REMOTE_IP:$REMOTE_TMP" "$LOCAL_BACKUP"

# Limpiar remoto
ssh -i "$SSH_KEY" -p 22 "$REMOTE_USER@$REMOTE_IP" "
    rm -rf /tmp/db.backup '$REMOTE_PROJECT' '$REMOTE_TMP' &&
    sudo -u postgres psql -c 'DROP DATABASE IF EXISTS nombre_base;' &&
    echo '🧹 Proyecto, backups y base eliminados.'
"
