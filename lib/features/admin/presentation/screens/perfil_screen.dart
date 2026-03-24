import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/session.dart';
import '../../../../shared/widgets/sigmar_page.dart';

final _sb = Supabase.instance.client;
const _kColor = kGold;

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _miembro;
  bool _cargando = true;
  bool _editando = false;
  bool _guardando = false;
  String? _error;

  // Controladores
  final _nombreCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  final _carnetCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _ministerioCtrl = TextEditingController();
  final _fechaConvCtrl = TextEditingController();
  bool _bautizado = false;
  bool _encuentro = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _edadCtrl.dispose();
    _carnetCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _ministerioCtrl.dispose();
    _fechaConvCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final idUsuario = AppSession.usuario?['id'];
      if (idUsuario == null) {
        setState(() => _cargando = false);
        return;
      }
      final data = await _sb
          .from('miembros')
          .select()
          .eq('idUsuario', idUsuario)
          .maybeSingle();
      setState(() {
        _miembro = data;
        _cargando = false;
      });
      if (data != null) _llenarControladores(data);
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  void _llenarControladores(Map<String, dynamic> m) {
    _nombreCtrl.text = m['nombre'] ?? '';
    _edadCtrl.text = '${m['edad'] ?? ''}';
    _carnetCtrl.text = m['carnet'] ?? '';
    _telefonoCtrl.text = '${m['telefono'] ?? ''}';
    _direccionCtrl.text = m['direccion'] ?? '';
    _ministerioCtrl.text = m['ministerio'] ?? '';
    _fechaConvCtrl.text = m['fechaConversion'] ?? '';
    _bautizado = m['bautizado'] ?? false;
    _encuentro = m['asistioEncuentro'] ?? false;
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
    try {
      final datos = {
        'nombre': _nombreCtrl.text.trim(),
        'edad': int.tryParse(_edadCtrl.text.trim()) ?? 0,
        'carnet': _carnetCtrl.text.trim(),
        'telefono': int.tryParse(_telefonoCtrl.text.trim()) ?? 0,
        'direccion': _direccionCtrl.text.trim(),
        'ministerio': _ministerioCtrl.text.trim(),
        'fechaConversion': _fechaConvCtrl.text.trim(),
        'bautizado': _bautizado,
        'asistioEncuentro': _encuentro,
      };
      await _sb.from('miembros').update(datos).eq('id', _miembro!['id']);
      // Actualizar nombre en sesión
      AppSession.usuario?['nombre'] = _nombreCtrl.text.trim();
      setState(() {
        _guardando = false;
        _editando = false;
      });
      _mostrarExito('Perfil actualizado');
      _cargar();
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _guardando = false;
      });
    }
  }

  void _mostrarExito(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: kSuccess));
  }

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.of(context).size.width < 700;
    return SigmarPage(
      rutaActual: '/perfil',
      child: Padding(
        padding: EdgeInsets.all(movil ? 16 : 32),
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: kGold))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: kGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: kGold,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mi Perfil',
                              style: TextStyle(
                                color: kWhite,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Ver y editar mis datos personales',
                              style: TextStyle(color: kGrey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (_miembro != null)
                        ElevatedButton.icon(
                          onPressed: () => setState(() {
                            _editando = !_editando;
                            _error = null;
                            if (!_editando && _miembro != null) {
                              _llenarControladores(_miembro!);
                            }
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _editando ? kBgCard : kGold,
                            foregroundColor: _editando ? kGrey : Colors.black,
                            side: _editando
                                ? const BorderSide(color: kDivider)
                                : null,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          icon: Icon(
                            _editando ? Icons.close : Icons.edit_outlined,
                            size: 16,
                          ),
                          label: Text(
                            _editando ? 'Cancelar' : 'Editar',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(width: 50, height: 3, color: kGold),
                  const SizedBox(height: 24),

                  if (_miembro == null)
                    _SinMiembro()
                  else if (_editando)
                    _FormEditar(
                      movil: movil,
                      nombreCtrl: _nombreCtrl,
                      edadCtrl: _edadCtrl,
                      carnetCtrl: _carnetCtrl,
                      telefonoCtrl: _telefonoCtrl,
                      direccionCtrl: _direccionCtrl,
                      ministerioCtrl: _ministerioCtrl,
                      fechaConvCtrl: _fechaConvCtrl,
                      bautizado: _bautizado,
                      encuentro: _encuentro,
                      onBautizado: (v) => setState(() => _bautizado = v),
                      onEncuentro: (v) => setState(() => _encuentro = v),
                      error: _error,
                      guardando: _guardando,
                      onGuardar: _guardar,
                    )
                  else
                    _VistaInfo(miembro: _miembro!, movil: movil),
                ],
              ),
      ),
    );
  }
}

