import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/session.dart';

final supabase = Supabase.instance.client;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _cargando = false;
  bool _verPass = false;
  String? _error;

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Por favor completa todos los campos.');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final res = await supabase
          .from('usuarios')
          .select()
          .eq('email', _emailCtrl.text.trim())
          .eq('contrasena', _passCtrl.text.trim())
          .maybeSingle();

      if (!mounted) return;
      if (res == null) {
        setState(() {
          _error = 'Correo o contrasena incorrectos.';
          _cargando = false;
        });
        return;
      }
      AppSession.usuario = res;
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      setState(() {
        _error = 'Error de conexion: $e';
        _cargando = false;
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      backgroundColor: kBg,
      body: Row(
        children: [
          if (desktop)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF111111),
                      Color(0xFF2A1A00),
                      Color(0xFF111111),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [kGold, kGoldDark]),
                      ),
                      child: const Center(
                        child: Text(
                          'LV',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'LUZ Y VIDA',
                      style: TextStyle(
                        color: kGold,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'SIGMAR — Sistema de Gestion',
                      style: TextStyle(color: kGrey, fontSize: 13),
                    ),
                    const SizedBox(height: 48),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Column(
                        children: const [
                          _InfoItem(
                            Icons.people_rounded,
                            'Gestion de Miembros',
                          ),
                          _InfoItem(Icons.group_rounded, 'Grupos y Asistencia'),
                          _InfoItem(Icons.school_rounded, 'Cursos y Formacion'),
                          _InfoItem(
                            Icons.volunteer_activism,
                            'Gestion de Aportes',
                          ),
                          _InfoItem(Icons.bar_chart_rounded, 'Reportes'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Somos Familia',
                      style: TextStyle(
                        color: kGold,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Container(
              color: kBgMid,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: SizedBox(
                    width: 380,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Row(
                              children: const [
                                Icon(Icons.arrow_back, color: kGrey, size: 15),
                                SizedBox(width: 6),
                                Text(
                                  'Volver al inicio',
                                  style: TextStyle(color: kGrey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [kGold, kGoldDark],
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'LV',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Iniciar Sesion',
                          style: TextStyle(
                            color: kWhite,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Accede al sistema SIGMAR',
                          style: TextStyle(color: kGrey, fontSize: 14),
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: kWhite, fontSize: 14),
                          decoration: _deco(
                            'Correo electronico',
                            Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passCtrl,
                          obscureText: !_verPass,
                          style: const TextStyle(color: kWhite, fontSize: 14),
                          decoration: _deco('Contrasena', Icons.lock_outline)
                              .copyWith(
                                suffixIcon: GestureDetector(
                                  onTap: () =>
                                      setState(() => _verPass = !_verPass),
                                  child: Icon(
                                    _verPass
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: kGrey,
                                    size: 18,
                                  ),
                                ),
                              ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kDanger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: kDanger.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: kDanger,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: kDanger,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: _cargando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'ENTRAR',
                                    style: TextStyle(
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Center(
                          child: Text(
                            '2025 Iglesia Luz y Vida - SIGMAR',
                            style: TextStyle(color: kGrey, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: kGrey, fontSize: 13),
    prefixIcon: Icon(icon, color: kGrey, size: 18),
    filled: true,
    fillColor: kBgCard,
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
  );
}

class _InfoItem extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _InfoItem(this.icono, this.texto);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Icon(icono, color: kGold, size: 18),
        const SizedBox(width: 12),
        Text(texto, style: const TextStyle(color: kGrey, fontSize: 14)),
      ],
    ),
  );
}
