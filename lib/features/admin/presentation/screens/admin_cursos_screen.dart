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

// ══════════════════════════════════════════════════════
//  PANTALLA PRINCIPAL
// ══════════════════════════════════════════════════════
class AdminCursosScreen extends StatefulWidget {
  const AdminCursosScreen({super.key});
  @override
  State<AdminCursosScreen> createState() => _AdminCursosScreenState();
}

class _AdminCursosScreenState extends State<AdminCursosScreen> {
  List<Map<String, dynamic>> _cursos = [];
  bool _cargando = true;
  String _busqueda = '';
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final data = await _sb
          .from('cursos')
          .select('*, miembros(nombre)')
          .order('nombre');
      if (mounted) {
        setState(() {
          _cursos = List<Map<String, dynamic>>.from(data);
          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando cursos: $e');
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<Map<String, dynamic>> get _cursosFiltrados => _cursos.where((c) {
    final estado = c['estado'] ?? '';
    final nombre = (c['nombre'] ?? '').toLowerCase();
    final pasaBusqueda =
        _busqueda.isEmpty || nombre.contains(_busqueda.toLowerCase());
    final pasaEstado = _filtroEstado == 'todos' || estado == _filtroEstado;
    return pasaBusqueda && pasaEstado;
  }).toList();

  void _msg(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: error ? kDanger : kSuccess),
    );
  }

  void _abrirFormulario({Map<String, dynamic>? curso}) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormCurso(curso: curso),
    );
    if (ok == true) _cargar();
  }

  void _gestionarInscritos(Map<String, dynamic> c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogInscritos(curso: c),
    );
    if (ok == true) _cargar();
  }

  /// Finalizar período: guarda snapshot y deja el curso intacto
  Future<void> _finalizarPeriodo(Map<String, dynamic> c) async {
    String? nombrePeriodo;
    await showDialog(
      context: context,
      builder: (_) => _DialogNombrePeriodo(
        cursoNombre: c['nombre'] ?? '',
        onConfirm: (n) => nombrePeriodo = n,
      ),
    );
    if (nombrePeriodo == null || nombrePeriodo!.trim().isEmpty) return;

    try {
      // Tomar activos Y retirados sin período asignado
      final inscritos = await _sb
          .from('inscripciones')
          .select('id, estado')
          .eq('id_curso', c['id'] as int)
          .isFilter('periodo_id', null);

      final total = (inscritos as List).length;
      final completados = inscritos
          .where((i) => i['estado'] == 'completado')
          .length;

      // Crear período
      final periodo = await _sb
          .from('periodos_curso')
          .insert({
            'id_curso': c['id'],
            'nombre': nombrePeriodo!.trim(),
            'fecha_fin': DateTime.now().toIso8601String().split('T').first,
            'total_inscritos': total,
            'total_completados': completados,
          })
          .select('id')
          .single();

      final periodoId = periodo['id'] as int;

      // Archivar inscripciones actuales a ese período
      if (total > 0) {
        final ids = (inscritos as List).map((i) => i['id']).toList();
        for (final id in ids) {
          await _sb
              .from('inscripciones')
              .update({'periodo_id': periodoId})
              .eq('id', id);
        }
      }

      _msg(
        'Período "${nombrePeriodo!.trim()}" guardado. El curso sigue activo.',
      );
      _cargar();
    } catch (e) {
      _msg('Error: $e', error: true);
    }
  }

  Future<void> _eliminar(Map<String, dynamic> c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogConfirm(
        titulo: 'Eliminar curso',
        mensaje:
            '¿Eliminar "${c['nombre']}"?\n\nSe perderán TODAS las inscripciones y períodos asociados.',
        botonTexto: 'Eliminar',
        botonColor: kDanger,
      ),
    );
    if (ok != true) return;
    await _sb.from('cursos').delete().eq('id', c['id']);
    _msg('Curso eliminado');
    _cargar();
  }

  void _verHistorial(Map<String, dynamic> c) async {
    await showDialog(
      context: context,
      builder: (_) => _DialogHistorial(curso: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = _cursosFiltrados;

    return SigmarPage(
      rutaActual: '/admin/cursos',
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
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
                    Icons.school_outlined,
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
                        'Gestión de Cursos',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Cursos permanentes · Finaliza períodos, no cursos',
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
                    'Nuevo Curso',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 50, height: 3, color: _kColor),
            const SizedBox(height: 20),

            // ── Búsqueda + filtro ──
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (v) => setState(() => _busqueda = v),
                    style: const TextStyle(color: kWhite, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar curso...',
                      hintStyle: const TextStyle(color: kGrey, fontSize: 13),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: kGrey,
                        size: 18,
                      ),
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
                      value: _filtroEstado,
                      dropdownColor: kBgCard,
                      style: const TextStyle(color: kWhite, fontSize: 13),
                      onChanged: (v) =>
                          setState(() => _filtroEstado = v ?? 'todos'),
                      items: const [
                        DropdownMenuItem(value: 'todos', child: Text('Todos')),
                        DropdownMenuItem(
                          value: 'activo',
                          child: Text('Activos'),
                        ),
                        DropdownMenuItem(
                          value: 'inactivo',
                          child: Text('Inactivos'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${lista.length} curso${lista.length != 1 ? 's' : ''}',
              style: const TextStyle(color: kGrey, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // ── Lista ──
            _cargando
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: _kColor),
                    ),
                  )
                : lista.isEmpty
                ? _EmptyState(
                    icon: _busqueda.isNotEmpty
                        ? Icons.search_off
                        : Icons.school_outlined,
                    mensaje: _busqueda.isNotEmpty
                        ? 'Sin resultados para "$_busqueda"'
                        : 'No hay cursos registrados',
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lista.length,
                    itemBuilder: (_, i) {
                      final c = lista[i];
                      return _TarjetaCurso(
                        curso: c,
                        onEditar: () => _abrirFormulario(curso: c),
                        onInscritos: () => _gestionarInscritos(c),
                        onFinalizar: () => _finalizarPeriodo(c),
                        onHistorial: () => _verHistorial(c),
                        onEliminar: () => _eliminar(c),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  TARJETA CURSO
// ══════════════════════════════════════════════════════
class _TarjetaCurso extends StatelessWidget {
  final Map<String, dynamic> curso;
  final VoidCallback onEditar;
  final VoidCallback onInscritos;
  final VoidCallback onFinalizar;
  final VoidCallback onHistorial;
  final VoidCallback onEliminar;

  const _TarjetaCurso({
    required this.curso,
    required this.onEditar,
    required this.onInscritos,
    required this.onFinalizar,
    required this.onHistorial,
    required this.onEliminar,
  });

  Color get _estadoColor => curso['estado'] == 'activo' ? kSuccess : kDanger;

  @override
  Widget build(BuildContext context) {
    final c = curso;
    final guiaNombre = (c['miembros'] as Map?)?['nombre'] ?? 'Sin guía';
    final estado = (c['estado'] ?? 'activo') as String;
    final precioCurso = c['precio_curso'];
    final precioLibro = c['precio_libro'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgMid,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kDivider),
      ),
      child: Row(
        children: [
          // Ícono
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _estadoColor.withValues(alpha: 0.12),
              border: Border.all(color: _estadoColor.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                (c['nombre'] ?? 'C')[0].toUpperCase(),
                style: TextStyle(
                  color: _estadoColor,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c['nombre'] ?? '',
                        style: const TextStyle(
                          color: kWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _BadgeEstado(estado: estado, color: _estadoColor),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.person_outline, color: kGrey, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Guía: $guiaNombre',
                      style: const TextStyle(color: kGrey, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.room_outlined, color: kGrey, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      c['aula'] ?? '-',
                      style: const TextStyle(color: kGrey, fontSize: 12),
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
                      '${c['dia_semana'] ?? '-'}  ${c['hora'] ?? ''}',
                      style: const TextStyle(color: kGrey, fontSize: 12),
                    ),
                    if (c['horas'] != null) ...[
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.access_time_outlined,
                        color: kGrey,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${c['horas']}h',
                        style: const TextStyle(color: kGrey, fontSize: 12),
                      ),
                    ],
                  ],
                ),
                if (precioCurso != null || precioLibro != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        if (precioCurso != null &&
                            (precioCurso as num) > 0) ...[
                          const Icon(
                            Icons.attach_money,
                            color: kGold,
                            size: 12,
                          ),
                          Text(
                            'Bs ${(precioCurso as num).toStringAsFixed(2)}',
                            style: const TextStyle(color: kGold, fontSize: 11),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (precioLibro != null &&
                            (precioLibro as num) > 0) ...[
                          const Icon(
                            Icons.book_outlined,
                            color: kGold,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Libro: Bs ${(precioLibro as num).toStringAsFixed(2)}',
                            style: const TextStyle(color: kGold, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Menú
          PopupMenuButton<String>(
            color: kBgCard,
            icon: const Icon(Icons.more_vert, color: kGrey, size: 20),
            onSelected: (v) {
              switch (v) {
                case 'editar':
                  onEditar();
                case 'inscritos':
                  onInscritos();
                case 'historial':
                  onHistorial();
                case 'finalizar':
                  onFinalizar();
                case 'borrar':
                  onEliminar();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'editar',
                child: _MenuRow(
                  icon: Icons.edit_outlined,
                  color: _kColor,
                  texto: 'Editar curso',
                ),
              ),
              const PopupMenuItem(
                value: 'inscritos',
                child: _MenuRow(
                  icon: Icons.people_outline,
                  color: _kColor,
                  texto: 'Gestionar inscritos activos',
                ),
              ),
              const PopupMenuItem(
                value: 'historial',
                child: _MenuRow(
                  icon: Icons.history,
                  color: kGold,
                  texto: 'Ver historial de períodos',
                ),
              ),
              const PopupMenuItem(
                value: 'finalizar',
                child: _MenuRow(
                  icon: Icons.archive_outlined,
                  color: kGold,
                  texto: 'Cerrar período actual',
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'borrar',
                child: _MenuRow(
                  icon: Icons.delete_outline,
                  color: kDanger,
                  texto: 'Eliminar curso',
                  textoColor: kDanger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  DIALOG: GESTIÓN DE INSCRITOS ACTIVOS
// ══════════════════════════════════════════════════════
class _DialogInscritos extends StatefulWidget {
  final Map<String, dynamic> curso;
  const _DialogInscritos({required this.curso});
  @override
  State<_DialogInscritos> createState() => _DialogInscritosState();
}

class _DialogInscritosState extends State<_DialogInscritos> {
  List<Map<String, dynamic>> _inscritos = [];
  List<Map<String, dynamic>> _miembrosDisponibles = [];
  bool _cargando = true;
  bool _guardando = false;
  int? _miembroAAgregar;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      // Todos los inscritos activos sin período asignado
      final inscritos = await _sb
          .from('inscripciones')
          .select('*, miembros(id, nombre, carnet)')
          .eq('id_curso', widget.curso['id'] as int)
          .isFilter('periodo_id', null);

      final inscritosIds = (inscritos as List)
          .map((i) => (i['miembros'] as Map)['id'] as int)
          .toList();

      // Miembros activos que no están ya en este período activo
      final todos = await _sb
          .from('miembros')
          .select('id, nombre, carnet')
          .eq('estado', 'activo')
          .order('nombre');

      setState(() {
        _inscritos = List<Map<String, dynamic>>.from(inscritos);
        _miembrosDisponibles = (todos as List)
            .where((m) => !inscritosIds.contains(m['id'] as int))
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _cargando = false;
        _error = 'Error cargando: $e';
      });
    }
  }

  Future<void> _cambiarEstado(
    Map<String, dynamic> ins,
    String nuevoEstado,
  ) async {
    setState(() => _guardando = true);
    try {
      await _sb
          .from('inscripciones')
          .update({'estado': nuevoEstado})
          .eq('id', ins['id'] as int);
      await _cargar();
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _eliminar(Map<String, dynamic> ins) async {
    final nombre = (ins['miembros'] as Map?)?['nombre'] ?? '-';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogConfirm(
        titulo: 'Quitar inscripción',
        mensaje:
            'Se eliminará la inscripción de "$nombre".\nPodrá volver a inscribirse después.',
        botonTexto: 'Quitar',
        botonColor: kDanger,
      ),
    );
    if (ok != true) return;
    setState(() => _guardando = true);
    try {
      await _sb.from('inscripciones').delete().eq('id', ins['id'] as int);
      await _cargar();
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _agregar() async {
    if (_miembroAAgregar == null) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await _sb.from('inscripciones').insert({
        'id_miembro': _miembroAAgregar,
        'id_curso': widget.curso['id'],
        'estado': 'activo',
        'fecha_inicio': DateTime.now().toIso8601String().split('T').first,
      });
      setState(() => _miembroAAgregar = null);
      await _cargar();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('ya completó')) {
        setState(
          () => _error =
              'Este miembro ya completó el curso y no puede reinscribirse.',
        );
      } else {
        setState(() => _error = 'Error al inscribir: $msg');
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'completado':
        return kSuccess;
      case 'retirado':
        return kDanger;
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
            // ── Header ──
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
                      Icons.people_outline,
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
                          widget.curso['nombre'] ?? '',
                          style: const TextStyle(
                            color: kWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_inscritos.length} inscrito${_inscritos.length != 1 ? 's' : ''} en período activo',
                          style: const TextStyle(color: kGrey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: const Icon(Icons.close, color: kGrey, size: 20),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: _kColor),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Panel agregar
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: kBgCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _kColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AGREGAR MIEMBRO AL PERÍODO ACTIVO',
                                  style: TextStyle(
                                    color: kGrey,
                                    fontSize: 11,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: kBgMid,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(color: kDivider),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<int>(
                                            value: _miembroAAgregar,
                                            isExpanded: true,
                                            dropdownColor: kBgCard,
                                            hint: const Text(
                                              'Seleccionar miembro…',
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
                                              () => _miembroAAgregar = v,
                                            ),
                                            items: _miembrosDisponibles
                                                .map(
                                                  (m) => DropdownMenuItem<int>(
                                                    value: m['id'] as int,
                                                    child: Text(
                                                      '${m['nombre']}${m['carnet'] != null ? '  ·  ${m['carnet']}' : ''}',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      onPressed:
                                          _guardando || _miembroAAgregar == null
                                          ? null
                                          : _agregar,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _kColor,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.person_add_outlined,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Inscribir',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
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
                                          size: 14,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: const TextStyle(
                                              color: kDanger,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () =>
                                              setState(() => _error = null),
                                          child: const Icon(
                                            Icons.close,
                                            color: kDanger,
                                            size: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Lista inscritos
                          if (_inscritos.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: kBgCard,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: kDivider),
                              ),
                              child: const Center(
                                child: Text(
                                  'Ningún miembro inscrito en el período activo',
                                  style: TextStyle(color: kGrey),
                                ),
                              ),
                            )
                          else
                            ...(_inscritos.map((ins) {
                              final m = ins['miembros'] as Map?;
                              final estado =
                                  ins['estado'] as String? ?? 'activo';
                              final color = _colorEstado(estado);
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
                                    // Avatar
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: color.withValues(alpha: 0.12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          (m?['nombre'] ?? 'M')[0]
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m?['nombre'] ?? '-',
                                            style: const TextStyle(
                                              color: kWhite,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            m?['carnet'] ?? 'Sin carnet',
                                            style: const TextStyle(
                                              color: kGrey,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Badge estado
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: color.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        estado.toUpperCase(),
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Menú acciones
                                    PopupMenuButton<String>(
                                      color: kBgCard,
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: kGrey,
                                        size: 18,
                                      ),
                                      onSelected: (v) {
                                        if (v == 'completar') {
                                          _cambiarEstado(ins, 'completado');
                                        }
                                        if (v == 'retirar') {
                                          _cambiarEstado(ins, 'retirado');
                                        }
                                        if (v == 'activar') {
                                          _cambiarEstado(ins, 'activo');
                                        }
                                        if (v == 'eliminar') {
                                          _eliminar(ins);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        if (estado != 'completado')
                                          const PopupMenuItem(
                                            value: 'completar',
                                            child: _MenuRow(
                                              icon: Icons.check_circle_outline,
                                              color: kSuccess,
                                              texto: 'Marcar completado',
                                            ),
                                          ),
                                        if (estado != 'retirado')
                                          const PopupMenuItem(
                                            value: 'retirar',
                                            child: _MenuRow(
                                              icon: Icons.exit_to_app,
                                              color: kDanger,
                                              texto: 'Marcar retirado',
                                            ),
                                          ),
                                        if (estado != 'activo')
                                          const PopupMenuItem(
                                            value: 'activar',
                                            child: _MenuRow(
                                              icon: Icons.refresh,
                                              color: _kColor,
                                              texto: 'Reactivar',
                                            ),
                                          ),
                                        const PopupMenuDivider(),
                                        const PopupMenuItem(
                                          value: 'eliminar',
                                          child: _MenuRow(
                                            icon: Icons.delete_outline,
                                            color: kDanger,
                                            texto: 'Quitar inscripción',
                                            textoColor: kDanger,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            })),
                        ],
                      ),
                    ),
            ),

            // ── Footer ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: kBgCard,
                border: Border(top: BorderSide(color: kDivider)),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kGrey,
                    side: const BorderSide(color: kDivider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  DIALOG: NOMBRE DEL PERÍODO AL CERRAR
// ══════════════════════════════════════════════════════
class _DialogNombrePeriodo extends StatefulWidget {
  final String cursoNombre;
  final ValueChanged<String> onConfirm;
  const _DialogNombrePeriodo({
    required this.cursoNombre,
    required this.onConfirm,
  });

  @override
  State<_DialogNombrePeriodo> createState() => _DialogNombrePeriodoState();
}

class _DialogNombrePeriodoState extends State<_DialogNombrePeriodo> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final meses = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    _ctrl.text = '${meses[now.month]} ${now.year}';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBgMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.archive_outlined,
                    color: kGold,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cerrar período',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.cursoNombre,
                        style: const TextStyle(color: kGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kGold.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kGold.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'El curso seguirá activo para nuevas inscripciones.\n'
                'Los inscritos actuales quedarán archivados en este período.',
                style: TextStyle(color: kGold, fontSize: 12, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nombre del período',
              style: TextStyle(color: kGrey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: const TextStyle(color: kWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'ej: Enero–Marzo 2026',
                hintStyle: const TextStyle(color: kGrey, fontSize: 13),
                filled: true,
                fillColor: kBgCard,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
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
                  borderSide: const BorderSide(color: kGold, width: 2),
                ),
              ),
            ),
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
                  onPressed: () {
                    widget.onConfirm(_ctrl.text);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGold,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cerrar período',
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
}

// ══════════════════════════════════════════════════════
//  DIALOG HISTORIAL DE PERÍODOS (solo lectura)
// ══════════════════════════════════════════════════════
class _DialogHistorial extends StatefulWidget {
  final Map<String, dynamic> curso;
  const _DialogHistorial({required this.curso});
  @override
  State<_DialogHistorial> createState() => _DialogHistorialState();
}

class _DialogHistorialState extends State<_DialogHistorial> {
  List<Map<String, dynamic>> _periodos = [];
  bool _cargando = true;
  int? _periodoExpandido;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final data = await _sb
        .from('periodos_curso')
        .select()
        .eq('id_curso', widget.curso['id'] as int)
        .order('fecha_fin', ascending: false);
    setState(() {
      _periodos = List<Map<String, dynamic>>.from(data);
      _cargando = false;
    });
  }

  Future<List<Map<String, dynamic>>> _cargarInscritos(int periodoId) async {
    final data = await _sb
        .from('inscripciones')
        .select('*, miembros(nombre, carnet)')
        .eq('periodo_id', periodoId)
        .order('estado');
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBgMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 540,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
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
                      color: kGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history, color: kGold, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.curso['nombre'] ?? '',
                          style: const TextStyle(
                            color: kWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Historial de períodos — solo lectura',
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

            // Body
            if (_cargando)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: kGold)),
              )
            else if (_periodos.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Este curso aún no tiene períodos cerrados',
                    style: TextStyle(color: kGrey),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemCount: _periodos.length,
                  itemBuilder: (_, i) {
                    final p = _periodos[i];
                    final isOpen = _periodoExpandido == p['id'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isOpen ? kGold.withValues(alpha: 0.4) : kDivider,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Cabecera período
                          InkWell(
                            onTap: () => setState(
                              () => _periodoExpandido = isOpen
                                  ? null
                                  : p['id'] as int,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: kGold.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month_outlined,
                                      color: kGold,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['nombre'] ?? '',
                                          style: const TextStyle(
                                            color: kWhite,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Cerrado: ${p['fecha_fin'] ?? '-'}',
                                          style: const TextStyle(
                                            color: kGrey,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${p['total_inscritos'] ?? 0} inscritos',
                                        style: const TextStyle(
                                          color: kGrey,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        '${p['total_completados'] ?? 0} completaron',
                                        style: const TextStyle(
                                          color: kSuccess,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isOpen
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: kGrey,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Detalle expandible — SOLO LECTURA
                          if (isOpen)
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: _cargarInscritos(p['id'] as int),
                              builder: (_, snap) {
                                if (!snap.hasData) {
                                  return const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: kGold,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final inscritos = snap.data!;
                                if (inscritos.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text(
                                      'Sin inscritos',
                                      style: TextStyle(color: kGrey),
                                    ),
                                  );
                                }
                                return Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: kDivider),
                                    ),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: inscritos.length,
                                    itemBuilder: (_, j) {
                                      final ins = inscritos[j];
                                      final m = ins['miembros'] as Map?;
                                      final estado = ins['estado'] ?? 'activo';
                                      final color = estado == 'completado'
                                          ? kSuccess
                                          : estado == 'retirado'
                                          ? kDanger
                                          : _kColor;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 7,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              estado == 'completado'
                                                  ? Icons.check_circle_outline
                                                  : estado == 'retirado'
                                                  ? Icons.cancel_outlined
                                                  : Icons.school_outlined,
                                              color: color,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                m?['nombre'] ?? '-',
                                                style: const TextStyle(
                                                  color: kWhite,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              m?['carnet'] ?? '-',
                                              style: const TextStyle(
                                                color: kGrey,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                estado.toUpperCase(),
                                                style: TextStyle(
                                                  color: color,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: kBgCard,
                border: Border(top: BorderSide(color: kDivider)),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kGrey,
                    side: const BorderSide(color: kDivider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  FORMULARIO CURSO
// ══════════════════════════════════════════════════════
class _FormCurso extends StatefulWidget {
  final Map<String, dynamic>? curso;
  const _FormCurso({this.curso});
  @override
  State<_FormCurso> createState() => _FormCursoState();
}

class _FormCursoState extends State<_FormCurso> {
  final _nombreCtrl = TextEditingController();
  final _aulaCtrl = TextEditingController();
  final _horasCtrl = TextEditingController();
  final _horaCtrl = TextEditingController();
  final _precioCursoCtrl = TextEditingController();
  final _precioLibroCtrl = TextEditingController();
  String? _diaSemana;
  String _estado = 'activo';
  int? _idGuia;
  List<Map<String, dynamic>> _miembros = [];
  List<Map<String, dynamic>> _todosCursos = [];
  List<int> _prerequisitosSeleccionados = [];
  bool _requiereBautismo = false;
  bool _requiereEncuentro = false;
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.curso != null;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    if (_esEdicion) {
      final c = widget.curso!;
      _nombreCtrl.text = c['nombre'] ?? '';
      _aulaCtrl.text = c['aula'] ?? '';
      _horasCtrl.text = '${c['horas'] ?? ''}';
      _horaCtrl.text = c['hora'] ?? '';
      _diaSemana = c['dia_semana'] as String?;
      _estado = c['estado'] ?? 'activo';
      _idGuia = c['id_guia'] as int?;
      _precioCursoCtrl.text =
          c['precio_curso'] != null && (c['precio_curso'] as num) > 0
          ? '${c['precio_curso']}'
          : '';
      _precioLibroCtrl.text =
          c['precio_libro'] != null && (c['precio_libro'] as num) > 0
          ? '${c['precio_libro']}'
          : '';
    }
  }

  Future<void> _cargarDatos() async {
    final miembros = await _sb
        .from('miembros')
        .select('id, nombre')
        .eq('estado', 'activo')
        .order('nombre');
    setState(() => _miembros = List<Map<String, dynamic>>.from(miembros));

    final cursos = await _sb
        .from('cursos')
        .select('id, nombre')
        .eq('estado', 'activo')
        .order('nombre');
    setState(
      () => _todosCursos = (cursos as List)
          .where((c) => !_esEdicion || c['id'] != widget.curso!['id'])
          .map((c) => Map<String, dynamic>.from(c))
          .toList(),
    );

    if (_esEdicion) {
      final reqs = await _sb
          .from('curso_requisitos')
          .select()
          .eq('id_curso', widget.curso!['id'] as int);
      final lista = reqs as List;
      setState(() {
        _prerequisitosSeleccionados = lista
            .where((r) => r['id_curso_prerequisito'] != null)
            .map<int>((r) => r['id_curso_prerequisito'] as int)
            .toList();
        if (lista.isNotEmpty) {
          _requiereBautismo = lista.any((r) => r['requiere_bautismo'] == true);
          _requiereEncuentro = lista.any(
            (r) => r['requiere_encuentro'] == true,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _aulaCtrl.dispose();
    _horasCtrl.dispose();
    _horaCtrl.dispose();
    _precioCursoCtrl.dispose();
    _precioLibroCtrl.dispose();
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
      'aula': _aulaCtrl.text.trim(),
      'horas': int.tryParse(_horasCtrl.text.trim()),
      'hora': _horaCtrl.text.trim(),
      'dia_semana': _diaSemana,
      'id_guia': _idGuia,
      'estado': _estado,
      'precio_curso': double.tryParse(_precioCursoCtrl.text.trim()) ?? 0,
      'precio_libro': double.tryParse(_precioLibroCtrl.text.trim()) ?? 0,
    };
    try {
      int cursoId;
      if (_esEdicion) {
        await _sb.from('cursos').update(datos).eq('id', widget.curso!['id']);
        cursoId = widget.curso!['id'] as int;
        await _sb.from('curso_requisitos').delete().eq('id_curso', cursoId);
      } else {
        final inserted = await _sb
            .from('cursos')
            .insert(datos)
            .select('id')
            .single();
        cursoId = inserted['id'] as int;
      }
      await _guardarRequisitos(cursoId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _guardando = false;
      });
    }
  }

  Future<void> _guardarRequisitos(int cursoId) async {
    if (_prerequisitosSeleccionados.isNotEmpty) {
      await _sb
          .from('curso_requisitos')
          .insert(
            _prerequisitosSeleccionados
                .map(
                  (id) => {
                    'id_curso': cursoId,
                    'id_curso_prerequisito': id,
                    'requiere_bautismo': _requiereBautismo,
                    'requiere_encuentro': _requiereEncuentro,
                  },
                )
                .toList(),
          );
    } else if (_requiereBautismo || _requiereEncuentro) {
      await _sb.from('curso_requisitos').insert({
        'id_curso': cursoId,
        'id_curso_prerequisito': null,
        'requiere_bautismo': _requiereBautismo,
        'requiere_encuentro': _requiereEncuentro,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBgMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 540,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
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
                      Icons.school_outlined,
                      color: _kColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _esEdicion ? 'Editar Curso' : 'Nuevo Curso',
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

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SecLabel('INFORMACIÓN DEL CURSO'),
                    const SizedBox(height: 12),
                    _Campo(
                      label: 'Nombre del curso *',
                      ctrl: _nombreCtrl,
                      icon: Icons.school_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Campo(
                            label: 'Aula',
                            ctrl: _aulaCtrl,
                            icon: Icons.room_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Campo(
                            label: 'Horas totales',
                            ctrl: _horasCtrl,
                            icon: Icons.access_time_outlined,
                            tipo: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Dropdown(
                            hint: 'Día de clase',
                            value: _diaSemana,
                            onChanged: (v) =>
                                setState(() => _diaSemana = v as String?),
                            items: _diasSemana
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(
                                      d[0].toUpperCase() + d.substring(1),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Campo(
                            label: 'Hora (ej: 18:00)',
                            ctrl: _horaCtrl,
                            icon: Icons.access_time_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Dropdown(
                      hint: 'Asignar guía',
                      value: _idGuia,
                      onChanged: (v) => setState(() => _idGuia = v as int?),
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
                    const SizedBox(height: 12),
                    _Dropdown(
                      hint: 'Estado',
                      value: _estado,
                      onChanged: (v) => setState(() => _estado = v as String),
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

                    const SizedBox(height: 20),
                    const _SecLabel('PRECIOS'),
                    const SizedBox(height: 4),
                    const Text(
                      'Dejar en 0 si el curso es gratuito.',
                      style: TextStyle(color: kGrey, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Campo(
                            label: 'Precio del curso (Bs)',
                            ctrl: _precioCursoCtrl,
                            icon: Icons.attach_money,
                            tipo: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Campo(
                            label: 'Precio del libro (Bs)',
                            ctrl: _precioLibroCtrl,
                            icon: Icons.book_outlined,
                            tipo: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const _SecLabel('REQUISITOS PARA INSCRIBIRSE'),
                    const SizedBox(height: 4),
                    const Text(
                      'El miembro debe cumplir todos estos requisitos.',
                      style: TextStyle(color: kGrey, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    _Sw(
                      'Requiere estar bautizado',
                      _requiereBautismo,
                      (v) => setState(() => _requiereBautismo = v),
                    ),
                    const SizedBox(height: 8),
                    _Sw(
                      'Requiere haber ido al encuentro',
                      _requiereEncuentro,
                      (v) => setState(() => _requiereEncuentro = v),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'CURSOS PREREQUISITO',
                      style: TextStyle(
                        color: kGrey,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kDivider),
                      ),
                      child: _todosCursos.isEmpty
                          ? const Text(
                              'No hay otros cursos disponibles',
                              style: TextStyle(color: kGrey, fontSize: 12),
                            )
                          : Column(
                              children: _todosCursos.map((curso) {
                                final id = curso['id'] as int;
                                final sel = _prerequisitosSeleccionados
                                    .contains(id);
                                return CheckboxListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  value: sel,
                                  activeColor: _kColor,
                                  checkColor: Colors.white,
                                  title: Text(
                                    curso['nombre'] ?? '',
                                    style: const TextStyle(
                                      color: kWhite,
                                      fontSize: 13,
                                    ),
                                  ),
                                  onChanged: (v) => setState(() {
                                    if (v == true) {
                                      _prerequisitosSeleccionados.add(id);
                                    } else {
                                      _prerequisitosSeleccionados.remove(id);
                                    }
                                  }),
                                );
                              }).toList(),
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

            // Footer
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
                            _esEdicion ? 'Guardar cambios' : 'Crear curso',
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

// ══════════════════════════════════════════════════════
//  WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String mensaje;
  const _EmptyState({required this.icon, required this.mensaje});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kGrey.withValues(alpha: 0.4), size: 36),
          const SizedBox(height: 10),
          Text(mensaje, style: const TextStyle(color: kGrey)),
        ],
      ),
    ),
  );
}

class _BadgeEstado extends StatelessWidget {
  final String estado;
  final Color color;
  const _BadgeEstado({required this.estado, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      estado.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    ),
  );
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String texto;
  final Color textoColor;
  const _MenuRow({
    required this.icon,
    required this.color,
    required this.texto,
    this.textoColor = kWhite,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Text(texto, style: TextStyle(color: textoColor, fontSize: 13)),
    ],
  );
}

class _SecLabel extends StatelessWidget {
  final String t;
  const _SecLabel(this.t);
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
  final IconData icon;
  final TextInputType tipo;
  const _Campo({
    required this.label,
    required this.ctrl,
    required this.icon,
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
      prefixIcon: Icon(icon, color: kGrey, size: 16),
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

class _Dropdown extends StatelessWidget {
  final String hint;
  final dynamic value;
  final List<DropdownMenuItem> items;
  final ValueChanged onChanged;
  const _Dropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: kBgCard,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: kDivider),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton(
        value: value,
        isExpanded: true,
        dropdownColor: kBgCard,
        hint: Text(hint, style: const TextStyle(color: kGrey, fontSize: 13)),
        style: const TextStyle(color: kWhite, fontSize: 14),
        onChanged: onChanged,
        items: items,
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
          activeThumbColor: _kColor,
          activeTrackColor: _kColor.withValues(alpha: 0.3),
        ),
      ],
    ),
  );
}

class _DialogConfirm extends StatelessWidget {
  final String titulo, mensaje, botonTexto;
  final Color botonColor;
  const _DialogConfirm({
    required this.titulo,
    required this.mensaje,
    required this.botonTexto,
    required this.botonColor,
  });
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: kBgMid,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Container(
      width: 400,
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
          Text(
            mensaje,
            style: const TextStyle(color: kGrey, fontSize: 13, height: 1.5),
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
                  backgroundColor: botonColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  botonTexto,
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
