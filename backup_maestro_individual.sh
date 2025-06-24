#!/bin/bash

# === CONFIG Y UTILIDADES ===
INSTALL_DIR="${HOME}/Notas"
CONFIG_FILE="${INSTALL_DIR}/config.conf"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ No se encontró $CONFIG_FILE"
  exit 1
fi
set -o allexport; source "$CONFIG_FILE"; set +o allexport

# Variables derivadas
USER_LOCAL="$(basename "$(dirname "$INSTALL_DIR")")"
BACKUP_VPS_DIR="${BACKUP_DIR}/vps"
LOG_DIR="${INSTALL_DIR}/logs"
LOG_FILE="${LOG_DIR}/backup_master.log"
ENVIAR_TG="${INSTALL_DIR}/enviar_telegram.sh"

mkdir -p "$BACKUP_VPS_DIR" "$LOG_DIR"

# Función de log + notificación local + Telegram
log() {
  local MSG="$1"
  # 1) Log en archivo
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $MSG" >> "$LOG_FILE"
  # 2) Notificación de escritorio
  notify-send "Backup Maestro" "$MSG"
  # 3) Envío a Telegram
  "$ENVIAR_TG" "$MSG"
}

# Timestamp
TIMESTAMP=$(date +%Y-%m-%d__%H-%M)

# Mapeo de proyectos: código → ruta local en VPS
declare -A PROJECTS=(
  ["H2"]="${HOME}/api_bank_h2"
  ["HK"]="${HOME}/api_bank_heroku"
  ["SC"]="${HOME}/scripts"
  ["SM"]="${HOME}/Simulador"
)

log "👉 Inicio de backup maestro."

# 1) Dump BD
DB_OUT="$BACKUP_VPS_DIR/db_backup_${TIMESTAMP}.sql"
PGPASSWORD="$DB_PASSWORD" pg_dump -U "$DB_USER" -h localhost -p 5432 "$DB_NAME" > "$DB_OUT"
log "✅ Dump de BD generado: $(basename "$DB_OUT")"

# 2) Función para empaquetar un proyecto
backup_project() {
  local CODE="$1"
  local SRC_DIR="$2"
  local OUT_TAR="$BACKUP_VPS_DIR/proyecto_backup_${CODE}_${TIMESTAMP}.tar.gz"
  tar -czf "$OUT_TAR" -C "$SRC_DIR" .
  log "✅ Tar $CODE completado: $(basename "$OUT_TAR")"
}

# Llamadas manuales (sin usar for)
backup_project "H2" "${HOME}/api_bank_h2"
backup_project "HK" "${HOME}/api_bank_heroku"
backup_project "SC" "${HOME}/scripts"
backup_project "SM" "${HOME}/Simulador"
backup_project "SM" "${HOME}/Notas"

# 3) Seleccionar 4 tar.gz más recientes
mapfile -t RECENT_TARS < <(
  ls -1t "${BACKUP_VPS_DIR}"/proyecto_backup_*.tar.gz 2>/dev/null | head -n 4
)
if [[ ${#RECENT_TARS[@]} -lt 1 ]]; then
  log "❌ No hay tars para enviar."
  exit 1
fi
log "📦 Tars a enviar: ${#RECENT_TARS[@]} archivos."

# 4) Enviar cada tar por Telegram con xargs (sin usar for)
printf '%s\n' "${RECENT_TARS[@]}" \
| xargs -I {} bash -c '
  "$ENVIAR_TG" "🚀 Enviando backup: $(basename "{}")" "{}" && \
  log "📤 Enviado tar: $(basename "{}")"
'

# 5) Retención: borrar tars > 3 días con find -exec (sin usar for)
find "$BACKUP_VPS_DIR" -maxdepth 1 -type f \
  -name 'proyecto_backup_*.tar.gz' -mtime +3 \
  -exec bash -c 'rm -f "$1" && log "🗑️ Tar antiguo borrado (>3d): $(basename "$1")"' _ {} \;

log "🧹 Limpieza de tars antiguos completada."