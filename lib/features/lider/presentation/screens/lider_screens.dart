import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sigmar_page.dart';

class MiGrupoScreen extends StatelessWidget {
  const MiGrupoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SigmarPage(
      rutaActual: '/lider/grupo',
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
                    color: const Color(0xFF378ADD).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.group_outlined,
                    color: Color(0xFF378ADD),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mi Grupo',
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Gestionar tu grupo de reunión',
                      style: TextStyle(color: kGrey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 50, height: 3, color: const Color(0xFF378ADD)),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Módulo en desarrollo',
                style: TextStyle(color: kGrey, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
