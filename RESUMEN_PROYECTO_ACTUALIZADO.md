# SIGMAR — Sistema de Gestión Iglesia Luz y Vida
## Resumen Actualizado del Proyecto
**Fecha:** 2026-05-23 | **Versión SIGMAR:** 1.0 | **Auditado por:** Claude Code

---

## 1. STACK TECNOLÓGICO

| Capa | Tecnología |
|---|---|
| Framework | Flutter ^3.x (Dart SDK ^3.11.3) |
| Backend | Supabase (PostgreSQL + Auth + Storage + Edge Functions) |
| State Management | Sin gestión de estado formal — `setState` directo |
| Arquitectura | Feature-first (sin BLoC/Riverpod/Provider) |
| Navegación | Named routes (`MaterialApp.routes`) |
| Gráficos | `fl_chart ^1.2.0` |
| PDF | `pdf ^3.11.1` + `printing ^5.14.3` |
| Imágenes | `image_picker ^1.2.2` + Supabase Storage |
| Fuentes | `google_fonts ^8.1.0` |
| Internacionalización | `intl ^0.20.2` |
| Preferencias | `shared_preferences ^2.5.5` |

---

## 2. ARQUITECTURA

```
lib/
├── main.dart                    # Entry point, inicializa Supabase + AppSession
├── app.dart                     # MaterialApp, 21 rutas nombradas
├── core/
│   ├── session.dart             # AppSession (static, SharedPreferences)
│   └── constants/
│       ├── app_colors.dart      # 11 colores globales (kBg, kGold, kDanger...)
│       └── app_layout.dart      # Breakpoints y paddings responsivos
├── shared/widgets/
│   ├── sigmar_page.dart         # Layout base público (navbar + scroll + footer)
│   ├── dashboard_shell.dart     # Shell autenticado (sidebar/drawer + topbar)
│   ├── sigmar_navbar.dart       # Navbar responsive con menú por rol
│   └── sigmar_footer.dart       # Footer con info iglesia y redes
└── features/
    ├── auth/                    # Login (Supabase Auth + redirección por rol)
    ├── home/                    # Página principal pública con ministerios
    ├── sobre/                   # "Quiénes somos" con Google Maps
    ├── miembro/                 # Dashboard miembro + inscripción a cursos
    ├── lider/                   # Dashboard líder + gestión de grupo + asistencia
    ├── pastor/                  # Miembros, grupos, cursos, asistencia, aportes (read)
    ├── admin/                   # CRUD completo: miembros, usuarios, grupos, cursos,
    │                            #   ministerios, aportes + gestión períodos
    └── finanzas/                # Dashboard finanzas (vista de aportes)
```

---

## 3. BASE DE DATOS SUPABASE

### Tablas principales
| Tabla | Descripción | Relaciones clave |
|---|---|---|
| `usuarios` | Usuarios del sistema (FK → auth.users) | `miembro_id → miembros.id` |
| `miembros` | Feligreses de la iglesia | — |
| `grupos` | Grupos celulares | `id_lider → miembros.id` |
| `grupo_miembros` | Relación N:M grupos-miembros | `id_grupo`, `id_miembro` |
| `cursos` | Cursos permanentes | `id_guia → miembros.id` |
| `curso_requisitos` | Prerrequisitos de cursos | `id_curso`, `id_curso_prerequisito` |
| `periodos_curso` | Snapshots históricos de cursos | `id_curso → cursos.id` |
| `inscripciones` | Inscripciones a cursos | `id_miembro`, `id_curso`, `id_periodo` |
| `asistencia` | Asistencia grupal | `id_grupo`, `id_miembro`, `fecha` UNIQUE |
| `ministerios` | Ministerios de la iglesia | — |
| `ministerio_miembros` | Miembros por ministerio con rol | `id_ministerio`, `id_miembro` |
| `diezmos` | Diezmos individuales | `id_miembro → miembros.id` |
| `ofrendas` | Ofrendas generales | Tipos: general/misionera/construccion/especial/otro |
| `roles` | Tabla de roles del sistema | — |
| `permisos` | Permisos por rol | `id_rol → roles.id` |
| `audit_log` | Log de auditoría automático | Triggers en miembros, usuarios, diezmos, ofrendas, grupos |

### Seguridad (RLS)
- RLS activo en todas las tablas principales
- Función `es_admin()` lee rol desde JWT (sin query a DB = rápido)
- Trigger `trg_sincronizar_rol` mantiene `auth.users.user_metadata.rol` sincronizado
- Políticas granulares por rol (admin, pastor, lider, miembro, finanzas)

