-- ============================================================
--  SIGMAR — LUZ Y VIDA
--  Base de datos normalizada (3FN) — Supabase / PostgreSQL
--  Versión completa con periodos_curso integrado
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ============================================================
--  1. ROLES Y PERMISOS
-- ============================================================

CREATE TABLE roles (
  id          SERIAL PRIMARY KEY,
  nombre      TEXT NOT NULL UNIQUE,
  descripcion TEXT,
  activo      BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO roles (nombre, descripcion) VALUES
  ('admin',    'Acceso total al sistema'),
  ('pastor',   'Acceso a reportes y guías'),
  ('lider',    'Gestión de su grupo de reunión'),
  ('miembro',  'Acceso básico e inscripciones'),
  ('finanzas', 'Registro y consulta de aportes');

CREATE TABLE permisos (
  id             SERIAL PRIMARY KEY,
  id_rol         INT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  recurso        TEXT NOT NULL,
  puede_ver      BOOLEAN DEFAULT FALSE,
  puede_crear    BOOLEAN DEFAULT FALSE,
  puede_editar   BOOLEAN DEFAULT FALSE,
  puede_eliminar BOOLEAN DEFAULT FALSE,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(id_rol, recurso)
);

INSERT INTO permisos (id_rol, recurso, puede_ver, puede_crear, puede_editar, puede_eliminar) VALUES
  (1, 'miembros',        TRUE, TRUE, TRUE, TRUE),
  (1, 'usuarios',        TRUE, TRUE, TRUE, TRUE),
  (1, 'grupos',          TRUE, TRUE, TRUE, TRUE),
  (1, 'cursos',          TRUE, TRUE, TRUE, TRUE),
  (1, 'ministerios',     TRUE, TRUE, TRUE, TRUE),
  (1, 'aportes',         TRUE, TRUE, TRUE, TRUE),
  (1, 'asistencia',      TRUE, TRUE, TRUE, TRUE),
  (1, 'inscripciones',   TRUE, TRUE, TRUE, TRUE),
  (1, 'periodos_curso',  TRUE, TRUE, TRUE, TRUE),
  (2, 'miembros',        TRUE, FALSE, FALSE, FALSE),
  (2, 'grupos',          TRUE, FALSE, FALSE, FALSE),
  (2, 'cursos',          TRUE, TRUE,  TRUE,  FALSE),
  (2, 'aportes',         TRUE, FALSE, FALSE, FALSE),
  (2, 'asistencia',      TRUE, FALSE, FALSE, FALSE),
  (2, 'periodos_curso',  TRUE, TRUE,  TRUE,  FALSE),
  (3, 'grupos',          TRUE, FALSE, FALSE, FALSE),
  (3, 'asistencia',      TRUE, TRUE,  TRUE,  FALSE),
  (3, 'miembros',        TRUE, FALSE, TRUE,  FALSE),
  (4, 'inscripciones',   TRUE, TRUE,  FALSE, FALSE),
  (4, 'miembros',        TRUE, FALSE, TRUE,  FALSE),
  (4, 'periodos_curso',  TRUE, FALSE, FALSE, FALSE),
  (5, 'aportes',         TRUE, TRUE,  TRUE,  FALSE);


-- ============================================================
--  2. AUDITORÍA Y LOGS
-- ============================================================

CREATE TABLE audit_log (
  id               BIGSERIAL PRIMARY KEY,
  tabla            TEXT NOT NULL,
  operacion        TEXT NOT NULL CHECK (operacion IN ('INSERT','UPDATE','DELETE')),
  id_registro      TEXT,
  datos_anteriores JSONB,
  datos_nuevos     JSONB,
  id_usuario       UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ip_address       INET,
  user_agent       TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE sesiones_log (
  id          BIGSERIAL PRIMARY KEY,
  id_usuario  UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  accion      TEXT NOT NULL CHECK (accion IN ('login','logout','token_refresh','password_change')),
  ip_address  INET,
  dispositivo TEXT,
  exitoso     BOOLEAN DEFAULT TRUE,
  detalle     TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE errores_log (
  id          BIGSERIAL PRIMARY KEY,
  id_usuario  UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  modulo      TEXT,
  mensaje     TEXT NOT NULL,
  stack_trace TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE intentos_acceso (
  id          BIGSERIAL PRIMARY KEY,
  email       TEXT NOT NULL,
  ip_address  INET,
  exitoso     BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE tokens_verificacion (
  id          SERIAL PRIMARY KEY,
  id_usuario  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token       TEXT NOT NULL UNIQUE DEFAULT encode(gen_random_bytes(32), 'hex'),
  tipo        TEXT NOT NULL CHECK (tipo IN ('recuperacion','verificacion','invitacion')),
  usado       BOOLEAN DEFAULT FALSE,
  expira_at   TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours'),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE configuracion (
  id          SERIAL PRIMARY KEY,
  clave       TEXT NOT NULL UNIQUE,
  valor       TEXT,
  descripcion TEXT,
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_by  UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

INSERT INTO configuracion (clave, valor, descripcion) VALUES
  ('nombre_iglesia',     'Luz y Vida', 'Nombre de la iglesia'),
  ('max_intentos_login', '5',          'Intentos máximos antes de bloquear'),
  ('duracion_token_min', '1440',       'Duración token en minutos (24h)'),
  ('version_sistema',    '1.0.0',      'Versión actual del sistema');


-- ============================================================
--  3. MINISTERIOS
-- ============================================================

CREATE TABLE ministerios (
  id          SERIAL PRIMARY KEY,
  nombre      TEXT NOT NULL UNIQUE,
  descripcion TEXT,
  estado      TEXT NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo','inactivo')),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);


-- ============================================================
--  4. MIEMBROS
-- ============================================================

CREATE TABLE miembros (
  id                SERIAL PRIMARY KEY,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW(),
  nombre            TEXT NOT NULL,
  fecha_nacimiento  DATE,
  edad              INT,
  carnet            TEXT UNIQUE,
  foto_url          TEXT,
  telefono          TEXT,
  direccion         TEXT,
  bautizado         BOOLEAN DEFAULT FALSE,
  fecha_conversion  DATE,
  asistio_encuentro BOOLEAN DEFAULT FALSE,
  estado            TEXT NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo','inactivo','visita'))
);


-- ============================================================
--  5. MINISTERIO_MIEMBROS
-- ============================================================

CREATE TABLE ministerio_miembros (
  id             SERIAL PRIMARY KEY,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  id_ministerio  INT NOT NULL REFERENCES ministerios(id) ON DELETE CASCADE,
  id_miembro     INT NOT NULL REFERENCES miembros(id) ON DELETE CASCADE,
  rol_ministerio TEXT NOT NULL DEFAULT 'integrante' CHECK (rol_ministerio IN ('integrante','lider','co-lider')),
  UNIQUE(id_ministerio, id_miembro)
);


-- ============================================================
--  6. USUARIOS
-- ============================================================

CREATE TABLE usuarios (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  email         TEXT NOT NULL UNIQUE,
  rol           TEXT NOT NULL DEFAULT 'miembro' REFERENCES roles(nombre) ON DELETE RESTRICT,
  miembro_id    INT UNIQUE REFERENCES miembros(id) ON DELETE SET NULL,
  activo        BOOLEAN DEFAULT TRUE,
  ultimo_acceso TIMESTAMPTZ
);


-- ============================================================
--  7. GRUPOS
-- ============================================================

CREATE TABLE grupos (
  id          SERIAL PRIMARY KEY,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  nombre      TEXT NOT NULL,
  lugar       TEXT,
  dia_semana  TEXT CHECK (dia_semana IN ('lunes','martes','miercoles','jueves','viernes','sabado','domingo')),
  hora        TIME,
  id_lider    INT REFERENCES miembros(id) ON DELETE SET NULL,
  estado      TEXT NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo','inactivo'))
);

CREATE TABLE grupo_miembros (
  id          SERIAL PRIMARY KEY,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  id_grupo    INT NOT NULL REFERENCES grupos(id) ON DELETE CASCADE,
  id_miembro  INT NOT NULL REFERENCES miembros(id) ON DELETE CASCADE,
  UNIQUE(id_grupo, id_miembro)
);


-- ============================================================
--  8. CURSOS
-- ============================================================

CREATE TABLE cursos (
  id          SERIAL PRIMARY KEY,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  nombre      TEXT NOT NULL,
  aula        TEXT,
  horas       INT,
  dia_semana  TEXT CHECK (dia_semana IN ('lunes','martes','miercoles','jueves','viernes','sabado','domingo')),
  hora        TIME,
  id_guia     INT REFERENCES miembros(id) ON DELETE SET NULL,
  estado      TEXT NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo','inactivo','finalizado'))
);

CREATE TABLE curso_requisitos (
  id                    SERIAL PRIMARY KEY,
  id_curso              INT NOT NULL REFERENCES cursos(id) ON DELETE CASCADE,
  id_curso_prerequisito INT REFERENCES cursos(id) ON DELETE CASCADE,
  requiere_bautismo     BOOLEAN DEFAULT FALSE,
  requiere_encuentro    BOOLEAN DEFAULT FALSE,
  UNIQUE(id_curso, id_curso_prerequisito)
);


-- ============================================================
--  9. PERIODOS DE CURSO
-- ============================================================

CREATE TABLE periodos_curso (
  id                SERIAL PRIMARY KEY,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW(),
  id_curso          INT NOT NULL REFERENCES cursos(id) ON DELETE CASCADE,
  nombre            TEXT NOT NULL,
  fecha_inicio      DATE,
  fecha_fin         DATE NOT NULL,
  total_inscritos   INT NOT NULL DEFAULT 0,
  total_completados INT NOT NULL DEFAULT 0
);


-- ============================================================
--  10. INSCRIPCIONES
-- ============================================================

CREATE TABLE inscripciones (
  id           SERIAL PRIMARY KEY,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  id_miembro   INT NOT NULL REFERENCES miembros(id) ON DELETE CASCADE,
  id_curso     INT NOT NULL REFERENCES cursos(id) ON DELETE CASCADE,
  id_periodo   INT REFERENCES periodos_curso(id) ON DELETE SET NULL,
  estado       TEXT NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo','completado','retirado')),
  fecha_inicio DATE DEFAULT CURRENT_DATE,
  fecha_fin    DATE,
  UNIQUE(id_miembro, id_curso, id_periodo)
);


-- ============================================================
--  11. ASISTENCIA
-- ============================================================

CREATE TABLE asistencia (
  id             BIGSERIAL PRIMARY KEY,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  id_miembro     INT NOT NULL REFERENCES miembros(id) ON DELETE CASCADE,
  id_grupo       INT NOT NULL REFERENCES grupos(id) ON DELETE CASCADE,
  fecha          DATE NOT NULL,
  presente       BOOLEAN NOT NULL DEFAULT FALSE,
  registrado_por INT REFERENCES miembros(id) ON DELETE SET NULL,
  UNIQUE(id_miembro, id_grupo, fecha)
);


-- ============================================================
--  12. APORTES
-- ============================================================

CREATE TABLE diezmos (
  id             BIGSERIAL PRIMARY KEY,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  id_miembro     INT NOT NULL REFERENCES miembros(id) ON DELETE CASCADE,
  monto          NUMERIC(10,2) NOT NULL CHECK (monto > 0),
  fecha          DATE NOT NULL DEFAULT CURRENT_DATE,
  observacion    TEXT,
  registrado_por UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

CREATE TABLE ofrendas (
  id             BIGSERIAL PRIMARY KEY,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  tipo           TEXT NOT NULL DEFAULT 'general' CHECK (tipo IN ('general','misionera','construccion','especial','otro')),
  monto          NUMERIC(10,2) NOT NULL CHECK (monto > 0),
  fecha          DATE NOT NULL DEFAULT CURRENT_DATE,
  descripcion    TEXT,
  registrado_por UUID REFERENCES auth.users(id) ON DELETE SET NULL
);


-- ============================================================
--  13. ÍNDICES
-- ============================================================

CREATE INDEX idx_miembros_estado             ON miembros(estado);
CREATE INDEX idx_miembros_nombre             ON miembros(nombre);
CREATE INDEX idx_usuarios_rol                ON usuarios(rol);
CREATE INDEX idx_usuarios_miembro            ON usuarios(miembro_id);
CREATE INDEX idx_grupos_lider                ON grupos(id_lider);
CREATE INDEX idx_grupo_miembros_grupo        ON grupo_miembros(id_grupo);
CREATE INDEX idx_grupo_miembros_miembro      ON grupo_miembros(id_miembro);
CREATE INDEX idx_ministerio_miembros_min     ON ministerio_miembros(id_ministerio);
CREATE INDEX idx_ministerio_miembros_mie     ON ministerio_miembros(id_miembro);
CREATE INDEX idx_asistencia_grupo_fecha      ON asistencia(id_grupo, fecha);
CREATE INDEX idx_asistencia_miembro          ON asistencia(id_miembro);
CREATE INDEX idx_inscripciones_miembro       ON inscripciones(id_miembro);
CREATE INDEX idx_inscripciones_curso         ON inscripciones(id_curso);
CREATE INDEX idx_inscripciones_periodo       ON inscripciones(id_periodo);
CREATE INDEX idx_periodos_curso_curso        ON periodos_curso(id_curso);
CREATE INDEX idx_periodos_curso_fecha        ON periodos_curso(fecha_fin);
CREATE INDEX idx_diezmos_miembro             ON diezmos(id_miembro);
CREATE INDEX idx_diezmos_fecha               ON diezmos(fecha);
CREATE INDEX idx_ofrendas_fecha              ON ofrendas(fecha);
CREATE INDEX idx_audit_log_tabla             ON audit_log(tabla, created_at);
CREATE INDEX idx_audit_log_usuario           ON audit_log(id_usuario);
CREATE INDEX idx_sesiones_usuario            ON sesiones_log(id_usuario, created_at);


-- ============================================================
--  14. FUNCIONES
-- ============================================================

CREATE OR REPLACE FUNCTION fn_audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_log (tabla, operacion, id_registro, datos_anteriores, datos_nuevos)
  VALUES (
    TG_TABLE_NAME,
    TG_OP,
    CASE TG_OP WHEN 'DELETE' THEN OLD.id::TEXT ELSE NEW.id::TEXT END,
    CASE TG_OP WHEN 'INSERT' THEN NULL ELSE row_to_json(OLD)::JSONB END,
    CASE TG_OP WHEN 'DELETE' THEN NULL ELSE row_to_json(NEW)::JSONB END
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION fn_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Función ultra-rápida: lee el rol desde el JWT, no de la tabla
CREATE OR REPLACE FUNCTION public.es_admin()
RETURNS boolean AS $$
BEGIN
  RETURN (auth.jwt() -> 'user_metadata' ->> 'rol') = 'admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Sincroniza el rol de la tabla pública hacia auth.users metadata
CREATE OR REPLACE FUNCTION public.sincronizar_rol_auth()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{rol}',
    to_jsonb(NEW.rol)
  )
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
--  15. TRIGGERS
-- ============================================================

-- Auditoría
CREATE TRIGGER trg_audit_miembros
  AFTER INSERT OR UPDATE OR DELETE ON miembros
  FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

CREATE TRIGGER trg_audit_usuarios
  AFTER INSERT OR UPDATE OR DELETE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

CREATE TRIGGER trg_audit_diezmos
  AFTER INSERT OR UPDATE OR DELETE ON diezmos
  FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

CREATE TRIGGER trg_audit_ofrendas
  AFTER INSERT OR UPDATE OR DELETE ON ofrendas
  FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

CREATE TRIGGER trg_audit_grupos
  AFTER INSERT OR UPDATE OR DELETE ON grupos
  FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

CREATE TRIGGER trg_audit_periodos_curso
  AFTER INSERT OR UPDATE OR DELETE ON periodos_curso
  FOR EACH ROW EXECUTE FUNCTION fn_audit_trigger();

-- updated_at automático
CREATE TRIGGER trg_updated_miembros
  BEFORE UPDATE ON miembros
  FOR EACH ROW EXECUTE FUNCTION fn_updated_at();

CREATE TRIGGER trg_updated_usuarios
  BEFORE UPDATE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION fn_updated_at();

CREATE TRIGGER trg_updated_grupos
  BEFORE UPDATE ON grupos
  FOR EACH ROW EXECUTE FUNCTION fn_updated_at();

CREATE TRIGGER trg_updated_cursos
  BEFORE UPDATE ON cursos
  FOR EACH ROW EXECUTE FUNCTION fn_updated_at();

CREATE TRIGGER trg_updated_ministerios
  BEFORE UPDATE ON ministerios
  FOR EACH ROW EXECUTE FUNCTION fn_updated_at();

CREATE TRIGGER trg_updated_periodos_curso
  BEFORE UPDATE ON periodos_curso
  FOR EACH ROW EXECUTE FUNCTION fn_updated_at();

-- Sincronización de rol en Auth
CREATE TRIGGER trg_sincronizar_rol
  AFTER INSERT OR UPDATE OF rol ON usuarios
  FOR EACH ROW EXECUTE FUNCTION public.sincronizar_rol_auth();


-- ============================================================
--  16. ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE miembros            ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios            ENABLE ROW LEVEL SECURITY;
ALTER TABLE grupos              ENABLE ROW LEVEL SECURITY;
ALTER TABLE grupo_miembros      ENABLE ROW LEVEL SECURITY;
ALTER TABLE cursos              ENABLE ROW LEVEL SECURITY;
ALTER TABLE periodos_curso      ENABLE ROW LEVEL SECURITY;
ALTER TABLE inscripciones       ENABLE ROW LEVEL SECURITY;
ALTER TABLE asistencia          ENABLE ROW LEVEL SECURITY;
ALTER TABLE diezmos             ENABLE ROW LEVEL SECURITY;
ALTER TABLE ofrendas            ENABLE ROW LEVEL SECURITY;
ALTER TABLE ministerios         ENABLE ROW LEVEL SECURITY;
ALTER TABLE ministerio_miembros ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log           ENABLE ROW LEVEL SECURITY;

-- USUARIOS
CREATE POLICY "usuarios_self_select" ON usuarios
  FOR SELECT TO authenticated USING (id = auth.uid());

CREATE POLICY "usuarios_admin_manage" ON usuarios
  FOR ALL TO authenticated USING (es_admin());

CREATE POLICY "service_role_insert" ON usuarios
  FOR INSERT TO service_role WITH CHECK (true);

-- MIEMBROS
CREATE POLICY "miembros_select_logic" ON miembros
  FOR SELECT TO authenticated
  USING (
    es_admin()
    OR (auth.jwt() -> 'user_metadata' ->> 'rol') = 'pastor'
    OR id IN (SELECT miembro_id FROM usuarios WHERE id = auth.uid())
  );

CREATE POLICY "miembros_admin_all" ON miembros
  FOR ALL TO authenticated USING (es_admin());

CREATE POLICY "lider_edita_miembros_grupo" ON miembros
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM grupo_miembros gm
      JOIN grupos g ON g.id = gm.id_grupo
      JOIN usuarios u ON u.miembro_id = g.id_lider
      WHERE gm.id_miembro = miembros.id AND u.id = auth.uid()
    )
  );

-- GRUPOS
CREATE POLICY "grupos_read_logic" ON grupos
  FOR SELECT TO authenticated
  USING (
    es_admin()
    OR (auth.jwt() -> 'user_metadata' ->> 'rol') = 'pastor'
    OR id_lider IN (SELECT miembro_id FROM usuarios WHERE id = auth.uid())
  );

CREATE POLICY "admin_todo_grupos" ON grupos
  FOR ALL TO authenticated USING (es_admin());

-- GRUPO MIEMBROS
CREATE POLICY "admin_todo_grupo_miembros" ON grupo_miembros
  FOR ALL TO authenticated USING (es_admin());

CREATE POLICY "Líderes pueden ver sus miembros" ON grupo_miembros
  FOR SELECT TO authenticated
  USING (
    id_grupo IN (
      SELECT id FROM grupos
      WHERE id_lider = (
        SELECT miembro_id FROM usuarios WHERE id = auth.uid()
      )
    )
  );

CREATE POLICY "lider_gestiona_su_grupo_miembros" ON grupo_miembros
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM grupos g
      JOIN usuarios u ON u.miembro_id = g.id_lider
      WHERE g.id = id_grupo AND u.id = auth.uid()
    )
  );

-- CURSOS
CREATE POLICY "admin_pastor_todo_cursos" ON cursos
  FOR ALL TO authenticated
  USING (
    es_admin()
    OR (auth.jwt() -> 'user_metadata' ->> 'rol') = 'pastor'
  );

CREATE POLICY "todos_ven_cursos" ON cursos
  FOR SELECT TO authenticated USING (true);

-- PERIODOS DE CURSO
CREATE POLICY "admin_pastor_todo_periodos" ON periodos_curso
  FOR ALL TO authenticated
  USING (
    es_admin()
    OR (auth.jwt() -> 'user_metadata' ->> 'rol') = 'pastor'
  );

CREATE POLICY "todos_ven_periodos" ON periodos_curso
  FOR SELECT TO authenticated USING (true);

-- INSCRIPCIONES
CREATE POLICY "admin_todo_inscripciones" ON inscripciones
  FOR ALL TO authenticated USING (es_admin());

CREATE POLICY "miembro_sus_inscripciones" ON inscripciones
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM usuarios WHERE id = auth.uid() AND miembro_id = id_miembro)
  );

-- ASISTENCIA
CREATE POLICY "admin_todo_asistencia" ON asistencia
  FOR ALL TO authenticated USING (es_admin());

CREATE POLICY "lider_gestiona_asistencia_grupo" ON asistencia
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM grupos g
      JOIN usuarios u ON u.miembro_id = g.id_lider
      WHERE g.id = id_grupo AND u.id = auth.uid()
    )
  );

