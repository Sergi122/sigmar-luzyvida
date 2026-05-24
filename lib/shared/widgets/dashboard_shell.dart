import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_layout.dart';
import '../../core/session.dart';

// ── Menús por rol ─────────────────────────────────────────────────────────────

const _menuAdmin = <MenuItemData>[
  MenuItemData(label: 'Dashboard', icono: Icons.dashboard, ruta: '/admin'),
  MenuItemData(label: 'Miembros', icono: Icons.people, ruta: '/admin/miembros'),
  MenuItemData(label: 'Grupos', icono: Icons.group, ruta: '/admin/grupos'),
  MenuItemData(label: 'Cursos', icono: Icons.school, ruta: '/admin/cursos'),
  MenuItemData(
    label: 'Ministerios',
    icono: Icons.account_balance,
    ruta: '/admin/ministerios',
  ),
  MenuItemData(
    label: 'Finanzas',
    icono: Icons.monetization_on,
    ruta: '/admin/aportes',
  ),
  MenuItemData(
    label: 'Usuarios',
    icono: Icons.manage_accounts,
    ruta: '/admin/usuarios',
  ),
];

const _menuPastor = <MenuItemData>[
  MenuItemData(
    label: 'Miembros',
    icono: Icons.people,
    ruta: '/pastor/miembros',
  ),
  MenuItemData(label: 'Grupos', icono: Icons.group, ruta: '/pastor/grupos'),
  MenuItemData(label: 'Cursos', icono: Icons.school, ruta: '/pastor/cursos'),
  MenuItemData(
    label: 'Asistencia',
    icono: Icons.fact_check,
    ruta: '/pastor/asistencia',
  ),
  MenuItemData(
    label: 'Aportes',
    icono: Icons.monetization_on,
    ruta: '/pastor/aportes',
  ),
];

const _menuLider = <MenuItemData>[
  MenuItemData(label: 'Mi Grupo', icono: Icons.group, ruta: '/lider/grupo'),
  MenuItemData(
    label: 'Asistencia',
    icono: Icons.fact_check,
    ruta: '/lider/grupo',
  ),
  MenuItemData(
    label: 'Miembros del Grupo',
    icono: Icons.people,
    ruta: '/lider/grupo',
  ),
  MenuItemData(label: 'Mi Perfil', icono: Icons.person, ruta: '/perfil'),
];

const _menuMiembro = <MenuItemData>[
  MenuItemData(
    label: 'Mis Cursos',
    icono: Icons.school,
    ruta: '/miembro/inscripcion',
  ),
  MenuItemData(label: 'Mi Grupo', icono: Icons.group, ruta: '/miembro'),
  MenuItemData(
    label: 'Mis Aportes',
    icono: Icons.monetization_on,
    ruta: '/miembro',
  ),
  MenuItemData(
    label: 'Sobre Nosotros',
    icono: Icons.info_outline,
    ruta: '/sobre',
  ),
];

const _menuFinanzas = <MenuItemData>[
  MenuItemData(label: 'Inicio', icono: Icons.home, ruta: '/finanzas'),
  MenuItemData(
    label: 'Diezmos y Ofrendas',
    icono: Icons.monetization_on,
    ruta: '/finanzas/aportes',
  ),
];

List<MenuItemData> menuPorRol(String rol) {
  switch (rol.toLowerCase()) {
    case 'admin':
      return _menuAdmin;
    case 'pastor':
      return _menuPastor;
    case 'lider':
      return _menuLider;
    case 'miembro':
      return _menuMiembro;
    case 'finanzas':
      return _menuFinanzas;
    default:
      return [];
  }
}

Color colorPorRol(String rol) {
  switch (rol.toLowerCase()) {
    case 'miembro':
      return const Color(0xFF1D9E75);
    case 'lider':
      return const Color(0xFF378ADD);
    case 'pastor':
      return const Color(0xFFBA7517);
    case 'admin':
      return const Color(0xFF7F77DD);
    case 'finanzas':
      return const Color(0xFF4CAF50);
    default:
      return kGrey;
  }
}

// ── DashboardPage ─────────────────────────────────────────────────────────────
/// Reemplaza SigmarPage y DashboardShell en todas las pantallas autenticadas.
/// Lee el rol automáticamente desde AppSession y construye el sidebar correcto.
class DashboardPage extends StatelessWidget {
  final String rutaActual;
  final Widget child;

  /// true (default) = envuelve child en SingleChildScrollView (mismo comportamiento
  /// que SigmarPage). false = el child maneja su propio scroll.
  final bool conScroll;

  const DashboardPage({
    super.key,
    required this.rutaActual,
    required this.child,
    this.conScroll = true,
  });

  @override
  Widget build(BuildContext context) {
    final body = conScroll ? SingleChildScrollView(child: child) : child;
    return DashboardShell(
      nombreUsuario: AppSession.nombre,
      rol: AppSession.rol,
      menuItems: menuPorRol(AppSession.rol),
      rutaActual: rutaActual,
      body: body,
    );
  }
}

// ── DashboardShell ────────────────────────────────────────────────────────────
class DashboardShell extends StatelessWidget {
  final String nombreUsuario;
  final String rol;
  final List<MenuItemData> menuItems;
  final Widget body;
  final String rutaActual;

  const DashboardShell({
    super.key,
    required this.nombreUsuario,
    required this.rol,
    required this.menuItems,
    required this.body,
    required this.rutaActual,
  });

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.of(context).size.width < kMobileBreakpoint;
    final color = colorPorRol(rol);

