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
      // 🔐 LOGIN CON SUPABASE AUTH
      final res = await supabase.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final user = res.user;

      if (user == null) {
        setState(() {
          _error = 'Correo o contraseña incorrectos.';
          _cargando = false;
        });
        return;
      }

      // 📦 TRAER DATOS DEL USUARIO
      final data = await supabase
          .from('usuarios')
          .select('*, miembros(*)')
          .eq('id', user.id)
          .single();

      // 💾 GUARDAR SESIÓN
      AppSession.usuario = data;
      AppSession.miembro = data['miembros'];

      if (!mounted) return;

      final rol = (data['rol'] as String).toLowerCase();

      // 🚀 REDIRECCIÓN POR ROL
      if (rol == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (rol == 'pastor') {
        Navigator.pushReplacementNamed(context, '/pastor');
      } else {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
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
                    _logoGrande(),
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
                      'SIGMAR — Sistema de Gestión',
                      style: TextStyle(color: kGrey, fontSize: 13),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Somos Familia',
                      style: TextStyle(
                        color: kGold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          /// LOGIN
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
                        const Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            color: kWhite,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Accede al sistema SIGMAR',
                          style: TextStyle(color: kGrey),
                        ),
                        const SizedBox(height: 30),

                        /// EMAIL
                        TextField(
                          controller: _emailCtrl,
                          style: const TextStyle(color: kWhite),
                          decoration: _deco(
                            'Correo electrónico',
                            Icons.email_outlined,
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// PASSWORD
                        TextField(
                          controller: _passCtrl,
                          obscureText: !_verPass,
                          style: const TextStyle(color: kWhite),
                          decoration: _deco('Contraseña', Icons.lock_outline)
                              .copyWith(
                                suffixIcon: GestureDetector(
                                  onTap: () =>
                                      setState(() => _verPass = !_verPass),
                                  child: Icon(
                                    _verPass
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: kGrey,
                                  ),
                                ),
                              ),
                        ),

                        /// ERROR
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],

                        const SizedBox(height: 24),

                        /// BOTÓN
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _cargando
                                ? const CircularProgressIndicator(
                                    color: Colors.black,
                                  )
                                : const Text('ENTRAR'),
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

  Widget _logoGrande() {
    return Container(
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
    );
  }

  InputDecoration _deco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kGrey),
      prefixIcon: Icon(icon, color: kGrey),
      filled: true,
      fillColor: kBgCard,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
