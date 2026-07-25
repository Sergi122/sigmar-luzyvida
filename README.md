# SIGMAR — Sistema de Gestión Iglesia Luz y Vida

Sistema de gestión integral para una iglesia, construido con Flutter y Supabase. Cubre miembros, grupos celulares, cursos, asistencia, ministerios y finanzas (diezmos/ofrendas), con control de acceso por rol.

## Stack

| Capa | Tecnología |
|---|---|
| Framework | Flutter (Dart) |
| Backend | Supabase (PostgreSQL + Auth + Storage + Edge Functions) |
| Gráficos | fl_chart |
| Reportes PDF | pdf + printing |
| Navegación | Named routes |

## Roles y funcionalidades

- **Público** — página principal, "Quiénes somos" con mapa, login
- **Miembro** — dashboard, inscripción a cursos, historial, edición de perfil
- **Líder** — gestión de grupo celular y toma de asistencia
- **Pastor** — vista global de miembros/grupos/cursos, reportes con gráficos y exportación a PDF
- **Admin** — CRUD completo: miembros, usuarios, grupos, cursos (con prerrequisitos y períodos), ministerios, diezmos y ofrendas
- **Finanzas** — dashboard y vista de aportes

## Base de datos

PostgreSQL vía Supabase con Row Level Security activo en todas las tablas principales (`miembros`, `grupos`, `cursos`, `inscripciones`, `asistencia`, `ministerios`, `diezmos`, `ofrendas`, `roles`, `permisos`, `audit_log`), control de acceso por rol vía JWT y triggers de auditoría.

## Arquitectura

```
lib/
├── main.dart                # Entry point, inicializa Supabase
├── app.dart                 # Rutas nombradas
├── core/                    # Sesión y constantes (colores, layout)
├── shared/widgets/          # Layout base, navbar, footer, dashboard shell
└── features/                # auth, home, sobre, miembro, lider, pastor, admin, finanzas
```

Arquitectura feature-first, sin gestor de estado formal (`setState` directo).

## Ejecutar el proyecto

```bash
flutter pub get
flutter run
```

Requiere configurar las credenciales de Supabase (URL + anon key) del proyecto.
