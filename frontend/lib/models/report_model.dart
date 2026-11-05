import 'dashboard_model.dart';

class DailyExpenseItemModel {
  final String date;
  final double income;
  final double expense;

  DailyExpenseItemModel({
    required this.date,
    required this.income,
    required this.expense,
  });

  factory DailyExpenseItemModel.fromJson(Map<String, dynamic> json) {
    return DailyExpenseItemModel(
      date: json['date'],
      income: double.tryParse(json['income'].toString()) ?? 0.0,
      expense: double.tryParse(json['expense'].toString()) ?? 0.0,
    );
  }
}

class TopExpenseItemModel {
  final String id;
  final String description;
  final String category;
  final double amount;
  final String date;

  TopExpenseItemModel({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
  });

  factory TopExpenseItemModel.fromJson(Map<String, dynamic> json) {
    return TopExpenseItemModel(
      id: json['id'],
      description: json['description'] ?? '',
      category: json['category'] ?? 'Other',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      date: json['date'],
    );
  }
}

class MonthlyReportModel {
  final String currency;
  final int month;
  final int year;
  final String monthName;
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final double savingsRate;
  final List<CategoryBreakdownItemModel> categoryBreakdown;
  final List<DailyExpenseItemModel> dailyBreakdown;
  final List<TopExpenseItemModel> topExpenses;

  MonthlyReportModel({
    required this.currency,
    required this.month,
    required this.year,
    required this.monthName,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.savingsRate,
    required this.categoryBreakdown,
    required this.dailyBreakdown,
    required this.topExpenses,
  });

  factory MonthlyReportModel.fromJson(Map<String, dynamic> json) {
    return MonthlyReportModel(
      currency: json['currency'] ?? 'INR',
      month: json['month'],
      year: json['year'],
      monthName: json['month_name'],
      totalIncome: double.tryParse(json['total_income'].toString()) ?? 0.0,
      totalExpense: double.tryParse(json['total_expense'].toString()) ?? 0.0,
      netSavings: double.tryParse(json['net_savings'].toString()) ?? 0.0,
      savingsRate: (json['savings_rate'] as num?)?.toDouble() ?? 0.0,
      categoryBreakdown: (json['category_breakdown'] as List)
          .map((c) => CategoryBreakdownItemModel.fromJson(c))
          .toList(),
      dailyBreakdown: (json['daily_breakdown'] as List)
          .map((d) => DailyExpenseItemModel.fromJson(d))
          .toList(),
      topExpenses: (json['top_expenses'] as List)
          .map((t) => TopExpenseItemModel.fromJson(t))
          .toList(),
    );
  }
}

class YearlyReportModel {
  final String currency;
  final int year;
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final double savingsRate;
  final List<MonthlyTrendItemModel> monthlyTrends;
  final List<CategoryBreakdownItemModel> categoryBreakdown;

  YearlyReportModel({
    required this.currency,
    required this.year,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.savingsRate,
    required this.monthlyTrends,
    required this.categoryBreakdown,
  });

  factory YearlyReportModel.fromJson(Map<String, dynamic> json) {
    return YearlyReportModel(
      currency: json['currency'] ?? 'INR',
      year: json['year'],
      totalIncome: double.tryParse(json['total_income'].toString()) ?? 0.0,
      totalExpense: double.tryParse(json['total_expense'].toString()) ?? 0.0,
      netSavings: double.tryParse(json['net_savings'].toString()) ?? 0.0,
      savingsRate: (json['savings_rate'] as num?)?.toDouble() ?? 0.0,
      monthlyTrends: (json['monthly_trends'] as List)
          .map((m) => MonthlyTrendItemModel.fromJson(m))
          .toList(),
      categoryBreakdown: (json['category_breakdown'] as List)
          .map((c) => CategoryBreakdownItemModel.fromJson(c))
          .toList(),
    );
  }
}

