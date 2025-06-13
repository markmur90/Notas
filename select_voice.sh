#!/bin/bash
VOICE_FILE="$HOME/Notas/voz_seleccionada"

ENGINES=()
command -v espeak >/dev/null && ENGINES+=("espeak")
command -v gtts-cli >/dev/null && ENGINES+=("gtts-cli")
ENGINES+=("Salir")

[ ${#ENGINES[@]} -le 1 ] && { echo "❌ No hay motores de síntesis instalados." >&2; exit 1; }

echo "Motores disponibles:"
PS3="Selecciona un motor (#): "
select engine in "${ENGINES[@]}"; do
    case "$engine" in
        espeak)
            mapfile -t VOICES < <(espeak --voices | awk 'NR>1 {print $5}' | sed 's:.*/::' | sort -u)
            while true; do
                echo "Voces disponibles (espeak):"
                PS3="Voz espeak (#): "
                select V in "${VOICES[@]}"; do
                    if [ -n "$V" ]; then
                        espeak -v "$V" "Esta es la voz $V"
                        read -rp "¿Usar esta voz? [s/n]: " RESP
                        if [[ $RESP =~ ^[sS]$ ]]; then
                            echo "$V" > "$VOICE_FILE"
                            echo "Voz seleccionada: $V"
                            exit 0
                        else
                            break
                        fi
                    else
                        echo "Opción inválida"
                    fi
                done
            done
            ;;
        gtts-cli)
            mapfile -t LANGS < <(gtts-cli --all | awk -F: '{gsub(/^ +| +$/,"",$1); print $1}')
            while true; do
                echo "Idiomas disponibles (gTTS):"
                PS3="Idioma gTTS (#): "
                select L in "${LANGS[@]}"; do
                    if [ -n "$L" ]; then
                        TMP_MP3="/tmp/gtts_test.mp3"
                        gtts-cli --lang "$L" "Esta es la voz $L" --output "$TMP_MP3"
                        if command -v mpg123 >/dev/null; then
                            mpg123 -q "$TMP_MP3"
                        elif command -v ffmpeg >/dev/null && command -v play >/dev/null; then
                            ffmpeg -loglevel quiet -i "$TMP_MP3" /tmp/gtts_test.wav
                            play /tmp/gtts_test.wav
                            rm -f /tmp/gtts_test.wav
                        else
                            echo "⚠️ No hay reproductor de audio instalado." >&2
                        fi
                        rm -f "$TMP_MP3"
                        read -rp "¿Usar este idioma? [s/n]: " RESP
                        if [[ $RESP =~ ^[sS]$ ]]; then
                            echo "gtts:$L" > "$VOICE_FILE"
                            echo "Motor seleccionado: gtts-cli, idioma: $L"
                            exit 0
                        else
                            break
                        fi
                    else
                        echo "Opción inválida"
                    fi
                done
            done
            ;;
        Salir)
            exit 0
            ;;
        *) echo "Opción inválida";;
    esac
    echo
 done
