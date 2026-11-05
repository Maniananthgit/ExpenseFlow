import 'category_model.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final String type; // 'INCOME' or 'EXPENSE'
  final String? description;
  final DateTime transactionDate;
  final DateTime createdAt;
  final CategoryModel? category;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.type,
    this.description,
    required this.transactionDate,
    required this.createdAt,
    this.category,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      type: json['type'],
      description: json['description'],
      transactionDate: DateTime.parse(json['transaction_date']),
      createdAt: DateTime.parse(json['created_at']),
      category: json['category'] != null ? CategoryModel.fromJson(json['category']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'type': type,
      'description': description,
      'transaction_date': transactionDate.toIso8601String().substring(0, 10),
    };
  }

  bool get isIncome => type == 'INCOME';
}

class TransactionListResponse {
  final List<TransactionModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  TransactionListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory TransactionListResponse.fromJson(Map<String, dynamic> json) {
    return TransactionListResponse(
      items: (json['items'] as List).map((i) => TransactionModel.fromJson(i)).toList(),
      total: json['total'],
      page: json['page'],
      pageSize: json['page_size'],
      totalPages: json['total_pages'],
    );
  }
}

