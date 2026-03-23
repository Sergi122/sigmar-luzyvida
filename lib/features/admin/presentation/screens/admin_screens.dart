import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/session.dart';
import '../../../../shared/widgets/sigmar_page.dart';
import 'admin_miembros_screen.dart';

// ══════════════════════════════════════════════════════
//  WIDGET BASE para pantallas de modulo
// ══════════════════════════════════════════════════════
class _PantallaModulo extends StatelessWidget {
  final String ruta, titulo, subtitulo;
  final IconData icono;
  final Color color;
  final List<String> acciones;
  final List<VoidCallback?> onAcciones;

  const _PantallaModulo({
    required this.ruta,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    this.acciones = const [],
    this.onAcciones = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SigmarPage(
      rutaActual: ruta,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icono, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: const TextStyle(color: kGrey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 50, height: 3, color: color),
            const SizedBox(height: 32),

            // Quien esta usando esto
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: color, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${AppSession.nombre} • ${AppSession.rol.toUpperCase()}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Acciones
            if (acciones.isNotEmpty) ...[
              const Text(
                'ACCIONES DISPONIBLES',
                style: TextStyle(color: kGrey, fontSize: 11, letterSpacing: 2),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(acciones.length, (i) {
                  final cb = i < onAcciones.length ? onAcciones[i] : null;
                  return OutlinedButton.icon(
                    onPressed: cb,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.chevron_right, size: 15),
                    label: Text(
                      acciones[i],
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
            ],

            // En construccion
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kDivider),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.construction_outlined,
                    color: kGold,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'En construccion',
                          style: TextStyle(
                            color: kWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Implementar logica de "$titulo" aqui con Supabase',
                          style: const TextStyle(color: kGrey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  MIEMBRO
// ══════════════════════════════════════════════════════
class InscripcionScreen extends StatelessWidget {
  const InscripcionScreen({super.key});
  @override
  Widget build(BuildContext context) => _PantallaModulo(
    ruta: '/miembro/inscripcion',
    titulo: 'Inscripcion a Curso',
    subtitulo: 'Ver cursos disponibles e inscribirse',
    icono: Icons.school_outlined,
    color: const Color(0xFF1D9E75),
    acciones: const ['Ver cursos disponibles', 'Mis inscripciones'],
    onAcciones: [null, null],
  );
}

// ══════════════════════════════════════════════════════
//  LIDER
// ══════════════════════════════════════════════════════
class MiGrupoScreen extends StatelessWidget {
  const MiGrupoScreen({super.key});
  @override
  Widget build(BuildContext context) => _PantallaModulo(
    ruta: '/lider/grupo',
    titulo: 'Mi Grupo',
    subtitulo: 'Gestionar tu grupo de reunion',
    icono: Icons.group_outlined,
    color: const Color(0xFF378ADD),
    acciones: const [
      'Ver lista de miembros',
      'Tomar asistencia hoy',
      'Ver historial de asistencia',
      'Agregar miembro',
    ],
    onAcciones: [null, null, null, null],
  );
}

// ══════════════════════════════════════════════════════
//  PASTOR
// ══════════════════════════════════════════════════════
class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});
  @override
  Widget build(BuildContext context) => _PantallaModulo(
    ruta: '/pastor/reportes',
    titulo: 'Reportes',
    subtitulo: 'Reportes generales de la iglesia',
    icono: Icons.bar_chart_outlined,
    color: const Color(0xFFBA7517),
    acciones: const [
      'Reporte de miembros',
      'Reporte de asistencia',
      'Reporte de aportes',
      'Reporte de cursos',
      'Exportar a PDF',
    ],
    onAcciones: [null, null, null, null, null],
  );
}

class GuiasScreen extends StatelessWidget {
  const GuiasScreen({super.key});
  @override
  Widget build(BuildContext context) => _PantallaModulo(
    ruta: '/pastor/guias',
    titulo: 'Asignar Guias',
    subtitulo: 'Designar miembros como guias de curso',
    icono: Icons.assignment_ind_outlined,
    color: const Color(0xFFBA7517),
    acciones: const [
      'Ver cursos sin guia',
      'Asignar guia a curso',
      'Ver lista de guias',
    ],
    onAcciones: [null, null, null],
  );
}

// ══════════════════════════════════════════════════════
//  ADMIN
// ══════════════════════════════════════════════════════

class AdminGruposScreen extends StatelessWidget {
  const AdminGruposScreen({super.key});
  @override
  Widget build(BuildContext context) => _PantallaModulo(
    ruta: '/admin/grupos',
    titulo: 'Gestion de Grupos',
    subtitulo: 'Administrar grupos de reunion',
    icono: Icons.group_outlined,
    color: const Color(0xFF7F77DD),
    acciones: const [
      'Ver lista de grupos',
      'Crear nuevo grupo',
      'Asignar lider',
      'Agregar miembros',
      'Editar / Eliminar grupo',
    ],
    onAcciones: [null, null, null, null, null],
  );
}

class AdminCursosScreen extends StatelessWidget {
  const AdminCursosScreen({super.key});
  @override
  Widget build(BuildContext context) => _PantallaModulo(
    ruta: '/admin/cursos',
    titulo: 'Gestion de Cursos',
    subtitulo: 'Administrar cursos y aulas',
    icono: Icons.school_outlined,
    color: const Color(0xFF7F77DD),
    acciones: const [
      'Ver lista de cursos',
      'Crear nuevo curso',
      'Asignar guia al curso',
      'Agregar miembros al curso',
      'Editar / Eliminar curso',
    ],
    onAcciones: [
      null,
      null,
      null,
      // ✅ UNICO botón que navega a AdminMiembrosScreen
      () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminMiembrosScreen()),
      ),
      null,
    ],
  );
}

class AdminUsuariosScreen extends StatelessWidget {
  const AdminUsuariosScreen({super.key});
  @override
  Widget build(BuildContext context) => _PantallaModulo(
    ruta: '/admin/usuarios',
    titulo: 'Gestion de Usuarios',
    subtitulo: 'Crear accesos al sistema SIGMAR',
    icono: Icons.manage_accounts_outlined,
    color: const Color(0xFF7F77DD),
    acciones: const [
      'Ver lista de usuarios',
      'Crear usuario (email, contrasena y rol)',
      'Cambiar rol de usuario',
      'Activar / Desactivar usuario',
    ],
    onAcciones: [null, null, null, null],
  );
}

class AdminAportesScreen extends StatelessWidget {
  const AdminAportesScreen({super.key});
  @override
  Widget build(BuildContext context) => _PantallaModulo(
    ruta: '/admin/aportes',
    titulo: 'Gestion de Aportes',
    subtitulo: 'Ofrendas y diezmos de la iglesia',
    icono: Icons.attach_money_outlined,
    color: const Color(0xFF7F77DD),
    acciones: const [
      'Ver aportes del dia',
      'Registrar ofrenda',
      'Registrar diezmo',
      'Modificar aporte',
      'Buscar por fecha',
    ],
    onAcciones: [null, null, null, null, null],
  );
}

// ══════════════════════════════════════════════════════
//  PERFIL — compartido todos los roles
// ══════════════════════════════════════════════════════
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});
  @override
  Widget build(BuildContext context) => _PantallaModulo(
    ruta: '/perfil',
    titulo: 'Mi Perfil',
    subtitulo: 'Ver y editar mis datos personales',
    icono: Icons.person_outline,
    color: kGold,
    acciones: const ['Editar datos personales', 'Cambiar contrasena'],
    onAcciones: [null, null],
  );
}
