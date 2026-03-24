import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sigmar_page.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFF7F77DD);

class RegistroUsuarioScreen extends StatefulWidget {
  final Map<String, dynamic>? usuarioParaEditar;
  const RegistroUsuarioScreen({super.key, this.usuarioParaEditar});

  @override
  State<RegistroUsuarioScreen> createState() => _RegistroUsuarioScreenState();
}

class _RegistroUsuarioScreenState extends State<RegistroUsuarioScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _verPass = false;
  bool _cargando = false;
  String? _rolSeleccionado;
  String? _miembroSeleccionadoId;
  List<Map<String, dynamic>> _miembrosSinUsuario = [];

  bool get _esEdicion => widget.usuarioParaEditar != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _emailCtrl.text = widget.usuarioParaEditar!['email'] ?? '';
      _rolSeleccionado = widget.usuarioParaEditar!['rol'];
    } else {
      _cargarMiembrosSinUsuario();
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarMiembrosSinUsuario() async {
    try {
      final data = await _sb
          .from('miembros')
          .select('id, nombre')
          .isFilter('idUsuario', null);
      setState(
        () => _miembrosSinUsuario = List<Map<String, dynamic>>.from(data),
      );
    } catch (e) {
      debugPrint('Error al cargar miembros: $e');
    }
  }

  Future<void> _guardar() async {
    if (_emailCtrl.text.isEmpty) {
      _mostrarError('El email es obligatorio');
      return;
    }
    if (!_esEdicion && _passCtrl.text.trim().isEmpty) {
      _mostrarError('La contraseña es obligatoria');
      return;
    }
    setState(() => _cargando = true);
    try {
      if (!_esEdicion) {
        final data = <String, dynamic>{
          'email': _emailCtrl.text.trim(),
          'contrasena': _passCtrl.text.trim(),
          'rol': _rolSeleccionado ?? 'miembro',
          'estado': 'activo',
        };
        if (_miembroSeleccionadoId != null) {
          data['miembro_id'] = _miembroSeleccionadoId!;
        }
        await _sb.from('usuarios').insert(data);
      } else {
        final updates = <String, dynamic>{'rol': _rolSeleccionado ?? 'miembro'};
        if (_passCtrl.text.isNotEmpty) {
          updates['contrasena'] = _passCtrl.text.trim();
        }
        await _sb
            .from('usuarios')
            .update(updates)
            .eq('id', widget.usuarioParaEditar!['id']);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _mostrarError('Error: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: kDanger));
  }

  Future<void> _darDeBaja() async {
    try {
      await _sb
          .from('usuarios')
          .update({'estado': 'inactivo'})
          .eq('id', widget.usuarioParaEditar!['id']);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _mostrarError('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SigmarPage(
      rutaActual: '/admin/usuarios',
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kDivider),
            ),
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
                        color: _kColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.manage_accounts,
                        color: _kColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _esEdicion ? 'Editar Usuario' : 'Nuevo Usuario',
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 18,
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
                const SizedBox(height: 24),

                if (!_esEdicion && _miembrosSinUsuario.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _miembroSeleccionadoId,
                    dropdownColor: kBgCard,
                    style: const TextStyle(color: kWhite),
                    decoration: _deco(
                      'Vincular miembro (opcional)',
                      Icons.person_add_outlined,
                    ),
                    hint: const Text(
                      'Seleccionar miembro...',
                      style: TextStyle(color: kGrey),
                    ),
                    items: _miembrosSinUsuario
                        .map(
                          (m) => DropdownMenuItem<String>(
                            value: m['id'].toString(),
                            child: Text(
                              m['nombre'] ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _miembroSeleccionadoId = v),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _emailCtrl,
                  enabled: !_esEdicion,
                  style: const TextStyle(color: kWhite),
                  decoration: _deco('Email', Icons.email_outlined),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passCtrl,
                  obscureText: !_verPass,
                  style: const TextStyle(color: kWhite),
                  decoration:
                      _deco(
                        _esEdicion
                            ? 'Nueva contraseña (opcional)'
                            : 'Contraseña',
                        Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _verPass ? Icons.visibility_off : Icons.visibility,
                            color: kGrey,
                          ),
                          onPressed: () => setState(() => _verPass = !_verPass),
                        ),
                      ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _rolSeleccionado,
                  dropdownColor: kBgCard,
                  style: const TextStyle(color: kWhite),
                  decoration: _deco('Rol', Icons.admin_panel_settings_outlined),
                  hint: const Text(
                    'Seleccionar rol...',
                    style: TextStyle(color: kGrey),
                  ),
                  items: ['admin', 'pastor', 'lider', 'miembro']
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _rolSeleccionado = v),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kColor,
                      foregroundColor: kWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: kWhite,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _esEdicion ? 'ACTUALIZAR' : 'REGISTRAR',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                if (_esEdicion) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _darDeBaja,
                      child: const Text(
                        'DAR DE BAJA',
                        style: TextStyle(color: kDanger),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: kGrey),
    prefixIcon: Icon(icon, color: kGrey),
    filled: true,
    fillColor: kBgMid,
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
  );
}
