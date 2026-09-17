import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('SmartBudgetApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartBudgetApp());
    expect(find.byType(SmartBudgetApp), findsOneWidget);
  });
}
