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

# === Función de envío a Telegram con gestión de 413 (versión parcheada) ===
send_telegram() {
  local MSG="$1"
  local FILE="${2:-}"

  # helper que devuelve sólo el código HTTP
  _do_send() {
    curl -s -w '%{http_code}' -o /dev/null "$@"
  }

  if [[ -n "$FILE" && -f "$FILE" ]]; then
    http_code=$(_do_send \
      -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendDocument" \
      -F chat_id="${CHAT_ID}" \
      -F document=@"${FILE}" \
      -F caption="${MSG}")
    action="Documento"
    name="$(basename "$FILE")"
  else
    http_code=$(_do_send \
      -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
      -d chat_id="${CHAT_ID}" \
      -d text="${MSG}")
    action="Mensaje"
    name=""
  fi

  if [[ "$http_code" -eq 200 ]]; then
    [[ -n "$name" ]] && echo "📨 ${action} enviado: ${name}" || echo "📨 ${action} enviado"
    return 0
  fi

  if [[ "$http_code" -eq 413 && -n "$FILE" ]]; then
    echo "⚠️ ${name} demasiado grande (413), partiendo en trozos de 49MB..."
    split -b 49M --numeric-suffixes=1 --suffix-length=3 "$FILE" "${FILE}.part_"
    parts=( "${FILE}.part_"* )
    total=${#parts[@]}

    for i in "${!parts[@]}"; do
      chunk="${parts[i]}"
      seq=$((i+1))
      echo "➡️ Enviando parte ${seq}/${total}: $(basename "$chunk")"
      code=$(_do_send \
        -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendDocument" \
        -F chat_id="${CHAT_ID}" \
        -F document=@"${chunk}" \
        -F caption="${MSG} (parte ${seq}/${total})")
      if [[ "$code" -ne 200 ]]; then
        echo "❌ Falló envío parte ${seq}/${total} (HTTP $code)"
        exit 1
      fi
      echo "✅ Parte ${seq}/${total} enviada"
      rm -f "$chunk"
    done

    echo "✅ Todas las partes de ${name} enviadas"
    return 0
  fi

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
