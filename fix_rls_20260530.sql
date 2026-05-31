-- ============================================================
--  SIGMAR — FIX RLS 2026-05-30
--  Ejecutar en: Supabase Dashboard → SQL Editor
-- ============================================================

-- ─── FIX 1: es_admin() robusto ───────────────────────────────
-- Problema: sólo leía el JWT. Si el JWT es stale (emitido antes
-- de sincronizar user_metadata), devuelve false → 42501 en INSERT.
-- Solución: JWT primero; si falla, consulta directa a usuarios.
-- SECURITY DEFINER + postgres propietario → bypassea RLS en usuarios.
CREATE OR REPLACE FUNCTION public.es_admin()
RETURNS boolean AS $$
BEGIN
  RETURN (
    (auth.jwt() -> 'user_metadata' ->> 'rol') = 'admin'
    OR EXISTS (
      SELECT 1 FROM public.usuarios
      WHERE id = auth.uid() AND rol = 'admin' AND activo = true
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- ─── FIX 2: cursos — WITH CHECK explícito para INSERT/UPDATE ──
DROP POLICY IF EXISTS "admin_pastor_todo_cursos" ON public.cursos;
CREATE POLICY "admin_pastor_todo_cursos" ON public.cursos
  FOR ALL TO authenticated
  USING (
    es_admin()
    OR (auth.jwt() -> 'user_metadata' ->> 'rol') = 'pastor'
  )
  WITH CHECK (
    es_admin()
    OR (auth.jwt() -> 'user_metadata' ->> 'rol') = 'pastor'
  );


-- ─── FIX 3: grupos — WITH CHECK explícito para INSERT/UPDATE ──
DROP POLICY IF EXISTS "admin_todo_grupos" ON public.grupos;
CREATE POLICY "admin_todo_grupos" ON public.grupos
  FOR ALL TO authenticated
  USING   (es_admin())
  WITH CHECK (es_admin());


-- ─── FIX 4: diezmos — miembro puede ver sus propios aportes ───
DROP POLICY IF EXISTS "miembro_sus_diezmos" ON public.diezmos;
CREATE POLICY "miembro_sus_diezmos" ON public.diezmos
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios
      WHERE id = auth.uid() AND miembro_id = diezmos.id_miembro
    )
  );
