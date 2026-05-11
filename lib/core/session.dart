import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppSession {
  static Map<String, dynamic>? usuario;
  static Map<String, dynamic>? miembro;
  static const String _keyUsuario = 'session_usuario';
  static const String _keyMiembro = 'session_miembro';

  static bool get autenticado => usuario != null;
  static String get rol =>
      (usuario?['rol'] as String?)?.toLowerCase().trim() ?? '';
  static String get nombre => miembro?['nombre'] ?? usuario?['email'] ?? '';
  static int? get miembroId => usuario?['miembro_id'] as int?;

  static Future<void> guardarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    if (usuario != null) {
      await prefs.setString(_keyUsuario, jsonEncode(usuario));
    }
    if (miembro != null) {
      await prefs.setString(_keyMiembro, jsonEncode(miembro));
    }
  }

  static Future<bool> cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioStr = prefs.getString(_keyUsuario);
    final miembroStr = prefs.getString(_keyMiembro);

    if (usuarioStr != null) {
      usuario = jsonDecode(usuarioStr) as Map<String, dynamic>;
      miembro = miembroStr != null
          ? jsonDecode(miembroStr) as Map<String, dynamic>
          : null;
      return true;
    }
    return false;
  }

  static Future<void> cerrar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsuario);
    await prefs.remove(_keyMiembro);
    usuario = null;
    miembro = null;
  }
}
