import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sigmar_page.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFF7F77DD);

const _diasSemana = [
  'lunes',
  'martes',
  'miercoles',
  'jueves',
  'viernes',
  'sabado',
  'domingo',
];

class AdminGruposScreen extends StatefulWidget {
  const AdminGruposScreen({super.key});
  @override
  State<AdminGruposScreen> createState() => _AdminGruposScreenState();
}

class _AdminGruposScreenState extends State<AdminGruposScreen> {
  List<Map<String, dynamic>> _grupos = [];
  List<Map<String, dynamic>> _filtrados = [];
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
      // ✅ join con miembros para obtener nombre del lider (id_lider)
      final data = await _sb
          .from('grupos')
          .select('*, miembros!grupos_id_lider_fkey(nombre)')
          .order('nombre');
      setState(() {
        _grupos = List<Map<String, dynamic>>.from(data);
        _filtrar();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _msg('Error: $e', error: true);
    }
  }

  void _filtrar() {
    _filtrados = _grupos.where((g) {
      final nombre = (g['nombre'] ?? '').toLowerCase();
      return _busqueda.isEmpty || nombre.contains(_busqueda.toLowerCase());
    }).toList();
  }

  void _msg(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: error ? kDanger : kSuccess),
    );
  }

  Future<void> _eliminar(Map<String, dynamic> g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogConfirm(
        titulo: 'Eliminar grupo',
        mensaje: '¿Eliminar el grupo "${g['nombre']}"?',
      ),
    );
    if (ok != true) return;
    await _sb.from('grupos').delete().eq('id', g['id']);
    _msg('Grupo eliminado');
    _cargar();
  }

  void _abrirFormulario({Map<String, dynamic>? grupo}) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormGrupo(grupo: grupo),
    );
    if (ok == true) _cargar();
  }

  void _verMiembros(Map<String, dynamic> g) {
    showDialog(
      context: context,
      builder: (_) => _DialogMiembrosGrupo(grupo: g),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.of(context).size.width < 800;
    return SigmarPage(
      rutaActual: '/admin/grupos',
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
                    Icons.group_outlined,
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
                        'Gestion de Grupos',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Administrar grupos de reunión',
                        style: TextStyle(color: kGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (!movil)
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
                      'Nuevo Grupo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            if (movil) ...[
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
                    'Nuevo Grupo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Container(width: 50, height: 3, color: _kColor),
            const SizedBox(height: 20),
            TextField(
              onChanged: (v) => setState(() {
                _busqueda = v;
                _filtrar();
              }),
              style: const TextStyle(color: kWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar grupo por nombre...',
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
              '${_filtrados.length} grupo${_filtrados.length != 1 ? 's' : ''}',
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
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    'No hay grupos registrados',
                    style: TextStyle(color: kGrey, fontSize: 14),
                  ),
                ),
              )
            else
              ...(_filtrados.map(
                (g) => _TarjetaGrupo(
                  grupo: g,
                  onEditar: () => _abrirFormulario(grupo: g),
                  onEliminar: () => _eliminar(g),
                  onVerMiembros: () => _verMiembros(g),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

class _TarjetaGrupo extends StatefulWidget {
  final Map<String, dynamic> grupo;
  final VoidCallback onEditar, onEliminar, onVerMiembros;
  const _TarjetaGrupo({
    required this.grupo,
    required this.onEditar,
    required this.onEliminar,
    required this.onVerMiembros,
  });
  @override
  State<_TarjetaGrupo> createState() => _TarjetaGrupoState();
}

class _TarjetaGrupoState extends State<_TarjetaGrupo> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final g = widget.grupo;
    final activo = g['estado'] == 'activo';
    // ✅ nombre del lider via join
    final liderNombre = (g['miembros'] as Map?)?['nombre'] ?? 'Sin líder';
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
                  (g['nombre'] ?? 'G')[0].toUpperCase(),
                  style: const TextStyle(
                    color: _kColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        g['nombre'] ?? '',
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
                          g['estado'] ?? '',
                          style: TextStyle(
                            color: activo ? kSuccess : kDanger,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // ✅ usar lugar y dia_semana
                  Row(
                    children: [
                      const Icon(Icons.person_outline, color: kGrey, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        liderNombre,
                        style: const TextStyle(color: kGrey, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.location_on_outlined,
                        color: kGrey,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          g['lugar'] ?? '',
                          style: const TextStyle(color: kGrey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: kGrey,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${g['dia_semana'] ?? ''} ${g['hora'] ?? ''}',
                        style: const TextStyle(color: kGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: kBgCard,
              icon: const Icon(Icons.more_vert, color: kGrey, size: 20),
              onSelected: (v) {
                if (v == 'editar') widget.onEditar();
                if (v == 'miembros') widget.onVerMiembros();
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
                const PopupMenuItem(
                  value: 'miembros',
                  child: Row(
                    children: [
                      Icon(Icons.people_outline, color: _kColor, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Ver / Agregar miembros',
                        style: TextStyle(color: kWhite, fontSize: 13),
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

// ── Formulario crear/editar grupo ─────────────────────
class _FormGrupo extends StatefulWidget {
  final Map<String, dynamic>? grupo;
  const _FormGrupo({this.grupo});
  @override
  State<_FormGrupo> createState() => _FormGrupoState();
}

class _FormGrupoState extends State<_FormGrupo> {
  final _nombreCtrl = TextEditingController();
  final _lugarCtrl = TextEditingController();
  final _horaCtrl = TextEditingController();
  String? _diaSemana;
  String _estado = 'activo';
  int? _idLider;
  List<Map<String, dynamic>> _miembros = [];
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.grupo != null;

  @override
  void initState() {
    super.initState();
    _cargarMiembros();
    if (_esEdicion) {
      final g = widget.grupo!;
      _nombreCtrl.text = g['nombre'] ?? '';
      // ✅ snake_case
      _lugarCtrl.text = g['lugar'] ?? '';
      _horaCtrl.text = g['hora'] ?? '';
      _diaSemana = g['dia_semana'];
      _estado = g['estado'] ?? 'activo';
      _idLider = g['id_lider'] as int?;
    }
  }

  Future<void> _cargarMiembros() async {
    final data = await _sb
        .from('miembros')
        .select('id, nombre')
        .eq('estado', 'activo')
        .order('nombre');
    setState(() => _miembros = List<Map<String, dynamic>>.from(data));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _lugarCtrl.dispose();
    _horaCtrl.dispose();
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
    // ✅ snake_case
    final datos = {
      'nombre': _nombreCtrl.text.trim(),
      'lugar': _lugarCtrl.text.trim(),
      'hora': _horaCtrl.text.trim(),
      'dia_semana': _diaSemana,
      'id_lider': _idLider,
      'estado': _estado,
    };
    try {
      if (_esEdicion) {
        await _sb.from('grupos').update(datos).eq('id', widget.grupo!['id']);
      } else {
        await _sb.from('grupos').insert(datos);
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
        width: 520,
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
                      Icons.group_outlined,
                      color: _kColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _esEdicion ? 'Editar Grupo' : 'Nuevo Grupo',
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
                    _Campo(
                      'Nombre del grupo *',
                      _nombreCtrl,
                      Icons.group_outlined,
                    ),
                    const SizedBox(height: 12),
                    _Campo(
                      'Lugar de reunión',
                      _lugarCtrl,
                      Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 12),
                    // ✅ dia_semana con dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kDivider),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _diaSemana,
                          isExpanded: true,
                          dropdownColor: kBgCard,
                          hint: const Text(
                            'Día de reunión',
                            style: TextStyle(color: kGrey, fontSize: 13),
                          ),
                          style: const TextStyle(color: kWhite, fontSize: 14),
                          onChanged: (v) => setState(() => _diaSemana = v),
                          items: _diasSemana
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d.toUpperCase()),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Campo(
                      'Hora (ej: 19:00)',
                      _horaCtrl,
                      Icons.access_time_outlined,
                    ),
                    const SizedBox(height: 12),
                    // Lider
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kDivider),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _idLider,
                          isExpanded: true,
                          dropdownColor: kBgCard,
                          hint: const Text(
                            'Asignar líder',
                            style: TextStyle(color: kGrey, fontSize: 13),
                          ),
                          style: const TextStyle(color: kWhite, fontSize: 14),
                          onChanged: (v) => setState(() => _idLider = v),
                          items: _miembros
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
                        child: Text(
                          _error!,
                          style: const TextStyle(color: kDanger, fontSize: 13),
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
                            _esEdicion ? 'Guardar cambios' : 'Crear grupo',
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

  Widget _Campo(String label, TextEditingController ctrl, IconData icon) =>
      TextField(
        controller: ctrl,
        style: const TextStyle(color: kWhite, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: kGrey, fontSize: 12),
          prefixIcon: Icon(icon, color: kGrey, size: 16),
          filled: true,
          fillColor: kBgCard,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
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
      );
}

// ── Dialog miembros del grupo ─────────────────────────
class _DialogMiembrosGrupo extends StatefulWidget {
  final Map<String, dynamic> grupo;
  const _DialogMiembrosGrupo({required this.grupo});
  @override
  State<_DialogMiembrosGrupo> createState() => _DialogMiembrosGrupoState();
}

class _DialogMiembrosGrupoState extends State<_DialogMiembrosGrupo> {
  List<Map<String, dynamic>> _miembrosGrupo = [];
  List<Map<String, dynamic>> _todosLosMiembros = [];
  int? _miembroAAgregar;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    // ✅ id_grupo, id_miembro
    final gmData = await _sb
        .from('grupo_miembros')
        .select('id, miembros(id, nombre)')
        .eq('id_grupo', widget.grupo['id']);
    final todosData = await _sb
        .from('miembros')
        .select('id, nombre')
        .eq('estado', 'activo')
        .order('nombre');
    setState(() {
      _miembrosGrupo = List<Map<String, dynamic>>.from(gmData);
      _todosLosMiembros = List<Map<String, dynamic>>.from(todosData);
      _cargando = false;
    });
  }

  Future<void> _agregar() async {
    if (_miembroAAgregar == null) return;
    try {
      // ✅ id_grupo, id_miembro
      await _sb.from('grupo_miembros').insert({
        'id_grupo': widget.grupo['id'],
        'id_miembro': _miembroAAgregar,
      });
      setState(() => _miembroAAgregar = null);
      _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kDanger),
        );
      }
    }
  }

  Future<void> _quitar(int gmId) async {
    await _sb.from('grupo_miembros').delete().eq('id', gmId);
    _cargar();
  }

  List<Map<String, dynamic>> get _disponibles {
    final idsEnGrupo = _miembrosGrupo
        .map((gm) => (gm['miembros'] as Map)['id'])
        .toSet();
    return _todosLosMiembros
        .where((m) => !idsEnGrupo.contains(m['id']))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBgMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 480,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Miembros — ${widget.grupo['nombre']}',
                  style: const TextStyle(
                    color: kWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: kGrey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Agregar miembro
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: kBgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kDivider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _miembroAAgregar,
                        isExpanded: true,
                        dropdownColor: kBgCard,
                        hint: const Text(
                          'Agregar miembro...',
                          style: TextStyle(color: kGrey, fontSize: 13),
                        ),
                        style: const TextStyle(color: kWhite, fontSize: 13),
                        onChanged: (v) => setState(() => _miembroAAgregar = v),
                        items: _disponibles
                            .map(
                              (m) => DropdownMenuItem<int>(
                                value: m['id'] as int,
                                child: Text(m['nombre'] ?? ''),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _miembroAAgregar != null ? _agregar : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${_miembrosGrupo.length} miembro${_miembrosGrupo.length != 1 ? 's' : ''}',
              style: const TextStyle(color: kGrey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (_cargando)
              const Center(child: CircularProgressIndicator(color: _kColor))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _miembrosGrupo.length,
                  itemBuilder: (_, i) {
                    final gm = _miembrosGrupo[i];
                    final m = gm['miembros'] as Map;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
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
                            radius: 16,
                            backgroundColor: _kColor.withValues(alpha: 0.2),
                            child: Text(
                              (m['nombre'] ?? 'M')[0].toUpperCase(),
                              style: const TextStyle(
                                color: _kColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              m['nombre'] ?? '',
                              style: const TextStyle(
                                color: kWhite,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: kDanger,
                              size: 18,
                            ),
                            onPressed: () => _quitar(gm['id'] as int),
                            tooltip: 'Quitar del grupo',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DialogConfirm extends StatelessWidget {
  final String titulo, mensaje;
  const _DialogConfirm({required this.titulo, required this.mensaje});
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: kBgMid,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: kWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(mensaje, style: const TextStyle(color: kGrey, fontSize: 13)),
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
