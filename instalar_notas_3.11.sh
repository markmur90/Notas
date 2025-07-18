#!/bin/bash

set -e

INSTALL_PATH="$HOME/.local/share/Notas"
BIN_PATH="$HOME/.local/bin"
mkdir -p "$INSTALL_PATH"
mkdir -p "$BIN_PATH"

# Copiar archivos
echo "[INFO] Copiando archivos a $INSTALL_PATH..."
cp -r Notas/* "$INSTALL_PATH"

# Añadir alias a .zshrc si no existe
if ! grep -q "alias_notas.sh" "$HOME/.zshrc"; then
    echo 'source "$HOME/.local/share/Notas/alias_notas.sh"' >> "$HOME/.zshrc"
    echo "[INFO] Alias añadidos a .zshrc"
fi

# Instalar crontab
crontab "$INSTALL_PATH/crontab.txt"
echo "[INFO] Crontab instalado"

# Crear acceso directo en ~/.local/bin
echo '#!/bin/bash' > "$BIN_PATH/Notas"
echo 'bash "$HOME/.local/share/Notas/Notas_menu.sh" "$@"' >> "$BIN_PATH/Notas"
chmod +x "$BIN_PATH/Notas"

echo "[✔] Instalación completada. Abre una nueva terminal o ejecuta 'source ~/.zshrc'"
