import 'package:flutter_test/flutter_test.dart';
import 'package:sikas_josjis/main.dart';

void main() {
  testWidgets('SIKAS App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SikasApp());
    expect(find.text('SIKAS Mobile'), findsOneWidget);
  });
}
