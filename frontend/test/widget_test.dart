import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_flow/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ExpenseFlowApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ExpenseFlowApp());
    expect(find.byType(ExpenseFlowApp), findsOneWidget);
  });
}
