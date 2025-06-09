#!/bin/bash
echo "📦 Resumen total del proyecto"
echo "📝 Notas acumuladas:"
find "$HOME/notas/texto" -type f -name "*.txt" -exec echo "🗒 {}" \; -exec cat {} \;
echo -e "\n🎤 Audios acumulados:"
find "$HOME/notas/audio" -type f -name "voz_*.wav"
