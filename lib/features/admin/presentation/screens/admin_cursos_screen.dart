import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sigmar_page.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFF7F77DD);

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
  List<Map<String, dynamic>> _filtrados = [];
  List<Map<String, dynamic>> _miembros = [];
  Set<int> _idsGuias = {};
  Map<int, Set<int>> _inscritosPorCurso = {};
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
      final cursos = await _sb.from('curso').select().order('nombre');
      final miembros = await _sb
          .from('miembros')
          .select('id, nombre')
          .eq('estado', 'activo')
          .order('nombre');
      final inscripciones = await _sb
          .from('inscripciones')
          .select('idCurso, idMiembro');

      // IDs de guías
      final idsGuias = (cursos as List)
          .where((c) => c['idGuia'] != null)
          .map((c) => c['idGuia'] as int)
          .toSet();

      // Mapa: idCurso -> Set<idMiembro>
      final Map<int, Set<int>> inscritosPorCurso = {};
      for (final r in (inscripciones as List)) {
        final cid = r['idCurso'] as int;
        final mid = r['idMiembro'] as int;
        inscritosPorCurso.putIfAbsent(cid, () => {}).add(mid);
      }

      // Agregar nombre del guía a cada curso
      final List<Map<String, dynamic>> conGuia = [];
      for (final c in cursos) {
        final m = Map<String, dynamic>.from(c);
        if (c['idGuia'] != null) {
          try {
            final g = await _sb
                .from('miembros')
                .select('nombre')
                .eq('id', c['idGuia'])
                .maybeSingle();
            m['guiaNombre'] = g?['nombre'] ?? '';
          } catch (_) {}
        }
        // Contar inscritos
        m['totalInscritos'] = inscritosPorCurso[c['id'] as int]?.length ?? 0;
        conGuia.add(m);
      }

      setState(() {
        _cursos = conGuia;
        _miembros = List<Map<String, dynamic>>.from(miembros);
        _idsGuias = idsGuias;
        _inscritosPorCurso = inscritosPorCurso;
        _filtrar();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _snack('Error al cargar: $e', error: true);
    }
  }

  void _filtrar() {
    final q = _busqueda.toLowerCase();
    setState(() {
      _filtrados = q.isEmpty
          ? _cursos
          : _cursos
                .where((c) => (c['nombre'] ?? '').toLowerCase().contains(q))
                .toList();
    });
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? kDanger : kSuccess),
    );
  }

  void _abrirForm({Map<String, dynamic>? curso}) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormCurso(
        curso: curso,
        miembros: _miembros,
        idsGuias: _idsGuias,
        todosCursos: _cursos,
      ),
    );
    if (ok == true) _cargar();
  }

  void _gestionarInscritos(Map<String, dynamic> c) async {
    await showDialog(
      context: context,
      builder: (_) => _DialogoInscritos(
        curso: c,
        todosMiembros: _miembros,
        idsGuias: _idsGuias,
        inscritosPorCurso: _inscritosPorCurso,
      ),
    );
    _cargar();
  }

  void _eliminar(Map<String, dynamic> c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBgCard,
        title: const Text('Eliminar Curso', style: TextStyle(color: kWhite)),
        content: Text(
          '¿Eliminar "${c['nombre']}"? Se eliminarán también todas las inscripciones.',
          style: const TextStyle(color: kGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: kGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kDanger,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
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
      // Eliminar inscripciones del curso
      await _sb.from('inscripciones').delete().eq('idCurso', c['id']);
      // Eliminar requisitos
      await _sb.from('curso_requisitos').delete().eq('idCurso', c['id']);
      await _sb
          .from('curso_requisitos')
          .delete()
          .eq('idRequisito', c['id']);
      // Eliminar curso
      await _sb.from('curso').delete().eq('id', c['id']);
      _snack('Curso eliminado');
      _cargar();
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SigmarPage(
      rutaActual: '/admin/cursos',
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
                        'Gestion de Cursos',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Administrar cursos y aulas',
                        style: TextStyle(color: kGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _abrirForm(),
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
                    'Nuevo Curso',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 50, height: 3, color: _kColor),
            const SizedBox(height: 24),

            // Buscador
            TextField(
              onChanged: (v) => setState(() {
                _busqueda = v;
                _filtrar();
              }),
              style: const TextStyle(color: kWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar curso por nombre...',
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_filtrados.length} curso${_filtrados.length != 1 ? 's' : ''}',
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(Icons.school_outlined, color: kGrey, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _busqueda.isEmpty
                            ? 'No hay cursos registrados'
                            : 'Sin resultados para "$_busqueda"',
                        style: const TextStyle(color: kGrey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...(_filtrados.map(
                (c) => _TarjetaCurso(
                  curso: c,
                  onEditar: () => _abrirForm(curso: c),
                  onInscritos: () => _gestionarInscritos(c),
                  onEliminar: () => _eliminar(c),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  TARJETA DE CURSO
// ══════════════════════════════════════════════════════
class _TarjetaCurso extends StatefulWidget {
  final Map<String, dynamic> curso;
  final VoidCallback onEditar, onInscritos, onEliminar;
  const _TarjetaCurso({
    required this.curso,
    required this.onEditar,
    required this.onInscritos,
    required this.onEliminar,
  });
  @override
  State<_TarjetaCurso> createState() => _TarjetaCursoState();
}

class _TarjetaCursoState extends State<_TarjetaCurso> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final c = widget.curso;
    final activo = c['estado'] == 'activo';
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _h ? kBgCard : kBgMid,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _h ? _kColor.withValues(alpha: 0.3) : kDivider,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.school_outlined,
                color: _kColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: activo
                              ? kSuccess.withValues(alpha: 0.15)
                              : kGrey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          c['estado'] ?? 'activo',
                          style: TextStyle(
                            color: activo ? kSuccess : kGrey,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (c['aula'] != null)
                        _InfoChip(Icons.meeting_room_outlined, c['aula']),
                      if (c['horas'] != null)
                        _InfoChip(Icons.timer_outlined, '${c['horas']}h'),
                      if (c['horario'] != null &&
                          (c['horario'] as String).isNotEmpty)
                        _InfoChip(Icons.schedule_outlined, c['horario']),
                      _InfoChip(
                        Icons.people_outline,
                        '${c['totalInscritos'] ?? 0} inscritos',
                        color: const Color(0xFF1D9E75),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if ((c['guiaNombre'] ?? '').isNotEmpty)
                    _InfoRow(
                      Icons.person_outline,
                      'Guia: ${c['guiaNombre']}',
                      color: kGold,
                    ),
                  if (c['idGuia'] == null)
                    _InfoRow(
                      Icons.person_off_outlined,
                      'Sin guia asignado',
                      color: kDanger,
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: kBgCard,
              icon: const Icon(Icons.more_vert, color: kGrey, size: 20),
              onSelected: (v) {
                if (v == 'inscritos') widget.onInscritos();
                if (v == 'editar') widget.onEditar();
                if (v == 'eliminar') widget.onEliminar();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'inscritos',
                  child: Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        color: Color(0xFF1D9E75),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Gestionar inscritos',
                        style: TextStyle(color: kWhite, fontSize: 13),
                      ),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String texto;
  final Color color;
  const _InfoChip(this.icon, this.texto, {this.color = kGrey});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 6, bottom: 4),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 4),
        Text(
          texto,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String texto;
  final Color color;
  const _InfoRow(this.icon, this.texto, {this.color = kGrey});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 5),
        Expanded(
          child: Text(texto, style: TextStyle(color: color, fontSize: 12)),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
//  DIALOGO GESTIONAR INSCRITOS
// ══════════════════════════════════════════════════════
class _DialogoInscritos extends StatefulWidget {
  final Map<String, dynamic> curso;
  final List<Map<String, dynamic>> todosMiembros;
  final Set<int> idsGuias;
  final Map<int, Set<int>> inscritosPorCurso;
  const _DialogoInscritos({
    required this.curso,
    required this.todosMiembros,
    required this.idsGuias,
    required this.inscritosPorCurso,
  });
  @override
  State<_DialogoInscritos> createState() => _DialogoInscritosState();
}

class _DialogoInscritosState extends State<_DialogoInscritos> {
  Set<int> _inscritos = {};
  bool _cargando = true;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await _sb
          .from('inscripciones')
          .select('idMiembro')
          .eq('idCurso', widget.curso['id']);
      setState(() {
        _inscritos = (data as List).map((r) => r['idMiembro'] as int).toSet();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _toggle(int idMiembro, bool agregar) async {
    try {
      if (agregar) {
        await _sb.from('inscripciones').insert({
          'idCurso': widget.curso['id'],
          'idMiembro': idMiembro,
          'fecha': DateTime.now().toIso8601String().substring(0, 10),
        });
        setState(() => _inscritos.add(idMiembro));
      } else {
        await _sb
            .from('inscripciones')
            .delete()
            .eq('idCurso', widget.curso['id'])
            .eq('idMiembro', idMiembro);
        setState(() => _inscritos.remove(idMiembro));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kDanger),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filtrados {
    final q = _busqueda.toLowerCase();
    final idCursoActual = widget.curso['id'] as int;

    // Miembros inscritos en OTROS cursos
    final enOtrosCursos = <int>{};
    widget.inscritosPorCurso.forEach((cid, mids) {
      if (cid != idCursoActual) enOtrosCursos.addAll(mids);
    });

    return widget.todosMiembros.where((m) {
      final mid = m['id'] as int;

      // Los guías de cualquier curso no pueden ser inscritos
      if (widget.idsGuias.contains(mid)) return false;

      // Si ya está inscrito en este curso aparece (para quitarlo)
      // Si está en otro curso no aparece
      final visible = _inscritos.contains(mid) || !enOtrosCursos.contains(mid);

      final pasaBusqueda =
          q.isEmpty || (m['nombre'] ?? '').toLowerCase().contains(q);

      return visible && pasaBusqueda;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBgMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                      color: const Color(0xFF1D9E75).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.people_outline,
                      color: Color(0xFF1D9E75),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inscritos — ${widget.curso['nombre']}',
                          style: const TextStyle(
                            color: kWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_inscritos.length} inscrito${_inscritos.length != 1 ? 's' : ''}',
                          style: const TextStyle(color: kGrey, fontSize: 12),
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

            // Buscador
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _busqueda = v),
                style: const TextStyle(color: kWhite, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar miembro por nombre...',
                  hintStyle: const TextStyle(color: kGrey, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: kGrey, size: 16),
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
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),

            // Lista
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: _kColor),
                    )
                  : _filtrados.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin resultados',
                        style: TextStyle(color: kGrey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtrados.length,
                      itemBuilder: (_, i) {
                        final m = _filtrados[i];
                        final inscrito = _inscritos.contains(m['id'] as int);
                        final inicial = (m['nombre'] ?? 'M')[0].toUpperCase();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: inscrito
                                ? const Color(
                                    0xFF1D9E75,
                                  ).withValues(alpha: 0.08)
                                : kBgCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: inscrito
                                  ? const Color(
                                      0xFF1D9E75,
                                    ).withValues(alpha: 0.35)
                                  : kDivider,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: inscrito,
                            activeColor: const Color(0xFF1D9E75),
                            checkColor: Colors.white,
                            title: Text(
                              m['nombre'] ?? '',
                              style: TextStyle(
                                color: inscrito ? kWhite : kGrey,
                                fontSize: 13,
                                fontWeight: inscrito
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            secondary: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: inscrito
                                    ? const Color(
                                        0xFF1D9E75,
                                      ).withValues(alpha: 0.15)
                                    : kBgMid,
                                border: Border.all(
                                  color: inscrito
                                      ? const Color(
                                          0xFF1D9E75,
                                        ).withValues(alpha: 0.4)
                                      : kDivider,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  inicial,
                                  style: TextStyle(
                                    color: inscrito
                                        ? const Color(0xFF1D9E75)
                                        : kGrey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            onChanged: (v) => _toggle(m['id'] as int, v!),
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
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

// ══════════════════════════════════════════════════════
//  FORMULARIO CREAR / EDITAR CURSO
// ══════════════════════════════════════════════════════
class _FormCurso extends StatefulWidget {
  final Map<String, dynamic>? curso;
  final List<Map<String, dynamic>> miembros;
  final Set<int> idsGuias;
  final List<Map<String, dynamic>> todosCursos;
  const _FormCurso({
    this.curso,
    required this.miembros,
    required this.idsGuias,
    required this.todosCursos,
  });
  @override
  State<_FormCurso> createState() => _FormCursoState();
}

class _FormCursoState extends State<_FormCurso> {
  final _nombreCtrl = TextEditingController();
  final _aulaCtrl = TextEditingController();
  final _horasCtrl = TextEditingController();
  final _horarioCtrl = TextEditingController();
  final _buscarGuiaCtrl = TextEditingController();

  Map<String, dynamic>? _guia;
  List<Map<String, dynamic>> _guiaFiltrados = [];
  List<int> _requisitosSeleccionados = [];
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.curso != null;

  List<Map<String, dynamic>> get _guiasDisponibles {
    return widget.miembros.where((m) {
      final mid = m['id'] as int;
      final esGuiaActual = widget.curso?['idGuia'] == mid;
      return esGuiaActual || !widget.idsGuias.contains(mid);
    }).toList();
  }

  // Cursos disponibles como requisito (no puede ser el mismo curso)
  List<Map<String, dynamic>> get _cursosParaRequisito {
    final idActual = widget.curso?['id'];
    return widget.todosCursos.where((c) => c['id'] != idActual).toList();
  }

  @override
  void initState() {
    super.initState();
    _guiaFiltrados = _guiasDisponibles;
    if (_esEdicion) {
      final c = widget.curso!;
      _nombreCtrl.text = c['nombre'] ?? '';
      _aulaCtrl.text = c['aula'] ?? '';
      _horasCtrl.text = '${c['horas'] ?? ''}';
      _horarioCtrl.text = c['horario'] ?? '';
      if (c['idGuia'] != null) {
        _guia = widget.miembros
            .where((m) => m['id'] == c['idGuia'])
            .firstOrNull;
        if (_guia != null) _buscarGuiaCtrl.text = _guia!['nombre'] ?? '';
      }
      _cargarRequisitos();
    }
    _buscarGuiaCtrl.addListener(() {
      final q = _buscarGuiaCtrl.text.toLowerCase();
      setState(() {
        _guiaFiltrados = q.isEmpty
            ? _guiasDisponibles
            : _guiasDisponibles
                  .where((m) => (m['nombre'] ?? '').toLowerCase().contains(q))
                  .toList();
      });
    });
  }

  Future<void> _cargarRequisitos() async {
    if (!_esEdicion) return;
    try {
      final data = await _sb
          .from('curso_requisitos')
          .select('idRequisito')
          .eq('idCurso', widget.curso!['id']);
      setState(() {
        _requisitosSeleccionados = (data as List)
            .map((r) => r['idRequisito'] as int)
            .toList();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _aulaCtrl.dispose();
    _horasCtrl.dispose();
    _horarioCtrl.dispose();
    _buscarGuiaCtrl.dispose();
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
      'horas': int.tryParse(_horasCtrl.text.trim()) ?? 0,
      'horario': _horarioCtrl.text.trim(),
      'idGuia': _guia?['id'],
      'estado': 'activo',
    };

    try {
      int cursoId;
      if (_esEdicion) {
        await _sb.from('curso').update(datos).eq('id', widget.curso!['id']);
        cursoId = widget.curso!['id'] as int;
        // Actualizar requisitos: borrar y reinsertar
        await _sb.from('curso_requisitos').delete().eq('idCurso', cursoId);
      } else {
        final res = await _sb.from('curso').insert(datos).select().single();
        cursoId = res['id'] as int;
      }

      // Guardar requisitos
      for (final reqId in _requisitosSeleccionados) {
        await _sb.from('curso_requisitos').insert({
          'idCurso': cursoId,
          'idRequisito': reqId,
        });
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _lbl('DATOS DEL CURSO'),
                    const SizedBox(height: 12),
                    _tf(
                      _nombreCtrl,
                      'Nombre del curso *',
                      Icons.school_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _tf(
                            _aulaCtrl,
                            'Aula / Salon',
                            Icons.meeting_room_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _tf(
                            _horasCtrl,
                            'Total de horas',
                            Icons.timer_outlined,
                            tipo: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _tf(
                      _horarioCtrl,
                      'Horario (ej: Sabado 10:00)',
                      Icons.schedule_outlined,
                    ),
                    const SizedBox(height: 20),

                    _lbl('GUIA DEL CURSO'),
                    const SizedBox(height: 4),
                    const Text(
                      'Solo se muestran miembros sin guia asignado',
                      style: TextStyle(color: kGrey, fontSize: 11),
                    ),
                    const SizedBox(height: 12),

                    // Guia seleccionado
                    if (_guia != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: kGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: kGold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: kGold, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _guia!['nombre'] ?? '',
                                style: const TextStyle(
                                  color: kGold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() {
                                _guia = null;
                                _buscarGuiaCtrl.clear();
                              }),
                              child: const Icon(
                                Icons.close,
                                color: kGold,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                    TextField(
                      controller: _buscarGuiaCtrl,
                      style: const TextStyle(color: kWhite, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar guia por nombre...',
                        hintStyle: const TextStyle(color: kGrey, fontSize: 13),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: kGrey,
                          size: 16,
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
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      constraints: const BoxConstraints(maxHeight: 160),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kDivider),
                      ),
                      child: _guiaFiltrados.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Sin resultados',
                                style: TextStyle(color: kGrey, fontSize: 13),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _guiaFiltrados.length,
                              itemBuilder: (_, i) {
                                final m = _guiaFiltrados[i];
                                final sel = _guia?['id'] == m['id'];
                                return InkWell(
                                  onTap: () => setState(() {
                                    _guia = m;
                                    _buscarGuiaCtrl.text = m['nombre'] ?? '';
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? _kColor.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: kDivider.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          color: sel ? _kColor : kGrey,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            m['nombre'] ?? '',
                                            style: TextStyle(
                                              color: sel ? _kColor : kWhite,
                                              fontSize: 13,
                                              fontWeight: sel
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        if (sel)
                                          const Icon(
                                            Icons.check,
                                            color: _kColor,
                                            size: 14,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 20),

                    // ── Requisitos ──────────────────────────────
                    _lbl('REQUISITOS PREVIOS'),
                    const SizedBox(height: 4),
                    const Text(
                      'El cursante debe haber completado estos cursos antes',
                      style: TextStyle(color: kGrey, fontSize: 11),
                    ),
                    const SizedBox(height: 12),

                    if (_cursosParaRequisito.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No hay otros cursos disponibles',
                          style: TextStyle(color: kGrey, fontSize: 13),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: kBgCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kDivider),
                        ),
                        child: Column(
                          children: _cursosParaRequisito.map((c) {
                            final cid = c['id'] as int;
                            final sel = _requisitosSeleccionados.contains(cid);
                            return CheckboxListTile(
                              value: sel,
                              activeColor: _kColor,
                              checkColor: Colors.white,
                              dense: true,
                              title: Text(
                                c['nombre'] ?? '',
                                style: TextStyle(
                                  color: sel ? kWhite : kGrey,
                                  fontSize: 13,
                                  fontWeight: sel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: c['aula'] != null
                                  ? Text(
                                      c['aula'],
                                      style: const TextStyle(
                                        color: kGrey,
                                        fontSize: 11,
                                      ),
                                    )
                                  : null,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _requisitosSeleccionados.add(cid);
                                  } else {
                                    _requisitosSeleccionados.remove(cid);
                                  }
                                });
                              },
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
