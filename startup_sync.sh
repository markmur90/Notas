#!/bin/bash

# === CONFIGURACIÓN ===
LOCAL_BACKUP="/home/markmur88/backup/zip/ultima_reserva.tar.gz"
REMOTE_USER="markmur88"
REMOTE_IP="80.78.30.242"
REMOTE_DIR="/home/markmur88/backup/zip/respaldo_inicial"
SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"

echo "🔁 Sincronizando datos al servidor si hay respaldo local..."

if [ -f "$LOCAL_BACKUP" ]; then
    scp -i "$SSH_KEY" -P 22 "$LOCAL_BACKUP" "$REMOTE_USER@$REMOTE_IP:$REMOTE_DIR/"
    echo "✅ Respaldo enviado."
else
    echo "⚠️ No se encontró $LOCAL_BACKUP. No se subió nada."
fi
