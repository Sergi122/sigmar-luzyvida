import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/session.dart';

class SigmarNavbar extends StatelessWidget {
  final String rutaActual;
  const SigmarNavbar({super.key, required this.rutaActual});

  List<_Item> get _rutasBase => [
    _Item('INICIO', '/'),
    _Item('QUIENES SOMOS', '/sobre'),
  ];

  List<_Item> get _rutasRol {
    switch (AppSession.rol) {
      case 'miembro':
        return [_Item('INSCRIPCION', '/miembro/inscripcion')];
      case 'lider':
        return [_Item('MI GRUPO', '/lider/grupo')];
      case 'pastor':
        return [
          _Item('REPORTES', '/pastor/reportes'),
          _Item('GUIAS', '/pastor/guias'),
        ];
      case 'administrador':
      case 'admin':
        return [
          _Item('MIEMBROS', '/admin/miembros'),
          _Item('GRUPOS', '/admin/grupos'),
          _Item('CURSOS', '/admin/cursos'),
          _Item('USUARIOS', '/admin/usuarios'),
          _Item('APORTES', '/admin/aportes'),
        ];
      default:
        return [];
    }
  }

  List<_Item> get _todos => [..._rutasBase, ..._rutasRol];

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.of(context).size.width < 1100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(bottom: BorderSide(color: kDivider)),
      ),
      child: Row(
        children: [
          // Logo
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/'),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.jpg',
                    width: 44,
                    height: 44,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [kGold, kGoldDark]),
                      ),
                      child: const Center(
                        child: Text(
                          'LV',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LUZ Y VIDA',
                        style: TextStyle(
                          color: kGold,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'Somos Familia',
                        style: TextStyle(color: kGrey, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),

          // Links desktop
          if (!movil)
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _todos
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: _NavLink(
                            label: r.label,
                            ruta: r.ruta,
                            actual: rutaActual,
                            onTap: () =>
                                Navigator.pushReplacementNamed(context, r.ruta),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),

          // Boton derecho: login o perfil
          if (AppSession.autenticado)
            _MenuPerfil(
              onCerrar: () {
                AppSession.cerrar();
                Navigator.pushReplacementNamed(context, '/');
              },
            )
          else
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                elevation: 0,
              ),
              child: const Text('INICIAR SESION'),
            ),

          // Menu movil
          if (movil) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              color: kBgCard,
              icon: const Icon(Icons.menu, color: kWhite),
              onSelected: (v) => Navigator.pushReplacementNamed(context, v),
              itemBuilder: (_) => _todos
                  .map(
                    (r) => PopupMenuItem(
                      value: r.ruta,
                      child: Text(
                        r.label,
                        style: const TextStyle(color: kWhite, fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Item {
  final String label, ruta;
  const _Item(this.label, this.ruta);
}

class _NavLink extends StatefulWidget {
  final String label, ruta, actual;
  final VoidCallback onTap;
  const _NavLink({
    required this.label,
    required this.ruta,
    required this.actual,
    required this.onTap,
  });
  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final activo = widget.actual == widget.ruta;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                color: activo ? kGold : (_h ? kGoldLight : kGrey),
                fontSize: 11,
                fontWeight: activo ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: activo ? 24 : 0,
              height: 2,
              color: kGold,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuPerfil extends StatelessWidget {
  final VoidCallback onCerrar;
  const _MenuPerfil({required this.onCerrar});

  Color get _c {
    switch (AppSession.rol) {
      case 'miembro':
        return const Color(0xFF1D9E75);
      case 'lider':
        return const Color(0xFF378ADD);
      case 'pastor':
        return const Color(0xFFBA7517);
      default:
        return const Color(0xFF7F77DD);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ini = AppSession.nombre.isNotEmpty
        ? AppSession.nombre[0].toUpperCase()
        : 'U';
    return PopupMenuButton<String>(
      color: kBgCard,
      offset: const Offset(0, 48),
      onSelected: (v) {
        if (v == 'perfil') Navigator.pushNamed(context, '/perfil');
        if (v == 'salir') onCerrar();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppSession.nombre,
                style: const TextStyle(
                  color: kWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                AppSession.rol.toUpperCase(),
                style: TextStyle(color: _c, fontSize: 10, letterSpacing: 1),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'perfil',
          child: Row(
            children: [
              Icon(Icons.person_outline, color: kGrey, size: 16),
              SizedBox(width: 8),
              Text('Mi Perfil', style: TextStyle(color: kWhite, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'salir',
          child: Row(
            children: [
              Icon(Icons.logout, color: kDanger, size: 16),
              SizedBox(width: 8),
              Text(
                'Cerrar sesion',
                style: TextStyle(color: kDanger, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _c.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _c.withValues(alpha: 0.4)),
            ),
            child: Text(
              AppSession.rol.toUpperCase(),
              style: TextStyle(
                color: _c,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _c.withValues(alpha: 0.15),
              border: Border.all(color: _c.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                ini,
                style: TextStyle(
                  color: _c,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, color: kGrey, size: 16),
        ],
      ),
    );
  }
}
