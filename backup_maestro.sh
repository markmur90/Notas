#!/usr/bin/env bash

# === CONFIG Y UTILIDADES ===
set -euo pipefail
IFS=$'\n\t'

INSTALL_DIR="${HOME}/Notas"
CONFIG_FILE="${INSTALL_DIR}/config.conf"
[[ -f "$CONFIG_FILE" ]] || { echo "❌ No se encontró $CONFIG_FILE"; exit 1; }
set -o allexport; source "$CONFIG_FILE"; set +o allexport

BACKUP_VPS_DIR="${BACKUP_DIR}/vps"
LOG_DIR="${INSTALL_DIR}/logs"
LOG_FILE="${LOG_DIR}/backup_master.log"
mkdir -p "$BACKUP_VPS_DIR" "$LOG_DIR"

# === Función de envío a Telegram con gestión de 413 ===
send_telegram() {
  local MSG="$1"
  local FILE="${2:-}"

  _do_send() {
    local method="$1"   # sendDocument o sendMessage
    shift
    curl -s -w '%{http_code}' -o /dev/null "$@"
  }

  if [[ -n "$FILE" && -f "$FILE" ]]; then
    # Intentamos enviar como documento
    http_code=$(_do_send \
      "sendDocument" -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendDocument" \
      -F chat_id="${CHAT_ID}" \
      -F document=@"${FILE}" \
      -F caption="${MSG}")
    action="Documento"
    name="$(basename "$FILE")"
  else
    http_code=$(_do_send \
      "sendMessage" -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
      -d chat_id="${CHAT_ID}" \
      -d text="${MSG}")
    action="Mensaje"
    name=""
  fi

  if [[ "$http_code" -eq 200 ]]; then
    if [[ -n "$name" ]]; then
      echo "📨 ${action} enviado: ${name}"
    else
      echo "📨 ${action} enviado"
    fi
    return 0
  fi

  if [[ "$http_code" -eq 413 && -n "$FILE" ]]; then
    # Payload Too Large: partida en chunks de 49MB
    echo "⚠️ ${name} demasiado grande, dividiendo en partes..."
    mapfile -t chunks < <(split -b 49M --numeric-suffixes=1 --suffix-length=3 "$FILE" "${FILE}.part_")
    total=${#chunks[@]}

    for i in "${!chunks[@]}"; do
      part="${chunks[i]}"
      seq=$((i+1))
      send_telegram "${MSG} (parte ${seq}/${total})" "$part" || {
        echo "❌ Falló envío de parte ${seq}/${total}: $(basename "$part")"
        exit 1
      }
      rm -f "$part"
    done

    # Todas las partes enviadas
    echo "✅ Todas las partes de ${name} enviadas"
    return 0
  fi

  # Otro error HTTP o sin archivo
  echo "❌ Error enviando a Telegram (${action} ${name}), código HTTP $http_code"
  return 1
}

# === Función de log + notificación local + Telegram ===
log() {
  local MSG="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $MSG" >> "$LOG_FILE"
  notify-send "Backup Maestro" "$MSG"
  send_telegram "$MSG" || { echo "❌ Abortando: no se pudo notificar por Telegram."; exit 1; }
}

log "👉 Inicio de backup maestro."

# === 1) Dump BD ===
TIMESTAMP=$(date +%Y-%m-%d__%H-%M)
DB_OUT="$BACKUP_VPS_DIR/db_backup_${TIMESTAMP}.sql"
PGPASSWORD="$DB_PASSWORD" pg_dump -U "$DB_USER" -h localhost -p 5432 "$DB_NAME" > "$DB_OUT"
log "✅ Dump de BD generado: $(basename "$DB_OUT")"

# === 2) Empaquetado de proyectos ===
backup_project() {
  local CODE="$1" SRC="$2"
  local OUT="${BACKUP_VPS_DIR}/proyecto_backup_${CODE}_${TIMESTAMP}.tar.gz"
  tar -czf "$OUT" -C "$SRC" .
  log "✅ Tar $CODE completado: $(basename "$OUT")"
}

backup_project "H2" "${HOME}/api_bank_h2"
backup_project "HK" "${HOME}/api_bank_heroku"
backup_project "SC" "${HOME}/scripts"
backup_project "SM" "${HOME}/Simulador"
backup_project "NT" "${HOME}/Notas"

# === 3) Selección de 4 tars más recientes ===
mapfile -t RECENT < <(ls -1t "${BACKUP_VPS_DIR}"/proyecto_backup_*.tar.gz 2>/dev/null | head -n 4)
(( ${#RECENT[@]} )) || { log "❌ No hay tars para enviar."; exit 1; }
log "📦 Tars a enviar: ${#RECENT[@]} archivos."

# === 4) Envío con confirmación ===
for TAR in "${RECENT[@]}"; do
  send_telegram "🚀 Enviando backup: $(basename "$TAR")" "$TAR" \
    && log "📤 Enviado tar: $(basename "$TAR")"
done

# === 5) Retención >3 días ===
find "$BACKUP_VPS_DIR" -maxdepth 1 -type f \
  -name 'proyecto_backup_*.tar.gz' -mtime +3 \
  -exec bash -c 'rm -f "$1" && log "🗑️ Tar borrado (>3d): $(basename "$1")"' _ {} \;

log "🧹 Limpieza de tars antiguos completada."
