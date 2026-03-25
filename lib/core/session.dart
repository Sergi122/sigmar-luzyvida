class AppSession {
  static Map<String, dynamic>? usuario;
  static Map<String, dynamic>? miembro;

  static bool get autenticado => usuario != null;
  static String get rol =>
      (usuario?['rol'] as String?)?.toLowerCase().trim() ?? '';
  static String get nombre => miembro?['nombre'] ?? usuario?['email'] ?? '';
  static int? get miembroId => usuario?['miembro_id'] as int?;

  static void cerrar() {
    usuario = null;
    miembro = null;
  }
}
