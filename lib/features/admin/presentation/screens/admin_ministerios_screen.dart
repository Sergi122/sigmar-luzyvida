import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sigmar_page.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFF9C6FE4);

class AdminMinisteriosScreen extends StatefulWidget {
  const AdminMinisteriosScreen({super.key});
  @override
  State<AdminMinisteriosScreen> createState() => _AdminMinisteriosScreenState();
}

class _AdminMinisteriosScreenState extends State<AdminMinisteriosScreen> {
  List<Map<String, dynamic>> _ministerios = [];
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
      // Carga ministerios con sus miembros vinculados
      final data = await _sb
          .from('ministerios')
          .select(
            '*, ministerio_miembros(id, rol_ministerio, miembros(id, nombre))',
          )
          .order('nombre');
      setState(() {
        _ministerios = List<Map<String, dynamic>>.from(data);
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _msg('Error al cargar: $e', error: true);
    }
  }

  List<Map<String, dynamic>> get _filtrados {
    if (_busqueda.isEmpty) return _ministerios;
    return _ministerios.where((m) {
      final nombre = (m['nombre'] ?? '').toLowerCase();
      return nombre.contains(_busqueda.toLowerCase());
    }).toList();
  }

  void _msg(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? kDanger : kSuccess),
    );
  }

  void _abrirFormulario({Map<String, dynamic>? ministerio}) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormMinisterio(ministerio: ministerio),
    );
    if (ok == true) _cargar();
  }

  void _abrirMiembros(Map<String, dynamic> ministerio) async {
    await showDialog(
      context: context,
      builder: (_) => _GestionMiembros(ministerio: ministerio),
    );
    _cargar();
  }

  Future<void> _eliminar(Map<String, dynamic> m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogConfirm(
        titulo: 'Eliminar ministerio',
        mensaje:
            '¿Eliminar el ministerio "${m['nombre']}"? Se eliminarán también todos sus miembros vinculados.',
      ),
    );
    if (ok != true) return;
    try {
      await _sb.from('ministerios').delete().eq('id', m['id']);
      _msg('Ministerio eliminado');
      _cargar();
    } catch (e) {
      _msg('Error: $e', error: true);
    }
  }

  Future<void> _toggleEstado(Map<String, dynamic> m) async {
    final nuevo = m['estado'] == 'activo' ? 'inactivo' : 'activo';
    try {
      await _sb.from('ministerios').update({'estado': nuevo}).eq('id', m['id']);
      _msg('Estado cambiado a $nuevo');
      _cargar();
    } catch (e) {
      _msg('Error: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.of(context).size.width < 800;
    return SigmarPage(
      rutaActual: '/admin/ministerios',
      child: Padding(
        padding: EdgeInsets.all(movil ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
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
                    Icons.church_outlined,
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
                        'Gestión de Ministerios',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Administrar ministerios y sus integrantes',
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
                    'Nuevo Ministerio',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 50, height: 3, color: _kColor),
            const SizedBox(height: 20),

            // ── Buscador ─────────────────────────────────────────────
            TextField(
              onChanged: (v) => setState(() => _busqueda = v),
              style: const TextStyle(color: kWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar ministerio...',
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
            const SizedBox(height: 8),
            Text(
              '${_filtrados.length} ministerio${_filtrados.length != 1 ? 's' : ''}',
              style: const TextStyle(color: kGrey, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // ── Lista ─────────────────────────────────────────────────
            if (_cargando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: _kColor),
                ),
              )
            else if (_filtrados.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(Icons.church_outlined, color: kGrey, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _busqueda.isEmpty
                            ? 'No hay ministerios registrados'
                            : 'Sin resultados para "$_busqueda"',
                        style: const TextStyle(color: kGrey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...(_filtrados.map(
                (m) => _TarjetaMinisterio(
                  ministerio: m,
                  onEditar: () => _abrirFormulario(ministerio: m),
                  onMiembros: () => _abrirMiembros(m),
                  onEstado: () => _toggleEstado(m),
                  onEliminar: () => _eliminar(m),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de ministerio ──────────────────────────────────────────────────
class _TarjetaMinisterio extends StatefulWidget {
  final Map<String, dynamic> ministerio;
  final VoidCallback onEditar, onMiembros, onEstado, onEliminar;

  const _TarjetaMinisterio({
    required this.ministerio,
    required this.onEditar,
    required this.onMiembros,
    required this.onEstado,
    required this.onEliminar,
  });

  @override
  State<_TarjetaMinisterio> createState() => _TarjetaMinisterioState();
}

class _TarjetaMinisterioState extends State<_TarjetaMinisterio> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.ministerio;
    final activo = m['estado'] == 'activo';
    final miembros = (m['ministerio_miembros'] as List?) ?? [];
    final inicial = (m['nombre'] as String? ?? 'M')[0].toUpperCase();

    // Buscar el líder
    final liderEntries = miembros.where(
      (mm) => mm['rol_ministerio'] == 'lider',
    );
    final liderNombre = liderEntries.isNotEmpty
        ? (liderEntries.first['miembros']?['nombre'] ?? 'Sin líder')
        : 'Sin líder';

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _hover ? kBgCard : kBgMid,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hover ? _kColor.withValues(alpha: 0.3) : kDivider,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
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
                    fontSize: 20,
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (activo ? kSuccess : kDanger).withValues(
                            alpha: 0.1,
                          ),
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
                  const SizedBox(height: 3),
                  if ((m['descripcion'] ?? '').isNotEmpty)
                    Text(
                      m['descripcion'],
                      style: const TextStyle(color: kGrey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, color: kGrey, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${miembros.length} integrante${miembros.length != 1 ? 's' : ''}',
                        style: const TextStyle(color: kGrey, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.star_outline, color: kGrey, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        liderNombre,
                        style: const TextStyle(color: kGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Botón gestionar miembros
            TextButton.icon(
              onPressed: widget.onMiembros,
              style: TextButton.styleFrom(
                foregroundColor: _kColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              icon: const Icon(Icons.group_outlined, size: 16),
              label: const Text('Miembros', style: TextStyle(fontSize: 12)),
            ),

            // Menú
            PopupMenuButton<String>(
              color: kBgCard,
              icon: const Icon(Icons.more_vert, color: kGrey, size: 20),
              onSelected: (v) {
                if (v == 'editar') widget.onEditar();
                if (v == 'estado') widget.onEstado();
                if (v == 'borrar') widget.onEliminar();
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
                PopupMenuItem(
                  value: 'estado',
                  child: Row(
                    children: [
                      Icon(
                        activo
                            ? Icons.block_outlined
                            : Icons.check_circle_outline,
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

// ── Formulario crear/editar ministerio ────────────────────────────────────
class _FormMinisterio extends StatefulWidget {
  final Map<String, dynamic>? ministerio;
  const _FormMinisterio({this.ministerio});
  @override
  State<_FormMinisterio> createState() => _FormMinisterioState();
}

class _FormMinisterioState extends State<_FormMinisterio> {
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _estado = 'activo';
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.ministerio != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreCtrl.text = widget.ministerio!['nombre'] ?? '';
      _descCtrl.text = widget.ministerio!['descripcion'] ?? '';
      _estado = widget.ministerio!['estado'] ?? 'activo';
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      setState(() => _error = 'El nombre es obligatorio.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    final datos = {
      'nombre': _nombreCtrl.text.trim(),
      'descripcion': _descCtrl.text.trim(),
      'estado': _estado,
    };
    try {
      if (_esEdicion) {
        await _sb
            .from('ministerios')
            .update(datos)
            .eq('id', widget.ministerio!['id']);
      } else {
        await _sb.from('ministerios').insert(datos);
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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.church_outlined,
                    color: _kColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _esEdicion ? 'Editar Ministerio' : 'Nuevo Ministerio',
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
            const SizedBox(height: 24),

            const Text(
              'NOMBRE',
              style: TextStyle(color: kGrey, fontSize: 11, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nombreCtrl,
              style: const TextStyle(color: kWhite),
              decoration: _deco('Nombre del ministerio', Icons.church_outlined),
            ),
            const SizedBox(height: 16),

            const Text(
              'DESCRIPCIÓN',
              style: TextStyle(color: kGrey, fontSize: 11, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              style: const TextStyle(color: kWhite),
              maxLines: 3,
              decoration: _deco(
                'Descripción (opcional)',
                Icons.description_outlined,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'ESTADO',
              style: TextStyle(color: kGrey, fontSize: 11, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
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
                    DropdownMenuItem(value: 'activo', child: Text('Activo')),
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
                  border: Border.all(color: kDanger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: kDanger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: kDanger, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            Row(
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
                          _esEdicion ? 'Guardar cambios' : 'Crear ministerio',
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

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: kGrey, fontSize: 13),
    prefixIcon: Icon(icon, color: kGrey),
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
  );
}

// ── Gestión de miembros del ministerio ────────────────────────────────────
class _GestionMiembros extends StatefulWidget {
  final Map<String, dynamic> ministerio;
  const _GestionMiembros({required this.ministerio});
  @override
  State<_GestionMiembros> createState() => _GestionMiembrosState();
}

class _GestionMiembrosState extends State<_GestionMiembros> {
  List<Map<String, dynamic>> _miembrosMinisterio = [];
  List<Map<String, dynamic>> _todosLosMiembros = [];
  int? _miembroSeleccionado;
  String _rolSeleccionado = 'integrante';
  bool _cargando = true;
  bool _agregando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      // Miembros del ministerio
      final vinculados = await _sb
          .from('ministerio_miembros')
          .select('id, rol_ministerio, miembros(id, nombre)')
          .eq('id_ministerio', widget.ministerio['id']);

      // Todos los miembros activos
      final todos = await _sb
          .from('miembros')
          .select('id, nombre')
          .eq('estado', 'activo')
          .order('nombre');

      // IDs ya vinculados para excluirlos del dropdown
      final idsVinculados = (vinculados as List)
          .map((v) => v['miembros']?['id'] as int?)
          .whereType<int>()
          .toList();

      setState(() {
        _miembrosMinisterio = List<Map<String, dynamic>>.from(vinculados);
        _todosLosMiembros = (todos as List)
            .map((m) => Map<String, dynamic>.from(m))
            .where((m) => !idsVinculados.contains(m['id'] as int))
            .toList();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _agregar() async {
    if (_miembroSeleccionado == null) return;
    setState(() => _agregando = true);
    try {
      await _sb.from('ministerio_miembros').insert({
        'id_ministerio': widget.ministerio['id'],
        'id_miembro': _miembroSeleccionado,
        'rol_ministerio': _rolSeleccionado,
      });
      setState(() {
        _miembroSeleccionado = null;
        _rolSeleccionado = 'integrante';
      });
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kDanger),
        );
      }
    } finally {
      setState(() => _agregando = false);
    }
  }

  Future<void> _eliminarMiembro(int idVinculo, String nombre) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogConfirm(
        titulo: 'Quitar miembro',
        mensaje: '¿Quitar a $nombre del ministerio?',
      ),
    );
    if (ok != true) return;
    await _sb.from('ministerio_miembros').delete().eq('id', idVinculo);
    await _cargar();
  }

  Future<void> _cambiarRol(int idVinculo, String nuevoRol) async {
    await _sb
        .from('ministerio_miembros')
        .update({'rol_ministerio': nuevoRol})
        .eq('id', idVinculo);
    await _cargar();
  }

  Color _colorRol(String rol) {
    switch (rol) {
      case 'lider':
        return const Color(0xFFFFD700);
      case 'co-lider':
        return const Color(0xFF378ADD);
      default:
        return _kColor;
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
                      Icons.group_outlined,
                      color: _kColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ministerio['nombre'] ?? '',
                          style: const TextStyle(
                            color: kWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Gestión de integrantes',
                          style: TextStyle(color: kGrey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: kGrey, size: 20),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Agregar miembro ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _kColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AGREGAR INTEGRANTE',
                            style: TextStyle(
                              color: kGrey,
                              fontSize: 11,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kBgMid,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: kDivider),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _miembroSeleccionado,
                                      isExpanded: true,
                                      dropdownColor: kBgMid,
                                      hint: const Text(
                                        'Seleccionar miembro',
                                        style: TextStyle(
                                          color: kGrey,
                                          fontSize: 13,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: kWhite,
                                        fontSize: 13,
                                      ),
                                      onChanged: (v) => setState(
                                        () => _miembroSeleccionado = v,
                                      ),
                                      items: _todosLosMiembros
                                          .map(
                                            (m) => DropdownMenuItem<int>(
                                              value: m['id'] as int,
                                              child: Text(
                                                m['nombre'] ?? '',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kBgMid,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: kDivider),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _rolSeleccionado,
                                      isExpanded: true,
                                      dropdownColor: kBgMid,
                                      style: const TextStyle(
                                        color: kWhite,
                                        fontSize: 13,
                                      ),
                                      onChanged: (v) =>
                                          setState(() => _rolSeleccionado = v!),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'integrante',
                                          child: Text('Integrante'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'lider',
                                          child: Text('Líder'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'co-lider',
                                          child: Text('Co-líder'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed:
                                    (_miembroSeleccionado == null || _agregando)
                                    ? null
                                    : _agregar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _kColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: _agregando
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.add, size: 18),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Lista de integrantes actuales ────────────────
                    Text(
                      'INTEGRANTES (${_miembrosMinisterio.length})',
                      style: const TextStyle(
                        color: kGrey,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_cargando)
                      const Center(
                        child: CircularProgressIndicator(color: _kColor),
                      )
                    else if (_miembrosMinisterio.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kBgCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kDivider),
                        ),
                        child: const Center(
                          child: Text(
                            'No hay integrantes aún',
                            style: TextStyle(color: kGrey, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ..._miembrosMinisterio.map((mm) {
                        final nombre = mm['miembros']?['nombre'] ?? '';
                        final rol = mm['rol_ministerio'] ?? 'integrante';
                        final colorRol = _colorRol(rol);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: kBgCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kDivider),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: colorRol.withValues(
                                  alpha: 0.15,
                                ),
                                child: Text(
                                  nombre.isNotEmpty
                                      ? nombre[0].toUpperCase()
                                      : '?',
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
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
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
                                  ],
                                ),
                              ),

                              // Cambiar rol
                              PopupMenuButton<String>(
                                color: kBgCard,
                                tooltip: 'Cambiar rol',
                                icon: const Icon(
                                  Icons.swap_horiz,
                                  color: kGrey,
                                  size: 18,
                                ),
                                onSelected: (nuevoRol) =>
                                    _cambiarRol(mm['id'] as int, nuevoRol),
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'integrante',
                                    child: Text(
                                      'Integrante',
                                      style: TextStyle(color: kWhite),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'lider',
                                    child: Text(
                                      'Líder',
                                      style: TextStyle(color: kWhite),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'co-lider',
                                    child: Text(
                                      'Co-líder',
                                      style: TextStyle(color: kWhite),
                                    ),
                                  ),
                                ],
                              ),

                              // Eliminar
                              IconButton(
                                icon: const Icon(
                                  Icons.person_remove_outlined,
                                  color: kDanger,
                                  size: 18,
                                ),
                                tooltip: 'Quitar del ministerio',
                                onPressed: () =>
                                    _eliminarMiembro(mm['id'] as int, nombre),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
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
                    child: const Text(
                      'Listo',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

// ── Diálogo de confirmación ────────────────────────────────────────────────
class _DialogConfirm extends StatelessWidget {
  final String titulo, mensaje;
  const _DialogConfirm({required this.titulo, required this.mensaje});

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
                  backgroundColor: kDanger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirmar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
