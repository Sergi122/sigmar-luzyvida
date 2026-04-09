import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/session.dart';
import '../../../../shared/widgets/dashboard_shell.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFFBA7517);

class PastorCursosScreen extends StatefulWidget {
  const PastorCursosScreen({super.key});
  @override
  State<PastorCursosScreen> createState() => _PastorCursosScreenState();
}

class _PastorCursosScreenState extends State<PastorCursosScreen> {
  List<Map<String, dynamic>> _cursos = [];
  List<Map<String, dynamic>> _filtrados = [];
  bool _cargando = true;
  String _busqueda = '';
  final int _menuActivo = 2;

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
          .from('cursos')
          .select(
            'id, nombre, aula, horas, dia_semana, hora, estado, miembros!cursos_id_guia_fkey(nombre)',
          )
          .order('nombre');
      setState(() {
        _cursos = List<Map<String, dynamic>>.from(data);
        _filtrar();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _msg('Error: $e', error: true);
    }
  }

  void _filtrar() {
    _filtrados = _cursos.where((c) {
      final nombre = (c['nombre'] ?? '').toString().toLowerCase();
      return _busqueda.isEmpty || nombre.contains(_busqueda.toLowerCase());
    }).toList();
  }

  void _msg(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: error ? kDanger : kSuccess),
    );
  }

  void _verInscritos(Map<String, dynamic> c) {
    showDialog(
      context: context,
      builder: (_) => _DialogInscritos(curso: c),
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
                      Icons.school_outlined,
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
                          'Cursos de la Iglesia',
                          style: TextStyle(
                            color: kWhite,
                            fontSize: movil ? 18 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total: ${_cursos.length} cursos',
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
                  hintText: 'Buscar curso...',
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
                'Mostrando ${_filtrados.length} de ${_cursos.length}',
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
                      'No se encontraron cursos',
                      style: TextStyle(color: kGrey, fontSize: 16),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filtrados.length,
                  itemBuilder: (_, i) => _CardCurso(
                    curso: _filtrados[i],
                    onVerInscritos: () => _verInscritos(_filtrados[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardCurso extends StatelessWidget {
  final Map<String, dynamic> curso;
  final VoidCallback onVerInscritos;
  const _CardCurso({required this.curso, required this.onVerInscritos});

  @override
  Widget build(BuildContext context) {
    final guia = curso['miembros'] as Map<String, dynamic>?;
    final estado = (curso['estado'] ?? 'activo').toString();
    final estadoColor = estado == 'activo' ? kSuccess : kDanger;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDivider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_outlined, color: _kColor, size: 20),
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
                        curso['nombre'] ?? '',
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
                Row(
                  children: [
                    const Icon(Icons.person, color: kGrey, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        guia?['nombre'] ?? 'Sin guía',
                        style: const TextStyle(color: kGrey, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.room, color: kGrey, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      curso['aula'] ?? '-',
                      style: const TextStyle(color: kGrey, fontSize: 12),
                    ),
                  ],
                ),
                if (curso['dia_semana'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: kGrey, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '${curso['dia_semana']}  ${curso['hora'] ?? ''}',
                          style: const TextStyle(color: kGrey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onVerInscritos,
                    icon: const Icon(Icons.people, size: 15),
                    label: const Text(
                      'Inscritos',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: _kColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogInscritos extends StatefulWidget {
  final Map<String, dynamic> curso;
  const _DialogInscritos({required this.curso});
  @override
  State<_DialogInscritos> createState() => _DialogInscritosState();
}

class _DialogInscritosState extends State<_DialogInscritos> {
  List<Map<String, dynamic>> _inscritos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await _sb
          .from('inscripciones')
          .select('estado, fecha_inicio, miembros(nombre, carnet)')
          .eq('id_curso', widget.curso['id'] as int)
          .order('estado');
      setState(() {
        _inscritos = List<Map<String, dynamic>>.from(data);
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Expanded(
                  child: Text(
                    widget.curso['nombre'] ?? '',
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: kGrey),
                ),
              ],
            ),
            Text(
              '${_inscritos.length} inscrito(s)',
              style: const TextStyle(color: kGrey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 1, color: kDivider),
            const SizedBox(height: 12),
            Flexible(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: _kColor),
                    )
                  : _inscritos.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin inscritos',
                        style: TextStyle(color: kGrey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _inscritos.length,
                      itemBuilder: (_, i) {
                        final m =
                            _inscritos[i]['miembros'] as Map<String, dynamic>?;
                        final estado = (_inscritos[i]['estado'] ?? 'activo')
                            .toString();
                        final color = estado == 'completado'
                            ? kSuccess
                            : estado == 'retirado'
                            ? kDanger
                            : _kColor;
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m?['nombre'] ?? '',
                                      style: const TextStyle(
                                        color: kWhite,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      m?['carnet'] ?? '-',
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
