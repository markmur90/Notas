#!/bin/bash

set -e

CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Añadir source de alias_notas.sh al zshrc si no está presente
if ! grep -q "alias_notas.sh" "$HOME/.zshrc"; then
    echo "source \"$CURRENT_DIR/alias_notas.sh\"" >> "$HOME/.zshrc"
    echo "[INFO] Alias añadidos a .zshrc"
else
    echo "[INFO] alias_notas.sh ya está referenciado en .zshrc"
fi

# Instalar crontab con rutas absolutas
TMP_CRON=$(mktemp)
sed "s|\$HOME/.local/share/notas|$CURRENT_DIR|g" "$CURRENT_DIR/crontab.txt" > "$TMP_CRON"
crontab "$TMP_CRON"
rm "$TMP_CRON"

echo "[✔] Entorno configurado con alias y cron correctamente."
