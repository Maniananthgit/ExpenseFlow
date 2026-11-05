import 'package:flutter_test/flutter_test.dart';
import 'package:expense_flow/main.dart';

void main() {
  testWidgets('ExpenseFlowApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpenseFlowApp());
    expect(find.byType(ExpenseFlowApp), findsOneWidget);
  });
}