### Índices
- 20 índices creados para queries frecuentes
- Cubren: `miembros(estado, nombre)`, `asistencia(id_grupo, fecha)`, `inscripciones(id_periodo)`, `diezmos(fecha)`, etc.

### ✅ Columnas verificadas vía REST API (2026-05-23)
`precio_curso` y `precio_libro` **SÍ existen** en la tabla `cursos` real de Supabase. El archivo `sigmar_schema_completo.sql` simplemente está desactualizado — le faltan esas dos columnas. El código Dart es correcto.

---

## 4. FUNCIONALIDADES IMPLEMENTADAS

### Públicas (sin login)
- [x] Página principal con sliders de ministerios
- [x] "Quiénes Somos" con historia, pastores, valores, Google Maps (web)
- [x] Login con redirección por rol

### Miembro
- [x] Dashboard con acceso rápido
- [x] Inscripción/desinscripción a cursos (con verificación de requisitos)
- [x] Ver mis cursos activos y completados
- [x] Editar perfil personal + foto

### Líder
- [x] Dashboard de grupo
- [x] Ver miembros del grupo celular
- [x] Tomar asistencia
- [x] Ver historial de asistencia del grupo

### Pastor (solo lectura + reportes)
- [x] Ver todos los miembros
- [x] Ver todos los grupos
- [x] Ver todos los cursos con inscritos
- [x] Reporte de asistencia con gráfico PieChart + exportar PDF
- [x] Reporte de aportes (diezmos/ofrendas) con gráficos + exportar PDF

### Admin (CRUD completo)
- [x] Gestión de miembros (crear, editar, cambiar estado, eliminar + foto en Storage)
- [x] Gestión de usuarios (crear via Edge Function, editar rol, activar/desactivar)
- [x] Gestión de grupos + asignación de miembros
- [x] Gestión de cursos + prerequisitos + precios
  - Gestión de inscritos por período activo
  - Cerrar período (snapshot histórico)
  - Ver historial de períodos
- [x] Gestión de ministerios + roles por ministerio
- [x] Registro de diezmos y ofrendas

### Finanzas
- [x] Dashboard (acceso a aportes)
- [x] Vista de diezmos y ofrendas (ruta `/finanzas/aportes`)

---

## 5. PROBLEMAS ENCONTRADOS Y SOLUCIONADOS EN ESTA AUDITORÍA

### 🔴 Críticos corregidos

| # | Problema | Archivo | Solución |
|---|---|---|---|
| 1 | Ruta `/admin/usuarios` inexistente en app.dart | `app.dart`, `admin_screens.dart` | Añadida ruta + export de `AdminUsuariosScreen` |
| 2 | Rutas `/finanzas/diezmos` y `/finanzas/ofrendas` en navbar → no existen | `sigmar_navbar.dart` | Cambiado a `/finanzas/aportes` |
| 3 | N+1 queries en `_finalizarPeriodo` (1 query por inscrito) | `admin_cursos_screen.dart` | Reemplazado por batch `.inFilter('id', ids)` |
| 4 | `_DialogHistorial._cargar()` sin try-catch (crash en error de red) | `admin_cursos_screen.dart` | Añadido try-catch + `if (mounted)` |
| 5 | `FinanzasDashboardScreen.onMenuTap` vacío (navegación no funciona) | `finanzas_dashboard_screen.dart` | Implementada navegación por índice |
| 6 | `use_build_context_synchronously` en mi_grupo_screen.dart | `mi_grupo_screen.dart` | Corregido a `if (!mounted) return;` |

### 🟡 Importantes corregidos

| # | Problema | Archivo | Solución |
|---|---|---|---|
| 7 | `_cambiarEstado` sin try-catch + lógica visita→activo incorrecta | `admin_miembros_screen.dart` | Añadido try-catch + respeta estado 'visita' |
| 8 | `_eliminar` miembro sin try-catch en la query principal | `admin_miembros_screen.dart` | Envuelto en try-catch con mensaje de error |
| 9 | `_toggleActivo` sin try-catch | `admin_usuarios_screen.dart` | Añadido try-catch con SnackBar de error |

### 🟢 Mejoras aplicadas

