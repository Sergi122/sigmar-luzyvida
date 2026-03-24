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
    return SigmarPage(
      rutaActual: '/admin/aportes',
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

            // Tabs
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
                  Tab(text: '🙏 OFRENDA'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Contenido del tab — sin Expanded, usa SizedBox con altura de pantalla
            SizedBox(
              height: MediaQuery.of(context).size.height - 280,
              child: TabBarView(
                controller: _tab,
                children: const [_TabDiezmos(), _TabOfrenda()],
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
      final diezmos = await _sb
          .from('aportes')
          .select('*, miembros(nombre)')
          .eq('tipo', 'diezmo')
          .order('fecha', ascending: false);
      final miembros = await _sb
          .from('miembros')
          .select('id, nombre')
          .order('nombre');
      setState(() {
        _diezmos = List<Map<String, dynamic>>.from(diezmos);
        _miembros = List<Map<String, dynamic>>.from(miembros);
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _msg('Error: $e', error: true);
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogConfirm(
        titulo: 'Eliminar diezmo',
        mensaje:
            '¿Eliminar el diezmo de ${(d['miembros'] as Map?)?['nombre'] ?? ''}?',
      ),
    );
    if (ok != true) return;
    await _sb.from('aportes').delete().eq('id', d['id']);
    _msg('Diezmo eliminado');
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final total = _diezmos.fold<int>(
      0,
      (s, d) => s + ((d['monto'] as int?) ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra superior
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _busqueda = v),
                style: const TextStyle(color: kWhite, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre del miembro...',
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
              onPressed: () => _abrirFormulario(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
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

        // Resumen total
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: _kColor,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'Total diezmos: Bs. $total',
                style: const TextStyle(
                  color: kWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${_filtrados.length} registros',
                style: const TextStyle(color: kGrey, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Lista — shrinkWrap dentro de scroll
        if (_cargando)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: _kColor),
            ),
          )
        else if (_filtrados.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
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
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kColor.withValues(alpha: 0.15),
                          border: Border.all(
                            color: _kColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            (nombre as String)[0].toUpperCase(),
                            style: const TextStyle(
                              color: _kColor,
                              fontWeight: FontWeight.bold,
                            ),
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
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Fecha: ${d['fecha'] ?? ''}',
                              style: const TextStyle(
                                color: kGrey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kSuccess.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: kSuccess.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Bs. ${d['monto']}',
                          style: const TextStyle(
                            color: kSuccess,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: _kColor,
                          size: 18,
                        ),
                        onPressed: () => _abrirFormulario(diezmo: d),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: kDanger,
                          size: 18,
                        ),
                        onPressed: () => _eliminar(d),
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
//  TAB OFRENDA
// ══════════════════════════════════════════════════════
class _TabOfrenda extends StatefulWidget {
  const _TabOfrenda();
  @override
  State<_TabOfrenda> createState() => _TabOfrendaState();
}

class _TabOfrendaState extends State<_TabOfrenda> {
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
          .from('aportes')
          .select()
          .eq('tipo', 'ofrenda')
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
    await _sb.from('aportes').delete().eq('id', o['id']);
    _msg('Ofrenda eliminada');
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final total = _filtrados.fold<int>(
      0,
      (s, o) => s + ((o['monto'] as int?) ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _filtrFecha = v),
                style: const TextStyle(color: kWhite, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Filtrar por fecha (ej: 2026-03)...',
                  hintStyle: const TextStyle(color: kGrey, fontSize: 12),
                  prefixIcon: const Icon(
                    Icons.calendar_today_outlined,
                    color: kGrey,
                    size: 16,
                  ),
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
              onPressed: _registrar,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
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

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kGold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kGold.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.church_outlined, color: kGold, size: 18),
              const SizedBox(width: 10),
              Text(
                'Total ofrendas: Bs. $total',
                style: const TextStyle(
                  color: kWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${_filtrados.length} registros',
                style: const TextStyle(color: kGrey, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_cargando)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: _kColor),
            ),
          )
        else if (_filtrados.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
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
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kGold.withValues(alpha: 0.15),
                          border: Border.all(
                            color: kGold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.volunteer_activism,
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
                              'Ofrenda Iglesia',
                              style: TextStyle(
                                color: kWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Fecha: ${o['fecha'] ?? ''}',
                              style: const TextStyle(
                                color: kGrey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: kGold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Bs. ${o['monto']}',
                          style: const TextStyle(
                            color: kGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: kDanger,
                          size: 18,
                        ),
                        onPressed: () => _eliminar(o),
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
  final _busquedaCtrl = TextEditingController();
  Map<String, dynamic>? _miembroSeleccionado;
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
      final idMiembro = widget.diezmo!['idMiembro'];
      try {
        _miembroSeleccionado = widget.miembros.firstWhere(
          (m) => m['id'] == idMiembro,
        );
        _busquedaCtrl.text = _miembroSeleccionado!['nombre'] ?? '';
      } catch (_) {}
    } else {
      _fechaCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    }
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _fechaCtrl.dispose();
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _buscarMiembro(String q) {
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
    if (_miembroSeleccionado == null) {
      setState(() => _error = 'Selecciona un miembro.');
      return;
    }
    if (_montoCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Ingresa el monto.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    final datos = {
      'idMiembro': _miembroSeleccionado!['id'],
      'tipo': 'diezmo',
      'monto': int.tryParse(_montoCtrl.text.trim()) ?? 0,
      'fecha': _fechaCtrl.text.trim(),
    };
    try {
      if (_esEdicion) {
        await _sb.from('aportes').update(datos).eq('id', widget.diezmo!['id']);
      } else {
        await _sb.from('aportes').insert(datos);
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
                    Icons.attach_money,
                    color: _kColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _esEdicion ? 'Editar Diezmo' : 'Registrar Diezmo',
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
            const SizedBox(height: 20),
            const Text(
              'MIEMBRO',
              style: TextStyle(color: kGrey, fontSize: 11, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _busquedaCtrl,
              onChanged: _buscarMiembro,
              style: const TextStyle(color: kWhite, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar miembro por nombre...',
                hintStyle: const TextStyle(color: kGrey, fontSize: 12),
                prefixIcon: const Icon(
                  Icons.person_search,
                  color: kGrey,
                  size: 18,
                ),
                suffixIcon: _miembroSeleccionado != null
                    ? const Icon(Icons.check_circle, color: kSuccess, size: 18)
                    : null,
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
                  borderSide: const BorderSide(color: _kColor, width: 2),
                ),
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
                              m['nombre'][0],
                              style: const TextStyle(
                                color: _kColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            m['nombre'],
                            style: const TextStyle(color: kWhite, fontSize: 13),
                          ),
                          onTap: () => setState(() {
                            _miembroSeleccionado = m;
                            _busquedaCtrl.text = m['nombre'];
                            _sugerencias = [];
                          }),
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MONTO (Bs.)',
                        style: TextStyle(
                          color: kGrey,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _montoCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: kWhite, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: const TextStyle(color: kGrey),
                          prefixIcon: const Icon(
                            Icons.monetization_on_outlined,
                            color: kGrey,
                            size: 16,
                          ),
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
                            borderSide: const BorderSide(
                              color: _kColor,
                              width: 2,
                            ),
                          ),
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
                      const Text(
                        'FECHA',
                        style: TextStyle(
                          color: kGrey,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fechaCtrl,
                        style: const TextStyle(color: kWhite, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'AAAA-MM-DD',
                          hintStyle: const TextStyle(color: kGrey),
                          prefixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            color: kGrey,
                            size: 16,
                          ),
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
                            borderSide: const BorderSide(
                              color: _kColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
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
                        style: const TextStyle(color: kDanger, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
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
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _esEdicion ? 'Guardar cambios' : 'Registrar',
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
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_montoCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Ingresa el monto.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await _sb.from('aportes').insert({
        'tipo': 'ofrenda',
        'monto': int.tryParse(_montoCtrl.text.trim()) ?? 0,
        'fecha': _fechaCtrl.text.trim(),
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
        width: 380,
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
                    Icons.volunteer_activism,
                    color: kGold,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Registrar Ofrenda',
                  style: TextStyle(
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
            const SizedBox(height: 8),
            const Text(
              'La ofrenda se registra como total de la iglesia.',
              style: TextStyle(color: kGrey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            const Text(
              'MONTO (Bs.)',
              style: TextStyle(color: kGrey, fontSize: 11, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: kWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(color: kGrey),
                prefixIcon: const Icon(
                  Icons.monetization_on_outlined,
                  color: kGrey,
                  size: 18,
                ),
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
            const SizedBox(height: 14),
            const Text(
              'FECHA',
              style: TextStyle(color: kGrey, fontSize: 11, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fechaCtrl,
              style: const TextStyle(color: kWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'AAAA-MM-DD',
                hintStyle: const TextStyle(color: kGrey),
                prefixIcon: const Icon(
                  Icons.calendar_today_outlined,
                  color: kGrey,
                  size: 16,
                ),
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
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kDanger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kDanger.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: kDanger, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 20),
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
                    backgroundColor: kGold,
                    foregroundColor: Colors.black,
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
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Registrar',
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
//  DIALOGO CONFIRMACION
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
