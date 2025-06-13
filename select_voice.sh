#!/usr/bin/env bash
# select_voice.sh: Selecciona voz para alertas (solo latino)
set -euo pipefail

VOICE_FILE="$HOME/Notas/voz_seleccionada"
VENV="$HOME/notas_env/bin/activate"

# Cargar entorno virtual si existe
[ -f "$VENV" ] && source "$VENV"

# Detectar motores disponibles
declare -A ENGINES
if command -v espeak >/dev/null; then ENGINES[espeak]=1; fi
if command -v gtts-cli >/dev/null; then ENGINES[gtts]=1; fi
if [ ${#ENGINES[@]} -eq 0 ]; then
  echo "❌ No hay motores TTS instalados. Instala espeak o gtts-cli." >&2
  exit 1
fi

# Función para menú genérico
menu() {
  local prompt="$1"; shift
  PS3="$prompt"
  select opt in "$@" "Volver"; do
    [[ "$opt" == "Volver" ]] && return 1
    for item in "$@"; do
      [[ "$opt" == "$item" ]] && printf "%s" "$opt" && return 0
    done
    echo "Opción inválida."
  done
}

# Listar y elegir voz espeak (solo es*)
select_espeak() {
  local all voices voice
  mapfile -t all < <(espeak --voices | awk 'NR>1{print $5}' | sed 's:.*/::' | sort -u)
  voices=()
  for v in "${all[@]}"; do [[ "$v" == es* ]] && voices+=("$v"); done
  [ ${#voices[@]} -eq 0 ] && voices=(es)

  while true; do
    echo "Voces latinas (espeak):"
    voice=$(menu "Elige voz espeak (#): " "${voices[@]}") || break
    espeak -v "$voice" "Esta es la voz $voice"
    read -rp "Usar esta voz? [s/n]: " yn
    [[ "$yn" =~ ^[sS] ]] && echo "$voice" > "$VOICE_FILE" && echo "Selección guardada: $voice" && exit
  done
}

# Listar y elegir idioma gtts (solo es*)
select_gtts() {
  local all langs lang
  mapfile -t all < <(gtts-cli --all | awk -F: '{gsub(/^ +| +$/,"",$1); print $1}')
  langs=()
  for l in "${all[@]}"; do [[ "$l" == es* ]] && langs+=("$l"); done
  [ ${#langs[@]} -eq 0 ] && langs=(es)

  while true; do
    echo "Dialetos latinos (gTTS):"
    lang=$(menu "Elige idioma gTTS (#): " "${langs[@]}") || break
    tempfile=$(mktemp --suffix=.mp3)
    gtts-cli --lang "$lang" "Esta es la voz $lang" --output "$tempfile"
    if command -v mpg123 >/dev/null; then mpg123 -q "$tempfile";
    elif command -v ffmpeg >/dev/null && command -v play >/dev/null; then
      ffmpeg -loglevel quiet -i "$tempfile" -y "${tempfile%.mp3}.wav"
      play "${tempfile%.mp3}.wav"
      rm -f "${tempfile%.mp3}.wav"
    else
      echo "⚠️ Instala mpg123 o ffmpeg+sox para reproducir audio." >&2
    fi
    rm -f "$tempfile"
    read -rp "Usar este dialecto? [s/n]: " yn
    [[ "$yn" =~ ^[sS] ]] && echo "gtts:$lang" > "$VOICE_FILE" && echo "Selección guardada: gtts:$lang" && exit
  done
}

# Menú principal
while true; do
  echo "Motores disponibles: ${!ENGINES[*]}"
  choice=$(menu "Selecciona motor (#): " "${!ENGINES[@]}") || exit
  case "$choice" in
    espeak) select_espeak;;
    gtts)    select_gtts;;
  esac
done
