import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  Future<TransactionListResponse> getTransactions({
    String? type,
    String? categoryId,
    String? startDate,
    String? endDate,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (type != null) queryParams['type'] = type;
    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final res = await ApiClient.get(ApiConstants.transactions, queryParams: queryParams);
    return TransactionListResponse.fromJson(res);
  }

  Future<TransactionModel> createTransaction({
    required String categoryId,
    required double amount,
    required String type,
    String? description,
    required String transactionDate,
  }) async {
    final res = await ApiClient.post(
      ApiConstants.transactions,
      body: {
        'category_id': categoryId,
        'amount': amount,
        'type': type,
        'description': description,
        'transaction_date': transactionDate,
      },
    );
    return TransactionModel.fromJson(res);
  }

  Future<TransactionModel> updateTransaction({
    required String id,
    String? categoryId,
    double? amount,
    String? type,
    String? description,
    String? transactionDate,
  }) async {
    final body = <String, dynamic>{};
    if (categoryId != null) body['category_id'] = categoryId;
    if (amount != null) body['amount'] = amount;
    if (type != null) body['type'] = type;
    if (description != null) body['description'] = description;
    if (transactionDate != null) body['transaction_date'] = transactionDate;

    final res = await ApiClient.put('${ApiConstants.transactions}/$id', body: body);
    return TransactionModel.fromJson(res);
  }

  Future<void> deleteTransaction(String id) async {
    await ApiClient.delete('${ApiConstants.transactions}/$id');
  }
}

