import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _sb = Supabase.instance.client;

class AdminAportesScreen extends StatefulWidget {
  const AdminAportesScreen({super.key});

  @override
  State<AdminAportesScreen> createState() => _AdminAportesScreenState();
}

class _AdminAportesScreenState extends State<AdminAportesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const SizedBox(height: 40),
          const Text(
            "APORTES",
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
          TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: "DIEZMOS"),
              Tab(text: "OFRENDAS"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [_TabDiezmos(), _TabOfrendas()],
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// DIEZMOS CRUD
////////////////////////////////////////////////////////////
class _TabDiezmos extends StatefulWidget {
  const _TabDiezmos();

  @override
  State<_TabDiezmos> createState() => _TabDiezmosState();
}

class _TabDiezmosState extends State<_TabDiezmos> {
  List<Map<String, dynamic>> _diezmos = [];
  Map<int, String> _miembros = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final d = await _sb.from('diezmos').select().order('fecha');
    final m = await _sb.from('miembros').select('id,nombre');

    final map = <int, String>{};
    for (var item in m) {
      map[item['id']] = item['nombre'];
    }

    if (!mounted) return;

    setState(() {
      _diezmos = List<Map<String, dynamic>>.from(d);
      _miembros = map;
      _cargando = false;
    });
  }

  String nombre(int? id) => _miembros[id] ?? 'Sin nombre';

  Future<void> _eliminar(int id) async {
    await _sb.from('diezmos').delete().eq('id', id);
    _cargar();
  }

  Future<void> _guardar(Map<String, dynamic> data, {int? id}) async {
    if (id == null) {
      await _sb.from('diezmos').insert(data);
    } else {
      await _sb.from('diezmos').update(data).eq('id', id);
    }
    _cargar();
  }

  void _form({Map<String, dynamic>? d}) {
    final monto = TextEditingController(text: d?['monto']?.toString() ?? '');
    final fecha = TextEditingController(text: d?['fecha'] ?? '');
    int? miembroId = d?['id_miembro'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(d == null ? "Nuevo Diezmo" : "Editar"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<int>(
              value: miembroId,
              hint: const Text("Seleccionar miembro"),
              items: _miembros.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (v) => miembroId = v,
            ),
            TextField(
              controller: monto,
              decoration: const InputDecoration(labelText: "Monto"),
            ),
            TextField(
              controller: fecha,
              decoration: const InputDecoration(labelText: "Fecha"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              _guardar({
                'id_miembro': miembroId,
                'monto': double.tryParse(monto.text) ?? 0,
                'fecha': fecha.text,
              }, id: d?['id']);
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _form(),
          child: const Text("Registrar Diezmo"),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _diezmos.length,
            itemBuilder: (_, i) {
              final d = _diezmos[i];

              return ListTile(
                title: Text(
                  nombre(d['id_miembro']),
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  d['fecha'] ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Bs. ${d['monto']}"),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _form(d: d),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _eliminar(d['id']),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

////////////////////////////////////////////////////////////
/// OFRENDAS CRUD
////////////////////////////////////////////////////////////
class _TabOfrendas extends StatefulWidget {
  const _TabOfrendas();

  @override
  State<_TabOfrendas> createState() => _TabOfrendasState();
}

class _TabOfrendasState extends State<_TabOfrendas> {
  List<Map<String, dynamic>> _ofrendas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final data = await _sb.from('ofrendas').select();

    if (!mounted) return;

    setState(() {
      _ofrendas = List<Map<String, dynamic>>.from(data);
      _cargando = false;
    });
  }

  Future<void> _guardar(Map<String, dynamic> data, {int? id}) async {
    if (id == null) {
      await _sb.from('ofrendas').insert(data);
    } else {
      await _sb.from('ofrendas').update(data).eq('id', id);
    }
    _cargar();
  }

  Future<void> _eliminar(int id) async {
    await _sb.from('ofrendas').delete().eq('id', id);
    _cargar();
  }

  void _form({Map<String, dynamic>? o}) {
    final monto = TextEditingController(text: o?['monto']?.toString() ?? '');
    final fecha = TextEditingController(text: o?['fecha'] ?? '');
    String tipo = o?['tipo'] ?? 'general';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ofrenda"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              value: tipo,
              items: const [
                DropdownMenuItem(value: 'general', child: Text('General')),
                DropdownMenuItem(value: 'especial', child: Text('Especial')),
              ],
              onChanged: (v) => tipo = v!,
            ),
            TextField(controller: monto),
            TextField(controller: fecha),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _guardar({
                'tipo': tipo,
                'monto': double.tryParse(monto.text) ?? 0,
                'fecha': fecha.text,
              }, id: o?['id']);
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _form(),
          child: const Text("Registrar Ofrenda"),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _ofrendas.length,
            itemBuilder: (_, i) {
              final o = _ofrendas[i];

              return ListTile(
                title: Text(o['tipo']),
                subtitle: Text(o['fecha']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Bs. ${o['monto']}"),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _form(o: o),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _eliminar(o['id']),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
