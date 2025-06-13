#!/usr/bin/env bash

# Detectar el directorio actual del script
INSTALL_DIR="/home/markmur88/Notas"
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
alias Sincronizar="bash \"$INSTALL_DIR/logs_sync.sh\""

# Menú interactivo basado en grupos de alias
Notas() {
    typeset -A alias_groups
    alias_groups=(
        ["Notas"]="texto voz"
        ["Alertas"]="alerta_horaria pendientes Sincronizar"
        ["Resumen"]="dia_resumen proyecto_resumen audio_resumen"
    )

    while true; do
        echo -e "\nSelecciona un grupo de alias para ver o ejecutar:"
        select grupo in "${(@k)alias_groups}" "Salir"; do
            if [[ "$grupo" == "Salir" ]]; then
                return
            elif [[ -n "$grupo" && -n "${alias_groups[$grupo]}" ]]; then
                while true; do
                    echo -e "\nAlias en el grupo: $grupo"
                    alias_list=("${(s: :)alias_groups[$grupo]}")
                    select alias_cmd in "${alias_list[@]}" "Volver"; do
                        if [[ "$alias_cmd" == "Volver" ]]; then
                            break
                        elif [[ -n "$alias_cmd" ]]; then
                            echo -e "\n🔧 Ejecutando alias: $alias_cmd\n"
                            eval "$alias_cmd"
                        fi
                        break
                    done
                    [[ "$REPLY" -eq ${#alias_list[@]}+1 ]] && break
                done
                break
            fi
        done
    done
}
