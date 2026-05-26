import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_layout.dart';
import '../../../../shared/widgets/dashboard_shell.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFFBA7517);

class PastorMiembrosScreen extends StatefulWidget {
  const PastorMiembrosScreen({super.key});
  @override
  State<PastorMiembrosScreen> createState() => _PastorMiembrosScreenState();
}

class _PastorMiembrosScreenState extends State<PastorMiembrosScreen> {
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
      final data = await _sb
          .from('miembros')
          .select(
            'id, nombre, carnet, telefono, direccion, estado, bautizado, asistio_encuentro, fecha_conversion',
          )
          .order('nombre');
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
      final nombre = (m['nombre'] ?? '').toString().toLowerCase();
      final carnet = (m['carnet'] ?? '').toString().toLowerCase();
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

  void _verDetalle(Map<String, dynamic> m) {
    showDialog(
      context: context,
      builder: (_) => _DialogDetalleMiembro(miembro: m),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.of(context).size.width < kMobileBreakpoint;
    return DashboardPage(
      rutaActual: '/pastor/miembros',
      conScroll: false,
      child: RefreshIndicator(
        color: _kColor,
        onRefresh: _cargar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(movil ? kMobilePadding : kDesktopPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: movil ? 42 : 52,
                    height: movil ? 42 : 52,
                    decoration: BoxDecoration(
                      color: _kColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.people_outline,
                      color: _kColor,
                      size: movil ? 22 : 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Miembros de la Iglesia',
                          style: TextStyle(
                            color: kWhite,
                            fontSize: movil ? 18 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total: ${_miembros.length} miembros registrados',
                          style: const TextStyle(color: kGrey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(width: 50, height: 3, color: _kColor),
              const SizedBox(height: 20),
              // Búsqueda y filtro
              if (movil) ...[
                TextField(
                  onChanged: (v) => setState(() {
                    _busqueda = v;
                    _filtrar();
                  }),
                  style: const TextStyle(color: kWhite, fontSize: 16),
                  decoration: _inputDecoration('Buscar por nombre o carnet...'),
                ),
                const SizedBox(height: 10),
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
                      isExpanded: true,
                      dropdownColor: kBgCard,
                      style: const TextStyle(color: kWhite, fontSize: 13),
                      onChanged: (v) => setState(() {
                        _filtroEstado = v ?? 'todos';
                        _filtrar();
                      }),
                      items: _dropdownItems(),
                    ),
                  ),
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() {
                          _busqueda = v;
                          _filtrar();
                        }),
                        style: const TextStyle(color: kWhite, fontSize: 16),
                        decoration: _inputDecoration(
                          'Buscar por nombre o carnet...',
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
                          onChanged: (v) => setState(() {
                            _filtroEstado = v ?? 'todos';
                            _filtrar();
                          }),
                          items: _dropdownItems(),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Text(
                'Mostrando ${_filtrados.length} de ${_miembros.length}',
                style: const TextStyle(color: kGrey, fontSize: 12),
              ),
              const SizedBox(height: 12),
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
                      'No se encontraron miembros',
                      style: TextStyle(color: kGrey, fontSize: 16),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filtrados.length,
                  itemBuilder: (_, i) => _CardMiembro(
                    miembro: _filtrados[i],
                    onTap: () => _verDetalle(_filtrados[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kGrey, fontSize: 16),
      prefixIcon: const Icon(Icons.search, color: kGrey, size: 22),
      filled: true,
      fillColor: kBgCard,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
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
        borderSide: const BorderSide(color: _kColor),
      ),
    );
  }

  List<DropdownMenuItem<String>> _dropdownItems() => const [
    DropdownMenuItem(value: 'todos', child: Text('Todos')),
    DropdownMenuItem(value: 'activo', child: Text('Activos')),
    DropdownMenuItem(value: 'inactivo', child: Text('Inactivos')),
    DropdownMenuItem(value: 'visita', child: Text('Visitas')),
  ];
}

class _CardMiembro extends StatelessWidget {
  final Map<String, dynamic> miembro;
  final VoidCallback onTap;
  const _CardMiembro({required this.miembro, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final estado = (miembro['estado'] ?? 'activo').toString();
    final estadoColor = estado == 'activo'
        ? kSuccess
        : estado == 'visita'
        ? _kColor
        : kDanger;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kDivider),
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
                  (miembro['nombre'] ?? 'U').toString()[0].toUpperCase(),
                  style: const TextStyle(
                    color: _kColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
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
                    miembro['nombre'] ?? '',
                    style: const TextStyle(
                      color: kWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    miembro['carnet'] ?? 'Sin carnet',
                    style: const TextStyle(color: kGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: estadoColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                estado.toUpperCase(),
                style: TextStyle(
                  color: estadoColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: kGrey, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DialogDetalleMiembro extends StatelessWidget {
  final Map<String, dynamic> miembro;
  const _DialogDetalleMiembro({required this.miembro});

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    return Dialog(
      backgroundColor: kBgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: ancho < 600 ? 16 : 100,
        vertical: 24,
      ),
      child: Container(
        width: ancho < 600 ? double.infinity : 550,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kColor.withValues(alpha: 0.15),
                      border: Border.all(color: _kColor.withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Text(
                        (miembro['nombre'] ?? 'U').toString()[0].toUpperCase(),
                        style: const TextStyle(
                          color: _kColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          miembro['nombre'] ?? '',
                          style: const TextStyle(
                            color: kWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Miembro de la iglesia',
                          style: TextStyle(color: kGrey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: kGrey, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(width: double.infinity, height: 1, color: kDivider),
              const SizedBox(height: 20),
              _Dato(
                icon: Icons.badge,
                label: 'Carnet',
                valor: miembro['carnet'] ?? '-',
              ),
              _Dato(
                icon: Icons.phone,
                label: 'Teléfono',
                valor: miembro['telefono'] ?? '-',
              ),
              _Dato(
                icon: Icons.home,
                label: 'Dirección',
                valor: miembro['direccion'] ?? '-',
              ),
              _Dato(
                icon: Icons.cake,
                label: 'Fecha Nac.',
                valor: miembro['fecha_nacimiento'] ?? '-',
              ),
              _Dato(
                icon: Icons.water_drop,
                label: 'Bautizado',
                valor: (miembro['bautizado'] == true) ? 'Sí' : 'No',
              ),
              _Dato(
                icon: Icons.church,
                label: 'Encuentro',
                valor: (miembro['asistio_encuentro'] == true) ? 'Sí' : 'No',
              ),
              _Dato(
                icon: Icons.verified,
                label: 'Estado',
                valor: (miembro['estado'] ?? 'activo').toString().toUpperCase(),
                esEstado: true,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kGrey,
                    side: const BorderSide(color: kDivider),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icon;
  final String label, valor;
  final bool esEstado;
  const _Dato({
    required this.icon,
    required this.label,
    required this.valor,
    this.esEstado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _kColor, size: 22),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(color: kGrey, fontSize: 15),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(color: kWhite, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
