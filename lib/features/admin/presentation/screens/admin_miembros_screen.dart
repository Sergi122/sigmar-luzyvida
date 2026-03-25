import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sigmar_page.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFF7F77DD);

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
      final data = await _sb.from('miembros').select().order('nombre');
      setState(() {
        _miembros = List<Map<String, dynamic>>.from(data);
        _filtrar();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _msg('Error: $e', error: true);
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

  void _msg(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: error ? kDanger : kSuccess),
    );
  }

  Future<void> _cambiarEstado(Map<String, dynamic> m) async {
    final nuevo = m['estado'] == 'activo' ? 'inactivo' : 'activo';
    await _sb.from('miembros').update({'estado': nuevo}).eq('id', m['id']);
    _msg('Estado cambiado a $nuevo');
    _cargar();
  }

  Future<void> _eliminar(Map<String, dynamic> m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogConfirm(
        titulo: 'Eliminar miembro',
        mensaje: '¿Eliminar a ${m['nombre']}?',
      ),
    );
    if (ok != true) return;
    await _sb.from('miembros').delete().eq('id', m['id']);
    _msg('Miembro eliminado');
    _cargar();
  }

  void _abrirFormulario({Map<String, dynamic>? miembro}) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormMiembro(miembro: miembro),
    );
    if (ok == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.of(context).size.width < 800;
    return SigmarPage(
      rutaActual: '/admin/miembros',
      child: Padding(
        padding: EdgeInsets.all(movil ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (movil) ...[
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _kColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.people_outlined,
                      color: _kColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestion de Miembros',
                          style: TextStyle(
                            color: kWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Administrar miembros',
                          style: TextStyle(color: kGrey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _abrirFormulario(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
              ),
            ] else ...[
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
            ],
            const SizedBox(height: 8),
            Container(width: 50, height: 3, color: _kColor),
            const SizedBox(height: 20),
            movil
                ? Column(
                    children: [
                      _Buscador(
                        onChanged: (v) => setState(() {
                          _busqueda = v;
                          _filtrar();
                        }),
                      ),
                      const SizedBox(height: 10),
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
            Text(
              '${_filtrados.length} miembro${_filtrados.length != 1 ? 's' : ''}',
              style: const TextStyle(color: kGrey, fontSize: 12),
            ),
            const SizedBox(height: 16),
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
                ),
              )),
          ],
        ),
      ),
    );
  }
}

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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
  );
}

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
          DropdownMenuItem(value: 'visita', child: Text('Visitas')),
        ],
      ),
    ),
  );
}

class _TarjetaMiembro extends StatefulWidget {
  final Map<String, dynamic> miembro;
  final VoidCallback onEditar, onEstado, onEliminar;
  const _TarjetaMiembro({
    required this.miembro,
    required this.onEditar,
    required this.onEstado,
    required this.onEliminar,
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
        child: Row(
          children: [
            Stack(
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
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m['nombre'] ?? '',
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
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
                  Text(
                    m['direccion'] ?? '',
                    style: const TextStyle(color: kGrey, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
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

// ── Formulario ────────────────────────────────────────
class _FormMiembro extends StatefulWidget {
  final Map<String, dynamic>? miembro;
  const _FormMiembro({this.miembro});
  @override
  State<_FormMiembro> createState() => _FormMiembroState();
}

class _FormMiembroState extends State<_FormMiembro> {
  final _nombreCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  final _carnetCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
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
      // ✅ nueva columna snake_case
      _fechaConvCtrl.text = m['fecha_conversion'] ?? '';
      _bautizado = m['bautizado'] ?? false;
      _encuentro = m['asistio_encuentro'] ?? false;
      _estado = m['estado'] ?? 'activo';
    } else {
      _fechaConvCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _edadCtrl.dispose();
    _carnetCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
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
    // ✅ snake_case en todos los campos
    final datos = {
      'nombre': _nombreCtrl.text.trim(),
      'edad': int.tryParse(_edadCtrl.text.trim()) ?? 0,
      'carnet': _carnetCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
      'fecha_conversion': _fechaConvCtrl.text.trim(),
      'bautizado': _bautizado,
      'asistio_encuentro': _encuentro,
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
        width: 560,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Sec('DATOS PERSONALES'),
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
                    _Campo(
                      'Teléfono',
                      _telefonoCtrl,
                      Icons.phone_outlined,
                      tipo: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _Campo(
                      'Dirección',
                      _direccionCtrl,
                      Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 20),
                    _Sec('DATOS ESPIRITUALES'),
                    const SizedBox(height: 12),
                    _Campo(
                      'Fecha de conversión (AAAA-MM-DD)',
                      _fechaConvCtrl,
                      Icons.calendar_today_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Sw(
                            'Bautizado',
                            _bautizado,
                            (v) => setState(() => _bautizado = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Sw(
                            'Asistió a encuentro',
                            _encuentro,
                            (v) => setState(() => _encuentro = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _Sec('ESTADO'),
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
                            DropdownMenuItem(
                              value: 'visita',
                              child: Text('Visita'),
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

class _Sec extends StatelessWidget {
  final String t;
  const _Sec(this.t);
  @override
  Widget build(BuildContext context) => Text(
    t,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
  );
}

class _Sw extends StatelessWidget {
  final String label;
  final bool valor;
  final ValueChanged<bool> onChanged;
  const _Sw(this.label, this.valor, this.onChanged);
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
                  'Eliminar',
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
