import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'sigmar_navbar.dart';
import 'sigmar_footer.dart';

/// Layout base para TODAS las pantallas — invitados y autenticados.
/// Navbar arriba, footer abajo, contenido en el medio.
class SigmarPage extends StatelessWidget {
  final String rutaActual;
  final Widget child;
  final bool mostrarFooter;

  const SigmarPage({
    super.key,
    required this.rutaActual,
    required this.child,
    this.mostrarFooter = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          SigmarNavbar(rutaActual: rutaActual),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [child, if (mostrarFooter) const SigmarFooter()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
