#!/bin/bash

# === CONFIGURACIÓN VPS ===
VPS_USER="markmur88"
VPS_IP="80.78.30.242"
VPS_PORT="22"
SSH_KEY="${HOME}/.ssh/vps_njalla_nueva"
REMOTE_DIR="/home/${VPS_USER}/backup/vps"

# === CONFIG LOCAL ===
LOCAL_DIR="${HOME}/descargas/backups"
mkdir -p "$LOCAL_DIR"

# Ruta al script de Telegram
ENVIAR_TG="${HOME}/Notas/enviar_telegram.sh"

# Timestamp para nombres
TIMESTAMP=$(date +%Y-%m-%d__%H-%M)

# 1) Obtener rutas de los 4 backups más recientes en remoto
readarray -t REMOTE_FILES < <(
  ssh -i "$SSH_KEY" -p "$VPS_PORT" "${VPS_USER}@${VPS_IP}" \
      "ls -1t ${REMOTE_DIR}/proyecto_backup_*.tar.gz | head -n 4"
)

if [[ ${#REMOTE_FILES[@]} -eq 0 ]]; then
  "$ENVIAR_TG" "❌ No se encontraron archivos de backup en ${REMOTE_DIR}"
  exit 1
fi

# 2) Descargarlos a LOCAL_DIR
declare -a LOCAL_PATHS=()
for remote_path in "${REMOTE_FILES[@]}"; do
  filename=$(basename "$remote_path")
  scp -i "$SSH_KEY" -P "$VPS_PORT" \
      "${VPS_USER}@${VPS_IP}:${remote_path}" \
      "${LOCAL_DIR}/${filename}"
  LOCAL_PATHS+=( "${LOCAL_DIR}/${filename}" )
done

# 3) Crear ZIP combinado
ZIP_FILE="${LOCAL_DIR}/combined_backup_${TIMESTAMP}.zip"
zip -j "$ZIP_FILE" "${LOCAL_PATHS[@]}"

# 4) Enviar ZIP por Telegram
"$ENVIAR_TG" "✅ Backup combinado: ${TIMESTAMP}" "$ZIP_FILE"

# 5) Programar eliminación local a los 40 minutos
(
  sleep 2400
  if rm -f "$ZIP_FILE"; then
    "$ENVIAR_TG" "✅ Eliminado archivo local: $(basename "$ZIP_FILE")"
  fi
) &

echo "✅ Script completado: descargados ${#LOCAL_PATHS[@]} archivos, enviado y programado eliminación."
