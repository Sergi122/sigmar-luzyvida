import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/session.dart';
import '../../../../shared/widgets/dashboard_shell.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFF1D9E75);

class MiembroAportesScreen extends StatefulWidget {
  const MiembroAportesScreen({super.key});

  @override
  State<MiembroAportesScreen> createState() => _MiembroAportesScreenState();
}

class _MiembroAportesScreenState extends State<MiembroAportesScreen> {
  List<Map<String, dynamic>> _diezmos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final miembroId = AppSession.miembroId;
    if (miembroId == null) {
      if (mounted) setState(() => _cargando = false);
      return;
    }
    try {
      final data = await _sb
          .from('diezmos')
          .select('id, monto, fecha, observacion')
          .eq('id_miembro', miembroId)
          .order('fecha', ascending: false);
      if (mounted) {
        setState(() {
          _diezmos = List<Map<String, dynamic>>.from(data);
          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando aportes: $e');
      if (mounted) setState(() => _cargando = false);
    }
  }

  double get _total =>
      _diezmos.fold(0.0, (sum, d) => sum + (d['monto'] as num).toDouble());

  @override
  Widget build(BuildContext context) {
    return DashboardPage(
      rutaActual: '/miembro/aportes',
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
                    Icons.volunteer_activism,
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
                        'Mis Aportes',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Historial de tus diezmos registrados',
                        style: TextStyle(color: kGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 50, height: 3, color: _kColor),
            const SizedBox(height: 20),

            if (!_cargando && _diezmos.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _kColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total diezmos',
                      style: TextStyle(color: kGrey, fontSize: 13),
                    ),
                    Text(
                      'Bs ${_total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_cargando)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: _kColor),
                ),
              )
            else if (_diezmos.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.volunteer_activism,
                        size: 64,
                        color: kDivider,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aún no hay aportes registrados',
                        style: TextStyle(color: kGrey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _diezmos.length,
                  itemBuilder: (_, i) {
                    final d = _diezmos[i];
                    final obs = d['observacion'] as String?;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kBgMid,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kDivider),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _kColor.withValues(alpha: 0.12),
                            ),
                            child: const Icon(
                              Icons.monetization_on_outlined,
                              color: _kColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['fecha'] ?? '',
                                  style: const TextStyle(
                                    color: kGrey,
                                    fontSize: 12,
                                  ),
                                ),
                                if (obs != null && obs.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    obs,
                                    style: const TextStyle(
                                      color: kGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            'Bs ${(d['monto'] as num).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: kWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
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
