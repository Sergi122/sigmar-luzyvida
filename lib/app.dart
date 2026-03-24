import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'features/home/presentation/screens/inicio_screen.dart';
import 'features/sobre/presentation/screens/sobre_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/lider/presentation/screens/lider_screens.dart';
import 'features/admin/presentation/screens/admin_screens.dart';

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
        '/': (_) => const InicioScreen(),
        '/sobre': (_) => const SobreScreen(),
        '/login': (_) => const LoginScreen(),
        '/miembro/inscripcion': (_) => const InscripcionScreen(),
        '/lider/grupo': (_) => const MiGrupoScreen(),
        '/pastor/reportes': (_) => const ReportesScreen(),
        '/pastor/guias': (_) => const GuiasScreen(),
        '/admin/grupos': (_) => const AdminGruposScreen(),
        '/admin/cursos': (_) => const AdminCursosScreen(),
        '/admin/miembros': (_) => const AdminMiembrosScreen(),
        '/admin/usuarios': (_) => const AdminUsuariosScreen(),
        '/admin/aportes': (_) => const AdminAportesScreen(),
        '/perfil': (_) => const PerfilScreen(),
      },
    );
  }
}
