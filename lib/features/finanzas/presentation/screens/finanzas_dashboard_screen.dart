import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/session.dart';
import '../../../../shared/widgets/dashboard_shell.dart';

class FinanzasDashboardScreen extends StatelessWidget {
  const FinanzasDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.of(context).size.width < 600;

    return DashboardShell(
      nombreUsuario: AppSession.nombre,
      rol: 'finanzas',
      menuItems: [
        MenuItemData(label: 'Inicio', icono: Icons.home, ruta: '/finanzas'),
        MenuItemData(label: 'Diezmos y Ofrendas', icono: Icons.monetization_on, ruta: '/finanzas/aportes'),
      ],
      indiceActivo: 0,
      onMenuTap: (index) {
        // Navigation logic would go here
      },
      body: Padding(
        padding: EdgeInsets.all(movil ? 14 : 28),
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
                    color: kGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: kGold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gestión Financiera',
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
            Container(width: 50, height: 3, color: kGold),
            const SizedBox(height: 20),
            // Quick access cards
            Row(
              children: [
                Expanded(
                  child: _buildQuickCard(
                    icon: Icons.home,
                    label: 'Inicio',
                    description: 'Página principal de finanzas',
                    onTap: () {},
                    color: kGold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickCard(
                    icon: Icons.monetization_on,
                    label: 'Diezmos y Ofrendas',
                    description: 'Ver y gestionar aportes',
                    onTap: () {},
                    color: kGold,
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