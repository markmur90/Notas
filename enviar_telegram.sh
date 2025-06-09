#!/bin/bash

ENV_PATH="${HOME}/Notas/config.conf"
if [ ! -f "$ENV_PATH" ]; then
    echo "❌ No se encontró archivo de configuración: $ENV_PATH"
    exit 1
fi

# Cargar variables del .env
# export $(grep -v '^#' "$ENV_PATH" | xargs)
set -o allexport
source "$ENV_PATH"
set +o allexport

# Mensaje recibido como parámetro
MENSAJE="$1"

if [ -z "$TG_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "❌ Faltan TG_TOKEN o CHAT_ID en $ENV_PATH"
    exit 1
fi

# Enviar mensaje
curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
     -d chat_id="$CHAT_ID" \
     -d text="$MENSAJE" > /dev/null

echo "📨 Enviado a Telegram"
