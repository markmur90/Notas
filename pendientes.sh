#!/bin/bash

PENDIENTES="$HOME/Notas/pending.txt"
COMPLETADOS="$HOME/Notas/complete.txt"

mkdir -p "$(dirname "$PENDIENTES")"
touch "$PENDIENTES" "$COMPLETADOS"

while true; do
  clear
  echo "📌 GESTOR DE PENDIENTES"
  echo "======================="
  echo "1. Ver pendientes"
  echo "2. Añadir pendiente"
  echo "3. Completar pendiente"
  echo "4. Ver completados"
  echo "5. Salir"
  echo -n "Selecciona una opción [1-5]: "
  read -r OPCION

  case $OPCION in
    1)
      echo -e "\n📋 Lista de pendientes:"
      nl -w2 -s'. ' "$PENDIENTES"
      read -p $'\nPresiona enter para continuar...' ;;
    2)
      echo -n "🆕 Escribe el nuevo pendiente: "
      read -r NUEVO
      echo "$NUEVO" >> "$PENDIENTES"
      echo "✅ Añadido."
      sleep 1 ;;
    3)
      echo -e "\n📋 Pendientes actuales:"
      nl -w2 -s'. ' "$PENDIENTES"
      echo -n "Ingresa el número del pendiente a completar: "
      read -r NUM
      COMPLETADO=$(sed "${NUM}q;d" "$PENDIENTES")
      if [ -n "$COMPLETADO" ]; then
        echo "$COMPLETADO" >> "$COMPLETADOS"
        sed -i "${NUM}d" "$PENDIENTES"
        echo "✅ Marcado como completado."
      else
        echo "❌ Número inválido."
      fi
      sleep 1 ;;
    4)
      echo -e "\n✅ Completados:"
      nl -w2 -s'. ' "$COMPLETADOS"
      read -p $'\nPresiona enter para continuar...' ;;
    5)
      echo "👋 Salida..."
      break ;;
    *)
      echo "❌ Opción no válida. Intentá de nuevo."
      sleep 1 ;;
  esac
done

clear