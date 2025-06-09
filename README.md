# Notas

Colección de scripts Bash para llevar notas rápidas, gestionar pendientes y realizar
recordatorios horarios. Incluye además tareas de respaldo automático y
sincronización con un servidor remoto a través de `scp`.

## Estructura de scripts principales

- **alerta_horaria.sh** – Envía una notificación con la hora actual,
  pendientes y tiempo invertido en el día y el proyecto. Desde esta versión la
  alerta hablada y el mensaje de Telegram se ejecutan en cada corrida del script.
  Se espera que este script sea llamado periódicamente mediante `cron`.
- **nota_texto.sh** – Permite crear notas de texto rápidas guardándolas en la
  carpeta `texto` con fecha y hora.
- **nota_voz.sh** – Graba hasta 60 segundos de audio si hay dispositivo de
  captura disponible, guardando el archivo en `audio/FECHA`.
- **pendientes.sh** – Muestra un menú simple para listar, agregar o completar
  tareas pendientes almacenadas en `pending.txt`.
- **daily_backup.sh** y **startup_sync.sh** – Scripts de respaldo y
  sincronización de archivos hacia un servidor remoto mediante SSH.

El archivo `crontab.txt` contiene un ejemplo de programación para ejecutar estas
acciones de forma periódica.

## Lógica de `alerta_horaria.sh`

El script lleva contadores de tiempo total y del día mediante archivos de
log. Cada ejecución incrementa estos contadores en cinco minutos y genera un
mensaje con los pendientes actuales. Además de la notificación gráfica,
reproduce el texto por voz y lo envía por Telegram.

Anteriormente la reproducción de audio y el envío por Telegram se realizaban
cada tres ejecuciones (aproximadamente cada 30 minutos si se ejecutaba cada
10). Esta versión elimina esa condición, por lo que la salida de audio
coincide con cada notificación del sistema.

### Mejorar la voz de las alertas

El script usa `espeak` para la salida hablada. Si están instalados los paquetes
`mbrola` y alguna de sus voces (`mbrola-es1`, `mbrola-es2`, etc.), se utilizará
de forma automática la primera voz MBROLA disponible (por ejemplo `mb-es1`), que
suena más natural que la predeterminada.

También es posible emplear [gTTS](https://pypi.org/project/gTTS/) para obtener
una voz más natural. Si `gtts-cli` y `mpg123` están presentes, el script la
utilizará automáticamente en lugar de `espeak`. Requiere conexión a internet.

Para instalarlos en sistemas basados en Debian:

```bash
sudo apt-get install mbrola mbrola-es1
```

Para contar con más voces en español puedes instalar paquetes adicionales de
MBROLA, como `mbrola-es2`, `mbrola-es3` o `mbrola-es4`:

```bash
sudo apt-get install mbrola-es2 mbrola-es3 mbrola-es4
```

Para probar la síntesis con gTTS se necesitan `python3-pip` y el reproductor
`mpg123`. Instala ambos con:

```bash
sudo apt-get install python3-pip mpg123
pip3 install --user gtts
```

Para elegir una voz distinta o configurarla manualmente, ejecuta:

```bash
./alerta_horaria.sh --config-voice
```

Se mostrará un menú con las voces disponibles de `espeak` y la selección
quedará guardada en `~/Notas/voz_seleccionada` para próximas ejecuciones.
Al ejecutar esta opción se mostrará un menú con todas las voces disponibles
según `espeak` (por ejemplo `es`, `en`, `mb-es1`). Al elegir una,
escucharás una muestra y podrás confirmar si deseas usarla.
La selección quedará guardada en `~/Notas/voz_seleccionada` para próximas
ejecuciones.

## Sincronización automática de logs

El script `logs_sync.sh` monitorea la carpeta `logs` con `inotifywait` y, ante cualquier cambio, realiza un commit y empuja los resultados al repositorio configurado. Se debe contar con acceso por SSH al repositorio.

Ejemplo de uso:

```bash
./logs_sync.sh
```
