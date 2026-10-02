CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
  CREATE ROLE web_anon NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS paciente_fuera_cama (
  id BIGSERIAL PRIMARY KEY,
  habitacion TEXT NOT NULL DEFAULT '1A',
  hora TIMESTAMPTZ NOT NULL DEFAULT now(),
  validacion TEXT CHECK (
    validacion IS NULL OR validacion IN ('correcta', 'falsa_alarma', 'no_detectada')
  ),
  estado TEXT CHECK (
    estado IS NULL OR estado IN ('on', 'off', 'unknown', 'unavailable', 'detectado')
  ),
  disparador TEXT NOT NULL CHECK (disparador IN ('sensor', 'trabajador')),
  origen TEXT CHECK (origen IS NULL OR origen IN ('sensor', 'pantalla', 'push')),
  sensor_entity TEXT,
  usuario TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS trabajador_en_area (
  id BIGSERIAL PRIMARY KEY,
  habitacion TEXT NOT NULL DEFAULT '1A',
  hora TIMESTAMPTZ NOT NULL DEFAULT now(),
  trabajo TEXT CHECK (
    trabajo IS NULL OR trabajo IN ('cambio_pañal', 'reposo', 'vigilancia', 'otro')
  ),
  estado TEXT CHECK (
    estado IS NULL OR estado IN ('on', 'off', 'unknown', 'unavailable', 'detectado')
  ),
  disparador TEXT NOT NULL CHECK (disparador IN ('sensor', 'trabajador')),
  origen TEXT CHECK (origen IS NULL OR origen IN ('sensor', 'pantalla', 'push')),
  sensor_entity TEXT,
  usuario TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS caidas (
  id BIGSERIAL PRIMARY KEY,
  habitacion TEXT NOT NULL DEFAULT '1A',
  hora TIMESTAMPTZ NOT NULL DEFAULT now(),
  hora_caida TIMESTAMPTZ,
  estado TEXT CHECK (
    estado IS NULL OR estado IN ('on', 'off', 'unknown', 'unavailable', 'detectado')
  ),
  validacion TEXT CHECK (
    validacion IS NULL OR validacion IN ('correcta', 'falsa_alarma', 'no_detectada')
  ),
  disparador TEXT NOT NULL CHECK (disparador IN ('sensor', 'trabajador')),
  origen TEXT CHECK (origen IS NULL OR origen IN ('sensor', 'pantalla', 'push')),
  sensor_entity TEXT,
  usuario TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS barreras (
  id BIGSERIAL PRIMARY KEY,
  habitacion TEXT NOT NULL DEFAULT '1A',
  hora TIMESTAMPTZ NOT NULL DEFAULT now(),
  validacion TEXT CHECK (
    validacion IS NULL OR validacion IN ('correcta', 'falsa_alarma', 'no_detectada')
  ),
  barrera TEXT CHECK (
    barrera IS NULL OR barrera IN ('derecha', 'izquierda')
  ),
  estado TEXT,
  disparador TEXT NOT NULL CHECK (disparador IN ('sensor', 'trabajador')),
  origen TEXT,
  sensor_entity TEXT,
  usuario TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS posicion_encamado (
  id BIGSERIAL PRIMARY KEY,
  habitacion TEXT NOT NULL DEFAULT '1A',
  hora TIMESTAMPTZ NOT NULL DEFAULT now(),
  estado TEXT,
  validacion TEXT CHECK (
    validacion IS NULL OR validacion IN ('correcta', 'falsa_alarma', 'no_detectada')
  ),
  disparador TEXT NOT NULL CHECK (disparador IN ('sensor', 'trabajador')),
  origen TEXT,
  sensor_entity TEXT,
  usuario TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_paciente_fuera_cama_hora
  ON paciente_fuera_cama (hora DESC);
CREATE INDEX IF NOT EXISTS idx_trabajador_en_area_hora
  ON trabajador_en_area (hora DESC);
CREATE INDEX IF NOT EXISTS idx_caidas_hora
  ON caidas (hora DESC);
CREATE INDEX IF NOT EXISTS idx_caidas_hora_caida
  ON caidas (hora_caida DESC);

GRANT USAGE ON SCHEMA public TO web_anon;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO web_anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO web_anon;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE ON TABLES TO web_anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO web_anon;
