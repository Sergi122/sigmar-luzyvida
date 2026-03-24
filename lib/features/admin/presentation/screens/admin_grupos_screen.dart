import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sigmar_page.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFF7F77DD);

class AdminGruposScreen extends StatefulWidget {
  const AdminGruposScreen({super.key});
  @override
  State<AdminGruposScreen> createState() => _AdminGruposScreenState();
}

class _AdminGruposScreenState extends State<AdminGruposScreen> {
  List<Map<String, dynamic>> _grupos = [];
  List<Map<String, dynamic>> _filtrados = [];
  List<Map<String, dynamic>> _miembros = [];
  Set<int> _idsLideres = {};
  Map<int, Set<int>> _miembrosPorGrupo = {};
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
      final grupos = await _sb.from('grupos').select().order('nombre');
      final miembros = await _sb
          .from('miembros')
          .select('id, nombre')
          .eq('estado', 'activo')
          .order('nombre');

      // IDs de miembros que ya son líderes de algún grupo
      final idsLideres = (grupos as List)
          .where((g) => g['idLider'] != null)
          .map((g) => g['idLider'] as int)
          .toSet();

      // Cargar qué miembros están en cada grupo
      final todosMiembrosGrupo = await _sb
          .from('grupo_miembros')
          .select('idgrupo, idmiembro');

      // Mapa: idGrupo -> Set<idMiembro>
      final Map<int, Set<int>> miembrosPorGrupo = {};
      for (final r in (todosMiembrosGrupo as List)) {
        final gid = r['idgrupo'] as int;
        final mid = r['idmiembro'] as int;
        miembrosPorGrupo.putIfAbsent(gid, () => {}).add(mid);
      }

      // Obtener nombre del lider para cada grupo
      final List<Map<String, dynamic>> conLider = [];
      for (final g in grupos) {
        final m = Map<String, dynamic>.from(g);
        if (g['idLider'] != null) {
          try {
            final l = await _sb
                .from('miembros')
                .select('nombre')
                .eq('id', g['idLider'])
                .maybeSingle();
            m['liderNombre'] = l?['nombre'] ?? '';
          } catch (_) {}
        }
        conLider.add(m);
      }

