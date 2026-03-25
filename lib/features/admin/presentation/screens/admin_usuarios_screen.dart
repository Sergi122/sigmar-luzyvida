import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sigmar_page.dart';
import 'registro_usuario_screen.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFF7F77DD);

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});
  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  List<Map<String, dynamic>> _usuarios = [];
  bool _cargando = true;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      // ✅ join con miembros via miembro_id para obtener nombre
      final data = await _sb
          .from('usuarios')
          .select('*, miembros(nombre)')
          .order('email');
      setState(() {
        _usuarios = List<Map<String, dynamic>>.from(data);
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  List<Map<String, dynamic>> get _filtrados {
    if (_busqueda.isEmpty) return _usuarios;
    return _usuarios.where((u) {
      final email = (u['email'] ?? '').toLowerCase();
      final nombre = ((u['miembros'] as Map?)?['nombre'] ?? '').toLowerCase();
      return email.contains(_busqueda.toLowerCase()) ||
          nombre.contains(_busqueda.toLowerCase());
    }).toList();
  }

  void _abrirFormulario({Map<String, dynamic>? usuario}) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroUsuarioScreen(usuarioParaEditar: usuario),
      ),
    );
    if (ok == true) _cargar();
  }

  Future<void> _toggleActivo(Map<String, dynamic> u) async {
    // ✅ activo es boolean en nueva schema
    final nuevoActivo = !(u['activo'] as bool? ?? true);
    await _sb
        .from('usuarios')
        .update({'activo': nuevoActivo})
        .eq('id', u['id']);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.of(context).size.width < 800;
    return SigmarPage(
      rutaActual: '/admin/usuarios',
      child: Padding(
        padding: EdgeInsets.all(movil ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _kColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.manage_accounts_outlined,
                    color: _kColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestion de Usuarios',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Crear y gestionar accesos al sistema',
                        style: TextStyle(color: kGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _abrirFormulario(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Nuevo Usuario',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 50, height: 3, color: _kColor),
            const SizedBox(height: 20),
            TextField(
              onChanged: (v) => setState(() => _busqueda = v),
              style: const TextStyle(color: kWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar por email o nombre...',
                hintStyle: const TextStyle(color: kGrey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: kGrey, size: 18),
                filled: true,
                fillColor: kBgCard,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kDivider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kDivider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_cargando)
              const Center(child: CircularProgressIndicator(color: _kColor))
            else if (_filtrados.isEmpty)
              const Center(
                child: Text(
                  'No hay usuarios registrados',
                  style: TextStyle(color: kGrey),
                ),
              )
            else
              ...(_filtrados.map((u) {
                // ✅ activo es boolean
                final activo = u['activo'] as bool? ?? true;
                final nombre = (u['miembros'] as Map?)?['nombre'] ?? u['email'];
                final rol = u['rol'] ?? 'miembro';
                final colorRol = _colorPorRol(rol);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kBgMid,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kDivider),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: colorRol.withValues(alpha: 0.15),
                        child: Text(
                          (nombre[0]).toUpperCase(),
                          style: TextStyle(
                            color: colorRol,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: const TextStyle(
                                color: kWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              u['email'] ?? '',
                              style: const TextStyle(
                                color: kGrey,
                                fontSize: 11,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorRol.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    rol.toUpperCase(),
                                    style: TextStyle(
                                      color: colorRol,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (activo ? kSuccess : kDanger)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    activo ? 'Activo' : 'Inactivo',
                                    style: TextStyle(
                                      color: activo ? kSuccess : kDanger,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: _kColor,
                          size: 18,
                        ),
                        onPressed: () => _abrirFormulario(usuario: u),
                      ),
                      IconButton(
                        icon: Icon(
                          activo
                              ? Icons.block_outlined
                              : Icons.check_circle_outline,
                          color: activo ? kDanger : kSuccess,
                          size: 18,
                        ),
                        onPressed: () => _toggleActivo(u),
                        tooltip: activo ? 'Desactivar' : 'Activar',
                      ),
                    ],
                  ),
                );
              })),
          ],
        ),
      ),
    );
  }

  Color _colorPorRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':
        return const Color(0xFF7F77DD);
      case 'pastor':
        return const Color(0xFFBA7517);
      case 'lider':
        return const Color(0xFF378ADD);
      default:
        return const Color(0xFF1D9E75);
    }
  }
}
