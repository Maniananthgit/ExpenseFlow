import 'category_model.dart';

class BudgetModel {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final int month;
  final int year;
  final CategoryModel? category;
  final double spentAmount;
  final double remainingAmount;
  final double utilizationPercentage;
  final bool isExceeded;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
    this.category,
    required this.spentAmount,
    required this.remainingAmount,
    required this.utilizationPercentage,
    required this.isExceeded,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      month: json['month'],
      year: json['year'],
      category: json['category'] != null ? CategoryModel.fromJson(json['category']) : null,
      spentAmount: double.tryParse(json['spent_amount'].toString()) ?? 0.0,
      remainingAmount: double.tryParse(json['remaining_amount'].toString()) ?? 0.0,
      utilizationPercentage: (json['utilization_percentage'] as num?)?.toDouble() ?? 0.0,
      isExceeded: json['is_exceeded'] ?? false,
    );
  }
}

class BudgetSummaryModel {
  final double totalBudget;
  final double totalSpent;
  final double totalRemaining;
  final double overallUtilization;
  final List<BudgetModel> budgets;

  BudgetSummaryModel({
    required this.totalBudget,
    required this.totalSpent,
    required this.totalRemaining,
    required this.overallUtilization,
    required this.budgets,
  });

  factory BudgetSummaryModel.fromJson(Map<String, dynamic> json) {
    return BudgetSummaryModel(
      totalBudget: double.tryParse(json['total_budget'].toString()) ?? 0.0,
      totalSpent: double.tryParse(json['total_spent'].toString()) ?? 0.0,
      totalRemaining: double.tryParse(json['total_remaining'].toString()) ?? 0.0,
      overallUtilization: (json['overall_utilization'] as num?)?.toDouble() ?? 0.0,
      budgets: (json['budgets'] as List).map((b) => BudgetModel.fromJson(b)).toList(),
    );
  }
}

