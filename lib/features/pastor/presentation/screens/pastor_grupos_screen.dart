import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/session.dart';
import '../../../../shared/widgets/dashboard_shell.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFFBA7517);

class PastorGruposScreen extends StatefulWidget {
  const PastorGruposScreen({super.key});
  @override
  State<PastorGruposScreen> createState() => _PastorGruposScreenState();
}

class _PastorGruposScreenState extends State<PastorGruposScreen> {
  List<Map<String, dynamic>> _grupos = [];
  List<Map<String, dynamic>> _filtrados = [];
  bool _cargando = true;
  String _busqueda = '';
  int _menuActivo = 1;

  final _menuItems = [
    MenuItemData('Miembros', Icons.people_outline),
    MenuItemData('Grupos', Icons.group_outlined),
    MenuItemData('Cursos', Icons.school_outlined),
    MenuItemData('Asistencia', Icons.calendar_today_outlined),
    MenuItemData('Aportes', Icons.attach_money_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final data = await _sb
          .from('grupos')
          .select(
            'id, nombre, lugar, dia_semana, hora, estado, miembros!grupos_id_lider_fkey(nombre)',
          )
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
      final nombre = (g['nombre'] ?? '').toString().toLowerCase();
      return _busqueda.isEmpty || nombre.contains(_busqueda.toLowerCase());
    }).toList();
  }

  void _msg(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: error ? kDanger : kSuccess),
    );
  }

  void _verMiembros(Map<String, dynamic> g) {
    showDialog(
      context: context,
      builder: (_) => _DialogMiembrosGrupo(grupo: g),
    );
  }

  void _navegar(int idx) {
    final rutas = [
      '/pastor/miembros',
      '/pastor/grupos',
      '/pastor/cursos',
      '/pastor/asistencia',
      '/pastor/aportes',
    ];
    if (idx != _menuActivo && idx < rutas.length) {
      Navigator.pushReplacementNamed(context, rutas[idx]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.of(context).size.width < 600;
    return DashboardShell(
      nombreUsuario: AppSession.nombre,
      rol: 'Pastor',
      menuItems: _menuItems,
      indiceActivo: _menuActivo,
      onMenuTap: _navegar,
      body: RefreshIndicator(
        color: _kColor,
        onRefresh: _cargar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(movil ? 14 : 28),
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
                      Icons.group_outlined,
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
                          'Grupos de la Iglesia',
                          style: TextStyle(
                            color: kWhite,
                            fontSize: movil ? 18 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total: ${_grupos.length} grupos',
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
              TextField(
                onChanged: (v) => setState(() {
                  _busqueda = v;
                  _filtrar();
                }),
                style: const TextStyle(color: kWhite, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar grupo...',
                  hintStyle: const TextStyle(color: kGrey),
                  prefixIcon: const Icon(Icons.search, color: kGrey),
                  filled: true,
                  fillColor: kBgCard,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
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
                    borderSide: const BorderSide(color: _kColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mostrando ${_filtrados.length} de ${_grupos.length}',
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
                      'No se encontraron grupos',
                      style: TextStyle(color: kGrey, fontSize: 16),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filtrados.length,
                  itemBuilder: (_, i) => _CardGrupo(
                    grupo: _filtrados[i],
                    onTap: () => _verMiembros(_filtrados[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardGrupo extends StatelessWidget {
  final Map<String, dynamic> grupo;
  final VoidCallback onTap;
  const _CardGrupo({required this.grupo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lider = grupo['miembros'] as Map<String, dynamic>?;
    final dia = grupo['dia_semana'] ?? '';
    final hora = grupo['hora'] ?? '';
    final estado = (grupo['estado'] ?? 'activo').toString();
    final estadoColor = estado == 'activo' ? kSuccess : kDanger;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kDivider),
        ),
        child: Row(
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          grupo['nombre'] ?? '',
                          style: const TextStyle(
                            color: kWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: estadoColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: estadoColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          estado.toUpperCase(),
                          style: TextStyle(
                            color: estadoColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (lider != null)
                    Row(
                      children: [
                        const Icon(Icons.person, color: kGrey, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lider['nombre'] ?? '-',
                            style: const TextStyle(color: kGrey, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: kGrey, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          grupo['lugar'] ?? '-',
                          style: const TextStyle(color: kGrey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (dia.isNotEmpty || hora.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: kGrey, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '$dia  $hora',
                          style: const TextStyle(color: kGrey, fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: kGrey),
          ],
        ),
      ),
    );
  }
}

class _DialogMiembrosGrupo extends StatefulWidget {
  final Map<String, dynamic> grupo;
  const _DialogMiembrosGrupo({required this.grupo});
  @override
  State<_DialogMiembrosGrupo> createState() => _DialogMiembrosGrupoState();
}

class _DialogMiembrosGrupoState extends State<_DialogMiembrosGrupo> {
  List<Map<String, dynamic>> _miembros = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await _sb
          .from('grupo_miembros')
          .select('miembros(id, nombre, carnet, estado)')
          .eq('id_grupo', widget.grupo['id'] as int)
          .order('miembros(nombre)');
      setState(() {
        _miembros = List<Map<String, dynamic>>.from(data);
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lider = widget.grupo['miembros'] as Map<String, dynamic>?;
    final ancho = MediaQuery.of(context).size.width;
    return Dialog(
      backgroundColor: kBgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: ancho < 600 ? 16 : 80,
        vertical: 24,
      ),
      child: Container(
        width: ancho < 600 ? double.infinity : 480,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _kColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.group, color: _kColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.grupo['nombre'] ?? '',
                        style: const TextStyle(
                          color: kWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Líder: ${lider?['nombre'] ?? 'Sin líder'}',
                        style: const TextStyle(color: kGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: kGrey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 1, color: kDivider),
            const SizedBox(height: 12),
            Text(
              'Miembros (${_miembros.length})',
              style: const TextStyle(
                color: kWhite,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: _kColor),
                    )
                  : _miembros.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin miembros en este grupo',
                        style: TextStyle(color: kGrey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _miembros.length,
                      itemBuilder: (_, i) {
                        final m =
                            _miembros[i]['miembros'] as Map<String, dynamic>?;
                        final estado = (m?['estado'] ?? 'activo').toString();
                        final color = estado == 'activo' ? kSuccess : kDanger;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kBgMid,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kDivider),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _kColor.withValues(alpha: 0.15),
                                ),
                                child: Center(
                                  child: Text(
                                    (m?['nombre'] ?? 'U')
                                        .toString()[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: _kColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  m?['nombre'] ?? '',
                                  style: const TextStyle(
                                    color: kWhite,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
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
            ),
            const SizedBox(height: 14),
            SizedBox(
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
          ],
        ),
      ),
    );
  }
}
