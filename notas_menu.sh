# #!/bin/bash

# INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"
# source "$INSTALL_DIR/alias_notas.sh"

# command_exists() {
#     type "$1" &> /dev/null
# }

# if ! command -v dialog &> /dev/null; then
#     echo "ERROR: El programa 'dialog' no está instalado. Instalalo para usar el menú."
#     exit 1
# fi

# CHOICE=$(dialog --clear --backtitle "Menú Notas" \
#     --title "Opciones disponibles" \
#     --menu "Selecciona una acción:" 15 50 9 \
#     2 "alerta_horaria" \
#     3 "nota_texto" \
#     4 "nota_voz" \
#     5 "resumen_dia" \
#     6 "resumen_audio" \
#     7 "resumen_proyecto" \
#     8 "backup_now" \
#     9 "sync_backup" \
#     2>&1 >/dev/tty)

# clear

# case $CHOICE in
#   2) command_exists alerta_horaria && alerta_horaria ;;
#   3) command_exists nota_texto && nota_texto ;;
#   4) command_exists nota_voz && nota_voz ;;
#   5) command_exists resumen_dia && resumen_dia ;;
#   6) command_exists resumen_audio && resumen_audio ;;
#   7) command_exists resumen_proyecto && resumen_proyecto ;;
#   8) command_exists backup_now && backup_now ;;
#   9) command_exists sync_backup && sync_backup ;;
#   *) echo "Opción inválida o cancelada." ;;
# esac
