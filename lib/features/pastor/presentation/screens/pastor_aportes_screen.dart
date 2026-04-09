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

class PastorAportesScreen extends StatefulWidget {
  const PastorAportesScreen({super.key});
  @override
  State<PastorAportesScreen> createState() => _PastorAportesScreenState();
}

class _PastorAportesScreenState extends State<PastorAportesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _cargando = true;
  final int _menuActivo = 4;

  List<Map<String, dynamic>> _diezmos = [];
  List<Map<String, dynamic>> _ofrendas = [];
  double _totalDiezmos = 0;
  double _totalOfrendas = 0;
  Map<String, double> _diezmosPorMes = {};
  Map<String, double> _ofrendasPorMes = {};

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
    _tab = TabController(length: 2, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final diezmosData = await _sb
          .from('diezmos')
          .select('id, monto, fecha, observacion, miembros(nombre)')
          .order('fecha', ascending: false);

      final ofrendasData = await _sb
          .from('ofrendas')
          .select('id, monto, fecha, tipo, descripcion')
          .order('fecha', ascending: false);

      double totalD = 0;
      for (final d in diezmosData) {
        totalD += (d['monto'] ?? 0).toDouble();
      }

      double totalO = 0;
      for (final o in ofrendasData) {
        totalO += (o['monto'] ?? 0).toDouble();
      }

      final Map<String, double> diezmosMes = {};
      for (final d in diezmosData) {
        final fecha = (d['fecha'] ?? '').toString().substring(0, 7);
        diezmosMes[fecha] =
            (diezmosMes[fecha] ?? 0) + (d['monto'] ?? 0).toDouble();
      }

      final Map<String, double> ofrendasMes = {};
      for (final o in ofrendasData) {
        final fecha = (o['fecha'] ?? '').toString().substring(0, 7);
        ofrendasMes[fecha] =
            (ofrendasMes[fecha] ?? 0) + (o['monto'] ?? 0).toDouble();
      }

      setState(() {
        _diezmos = List<Map<String, dynamic>>.from(diezmosData);
        _ofrendas = List<Map<String, dynamic>>.from(ofrendasData);
        _totalDiezmos = totalD;
        _totalOfrendas = totalO;
        _diezmosPorMes = diezmosMes;
        _ofrendasPorMes = ofrendasMes;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
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

  Future<void> _exportarPDFDiezmos() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Reporte de Diezmos',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.amber800,
              ),
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
                      'Bs ${_totalDiezmos.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                    pw.Text('Total Diezmos'),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text(
                      '${_diezmos.length}',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                      ),
                    ),
                    pw.Text('Registros'),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.amber50),
                children: ['#', 'Miembro', 'Fecha', 'Monto']
                    .map(
                      (h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          h,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              ..._diezmos.asMap().entries.map(
                (e) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '${e.key + 1}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        (e.value['miembros'] as Map?)?['nombre'] ?? '-',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        (e.value['fecha'] ?? '').toString(),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Bs ${(e.value['monto'] ?? 0).toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
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

  Future<void> _exportarPDFOfrendas() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Reporte de Ofrendas',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.amber800,
              ),
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
                      'Bs ${_totalOfrendas.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.purple,
                      ),
                    ),
                    pw.Text('Total Ofrendas'),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text(
                      '${_ofrendas.length}',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                      ),
                    ),
                    pw.Text('Registros'),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.purple50),
                children: ['#', 'Tipo', 'Fecha', 'Monto']
                    .map(
                      (h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          h,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              ..._ofrendas.asMap().entries.map(
                (e) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '${e.key + 1}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        (e.value['tipo'] ?? 'general').toString(),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        (e.value['fecha'] ?? '').toString(),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Bs ${(e.value['monto'] ?? 0).toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
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

    return DashboardShell(
      nombreUsuario: AppSession.nombre,
      rol: 'Pastor',
      menuItems: _menuItems,
      indiceActivo: _menuActivo,
      onMenuTap: _navegar,
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: _kColor))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    movil ? 14 : 28,
                    movil ? 14 : 28,
                    movil ? 14 : 28,
                    0,
                  ),
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
                              Icons.attach_money_outlined,
                              color: _kColor,
                              size: movil ? 22 : 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reporte de Aportes',
                                  style: TextStyle(
                                    color: kWhite,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Diezmos y ofrendas',
                                  style: TextStyle(color: kGrey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(width: 50, height: 3, color: _kColor),
                      const SizedBox(height: 16),
                      // Cards resumen - responsivo
                      if (movil) ...[
                        _ResumenCard(
                          titulo: 'Total Diezmos',
                          monto: _totalDiezmos,
                          icon: Icons.volunteer_activism,
                          color: kSuccess,
                        ),
                        const SizedBox(height: 8),
                        _ResumenCard(
                          titulo: 'Total Ofrendas',
                          monto: _totalOfrendas,
                          icon: Icons.card_giftcard,
                          color: const Color(0xFF9C27B0),
                        ),
                        const SizedBox(height: 8),
                        _ResumenCard(
                          titulo: 'Total General',
                          monto: _totalDiezmos + _totalOfrendas,
                          icon: Icons.account_balance_wallet,
                          color: _kColor,
                        ),
                      ] else
                        Row(
                          children: [
                            _ResumenCard(
                              titulo: 'Total Diezmos',
                              monto: _totalDiezmos,
                              icon: Icons.volunteer_activism,
                              color: kSuccess,
                            ),
                            const SizedBox(width: 12),
                            _ResumenCard(
                              titulo: 'Total Ofrendas',
                              monto: _totalOfrendas,
                              icon: Icons.card_giftcard,
                              color: const Color(0xFF9C27B0),
                            ),
                            const SizedBox(width: 12),
                            _ResumenCard(
                              titulo: 'Total General',
                              monto: _totalDiezmos + _totalOfrendas,
                              icon: Icons.account_balance_wallet,
                              color: _kColor,
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      // TabBar
                      Container(
                        decoration: BoxDecoration(
                          color: kBgCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kDivider),
                        ),
                        child: TabBar(
                          controller: _tab,
                          indicatorColor: _kColor,
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
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: movil ? 14 : 28,
                        ),
                        child: _TabDiezmos(
                          datos: _diezmos,
                          porMes: _diezmosPorMes,
                          onExport: _exportarPDFDiezmos,
                        ),
                      ),
                      SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: movil ? 14 : 28,
                        ),
                        child: _TabOfrendas(
                          datos: _ofrendas,
                          porMes: _ofrendasPorMes,
                          onExport: _exportarPDFOfrendas,
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

class _ResumenCard extends StatelessWidget {
  final String titulo;
  final double monto;
  final IconData icon;
  final Color color;
  const _ResumenCard({
    required this.titulo,
    required this.monto,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.of(context).size.width < 600;
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDivider),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bs ${monto.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: kWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  titulo,
                  style: const TextStyle(color: kGrey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return movil ? card : Expanded(child: card);
  }
}

class _TabDiezmos extends StatelessWidget {
  final List<Map<String, dynamic>> datos;
  final Map<String, double> porMes;
  final VoidCallback onExport;
  const _TabDiezmos({
    required this.datos,
    required this.porMes,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Diezmos por Mes',
              style: TextStyle(
                color: kWhite,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: onExport,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.picture_as_pdf, size: 15),
              label: const Text(
                'PDF',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 170,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kDivider),
          ),
          child: _buildLineChart(porMes, kSuccess),
        ),
        const SizedBox(height: 20),
        const Text(
          'Últimos Diezmos',
          style: TextStyle(
            color: kWhite,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...datos.take(10).map((d) {
          final nombre = (d['miembros'] as Map?)?['nombre'] ?? '-';
          final monto = (d['monto'] ?? 0).toDouble();
          final fecha = (d['fecha'] ?? '').toString();
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kDivider),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: kSuccess.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: kSuccess, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(color: kWhite, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        fecha,
                        style: const TextStyle(color: kGrey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kSuccess.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Bs ${monto.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: kSuccess,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLineChart(Map<String, double> data, Color color) {
    final meses = data.keys.toList()..sort();
    if (meses.isEmpty) {
      return const Center(
        child: Text('No hay datos', style: TextStyle(color: kGrey)),
      );
    }
    final spots = meses
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), data[e.value]!))
        .toList();
    final maxY = data.values.reduce((a, b) => a > b ? a : b) * 1.2;
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: kDivider, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) {
                final idx = v.toInt();
                if (idx < 0 || idx >= meses.length) return const SizedBox();
                return Text(
                  meses[idx].substring(5),
                  style: const TextStyle(color: kGrey, fontSize: 9),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) => Text(
                '${v.toInt()}',
                style: const TextStyle(color: kGrey, fontSize: 9),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (meses.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabOfrendas extends StatelessWidget {
  final List<Map<String, dynamic>> datos;
  final Map<String, double> porMes;
  final VoidCallback onExport;
  const _TabOfrendas({
    required this.datos,
    required this.porMes,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ofrendas por Mes',
              style: TextStyle(
                color: kWhite,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: onExport,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.picture_as_pdf, size: 15),
              label: const Text(
                'PDF',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 170,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kDivider),
          ),
          child: _buildBarChart(porMes),
        ),
        const SizedBox(height: 20),
        const Text(
          'Últimas Ofrendas',
          style: TextStyle(
            color: kWhite,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...datos.take(10).map((o) {
          final monto = (o['monto'] ?? 0).toDouble();
          final fecha = (o['fecha'] ?? '').toString();
          final tipo = (o['tipo'] ?? 'general').toString();
          const color = Color(0xFF9C27B0);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kDivider),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tipo.toUpperCase(),
                        style: const TextStyle(
                          color: kWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        fecha,
                        style: const TextStyle(color: kGrey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Bs ${monto.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBarChart(Map<String, double> data) {
    final meses = data.keys.toList()..sort();
    if (meses.isEmpty) {
      return const Center(
        child: Text('No hay datos', style: TextStyle(color: kGrey)),
      );
    }
    const color = Color(0xFF9C27B0);
    final maxY = data.values.reduce((a, b) => a > b ? a : b) * 1.3;
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) {
                final idx = v.toInt();
                if (idx < 0 || idx >= meses.length) return const SizedBox();
                return Text(
                  meses[idx].substring(5),
                  style: const TextStyle(color: kGrey, fontSize: 9),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) => Text(
                '${v.toInt()}',
                style: const TextStyle(color: kGrey, fontSize: 9),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: kDivider, strokeWidth: 1),
        ),
        barGroups: meses
            .asMap()
            .entries
            .map(
              (e) => BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: data[e.value]!,
                    color: color,
                    width: 14,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