| # | Problema | Archivo | Solución |
|---|---|---|---|
| 10 | `withOpacity` deprecated (7 ocurrencias) | `inicio_screen.dart`, `sigmar_navbar.dart`, `sigmar_footer.dart` | Reemplazado por `.withValues(alpha:)` |
| 11 | Typo "Gestion" → "Gestión" | `admin_usuarios_screen.dart` | Corregido |
| 12 | `_kColor` con leading underscore en variable local | `lider_dashboard_screen.dart`, `miembro_screens.dart` | Renombrado a `kColor` |
| 13 | `_MapaIframe()` sin `const` en clase `@immutable` | `sobre_screen.dart` | Añadido `const` al constructor |

---

## 6. DEUDA TÉCNICA PENDIENTE

### 🔴 Alta prioridad

1. ~~Verificar columnas `precio_curso` / `precio_libro`~~ — **RESUELTO**: confirmado vía REST API que existen en la DB. Solo faltaban en el archivo SQL local.

2. **AnonKey y URL expuestas en main.dart** — `sb_publishable_qI7702sYFZuEZZbgQqOlSg_L8zbxHYn` está hardcodeada. Para Flutter web (código visible al usuario) es una práctica cuestionable aunque Supabase las diseña como "publishable". Considerar usar `--dart-define` o `.env` para separar por ambiente (dev/prod).

3. **Sin guards de autenticación en rutas protegidas** — Las rutas `/admin`, `/pastor`, `/lider`, `/miembro`, `/finanzas` no verifican si hay sesión activa. Si un usuario accede directamente por URL sin sesión, Supabase RLS rechazará las queries pero la UX será mala (pantalla en blanco o error). Implementar un `AuthGuard` widget.

### 🟡 Prioridad media

4. **`dart:html` deprecated** en `sobre_screen.dart` (Google Maps) — Debe migrarse a `package:web` + `dart:js_interop` para compatibilidad futura con Flutter web. Es un refactor no trivial del iframe.

5. **`_buildQuickCard` duplicado** en 3 dashboards (`FinanzasDashboardScreen`, `LiderDashboardScreen`, `MiembroDashboardScreen`) — Extraer a `shared/widgets/`.

6. **`_FutureBuilder` sin caché en historial de períodos** — Cada expand/collapse de un período hace una nueva query. Cachear con un `Map<int, List>`.

7. **`admin_miembros_screen.dart` usa `use_null_aware_elements`** — Línea 995: `if (fotoUrl != null) 'foto_url': fotoUrl` puede reescribirse con `?` para mayor claridad.

8. **Sin `AdminUsuariosScreen` en la navbar del admin** — El componente `sigmar_navbar.dart` case 'admin' no incluye la ruta `/admin/usuarios` en el menú de navegación (aunque la ruta ya existe en app.dart). Si se quiere acceder desde la navbar, hay que añadirla.

### 🟢 Mejoras futuras

9. **Strings hardcodeados en español** — Todo el texto UI está hardcodeado. No hay `l10n`. Aceptable para una app single-language pero limita futura expansión.

10. **`miembro_id` es UNIQUE en `usuarios`** (schema SQL) — Un miembro solo puede tener un usuario. Si se necesita múltiples roles para un miembro, esto es una limitación.

11. **`hora` en `cursos` y `grupos` es `TIME` en SQL** pero el código la trata como `String`. No hay `TimePickerDialog`. El usuario debe escribir "18:00" manualmente.

12. **`precio_curso`/`precio_libro` en `cursos` son opcionales pero se guardan como `0` cuando vacío** — Semánticamente es mejor guardarlos como `null`. Cambiar `?? 0` por `?? null`.

---

## 7. ESTADO DEL ANALIZADOR

| Métrica | Antes auditoría | Después auditoría |
|---|---|---|
| Issues totales | 30 | 14 |
| Errores | 0 | 0 |
| Warnings | 0 | 0 |
| Info (all) | 30 | 14 |
| `deprecated_member_use` | 10 | 2 (dart:html en sobre_screen) |
| `use_build_context_synchronously` | 1 | 0 |
| `no_leading_underscores` | 2 | 0 |
| `prefer_const_constructors` | 1 | 0 |

Los 14 info restantes son: `unnecessary_underscores` en callbacks `(_, __)` (cosmético, no funcional) y las 2 advertencias de `dart:html` que requieren refactor mayor.

---

## 8. ROLES Y RUTAS

| Rol | Ruta inicio | Acceso |
|---|---|---|
| `admin` | `/admin` | CRUD total |
| `pastor` | `/pastor` | Lectura + reportes |
| `lider` | `/lider` | Su grupo + asistencia |
| `miembro` | `/miembro` | Sus cursos + perfil |
| `finanzas` | `/finanzas` | Vista de aportes |

---

*Generado por Claude Code — Auditoría 2026-05-23*
