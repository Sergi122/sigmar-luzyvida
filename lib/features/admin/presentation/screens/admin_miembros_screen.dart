import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sigmar_page.dart';
import 'registro_usuario_screen.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFF7F77DD); // purple admin

// ══════════════════════════════════════════════════════
//  PANTALLA PRINCIPAL
// ══════════════════════════════════════════════════════
class AdminMiembrosScreen extends StatefulWidget {
  const AdminMiembrosScreen({super.key});
  @override
  State<AdminMiembrosScreen> createState() => _AdminMiembrosScreenState();
}

class _AdminMiembrosScreenState extends State<AdminMiembrosScreen> {
  List<Map<String, dynamic>> _miembros = [];
  List<Map<String, dynamic>> _filtrados = [];
  bool _cargando = true;
  String _busqueda = '';
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final data = await _sb
          .from('miembros')
          .select('*, usuarios!miembro_id(id)')
          .order('nombre');
      setState(() {
        _miembros = List<Map<String, dynamic>>.from(data).map((m) {
          final usuarios = m['usuarios'] as List?;
          m['tieneUsuario'] = usuarios != null && usuarios.isNotEmpty;
          return m;
        }).toList();
        _filtrar();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError('Error al cargar miembros: $e');
    }
  }

  void _filtrar() {
    _filtrados = _miembros.where((m) {
      final nombre = (m['nombre'] ?? '').toLowerCase();
      final carnet = (m['carnet'] ?? '').toLowerCase();
      final buscado = _busqueda.toLowerCase();
      final pasaBusqueda =
          _busqueda.isEmpty ||
          nombre.contains(buscado) ||
          carnet.contains(buscado);
      final pasaEstado =
          _filtroEstado == 'todos' || (m['estado'] ?? '') == _filtroEstado;
      return pasaBusqueda && pasaEstado;
    }).toList();
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: kDanger));
  }

  void _mostrarExito(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: kSuccess));
  }

  Future<void> _cambiarEstado(Map<String, dynamic> m) async {
    final nuevoEstado = m['estado'] == 'activo' ? 'inactivo' : 'activo';
    try {
      await _sb
          .from('miembros')
          .update({'estado': nuevoEstado})
          .eq('id', m['id']);
      _mostrarExito('Estado cambiado a $nuevoEstado');
      _cargar();
    } catch (e) {
      _mostrarError('Error: $e');
    }
  }

  Future<void> _eliminar(Map<String, dynamic> m) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoConfirmar(
        titulo: 'Eliminar miembro',
        mensaje:
            '¿Eliminar a ${m['nombre']}? Esta acción no se puede deshacer.',
        colorBoton: kDanger,
        textoBoton: 'Eliminar',
      ),
    );
    if (confirma != true) return;
    try {
      await _sb.from('miembros').delete().eq('id', m['id']);
      _mostrarExito('Miembro eliminado');
      _cargar();
    } catch (e) {
      _mostrarError('Error al eliminar: $e');
    }
  }

  void _abrirFormulario({Map<String, dynamic>? miembro}) async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormularioMiembro(miembro: miembro),
    );
    if (resultado == true) _cargar();
  }

  void _abrirGestionUsuario({Map<String, dynamic>? miembro}) async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        if (miembro != null && miembro['tieneUsuario'] == true) {
          // Buscar el usuario vinculado
          final usuarios = miembro['usuarios'] as List?;
          if (usuarios != null && usuarios.isNotEmpty) {
            return RegistroUsuarioScreen(usuarioParaEditar: usuarios[0]);
          }
        }
        // Crear nuevo usuario vinculado al miembro
        return RegistroUsuarioScreen(
          usuarioParaEditar: null,
        );
      },
    );
    if (resultado == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.of(context).size.width < 800;
    return SigmarPage(
      rutaActual: '/admin/miembros',
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
                    Icons.people_outlined,
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
                        'Gestion de Miembros',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Administrar todos los miembros de la iglesia',
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
                    'Nuevo Miembro',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 50, height: 3, color: _kColor),
            const SizedBox(height: 24),

            // Barra de busqueda y filtros
            movil
                ? Column(
                    children: [
                      _Buscador(
                        onChanged: (v) => setState(() {
                          _busqueda = v;
                          _filtrar();
                        }),
                      ),
                      const SizedBox(height: 12),
                      _FiltroEstado(
                        valor: _filtroEstado,
                        onChanged: (v) => setState(() {
                          _filtroEstado = v;
                          _filtrar();
                        }),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _Buscador(
                          onChanged: (v) => setState(() {
                            _busqueda = v;
                            _filtrar();
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _FiltroEstado(
                        valor: _filtroEstado,
                        onChanged: (v) => setState(() {
                          _filtroEstado = v;
                          _filtrar();
                        }),
                      ),
                    ],
                  ),
            const SizedBox(height: 8),

            // Contador
            Text(
              '${_filtrados.length} miembro${_filtrados.length != 1 ? 's' : ''}',
              style: const TextStyle(color: kGrey, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Lista
            if (_cargando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: _kColor),
                ),
              )
            else if (_filtrados.isEmpty)
              _EmptyState(busqueda: _busqueda)
            else
              ...(_filtrados.map(
                (m) => _TarjetaMiembro(
                  miembro: m,
                  onEditar: () => _abrirFormulario(miembro: m),
                  onEstado: () => _cambiarEstado(m),
                  onEliminar: () => _eliminar(m),
                  onGestionarUsuario: () => _abrirGestionUsuario(miembro: m),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

// ── Buscador ──────────────────────────────────────────
class _Buscador extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _Buscador({required this.onChanged});
  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    style: const TextStyle(color: kWhite, fontSize: 14),
    decoration: InputDecoration(
      hintText: 'Buscar por nombre o carnet...',
      hintStyle: const TextStyle(color: kGrey, fontSize: 13),
      prefixIcon: const Icon(Icons.search, color: kGrey, size: 18),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}

// ── Filtro estado ─────────────────────────────────────
class _FiltroEstado extends StatelessWidget {
  final String valor;
  final ValueChanged<String> onChanged;
  const _FiltroEstado({required this.valor, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: kBgCard,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: kDivider),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: valor,
        dropdownColor: kBgCard,
        style: const TextStyle(color: kWhite, fontSize: 13),
        onChanged: (v) => onChanged(v!),
        items: const [
          DropdownMenuItem(value: 'todos', child: Text('Todos')),
          DropdownMenuItem(value: 'activo', child: Text('Activos')),
          DropdownMenuItem(value: 'inactivo', child: Text('Inactivos')),
        ],
      ),
    ),
  );
}

// ── Tarjeta de miembro ────────────────────────────────
class _TarjetaMiembro extends StatefulWidget {
  final Map<String, dynamic> miembro;
  final VoidCallback onEditar, onEstado, onEliminar;
  final VoidCallback? onGestionarUsuario;
  const _TarjetaMiembro({
    required this.miembro,
    required this.onEditar,
    required this.onEstado,
    required this.onEliminar,
    this.onGestionarUsuario,
  });
  @override
  State<_TarjetaMiembro> createState() => _TarjetaMiembroState();
}

class _TarjetaMiembroState extends State<_TarjetaMiembro> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final m = widget.miembro;
    final activo = m['estado'] == 'activo';
    final inicial = (m['nombre'] ?? 'M')[0].toUpperCase();
    final movil = MediaQuery.of(context).size.width < 700;

    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _h ? kBgCard : kBgMid,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _h ? _kColor.withValues(alpha: 0.3) : kDivider,
          ),
        ),
        child: movil
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Avatar(inicial: inicial, activo: activo),
                      const SizedBox(width: 12),
                      Expanded(child: _InfoMiembro(m: m)),
                      _MenuAcciones(
                        onEditar: widget.onEditar,
                        onEstado: widget.onEstado,
                        onEliminar: widget.onEliminar,
                        activo: activo,
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  _Avatar(inicial: inicial, activo: activo),
                  const SizedBox(width: 14),
                  Expanded(child: _InfoMiembro(m: m)),
                  _Chips(m: m),
                  const SizedBox(width: 12),
                  _MenuAcciones(
                    onEditar: widget.onEditar,
                    onEstado: widget.onEstado,
                    onEliminar: widget.onEliminar,
                    activo: activo,
                  ),
                ],
              ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String inicial;
  final bool activo;
  const _Avatar({required this.inicial, required this.activo});
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _kColor.withValues(alpha: 0.15),
          border: Border.all(color: _kColor.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text(
            inicial,
            style: const TextStyle(
              color: _kColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activo ? kSuccess : kDanger,
            border: Border.all(color: kBgMid, width: 2),
          ),
        ),
      ),
    ],
  );
}

class _InfoMiembro extends StatelessWidget {
  final Map<String, dynamic> m;
  const _InfoMiembro({required this.m});
  @override
  Widget build(BuildContext context) {
    final tieneUsuario = m['tieneUsuario'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              m['nombre'] ?? '',
              style: const TextStyle(
                color: kWhite,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            if (tieneUsuario)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'USUARIO',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            const Icon(Icons.badge_outlined, color: kGrey, size: 12),
            const SizedBox(width: 4),
            Text(
              m['carnet'] ?? '',
              style: const TextStyle(color: kGrey, fontSize: 12),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.phone_outlined, color: kGrey, size: 12),
            const SizedBox(width: 4),
            Text(
              '${m['telefono'] ?? ''}',
              style: const TextStyle(color: kGrey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          m['direccion'] ?? '',
          style: const TextStyle(color: kGrey, fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _Chips extends StatelessWidget {
  final Map<String, dynamic> m;
  const _Chips({required this.m});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Chip(m['ministerio'] ?? '', const Color(0xFF1D9E75)),
      const SizedBox(width: 6),
      _Chip(
        m['bautizado'] == true ? 'Bautizado' : 'Sin bautismo',
        m['bautizado'] == true ? kSuccess : kGrey,
      ),
    ],
  );
}

class _Chip extends StatelessWidget {
  final String texto;
  final Color color;
  const _Chip(this.texto, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      texto,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
    ),
  );
}

class _MenuAcciones extends StatelessWidget {
  final VoidCallback onEditar, onEstado, onEliminar;
  final VoidCallback? onGestionarUsuario;
  final bool activo;
  const _MenuAcciones({
    required this.onEditar,
    required this.onEstado,
    required this.onEliminar,
    this.onGestionarUsuario,
    required this.activo,
  });
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    color: kBgCard,
    icon: const Icon(Icons.more_vert, color: kGrey, size: 20),
    onSelected: (v) {
      if (v == 'editar') onEditar();
      if (v == 'estado') onEstado();
      if (v == 'borrar') onEliminar();
      if (v == 'usuario') onGestionarUsuario?.call();
    },
    itemBuilder: (_) => [
      PopupMenuItem(
        value: 'usuario',
        child: Row(
          children: [
            Icon(Icons.login_outlined, color: _kColor, size: 16),
            const SizedBox(width: 8),
            Text('Gestionar Usuario', style: TextStyle(color: kWhite, fontSize: 13)),
          ],
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: 'editar',
        child: Row(
          children: [
            Icon(Icons.edit_outlined, color: _kColor, size: 16),
            SizedBox(width: 8),
            Text('Editar', style: TextStyle(color: kWhite, fontSize: 13)),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'estado',
        child: Row(
          children: [
            Icon(
              activo ? Icons.block_outlined : Icons.check_circle_outline,
              color: activo ? kDanger : kSuccess,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              activo ? 'Desactivar' : 'Activar',
              style: const TextStyle(color: kWhite, fontSize: 13),
            ),
          ],
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: 'borrar',
        child: Row(
          children: [
            Icon(Icons.delete_outline, color: kDanger, size: 16),
            SizedBox(width: 8),
            Text('Eliminar', style: TextStyle(color: kDanger, fontSize: 13)),
          ],
        ),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  final String busqueda;
  const _EmptyState({required this.busqueda});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            busqueda.isEmpty ? Icons.people_outline : Icons.search_off,
            color: kGrey,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            busqueda.isEmpty
                ? 'No hay miembros registrados'
                : 'Sin resultados para "$busqueda"',
            style: const TextStyle(color: kGrey, fontSize: 14),
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════
//  FORMULARIO CREAR / EDITAR MIEMBRO
// ══════════════════════════════════════════════════════
class _FormularioMiembro extends StatefulWidget {
  final Map<String, dynamic>? miembro;
  const _FormularioMiembro({this.miembro});
  @override
  State<_FormularioMiembro> createState() => _FormularioMiembroState();
}

class _FormularioMiembroState extends State<_FormularioMiembro> {
  final _nombreCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  final _carnetCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _ministerioCtrl = TextEditingController();
  final _fechaConvCtrl = TextEditingController();

  bool _bautizado = false;
  bool _encuentro = false;
  String _estado = 'activo';
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.miembro != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      final m = widget.miembro!;
      _nombreCtrl.text = m['nombre'] ?? '';
      _edadCtrl.text = '${m['edad'] ?? ''}';
      _carnetCtrl.text = m['carnet'] ?? '';
      _telefonoCtrl.text = '${m['telefono'] ?? ''}';
      _direccionCtrl.text = m['direccion'] ?? '';
      _ministerioCtrl.text = m['ministerio'] ?? '';
      _fechaConvCtrl.text = m['fechaConversion'] ?? '';
      _bautizado = m['bautizado'] ?? false;
      _encuentro = m['asistioEncuentro'] ?? false;
      _estado = m['estado'] ?? 'activo';
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _edadCtrl.dispose();
    _carnetCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _ministerioCtrl.dispose();
    _fechaConvCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty || _carnetCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Nombre y carnet son obligatorios.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });

    final datos = {
      'nombre': _nombreCtrl.text.trim(),
      'edad': int.tryParse(_edadCtrl.text.trim()) ?? 0,
      'carnet': _carnetCtrl.text.trim(),
      'telefono': int.tryParse(_telefonoCtrl.text.trim()) ?? 0,
      'direccion': _direccionCtrl.text.trim(),
      'ministerio': _ministerioCtrl.text.trim(),
      'fechaConversion': _fechaConvCtrl.text.trim(),
      'bautizado': _bautizado,
      'asistioEncuentro': _encuentro,
      'estado': _estado,
    };

    try {
      if (_esEdicion) {
        await _sb
            .from('miembros')
            .update(datos)
            .eq('id', widget.miembro!['id']);
      } else {
        await _sb.from('miembros').insert(datos);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = 'Error al guardar: $e';
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
        width: 560,
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
                      Icons.person_outlined,
                      color: _kColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _esEdicion ? 'Editar Miembro' : 'Nuevo Miembro',
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

            // Formulario
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Seccion('DATOS PERSONALES'),
                    const SizedBox(height: 12),
                    _Campo(
                      'Nombre completo *',
                      _nombreCtrl,
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Campo(
                            'Carnet *',
                            _carnetCtrl,
                            Icons.badge_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Campo(
                            'Edad',
                            _edadCtrl,
                            Icons.cake_outlined,
                            tipo: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Campo(
                            'Telefono',
                            _telefonoCtrl,
                            Icons.phone_outlined,
                            tipo: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Campo(
                            'Ministerio',
                            _ministerioCtrl,
                            Icons.church_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Campo(
                      'Direccion',
                      _direccionCtrl,
                      Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 20),

                    _Seccion('DATOS ESPIRITUALES'),
                    const SizedBox(height: 12),
                    _Campo(
                      'Fecha de conversion (AAAA-MM-DD)',
                      _fechaConvCtrl,
                      Icons.calendar_today_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Switch(
                            'Bautizado',
                            _bautizado,
                            (v) => setState(() => _bautizado = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Switch(
                            'Asistio a encuentro',
                            _encuentro,
                            (v) => setState(() => _encuentro = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _Seccion('ESTADO'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kDivider),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _estado,
                          isExpanded: true,
                          dropdownColor: kBgCard,
                          style: const TextStyle(color: kWhite, fontSize: 14),
                          onChanged: (v) => setState(() => _estado = v!),
                          items: const [
                            DropdownMenuItem(
                              value: 'activo',
                              child: Text('Activo'),
                            ),
                            DropdownMenuItem(
                              value: 'inactivo',
                              child: Text('Inactivo'),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
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
                            _esEdicion
                                ? 'Guardar cambios'
                                : 'Registrar miembro',
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
}

// ── Widgets auxiliares del formulario ─────────────────
class _Seccion extends StatelessWidget {
  final String texto;
  const _Seccion(this.texto);
  @override
  Widget build(BuildContext context) => Text(
    texto,
    style: const TextStyle(
      color: kGrey,
      fontSize: 11,
      letterSpacing: 2,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _Campo extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icono;
  final TextInputType tipo;
  const _Campo(
    this.label,
    this.ctrl,
    this.icono, {
    this.tipo = TextInputType.text,
  });
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: tipo,
    style: const TextStyle(color: kWhite, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kGrey, fontSize: 12),
      prefixIcon: Icon(icono, color: kGrey, size: 16),
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
}

class _Switch extends StatelessWidget {
  final String label;
  final bool valor;
  final ValueChanged<bool> onChanged;
  const _Switch(this.label, this.valor, this.onChanged);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: kBgCard,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: kDivider),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: kGrey, fontSize: 13)),
        Switch(
          value: valor,
          onChanged: onChanged,
          activeColor: _kColor,
          activeTrackColor: _kColor.withValues(alpha: 0.3),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
//  DIALOGO CONFIRMACION
// ══════════════════════════════════════════════════════
class _DialogoConfirmar extends StatelessWidget {
  final String titulo, mensaje, textoBoton;
  final Color colorBoton;
  const _DialogoConfirmar({
    required this.titulo,
    required this.mensaje,
    required this.textoBoton,
    required this.colorBoton,
  });
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: kBgMid,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Container(
      width: 380,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: kWhite,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            mensaje,
            style: const TextStyle(color: kGrey, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
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
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorBoton,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  textoBoton,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
