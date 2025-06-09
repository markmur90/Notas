#!/bin/bash
FECHA=$(date '+%Y-%m-%d')
HORA=$(date '+%H:%M')
DIR="$HOME/notas/texto"
mkdir -p "$DIR"
echo "📒 Nota rápida (terminá con Ctrl+D):"
cat >> "$DIR/$FECHA.txt" <<EOF
[$HORA]
$(cat)
EOF
echo "✅ Nota guardada en $DIR/$FECHA.txt"
