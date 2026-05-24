import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_layout.dart';
import '../../../../core/session.dart';
import '../../../../shared/widgets/dashboard_shell.dart';

class LiderDashboardScreen extends StatelessWidget {
  const LiderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.of(context).size.width < kMobileBreakpoint;
    const Color kColor = Color(0xFF378ADD);

    return DashboardPage(
      rutaActual: '/lider',
      conScroll: false,
      child: Padding(
        padding: EdgeInsets.all(movil ? kMobilePadding : kDesktopPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: movil ? 42 : 52,
                  height: movil ? 42 : 52,
                  decoration: BoxDecoration(
                    color: kColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.group_outlined,
                    color: kColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gestión de Grupo',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Bienvenido, ${AppSession.nombre}',
                        style: const TextStyle(color: kGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 50, height: 3, color: kColor),
            const SizedBox(height: 20),
            // Quick access cards
            movil
                ? Column(
                    children: [
                      _buildQuickCard(
                        icon: Icons.home,
                        label: 'Inicio',
                        description: 'Página principal de líder',
                        onTap: () {},
                        color: kColor,
                      ),
                      const SizedBox(height: 16),
                      _buildQuickCard(
                        icon: Icons.group,
                        label: 'Mi Grupo',
                        description: 'Ver y gestionar mi grupo',
                        onTap: () => Navigator.pushNamed(context, '/lider/grupo'),
                        color: kColor,
                      ),
                      const SizedBox(height: 16),
                      _buildQuickCard(
                        icon: Icons.person,
                        label: 'Mi Perfil',
                        description: 'Editar mis datos personales',
                        onTap: () => Navigator.pushNamed(context, '/perfil'),
                        color: kColor,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildQuickCard(
                          icon: Icons.home,
                          label: 'Inicio',
                          description: 'Página principal de líder',
                          onTap: () {},
                          color: kColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildQuickCard(
                          icon: Icons.group,
                          label: 'Mi Grupo',
                          description: 'Ver y gestionar mi grupo',
                          onTap: () => Navigator.pushNamed(context, '/lider/grupo'),
                          color: kColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildQuickCard(
                          icon: Icons.person,
                          label: 'Mi Perfil',
                          description: 'Editar mis datos personales',
                          onTap: () => Navigator.pushNamed(context, '/perfil'),
                          color: kColor,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCard({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kWhite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: kGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}