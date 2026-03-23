import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'features/home/presentation/screens/inicio_screen.dart';
import 'features/sobre/presentation/screens/sobre_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/miembro/presentation/screens/miembro_screens.dart';
import 'features/lider/presentation/screens/lider_screens.dart';
import 'features/pastor/presentation/screens/pastor_screens.dart';
import 'features/admin/presentation/screens/admin_screens.dart';
import 'features/admin/presentation/screens/admin_miembros_screen.dart'; // ✅

class SigmarApp extends StatelessWidget {
  const SigmarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIGMAR — Luz y Vida',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(
          primary: kGold,
          secondary: kGoldLight,
          surface: kBgCard,
        ),
      ),
      initialRoute: '/',
      routes: {
        // Publicas
        '/': (_) => const InicioScreen(),
        '/sobre': (_) => const SobreScreen(),
        '/login': (_) => const LoginScreen(),

        // Miembro
        '/miembro/inscripcion': (_) => const InscripcionScreen(),

        // Lider
        '/lider/grupo': (_) => const MiGrupoScreen(),

        // Pastor
        '/pastor/reportes': (_) => const ReportesScreen(),
        '/pastor/guias': (_) => const GuiasScreen(),

        // Admin
        '/admin/grupos': (_) => const AdminGruposScreen(),
        '/admin/cursos': (_) => const AdminCursosScreen(),
        '/admin/usuarios': (_) => const AdminUsuariosScreen(),
        '/admin/aportes': (_) => const AdminAportesScreen(),
        '/admin/miembros': (_) => const AdminMiembrosScreen(), // ✅
        // Compartida
        '/perfil': (_) => const PerfilScreen(),
      },
    );
  }
}
