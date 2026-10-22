#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG="/data/options.json"

DB_NAME="$(jq -r '.database' "$CONFIG")"
DB_USER="$(jq -r '.username' "$CONFIG")"
DB_PASSWORD="$(jq -r '.password' "$CONFIG")"
TZ_VALUE="$(jq -r '.timezone' "$CONFIG")"
RESTORE_DUMP="$(jq -r '.restore_dump // "verifai_full.dump"' "$CONFIG")"

if [[ -z "$DB_PASSWORD" || "$DB_PASSWORD" == "null" ]]; then
  echo "ERROR: configura una contraseña para PostgreSQL."
  exit 1
fi

export POSTGRES_DB="$DB_NAME"
export POSTGRES_USER="$DB_USER"
export POSTGRES_PASSWORD="$DB_PASSWORD"
export PGDATA="/data/postgresql"
export TZ="$TZ_VALUE"

FIRST_START=0
if [[ ! -s "$PGDATA/PG_VERSION" ]]; then
  FIRST_START=1
fi

echo "======================================="
echo " VerifAI Data Service"
echo " PostgreSQL 16 + PostgREST 16.3 + Adminer"
echo " Database: $DB_NAME"
echo " PGDATA:   $PGDATA"
echo "======================================="

/usr/local/bin/docker-entrypoint.sh postgres &
PG_PID=$!

PGRST_PID=""
ADMINER_PID=""
NGINX_PID=""

cleanup() {
  set +e

  if [[ -n "${NGINX_PID:-}" ]] && kill -0 "$NGINX_PID" 2>/dev/null; then
    kill -TERM "$NGINX_PID"
  fi

  if [[ -n "${ADMINER_PID:-}" ]] && kill -0 "$ADMINER_PID" 2>/dev/null; then
    kill -TERM "$ADMINER_PID"
  fi

  if [[ -n "${PGRST_PID:-}" ]] && kill -0 "$PGRST_PID" 2>/dev/null; then
    kill -TERM "$PGRST_PID"
  fi

  if kill -0 "$PG_PID" 2>/dev/null; then
    kill -TERM "$PG_PID"
  fi

  wait "$NGINX_PID" 2>/dev/null || true
  wait "$ADMINER_PID" 2>/dev/null || true
  wait "$PGRST_PID" 2>/dev/null || true
  wait "$PG_PID" 2>/dev/null || true
}

trap cleanup EXIT TERM INT


#######################################
# ESPERAR POSTGRESQL
#######################################

for _ in $(seq 1 120); do

  if pg_isready \
      -h 127.0.0.1 \
      -p 5432 \
      -U "$DB_USER" \
      -d "$DB_NAME" >/dev/null 2>&1; then
    break
  fi

  if ! kill -0 "$PG_PID" 2>/dev/null; then
    echo "ERROR: PostgreSQL terminó durante el arranque."
    wait "$PG_PID"
    exit 1
  fi

  sleep 1
done


if ! pg_isready \
    -h 127.0.0.1 \
    -p 5432 \
    -U "$DB_USER" \
    -d "$DB_NAME" >/dev/null 2>&1; then

  echo "ERROR: PostgreSQL no está listo tras 120 segundos."
  exit 1
fi


PSQL=(
  psql
  -h 127.0.0.1
  -U "$DB_USER"
  -d "$DB_NAME"
  -v ON_ERROR_STOP=1
)


#######################################
# CREAR / RESTAURAR BD
#######################################

if [[ "$FIRST_START" -eq 1 \
      && -n "$RESTORE_DUMP" \
      && -f "/share/$RESTORE_DUMP" ]]; then

  echo "Restaurando /share/$RESTORE_DUMP ..."

  "${PSQL[@]}" -c \
    "DO \$\$ BEGIN CREATE ROLE web_anon NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END \$\$;"

  pg_restore \
    -h 127.0.0.1 \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    --no-owner \
    --no-privileges \
    "/share/$RESTORE_DUMP"

else

  "${PSQL[@]}" -f /opt/verifai/bootstrap.sql

fi


"${PSQL[@]}" -f /opt/verifai/migrate_v2.sql


#######################################
# POSTGREST
#######################################

uri_encode() {
  jq -nr --arg v "$1" '$v|@uri'
}

DB_USER_URI="$(uri_encode "$DB_USER")"
DB_PASS_URI="$(uri_encode "$DB_PASSWORD")"
DB_NAME_URI="$(uri_encode "$DB_NAME")"

export PGRST_DB_URI="postgresql://${DB_USER_URI}:${DB_PASS_URI}@127.0.0.1:5432/${DB_NAME_URI}"
export PGRST_DB_SCHEMAS="public"
export PGRST_DB_ANON_ROLE="web_anon"

export PGRST_SERVER_HOST="0.0.0.0"
export PGRST_SERVER_PORT="3000"

echo "PostgreSQL listo."
echo "Arrancando PostgREST en 3000..."

/usr/local/bin/postgrest &
PGRST_PID=$!


#######################################
# ADMINER
#######################################

echo "Arrancando Adminer en 127.0.0.1:8081..."

php \
  -S 127.0.0.1:8081 \
  -t /var/www/adminer &

ADMINER_PID=$!


#######################################
# HOME ASSISTANT INGRESS
#######################################

echo "Arrancando interfaz Home Assistant Ingress en 8099..."

nginx -g 'daemon off;' &
NGINX_PID=$!


#######################################
# MANTENER SERVICIOS
#######################################

wait -n \
  "$PG_PID" \
  "$PGRST_PID" \
  "$ADMINER_PID" \
  "$NGINX_PID"
