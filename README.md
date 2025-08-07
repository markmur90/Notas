# Proyecto de Automatización y Gestión de Notas

Este repositorio agrupa una serie de scripts Bash para:

- **Control de tiempo de trabajo** en zona America/Bogota, con registro diario y total.
- **Alertas horarias** mediante notificación gráfica, síntesis de voz y Telegram.
- **Respaldo y sincronización** de base de datos y proyecto en un servidor VPS.
- **Generación de resúmenes** de notas en texto y audio, con envío por Telegram.
- **Listado completo** de notas, audios y tareas (pendientes/completadas).

---

## 📁 Estructura de carpetas

```
/home/markmur88/Notas/
├── texto/                     # Archivos de notas .txt
│   └── nota_texto.txt
├── audio/                     # Audios generados (.wav)
│   └── voz_*.wav
├── logs/                      # Logs diversos
│   ├── alerta_horaria.log
│   ├── tiempo_total.log
│   ├── tiempo_dia.log
│   ├── ultima_fecha.log
│   ├── resumen_audio.log
│   └── resumen_total_audio.log
├── pending.txt                # Tareas pendientes
├── complete.txt               # Tareas completadas
├── voz_seleccionada           # Código de voz elegida para espeak
└── enviar_telegram.sh         # Script para enviar mensajes a Telegram
```

En tu directorio de proyecto (por ejemplo `api_bank_h2/`) y backups encontrarás:

```
/home/markmur88/backup/vps/
├── db_backup_YYYY-MM-DD_HH.sql
└── proyecto_backup_YYYY-MM-DD_HH.tar.gz
```

---

## 🔧 Prerrequisitos

- **bash**
- **coreutils** (`date`, `find`, `stat`, `awk`, etc.)
- **espeak** (o `gtts-cli` + `mpg123` + `ffmpeg/play`)
- **aplay** (o reproductor WAV compatible)
- **notify-send** (para notificaciones gráficas)
- **psql/pg\_dump** (cliente de PostgreSQL)
- **ssh/scp** con clave pública configurada
- Un **bot de Telegram** y tu script `enviar_telegram.sh` con `BOT_TOKEN` y `CHAT_ID`.

---

## Instaladores de Voces

### 1) espeak y voces MBROLA

sudo apt-get update && sudo apt-get install -y espeak mbrola mbrola-us1 mbrola-us2 mbrola-uk1 mbrola-uk2 mbrola-de1 mbrola-de2

### 2) Python y gtts-cli

sudo apt-get install -y python3-pip && pip3 install --upgrade gTTS

### 3) mpg123 (para reproducir MP3)

sudo apt-get install -y mpg123

### 4) ffmpeg y sox (para convertir y reproducir WAV)

sudo apt-get install -y ffmpeg sox

### 5) opción: instala todas las voces disponibles de MBROLA (si deseas más idiomas)

sudo apt-get install -y mbrola-*

---

## ⚙️ Configuración global

Edita en cada script, o exporta como variable de entorno:

```bash
USER_LOCAL="markmur88"                              # Tu usuario Linux
TIMEZONE="America/Bogota"                          # Zona horaria de referencia
VOICE_FILE="$HOME/Notas/voz_seleccionada"          # Voz para espeak
LOG_DIR="$HOME/Notas/logs"                         # Directorio de logs
DIR_PROYECTO="/home/$USER_LOCAL/api_bank_h2"       # Ruta a tu código fuente
DIR_BACKUP="/home/$USER_LOCAL/backup/vps"          # Carpeta de backups
# Datos de la BD
DB_NAME="mydatabase"
DB_USER="$USER_LOCAL"
DB_PASS="Ptf8454Jd55"
DB_HOST="localhost"
DB_PORT="5432"
# VPS
VPS_USER="$USER_LOCAL"
VPS_IP="80.78.30.242"
VPS_PORT="22"
SSH_KEY="/home/$USER_LOCAL/.ssh/vps_njalla_nueva"
DIR_REMOTO="/home/$VPS_USER/api_bank_heroku"
```

---

## 🚀 Scripts y Usos

### 1. `alerta_horaria.sh`

Envía cada X minutos una notificación local y por Telegram, anuncia la hora y tiempo trabajado desde el inicio de sesión en Bogotá.\
**Uso:**

```bash
chmod +x alerta_horaria.sh
./alerta_horaria.sh
```

### 2. `backup_sync.sh`

Genera dump de PostgreSQL y comprime tu proyecto, luego copia a VPS vía `scp`.\
**Uso:**

```bash
chmod +x backup_sync.sh
./backup_sync.sh
```

### 3. `resumen_dia.sh`

Lee la nota más reciente en `Notas/texto`, anuncia fecha/hora y contenido por voz, envía por Telegram y guarda el audio.\
**Uso:**

```bash
chmod +x resumen_dia.sh
./resumen_dia.sh
```

### 4. `resumen_total.sh`

Listados completos de notas, audios, pendientes y completadas; envía conteo por Telegram, genera y archiva un audio.\
**Uso:**

```bash
chmod +x resumen_total.sh
./resumen_total.sh
```

### 5. `tiempo_acumulado.sh`

Calcula minutos/horas trabajados hoy y total, basados en logs diarios y totales, envía resumen por Telegram.\
**Uso:**

```bash
chmod +x tiempo_acumulado.sh
./tiempo_acumulado.sh
```

---

## 📋 Ejemplo de envío por Telegram

Tu script `enviar_telegram.sh` debe recibir un solo argumento con el texto:

```bash
#!/bin/bash
BOT_TOKEN="TU_TOKEN_AQUI"
CHAT_ID="TU_CHAT_ID"
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
     -d chat_id="$CHAT_ID" -d text="$1"
```

---

## 🛠️ Personalización

- **Frecuencia de alertas:** ajusta el cron o bucle en `alerta_horaria.sh`.
- **Voz y velocidad:** cambia el parámetro `-s` de espeak o elige otra voz en `voz_seleccionada`.
- **Formato de backup:** añade exclusiones o compresión incremental en `backup_sync.sh`.
- **Filtros de notas:** modifica patrones en `find` para distintos nombres de archivos.

---

## 📜 Licencia

Este proyecto es de uso personal. Adáptalo y extiéndelo según tus necesidades bancarias y de productividad. ¡Disfruta de tus scripts!

