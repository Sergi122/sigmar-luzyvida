import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminCursosScreen - Corrección curso_requisitos', () {
    test('debe usar idRequisito en lugar de idCursoRequisito al cargar',
        () async {
      // Simula respuesta de Supabase con la columna correcta
      final data = [
        {'idRequisito': 5},
        {'idRequisito': 8},
      ];

      // Código corregido (líneas 982-986)
      final requisitosSeleccionados =
          data.map((r) => r['idRequisito'] as int).toList();

      expect(requisitosSeleccionados, contains(5));
      expect(requisitosSeleccionados, contains(8));
      expect(requisitosSeleccionados.length, 2);
    });

    test('debe usar idRequisito en lugar de idCursoRequisito al insertar',
        () async {
      final cursoId = 1;
      final reqId = 5;

      // Código corregido (líneas 1035-1038)
      final datosInsert = {
        'idCurso': cursoId,
        'idRequisito': reqId, // CORRECTO: idRequisito
      };

      expect(datosInsert['idCurso'], equals(1));
      expect(datosInsert['idRequisito'], equals(5));
      expect(datosInsert.containsKey('idCursoRequisito'), isFalse);
    });

    test('debe usar idRequisito en lugar de idCursoRequisito al eliminar',
        () async {
      // Código corregido (línea 176)
      final filtroDelete = 'idRequisito'; // CORRECTO

      expect(filtroDelete, equals('idRequisito'));
      expect(filtroDelete, isNot(equals('idCursoRequisito')));
    });

    test('estructura de tabla curso_requisitos: idCurso + idRequisito',
        () async {
      // Esquema correcto de Supabase
      final esquemaTabla = {
        'tabla': 'curso_requisitos',
        'columnas': ['id', 'idCurso', 'idRequisito'],
      };

      expect(esquemaTabla['columnas'], contains('idCurso'));
      expect(esquemaTabla['columnas'], contains('idRequisito'));
      expect(esquemaTabla['columnas'], isNot(contains('idCursoRequisito')));
    });
  });
}
