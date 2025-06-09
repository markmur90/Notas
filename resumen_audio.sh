#!/bin/bash
echo "🔊 Generando resumen por voz"
ULTIMO_RESUMEN=$(find "$HOME/notas/texto" -type f -name "*.txt" -exec stat --format="%Y %n" {} \; 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
RESUMEN=$(cat "$ULTIMO_RESUMEN" 2>/dev/null)
[ -z "$RESUMEN" ] && RESUMEN="No hay notas recientes."
espeak "Resumen de tus notas: $RESUMEN"
