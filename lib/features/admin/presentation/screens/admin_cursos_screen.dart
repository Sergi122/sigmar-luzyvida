import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sigmar_page.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFF7F77DD);
const _diasSemana = [
  'lunes',
  'martes',
  'miercoles',
  'jueves',
  'viernes',
  'sabado',
  'domingo',
];

class AdminCursosScreen extends StatefulWidget {
  const AdminCursosScreen({super.key});
  @override
  State<AdminCursosScreen> createState() => _AdminCursosScreenState();
}

class _AdminCursosScreenState extends State<AdminCursosScreen> {
  List<Map<String, dynamic>> _cursos = [];
  bool _cargando = true;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      // ✅ join con miembros para obtener nombre del guia via id_guia
      final data = await _sb
          .from('cursos')
          .select('*, miembros!cursos_id_guia_fkey(nombre)')
          .order('nombre');
      setState(() {
        _cursos = List<Map<String, dynamic>>.from(data);
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  List<Map<String, dynamic>> get _filtrados {
    if (_busqueda.isEmpty) return _cursos;
    return _cursos
        .where(
          (c) => (c['nombre'] ?? '').toLowerCase().contains(
            _busqueda.toLowerCase(),
          ),
        )
        .toList();
  }

  void _abrirFormulario({Map<String, dynamic>? curso}) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormCurso(curso: curso),
    );
    if (ok == true) _cargar();
  }

