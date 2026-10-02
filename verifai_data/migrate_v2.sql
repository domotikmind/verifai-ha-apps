CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
  CREATE ROLE web_anon NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS resiplus_event_map (
  event_type TEXT PRIMARY KEY,
  table_name TEXT NOT NULL UNIQUE,
  type_id INTEGER,
  enabled BOOLEAN NOT NULL DEFAULT true,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO resiplus_event_map (event_type, table_name, type_id)
VALUES
  ('caida', 'caidas', 14),
  ('barreras', 'barreras', 15),
  ('trabajador_en_area', 'trabajador_en_area', 16),
  ('paciente_fuera_cama', 'paciente_fuera_cama', 17),
  ('posicion_encamado', 'posicion_encamado', 18)
ON CONFLICT (event_type) DO NOTHING;

CREATE TABLE IF NOT EXISTS resiplus_room_map (
  habitacion TEXT PRIMARY KEY,
  resident_id BIGINT,
  patient_name TEXT,
  enabled BOOLEAN NOT NULL DEFAULT true,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'caidas',
    'paciente_fuera_cama',
    'trabajador_en_area',
    'barreras',
    'posicion_encamado'
  ]
  LOOP
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS event_uuid UUID DEFAULT gen_random_uuid()', t);
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS hora_trabajador TIMESTAMPTZ', t);
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS resiplus_resident_id BIGINT', t);
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS resiplus_type_id INTEGER', t);
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS resiplus_record_id BIGINT', t);
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS resiplus_status TEXT', t);
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS resiplus_sent_at TIMESTAMPTZ', t);
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS resiplus_error TEXT', t);
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now()', t);
    EXECUTE format('UPDATE %I SET event_uuid = gen_random_uuid() WHERE event_uuid IS NULL', t);
    EXECUTE format('ALTER TABLE %I ALTER COLUMN event_uuid SET NOT NULL', t);
    EXECUTE format('CREATE UNIQUE INDEX IF NOT EXISTS %I ON %I (event_uuid)', 'idx_' || t || '_event_uuid', t);
  END LOOP;
END $$;

GRANT USAGE ON SCHEMA public TO web_anon;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO web_anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO web_anon;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE ON TABLES TO web_anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO web_anon;
