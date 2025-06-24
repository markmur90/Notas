#!/bin/bash

# ================= Problema =================
# Tenemos en local cuatro archivos de respaldo diario
# (proyecto_backup_*.tar.gz) en ~/backup/vps. 
# Queremos:
# 1) Agrupar los 4 más recientes en un solo ZIP.
# 2) Enviarlo via Telegram usando enviar_telegram.sh.
# 3) Tras 40 min, eliminar ese ZIP local y notificar la eliminación.
# Los archivos originales en VPS siguen intactos.

# ================ Implementación ================
USER_LOCAL="markmur88"
DIR_BACKUP="/home/${USER_LOCAL}/backup/vps"
LOCAL_TMP_DIR="/home/markmur88/backup"
ENVIAR_TG="/home/markmur88/Notas/enviar_telegram.sh"

# Crear carpeta temporal si no existe
mkdir -p "$LOCAL_TMP_DIR"

# Timestamp para el ZIP
TIMESTAMP=$(date +%Y-%m-%d)

# 1) Seleccionar los 4 tar.gz más recientes de DIR_BACKUP
readarray -t RECENT_FILES < <(
  ls -1t "${DIR_BACKUP}/proyecto_backup_"*.tar.gz 2>/dev/null | head -n 4
)

if [[ ${#RECENT_FILES[@]} -lt 1 ]]; then
  "$ENVIAR_TG" "❌ No se encontraron archivos proyecto_backup_*.tar.gz en ${DIR_BACKUP}"
  exit 1
fi

# 2) Copiarlos a LOCAL_TMP_DIR
TMP_PATHS=()
for f in "${RECENT_FILES[@]}"; do
  cp "$f" "$LOCAL_TMP_DIR/"
  TMP_PATHS+=( "${LOCAL_TMP_DIR}/$(basename "$f")" )
done

# 3) Empaquetar en un solo ZIP
ZIP_FILE="${LOCAL_TMP_DIR}/combined_backup_${TIMESTAMP}.zip"
zip -j "$ZIP_FILE" "${TMP_PATHS[@]}"

# 4) Enviar ZIP por Telegram
"$ENVIAR_TG" "✅ Backup combinado: ${TIMESTAMP}" "$ZIP_FILE"

# 5) Programar eliminación local a los 40 minutos
(
  sleep 7200
  if rm -f "$ZIP_FILE"; then
    "$ENVIAR_TG" "✅ Eliminado local: $(basename "$ZIP_FILE")"
  fi
) &

echo "✅ Completado: empaquetados ${#TMP_PATHS[@]} archivos, enviado y programada eliminación."
