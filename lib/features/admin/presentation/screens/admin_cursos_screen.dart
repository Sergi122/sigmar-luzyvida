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

  // 0 = Cursos Activos  |  1 = Historial
  int _tabActual = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      // FIX 1: Consulta simplificada para evitar errores de llave foránea (404/400)
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

  List<Map<String, dynamic>> get _cursosActivos => _cursos.where((c) {
    final estado = c['estado'] ?? '';
    if (estado == 'finalizado') return false;
    final nombre = (c['nombre'] ?? '').toLowerCase();
    final pasaBusqueda =
        _busqueda.isEmpty || nombre.contains(_busqueda.toLowerCase());
    final pasaEstado = _filtroEstado == 'todos' || estado == _filtroEstado;
    return pasaBusqueda && pasaEstado;
  }).toList();

  List<Map<String, dynamic>> get _cursosFinalizados => _cursos.where((c) {
    if ((c['estado'] ?? '') != 'finalizado') return false;
    final nombre = (c['nombre'] ?? '').toLowerCase();
    return _busqueda.isEmpty || nombre.contains(_busqueda.toLowerCase());
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

  Future<void> _finalizarCurso(Map<String, dynamic> c) async {
    final nombreBase = _nombreBase(c['nombre'] ?? '');
    final versiones = _cursos
        .where((x) => _nombreBase(x['nombre'] ?? '') == nombreBase)
        .length;
    final nuevoNombre = '$nombreBase v${versiones + 1}';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogConfirm(
        titulo: 'Finalizar curso',
        mensaje:
            '¿Finalizar "${c['nombre']}"?\n\n'
            'Se guardará en el historial y se creará automáticamente '
            '"$nuevoNombre" como nuevo curso activo con la misma configuración.',
        botonTexto: 'Finalizar y crear versión',
        botonColor: kGold,
      ),
    );
    if (ok != true) return;

    try {
      await _sb
          .from('cursos')
          .update({'estado': 'finalizado'})
          .eq('id', c['id']);

      final nuevoCurso = await _sb
          .from('cursos')
          .insert({
            'nombre': nuevoNombre,
            'aula': c['aula'],
            'horas': c['horas'],
            'dia_semana': c['dia_semana'],
            'hora': c['hora'],
            'id_guia': c['id_guia'],
            'estado': 'activo',
          })
          .select('id')
          .single();

      final nuevoId = nuevoCurso['id'] as int;

      final requisitos = await _sb
          .from('curso_requisitos')
          .select()
          .eq('id_curso', c['id'] as int);

      if ((requisitos as List).isNotEmpty) {
        await _sb
            .from('curso_requisitos')
            .insert(
              requisitos
                  .map(
                    (r) => {
                      'id_curso': nuevoId,
                      'id_curso_prerequisito': r['id_curso_prerequisito'],
                      'requiere_bautismo': r['requiere_bautismo'],
                      'requiere_encuentro': r['requiere_encuentro'],
                    },
                  )
                  .toList(),
            );
      }

      _msg(
        '"${c['nombre']}" finalizado. "$nuevoNombre" creado automáticamente.',
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
            '¿Eliminar "${c['nombre']}"?\n\nSe perderán TODAS las inscripciones asociadas.',
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

  String _nombreBase(String nombre) {
    final regex = RegExp(r'\s+v\d+$', caseSensitive: false);
    return nombre.replaceAll(regex, '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final activos = _cursosActivos;
    final finalizados = _cursosFinalizados;
    final lista = _tabActual == 0 ? activos : finalizados;

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
                    color: _kColor.withOpacity(
                      0.12,
                    ), // FIX 3: withValues -> withOpacity
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
                        'Administrar cursos, versiones e historial',
                        style: TextStyle(color: kGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (_tabActual == 0)
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

            // ── Tabs ──
            Container(
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kDivider),
              ),
              child: Row(
                children: [
                  _Tab(
                    icon: Icons.school_outlined,
                    label: 'CURSOS ACTIVOS',
                    activo: _tabActual == 0,
                    color: _kColor,
                    onTap: () => setState(() {
                      _tabActual = 0;
                      _busqueda = '';
                      _filtroEstado = 'todos';
                    }),
                  ),
                  _Tab(
                    icon: Icons.history,
                    label: 'HISTORIAL',
                    activo: _tabActual == 1,
                    color: kGold,
                    onTap: () => setState(() {
                      _tabActual = 1;
                      _busqueda = '';
                      _filtroEstado = 'todos';
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Búsqueda + filtro ──
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    key: ValueKey(_tabActual),
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
                        borderSide: BorderSide(
                          color: _tabActual == 0 ? _kColor : kGold,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_tabActual == 0) ...[
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
                          DropdownMenuItem(
                            value: 'todos',
                            child: Text('Todos'),
                          ),
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
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _tabActual == 0
                  ? '${activos.length} curso${activos.length != 1 ? 's' : ''}'
                  : '${finalizados.length} curso${finalizados.length != 1 ? 's' : ''} finalizado${finalizados.length != 1 ? 's' : ''}',
              style: const TextStyle(color: kGrey, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // ── Lista ──
            // FIX 2: Removido el "Expanded" que envolvía esto. Es el causante del RenderFlex Error
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
                        : _tabActual == 0
                        ? Icons.school_outlined
                        : Icons.history,
                    mensaje: _busqueda.isNotEmpty
                        ? 'Sin resultados para "$_busqueda"'
                        : _tabActual == 0
                        ? 'No hay cursos registrados'
                        : 'No hay cursos en el historial',
                  )
                : ListView.builder(
                    shrinkWrap:
                        true, // FIX 2.1: Necesario para listas dentro de un scroll infinito
                    physics:
                        const NeverScrollableScrollPhysics(), // FIX 2.2: Para no chocar con el scroll padre
                    itemCount: lista.length,
                    itemBuilder: (_, i) {
                      final c = lista[i];
                      final esHistorial = _tabActual == 1;
                      return _TarjetaCurso(
                        curso: c,
                        soloLectura: esHistorial,
                        onEditar: esHistorial
                            ? () {}
                            : () => _abrirFormulario(curso: c),
                        onFinalizar: esHistorial
                            ? () {}
                            : () => _finalizarCurso(c),
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
//  WIDGET TAB
// ══════════════════════════════════════════════════════
class _Tab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool activo;
  final Color color;
  final VoidCallback onTap;
  const _Tab({
    required this.icon,
    required this.label,
    required this.activo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: activo
                ? color.withOpacity(0.12)
                : Colors.transparent, // FIX 3
            borderRadius: BorderRadius.circular(9),
            border: Border(
              bottom: BorderSide(
                color: activo ? color : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: activo ? color : kGrey),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: activo ? color : kGrey,
                  fontSize: 13,
                  fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  EMPTY STATE
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
          Icon(icon, color: kGrey.withOpacity(0.4), size: 36), // FIX 3
          const SizedBox(height: 10),
          Text(mensaje, style: const TextStyle(color: kGrey)),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════
//  TARJETA CURSO
// ══════════════════════════════════════════════════════
class _TarjetaCurso extends StatelessWidget {
  final Map<String, dynamic> curso;
  final bool soloLectura;
  final VoidCallback onEditar, onFinalizar, onHistorial, onEliminar;
  const _TarjetaCurso({
    required this.curso,
    required this.soloLectura,
    required this.onEditar,
    required this.onFinalizar,
    required this.onHistorial,
    required this.onEliminar,
  });

  Color get _estadoColor {
    switch (curso['estado']) {
      case 'activo':
        return kSuccess;
      case 'finalizado':
        return kGold;
      default:
        return kDanger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = curso;
    final guiaNombre = (c['miembros'] as Map?)?['nombre'] ?? 'Sin guía';
    final estado = (c['estado'] ?? 'activo') as String;
    final finalizado = estado == 'finalizado';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgMid,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: finalizado ? kGold.withOpacity(0.2) : kDivider, // FIX 3
        ),
      ),
      child: Row(
        children: [
          // Ícono
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _estadoColor.withOpacity(0.12), // FIX 3
              border: Border.all(color: _estadoColor.withOpacity(0.4)), // FIX 3
            ),
            child: Center(
              child: finalizado
                  ? Icon(
                      Icons.lock_outline,
                      color: kGold.withOpacity(0.7), // FIX 3
                      size: 18,
                    )
                  : Text(
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
                        style: TextStyle(
                          color: finalizado
                              ? kGrey.withOpacity(0.8) // FIX 3
                              : kWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _BadgeEstado(estado: estado, color: _estadoColor),
                    if (finalizado) ...[
                      const SizedBox(width: 6),
                      _BadgeSoloLectura(),
                    ],
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
                if (finalizado)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: onHistorial,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history,
                            color: kGold.withOpacity(0.8), // FIX 3
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ver historial de inscritos',
                            style: TextStyle(
                              color: kGold.withOpacity(0.8), // FIX 3
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                              decorationColor: kGold.withOpacity(0.5), // FIX 3
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Menú contextual
          PopupMenuButton<String>(
            color: kBgCard,
            icon: const Icon(Icons.more_vert, color: kGrey, size: 20),
            onSelected: (v) {
              switch (v) {
                case 'editar':
                  onEditar();
                case 'historial':
                  onHistorial();
                case 'finalizar':
                  onFinalizar();
                case 'borrar':
                  onEliminar();
              }
            },
            itemBuilder: (_) => soloLectura ? _menuHistorial() : _menuActivo(),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _menuHistorial() => [
    const PopupMenuItem(
      value: 'historial',
      child: _MenuRow(
        icon: Icons.history,
        color: kGold,
        texto: 'Ver inscritos',
      ),
    ),
    const PopupMenuDivider(),
    const PopupMenuItem(
      value: 'borrar',
      child: _MenuRow(
        icon: Icons.delete_outline,
        color: kDanger,
        texto: 'Eliminar del historial',
        textoColor: kDanger,
      ),
    ),
  ];

  List<PopupMenuEntry<String>> _menuActivo() => [
    const PopupMenuItem(
      value: 'editar',
      child: _MenuRow(
        icon: Icons.edit_outlined,
        color: _kColor,
        texto: 'Editar',
      ),
    ),
    const PopupMenuItem(
      value: 'historial',
      child: _MenuRow(
        icon: Icons.history,
        color: kGold,
        texto: 'Ver inscritos',
      ),
    ),
    const PopupMenuItem(
      value: 'finalizar',
      child: _MenuRow(
        icon: Icons.check_circle_outline,
        color: kGold,
        texto: 'Finalizar y crear nueva versión',
      ),
    ),
    const PopupMenuDivider(),
    const PopupMenuItem(
      value: 'borrar',
      child: _MenuRow(
        icon: Icons.delete_outline,
        color: kDanger,
        texto: 'Eliminar',
        textoColor: kDanger,
      ),
    ),
  ];
}

// ── Badges ────────────────────────────────────────────
class _BadgeEstado extends StatelessWidget {
  final String estado;
  final Color color;
  const _BadgeEstado({required this.estado, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), // FIX 3
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withOpacity(0.3)), // FIX 3
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

class _BadgeSoloLectura extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: kGrey.withOpacity(0.08), // FIX 3
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: kGrey.withOpacity(0.2)), // FIX 3
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.lock_outline,
          color: kGrey.withOpacity(0.5),
          size: 9,
        ), // FIX 3
        const SizedBox(width: 3),
        Text(
          'SOLO LECTURA',
          style: TextStyle(
            color: kGrey.withOpacity(0.5), // FIX 3
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
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

// ══════════════════════════════════════════════════════
//  DIALOG HISTORIAL DE INSCRITOS
// ══════════════════════════════════════════════════════
class _DialogHistorial extends StatefulWidget {
  final Map<String, dynamic> curso;
  const _DialogHistorial({required this.curso});
  @override
  State<_DialogHistorial> createState() => _DialogHistorialState();
}

class _DialogHistorialState extends State<_DialogHistorial> {
  List<Map<String, dynamic>> _inscritos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final data = await _sb
        .from('inscripciones')
        .select('*, miembros(nombre, carnet)')
        .eq('id_curso', widget.curso['id'] as int)
        .order('estado');
    setState(() {
      _inscritos = List<Map<String, dynamic>>.from(data);
      _cargando = false;
    });
  }

  Color _colorEstado(String e) => e == 'completado'
      ? kSuccess
      : e == 'retirado'
      ? kDanger
      : _kColor;
  IconData _iconEstado(String e) => e == 'completado'
      ? Icons.check_circle_outline
      : e == 'retirado'
      ? Icons.cancel_outlined
      : Icons.school_outlined;

  int get _completados =>
      _inscritos.where((i) => i['estado'] == 'completado').length;
  int get _retirados =>
      _inscritos.where((i) => i['estado'] == 'retirado').length;
  int get _activos => _inscritos.where((i) => i['estado'] == 'activo').length;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBgMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 520,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.80,
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
                      color: kGold.withOpacity(0.15), // FIX 3
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
                          'Historial de inscritos',
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

            if (_cargando)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: kGold)),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    _ResumenBadge('${_inscritos.length}', 'Total', kGrey),
                    const SizedBox(width: 8),
                    _ResumenBadge('$_completados', 'Completaron', kSuccess),
                    const SizedBox(width: 8),
                    _ResumenBadge('$_retirados', 'Retirados', kDanger),
                    const SizedBox(width: 8),
                    _ResumenBadge('$_activos', 'Activos', _kColor),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: kDivider, height: 1),
              Expanded(
                child: _inscritos.isEmpty
                    ? const Center(
                        child: Text(
                          'Sin inscritos en este curso',
                          style: TextStyle(color: kGrey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        itemCount: _inscritos.length,
                        itemBuilder: (_, i) {
                          final ins = _inscritos[i];
                          final miembro =
                              ins['miembros'] as Map<String, dynamic>?;
                          final estado = (ins['estado'] ?? 'activo') as String;
                          final color = _colorEstado(estado);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kBgCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: color.withOpacity(0.2), // FIX 3
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _iconEstado(estado),
                                  color: color,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        miembro?['nombre'] ?? '-',
                                        style: const TextStyle(
                                          color: kWhite,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Carnet: ${miembro?['carnet'] ?? '-'}',
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1), // FIX 3
                                        borderRadius: BorderRadius.circular(4),
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
                                    ),
                                    if (ins['fecha_fin'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          ins['fecha_fin'].toString(),
                                          style: const TextStyle(
                                            color: kGrey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],

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

class _ResumenBadge extends StatelessWidget {
  final String numero, label;
  final Color color;
  const _ResumenBadge(this.numero, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), // FIX 3
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)), // FIX 3
      ),
      child: Column(
        children: [
          Text(
            numero,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: const TextStyle(color: kGrey, fontSize: 10)),
        ],
      ),
    ),
  );
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
        .neq('estado', 'inactivo')
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
          maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                      color: _kColor.withOpacity(0.15), // FIX 3
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
                          color: kDanger.withOpacity(0.1), // FIX 3
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: kDanger.withOpacity(0.3), // FIX 3
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
          activeTrackColor: _kColor.withOpacity(0.3), // FIX 3
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
//  DIALOG CONFIRMAR
// ══════════════════════════════════════════════════════
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
