import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sigmar_page.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFF7F77DD);

class AdminAportesScreen extends StatefulWidget {
  const AdminAportesScreen({super.key});
  @override
  State<AdminAportesScreen> createState() => _AdminAportesScreenState();
}

class _AdminAportesScreenState extends State<AdminAportesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SigmarPage tiene SingleChildScrollView interno, así que NO usamos
    // Expanded — en su lugar dejamos que el contenido tenga altura natural.
    return SigmarPage(
      rutaActual: '/admin/aportes',
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado ──────────────────────────────────
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
                    Icons.attach_money,
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
                        'Gestion de Aportes',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Diezmos y ofrendas de la iglesia',
                        style: TextStyle(color: kGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 50, height: 3, color: _kColor),
            const SizedBox(height: 24),

            // ── Tabs ────────────────────────────────────────
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
                tabs: const [
                  Tab(text: '💰 DIEZMOS'),
                  Tab(text: '🙏 OFRENDAS'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Contenido de tabs (altura fija, scroll interno) ──
            SizedBox(
              height: 680,
              child: TabBarView(
                controller: _tab,
                children: const [_TabDiezmos(), _TabOfrendas()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  TAB DIEZMOS
// ══════════════════════════════════════════════════════
class _TabDiezmos extends StatefulWidget {
  const _TabDiezmos();
  @override
  State<_TabDiezmos> createState() => _TabDiezmosState();
}

class _TabDiezmosState extends State<_TabDiezmos> {
  List<Map<String, dynamic>> _diezmos = [];
  List<Map<String, dynamic>> _miembros = [];
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
      final d = await _sb
          .from('diezmos')
          .select('*, miembros(nombre)')
          .order('fecha', ascending: false);
      final m = await _sb.from('miembros').select('id, nombre').order('nombre');
      setState(() {
        _diezmos = List<Map<String, dynamic>>.from(d);
        _miembros = List<Map<String, dynamic>>.from(m);
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _msg('Error cargando datos: $e', error: true);
    }
  }

  void _msg(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: error ? kDanger : kSuccess),
    );
  }

  List<Map<String, dynamic>> get _filtrados {
    if (_busqueda.isEmpty) return _diezmos;
    return _diezmos.where((d) {
      final nombre = ((d['miembros'] as Map?)?['nombre'] ?? '').toLowerCase();
      return nombre.contains(_busqueda.toLowerCase());
    }).toList();
  }

  void _abrirFormulario({Map<String, dynamic>? diezmo}) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormDiezmo(diezmo: diezmo, miembros: _miembros),
    );
    if (ok == true) _cargar();
  }

  Future<void> _eliminar(Map<String, dynamic> d) async {
    final nombre = (d['miembros'] as Map?)?['nombre'] ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogConfirm(
        titulo: 'Eliminar diezmo',
        mensaje: '¿Eliminar diezmo de $nombre?',
      ),
    );
    if (ok != true) return;
    await _sb.from('diezmos').delete().eq('id', d['id']);
    _msg('Diezmo eliminado');
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final total = _filtrados.fold<double>(
      0,
      (s, d) => s + ((d['monto'] as num?)?.toDouble() ?? 0),
    );

    return Column(
      children: [
        // Barra búsqueda + botón
        Row(
          children: [
            Expanded(
              child: _CampoBusqueda(
                hint: 'Buscar por nombre del miembro...',
                icono: Icons.search,
                onChanged: (v) => setState(() => _busqueda = v),
                colorFoco: _kColor,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _abrirFormulario(),
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
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'Registrar Diezmo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Totalizador
        _Totalizador(
          icono: Icons.account_balance_wallet_outlined,
          color: _kColor,
          total: total,
          cantidad: _filtrados.length,
        ),
        const SizedBox(height: 16),

        // Lista
        if (_cargando)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(color: _kColor)),
          )
        else if (_filtrados.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text(
                'No hay diezmos registrados',
                style: TextStyle(color: kGrey),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _filtrados.length,
              itemBuilder: (_, i) {
                final d = _filtrados[i];
                final nombre =
                    (d['miembros'] as Map?)?['nombre'] ?? 'Sin nombre';
                return _FilaDiezmo(
                  nombre: nombre,
                  fecha: d['fecha'] ?? '',
                  observacion: d['observacion'] ?? '',
                  monto: (d['monto'] as num?)?.toDouble() ?? 0,
                  onEditar: () => _abrirFormulario(diezmo: d),
                  onEliminar: () => _eliminar(d),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════
//  TAB OFRENDAS
// ══════════════════════════════════════════════════════
class _TabOfrendas extends StatefulWidget {
  const _TabOfrendas();
  @override
  State<_TabOfrendas> createState() => _TabOfrendasState();
}

class _TabOfrendasState extends State<_TabOfrendas> {
  List<Map<String, dynamic>> _ofrendas = [];
  bool _cargando = true;
  String _filtrFecha = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final data = await _sb
          .from('ofrendas')
          .select()
          .order('fecha', ascending: false);
      setState(() {
        _ofrendas = List<Map<String, dynamic>>.from(data);
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  void _msg(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: error ? kDanger : kSuccess),
    );
  }

  List<Map<String, dynamic>> get _filtrados {
    if (_filtrFecha.isEmpty) return _ofrendas;
    return _ofrendas
        .where((o) => (o['fecha'] ?? '').contains(_filtrFecha))
        .toList();
  }

  void _registrar() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _FormOfrenda(),
    );
    if (ok == true) _cargar();
  }

  Future<void> _eliminar(Map<String, dynamic> o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _DialogConfirm(
        titulo: 'Eliminar ofrenda',
        mensaje: '¿Eliminar este registro de ofrenda?',
      ),
    );
    if (ok != true) return;
    await _sb.from('ofrendas').delete().eq('id', o['id']);
    _msg('Ofrenda eliminada');
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final total = _filtrados.fold<double>(
      0,
      (s, o) => s + ((o['monto'] as num?)?.toDouble() ?? 0),
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _CampoBusqueda(
                hint: 'Filtrar por fecha (ej: 2026-03)...',
                icono: Icons.calendar_today_outlined,
                onChanged: (v) => setState(() => _filtrFecha = v),
                colorFoco: kGold,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _registrar,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'Registrar Ofrenda',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _Totalizador(
          icono: Icons.church_outlined,
          color: kGold,
          total: total,
          cantidad: _filtrados.length,
        ),
        const SizedBox(height: 16),

        if (_cargando)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(color: kGold)),
          )
        else if (_filtrados.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text(
                'No hay ofrendas registradas',
                style: TextStyle(color: kGrey),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _filtrados.length,
              itemBuilder: (_, i) {
                final o = _filtrados[i];
                return _FilaOfrenda(
                  tipo: o['tipo'] ?? 'general',
                  fecha: o['fecha'] ?? '',
                  descripcion: o['descripcion'] ?? '',
                  monto: (o['monto'] as num?)?.toDouble() ?? 0,
                  onEliminar: () => _eliminar(o),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════
//  WIDGETS REUTILIZABLES
// ══════════════════════════════════════════════════════

class _CampoBusqueda extends StatelessWidget {
  final String hint;
  final IconData icono;
  final ValueChanged<String> onChanged;
  final Color colorFoco;
  const _CampoBusqueda({
    required this.hint,
    required this.icono,
    required this.onChanged,
    required this.colorFoco,
  });

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    style: const TextStyle(color: kWhite, fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kGrey, fontSize: 12),
      prefixIcon: Icon(icono, color: kGrey, size: 18),
      filled: true,
      fillColor: kBgCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: BorderSide(color: colorFoco, width: 2),
      ),
    ),
  );
}

class _Totalizador extends StatelessWidget {
  final IconData icono;
  final Color color;
  final double total;
  final int cantidad;
  const _Totalizador({
    required this.icono,
    required this.color,
    required this.total,
    required this.cantidad,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Row(
      children: [
        Icon(icono, color: color, size: 18),
        const SizedBox(width: 10),
        Text(
          'Total: Bs. ${total.toStringAsFixed(2)}',
          style: const TextStyle(
            color: kWhite,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          '$cantidad registros',
          style: const TextStyle(color: kGrey, fontSize: 12),
        ),
      ],
    ),
  );
}

class _FilaDiezmo extends StatelessWidget {
  final String nombre, fecha, observacion;
  final double monto;
  final VoidCallback onEditar, onEliminar;
  const _FilaDiezmo({
    required this.nombre,
    required this.fecha,
    required this.observacion,
    required this.monto,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) => Container(
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
          radius: 20,
          backgroundColor: _kColor.withValues(alpha: 0.15),
          child: Text(
            nombre[0].toUpperCase(),
            style: const TextStyle(color: _kColor, fontWeight: FontWeight.bold),
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
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                'Fecha: $fecha${observacion.isNotEmpty ? '  · $observacion' : ''}',
                style: const TextStyle(color: kGrey, fontSize: 11),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: kSuccess.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: kSuccess.withValues(alpha: 0.3)),
          ),
          child: Text(
            'Bs. ${monto.toStringAsFixed(2)}',
            style: const TextStyle(
              color: kSuccess,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: _kColor, size: 18),
          onPressed: onEditar,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: kDanger, size: 18),
          onPressed: onEliminar,
        ),
      ],
    ),
  );
}

class _FilaOfrenda extends StatelessWidget {
  final String tipo, fecha, descripcion;
  final double monto;
  final VoidCallback onEliminar;
  const _FilaOfrenda({
    required this.tipo,
    required this.fecha,
    required this.descripcion,
    required this.monto,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) => Container(
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
          radius: 20,
          backgroundColor: kGold.withValues(alpha: 0.15),
          child: const Icon(Icons.volunteer_activism, color: kGold, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ofrenda ${tipo.toUpperCase()}',
                style: const TextStyle(
                  color: kWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                'Fecha: $fecha${descripcion.isNotEmpty ? '  · $descripcion' : ''}',
                style: const TextStyle(color: kGrey, fontSize: 11),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: kGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: kGold.withValues(alpha: 0.3)),
          ),
          child: Text(
            'Bs. ${monto.toStringAsFixed(2)}',
            style: const TextStyle(
              color: kGold,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: kDanger, size: 18),
          onPressed: onEliminar,
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════
//  FORMULARIO DIEZMO
// ══════════════════════════════════════════════════════
class _FormDiezmo extends StatefulWidget {
  final Map<String, dynamic>? diezmo;
  final List<Map<String, dynamic>> miembros;
  const _FormDiezmo({this.diezmo, required this.miembros});
  @override
  State<_FormDiezmo> createState() => _FormDiezmoState();
}

class _FormDiezmoState extends State<_FormDiezmo> {
  final _montoCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  final _busquedaCtrl = TextEditingController();
  Map<String, dynamic>? _miembroSel;
  List<Map<String, dynamic>> _sugerencias = [];
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.diezmo != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _montoCtrl.text = '${widget.diezmo!['monto'] ?? ''}';
      _fechaCtrl.text = widget.diezmo!['fecha'] ?? '';
      _obsCtrl.text = widget.diezmo!['observacion'] ?? '';
      final idMiembro = widget.diezmo!['id_miembro'];
      _miembroSel = widget.miembros.firstWhere(
        (m) => m['id'] == idMiembro,
        orElse: () => {},
      );
      if (_miembroSel != null && _miembroSel!.isNotEmpty) {
        _busquedaCtrl.text = _miembroSel!['nombre'] ?? '';
      }
    } else {
      _fechaCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    }
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _fechaCtrl.dispose();
    _obsCtrl.dispose();
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _buscar(String q) {
    setState(() {
      _sugerencias = q.isEmpty
          ? []
          : widget.miembros
                .where(
                  (m) => (m['nombre'] ?? '').toLowerCase().contains(
                    q.toLowerCase(),
                  ),
                )
                .take(5)
                .toList();
    });
  }

  Future<void> _guardar() async {
    if (_miembroSel == null || _miembroSel!.isEmpty) {
      setState(() => _error = 'Selecciona un miembro.');
      return;
    }
    final monto = double.tryParse(_montoCtrl.text.trim());
    if (monto == null || monto <= 0) {
      setState(() => _error = 'Ingresa un monto válido.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    final datos = {
      'id_miembro': _miembroSel!['id'],
      'monto': monto,
      'fecha': _fechaCtrl.text.trim(),
      'observacion': _obsCtrl.text.trim(),
    };
    try {
      if (_esEdicion) {
        await _sb.from('diezmos').update(datos).eq('id', widget.diezmo!['id']);
      } else {
        await _sb.from('diezmos').insert(datos);
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CabeceraDialog(
              icono: Icons.attach_money,
              color: _kColor,
              titulo: _esEdicion ? 'Editar Diezmo' : 'Registrar Diezmo',
            ),
            const SizedBox(height: 20),

            // Buscador miembro
            _Label('MIEMBRO'),
            const SizedBox(height: 8),
            TextField(
              controller: _busquedaCtrl,
              onChanged: _buscar,
              style: const TextStyle(color: kWhite, fontSize: 13),
              decoration: _decoInput(
                hint: 'Buscar miembro...',
                icono: Icons.person_search,
                colorFoco: _kColor,
                sufijo: _miembroSel != null && _miembroSel!.isNotEmpty
                    ? const Icon(Icons.check_circle, color: kSuccess, size: 18)
                    : null,
              ),
            ),
            if (_sugerencias.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: kBgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kDivider),
                ),
                child: Column(
                  children: _sugerencias
                      .map(
                        (m) => ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: _kColor.withValues(alpha: 0.2),
                            child: Text(
                              (m['nombre'] as String)[0],
                              style: const TextStyle(
                                color: _kColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            m['nombre'] as String,
                            style: const TextStyle(color: kWhite, fontSize: 13),
                          ),
                          onTap: () => setState(() {
                            _miembroSel = m;
                            _busquedaCtrl.text = m['nombre'] as String;
                            _sugerencias = [];
                          }),
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 16),

            // Monto + Fecha
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('MONTO (Bs.)'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _montoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(color: kWhite, fontSize: 13),
                        decoration: _decoInput(
                          hint: '0.00',
                          icono: Icons.monetization_on_outlined,
                          colorFoco: _kColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('FECHA'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fechaCtrl,
                        style: const TextStyle(color: kWhite, fontSize: 13),
                        decoration: _decoInput(
                          hint: 'AAAA-MM-DD',
                          icono: Icons.calendar_today_outlined,
                          colorFoco: _kColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Observación
            TextField(
              controller: _obsCtrl,
              style: const TextStyle(color: kWhite, fontSize: 13),
              decoration: _decoInput(
                hint: 'Observación (opcional)',
                icono: Icons.notes,
                colorFoco: _kColor,
                label: 'Observación (opcional)',
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              _ErrorBox(_error!),
            ],
            const SizedBox(height: 20),
            _BotonesDialog(
              guardando: _guardando,
              colorConfirm: _kColor,
              textoConfirm: _esEdicion ? 'Guardar cambios' : 'Registrar',
              onGuardar: _guardar,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  FORMULARIO OFRENDA
// ══════════════════════════════════════════════════════
class _FormOfrenda extends StatefulWidget {
  const _FormOfrenda();
  @override
  State<_FormOfrenda> createState() => _FormOfrendaState();
}

class _FormOfrendaState extends State<_FormOfrenda> {
  final _montoCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _tipo = 'general';
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fechaCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _fechaCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final monto = double.tryParse(_montoCtrl.text.trim());
    if (monto == null || monto <= 0) {
      setState(() => _error = 'Ingresa un monto válido.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await _sb.from('ofrendas').insert({
        'tipo': _tipo,
        'monto': monto,
        'fecha': _fechaCtrl.text.trim(),
        'descripcion': _descCtrl.text.trim(),
      });
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
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CabeceraDialog(
              icono: Icons.volunteer_activism,
              color: kGold,
              titulo: 'Registrar Ofrenda',
            ),
            const SizedBox(height: 6),
            const Text(
              'La ofrenda se registra como ingreso de la iglesia.',
              style: TextStyle(color: kGrey, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Tipo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kDivider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _tipo,
                  isExpanded: true,
                  dropdownColor: kBgCard,
                  style: const TextStyle(color: kWhite, fontSize: 14),
                  onChanged: (v) => setState(() => _tipo = v!),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(
                      value: 'misionera',
                      child: Text('Misionera'),
                    ),
                    DropdownMenuItem(
                      value: 'construccion',
                      child: Text('Construcción'),
                    ),
                    DropdownMenuItem(
                      value: 'especial',
                      child: Text('Especial'),
                    ),
                    DropdownMenuItem(value: 'otro', child: Text('Otro')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _montoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: kWhite, fontSize: 14),
              decoration: _decoInput(
                hint: '0.00',
                label: 'Monto (Bs.)',
                icono: Icons.monetization_on_outlined,
                colorFoco: kGold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fechaCtrl,
              style: const TextStyle(color: kWhite, fontSize: 14),
              decoration: _decoInput(
                hint: 'AAAA-MM-DD',
                label: 'Fecha',
                icono: Icons.calendar_today_outlined,
                colorFoco: kGold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              style: const TextStyle(color: kWhite, fontSize: 14),
              decoration: _decoInput(
                hint: 'Descripción',
                label: 'Descripción (opcional)',
                icono: Icons.notes,
                colorFoco: kGold,
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              _ErrorBox(_error!),
            ],
            const SizedBox(height: 20),
            _BotonesDialog(
              guardando: _guardando,
              colorConfirm: kGold,
              textoConfirm: 'Registrar',
              onGuardar: _guardar,
              textoColorConfirm: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  WIDGETS AUXILIARES DE FORMULARIOS
// ══════════════════════════════════════════════════════

class _CabeceraDialog extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  const _CabeceraDialog({
    required this.icono,
    required this.color,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icono, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          titulo,
          style: const TextStyle(
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
  );
}

class _Label extends StatelessWidget {
  final String texto;
  const _Label(this.texto);
  @override
  Widget build(BuildContext context) => Text(
    texto,
    style: const TextStyle(color: kGrey, fontSize: 11, letterSpacing: 2),
  );
}

class _ErrorBox extends StatelessWidget {
  final String mensaje;
  const _ErrorBox(this.mensaje);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: kDanger.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: kDanger.withValues(alpha: 0.3)),
    ),
    child: Text(mensaje, style: const TextStyle(color: kDanger, fontSize: 12)),
  );
}

class _BotonesDialog extends StatelessWidget {
  final bool guardando;
  final Color colorConfirm;
  final Color textoColorConfirm;
  final String textoConfirm;
  final VoidCallback onGuardar;
  const _BotonesDialog({
    required this.guardando,
    required this.colorConfirm,
    required this.textoConfirm,
    required this.onGuardar,
    this.textoColorConfirm = Colors.white,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: kGrey,
          side: const BorderSide(color: kDivider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Cancelar'),
      ),
      const SizedBox(width: 12),
      ElevatedButton(
        onPressed: guardando ? null : onGuardar,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorConfirm,
          foregroundColor: textoColorConfirm,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: guardando
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: textoColorConfirm,
                  strokeWidth: 2,
                ),
              )
            : Text(
                textoConfirm,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
      ),
    ],
  );
}

// ══════════════════════════════════════════════════════
//  DIALOG CONFIRMAR ELIMINACIÓN
// ══════════════════════════════════════════════════════
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

// ── Helper decoración de inputs ───────────────────────
InputDecoration _decoInput({
  required String hint,
  required IconData icono,
  required Color colorFoco,
  String? label,
  Widget? sufijo,
}) => InputDecoration(
  hintText: hint,
  labelText: label,
  hintStyle: const TextStyle(color: kGrey, fontSize: 12),
  labelStyle: const TextStyle(color: kGrey, fontSize: 12),
  prefixIcon: Icon(icono, color: kGrey, size: 18),
  suffixIcon: sufijo,
  filled: true,
  fillColor: kBgCard,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    borderSide: BorderSide(color: colorFoco, width: 2),
  ),
);
