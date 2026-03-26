import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/session.dart';
import '../../../../shared/widgets/sigmar_page.dart';

final _sb = Supabase.instance.client;

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
  bool _subiendoFoto = false;
  String? _error;

  // Controladores
  final _nombreCtrl = TextEditingController();
  final _carnetCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _fechaNacCtrl = TextEditingController();
  final _fechaConvCtrl = TextEditingController();
  bool _bautizado = false;
  bool _encuentro = false;

  // Foto
  Uint8List? _nuevaFotoBytes;
  String? _fotoUrlActual;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _carnetCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _fechaNacCtrl.dispose();
    _fechaConvCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final miembroId = AppSession.miembroId;
      if (miembroId == null) {
        setState(() => _cargando = false);
        return;
      }
      final data = await _sb
          .from('miembros')
          .select()
          .eq('id', miembroId)
          .maybeSingle();
      setState(() {
        _miembro = data;
        _cargando = false;
      });
      if (data != null) _llenar(data);
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  void _llenar(Map<String, dynamic> m) {
    _nombreCtrl.text = m['nombre'] ?? '';
    _carnetCtrl.text = m['carnet'] ?? '';
    _telefonoCtrl.text = '${m['telefono'] ?? ''}';
    _direccionCtrl.text = m['direccion'] ?? '';
    _fechaNacCtrl.text = m['fecha_nacimiento'] ?? '';
    _fechaConvCtrl.text = m['fecha_conversion'] ?? '';
    _bautizado = m['bautizado'] ?? false;
    _encuentro = m['asistio_encuentro'] ?? false;
    _fotoUrlActual = m['foto_url'];
    _nuevaFotoBytes = null;
  }

  // ── Selección de foto ──────────────────────────────
  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() => _nuevaFotoBytes = bytes);
  }

  // ── Subida de foto al Storage ──────────────────────
  Future<String?> _subirFoto() async {
    if (_nuevaFotoBytes == null) return _fotoUrlActual;
    setState(() => _subiendoFoto = true);
    try {
      final id = _miembro!['id'] as int;
      final path = 'miembro_$id/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _sb.storage
          .from('fotos-miembros')
          .uploadBinary(
            path,
            _nuevaFotoBytes!,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      return _sb.storage.from('fotos-miembros').getPublicUrl(path);
    } catch (e) {
      setState(() => _error = 'Error subiendo foto: $e');
      return _fotoUrlActual;
    } finally {
      setState(() => _subiendoFoto = false);
    }
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
      // Si eliminó la foto y no hay nueva, foto_url = null
      final fotoUrl = _nuevaFotoBytes != null
          ? await _subirFoto()
          : _fotoUrlActual; // null si la eliminó

      final datos = {
        'nombre': _nombreCtrl.text.trim(),
        'carnet': _carnetCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
        'fecha_nacimiento': _fechaNacCtrl.text.trim().isEmpty
            ? null
            : _fechaNacCtrl.text.trim(),
        'fecha_conversion': _fechaConvCtrl.text.trim().isEmpty
            ? null
            : _fechaConvCtrl.text.trim(),
        'bautizado': _bautizado,
        'asistio_encuentro': _encuentro,
        'foto_url': fotoUrl,
      };
      await _sb.from('miembros').update(datos).eq('id', _miembro!['id']);
      AppSession.miembro?['nombre'] = _nombreCtrl.text.trim();
      setState(() {
        _guardando = false;
        _editando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado'),
            backgroundColor: kSuccess,
          ),
        );
      }
      _cargar();
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _guardando = false;
      });
    }
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
                  // ── Header ──
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
                            if (!_editando && _miembro != null)
                              _llenar(_miembro!);
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
                    Container(
                      padding: const EdgeInsets.all(20),
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
                            child: Text(
                              'Tu usuario no está vinculado a un miembro. Contacta al administrador.',
                              style: TextStyle(color: kGrey, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_editando)
                    _FormEditar(
                      movil: movil,
                      nombreCtrl: _nombreCtrl,
                      carnetCtrl: _carnetCtrl,
                      telefonoCtrl: _telefonoCtrl,
                      direccionCtrl: _direccionCtrl,
                      fechaNacCtrl: _fechaNacCtrl,
                      fechaConvCtrl: _fechaConvCtrl,
                      bautizado: _bautizado,
                      encuentro: _encuentro,
                      onBautizado: (v) => setState(() => _bautizado = v),
                      onEncuentro: (v) => setState(() => _encuentro = v),
                      fotoUrlActual: _fotoUrlActual,
                      nuevaFotoBytes: _nuevaFotoBytes,
                      onSeleccionarFoto: _seleccionarFoto,
                      onEliminarFoto: () => setState(() {
                        _nuevaFotoBytes = null;
                        _fotoUrlActual = null;
                      }),
                      error: _error,
                      guardando: _guardando || _subiendoFoto,
                      onGuardar: _guardar,
                    )
                  else
                    _VistaInfo(miembro: _miembro!),
                ],
              ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  VISTA SOLO LECTURA
// ══════════════════════════════════════════════════════
class _VistaInfo extends StatelessWidget {
  final Map<String, dynamic> miembro;
  const _VistaInfo({required this.miembro});

  @override
  Widget build(BuildContext context) {
    final inicial = (miembro['nombre'] ?? 'M')[0].toUpperCase();
    final fotoUrl = miembro['foto_url'] as String?;

    return Column(
      children: [
        Center(
          child: Column(
            children: [
              // Avatar con foto
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kGold.withValues(alpha: 0.15),
                  border: Border.all(
                    color: kGold.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: fotoUrl != null && fotoUrl.isNotEmpty
                      ? Image.network(
                          fotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              inicial,
                              style: const TextStyle(
                                color: kGold,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : Center(
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
                  miembro['estado'] ?? 'activo',
                  style: const TextStyle(color: kGold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _InfoCard('Carnet', miembro['carnet'] ?? '-', Icons.badge_outlined),
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
              'Fecha Nacimiento',
              miembro['fecha_nacimiento'] ?? '-',
              Icons.cake_outlined,
            ),
            _InfoCard(
              'Fecha Conversión',
              miembro['fecha_conversion'] ?? '-',
              Icons.calendar_today_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _Badge('Bautizado', miembro['bautizado'] == true),
            const SizedBox(width: 12),
            _Badge('Asistió a Encuentro', miembro['asistio_encuentro'] == true),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String titulo, valor;
  final IconData icono;
  const _InfoCard(this.titulo, this.valor, this.icono);
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
        Icon(icono, color: kGold, size: 16),
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

// ══════════════════════════════════════════════════════
//  FORMULARIO DE EDICIÓN (PERFIL)
// ══════════════════════════════════════════════════════
class _FormEditar extends StatelessWidget {
  final bool movil;
  final TextEditingController nombreCtrl,
      carnetCtrl,
      telefonoCtrl,
      direccionCtrl,
      fechaNacCtrl,
      fechaConvCtrl;
  final bool bautizado, encuentro;
  final ValueChanged<bool> onBautizado, onEncuentro;
  // Foto
  final String? fotoUrlActual;
  final Uint8List? nuevaFotoBytes;
  final VoidCallback onSeleccionarFoto;
  final VoidCallback onEliminarFoto;
  // Estado
  final String? error;
  final bool guardando;
  final VoidCallback onGuardar;

  const _FormEditar({
    required this.movil,
    required this.nombreCtrl,
    required this.carnetCtrl,
    required this.telefonoCtrl,
    required this.direccionCtrl,
    required this.fechaNacCtrl,
    required this.fechaConvCtrl,
    required this.bautizado,
    required this.encuentro,
    required this.onBautizado,
    required this.onEncuentro,
    required this.fotoUrlActual,
    required this.nuevaFotoBytes,
    required this.onSeleccionarFoto,
    required this.onEliminarFoto,
    required this.error,
    required this.guardando,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Foto ──
        const Text(
          'FOTO DE PERFIL',
          style: TextStyle(color: kGrey, fontSize: 11, letterSpacing: 2),
        ),
        const SizedBox(height: 14),
        _FotoSelectorPerfil(
          fotoUrlActual: fotoUrlActual,
          nuevaFotoBytes: nuevaFotoBytes,
          onSeleccionar: onSeleccionarFoto,
          onEliminar: onEliminarFoto,
        ),
        const SizedBox(height: 20),

        // ── Datos personales ──
        const Text(
          'DATOS PERSONALES',
          style: TextStyle(color: kGrey, fontSize: 11, letterSpacing: 2),
        ),
        const SizedBox(height: 14),
        _campo('Nombre completo *', nombreCtrl, Icons.person_outline),
        const SizedBox(height: 12),
        movil
            ? Column(
                children: [
                  _campo('Carnet', carnetCtrl, Icons.badge_outlined),
                  const SizedBox(height: 12),
                  _campo(
                    'Teléfono',
                    telefonoCtrl,
                    Icons.phone_outlined,
                    tipo: TextInputType.phone,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _campo('Carnet', carnetCtrl, Icons.badge_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _campo(
                      'Teléfono',
                      telefonoCtrl,
                      Icons.phone_outlined,
                      tipo: TextInputType.phone,
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 12),
        _campo('Dirección', direccionCtrl, Icons.location_on_outlined),
        const SizedBox(height: 12),
        _campo(
          'Fecha de nacimiento (AAAA-MM-DD)',
          fechaNacCtrl,
          Icons.cake_outlined,
        ),
        const SizedBox(height: 20),

        // ── Datos espirituales ──
        const Text(
          'DATOS ESPIRITUALES',
          style: TextStyle(color: kGrey, fontSize: 11, letterSpacing: 2),
        ),
        const SizedBox(height: 14),
        _campo(
          'Fecha conversión (AAAA-MM-DD)',
          fechaConvCtrl,
          Icons.calendar_today_outlined,
        ),
        const SizedBox(height: 12),
        movil
            ? Column(
                children: [
                  _sw('Bautizado', bautizado, onBautizado),
                  const SizedBox(height: 10),
                  _sw('Asistió a encuentro', encuentro, onEncuentro),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _sw('Bautizado', bautizado, onBautizado)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _sw('Asistió a encuentro', encuentro, onEncuentro),
                  ),
                ],
              ),

        // ── Error ──
        if (error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kDanger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kDanger.withValues(alpha: 0.3)),
            ),
            child: Text(
              error!,
              style: const TextStyle(color: kDanger, fontSize: 13),
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

  Widget _campo(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType tipo = TextInputType.text,
  }) => TextField(
    controller: ctrl,
    keyboardType: tipo,
    style: const TextStyle(color: kWhite, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kGrey, fontSize: 12),
      prefixIcon: Icon(icon, color: kGrey, size: 16),
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

  Widget _sw(String label, bool valor, ValueChanged<bool> onChanged) =>
      Container(
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
              activeThumbColor: kGold,
              activeTrackColor: kGold.withValues(alpha: 0.3),
            ),
          ],
        ),
      );
}

// ── Selector de foto para perfil ──────────────────────
class _FotoSelectorPerfil extends StatelessWidget {
  final String? fotoUrlActual;
  final Uint8List? nuevaFotoBytes;
  final VoidCallback onSeleccionar;
  final VoidCallback onEliminar;

  const _FotoSelectorPerfil({
    required this.fotoUrlActual,
    required this.nuevaFotoBytes,
    required this.onSeleccionar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final tieneNueva = nuevaFotoBytes != null;
    final tieneActual = fotoUrlActual != null && fotoUrlActual!.isNotEmpty;
    final tieneFoto = tieneNueva || tieneActual;

    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kGold.withValues(alpha: 0.1),
            border: Border.all(
              color: tieneFoto ? kGold.withValues(alpha: 0.5) : kDivider,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: tieneNueva
                ? Image.memory(nuevaFotoBytes!, fit: BoxFit.cover)
                : tieneActual
                ? Image.network(
                    fotoUrlActual!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_outline,
                      color: kGold,
                      size: 36,
                    ),
                  )
                : const Icon(Icons.person_outline, color: kGold, size: 36),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: onSeleccionar,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold.withValues(alpha: 0.12),
                foregroundColor: kGold,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: kGold.withValues(alpha: 0.3)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              icon: const Icon(Icons.upload_outlined, size: 16),
              label: Text(
                tieneFoto ? 'Cambiar foto' : 'Subir foto',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (tieneFoto) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onEliminar,
                child: const Text(
                  'Eliminar foto',
                  style: TextStyle(color: kDanger, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 6),
            const Text(
              'JPG o PNG. Máx. 2MB.',
              style: TextStyle(color: kGrey, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
