import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/session.dart';
import '../../../../shared/widgets/sigmar_page.dart';

export 'admin_miembros_screen.dart';
export 'admin_grupos_screen.dart';
export 'admin_cursos_screen.dart';
export 'admin_usuarios_screen.dart';
export 'registro_usuario_screen.dart';
export 'admin_aportes_screen.dart';
export 'perfil_screen.dart';
export '../../../lider/presentation/screens/lider_screens.dart';

class _PantallaModulo extends StatelessWidget {
  final String ruta, titulo, subtitulo;
  final IconData icono;
  final Color color;

  const _PantallaModulo({
    required this.ruta,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
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
                Expanded(
                  child: Column(
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
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${AppSession.nombre} • ${AppSession.rol.toUpperCase()}',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Center(
              child: Text(
                'Módulo en desarrollo',
                style: TextStyle(color: kGrey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InscripcionScreen extends StatelessWidget {
  const InscripcionScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PantallaModulo(
    ruta: '/miembro/inscripcion',
    titulo: 'Inscripción',
    subtitulo: 'Ver cursos disponibles e inscribirse',
    icono: Icons.school,
    color: Colors.green,
  );
}

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PantallaModulo(
    ruta: '/pastor/reportes',
    titulo: 'Reportes',
    subtitulo: 'Reportes generales de la iglesia',
    icono: Icons.bar_chart,
    color: Colors.orange,
  );
}

class GuiasScreen extends StatelessWidget {
  const GuiasScreen({super.key});
  @override
  Widget build(BuildContext context) => const _PantallaModulo(
    ruta: '/pastor/guias',
    titulo: 'Guías',
    subtitulo: 'Asignar guías a cursos',
    icono: Icons.assignment,
    color: Colors.orange,
  );
}
