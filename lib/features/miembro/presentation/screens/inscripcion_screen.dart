import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/session.dart';
import '../../../../shared/widgets/dashboard_shell.dart';

final _sb = Supabase.instance.client;
const _kColor = Color(0xFF1D9E75); // verde miembro

// ══════════════════════════════════════════════════════
//  PANTALLA PRINCIPAL
// ══════════════════════════════════════════════════════
class MiembroInscripcionScreen extends StatefulWidget {
  const MiembroInscripcionScreen({super.key});

  @override
  State<MiembroInscripcionScreen> createState() =>
      _MiembroInscripcionScreenState();
}

class _MiembroInscripcionScreenState extends State<MiembroInscripcionScreen> {
  List<Map<String, dynamic>> _cursos = [];
  List<Map<String, dynamic>> _misInscripciones = [];
  bool _cargando = true;
  String _busqueda = '';
  String _filtro =
      'disponibles'; // 'disponibles' | 'mis_cursos' | 'completados'

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final miembroId = AppSession.miembroId;
      if (miembroId == null) {
        setState(() => _cargando = false);
        return;
      }

      final cursosData = await _sb
          .from('cursos')
          .select('''
            *,
            miembros(nombre),
            curso_requisitos!curso_requisitos_id_curso_fkey(
              id_curso_prerequisito,
              requiere_bautismo,
              requiere_encuentro
            )
          ''')
          .eq('estado', 'activo')
          .order('nombre');

