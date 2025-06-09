#!/usr/bin/env bash

# Detectar el directorio actual del script
INSTALL_DIR="/home/markmur88/notas"
# INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Alias para ejecutar scripts desde el directorio actual
alias alerta_horaria="bash \"$INSTALL_DIR/alerta_horaria.sh\""
alias texto="bash \"$INSTALL_DIR/nota_texto.sh\""
alias voz="bash \"$INSTALL_DIR/nota_voz.sh\""
alias dia_resumen="bash \"$INSTALL_DIR/resumen_dia.sh\""
alias proyecto_resumen="bash \"$INSTALL_DIR/resumen_proyecto.sh\""
alias audio_resumen="bash \"$INSTALL_DIR/resumen_audio.sh\""
alias backup_now="bash \"$INSTALL_DIR/daily_backup.sh\""
alias sync_backup="bash \"$INSTALL_DIR/backup_and_sync.sh\""
alias pendientes="bash \"$INSTALL_DIR/pendientes.sh\""

# Alias de menú y ayuda
alias notas='clear; 
echo "📚 GUÍA COMPLETA DE AYUDA DISPONIBLE";
echo "-------------------------------------";
echo "alerta_horaria       → Ejecuta con logs y Telegram";
echo "texto                → Crea una nueva nota de texto";
echo "voz                  → Graba una nota de voz";
echo "dia_resumen          → Genera resumen de notas diarias";
echo "proyecto_resumen     → Muestra resumen por proyecto";
echo "audio_resumen        → Convierte resumen a audio";
echo "backup_now           → Ejecuta backup manual";
echo "sync_backup          → Sincroniza backups y notas";
echo "pendientes           → Administra tareas pendientes";
'
