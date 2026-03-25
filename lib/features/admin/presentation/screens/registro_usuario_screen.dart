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
  int? _miembroId;
  List<Map<String, dynamic>> _miembros = [];

  bool get _esEdicion => widget.usuarioParaEditar != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _emailCtrl.text = widget.usuarioParaEditar!['email'] ?? '';
      _rolSeleccionado = widget.usuarioParaEditar!['rol'];
      _miembroId = widget.usuarioParaEditar!['miembro_id'] as int?;
    }
    _cargarMiembros();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarMiembros() async {
    try {
      final data = await _sb
          .from('miembros')
          .select('id, nombre')
          .order('nombre');
      setState(() => _miembros = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Error miembros: $e');
    }
  }

  // ✅ ÚNICO MÉTODO CAMBIADO — usa Edge Function
  Future<void> _guardar() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _mostrarError('El email es obligatorio');
      return;
    }
    if (!_esEdicion && _passCtrl.text.trim().length < 6) {
      _mostrarError('La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (_rolSeleccionado == null) {
      _mostrarError('Selecciona un rol');
      return;
    }

    setState(() => _cargando = true);

    try {
      if (!_esEdicion) {
        // ✅ Edge Function — no cierra la sesión del admin
        final response = await _sb.functions.invoke(
          'crear-usuario',
          body: {
            'email': _emailCtrl.text.trim(),
            'password': _passCtrl.text.trim(),
            'rol': _rolSeleccionado,
            if (_miembroId != null) 'miembro_id': _miembroId,
          },
        );

        if (response.status != 200) {
          final data = response.data;
          final msg = (data is Map && data['error'] != null)
              ? data['error'].toString()
              : 'Error al crear el usuario.';
          _mostrarError(msg);
          return;
        }
      } else {
        // ✅ Edición: solo actualiza rol y miembro vinculado
        final updates = <String, dynamic>{
          'rol': _rolSeleccionado,
          if (_miembroId != null) 'miembro_id': _miembroId,
        };
        await _sb
            .from('usuarios')
            .update(updates)
            .eq('id', widget.usuarioParaEditar!['id']);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _mostrarError('Error inesperado: $e');
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

  Future<void> _toggleActivo() async {
    try {
      final activo = widget.usuarioParaEditar!['activo'] as bool? ?? true;
      await _sb
          .from('usuarios')
          .update({'activo': !activo})
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
            width: 460,
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
                        color: _kColor.withValues(alpha: 0.15),
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

                // ── Vincular miembro ─────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: kBgMid,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kDivider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _miembroId,
                      isExpanded: true,
                      dropdownColor: kBgMid,
                      hint: const Text(
                        'Vincular con miembro (opcional)',
                        style: TextStyle(color: kGrey, fontSize: 13),
                      ),
                      style: const TextStyle(color: kWhite, fontSize: 14),
                      onChanged: (v) => setState(() => _miembroId = v),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text(
                            'Sin vincular',
                            style: TextStyle(color: kGrey),
                          ),
                        ),
                        ..._miembros.map(
                          (m) => DropdownMenuItem<int>(
                            value: m['id'] as int,
                            child: Text(
                              m['nombre'] ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Email ────────────────────────────────────────
                TextField(
                  controller: _emailCtrl,
                  enabled: !_esEdicion,
                  style: const TextStyle(color: kWhite),
                  decoration: _deco('Email', Icons.email_outlined),
                ),
                const SizedBox(height: 16),

                // ── Contraseña (solo creación) ───────────────────
                if (!_esEdicion) ...[
                  TextField(
                    controller: _passCtrl,
                    obscureText: !_verPass,
                    style: const TextStyle(color: kWhite),
                    decoration: _deco('Contraseña', Icons.lock_outline)
                        .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _verPass
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: kGrey,
                            ),
                            onPressed: () =>
                                setState(() => _verPass = !_verPass),
                          ),
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La contraseña se cambia desde el panel de Supabase.',
                    style: TextStyle(color: kGrey, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Rol ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: kBgMid,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kDivider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _rolSeleccionado,
                      isExpanded: true,
                      dropdownColor: kBgMid,
                      hint: const Text(
                        'Seleccionar rol...',
                        style: TextStyle(color: kGrey),
                      ),
                      style: const TextStyle(color: kWhite, fontSize: 14),
                      onChanged: (v) => setState(() => _rolSeleccionado = v),
                      items: const [
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('ADMINISTRADOR'),
                        ),
                        DropdownMenuItem(
                          value: 'pastor',
                          child: Text('PASTOR'),
                        ),
                        DropdownMenuItem(value: 'lider', child: Text('LÍDER')),
                        DropdownMenuItem(
                          value: 'miembro',
                          child: Text('MIEMBRO'),
                        ),
                        DropdownMenuItem(
                          value: 'finanzas',
                          child: Text('FINANZAS'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Botón guardar ────────────────────────────────
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
                            _esEdicion ? 'ACTUALIZAR' : 'CREAR USUARIO',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                // ── Activar / Desactivar ─────────────────────────
                if (_esEdicion) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _toggleActivo,
                      child: Text(
                        (widget.usuarioParaEditar!['activo'] as bool? ?? true)
                            ? 'DESACTIVAR USUARIO'
                            : 'ACTIVAR USUARIO',
                        style: TextStyle(
                          color:
                              (widget.usuarioParaEditar!['activo'] as bool? ??
                                  true)
                              ? kDanger
                              : kSuccess,
                        ),
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