      final inscripcionesData = await _sb
          .from('inscripciones')
          .select('''
            *,
            cursos(id, nombre),
            periodos_curso(nombre)
          ''')
          .eq('id_miembro', miembroId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _cursos = List<Map<String, dynamic>>.from(cursosData);
          _misInscripciones = List<Map<String, dynamic>>.from(
            inscripcionesData,
          );
          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando: $e');
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _msg(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: error ? kDanger : kSuccess),
    );
  }

  bool _cumpleRequisitos(Map<String, dynamic> curso) {
    final miembro = AppSession.miembro;
    if (miembro == null) return false;

    final requisitos = List<Map<String, dynamic>>.from(
      (curso['curso_requisitos'] as List?) ?? [],
    );

    for (final req in requisitos) {
      final cursoPreId = req['id_curso_prerequisito'] as int?;
      if (cursoPreId != null) {
        final completado = _misInscripciones.any(
          (ins) =>
              (ins['cursos'] as Map?)?['id'] == cursoPreId &&
              (ins['estado'] as String) == 'completado',
        );
        if (!completado) return false;
      }
      if (req['requiere_bautismo'] == true && miembro['bautizado'] != true) {
        return false;
      }
      if (req['requiere_encuentro'] == true &&
          miembro['asistio_encuentro'] != true) {
        return false;
      }
    }
    return true;
  }

  bool _yaInscrito(int cursoId) {
    return _misInscripciones.any(
      (ins) =>
          (ins['cursos'] as Map?)?['id'] == cursoId &&
          (ins['estado'] as String) == 'activo',
    );
  }

  Future<void> _inscribirse(Map<String, dynamic> curso) async {
    final miembroId = AppSession.miembroId;
    if (miembroId == null) {
      _msg('No hay miembro vinculado', error: true);
      return;
    }
    if (!_cumpleRequisitos(curso)) {
      _msg('No cumples los requisitos para este curso', error: true);
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogConfirmarInscripcion(curso: curso),
    );
    if (confirmado != true) return;

    try {
      await _sb.from('inscripciones').insert({
        'id_miembro': miembroId,
        'id_curso': curso['id'],
        'estado': 'activo',
      });
      _msg('¡Inscripción realizada con éxito!');
      _cargar();
    } catch (e) {
      _msg('Error al inscribirse: $e', error: true);
    }
  }

  List<Map<String, dynamic>> get _cursosFiltrados {
    switch (_filtro) {
      case 'mis_cursos':
        return _cursos.where((c) => _yaInscrito(c['id'] as int)).toList();
      case 'completados':
        return _misInscripciones
            .where((ins) => (ins['estado'] as String) == 'completado')
            .map(
              (ins) => {
                ...(ins['cursos'] as Map<String, dynamic>? ?? {}),
                '_periodo':
                    (ins['periodos_curso'] as Map?)?['nombre'] as String?,
              },
            )
            .toList();
      default: // disponibles
        return _cursos.where((c) => !_yaInscrito(c['id'] as int)).where((c) {
          if (_busqueda.isEmpty) return true;
          return (c['nombre'] ?? '').toString().toLowerCase().contains(
            _busqueda.toLowerCase(),
          );
        }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _cursosFiltrados;
    final miembroId = AppSession.miembroId;

    return DashboardShell(
      nombreUsuario: AppSession.nombre,
      rol: AppSession.rol,
      menuItems: const [
        // ¡CÓDIGO CORREGIDO AQUÍ! (String primero, IconData después)
        MenuItemData('Inicio', Icons.home),
        MenuItemData('Inscripción', Icons.school),
      ],
      indiceActivo: 1,
      onMenuTap: (i) {
        if (i == 0) Navigator.pushReplacementNamed(context, '/');
      },
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
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
                        'Inscripción a Cursos',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Inscríbete a los cursos disponibles',
                        style: TextStyle(color: kGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 50, height: 3, color: _kColor),
            const SizedBox(height: 20),

            // ── Tabs de filtro ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TabFiltro(
                    etiqueta: 'Disponibles',
                    icono: Icons.add_circle_outline,
                    activo: _filtro == 'disponibles',
                    onTap: () => setState(() => _filtro = 'disponibles'),
                  ),
                  const SizedBox(width: 8),
                  _TabFiltro(
                    etiqueta: 'Mis Cursos',
                    icono: Icons.list,
                    activo: _filtro == 'mis_cursos',
                    onTap: () => setState(() => _filtro = 'mis_cursos'),
                  ),
                  const SizedBox(width: 8),
                  _TabFiltro(
                    etiqueta: 'Completados',
                    icono: Icons.check_circle_outline,
                    activo: _filtro == 'completados',
                    onTap: () => setState(() => _filtro = 'completados'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Búsqueda (solo en disponibles) ──
            if (_filtro == 'disponibles') ...[
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
              const SizedBox(height: 8),
            ],

            Text(
              '${lista.length} '
              '${_filtro == 'completados' ? 'curso(s) completado(s)' : (_filtro == 'mis_cursos' ? 'curso(s) activo(s)' : 'curso(s) disponible(s)')}',
              style: const TextStyle(color: kGrey, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // ── Lista ──
            if (_cargando || miembroId == null)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: _kColor)),
              )
            else if (lista.isEmpty)
              _EmptyState(filtro: _filtro, busqueda: _busqueda)
            else
              Expanded(
                child: ListView.builder(
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    if (_filtro == 'completados') {
                      return _TarjetaCursoCompletado(curso: lista[i]);
                    }
                    return _TarjetaCurso(
                      curso: lista[i],
                      cumpleRequisitos: _cumpleRequisitos(lista[i]),
                      yaInscrito: _yaInscrito(lista[i]['id'] as int),
                      misInscripciones: _misInscripciones,
                      todosCursos: _cursos,
                      onInscribirse: () => _inscribirse(lista[i]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  TAB DE FILTRO
// ══════════════════════════════════════════════════════
class _TabFiltro extends StatelessWidget {
  final String etiqueta;
  final IconData icono;
  final bool activo;
  final VoidCallback onTap;

  const _TabFiltro({
    required this.etiqueta,
    required this.icono,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: activo ? _kColor : kBgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: activo ? _kColor : kDivider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: activo ? kWhite : kGrey, size: 16),
            const SizedBox(width: 6),
            Text(
              etiqueta,
              style: TextStyle(
                color: activo ? kWhite : kGrey,
                fontSize: 13,
                fontWeight: activo ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  TARJETA DE CURSO (disponible / activo)
// ══════════════════════════════════════════════════════
class _TarjetaCurso extends StatelessWidget {
  final Map<String, dynamic> curso;
  final bool cumpleRequisitos;
  final bool yaInscrito;
  final List<Map<String, dynamic>> misInscripciones;
  final List<Map<String, dynamic>> todosCursos;
  final VoidCallback onInscribirse;

  const _TarjetaCurso({
    required this.curso,
    required this.cumpleRequisitos,
    required this.yaInscrito,
    required this.misInscripciones,
    required this.todosCursos,
    required this.onInscribirse,
  });

  @override
  Widget build(BuildContext context) {
    final guiaNombre = (curso['miembros'] as Map?)?['nombre'] ?? 'Sin guía';
    final puedeInscribirse = cumpleRequisitos && !yaInscrito;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgMid,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: yaInscrito ? kGold : (puedeInscribirse ? kSuccess : kDivider),
          width: yaInscrito || puedeInscribirse ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (yaInscrito ? kGold : kSuccess).withValues(
                    alpha: 0.12,
                  ),
                  border: Border.all(
                    color: (yaInscrito ? kGold : kSuccess).withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    (curso['nombre'] ?? 'C')[0].toUpperCase(),
                    style: TextStyle(
                      color: yaInscrito ? kGold : kSuccess,
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
                    Text(
                      curso['nombre'] ?? '',
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
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
                          style: const TextStyle(color: kGrey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _InfoCurso(curso: curso),
          const SizedBox(height: 8),

          _Requisitos(
            curso: curso,
            misInscripciones: misInscripciones,
          ),

          const SizedBox(height: 12),

          // Botón
          if (!yaInscrito)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cumpleRequisitos ? onInscribirse : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: puedeInscribirse ? kSuccess : kBgCard,
                  foregroundColor: puedeInscribirse ? kWhite : kGrey,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  cumpleRequisitos
                      ? 'Inscribirme al curso'
                      : 'No cumples los requisitos',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: kGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: kGold, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Ya estás inscrito',
                    style: TextStyle(color: kGold, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  TARJETA DE CURSO COMPLETADO
// ══════════════════════════════════════════════════════
class _TarjetaCursoCompletado extends StatelessWidget {
  final Map<String, dynamic> curso;

  const _TarjetaCursoCompletado({required this.curso});

  @override
  Widget build(BuildContext context) {
    final periodo = curso['_periodo'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgMid,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kSuccess.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kSuccess.withValues(alpha: 0.12),
              border: Border.all(color: kSuccess.withValues(alpha: 0.4)),
            ),
            child: const Center(
              child: Icon(Icons.check_circle, color: kSuccess, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  curso['nombre'] ?? '',
                  style: const TextStyle(
                    color: kWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (periodo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Período: $periodo',
                    style: const TextStyle(color: kGrey, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.archive, color: kGrey, size: 20),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  INFO DEL CURSO
// ══════════════════════════════════════════════════════
class _InfoCurso extends StatelessWidget {
  final Map<String, dynamic> curso;

  const _InfoCurso({required this.curso});

  @override
  Widget build(BuildContext context) {
    final c = curso;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: kGrey, size: 12),
            const SizedBox(width: 4),
            Text(
              (c['dia_semana'] ?? '-').toString().capitalize(),
              style: const TextStyle(color: kGrey, fontSize: 12),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.access_time_outlined, color: kGrey, size: 12),
            const SizedBox(width: 4),
            Text(
              c['hora'] ?? '-',
              style: const TextStyle(color: kGrey, fontSize: 12),
            ),
            if (c['aula'] != null && (c['aula'] as String).isNotEmpty) ...[
              const SizedBox(width: 12),
              const Icon(Icons.room_outlined, color: kGrey, size: 12),
              const SizedBox(width: 4),
              Text(
                c['aula'] as String,
                style: const TextStyle(color: kGrey, fontSize: 12),
              ),
            ],
          ],
        ),
        if (c['horas'] != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.book_outlined, color: kGold, size: 12),
              const SizedBox(width: 4),
              Text(
                'Duración: ${c['horas']} horas',
                style: const TextStyle(color: kGold, fontSize: 12),
              ),
            ],
          ),
        ],
        if (c['precio_curso'] != null && (c['precio_curso'] as num) > 0) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.attach_money, color: kGold, size: 12),
              const SizedBox(width: 4),
              Text(
                'Curso: Bs ${(c['precio_curso'] as num).toStringAsFixed(2)}',
                style: const TextStyle(color: kGold, fontSize: 12),
              ),
            ],
          ),
        ],
        if (c['precio_libro'] != null && (c['precio_libro'] as num) > 0) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.book_outlined, color: kGold, size: 12),
              const SizedBox(width: 4),
              Text(
                'Libro: Bs ${(c['precio_libro'] as num).toStringAsFixed(2)}',
                style: const TextStyle(color: kGold, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════
//  REQUISITOS DEL CURSO
// ══════════════════════════════════════════════════════
class _Requisitos extends StatelessWidget {
  final Map<String, dynamic> curso;
  final List<Map<String, dynamic>> misInscripciones;

  const _Requisitos({
    required this.curso,
    required this.misInscripciones,
  });

  @override
  Widget build(BuildContext context) {
    final requisitos = List<Map<String, dynamic>>.from(
      (curso['curso_requisitos'] as List?) ?? [],
    );
    final miembro = AppSession.miembro;

    if (requisitos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: kSuccess, size: 14),
            SizedBox(width: 6),
            Text(
              'Sin requisitos previos',
              style: TextStyle(color: kSuccess, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final widgets = <Widget>[];
    for (final req in requisitos) {
      final cursoPreId = req['id_curso_prerequisito'] as int?;
      final requiereBautismo = req['requiere_bautismo'] == true;
      final requiereEncuentro = req['requiere_encuentro'] == true;

      if (cursoPreId != null) {
        // Buscar si completó el curso prerequisito
        final completado = misInscripciones.any((ins) =>
            (ins['cursos'] as Map?)?['id'] == cursoPreId &&
            (ins['estado'] as String) == 'completado');
        final nombrePre = (curso['curso_requisitos'] as List?)
                ?.firstWhere(
                  (r) => r['id_curso_prerequisito'] == cursoPreId,
                  orElse: () => null,
                )?['curso_prerequisito_nombre'] ??
            'Curso #$cursoPreId';
        widgets.add(
          _RequisitoItem(
            texto: 'Completar: $nombrePre',
            cumple: completado,
          ),
        );
      }

      if (requiereBautismo) {
        widgets.add(
          _RequisitoItem(
            texto: 'Estar bautizado',
            cumple: miembro?['bautizado'] == true,
          ),
        );
      }

      if (requiereEncuentro) {
        widgets.add(
          _RequisitoItem(
            texto: 'Haber asistido al encuentro',
            cumple: miembro?['asistio_encuentro'] == true,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 2),
          child: Text(
            'Requisitos:',
            style: TextStyle(
              color: kGrey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...widgets,
      ],
    );
  }
}

class _RequisitoItem extends StatelessWidget {
  final String texto;
  final bool cumple;

  const _RequisitoItem({required this.texto, required this.cumple});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(
            cumple ? Icons.check_circle : Icons.radio_button_unchecked,
            color: cumple ? kSuccess : kDanger,
            size: 14,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(color: cumple ? kSuccess : kGrey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  EMPTY STATE
// ══════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final String filtro;
  final String busqueda;

  const _EmptyState({required this.filtro, required this.busqueda});

  @override
  Widget build(BuildContext context) {
    late IconData icono;
    late String mensaje;

    if (filtro == 'disponibles') {
      icono = busqueda.isNotEmpty ? Icons.search_off : Icons.school_outlined;
      mensaje = busqueda.isNotEmpty
          ? 'No hay cursos que coincidan con "$busqueda"'
          : 'No hay cursos disponibles en este momento';
    } else if (filtro == 'mis_cursos') {
      icono = Icons.list;
      mensaje = 'No estás inscrito en ningún curso activo';
    } else {
      icono = Icons.check_circle_outline;
      mensaje = 'Aún no has completado ningún curso';
    }

    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 64, color: kDivider),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kGrey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  DIALOG CONFIRMAR INSCRIPCIÓN
// ══════════════════════════════════════════════════════
class _DialogConfirmarInscripcion extends StatelessWidget {
  final Map<String, dynamic> curso;

  const _DialogConfirmarInscripcion({required this.curso});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kBgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Confirmar Inscripción',
        style: TextStyle(color: kWhite, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Deseas inscribirte al curso:',
            style: TextStyle(color: kGrey),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBgMid,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kGold.withValues(alpha: 0.3)),
            ),
            child: Text(
              curso['nombre'] ?? '',
              style: const TextStyle(
                color: kWhite,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Una vez inscrito, podrás acceder al contenido del curso.',
            style: TextStyle(color: kGrey, fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: kGrey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: kSuccess,
            foregroundColor: kWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Inscribirme',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
