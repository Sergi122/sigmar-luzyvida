// Estado global del usuario autenticado — llamado AppSession para evitar
// conflicto con Session de supabase_flutter
class AppSession {
  static Map<String, dynamic>? usuario;

  static bool get autenticado => usuario != null;

  static String get rol =>
      (usuario?['rol'] as String?)?.toLowerCase().trim() ?? '';

  static String get nombre => usuario?['nombre'] ?? usuario?['email'] ?? '';

  static void cerrar() => usuario = null;
}
