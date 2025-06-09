#!/bin/bash

SERVICE_FILE="/etc/systemd/system/notas_startup.service"
SCRIPT_PATH="/home/markmur88/notas/backup_and_sync.sh"

echo "📦 Creando servicio systemd para ejecución en el arranque..."

sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Subida de respaldo de notas al iniciar sistema
After=network.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
RemainAfterExit=true

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable notas_startup.service

echo "✅ Servicio habilitado. Se ejecutará al iniciar el sistema."
