import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  Future<BudgetSummaryModel> getBudgets({int? month, int? year}) async {
    final queryParams = <String, String>{};
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();

    final res = await ApiClient.get(ApiConstants.budgets, queryParams: queryParams);
    return BudgetSummaryModel.fromJson(res);
  }

  Future<BudgetModel> createBudget({
    required String categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
    final res = await ApiClient.post(
      ApiConstants.budgets,
      body: {
        'category_id': categoryId,
        'amount': amount,
        'month': month,
        'year': year,
      },
    );
    return BudgetModel.fromJson(res);
  }

  Future<BudgetModel> updateBudget({
    required String id,
    double? amount,
    String? categoryId,
    int? month,
    int? year,
  }) async {
    final body = <String, dynamic>{};
    if (amount != null) body['amount'] = amount;
    if (categoryId != null) body['category_id'] = categoryId;
    if (month != null) body['month'] = month;
    if (year != null) body['year'] = year;

    final res = await ApiClient.put('${ApiConstants.budgets}/$id', body: body);
    return BudgetModel.fromJson(res);
  }

  Future<void> deleteBudget(String id) async {
    await ApiClient.delete('${ApiConstants.budgets}/$id');
  }
}

