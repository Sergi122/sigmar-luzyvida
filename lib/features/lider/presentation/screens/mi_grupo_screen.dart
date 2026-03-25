import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/session.dart';
import '../../../../shared/widgets/sigmar_page.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFF378ADD);

class MiGrupoScreen extends StatefulWidget {
  const MiGrupoScreen({super.key});
  @override
  State<MiGrupoScreen> createState() => _MiGrupoScreenState();
}

class _MiGrupoScreenState extends State<MiGrupoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  Map<String, dynamic>? _grupo;
  List<Map<String, dynamic>> _miembros = [];
  List<Map<String, dynamic>> _asistencias = [];
  bool _cargando = true;
  String? _error;

  // Fecha seleccionada para asistencia (hoy por defecto)
  DateTime _fechaAsist = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Carga principal ──────────────────────────────────────
  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final miembroId = AppSession.usuario?['miembro_id'];
      if (miembroId == null) {
        setState(() {
          _error = 'Tu cuenta no está vinculada a un miembro.';
          _cargando = false;
        });
        return;
      }

      // 1. Grupo del líder
      final grupos = await _sb
          .from('grupos')
          .select()
          .eq('id_lider', miembroId)
          .eq('estado', 'activo')
          .limit(1);

      if (grupos.isEmpty) {
        setState(() {
          _error = 'No tienes ningún grupo asignado.';
          _cargando = false;
        });
        return;
      }

      _grupo = Map<String, dynamic>.from(grupos.first);

      // 2. Miembros del grupo
      await _cargarMiembros();

      // 3. Asistencia del día seleccionado
      await _cargarAsistencia();

      setState(() => _cargando = false);
    } catch (e) {
      setState(() {
        _error = 'Error al cargar: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _cargarMiembros() async {
    final data = await _sb
        .from('grupo_miembros')
        .select('id, miembros(id, nombre, telefono, estado, bautizado)')
        .eq('id_grupo', _grupo!['id']);
    _miembros = List<Map<String, dynamic>>.from(data);
  }

  Future<void> _cargarAsistencia() async {
    final fecha = _fechaAsist.toIso8601String().substring(0, 10);
    final data = await _sb
        .from('asistencia')
        .select()
        .eq('id_grupo', _grupo!['id'])
        .eq('fecha', fecha);
    _asistencias = List<Map<String, dynamic>>.from(data);
  }

  // ── Helpers ──────────────────────────────────────────────
  void _msg(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: error ? kDanger : kSuccess),
    );
  }

  bool _presente(int idMiembro) => _asistencias.any(
    (a) => a['id_miembro'] == idMiembro && a['presente'] == true,
  );

  // ── Asistencia toggle ─────────────────────────────────────
  Future<void> _toggleAsistencia(int idMiembro) async {
    final fecha = _fechaAsist.toIso8601String().substring(0, 10);
    final yaPresente = _presente(idMiembro);
    try {
      if (yaPresente) {
        // Marcar ausente (update)
        await _sb
            .from('asistencia')
            .update({'presente': false})
            .eq('id_grupo', _grupo!['id'])
            .eq('id_miembro', idMiembro)
            .eq('fecha', fecha);
      } else {
        // Upsert — si no existe lo crea, si existe lo marca presente
        await _sb.from('asistencia').upsert({
          'id_miembro': idMiembro,
          'id_grupo': _grupo!['id'],
          'fecha': fecha,
          'presente': true,
          'registrado_por': AppSession.usuario?['miembro_id'],
        }, onConflict: 'id_miembro,id_grupo,fecha');
      }
      await _cargarAsistencia();
      setState(() {});
    } catch (e) {
      _msg('Error: $e', error: true);
    }
  }

  // ── Buscar miembro para agregar ───────────────────────────
  Future<void> _abrirAgregarMiembro() async {
    // IDs ya en el grupo
    final idsActuales = _miembros
        .map((m) => (m['miembros'] as Map)['id'] as int)
        .toSet();

    final todos = await _sb
        .from('miembros')
        .select('id, nombre')
        .eq('estado', 'activo')
        .order('nombre');

    final disponibles = (todos as List)
        .map((e) => Map<String, dynamic>.from(e))
        .where((m) => !idsActuales.contains(m['id']))
        .toList();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => _DialogAgregarMiembro(
        disponibles: disponibles,
        onAgregar: (idMiembro) async {
          await _sb.from('grupo_miembros').insert({
            'id_grupo': _grupo!['id'],
            'id_miembro': idMiembro,
          });
          await _cargarMiembros();
          setState(() {});
          _msg('Miembro agregado al grupo');
        },
      ),
    );
  }

  // ── Eliminar miembro del grupo ────────────────────────────
  Future<void> _eliminarDelGrupo(Map<String, dynamic> fila) async {
    final nombre = (fila['miembros'] as Map)['nombre'] ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogConfirm(
        titulo: 'Quitar del grupo',
        mensaje: '¿Quitar a $nombre de tu grupo?',
      ),
    );
    if (ok != true) return;
    await _sb.from('grupo_miembros').delete().eq('id', fila['id']);
    await _cargarMiembros();
    setState(() {});
    _msg('$nombre quitado del grupo');
  }

  // ── Seleccionar fecha asistencia ──────────────────────────
  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaAsist,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kColor,
            surface: kBgMid,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    _fechaAsist = picked;
    await _cargarAsistencia();
    setState(() {});
  }

  // ════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return SigmarPage(
      rutaActual: '/lider/grupo',
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado ──────────────────────────────
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _grupo != null
                            ? _grupo!['nombre'] ?? 'Mi Grupo'
                            : 'Mi Grupo',
                        style: const TextStyle(
                          color: kWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _grupo != null
                            ? '${_grupo!['lugar'] ?? ''} · ${_diasLabel(_grupo!['dia_semana'])} ${_grupo!['hora'] ?? ''}'
                            : 'Gestionar tu grupo de reunión',
                        style: const TextStyle(color: kGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 50, height: 3, color: _kColor),
            const SizedBox(height: 24),

            // ── Estado de carga / error ──────────────────
            if (_cargando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(60),
                  child: CircularProgressIndicator(color: _kColor),
                ),
              )
            else if (_error != null)
              _PanelError(mensaje: _error!, onReintentar: _cargar)
            else ...[
              // ── Tarjetas resumen ────────────────────────
              _ResumenGrupo(
                totalMiembros: _miembros.length,
                presentes: _asistencias
                    .where((a) => a['presente'] == true)
                    .length,
                dia: _diasLabel(_grupo!['dia_semana']),
                hora: _grupo!['hora'] ?? '',
                lugar: _grupo!['lugar'] ?? '',
              ),
              const SizedBox(height: 20),

              // ── Tabs ────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: kBgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kDivider),
                ),
                child: TabBar(
                  controller: _tab,
                  indicatorColor: _kColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: _kColor,
                  unselectedLabelColor: kGrey,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: '👥 INTEGRANTES (${_miembros.length})'),
                    const Tab(text: '✅ ASISTENCIA'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 560,
                child: TabBarView(
                  controller: _tab,
                  children: [
                    // ── TAB INTEGRANTES ──────────────────
                    _TabIntegrantes(
                      miembros: _miembros,
                      onAgregar: _abrirAgregarMiembro,
                      onEliminar: _eliminarDelGrupo,
                    ),
                    // ── TAB ASISTENCIA ───────────────────
                    _TabAsistencia(
                      miembros: _miembros,
                      fecha: _fechaAsist,
                      presente: _presente,
                      onToggle: _toggleAsistencia,
                      onCambiarFecha: _seleccionarFecha,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _diasLabel(String? d) {
    const map = {
      'lunes': 'Lunes',
      'martes': 'Martes',
      'miercoles': 'Miércoles',
      'jueves': 'Jueves',
      'viernes': 'Viernes',
      'sabado': 'Sábado',
      'domingo': 'Domingo',
    };
    return map[d] ?? d ?? '';
  }
}

// ══════════════════════════════════════════════════════
//  RESUMEN DEL GRUPO
// ══════════════════════════════════════════════════════
class _ResumenGrupo extends StatelessWidget {
  final int totalMiembros, presentes;
  final String dia, hora, lugar;
  const _ResumenGrupo({
    required this.totalMiembros,
    required this.presentes,
    required this.dia,
    required this.hora,
    required this.lugar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TarjetaStat(
          icono: Icons.people_outline,
          valor: '$totalMiembros',
          etiqueta: 'Integrantes',
          color: _kColor,
        ),
        const SizedBox(width: 12),
        _TarjetaStat(
          icono: Icons.check_circle_outline,
          valor: '$presentes',
          etiqueta: 'Presentes hoy',
          color: kSuccess,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kDivider),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: kGold,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$dia $hora',
                        style: const TextStyle(
                          color: kWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        lugar,
                        style: const TextStyle(color: kGrey, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TarjetaStat extends StatelessWidget {
  final IconData icono;
  final String valor, etiqueta;
  final Color color;
  const _TarjetaStat({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kBgCard,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: kDivider),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(etiqueta, style: const TextStyle(color: kGrey, fontSize: 11)),
          ],
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
//  TAB INTEGRANTES
// ══════════════════════════════════════════════════════
class _TabIntegrantes extends StatefulWidget {
  final List<Map<String, dynamic>> miembros;
  final VoidCallback onAgregar;
  final Future<void> Function(Map<String, dynamic>) onEliminar;
  const _TabIntegrantes({
    required this.miembros,
    required this.onAgregar,
    required this.onEliminar,
  });
  @override
  State<_TabIntegrantes> createState() => _TabIntegrantesState();
}

class _TabIntegrantesState extends State<_TabIntegrantes> {
  String _busqueda = '';

  List<Map<String, dynamic>> get _filtrados {
    if (_busqueda.isEmpty) return widget.miembros;
    return widget.miembros.where((f) {
      final nombre = ((f['miembros'] as Map)['nombre'] ?? '').toLowerCase();
      return nombre.contains(_busqueda.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra superior
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _busqueda = v),
                style: const TextStyle(color: kWhite, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar integrante...',
                  hintStyle: const TextStyle(color: kGrey, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: kGrey, size: 18),
                  filled: true,
                  fillColor: kBgCard,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
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
            ElevatedButton.icon(
              onPressed: widget.onAgregar,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.person_add_outlined, size: 16),
              label: const Text(
                'Agregar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (widget.miembros.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off_outlined, color: kGrey, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'No hay integrantes en tu grupo',
                    style: TextStyle(color: kGrey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Usa el botón Agregar para añadir miembros',
                    style: TextStyle(color: kGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _filtrados.length,
              itemBuilder: (_, i) {
                final fila = _filtrados[i];
                final m = fila['miembros'] as Map;
                final nombre = m['nombre'] as String? ?? '';
                final telefono = m['telefono'] as String? ?? '';
                final bautizado = m['bautizado'] as bool? ?? false;
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
                        radius: 22,
                        backgroundColor: _kColor.withValues(alpha: 0.15),
                        child: Text(
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: _kColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: const TextStyle(
                                color: kWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (telefono.isNotEmpty)
                              Text(
                                telefono,
                                style: const TextStyle(
                                  color: kGrey,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (bautizado)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: kSuccess.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: kSuccess.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            'Bautizado',
                            style: TextStyle(color: kSuccess, fontSize: 10),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.person_remove_outlined,
                          color: kDanger,
                          size: 18,
                        ),
                        tooltip: 'Quitar del grupo',
                        onPressed: () => widget.onEliminar(fila),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════
//  TAB ASISTENCIA
// ══════════════════════════════════════════════════════
class _TabAsistencia extends StatelessWidget {
  final List<Map<String, dynamic>> miembros;
  final DateTime fecha;
  final bool Function(int) presente;
  final Future<void> Function(int) onToggle;
  final VoidCallback onCambiarFecha;

  const _TabAsistencia({
    required this.miembros,
    required this.fecha,
    required this.presente,
    required this.onToggle,
    required this.onCambiarFecha,
  });

  @override
  Widget build(BuildContext context) {
    final fechaStr =
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    final presentes = miembros
        .where((f) => presente((f['miembros'] as Map)['id']))
        .length;

    return Column(
      children: [
        // Selector de fecha + estadística
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onCambiarFecha,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kDivider),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: _kColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        fechaStr,
                        style: const TextStyle(
                          color: kWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: kGrey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kSuccess.withValues(alpha: 0.3)),
              ),
              child: Text(
                '$presentes / ${miembros.length} presentes',
                style: const TextStyle(
                  color: kSuccess,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Indicación
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _kColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: _kColor, size: 15),
              SizedBox(width: 8),
              Text(
                'Toca el botón ✓ para marcar presente / ausente',
                style: TextStyle(color: kGrey, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (miembros.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'No hay integrantes en el grupo',
                style: TextStyle(color: kGrey),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: miembros.length,
              itemBuilder: (_, i) {
                final m = miembros[i]['miembros'] as Map;
                final idMiembro = m['id'] as int;
                final nombre = m['nombre'] as String? ?? '';
                final estaPresente = presente(idMiembro);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: estaPresente
                        ? kSuccess.withValues(alpha: 0.06)
                        : kBgMid,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: estaPresente
                          ? kSuccess.withValues(alpha: 0.3)
                          : kDivider,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: estaPresente
                            ? kSuccess.withValues(alpha: 0.15)
                            : _kColor.withValues(alpha: 0.12),
                        child: Text(
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: estaPresente ? kSuccess : _kColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          nombre,
                          style: TextStyle(
                            color: estaPresente ? kWhite : kGrey,
                            fontWeight: estaPresente
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // Badge estado
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: estaPresente
                              ? kSuccess.withValues(alpha: 0.12)
                              : kDanger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          estaPresente ? 'Presente' : 'Ausente',
                          style: TextStyle(
                            color: estaPresente ? kSuccess : kDanger,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Toggle
                      GestureDetector(
                        onTap: () => onToggle(idMiembro),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: estaPresente ? kSuccess : kBgCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: estaPresente ? kSuccess : kDivider,
                            ),
                          ),
                          child: Icon(
                            estaPresente ? Icons.check : Icons.close,
                            color: estaPresente ? Colors.white : kGrey,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════
//  DIALOG AGREGAR MIEMBRO
// ══════════════════════════════════════════════════════
class _DialogAgregarMiembro extends StatefulWidget {
  final List<Map<String, dynamic>> disponibles;
  final Future<void> Function(int idMiembro) onAgregar;
  const _DialogAgregarMiembro({
    required this.disponibles,
    required this.onAgregar,
  });
  @override
  State<_DialogAgregarMiembro> createState() => _DialogAgregarMiembroState();
}

class _DialogAgregarMiembroState extends State<_DialogAgregarMiembro> {
  String _busqueda = '';
  bool _procesando = false;

  List<Map<String, dynamic>> get _filtrados {
    if (_busqueda.isEmpty) return widget.disponibles;
    return widget.disponibles
        .where(
          (m) => (m['nombre'] ?? '').toLowerCase().contains(
            _busqueda.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBgMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 420,
        height: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
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
                    Icons.person_add_outlined,
                    color: _kColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Agregar al grupo',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: kGrey, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Buscador
            TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _busqueda = v),
              style: const TextStyle(color: kWhite, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar miembro...',
                hintStyle: const TextStyle(color: kGrey),
                prefixIcon: const Icon(Icons.search, color: kGrey, size: 18),
                filled: true,
                fillColor: kBgCard,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
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
            const SizedBox(height: 12),

            Text(
              '${_filtrados.length} miembros disponibles',
              style: const TextStyle(color: kGrey, fontSize: 11),
            ),
            const SizedBox(height: 8),

            // Lista
            Expanded(
              child: _filtrados.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay miembros disponibles',
                        style: TextStyle(color: kGrey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtrados.length,
                      itemBuilder: (_, i) {
                        final m = _filtrados[i];
                        final nombre = m['nombre'] as String? ?? '';
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: _kColor.withValues(alpha: 0.15),
                            child: Text(
                              nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: _kColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            nombre,
                            style: const TextStyle(color: kWhite, fontSize: 13),
                          ),
                          trailing: _procesando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _kColor,
                                  ),
                                )
                              : const Icon(
                                  Icons.add_circle_outline,
                                  color: _kColor,
                                  size: 22,
                                ),
                          onTap: _procesando
                              ? null
                              : () async {
                                  setState(() => _procesando = true);
                                  await widget.onAgregar(m['id'] as int);
                                  if (mounted) Navigator.pop(context);
                                },
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

// ══════════════════════════════════════════════════════
//  WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════

class _PanelError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _PanelError({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: kDanger, size: 48),
          const SizedBox(height: 16),
          Text(
            mensaje,
            style: const TextStyle(color: kGrey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onReintentar,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
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
      width: 340,
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
