import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_flow/core/storage/local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageManager.ensureInitialized();
  });

  test('LocalStorageManager initialization seeds default categories and transactions', () async {
    final categories = await LocalStorageManager.getCategories();
    expect(categories.length, greaterThanOrEqualTo(8));

    final txs = await LocalStorageManager.getTransactions();
    expect(txs['total'], greaterThanOrEqualTo(4));
  });

  test('Adding transaction saves and recalculates dashboard summary and budget utilization', () async {
    final initialSummary = await LocalStorageManager.getDashboardSummary();
    final initialIncome = double.parse(initialSummary['total_income']);

    // Create a new income
    final newTx = await LocalStorageManager.createTransaction({
      'amount': 25000.0,
      'type': 'INCOME',
      'category_id': 'cat-inc-1',
      'description': 'Consulting Gig',
      'transaction_date': DateTime.now().toIso8601String().substring(0, 10),
    });

    expect(newTx['id'], startsWith('tx-'));

    // Check transactions list
    final txsAfter = await LocalStorageManager.getTransactions();
    expect(txsAfter['items'].first['description'], equals('Consulting Gig'));

    // Check dashboard summary
    final updatedSummary = await LocalStorageManager.getDashboardSummary();
    final updatedIncome = double.parse(updatedSummary['total_income']);
    expect(updatedIncome, equals(initialIncome + 25000.0));

    // Create an expense
    await LocalStorageManager.createTransaction({
      'amount': 1500.0,
      'type': 'EXPENSE',
      'category_id': 'cat-exp-1',
      'description': 'Coffee & Snacks',
      'transaction_date': DateTime.now().toIso8601String().substring(0, 10),
    });

    // Check budget utilization updated
    final budgets = await LocalStorageManager.getBudgets();
    final foodBudget = (budgets['budgets'] as List).firstWhere((b) => b['category_id'] == 'cat-exp-1');
    expect(double.parse(foodBudget['spent_amount']), greaterThanOrEqualTo(1500.0));

    // Check CSV export contains the new record
    final csv = await LocalStorageManager.exportCsv();
    expect(csv.contains('Consulting Gig'), isTrue);
    expect(csv.contains('Coffee & Snacks'), isTrue);
  });
}

