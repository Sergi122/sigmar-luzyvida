import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// 🔹 SESSION SIMPLE
class AppSession {
  static Map<String, dynamic>? usuario;

  static int get miembroId => usuario?['miembro_id'];
}

// 🔹 PANTALLA
class MiGrupoScreen extends StatefulWidget {
  const MiGrupoScreen({super.key});

  @override
  State<MiGrupoScreen> createState() => _MiGrupoScreenState();
}

class _MiGrupoScreenState extends State<MiGrupoScreen> {
  List miembros = [];
  int? grupoId;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  // 🔹 CARGAR GRUPO Y MIEMBROS
  Future<void> cargar() async {
    final miembroId = AppSession.miembroId;

    // 1. Obtener grupo del líder
    final grupo = await supabase
        .from('grupos')
        .select()
        .eq('id_lider', miembroId);

    if (grupo.isEmpty) return;

    grupoId = grupo[0]['id'];

    // 2. Obtener miembros
    final data = await supabase
        .from('grupo_miembros')
        .select('miembros(*)')
        .eq('id_grupo', grupoId!);

    setState(() {
      miembros = data;
    });
  }

  // 🔹 TOMAR ASISTENCIA
  Future<void> tomarAsistencia(int miembroId) async {
    await supabase.from('asistencia').insert({
      'id_miembro': miembroId,
      'id_grupo': grupoId,
      'fecha': DateTime.now().toIso8601String(),
      'presente': true,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Asistencia registrada')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Grupo')),
      body: miembros.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: miembros.length,
              itemBuilder: (_, i) {
                final m = miembros[i]['miembros'];

                return ListTile(
                  title: Text(m['nombre']),
                  subtitle: Text("ID: ${m['id']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => tomarAsistencia(m['id']),
                  ),
                );
              },
            ),
    );
  }
}
