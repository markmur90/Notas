#!/bin/bash
echo "📦 Resumen total del proyecto (notas acumuladas)"
find /home/markmur88/notas/logs/texto -type f -name "nota_texto.txt" -exec echo "📝" {} \; -exec cat {} \;
echo -e "\n🎤 Audios grabados:"
find /home/markmur88/notas/logs/voz -type f -name "voz_*.wav"
