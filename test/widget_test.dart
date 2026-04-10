import 'package:flutter_test/flutter_test.dart';
import 'package:netscope/main.dart';

void main() {
  testWidgets('NetScope app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NetScopeApp());
    expect(find.text('NetScope'), findsOneWidget);
  });
}
