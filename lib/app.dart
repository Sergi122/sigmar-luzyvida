import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';

// Pantallas Base
import 'features/home/presentation/screens/inicio_screen.dart';
import 'features/sobre/presentation/screens/sobre_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';

// ✅ ADMIN
import 'features/admin/presentation/screens/admin_miembros_screen.dart';
import 'features/admin/presentation/screens/admin_grupos_screen.dart';
import 'features/admin/presentation/screens/admin_cursos_screen.dart';
import 'features/admin/presentation/screens/admin_usuarios_screen.dart';
import 'features/admin/presentation/screens/admin_aportes_screen.dart';
import 'features/admin/presentation/screens/admin_ministerios_screen.dart';
import 'features/admin/presentation/screens/perfil_screen.dart';

// ✅ PASTOR / MIEMBRO / LÍDER
import 'features/miembro/presentation/screens/miembro_screens.dart';

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
        // --- RUTAS PÚBLICAS ---
        '/': (_) => const InicioScreen(),
        '/sobre': (_) => const SobreScreen(),
        '/login': (_) => const LoginScreen(),

        // --- RUTAS DE ADMIN ---
        '/admin': (_) => const AdminUsuariosScreen(),
        '/admin/usuarios': (_) => const AdminUsuariosScreen(),
        '/admin/miembros': (_) => const AdminMiembrosScreen(),
        '/admin/grupos': (_) => const AdminGruposScreen(),
        '/admin/cursos': (_) => const AdminCursosScreen(),
        '/admin/aportes': (_) => const AdminAportesScreen(),
        '/admin/ministerios': (_) => const AdminMinisteriosScreen(),

        // --- RUTAS DE PASTOR ---
        '/pastor': (_) => const ReportesScreen(),
        '/pastor/reportes': (_) => const ReportesScreen(),
        '/pastor/guias': (_) => const GuiasScreen(),

        // --- RUTAS DE MIEMBRO / LÍDER ---
        '/miembro': (_) => const InscripcionScreen(),
        '/miembro/inscripcion': (_) => const InscripcionScreen(),
        '/lider/grupo': (_) => const MiGrupoScreen(),

        // --- GENERAL ---
        '/perfil': (_) => const PerfilScreen(),
      },
    );
  }
}