    return Scaffold(
      backgroundColor: kBg,
      drawer: movil
          ? _Drawer(menuItems: menuItems, rutaActual: rutaActual, color: color)
          : null,
      body: Column(
        children: [
          _TopNavbar(
            nombreUsuario: nombreUsuario,
            rol: rol,
            color: color,
            movil: movil,
          ),
          Expanded(
            child: Row(
              children: [
                if (!movil)
                  _Sidebar(
                    menuItems: menuItems,
                    rutaActual: rutaActual,
                    color: color,
                  ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── TopNavbar ─────────────────────────────────────────────────────────────────
class _TopNavbar extends StatelessWidget {
  final String nombreUsuario, rol;
  final Color color;
  final bool movil;

  const _TopNavbar({
    required this.nombreUsuario,
    required this.rol,
    required this.color,
    required this.movil,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(bottom: BorderSide(color: kDivider)),
      ),
      child: Row(
        children: [
          if (movil) ...[
            GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: const Icon(Icons.menu, color: kGold, size: 26),
            ),
            const SizedBox(width: 14),
          ],
          // Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/logo.jpg',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _LogoFallback(size: 36),
            ),
          ),
          const SizedBox(width: 10),
          if (!movil)
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LUZ Y VIDA',
                  style: TextStyle(
                    color: kGold,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Somos Familia',
                  style: TextStyle(color: kGrey, fontSize: 10),
                ),
              ],
            ),
          const Spacer(),
          // Badge de rol (solo desktop)
          if (!movil) ...[
            _RolBadge(rol: rol, color: color),
            const SizedBox(width: 14),
          ],
          // Dropdown de usuario
          _UserDropdown(nombreUsuario: nombreUsuario, color: color),
        ],
      ),
    );
  }
}

// ── RolBadge ──────────────────────────────────────────────────────────────────
class _RolBadge extends StatelessWidget {
  final String rol;
  final Color color;
  const _RolBadge({required this.rol, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        rol.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ── UserDropdown ──────────────────────────────────────────────────────────────
class _UserDropdown extends StatelessWidget {
  final String nombreUsuario;
  final Color color;
  const _UserDropdown({required this.nombreUsuario, required this.color});

  @override
  Widget build(BuildContext context) {
    final ini = nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : 'U';
    final nombre = nombreUsuario.length > 18
        ? '${nombreUsuario.substring(0, 16)}…'
        : nombreUsuario;

    return PopupMenuButton<String>(
      color: kBgCard,
      offset: const Offset(0, 54),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: kDivider),
      ),
      onSelected: (v) async {
        if (v == 'perfil') {
          Navigator.pushNamed(context, '/perfil');
        } else if (v == 'salir') {
          await AppSession.cerrar();
          if (context.mounted) Navigator.pushReplacementNamed(context, '/');
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombreUsuario,
                style: const TextStyle(
                  color: kWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                AppSession.rol.toUpperCase(),
                style: TextStyle(color: color, fontSize: 10),
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
              Text(
                'Modificar Perfil',
                style: TextStyle(color: kWhite, fontSize: 13),
              ),
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
                'Cerrar Sesión',
                style: TextStyle(color: kDanger, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: color.withValues(alpha: 0.18),
            child: Text(
              ini,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(nombre, style: const TextStyle(color: kWhite, fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, color: kGrey, size: 16),
        ],
      ),
    );
  }
}

// ── Sidebar (desktop) ─────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final List<MenuItemData> menuItems;
  final String rutaActual;
  final Color color;

  const _Sidebar({
    required this.menuItems,
    required this.rutaActual,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(right: BorderSide(color: kDivider)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: menuItems
            .map(
              (item) => _MenuItem(
                item: item,
                activo: item.ruta == rutaActual,
                color: color,
                enDrawer: false,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Drawer (móvil) ────────────────────────────────────────────────────────────
class _Drawer extends StatelessWidget {
  final List<MenuItemData> menuItems;
  final String rutaActual;
  final Color color;

  const _Drawer({
    required this.menuItems,
    required this.rutaActual,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF111111),
      child: Column(
        children: [
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              color: kBgMid,
              border: Border(bottom: BorderSide(color: kDivider)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _LogoFallback(size: 40),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LUZ Y VIDA',
                      style: TextStyle(
                        color: kGold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'Somos Familia',
                      style: TextStyle(color: kGrey, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: menuItems
                  .map(
                    (item) => _MenuItem(
                      item: item,
                      activo: item.ruta == rutaActual,
                      color: color,
                      enDrawer: true,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── MenuItem ──────────────────────────────────────────────────────────────────
class _MenuItem extends StatefulWidget {
  final MenuItemData item;
  final bool activo, enDrawer;
  final Color color;

  const _MenuItem({
    required this.item,
    required this.activo,
    required this.color,
    required this.enDrawer,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: GestureDetector(
      onTap: () {
        if (widget.enDrawer) Navigator.pop(context);
        Navigator.pushReplacementNamed(context, widget.item.ruta);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: widget.activo
              ? widget.color.withValues(alpha: 0.15)
              : _hover
              ? widget.color.withValues(alpha: 0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.activo
                ? widget.color.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              widget.item.icono,
              color: widget.activo ? widget.color : kGrey,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.item.label,
                style: TextStyle(
                  color: widget.activo ? widget.color : kGrey,
                  fontSize: 13,
                  fontWeight: widget.activo
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Logo fallback ─────────────────────────────────────────────────────────────
class _LogoFallback extends StatelessWidget {
  final double size;
  const _LogoFallback({required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: [kGold, kGoldDark]),
    ),
    child: Center(
      child: Text(
        'LV',
        style: TextStyle(
          color: Colors.black,
          fontSize: size * 0.33,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

// ── MenuItemData ──────────────────────────────────────────────────────────────
class MenuItemData {
  final String label;
  final IconData icono;
  final String ruta;
  const MenuItemData({
    required this.label,
    required this.icono,
    required this.ruta,
  });
}
