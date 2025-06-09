#!/bin/bash
echo "📦 Resumen total del proyecto (notas acumuladas)"
find /home/markmur88/Notas/texto -type f -name "nota_texto.txt" -exec echo "📝" {} \; -exec cat {} \;
echo -e "\n🎤 Audios grabados:"
find /home/markmur88/Notas/audio -type f -name "voz_*.wav"
echo -e "\n📦 Tareas Pendientes:"
find /home/markmur88/Notas -type f -name "pending.txt" -exec echo "📝" {} \; -exec cat {} \;
echo -e "\n📦 Tareas Completas:"
find /home/markmur88/Notas -type f -name "complete.txt" -exec echo "📝" {} \; -exec cat {} \;