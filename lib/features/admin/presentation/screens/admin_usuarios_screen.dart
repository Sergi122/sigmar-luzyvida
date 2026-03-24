import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sigmar_page.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFF7F77DD);

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});
  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> _filtrados = [];
  List<Map<String, dynamic>> _miembros = [];
  bool _cargando = true;
  String _busqueda = '';
  String _filtroRol = 'todos';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final usuarios = await _sb.from('usuarios').select().order('email');
      final miembros = await _sb
          .from('miembros')
          .select('id, nombre')
          .order('nombre');
      setState(() {
        _usuarios = List<Map<String, dynamic>>.from(usuarios);
        _miembros = List<Map<String, dynamic>>.from(miembros);
        _filtrar();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _snack('Error al cargar: $e', error: true);
    }
  }

  void _filtrar() {
    _filtrados = _usuarios.where((u) {
      final email = (u['email'] ?? '').toLowerCase();
      final pasaBusqueda =
          _busqueda.isEmpty || email.contains(_busqueda.toLowerCase());
      final pasaRol = _filtroRol == 'todos' || (u['rol'] ?? '') == _filtroRol;
      return pasaBusqueda && pasaRol;
    }).toList();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? kDanger : kSuccess),
    );
  }

  void _abrirFormulario({Map<String, dynamic>? usuario}) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormUsuario(usuario: usuario, miembros: _miembros),
    );
    if (ok == true) _cargar();
  }

  Future<void> _eliminar(Map<String, dynamic> u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBgCard,
        title: const Text('Eliminar Usuario', style: TextStyle(color: kWhite)),
        content: Text(
          '¿Eliminar el acceso de ${u['email']}?\nEsta accion no se puede deshacer.',
          style: const TextStyle(color: kGrey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: kGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kDanger,
              elevation: 0,
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _sb.from('usuarios').delete().eq('id', u['id']);
      _snack('Usuario eliminado');
      _cargar();
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  Color _colorRol(String rol) {
    switch (rol) {
      case 'admin':
      case 'administrador':
        return kDanger;
      case 'pastor':
        return const Color(0xFF9B59B6);
      case 'lider':
        return const Color(0xFF0E8A7A);
      default:
        return _kColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SigmarPage(
      rutaActual: '/admin/usuarios',
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                    Icons.manage_accounts,
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
                        'Accesos al sistema SIGMAR',
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
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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

            // Filtros
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (v) => setState(() {
                      _busqueda = v;
                      _filtrar();
                    }),
                    style: const TextStyle(color: kWhite, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar por email...',
                      hintStyle: const TextStyle(color: kGrey, fontSize: 13),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: kGrey,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: kBgCard,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kDivider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filtroRol,
                      dropdownColor: kBgCard,
                      style: const TextStyle(color: kWhite, fontSize: 13),
                      onChanged: (v) => setState(() {
                        _filtroRol = v!;
                        _filtrar();
                      }),
                      items: const [
                        DropdownMenuItem(
                          value: 'todos',
                          child: Text('Todos los roles'),
                        ),
                        DropdownMenuItem(
                          value: 'administrador',
                          child: Text('Administrador'),
                        ),
                        DropdownMenuItem(
                          value: 'pastor',
                          child: Text('Pastor'),
                        ),
                        DropdownMenuItem(value: 'lider', child: Text('Lider')),
                        DropdownMenuItem(
                          value: 'miembro',
                          child: Text('Miembro'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_filtrados.length} usuario(s)',
              style: const TextStyle(color: kGrey, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Lista — sin Expanded
            if (_cargando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: _kColor),
                ),
              )
            else if (_filtrados.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, color: kGrey, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'No hay usuarios registrados',
                        style: TextStyle(color: kGrey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...(_filtrados.map(
                (u) => _TarjetaUsuario(
                  usuario: u,
                  colorRol: _colorRol((u['rol'] ?? 'miembro').toString()),
                  onEditar: () => _abrirFormulario(usuario: u),
                  onEliminar: () => _eliminar(u),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta usuario ────────────────────────────────────
class _TarjetaUsuario extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final Color colorRol;
  final VoidCallback onEditar, onEliminar;
  const _TarjetaUsuario({
    required this.usuario,
    required this.colorRol,
    required this.onEditar,
    required this.onEliminar,
  });
  @override
  State<_TarjetaUsuario> createState() => _TarjetaUsuarioState();
}

class _TarjetaUsuarioState extends State<_TarjetaUsuario> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    final rol = (u['rol'] ?? 'miembro').toString();
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _h ? kBgCard : kBgMid,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _h ? _kColor.withValues(alpha: 0.3) : kDivider,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.colorRol.withValues(alpha: 0.15),
                border: Border.all(
                  color: widget.colorRol.withValues(alpha: 0.4),
                ),
              ),
              child: Center(
                child: Text(
                  (u['email'] ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    color: widget.colorRol,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u['email'] ?? '',
                    style: const TextStyle(
                      color: kWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [_Badge(rol.toUpperCase(), widget.colorRol)]),
                ],
              ),
            ),
            // Menu
            PopupMenuButton<String>(
              color: kBgCard,
              icon: const Icon(Icons.more_vert, color: kGrey, size: 20),
              onSelected: (v) {
                if (v == 'editar') widget.onEditar();
                if (v == 'eliminar') widget.onEliminar();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: _kColor, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Editar',
                        style: TextStyle(color: kWhite, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: kDanger, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Eliminar',
                        style: TextStyle(color: kDanger, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String texto;
  final Color color;
  const _Badge(this.texto, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      texto,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
    ),
  );
}

// ══════════════════════════════════════════════════════
//  FORMULARIO CREAR / EDITAR USUARIO
// ══════════════════════════════════════════════════════
class _FormUsuario extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final List<Map<String, dynamic>> miembros;
  const _FormUsuario({this.usuario, required this.miembros});
  @override
  State<_FormUsuario> createState() => _FormUsuarioState();
}

class _FormUsuarioState extends State<_FormUsuario> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _verPass = false;
  bool _guardando = false;
  String? _rol;
  String? _miembroId;
  String? _error;

  bool get _esEdicion => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _emailCtrl.text = widget.usuario!['email'] ?? '';
      _rol = widget.usuario!['rol'];
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'El email es obligatorio');
      return;
    }
    if (!_esEdicion && _passCtrl.text.trim().isEmpty) {
      setState(() => _error = 'La contrasena es obligatoria');
      return;
    }
    if (_rol == null) {
      setState(() => _error = 'Selecciona un rol');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      if (!_esEdicion) {
        final data = <String, dynamic>{
          'email': _emailCtrl.text.trim(),
          'contrasena': _passCtrl.text.trim(),
          'rol': _rol,
        };
        if (_miembroId != null) {
          data['idMiembro'] = int.tryParse(_miembroId!) ?? _miembroId;
        }
        await _sb.from('usuarios').insert(data);
      } else {
        final updates = <String, dynamic>{
          'email': _emailCtrl.text.trim(),
          'rol': _rol,
        };
        if (_passCtrl.text.trim().isNotEmpty) {
          updates['contrasena'] = _passCtrl.text.trim();
        }
        await _sb
            .from('usuarios')
            .update(updates)
            .eq('id', widget.usuario!['id']);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBgMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 480,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _kColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.manage_accounts,
                      color: _kColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _esEdicion ? 'Editar Usuario' : 'Nuevo Usuario',
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: kGrey, size: 20),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vincular miembro (solo al crear)
                    if (!_esEdicion) ...[
                      _lbl('VINCULAR A MIEMBRO (opcional)'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: kBgCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kDivider),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _miembroId,
                            isExpanded: true,
                            dropdownColor: kBgCard,
                            style: const TextStyle(color: kWhite, fontSize: 14),
                            hint: const Text(
                              'Sin vincular',
                              style: TextStyle(color: kGrey),
                            ),
                            onChanged: (v) => setState(() => _miembroId = v),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text(
                                  'Sin vincular',
                                  style: TextStyle(color: kGrey),
                                ),
                              ),
                              ...widget.miembros.map(
                                (m) => DropdownMenuItem(
                                  value: m['id'].toString(),
                                  child: Text(
                                    m['nombre'] ?? '',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    _lbl('CREDENCIALES DE ACCESO'),
                    const SizedBox(height: 10),
                    _tf(
                      _emailCtrl,
                      'Email *',
                      Icons.email_outlined,
                      tipo: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passCtrl,
                      obscureText: !_verPass,
                      style: const TextStyle(color: kWhite, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: _esEdicion
                            ? 'Nueva contrasena (opcional)'
                            : 'Contrasena *',
                        labelStyle: const TextStyle(color: kGrey, fontSize: 12),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: kGrey,
                          size: 16,
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _verPass = !_verPass),
                          child: Icon(
                            _verPass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: kGrey,
                            size: 18,
                          ),
                        ),
                        filled: true,
                        fillColor: kBgCard,
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
                          borderSide: const BorderSide(
                            color: _kColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _lbl('ROL EN EL SISTEMA'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kDivider),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _rol,
                          isExpanded: true,
                          dropdownColor: kBgCard,
                          style: const TextStyle(color: kWhite, fontSize: 14),
                          hint: const Text(
                            'Seleccionar rol *',
                            style: TextStyle(color: kGrey),
                          ),
                          onChanged: (v) => setState(() => _rol = v),
                          items: const [
                            DropdownMenuItem(
                              value: 'administrador',
                              child: Text('ADMINISTRADOR'),
                            ),
                            DropdownMenuItem(
                              value: 'pastor',
                              child: Text('PASTOR'),
                            ),
                            DropdownMenuItem(
                              value: 'lider',
                              child: Text('LIDER'),
                            ),
                            DropdownMenuItem(
                              value: 'miembro',
                              child: Text('MIEMBRO'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kDanger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: kDanger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: kDanger,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: kDanger,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Botones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                border: Border(top: BorderSide(color: kDivider)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kGrey,
                      side: const BorderSide(color: kDivider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _esEdicion ? 'Guardar cambios' : 'Crear usuario',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tf(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType tipo = TextInputType.text,
  }) => TextField(
    controller: ctrl,
    keyboardType: tipo,
    style: const TextStyle(color: kWhite, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kGrey, fontSize: 12),
      prefixIcon: Icon(icon, color: kGrey, size: 16),
      filled: true,
      fillColor: kBgCard,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );

  Widget _lbl(String t) => Text(
    t,
    style: const TextStyle(
      color: kGrey,
      fontSize: 11,
      letterSpacing: 2,
      fontWeight: FontWeight.w600,
    ),
  );
}
