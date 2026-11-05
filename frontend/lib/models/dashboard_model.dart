import 'transaction_model.dart';

class CategoryBreakdownItemModel {
  final String categoryId;
  final String categoryName;
  final String categoryColor;
  final String categoryIcon;
  final double totalAmount;
  final double percentage;
  final int transactionCount;

  CategoryBreakdownItemModel({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.totalAmount,
    required this.percentage,
    required this.transactionCount,
  });

  factory CategoryBreakdownItemModel.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdownItemModel(
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      categoryColor: json['category_color'] ?? '#3B82F6',
      categoryIcon: json['category_icon'] ?? 'category',
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      transactionCount: json['transaction_count'] ?? 0,
    );
  }
}

class MonthlyTrendItemModel {
  final int month;
  final String monthName;
  final int year;
  final double income;
  final double expense;
  final double netSavings;

  MonthlyTrendItemModel({
    required this.month,
    required this.monthName,
    required this.year,
    required this.income,
    required this.expense,
    required this.netSavings,
  });

  factory MonthlyTrendItemModel.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendItemModel(
      month: json['month'],
      monthName: json['month_name'],
      year: json['year'],
      income: double.tryParse(json['income'].toString()) ?? 0.0,
      expense: double.tryParse(json['expense'].toString()) ?? 0.0,
      netSavings: double.tryParse(json['net_savings'].toString()) ?? 0.0,
    );
  }
}

class DashboardSummaryModel {
  final String currency;
  final double totalIncome;
  final double totalExpenses;
  final double currentBalance;
  final double monthlyIncome;
  final double monthlySpending;
  final double monthlySavings;
  final double savingsRate;
  final List<TransactionModel> recentTransactions;

  DashboardSummaryModel({
    required this.currency,
    required this.totalIncome,
    required this.totalExpenses,
    required this.currentBalance,
    required this.monthlyIncome,
    required this.monthlySpending,
    required this.monthlySavings,
    required this.savingsRate,
    required this.recentTransactions,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      currency: json['currency'] ?? 'INR',
      totalIncome: double.tryParse(json['total_income'].toString()) ?? 0.0,
      totalExpenses: double.tryParse(json['total_expenses'].toString()) ?? 0.0,
      currentBalance: double.tryParse(json['current_balance'].toString()) ?? 0.0,
      monthlyIncome: double.tryParse(json['monthly_income'].toString()) ?? 0.0,
      monthlySpending: double.tryParse(json['monthly_spending'].toString()) ?? 0.0,
      monthlySavings: double.tryParse(json['monthly_savings'].toString()) ?? 0.0,
      savingsRate: (json['savings_rate'] as num?)?.toDouble() ?? 0.0,
      recentTransactions: (json['recent_transactions'] as List)
          .map((t) => TransactionModel.fromJson(t))
          .toList(),
    );
  }
}

class DashboardCategoryBreakdownModel {
  final String currency;
  final int month;
  final int year;
  final List<CategoryBreakdownItemModel> incomeCategories;
  final List<CategoryBreakdownItemModel> expenseCategories;

  DashboardCategoryBreakdownModel({
    required this.currency,
    required this.month,
    required this.year,
    required this.incomeCategories,
    required this.expenseCategories,
  });

  factory DashboardCategoryBreakdownModel.fromJson(Map<String, dynamic> json) {
    return DashboardCategoryBreakdownModel(
      currency: json['currency'] ?? 'INR',
      month: json['month'],
      year: json['year'],
      incomeCategories: (json['income_categories'] as List)
          .map((i) => CategoryBreakdownItemModel.fromJson(i))
          .toList(),
      expenseCategories: (json['expense_categories'] as List)
          .map((i) => CategoryBreakdownItemModel.fromJson(i))
          .toList(),
    );
  }
}

