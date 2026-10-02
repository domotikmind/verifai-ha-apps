# VerifAI Home Assistant Apps

Repositorio de apps para desplegar la infraestructura VerifAI en Home Assistant OS.

## Apps

- **VerifAI Data Service**: PostgreSQL 16 + PostgREST en una sola app.
- Arquitecturas: `aarch64` y `amd64`.

## Instalación

1. Home Assistant → Ajustes → Apps → Tienda de apps → Repositorios.
2. Añadir:
   `https://github.com/domotikmind/verifai-ha-apps`
3. Instalar **VerifAI Data Service**.
4. Antes del primer arranque, si se desea restaurar la BD antigua, copiar
   `verifai_full.dump` a `/share/verifai_full.dump`.
5. Configurar una contraseña nueva en la app.
6. Arrancar la app.

La API PostgREST escucha internamente en el puerto `3000`; no se publica a la LAN.