  Future<void> _eliminar(Map<String, dynamic> c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogConfirm(
        titulo: 'Eliminar curso',
        mensaje: '¿Eliminar el curso "${c['nombre']}"?',
      ),
    );
    if (ok != true) return;
    await _sb.from('cursos').delete().eq('id', c['id']);
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Curso eliminado'),
          backgroundColor: kSuccess,
        ),
      );
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return SigmarPage(
      rutaActual: '/admin/cursos',
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _kColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: _kColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestion de Cursos',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Administrar cursos y aulas',
                        style: TextStyle(color: kGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _abrirFormulario(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Nuevo Curso',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 50, height: 3, color: _kColor),
            const SizedBox(height: 20),
            TextField(
              onChanged: (v) => setState(() => _busqueda = v),
              style: const TextStyle(color: kWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar curso...',
                hintStyle: const TextStyle(color: kGrey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: kGrey, size: 18),
                filled: true,
                fillColor: kBgCard,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
              ),
            ),
            const SizedBox(height: 16),
            if (_cargando)
              const Center(child: CircularProgressIndicator(color: _kColor))
            else if (_filtrados.isEmpty)
              const Center(
                child: Text(
                  'No hay cursos registrados',
                  style: TextStyle(color: kGrey),
                ),
              )
            else
              ...(_filtrados.map((c) {
                final guiaNombre =
                    (c['miembros'] as Map?)?['nombre'] ?? 'Sin guía';
                final activo = c['estado'] == 'activo';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kBgMid,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kDivider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kColor.withValues(alpha: 0.15),
                          border: Border.all(
                            color: _kColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            (c['nombre'] ?? 'C')[0].toUpperCase(),
                            style: const TextStyle(
                              color: _kColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  c['nombre'] ?? '',
                                  style: const TextStyle(
                                    color: kWhite,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (activo ? kSuccess : kDanger)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    c['estado'] ?? '',
                                    style: TextStyle(
                                      color: activo ? kSuccess : kDanger,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  color: kGrey,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Guía: $guiaNombre',
                                  style: const TextStyle(
                                    color: kGrey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.room_outlined,
                                  color: kGrey,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  c['aula'] ?? '',
                                  style: const TextStyle(
                                    color: kGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: kGrey,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${c['dia_semana'] ?? ''} ${c['hora'] ?? ''}',
                                  style: const TextStyle(
                                    color: kGrey,
                                    fontSize: 12,
                                  ),
                                ),
                                if (c['horas'] != null) ...[
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.access_time_outlined,
                                    color: kGrey,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${c['horas']}h',
                                    style: const TextStyle(
                                      color: kGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        color: kBgCard,
                        icon: const Icon(
                          Icons.more_vert,
                          color: kGrey,
                          size: 20,
                        ),
                        onSelected: (v) {
                          if (v == 'editar') _abrirFormulario(curso: c);
                          if (v == 'borrar') _eliminar(c);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'editar',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  color: _kColor,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Editar',
                                  style: TextStyle(color: kWhite, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'borrar',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: kDanger,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Eliminar',
                                  style: TextStyle(
                                    color: kDanger,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              })),
          ],
        ),
      ),
    );
  }
}

class _FormCurso extends StatefulWidget {
  final Map<String, dynamic>? curso;
  const _FormCurso({this.curso});
  @override
  State<_FormCurso> createState() => _FormCursoState();
}

class _FormCursoState extends State<_FormCurso> {
  final _nombreCtrl = TextEditingController();
  final _aulaCtrl = TextEditingController();
  final _horasCtrl = TextEditingController();
  final _horaCtrl = TextEditingController();
  String? _diaSemana;
  String _estado = 'activo';
  int? _idGuia;
  List<Map<String, dynamic>> _miembros = [];
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.curso != null;

  @override
  void initState() {
    super.initState();
    _cargarMiembros();
    if (_esEdicion) {
      final c = widget.curso!;
      _nombreCtrl.text = c['nombre'] ?? '';
      _aulaCtrl.text = c['aula'] ?? '';
      _horasCtrl.text = '${c['horas'] ?? ''}';
      _horaCtrl.text = c['hora'] ?? '';
      // ✅ dia_semana, id_guia
      _diaSemana = c['dia_semana'];
      _estado = c['estado'] ?? 'activo';
      _idGuia = c['id_guia'] as int?;
    }
  }

  Future<void> _cargarMiembros() async {
    final data = await _sb
        .from('miembros')
        .select('id, nombre')
        .eq('estado', 'activo')
        .order('nombre');
    setState(() => _miembros = List<Map<String, dynamic>>.from(data));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _aulaCtrl.dispose();
    _horasCtrl.dispose();
    _horaCtrl.dispose();
    super.dispose();
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
    // ✅ snake_case: dia_semana, id_guia
    final datos = {
      'nombre': _nombreCtrl.text.trim(),
      'aula': _aulaCtrl.text.trim(),
      'horas': int.tryParse(_horasCtrl.text.trim()),
      'hora': _horaCtrl.text.trim(),
      'dia_semana': _diaSemana,
      'id_guia': _idGuia,
      'estado': _estado,
    };
    try {
      if (_esEdicion) {
        await _sb.from('cursos').update(datos).eq('id', widget.curso!['id']);
      } else {
        await _sb.from('cursos').insert(datos);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBgMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 520,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _kColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: _kColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _esEdicion ? 'Editar Curso' : 'Nuevo Curso',
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 17,
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
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _c(
                      'Nombre del curso *',
                      _nombreCtrl,
                      Icons.school_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _c('Aula', _aulaCtrl, Icons.room_outlined),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _c(
                            'Horas totales',
                            _horasCtrl,
                            Icons.access_time_outlined,
                            tipo: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kDivider),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _diaSemana,
                          isExpanded: true,
                          dropdownColor: kBgCard,
                          hint: const Text(
                            'Día de clase',
                            style: TextStyle(color: kGrey, fontSize: 13),
                          ),
                          style: const TextStyle(color: kWhite, fontSize: 14),
                          onChanged: (v) => setState(() => _diaSemana = v),
                          items: _diasSemana
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d.toUpperCase()),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _c(
                      'Hora (ej: 18:00)',
                      _horaCtrl,
                      Icons.access_time_outlined,
                    ),
                    const SizedBox(height: 12),
                    // ✅ id_guia
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kDivider),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _idGuia,
                          isExpanded: true,
                          dropdownColor: kBgCard,
                          hint: const Text(
                            'Asignar guía',
                            style: TextStyle(color: kGrey, fontSize: 13),
                          ),
                          style: const TextStyle(color: kWhite, fontSize: 14),
                          onChanged: (v) => setState(() => _idGuia = v),
                          items: _miembros
                              .map(
                                (m) => DropdownMenuItem<int>(
                                  value: m['id'] as int,
                                  child: Text(
                                    m['nombre'] ?? '',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kDivider),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _estado,
                          isExpanded: true,
                          dropdownColor: kBgCard,
                          style: const TextStyle(color: kWhite, fontSize: 14),
                          onChanged: (v) => setState(() => _estado = v!),
                          items: const [
                            DropdownMenuItem(
                              value: 'activo',
                              child: Text('Activo'),
                            ),
                            DropdownMenuItem(
                              value: 'inactivo',
                              child: Text('Inactivo'),
                            ),
                            DropdownMenuItem(
                              value: 'finalizado',
                              child: Text('Finalizado'),
                            ),
                          ],
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
                        child: Text(
                          _error!,
                          style: const TextStyle(color: kDanger, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                border: Border(top: BorderSide(color: kDivider)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kGrey,
                      side: const BorderSide(color: kDivider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _esEdicion ? 'Guardar cambios' : 'Crear curso',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _c(
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
        borderSide: const BorderSide(color: _kColor, width: 2),
      ),
    ),
  );
}

class _DialogConfirm extends StatelessWidget {
  final String titulo, mensaje;
  const _DialogConfirm({required this.titulo, required this.mensaje});
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: kBgMid,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: kWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(mensaje, style: const TextStyle(color: kGrey, fontSize: 13)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kGrey,
                  side: const BorderSide(color: kDivider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDanger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
