FROM postgrest/postgrest:v16.4 AS postgrest

FROM postgres:16.15-bookworm

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="app" \
  io.hass.arch="${BUILD_ARCH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends jq tzdata ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=postgrest /bin/postgrest /usr/local/bin/postgrest
COPY run.sh /run.sh
COPY bootstrap.sql /opt/verifai/bootstrap.sql
COPY migrate_v2.sql /opt/verifai/migrate_v2.sql

RUN chmod a+x /run.sh

ENTRYPOINT ["/run.sh"]
