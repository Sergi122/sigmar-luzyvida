import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Shell reutilizable para todos los roles autenticados.
/// Recibe la lista de items del menú y el body de la pantalla activa.
class DashboardShell extends StatelessWidget {
  final String nombreUsuario;
  final String rol;
  final List<MenuItemData> menuItems;
  final Widget body;
  final int indiceActivo;
  final ValueChanged<int> onMenuTap;

  const DashboardShell({
    super.key,
    required this.nombreUsuario,
    required this.rol,
    required this.menuItems,
    required this.body,
    required this.indiceActivo,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.of(context).size.width < 800;
    return Scaffold(
      backgroundColor: kBg,
      drawer: movil
          ? _Drawer(
              nombreUsuario: nombreUsuario,
              rol: rol,
              menuItems: menuItems,
              indiceActivo: indiceActivo,
              onMenuTap: onMenuTap,
            )
          : null,
      body: Row(
        children: [
          // Sidebar — solo desktop
          if (!movil)
            _Sidebar(
              nombreUsuario: nombreUsuario,
              rol: rol,
              menuItems: menuItems,
              indiceActivo: indiceActivo,
              onMenuTap: onMenuTap,
            ),
          // Contenido principal
          Expanded(
            child: Column(
              children: [
                _TopBar(nombreUsuario: nombreUsuario, rol: rol, movil: movil),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar desktop ───────────────────────────────────
class _Sidebar extends StatelessWidget {
  final String nombreUsuario, rol;
  final List<MenuItemData> menuItems;
  final int indiceActivo;
  final ValueChanged<int> onMenuTap;

  const _Sidebar({
    required this.nombreUsuario,
    required this.rol,
    required this.menuItems,
    required this.indiceActivo,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFF111111),
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kDivider)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [kGold, kGoldDark]),
                  ),
                  child: const Center(
                    child: Text(
                      'LV',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SIGMAR',
                      style: TextStyle(
                        color: kGold,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'Luz y Vida',
                      style: TextStyle(color: kGrey, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: menuItems
                  .asMap()
                  .entries
                  .map(
                    (e) => _MenuItem(
                      item: e.value,
                      activo: e.key == indiceActivo,
                      onTap: () => onMenuTap(e.key),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Footer usuario + cerrar sesion
          _SidebarFooter(nombreUsuario: nombreUsuario, rol: rol),
        ],
      ),
    );
  }
}

// ── Drawer movil ──────────────────────────────────────
class _Drawer extends StatelessWidget {
  final String nombreUsuario, rol;
  final List<MenuItemData> menuItems;
  final int indiceActivo;
  final ValueChanged<int> onMenuTap;

  const _Drawer({
    required this.nombreUsuario,
    required this.rol,
    required this.menuItems,
    required this.indiceActivo,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF111111),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: kBgCard),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
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
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'SIGMAR',
                      style: TextStyle(
                        color: kGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      nombreUsuario,
                      style: const TextStyle(color: kGrey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: menuItems
                  .asMap()
                  .entries
                  .map(
                    (e) => _MenuItem(
                      item: e.value,
                      activo: e.key == indiceActivo,
                      onTap: () {
                        onMenuTap(e.key);
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          _SidebarFooter(nombreUsuario: nombreUsuario, rol: rol),
        ],
      ),
    );
  }
}

// ── Menu item ─────────────────────────────────────────
class _MenuItem extends StatefulWidget {
  final MenuItemData item;
  final bool activo;
  final VoidCallback onTap;
  const _MenuItem({
    required this.item,
    required this.activo,
    required this.onTap,
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
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: widget.activo
              ? kGold.withValues(alpha: 0.15)
              : _hover
              ? kGold.withValues(alpha: 0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.activo
                ? kGold.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              widget.item.icono,
              color: widget.activo ? kGold : kGrey,
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              widget.item.label,
              style: TextStyle(
                color: widget.activo ? kGold : kGrey,
                fontSize: 13,
                fontWeight: widget.activo ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Top bar ───────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String nombreUsuario, rol;
  final bool movil;
  const _TopBar({
    required this.nombreUsuario,
    required this.rol,
    required this.movil,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: kBgMid,
        border: Border(bottom: BorderSide(color: kDivider)),
      ),
      child: Row(
        children: [
          if (movil) ...[
            GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: const Icon(Icons.menu, color: kWhite),
            ),
            const SizedBox(width: 16),
          ],
          const Text(
            'SIGMAR',
            style: TextStyle(
              color: kGold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          // Badge de rol
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _colorRol(rol).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _colorRol(rol).withValues(alpha: 0.4)),
            ),
            child: Text(
              rol.toUpperCase(),
              style: TextStyle(
                color: _colorRol(rol),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar usuario
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _colorRol(rol).withValues(alpha: 0.15),
              border: Border.all(color: _colorRol(rol).withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: _colorRol(rol),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorRol(String r) {
    switch (r.toLowerCase()) {
      case 'miembro':
        return const Color(0xFF1D9E75); // teal
      case 'lider':
        return const Color(0xFF378ADD); // blue
      case 'pastor':
        return const Color(0xFFBA7517); // amber
      case 'administrador':
      case 'admin':
        return const Color(0xFF7F77DD); // purple
      default:
        return kGrey;
    }
  }
}

// ── Sidebar footer con cerrar sesion ──────────────────
class _SidebarFooter extends StatelessWidget {
  final String nombreUsuario, rol;
  const _SidebarFooter({required this.nombreUsuario, required this.rol});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: kDivider)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kGold.withValues(alpha: 0.12),
                  border: Border.all(color: kGold.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    nombreUsuario.isNotEmpty
                        ? nombreUsuario[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: kGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreUsuario,
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      rol,
                      style: const TextStyle(color: kGrey, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kGrey,
                side: const BorderSide(color: kDivider),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              icon: const Icon(Icons.logout, size: 15),
              label: const Text(
                'Cerrar sesion',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modelo de item de menu ────────────────────────────
class MenuItemData {
  final String label;
  final IconData icono;
  const MenuItemData(this.label, this.icono);
}
