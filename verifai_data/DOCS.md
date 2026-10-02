# VerifAI Data Service

Esta app agrupa PostgreSQL 16 y PostgREST para que VerifAI tenga un único
servicio de datos portable entre Raspberry Pi (`aarch64`) y HAOS sobre
Proxmox/miniPC (`amd64`).

## Restaurar la BD antigua

Antes del primer arranque:

1. Copia `verifai_full.dump` a `/share/verifai_full.dump`.
2. Configura una contraseña nueva en la app.
3. Arranca la app.

Si encuentra el dump en el primer arranque, lo restaura y aplica la migración
VerifAI DB v2. Si no encuentra dump, crea una BD nueva.

## API

PostgREST escucha en el puerto interno 3000 y usa el rol `web_anon`.
La API no se publica directamente en la LAN.

## Persistencia y backups

PostgreSQL guarda sus datos en `/data/postgresql`. La app usa `backup: cold`,
por lo que Home Assistant detiene la app durante el backup para obtener una
copia consistente.
