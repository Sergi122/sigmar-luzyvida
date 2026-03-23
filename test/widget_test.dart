import 'package:flutter_test/flutter_test.dart';
import 'package:luzyvida/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SigmarApp());
    expect(find.text('Luz y Vida'), findsWidgets);
  });
}
