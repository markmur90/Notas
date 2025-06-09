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
`mbrola` y `mbrola-es1`, se utilizará de forma automática la voz `mb-es1`, que
suena más natural que la predeterminada.

Para instalarlos en sistemas basados en Debian:

```bash
sudo apt-get install mbrola mbrola-es1
```