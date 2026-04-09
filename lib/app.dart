import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';

import 'features/home/presentation/screens/inicio_screen.dart';
import 'features/sobre/presentation/screens/sobre_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';

import 'features/miembro/presentation/screens/miembro_screens.dart';
import 'features/admin/presentation/screens/admin_screens.dart';
import 'features/pastor/presentation/screens/pastor_screens.dart';

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

        '/admin': (_) => AdminUsuariosScreen(),
        '/admin/usuarios': (_) => AdminUsuariosScreen(),
        '/admin/miembros': (_) => AdminMiembrosScreen(),
        '/admin/grupos': (_) => AdminGruposScreen(),
        '/admin/cursos': (_) => AdminCursosScreen(),
        '/admin/aportes': (_) => AdminAportesScreen(),
        '/admin/ministerios': (_) => AdminMinisteriosScreen(),
        '/perfil': (_) => PerfilScreen(),

        '/pastor': (_) => PastorMiembrosScreen(),
        '/pastor/miembros': (_) => PastorMiembrosScreen(),
        '/pastor/grupos': (_) => PastorGruposScreen(),
        '/pastor/cursos': (_) => PastorCursosScreen(),
        '/pastor/asistencia': (_) => PastorAsistenciaScreen(),
        '/pastor/aportes': (_) => PastorAportesScreen(),

        '/miembro': (_) => MiembroInscripcionScreen(),
        '/miembro/inscripcion': (_) => MiembroInscripcionScreen(),
        '/lider/grupo': (_) => MiGrupoScreen(),
      },
    );
  }
}