// ── Sin miembro vinculado ─────────────────────────────
class _SinMiembro extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: kBgCard,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: kDivider),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline, color: kGold, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sin perfil de miembro',
                style: TextStyle(
                  color: kWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                'Tu usuario no está vinculado a un miembro. Contacta al administrador.',
                style: TextStyle(color: kGrey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── Vista de información (solo lectura) ───────────────
class _VistaInfo extends StatelessWidget {
  final Map<String, dynamic> miembro;
  final bool movil;
  const _VistaInfo({required this.miembro, required this.movil});

  @override
  Widget build(BuildContext context) {
    final inicial = (miembro['nombre'] ?? 'M')[0].toUpperCase();
    return Column(
      children: [
        // Avatar grande
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kGold.withValues(alpha: 0.15),
                  border: Border.all(
                    color: kGold.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    inicial,
                    style: const TextStyle(
                      color: kGold,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                miembro['nombre'] ?? '',
                style: const TextStyle(
                  color: kWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: kGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kGold.withValues(alpha: 0.3)),
                ),
                child: Text(
                  miembro['ministerio'] ?? 'Sin ministerio',
                  style: const TextStyle(color: kGold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Datos en grid
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _InfoCard('Carnet', miembro['carnet'] ?? '-', Icons.badge_outlined),
            _InfoCard(
              'Edad',
              '${miembro['edad'] ?? '-'} años',
              Icons.cake_outlined,
            ),
            _InfoCard(
              'Teléfono',
              '${miembro['telefono'] ?? '-'}',
              Icons.phone_outlined,
            ),
            _InfoCard(
              'Dirección',
              miembro['direccion'] ?? '-',
              Icons.location_on_outlined,
            ),
            _InfoCard(
              'Fecha Conversión',
              miembro['fechaConversion'] ?? '-',
              Icons.calendar_today_outlined,
            ),
            _InfoCard(
              'Estado',
              miembro['estado'] ?? '-',
              Icons.circle,
              color: miembro['estado'] == 'activo' ? kSuccess : kDanger,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Badges espirituales
        Row(
          children: [
            _Badge('Bautizado', miembro['bautizado'] == true),
            const SizedBox(width: 12),
            _Badge('Asistió a Encuentro', miembro['asistioEncuentro'] == true),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String titulo, valor;
  final IconData icono;
  final Color? color;
  const _InfoCard(this.titulo, this.valor, this.icono, {this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 280,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kBgCard,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: kDivider),
    ),
    child: Row(
      children: [
        Icon(icono, color: color ?? kGold, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: kGrey,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                  color: kWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  final String texto;
  final bool activo;
  const _Badge(this.texto, this.activo);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: activo ? kSuccess.withValues(alpha: 0.1) : kBgCard,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: activo ? kSuccess.withValues(alpha: 0.4) : kDivider,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          activo ? Icons.check_circle_outline : Icons.cancel_outlined,
          color: activo ? kSuccess : kGrey,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: TextStyle(color: activo ? kSuccess : kGrey, fontSize: 12),
        ),
      ],
    ),
  );
}

// ── Formulario de edición ─────────────────────────────
class _FormEditar extends StatelessWidget {
  final bool movil;
  final TextEditingController nombreCtrl,
      edadCtrl,
      carnetCtrl,
      telefonoCtrl,
      direccionCtrl,
      ministerioCtrl,
      fechaConvCtrl;
  final bool bautizado, encuentro;
  final ValueChanged<bool> onBautizado, onEncuentro;
  final String? error;
  final bool guardando;
  final VoidCallback onGuardar;

  const _FormEditar({
    required this.movil,
    required this.nombreCtrl,
    required this.edadCtrl,
    required this.carnetCtrl,
    required this.telefonoCtrl,
    required this.direccionCtrl,
    required this.ministerioCtrl,
    required this.fechaConvCtrl,
    required this.bautizado,
    required this.encuentro,
    required this.onBautizado,
    required this.onEncuentro,
    required this.error,
    required this.guardando,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DATOS PERSONALES',
          style: TextStyle(color: kGrey, fontSize: 11, letterSpacing: 2),
        ),
        const SizedBox(height: 14),
        _Campo('Nombre completo *', nombreCtrl, Icons.person_outline),
        const SizedBox(height: 12),
        movil
            ? Column(
                children: [
                  _Campo('Carnet', carnetCtrl, Icons.badge_outlined),
                  const SizedBox(height: 12),
                  _Campo(
                    'Edad',
                    edadCtrl,
                    Icons.cake_outlined,
                    tipo: TextInputType.number,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _Campo('Carnet', carnetCtrl, Icons.badge_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Campo(
                      'Edad',
                      edadCtrl,
                      Icons.cake_outlined,
                      tipo: TextInputType.number,
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 12),
        movil
            ? Column(
                children: [
                  _Campo(
                    'Teléfono',
                    telefonoCtrl,
                    Icons.phone_outlined,
                    tipo: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _Campo('Ministerio', ministerioCtrl, Icons.church_outlined),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _Campo(
                      'Teléfono',
                      telefonoCtrl,
                      Icons.phone_outlined,
                      tipo: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Campo(
                      'Ministerio',
                      ministerioCtrl,
                      Icons.church_outlined,
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 12),
        _Campo('Dirección', direccionCtrl, Icons.location_on_outlined),
        const SizedBox(height: 20),

        const Text(
          'DATOS ESPIRITUALES',
          style: TextStyle(color: kGrey, fontSize: 11, letterSpacing: 2),
        ),
        const SizedBox(height: 14),
        _Campo(
          'Fecha de conversión (AAAA-MM-DD)',
          fechaConvCtrl,
          Icons.calendar_today_outlined,
        ),
        const SizedBox(height: 12),
        movil
            ? Column(
                children: [
                  _Switch('Bautizado', bautizado, onBautizado),
                  const SizedBox(height: 10),
                  _Switch('Asistió a encuentro', encuentro, onEncuentro),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _Switch('Bautizado', bautizado, onBautizado)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Switch(
                      'Asistió a encuentro',
                      encuentro,
                      onEncuentro,
                    ),
                  ),
                ],
              ),

        if (error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
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
                    error!,
                    style: const TextStyle(color: kDanger, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: guardando ? null : onGuardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: kGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'GUARDAR CAMBIOS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────
class _Campo extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icono;
  final TextInputType tipo;
  const _Campo(
    this.label,
    this.ctrl,
    this.icono, {
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
      prefixIcon: Icon(icono, color: kGrey, size: 16),
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
        borderSide: const BorderSide(color: kGold, width: 2),
      ),
    ),
  );
}

class _Switch extends StatelessWidget {
  final String label;
  final bool valor;
  final ValueChanged<bool> onChanged;
  const _Switch(this.label, this.valor, this.onChanged);

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
          activeColor: kGold,
          activeTrackColor: kGold.withValues(alpha: 0.3),
        ),
      ],
    ),
  );
}