      setState(() {
        _grupos = conLider;
        _miembros = List<Map<String, dynamic>>.from(miembros);
        _idsLideres = idsLideres;
        _miembrosPorGrupo = miembrosPorGrupo;
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
          ? _grupos
          : _grupos
                .where((g) => (g['nombre'] ?? '').toLowerCase().contains(q))
                .toList();
    });
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? kDanger : kSuccess),
    );
  }

  void _abrirForm({Map<String, dynamic>? grupo}) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormGrupo(
        grupo: grupo,
        miembros: _miembros,
        idsLideres: _idsLideres,
        grupoActualId: grupo?['id'],
      ),
    );
    if (ok == true) _cargar();
  }

  void _gestionarMiembros(Map<String, dynamic> g) async {
    await showDialog(
      context: context,
      builder: (_) => _DialogoMiembros(
        grupo: g,
        todosMiembros: _miembros,
        miembrosPorGrupo: _miembrosPorGrupo,
        idsLideres: _idsLideres,
      ),
    );
    _cargar();
  }

  void _eliminar(Map<String, dynamic> g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBgCard,
        title: const Text('Eliminar Grupo', style: TextStyle(color: kWhite)),
        content: Text(
          '¿Eliminar "${g['nombre']}"?',
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
      await _sb.from('grupos').delete().eq('id', g['id']);
      _snack('Grupo eliminado');
      _cargar();
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SigmarPage(
      rutaActual: '/admin/grupos',
      child: Padding(
        padding: const EdgeInsets.all(28),
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
                        'Administrar grupos de reunion',
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
                    'Nuevo Grupo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 50, height: 3, color: _kColor),
            const SizedBox(height: 24),

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
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.group_off_outlined,
                        color: kGrey,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _busqueda.isEmpty
                            ? 'No hay grupos registrados'
                            : 'Sin resultados para "$_busqueda"',
                        style: const TextStyle(color: kGrey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...(_filtrados.map(
                (g) => _TarjetaGrupo(
                  grupo: g,
                  onEditar: () => _abrirForm(grupo: g),
                  onMiembros: () => _gestionarMiembros(g),
                  onEliminar: () => _eliminar(g),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  TARJETA DE GRUPO
// ══════════════════════════════════════════════════════
class _TarjetaGrupo extends StatefulWidget {
  final Map<String, dynamic> grupo;
  final VoidCallback onEditar, onMiembros, onEliminar;
  const _TarjetaGrupo({
    required this.grupo,
    required this.onEditar,
    required this.onMiembros,
    required this.onEliminar,
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
              child: const Icon(Icons.group_outlined, color: _kColor, size: 22),
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
                          g['nombre'] ?? '',
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
                          g['estado'] ?? 'activo',
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
                  if (g['lugar'] != null)
                    _InfoRow(Icons.location_on_outlined, g['lugar']),
                  if (g['horario'] != null)
                    _InfoRow(Icons.schedule_outlined, g['horario']),
                  if ((g['liderNombre'] ?? '').isNotEmpty)
                    _InfoRow(
                      Icons.person_outline,
                      'Lider: ${g['liderNombre']}',
                      color: kGold,
                    ),
                  if (g['idLider'] == null)
                    _InfoRow(
                      Icons.person_off_outlined,
                      'Sin lider asignado',
                      color: kDanger,
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: kBgCard,
              icon: const Icon(Icons.more_vert, color: kGrey, size: 20),
              onSelected: (v) {
                if (v == 'miembros') widget.onMiembros();
                if (v == 'editar') widget.onEditar();
                if (v == 'eliminar') widget.onEliminar();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'miembros',
                  child: Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        color: Color(0xFF1D9E75),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Gestionar miembros',
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String texto;
  final Color color;
  const _InfoRow(this.icon, this.texto, {this.color = kGrey});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 3),
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
//  DIALOGO GESTIONAR MIEMBROS DEL GRUPO
// ══════════════════════════════════════════════════════
class _DialogoMiembros extends StatefulWidget {
  final Map<String, dynamic> grupo;
  final List<Map<String, dynamic>> todosMiembros;
  final Map<int, Set<int>> miembrosPorGrupo;
  final Set<int> idsLideres;
  const _DialogoMiembros({
    required this.grupo,
    required this.todosMiembros,
    required this.miembrosPorGrupo,
    required this.idsLideres,
  });
  @override
  State<_DialogoMiembros> createState() => _DialogoMiembrosState();
}

class _DialogoMiembrosState extends State<_DialogoMiembros> {
  Set<int> _enGrupo = {};
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
          .from('grupo_miembros')
          .select('idmiembro')
          .eq('idgrupo', widget.grupo['id']);
      setState(() {
        _enGrupo = (data as List).map((r) => r['idmiembro'] as int).toSet();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _toggle(int idMiembro, bool agregar) async {
    try {
      if (agregar) {
        await _sb.from('grupo_miembros').insert({
          'idgrupo': widget.grupo['id'],
          'idmiembro': idMiembro,
        });
        setState(() => _enGrupo.add(idMiembro));
      } else {
        await _sb
            .from('grupo_miembros')
            .delete()
            .eq('idgrupo', widget.grupo['id'])
            .eq('idmiembro', idMiembro);
        setState(() => _enGrupo.remove(idMiembro));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kDanger),
        );
    }
  }

  List<Map<String, dynamic>> get _filtrados {
    final q = _busqueda.toLowerCase();
    final idGrupoActual = widget.grupo['id'] as int;

    // Miembros que están en OTROS grupos
    final enOtrosGrupos = <int>{};
    widget.miembrosPorGrupo.forEach((gid, mids) {
      if (gid != idGrupoActual) enOtrosGrupos.addAll(mids);
    });

    return widget.todosMiembros.where((m) {
      final mid = m['id'] as int;

      // Los líderes de cualquier grupo NO pueden aparecer como miembros
      if (widget.idsLideres.contains(mid)) return false;

      // Si está en otro grupo no aparece (a menos que ya esté en este, para poder quitarlo)
      final visible = _enGrupo.contains(mid) || !enOtrosGrupos.contains(mid);

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
                          'Miembros — ${widget.grupo['nombre']}',
                          style: const TextStyle(
                            color: kWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_enGrupo.length} miembro${_enGrupo.length != 1 ? 's' : ''} en este grupo',
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
                        final enGrupo = _enGrupo.contains(m['id'] as int);
                        final inicial = (m['nombre'] ?? 'M')[0].toUpperCase();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: enGrupo
                                ? const Color(
                                    0xFF1D9E75,
                                  ).withValues(alpha: 0.08)
                                : kBgCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: enGrupo
                                  ? const Color(
                                      0xFF1D9E75,
                                    ).withValues(alpha: 0.35)
                                  : kDivider,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: enGrupo,
                            activeColor: const Color(0xFF1D9E75),
                            checkColor: Colors.white,
                            title: Text(
                              m['nombre'] ?? '',
                              style: TextStyle(
                                color: enGrupo ? kWhite : kGrey,
                                fontSize: 13,
                                fontWeight: enGrupo
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            secondary: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: enGrupo
                                    ? const Color(
                                        0xFF1D9E75,
                                      ).withValues(alpha: 0.15)
                                    : kBgMid,
                                border: Border.all(
                                  color: enGrupo
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
                                    color: enGrupo
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
//  FORMULARIO CREAR / EDITAR GRUPO
// ══════════════════════════════════════════════════════
class _FormGrupo extends StatefulWidget {
  final Map<String, dynamic>? grupo;
  final List<Map<String, dynamic>> miembros;
  final Set<int> idsLideres;
  final int? grupoActualId;
  const _FormGrupo({
    this.grupo,
    required this.miembros,
    required this.idsLideres,
    this.grupoActualId,
  });
  @override
  State<_FormGrupo> createState() => _FormGrupoState();
}

class _FormGrupoState extends State<_FormGrupo> {
  final _nombreCtrl = TextEditingController();
  final _lugarCtrl = TextEditingController();
  final _horarioCtrl = TextEditingController();
  final _buscarCtrl = TextEditingController();

  Map<String, dynamic>? _lider;
  List<Map<String, dynamic>> _liderFiltrados = [];
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.grupo != null;

  // Excluye líderes de otros grupos, pero permite el lider actual de este grupo
  List<Map<String, dynamic>> get _miembrosDisponibles {
    return widget.miembros.where((m) {
      final mid = m['id'] as int;
      final esLiderActual = widget.grupo?['idLider'] == mid;
      return esLiderActual || !widget.idsLideres.contains(mid);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _liderFiltrados = _miembrosDisponibles;
    if (_esEdicion) {
      final g = widget.grupo!;
      _nombreCtrl.text = g['nombre'] ?? '';
      _lugarCtrl.text = g['lugar'] ?? '';
      _horarioCtrl.text = g['horario'] ?? '';
      if (g['idLider'] != null) {
        _lider = widget.miembros
            .where((m) => m['id'] == g['idLider'])
            .firstOrNull;
        if (_lider != null) _buscarCtrl.text = _lider!['nombre'] ?? '';
      }
    }
    _buscarCtrl.addListener(() {
      final q = _buscarCtrl.text.toLowerCase();
      setState(() {
        _liderFiltrados = q.isEmpty
            ? _miembrosDisponibles
            : _miembrosDisponibles
                  .where((m) => (m['nombre'] ?? '').toLowerCase().contains(q))
                  .toList();
      });
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _lugarCtrl.dispose();
    _horarioCtrl.dispose();
    _buscarCtrl.dispose();
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
      'lugar': _lugarCtrl.text.trim(),
      'horario': _horarioCtrl.text.trim(),
      'idLider': _lider?['id'],
      'estado': 'activo',
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
                    _lbl('DATOS DEL GRUPO'),
                    const SizedBox(height: 12),
                    _tf(
                      _nombreCtrl,
                      'Nombre del grupo *',
                      Icons.group_outlined,
                    ),
                    const SizedBox(height: 12),
                    _tf(
                      _lugarCtrl,
                      'Lugar / Direccion',
                      Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 12),
                    _tf(
                      _horarioCtrl,
                      'Horario (ej: Viernes 19:00)',
                      Icons.schedule_outlined,
                    ),
                    const SizedBox(height: 20),

                    _lbl('LIDER DEL GRUPO'),
                    const SizedBox(height: 4),
                    const Text(
                      'Solo se muestran miembros sin liderazgo asignado',
                      style: TextStyle(color: kGrey, fontSize: 11),
                    ),
                    const SizedBox(height: 12),

                    if (_lider != null)
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
                                _lider!['nombre'] ?? '',
                                style: const TextStyle(
                                  color: kGold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() {
                                _lider = null;
                                _buscarCtrl.clear();
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
                      controller: _buscarCtrl,
                      style: const TextStyle(color: kWhite, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar lider por nombre...',
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
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kDivider),
                      ),
                      child: _liderFiltrados.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Sin resultados',
                                style: TextStyle(color: kGrey, fontSize: 13),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _liderFiltrados.length,
                              itemBuilder: (_, i) {
                                final m = _liderFiltrados[i];
                                final sel = _lider?['id'] == m['id'];
                                return InkWell(
                                  onTap: () => setState(() {
                                    _lider = m;
                                    _buscarCtrl.text = m['nombre'] ?? '';
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

  Widget _tf(TextEditingController ctrl, String label, IconData icon) =>
      TextField(
        controller: ctrl,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
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
