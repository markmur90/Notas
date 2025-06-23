#!/bin/bash

ENV_PATH="${HOME}/Notas/config.conf"
if [[ ! -f "$ENV_PATH" ]]; then
    echo "❌ No se encontró archivo de configuración: $ENV_PATH"
    exit 1
fi

# Cargar variables TG_TOKEN y CHAT_ID
set -o allexport
source "$ENV_PATH"
set +o allexport

if [[ -z "$TG_TOKEN" || -z "$CHAT_ID" ]]; then
    echo "❌ Faltan TG_TOKEN o CHAT_ID en $ENV_PATH"
    exit 1
fi

# Parámetros
MENSAJE="$1"
FILE="$2"

if [[ -n "$FILE" && -f "$FILE" ]]; then
    # Enviar documento
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendDocument" \
         -F chat_id="${CHAT_ID}" \
         -F document=@"${FILE}" \
         -F caption="${MENSAJE}" > /dev/null
    echo "📨 Documento enviado a Telegram: $(basename "$FILE")"
else
    # Enviar solo mensaje de texto
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
         -d chat_id="${CHAT_ID}" \
         -d text="${MENSAJE}" > /dev/null
    echo "📨 Mensaje enviado a Telegram"
fi
