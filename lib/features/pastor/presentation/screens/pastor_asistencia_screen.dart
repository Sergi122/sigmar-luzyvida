import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/session.dart';
import '../../../../shared/widgets/dashboard_shell.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFFBA7517);

class PastorAsistenciaScreen extends StatefulWidget {
  const PastorAsistenciaScreen({super.key});
  @override
  State<PastorAsistenciaScreen> createState() => _PastorAsistenciaScreenState();
}

class _PastorAsistenciaScreenState extends State<PastorAsistenciaScreen> {
  List<Map<String, dynamic>> _grupos = [];
  List<Map<String, dynamic>> _asistencias = [];
  int? _grupoSeleccionado;
  bool _cargando = true;
  bool _cargandoAsistencia = false;
  final int _menuActivo = 3;

  // Filtro por fecha
  DateTime? _fechaSeleccionada;
  List<Map<String, dynamic>> _asistenciasFiltradas = [];

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
    _cargarGrupos();
  }

  Future<void> _cargarGrupos() async {
    setState(() => _cargando = true);
    try {
      final data = await _sb
          .from('grupos')
          .select('id, nombre')
          .order('nombre');
      setState(() {
        _grupos = List<Map<String, dynamic>>.from(data);
        if (_grupos.isNotEmpty) {
          _grupoSeleccionado = _grupos[0]['id'] as int;
          _cargarAsistencia();
        }
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _cargarAsistencia() async {
    if (_grupoSeleccionado == null) return;
    setState(() => _cargandoAsistencia = true);
    try {
      final data = await _sb
          .from('asistencia')
          .select('id, fecha, presente, miembros(nombre)')
          .eq('id_grupo', _grupoSeleccionado!)
          .order('fecha', ascending: false)
          .limit(200);
      setState(() {
        _asistencias = List<Map<String, dynamic>>.from(data);
        _aplicarFiltroFecha();
        _cargandoAsistencia = false;
      });
    } catch (e) {
      setState(() => _cargandoAsistencia = false);
    }
  }

  void _aplicarFiltroFecha() {
    if (_fechaSeleccionada == null) {
      _asistenciasFiltradas = List.from(_asistencias);
    } else {
      final fechaStr = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada!);
      _asistenciasFiltradas = _asistencias.where((a) {
        final f = (a['fecha'] ?? '').toString();
        return f.startsWith(fechaStr);
      }).toList();
    }
  }

  Map<String, int> get _stats {
    final lista = _asistenciasFiltradas;
    final presentes = lista.where((a) => a['presente'] == true).length;
    final ausentes = lista.where((a) => a['presente'] == false).length;
    return {
      'presentes': presentes,
      'ausentes': ausentes,
      'total': lista.length,
    };
  }

  // Stats globales sin filtro de fecha (para el gráfico)
  Map<String, int> get _statsGlobales {
    final presentes = _asistencias.where((a) => a['presente'] == true).length;
    final ausentes = _asistencias.where((a) => a['presente'] == false).length;
    return {
      'presentes': presentes,
      'ausentes': ausentes,
      'total': _asistencias.length,
    };
  }

  /// Retorna lista de fechas únicas disponibles para ese grupo
  List<DateTime> get _fechasDisponibles {
    final set = <String>{};
    for (final a in _asistencias) {
      final f = (a['fecha'] ?? '').toString();
      if (f.length >= 10) set.add(f.substring(0, 10));
    }
    final lista = set.map((s) => DateTime.parse(s)).toList();
    lista.sort((a, b) => b.compareTo(a)); // más reciente primero
    return lista;
  }

  Future<void> _seleccionarFecha() async {
    final fechas = _fechasDisponibles;
    if (fechas.isEmpty) return;

    final ancho = MediaQuery.of(context).size.width;

    // En móvil, mostrar un BottomSheet con lista de fechas
    // En escritorio, mostrar un Dialog
    if (ancho < 600) {
      await showModalBottomSheet(
        context: context,
        backgroundColor: kBgCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => _FechasBottomSheet(
          fechas: fechas,
          seleccionada: _fechaSeleccionada,
          onSeleccionar: (f) {
            setState(() {
              _fechaSeleccionada = f;
              _aplicarFiltroFecha();
            });
            Navigator.pop(ctx);
          },
          onLimpiar: () {
            setState(() {
              _fechaSeleccionada = null;
              _aplicarFiltroFecha();
            });
            Navigator.pop(ctx);
          },
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (ctx) => _FechasDialog(
          fechas: fechas,
          seleccionada: _fechaSeleccionada,
          onSeleccionar: (f) {
            setState(() {
              _fechaSeleccionada = f;
              _aplicarFiltroFecha();
            });
            Navigator.pop(ctx);
          },
          onLimpiar: () {
            setState(() {
              _fechaSeleccionada = null;
              _aplicarFiltroFecha();
            });
            Navigator.pop(ctx);
          },
        ),
      );
    }
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

  Future<void> _exportarPDF() async {
    final grupo = _grupos.firstWhere((g) => g['id'] == _grupoSeleccionado);
    final stats = _stats;
    final lista = _asistenciasFiltradas;
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Reporte de Asistencia',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.amber800,
              ),
            ),
            pw.Text(
              'Grupo: ${grupo['nombre']}',
              style: const pw.TextStyle(fontSize: 13),
            ),
            if (_fechaSeleccionada != null)
              pw.Text(
                'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            pw.Text(
              'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
            pw.SizedBox(height: 16),
          ],
        ),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Text(
                      '${stats['total']}',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                      ),
                    ),
                    pw.Text('Total'),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text(
                      '${stats['presentes']}',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                    pw.Text('Presentes'),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text(
                      '${stats['ausentes']}',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red,
                      ),
                    ),
                    pw.Text('Ausentes'),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.amber50),
                children: ['Miembro', 'Fecha', 'Estado']
                    .map(
                      (h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          h,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    )
                    .toList(),
              ),
              ...lista.map(
                (a) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        (a['miembros'] as Map?)?['nombre'] ?? '-',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        (a['fecha'] ?? '').toString(),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        a['presente'] == true ? 'Presente' : 'Ausente',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: a['presente'] == true
                              ? PdfColors.green800
                              : PdfColors.red800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (f) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.of(context).size.width < 600;
    final stats = _stats;
    final statsGlobales = _statsGlobales;

    return DashboardShell(
      nombreUsuario: AppSession.nombre,
      rol: 'Pastor',
      menuItems: _menuItems,
      indiceActivo: _menuActivo,
      onMenuTap: _navegar,
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: _kColor))
          : RefreshIndicator(
              color: _kColor,
              onRefresh: _cargarGrupos,
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
                            Icons.calendar_today_outlined,
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
                                'Reporte de Asistencia',
                                style: TextStyle(
                                  color: kWhite,
                                  fontSize: movil ? 18 : 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Resumen por grupo',
                                style: TextStyle(color: kGrey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _grupoSeleccionado != null
                              ? _exportarPDF
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kColor,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: movil ? 10 : 16,
                              vertical: movil ? 8 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: Text(
                            movil ? 'PDF' : 'PDF',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(width: 50, height: 3, color: _kColor),
                    const SizedBox(height: 20),

                    // Selector de grupo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kDivider),
                      ),
                      child: DropdownButton<int>(
                        value: _grupoSeleccionado,
                        dropdownColor: kBgCard,
                        underline: const SizedBox(),
                        isExpanded: true,
                        style: const TextStyle(color: kWhite, fontSize: 14),
                        hint: const Text(
                          'Seleccionar grupo',
                          style: TextStyle(color: kGrey),
                        ),
                        items: _grupos
                            .map(
                              (g) => DropdownMenuItem<int>(
                                value: g['id'] as int,
                                child: Text(g['nombre']),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _grupoSeleccionado = v;
                            _fechaSeleccionada = null;
                          });
                          _cargarAsistencia();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Selector de fecha
                    GestureDetector(
                      onTap: _cargandoAsistencia ? null : _seleccionarFecha,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: kBgCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _fechaSeleccionada != null
                                ? _kColor
                                : kDivider,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event,
                              color: _fechaSeleccionada != null
                                  ? _kColor
                                  : kGrey,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _fechaSeleccionada != null
                                    ? 'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)}'
                                    : 'Filtrar por día (todos los días)',
                                style: TextStyle(
                                  color: _fechaSeleccionada != null
                                      ? kWhite
                                      : kGrey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (_fechaSeleccionada != null)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _fechaSeleccionada = null;
                                    _aplicarFiltroFecha();
                                  });
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: kGrey,
                                  size: 18,
                                ),
                              )
                            else
                              const Icon(Icons.arrow_drop_down, color: kGrey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_cargandoAsistencia)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: _kColor),
                        ),
                      )
                    else ...[
                      // Stats cards
                      Row(
                        children: [
                          _StatCard(
                            titulo: 'Total',
                            valor: stats['total']!,
                            icon: Icons.assignment,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            titulo: 'Presentes',
                            valor: stats['presentes']!,
                            icon: Icons.check_circle,
                            color: kSuccess,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            titulo: 'Ausentes',
                            valor: stats['ausentes']!,
                            icon: Icons.cancel,
                            color: kDanger,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Gráfica - solo cuando no hay filtro de fecha activo
                      if (_fechaSeleccionada == null &&
                          statsGlobales['total']! > 0)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kBgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kDivider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Distribución General',
                                style: TextStyle(
                                  color: kWhite,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 160,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: PieChart(
                                        PieChartData(
                                          sectionsSpace: 2,
                                          centerSpaceRadius: 32,
                                          sections: [
                                            PieChartSectionData(
                                              value: statsGlobales['presentes']!
                                                  .toDouble(),
                                              title:
                                                  'P: ${statsGlobales['presentes']}',
                                              color: kSuccess,
                                              radius: 50,
                                              titleStyle: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            PieChartSectionData(
                                              value: statsGlobales['ausentes']!
                                                  .toDouble(),
                                              title:
                                                  'A: ${statsGlobales['ausentes']}',
                                              color: kDanger,
                                              radius: 50,
                                              titleStyle: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _Leyenda(
                                          color: kSuccess,
                                          texto:
                                              'Presentes: ${statsGlobales['presentes']}',
                                        ),
                                        const SizedBox(height: 10),
                                        _Leyenda(
                                          color: kDanger,
                                          texto:
                                              'Ausentes: ${statsGlobales['ausentes']}',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Lista de registros filtrados
                      if (_asistenciasFiltradas.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              _fechaSeleccionada != null
                                  ? 'Registros del ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)}'
                                  : 'Últimos registros',
                              style: const TextStyle(
                                color: kWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${_asistenciasFiltradas.length})',
                              style: const TextStyle(
                                color: kGrey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _asistenciasFiltradas.length > 30
                              ? 30
                              : _asistenciasFiltradas.length,
                          itemBuilder: (_, i) {
                            final a = _asistenciasFiltradas[i];
                            final nombre =
                                (a['miembros'] as Map?)?['nombre'] ?? '-';
                            final presente = a['presente'] == true;
                            final fecha = (a['fecha'] ?? '').toString();
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
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: presente ? kSuccess : kDanger,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      nombre,
                                      style: const TextStyle(
                                        color: kWhite,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    fecha.length >= 10
                                        ? fecha.substring(0, 10)
                                        : fecha,
                                    style: const TextStyle(
                                      color: kGrey,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: presente
                                          ? kSuccess.withValues(alpha: 0.15)
                                          : kDanger.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      presente ? 'P' : 'A',
                                      style: TextStyle(
                                        color: presente ? kSuccess : kDanger,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String texto;
  const _Leyenda({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(color: kGrey, fontSize: 12)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String titulo;
  final int valor;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.titulo,
    required this.valor,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kDivider),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$valor',
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    titulo,
                    style: const TextStyle(color: kGrey, fontSize: 10),
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

/// BottomSheet de fechas (móvil)
class _FechasBottomSheet extends StatelessWidget {
  final List<DateTime> fechas;
  final DateTime? seleccionada;
  final ValueChanged<DateTime> onSeleccionar;
  final VoidCallback onLimpiar;

  const _FechasBottomSheet({
    required this.fechas,
    required this.seleccionada,
    required this.onSeleccionar,
    required this.onLimpiar,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE, dd \'de\' MMMM yyyy', 'es');
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kDivider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Seleccionar día',
                  style: TextStyle(
                    color: kWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onLimpiar,
                  child: const Text(
                    'Ver todos',
                    style: TextStyle(color: _kColor),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: kDivider),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: fechas.length,
              itemBuilder: (_, i) {
                final f = fechas[i];
                final activa =
                    seleccionada != null &&
                    DateFormat('yyyy-MM-dd').format(seleccionada!) ==
                        DateFormat('yyyy-MM-dd').format(f);
                return ListTile(
                  onTap: () => onSeleccionar(f),
                  leading: Icon(
                    Icons.calendar_today,
                    color: activa ? _kColor : kGrey,
                    size: 18,
                  ),
                  title: Text(
                    _capitalizarPrimera(fmt.format(f)),
                    style: TextStyle(
                      color: activa ? _kColor : kWhite,
                      fontSize: 14,
                      fontWeight: activa ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: activa
                      ? const Icon(Icons.check, color: _kColor, size: 18)
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Dialog de fechas (escritorio)
class _FechasDialog extends StatelessWidget {
  final List<DateTime> fechas;
  final DateTime? seleccionada;
  final ValueChanged<DateTime> onSeleccionar;
  final VoidCallback onLimpiar;

  const _FechasDialog({
    required this.fechas,
    required this.seleccionada,
    required this.onSeleccionar,
    required this.onLimpiar,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE, dd \'de\' MMMM yyyy', 'es');
    return Dialog(
      backgroundColor: kBgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 380,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Seleccionar día',
                  style: TextStyle(
                    color: kWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onLimpiar,
                  child: const Text(
                    'Ver todos',
                    style: TextStyle(color: _kColor, fontSize: 12),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: kGrey, size: 20),
                ),
              ],
            ),
            const Divider(color: kDivider),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: fechas.length,
                itemBuilder: (_, i) {
                  final f = fechas[i];
                  final activa =
                      seleccionada != null &&
                      DateFormat('yyyy-MM-dd').format(seleccionada!) ==
                          DateFormat('yyyy-MM-dd').format(f);
                  return ListTile(
                    onTap: () => onSeleccionar(f),
                    leading: Icon(
                      Icons.calendar_today,
                      color: activa ? _kColor : kGrey,
                      size: 16,
                    ),
                    title: Text(
                      _capitalizarPrimera(fmt.format(f)),
                      style: TextStyle(
                        color: activa ? _kColor : kWhite,
                        fontSize: 13,
                        fontWeight: activa
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: activa
                        ? const Icon(Icons.check, color: _kColor, size: 16)
                        : null,
                    dense: true,
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

String _capitalizarPrimera(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
