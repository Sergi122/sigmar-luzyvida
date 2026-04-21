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
          _Item('MIEMBROS', '/pastor/miembros'),
          _Item('GRUPOS', '/pastor/grupos'),
          _Item('CURSOS', '/pastor/cursos'),
          _Item('ASISTENCIA', '/pastor/asistencia'),
          _Item('APORTES', '/pastor/aportes'),
        ];
      case 'finanzas':
        return [
          _Item('DIEZMOS', '/finanzas/diezmos'),
          _Item('OFRENDAS', '/finanzas/ofrendas'),
        ];
      case 'admin':
        return [
          _Item('MIEMBROS', '/admin/miembros'),
          _Item('GRUPOS', '/admin/grupos'),
          _Item('CURSOS', '/admin/cursos'),
          _Item('MINISTERIOS', '/admin/ministerios'),
          _Item('APORTES', '/admin/aportes'),
        ];
      default:
        return [];
    }
  }

  List<_Item> get _todos => [..._rutasBase, ..._rutasRol];

  @override
  Widget build(BuildContext context) {
    final bool esEscritorio = MediaQuery.of(context).size.width > 1000;

    return Container(
      // ── Altura aumentada ──
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(
          bottom: BorderSide(
            color: kGold,
            width: 2,
          ), // borde dorado más visible
        ),
      ),
      child: Row(
        children: [
          _buildLogo(context),
          const Spacer(),

          // Links desktop
          if (esEscritorio)
            Row(
              children: _todos
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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

          if (esEscritorio) const SizedBox(width: 24),

          // Botón derecho
          if (AppSession.autenticado)
            _MenuPerfil(
              esMovil: !esEscritorio,
              onCerrar: () {
                AppSession.cerrar();
                Navigator.pushReplacementNamed(context, '/');
              },
            )
          else
            _buildBotonLogin(context),

          // Menú hamburguesa móvil
          if (!esEscritorio) ...[
            const SizedBox(width: 10),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 200),
              color: kBgCard,
              icon: const Icon(Icons.menu, color: kGold, size: 30),
              onSelected: (v) => Navigator.pushReplacementNamed(context, v),
              itemBuilder: (_) => _todos
                  .map(
                    (r) => PopupMenuItem(
                      value: r.ruta,
                      child: Text(
                        r.label,
                        style: const TextStyle(color: kWhite, fontSize: 14),
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

  Widget _buildLogo(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushReplacementNamed(context, '/'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          children: [
            // ── Logo más grande ──
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/logo.jpg',
                width: 56, // antes 38
                height: 56, // antes 38
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderLogo(),
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LUZ Y VIDA',
                  style: TextStyle(
                    color: kGold,
                    fontSize: 17, // antes 13
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Somos Familia',
                  style: TextStyle(
                    color: kGrey,
                    fontSize: 11, // antes 9
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderLogo() {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [kGold, kGoldDark]),
      ),
      child: const Center(
        child: Text(
          'LV',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBotonLogin(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, '/login'),
      style: ElevatedButton.styleFrom(
        backgroundColor: kGold,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 0,
      ),
      child: const Text(
        'INICIAR SESION',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ─── Modelos y widgets internos ───────────────────────────────────────────────

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
                fontSize: 13, // antes 11
                fontWeight: activo ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            if (activo) Container(width: 20, height: 2, color: kGold),
          ],
        ),
      ),
    );
  }
}

class _MenuPerfil extends StatelessWidget {
  final bool esMovil;
  final VoidCallback onCerrar;
  const _MenuPerfil({required this.esMovil, required this.onCerrar});

  Color get _c {
    switch (AppSession.rol) {
      case 'miembro':
        return const Color(0xFF1D9E75);
      case 'lider':
        return const Color(0xFF378ADD);
      case 'pastor':
        return const Color(0xFFBA7517);
      case 'finanzas':
        return const Color(0xFF4CAF50);
      case 'admin':
        return const Color(0xFF7F77DD);
      default:
        return const Color(0xFF888888);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ini = AppSession.nombre.isNotEmpty
        ? AppSession.nombre[0].toUpperCase()
        : 'U';

    return PopupMenuButton<String>(
      color: kBgCard,
      offset: const Offset(0, 56),
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
                style: TextStyle(color: _c, fontSize: 10),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'perfil',
          child: Text('Mi Perfil', style: TextStyle(color: kWhite)),
        ),
        const PopupMenuItem(
          value: 'salir',
          child: Text('Cerrar sesion', style: TextStyle(color: kDanger)),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!esMovil) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _c.withOpacity(0.3)),
              ),
              child: Text(
                AppSession.rol.toUpperCase(),
                style: TextStyle(
                  color: _c,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          CircleAvatar(
            radius: 20,
            backgroundColor: _c.withOpacity(0.2),
            child: Text(
              ini,
              style: TextStyle(
                color: _c,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: kGrey, size: 18),
        ],
      ),
    );
  }
}