CREATE POLICY "pastor_ve_asistencia" ON asistencia
  FOR SELECT TO authenticated
  USING (
    (auth.jwt() -> 'user_metadata' ->> 'rol') = 'pastor'
  );

-- DIEZMOS Y OFRENDAS
CREATE POLICY "finanzas_access" ON diezmos
  FOR ALL TO authenticated
  USING (
    es_admin()
    OR (auth.jwt() -> 'user_metadata' ->> 'rol') IN ('finanzas', 'pastor')
  );

CREATE POLICY "finanzas_ofrendas_access" ON ofrendas
  FOR ALL TO authenticated
  USING (
    es_admin()
    OR (auth.jwt() -> 'user_metadata' ->> 'rol') IN ('finanzas', 'pastor')
  );

-- MINISTERIOS
CREATE POLICY "admin_todo_ministerios" ON ministerios
  FOR ALL TO authenticated USING (es_admin());

CREATE POLICY "todos_ven_ministerios" ON ministerios
  FOR SELECT TO authenticated USING (auth.uid() IS NOT NULL);

CREATE POLICY "admin_todo_ministerio_miembros" ON ministerio_miembros
  FOR ALL TO authenticated USING (es_admin());

CREATE POLICY "todos_ven_ministerio_miembros" ON ministerio_miembros
  FOR SELECT TO authenticated USING (auth.uid() IS NOT NULL);

-- AUDIT LOG
CREATE POLICY "admin_ve_audit" ON audit_log
  FOR SELECT TO authenticated USING (es_admin());


-- ============================================================
--  17. SINCRONIZACIÓN MASIVA INICIAL DE ROLES EN AUTH
-- ============================================================

DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT id, rol FROM public.usuarios LOOP
    UPDATE auth.users
    SET raw_user_meta_data = jsonb_build_object('rol', r.rol)
    WHERE id = r.id;
  END LOOP;
END $$;


-- ============================================================
--  EDGE FUNCTION: create-user
--  (Guardar como supabase/functions/create-user/index.ts)
-- ============================================================
/*
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { email, password, rol, miembro_id } = await req.json();

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { data, error } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { rol },
    });

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { error: dbError } = await supabaseAdmin.from("usuarios").insert({
      id: data.user.id,
      email,
      rol,
      activo: true,
      ...(miembro_id ? { miembro_id } : {}),
    });

    if (dbError) {
      return new Response(JSON.stringify({ error: dbError.message }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
*/
