import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageManager {
  static const String _keyTransactions = 'ef_transactions_v2';
  static const String _keyCategories = 'ef_categories_v2';
  static const String _keyBudgets = 'ef_budgets_v2';
  static const String _keyCloudUrl = 'ef_cloud_api_url';

  static List<Map<String, dynamic>>? _cachedTransactions;
  static List<Map<String, dynamic>>? _cachedCategories;
  static List<Map<String, dynamic>>? _cachedBudgets;
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();

    // 1. Categories
    final catRaw = prefs.getString(_keyCategories);
    if (catRaw != null) {
      try {
        _cachedCategories = List<Map<String, dynamic>>.from(jsonDecode(catRaw));
      } catch (_) {
        _cachedCategories = _defaultCategories();
      }
    } else {
      _cachedCategories = _defaultCategories();
      await prefs.setString(_keyCategories, jsonEncode(_cachedCategories));
    }

    // 2. Transactions
    final txRaw = prefs.getString(_keyTransactions);
    if (txRaw != null) {
      try {
        _cachedTransactions = List<Map<String, dynamic>>.from(jsonDecode(txRaw));
      } catch (_) {
        _cachedTransactions = _defaultTransactions();
      }
    } else {
      _cachedTransactions = _defaultTransactions();
      await prefs.setString(_keyTransactions, jsonEncode(_cachedTransactions));
    }

    // 3. Budgets
    final bgRaw = prefs.getString(_keyBudgets);
    if (bgRaw != null) {
      try {
        _cachedBudgets = List<Map<String, dynamic>>.from(jsonDecode(bgRaw));
      } catch (_) {
        _cachedBudgets = _defaultBudgets();
      }
    } else {
      _cachedBudgets = _defaultBudgets();
      await prefs.setString(_keyBudgets, jsonEncode(_cachedBudgets));
    }

    _initialized = true;
  }

  static Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTransactions, jsonEncode(_cachedTransactions));
  }

  static Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCategories, jsonEncode(_cachedCategories));
  }

  static Future<void> _saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBudgets, jsonEncode(_cachedBudgets));
  }

  // --- Transactions ---

  static Future<Map<String, dynamic>> getTransactions({
    String? type,
    String? categoryId,
    String? search,
    String? startDate,
    String? endDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    await ensureInitialized();
    var list = List<Map<String, dynamic>>.from(_cachedTransactions!);

    if (type != null && type.isNotEmpty && type != 'ALL') {
      list = list.where((t) => t['type'] == type).toList();
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      list = list.where((t) => t['category_id'] == categoryId).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list.where((t) {
        final desc = (t['description'] ?? '').toString().toLowerCase();
        final catName = (t['category']?['name'] ?? '').toString().toLowerCase();
        return desc.contains(q) || catName.contains(q);
      }).toList();
    }
    if (startDate != null && startDate.isNotEmpty) {
      list = list.where((t) => (t['transaction_date'] ?? '').toString().compareTo(startDate) >= 0).toList();
    }
    if (endDate != null && endDate.isNotEmpty) {
      list = list.where((t) => (t['transaction_date'] ?? '').toString().compareTo(endDate) <= 0).toList();
    }

    // Sort descending by date, then created_at
    list.sort((a, b) {
      final d1 = (a['transaction_date'] ?? '').toString();
      final d2 = (b['transaction_date'] ?? '').toString();
      final cmp = d2.compareTo(d1);
      if (cmp != 0) return cmp;
      return (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString());
    });

    final total = list.length;
    final totalPages = (total / pageSize).ceil().clamp(1, 9999);
    final startIndex = ((page - 1) * pageSize).clamp(0, total);
    final endIndex = (startIndex + pageSize).clamp(0, total);
    final items = list.sublist(startIndex, endIndex);

    return {
      'items': items,
      'total': total,
      'page': page,
      'page_size': pageSize,
      'total_pages': totalPages,
    };
  }

  static Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> data) async {
    await ensureInitialized();
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final categoryId = data['category_id']?.toString() ?? '';
    final category = _findCategory(categoryId) ?? _defaultCategories().first;

    final double amount = (data['amount'] is num)
        ? (data['amount'] as num).toDouble()
        : (double.tryParse(data['amount'].toString()) ?? 0.0);

    final item = <String, dynamic>{
      'id': 'tx-${now.millisecondsSinceEpoch}',
      'user_id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
      'category_id': category['id'],
      'amount': amount.toStringAsFixed(2),
      'type': data['type']?.toString().toUpperCase() ?? 'EXPENSE',
      'description': data['description']?.toString() ?? '',
      'transaction_date': data['transaction_date']?.toString() ?? DateFormat('yyyy-MM-dd').format(now),
      'created_at': nowIso,
      'updated_at': nowIso,
      'category': category,
    };

    _cachedTransactions!.insert(0, item);
    await _saveTransactions();
    return item;
  }

  static Future<Map<String, dynamic>> updateTransaction(String id, Map<String, dynamic> updates) async {
    await ensureInitialized();
    final index = _cachedTransactions!.indexWhere((t) => t['id'] == id);
    if (index == -1) {
      throw Exception('Transaction not found');
    }
    final existing = Map<String, dynamic>.from(_cachedTransactions![index]);
    if (updates.containsKey('category_id')) {
      existing['category_id'] = updates['category_id'];
      final cat = _findCategory(updates['category_id']);
      if (cat != null) existing['category'] = cat;
    }
    if (updates.containsKey('amount')) {
      final double amt = (updates['amount'] is num)
          ? (updates['amount'] as num).toDouble()
          : (double.tryParse(updates['amount'].toString()) ?? 0.0);
      existing['amount'] = amt.toStringAsFixed(2);
    }
    if (updates.containsKey('type')) {
      existing['type'] = updates['type'].toString().toUpperCase();
    }
    if (updates.containsKey('description')) {
      existing['description'] = updates['description'];
    }
    if (updates.containsKey('transaction_date')) {
      existing['transaction_date'] = updates['transaction_date'];
    }
    existing['updated_at'] = DateTime.now().toIso8601String();

    _cachedTransactions![index] = existing;
    await _saveTransactions();
    return existing;
  }

  static Future<void> deleteTransaction(String id) async {
    await ensureInitialized();
    _cachedTransactions!.removeWhere((t) => t['id'] == id);
    await _saveTransactions();
  }

  // --- Categories ---

  static Future<List<Map<String, dynamic>>> getCategories({String? type}) async {
    await ensureInitialized();
    if (type != null && type.isNotEmpty) {
      return _cachedCategories!.where((c) => c['type'] == type).toList();
    }
    return List<Map<String, dynamic>>.from(_cachedCategories!);
  }

  static Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    await ensureInitialized();
    final item = <String, dynamic>{
      'id': 'cat-${DateTime.now().millisecondsSinceEpoch}',
      'name': data['name'] ?? 'Custom',
      'type': data['type']?.toString().toUpperCase() ?? 'EXPENSE',
      'color': data['color'] ?? '#6366F1',
      'icon': data['icon'] ?? 'category',
      'is_system': false,
    };
    _cachedCategories!.add(item);
    await _saveCategories();
    return item;
  }

  static Future<Map<String, dynamic>> updateCategory(String id, Map<String, dynamic> data) async {
    await ensureInitialized();
    final index = _cachedCategories!.indexWhere((c) => c['id'] == id);
    if (index != -1) {
      _cachedCategories![index] = {
        ..._cachedCategories![index],
        ...data,
      };
      await _saveCategories();
      return _cachedCategories![index];
    }
    throw Exception('Category not found');
  }

  static Future<void> deleteCategory(String id) async {
    await ensureInitialized();
    _cachedCategories!.removeWhere((c) => c['id'] == id);
    await _saveCategories();
  }

  // --- Budgets ---

  static Future<Map<String, dynamic>> getBudgets({int? month, int? year}) async {
    await ensureInitialized();
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    // Filter budgets for this month/year or all
    final relevantBudgets = _cachedBudgets!.where((b) {
      final bm = b['month'] as int? ?? now.month;
      final by = b['year'] as int? ?? now.year;
      return bm == targetMonth && by == targetYear;
    }).toList();

    double totalBudget = 0.0;
    double totalSpent = 0.0;
    final enrichedList = <Map<String, dynamic>>[];

    for (final b in relevantBudgets) {
      final catId = b['category_id']?.toString();
      final double budgetAmount = (b['amount'] is num)
          ? (b['amount'] as num).toDouble()
          : (double.tryParse(b['amount'].toString()) ?? 0.0);
      totalBudget += budgetAmount;

      // Calculate spent from transactions in this month/year for this category
      double spent = 0.0;
      for (final tx in _cachedTransactions!) {
        if (tx['type'] == 'EXPENSE' && tx['category_id'] == catId) {
          final txDateStr = tx['transaction_date']?.toString() ?? '';
          if (txDateStr.length >= 7) {
            final parts = txDateStr.split('-');
            final txYear = int.tryParse(parts[0]);
            final txMonth = int.tryParse(parts[1]);
            if (txYear == targetYear && txMonth == targetMonth) {
              final amt = (tx['amount'] is num)
                  ? (tx['amount'] as num).toDouble()
                  : (double.tryParse(tx['amount'].toString()) ?? 0.0);
              spent += amt;
            }
          }
        }
      }
      totalSpent += spent;

      final double remaining = budgetAmount - spent;
      final double util = budgetAmount > 0 ? (spent / budgetAmount * 100).clamp(0, 999.0) : 0.0;
      final bool isExceeded = spent > budgetAmount;
      final cat = _findCategory(catId) ?? b['category'];

      enrichedList.add({
        ...b,
        'amount': budgetAmount.toStringAsFixed(2),
        'spent_amount': spent.toStringAsFixed(2),
        'remaining_amount': remaining.toStringAsFixed(2),
        'utilization_percentage': double.parse(util.toStringAsFixed(1)),
        'is_exceeded': isExceeded,
        'category': cat,
      });
    }

    final double overallUtil = totalBudget > 0 ? (totalSpent / totalBudget * 100).clamp(0, 999.0) : 0.0;

    return {
      'total_budget': totalBudget.toStringAsFixed(2),
      'total_spent': totalSpent.toStringAsFixed(2),
      'total_remaining': (totalBudget - totalSpent).toStringAsFixed(2),
      'overall_utilization': double.parse(overallUtil.toStringAsFixed(1)),
      'budgets': enrichedList,
    };
  }

  static Future<Map<String, dynamic>> createBudget(Map<String, dynamic> data) async {
    await ensureInitialized();
    final now = DateTime.now();
    final catId = data['category_id']?.toString() ?? '';
    final cat = _findCategory(catId);
    final double amount = (data['amount'] is num)
        ? (data['amount'] as num).toDouble()
        : (double.tryParse(data['amount'].toString()) ?? 0.0);

    final item = <String, dynamic>{
      'id': 'bg-${now.millisecondsSinceEpoch}',
      'user_id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
      'category_id': catId,
      'amount': amount.toStringAsFixed(2),
      'month': data['month'] ?? now.month,
      'year': data['year'] ?? now.year,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'category': cat,
    };

    _cachedBudgets!.add(item);
    await _saveBudgets();
    return item;
  }

  static Future<Map<String, dynamic>> updateBudget(String id, Map<String, dynamic> data) async {
    await ensureInitialized();
    final index = _cachedBudgets!.indexWhere((b) => b['id'] == id);
    if (index != -1) {
      final existing = Map<String, dynamic>.from(_cachedBudgets![index]);
      if (data.containsKey('amount')) {
        final double amt = (data['amount'] is num)
            ? (data['amount'] as num).toDouble()
            : (double.tryParse(data['amount'].toString()) ?? 0.0);
        existing['amount'] = amt.toStringAsFixed(2);
      }
      if (data.containsKey('month')) existing['month'] = data['month'];
      if (data.containsKey('year')) existing['year'] = data['year'];
      existing['updated_at'] = DateTime.now().toIso8601String();
      _cachedBudgets![index] = existing;
      await _saveBudgets();
      return existing;
    }
    throw Exception('Budget not found');
  }

  static Future<void> deleteBudget(String id) async {
    await ensureInitialized();
    _cachedBudgets!.removeWhere((b) => b['id'] == id);
    await _saveBudgets();
  }

  // --- Dashboard Analytics ---

  static Future<Map<String, dynamic>> getDashboardSummary({int? month, int? year}) async {
    await ensureInitialized();
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    double totalIncome = 0.0;
    double totalExpense = 0.0;
    double monthlyIncome = 0.0;
    double monthlyExpense = 0.0;

    for (final tx in _cachedTransactions!) {
      final amt = (tx['amount'] is num)
          ? (tx['amount'] as num).toDouble()
          : (double.tryParse(tx['amount'].toString()) ?? 0.0);

      final isInc = tx['type'] == 'INCOME';
      if (isInc) {
        totalIncome += amt;
      } else {
        totalExpense += amt;
      }

      final dateStr = tx['transaction_date']?.toString() ?? '';
      if (dateStr.length >= 7) {
        final parts = dateStr.split('-');
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (y == targetYear && m == targetMonth) {
          if (isInc) {
            monthlyIncome += amt;
          } else {
            monthlyExpense += amt;
          }
        }
      }
    }

    final balance = totalIncome - totalExpense;
    final monthlySavings = monthlyIncome - monthlyExpense;
    final savingsRate = monthlyIncome > 0 ? (monthlySavings / monthlyIncome * 100).clamp(0, 100.0) : 0.0;

    // Recent 5 transactions
    final sorted = List<Map<String, dynamic>>.from(_cachedTransactions!);
    sorted.sort((a, b) {
      final d1 = (a['transaction_date'] ?? '').toString();
      final d2 = (b['transaction_date'] ?? '').toString();
      return d2.compareTo(d1);
    });
    final recent = sorted.take(5).toList();

    return {
      'currency': 'INR',
      'total_income': totalIncome.toStringAsFixed(2),
      'total_expenses': totalExpense.toStringAsFixed(2),
      'current_balance': balance.toStringAsFixed(2),
      'monthly_income': monthlyIncome.toStringAsFixed(2),
      'monthly_spending': monthlyExpense.toStringAsFixed(2),
      'monthly_savings': monthlySavings.toStringAsFixed(2),
      'savings_rate': double.parse(savingsRate.toStringAsFixed(2)),
      'recent_transactions': recent,
    };
  }

  static Future<Map<String, dynamic>> getDashboardMonthly({int? year}) async {
    await ensureInitialized();
    final targetYear = year ?? DateTime.now().year;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final trends = <Map<String, dynamic>>[];
    for (int m = 1; m <= 12; m++) {
      double inc = 0.0;
      double exp = 0.0;
      for (final tx in _cachedTransactions!) {
        final dateStr = tx['transaction_date']?.toString() ?? '';
        if (dateStr.length >= 7) {
          final parts = dateStr.split('-');
          final y = int.tryParse(parts[0]);
          final monthNum = int.tryParse(parts[1]);
          if (y == targetYear && monthNum == m) {
            final amt = (tx['amount'] is num)
                ? (tx['amount'] as num).toDouble()
                : (double.tryParse(tx['amount'].toString()) ?? 0.0);
            if (tx['type'] == 'INCOME') {
              inc += amt;
            } else {
              exp += amt;
            }
          }
        }
      }
      trends.add({
        'month': m,
        'month_name': months[m - 1],
        'year': targetYear,
        'income': inc,
        'expense': exp,
        'net_savings': inc - exp,
      });
    }

    return {
      'currency': 'INR',
      'trends': trends,
    };
  }

  static Future<Map<String, dynamic>> getDashboardCategoryBreakdown({int? month, int? year}) async {
    await ensureInitialized();
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    final expenseMap = <String, double>{};
    final expenseCounts = <String, int>{};
    final incomeMap = <String, double>{};
    final incomeCounts = <String, int>{};

    double totalExp = 0.0;
    double totalInc = 0.0;

    for (final tx in _cachedTransactions!) {
      final dateStr = tx['transaction_date']?.toString() ?? '';
      if (dateStr.length >= 7) {
        final parts = dateStr.split('-');
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (y == targetYear && m == targetMonth) {
          final amt = (tx['amount'] is num)
              ? (tx['amount'] as num).toDouble()
              : (double.tryParse(tx['amount'].toString()) ?? 0.0);
          final catId = tx['category_id']?.toString() ?? 'other';

          if (tx['type'] == 'EXPENSE') {
            expenseMap[catId] = (expenseMap[catId] ?? 0.0) + amt;
            expenseCounts[catId] = (expenseCounts[catId] ?? 0) + 1;
            totalExp += amt;
          } else {
            incomeMap[catId] = (incomeMap[catId] ?? 0.0) + amt;
            incomeCounts[catId] = (incomeCounts[catId] ?? 0) + 1;
            totalInc += amt;
          }
        }
      }
    }

    final expenseCategories = <Map<String, dynamic>>[];
    expenseMap.forEach((catId, sum) {
      final cat = _findCategory(catId) ?? {'name': 'Expense', 'color': '#F59E0B', 'icon': 'receipt_long'};
      final pct = totalExp > 0 ? (sum / totalExp * 100) : 0.0;
      expenseCategories.add({
        'category_id': catId,
        'category_name': cat['name'],
        'category_color': cat['color'],
        'category_icon': cat['icon'],
        'total_amount': sum.toStringAsFixed(2),
        'percentage': double.parse(pct.toStringAsFixed(1)),
        'transaction_count': expenseCounts[catId] ?? 1,
      });
    });

    final incomeCategories = <Map<String, dynamic>>[];
    incomeMap.forEach((catId, sum) {
      final cat = _findCategory(catId) ?? {'name': 'Income', 'color': '#10B981', 'icon': 'payments'};
      final pct = totalInc > 0 ? (sum / totalInc * 100) : 0.0;
      incomeCategories.add({
        'category_id': catId,
        'category_name': cat['name'],
        'category_color': cat['color'],
        'category_icon': cat['icon'],
        'total_amount': sum.toStringAsFixed(2),
        'percentage': double.parse(pct.toStringAsFixed(1)),
        'transaction_count': incomeCounts[catId] ?? 1,
      });
    });

    return {
      'currency': 'INR',
      'month': targetMonth,
      'year': targetYear,
      'income_categories': incomeCategories,
      'expense_categories': expenseCategories,
    };
  }

  // --- Reports ---

  static Future<Map<String, dynamic>> getMonthlyReport({int? month, int? year}) async {
    await ensureInitialized();
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    final breakdown = await getDashboardCategoryBreakdown(month: targetMonth, year: targetYear);
    final summary = await getDashboardSummary(month: targetMonth, year: targetYear);

    // Daily breakdown
    final daily = <Map<String, dynamic>>[];
    final daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    for (int d = 1; d <= daysInMonth; d++) {
      final dateStr = '$targetYear-${targetMonth.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      double inc = 0.0;
      double exp = 0.0;
      for (final tx in _cachedTransactions!) {
        if (tx['transaction_date'] == dateStr) {
          final amt = (tx['amount'] is num) ? (tx['amount'] as num).toDouble() : (double.tryParse(tx['amount'].toString()) ?? 0.0);
          if (tx['type'] == 'INCOME') inc += amt; else exp += amt;
        }
      }
      daily.add({'date': dateStr, 'income': inc.toStringAsFixed(2), 'expense': exp.toStringAsFixed(2)});
    }

    // Top expenses
    final expenses = _cachedTransactions!.where((t) {
      if (t['type'] != 'EXPENSE') return false;
      final dateStr = t['transaction_date']?.toString() ?? '';
      if (dateStr.length >= 7) {
        final p = dateStr.split('-');
        return int.tryParse(p[0]) == targetYear && int.tryParse(p[1]) == targetMonth;
      }
      return false;
    }).toList();
    expenses.sort((a, b) {
      final aAmt = double.tryParse(a['amount'].toString()) ?? 0.0;
      final bAmt = double.tryParse(b['amount'].toString()) ?? 0.0;
      return bAmt.compareTo(aAmt);
    });

    final topExpenses = expenses.take(5).map((t) => {
      'id': t['id'],
      'description': t['description'] ?? t['category']?['name'] ?? 'Expense',
      'category': t['category']?['name'] ?? 'Expense',
      'amount': double.tryParse(t['amount'].toString()) ?? 0.0,
      'date': t['transaction_date'] ?? '',
    }).toList();

    return {
      'currency': 'INR',
      'month': targetMonth,
      'year': targetYear,
      'month_name': months[targetMonth - 1],
      'total_income': summary['monthly_income'],
      'total_expense': summary['monthly_spending'],
      'net_savings': summary['monthly_savings'],
      'savings_rate': summary['savings_rate'],
      'category_breakdown': breakdown['expense_categories'],
      'daily_breakdown': daily,
      'top_expenses': topExpenses,
    };
  }

  static Future<Map<String, dynamic>> getYearlyReport({int? year}) async {
    await ensureInitialized();
    final targetYear = year ?? DateTime.now().year;
    final trends = await getDashboardMonthly(year: targetYear);

    double totalInc = 0.0;
    double totalExp = 0.0;
    for (final tr in (trends['trends'] as List)) {
      totalInc += (tr['income'] as num).toDouble();
      totalExp += (tr['expense'] as num).toDouble();
    }
    final net = totalInc - totalExp;
    final rate = totalInc > 0 ? (net / totalInc * 100) : 0.0;

    return {
      'currency': 'INR',
      'year': targetYear,
      'total_income': totalInc.toStringAsFixed(2),
      'total_expense': totalExp.toStringAsFixed(2),
      'net_savings': net.toStringAsFixed(2),
      'savings_rate': double.parse(rate.toStringAsFixed(2)),
      'monthly_trends': trends['trends'],
      'category_breakdown': [],
    };
  }

  static Future<String> exportCsv() async {
    await ensureInitialized();
    final sb = StringBuffer();
    sb.writeln('Transaction ID,Date,Type,Category,Amount,Currency,Description,Created At');
    for (final tx in _cachedTransactions!) {
      final id = tx['id'];
      final date = tx['transaction_date'];
      final type = tx['type'];
      final cat = tx['category']?['name'] ?? 'General';
      final amt = tx['amount'];
      final desc = (tx['description'] ?? '').replaceAll('"', '""');
      final created = tx['created_at'];
      sb.writeln('"$id","$date","$type","$cat","$amt","INR","$desc","$created"');
    }
    return sb.toString();
  }

  // --- Helper lookups & starter seeds ---

  static Map<String, dynamic>? _findCategory(String? id) {
    if (id == null) return null;
    try {
      return _cachedCategories?.firstWhere((c) => c['id'] == id);
    } catch (_) {
      return null;
    }
  }

  static List<Map<String, dynamic>> _defaultCategories() {
    return [
      {'id': 'cat-inc-1', 'name': 'Salary', 'type': 'INCOME', 'color': '#10B981', 'icon': 'payments', 'is_system': true},
      {'id': 'cat-inc-2', 'name': 'Freelancing', 'type': 'INCOME', 'color': '#06B6D4', 'icon': 'laptop', 'is_system': true},
      {'id': 'cat-inc-3', 'name': 'Investment', 'type': 'INCOME', 'color': '#8B5CF6', 'icon': 'trending_up', 'is_system': true},
      {'id': 'cat-inc-4', 'name': 'Business', 'type': 'INCOME', 'color': '#3B82F6', 'icon': 'business_center', 'is_system': true},
      {'id': 'cat-exp-1', 'name': 'Food & Groceries', 'type': 'EXPENSE', 'color': '#F59E0B', 'icon': 'restaurant', 'is_system': true},
      {'id': 'cat-exp-2', 'name': 'Bills & Utilities', 'type': 'EXPENSE', 'color': '#F97316', 'icon': 'receipt_long', 'is_system': true},
      {'id': 'cat-exp-3', 'name': 'Shopping', 'type': 'EXPENSE', 'color': '#EC4899', 'icon': 'shopping_bag', 'is_system': true},
      {'id': 'cat-exp-4', 'name': 'Transportation', 'type': 'EXPENSE', 'color': '#3B82F6', 'icon': 'directions_car', 'is_system': true},
      {'id': 'cat-exp-5', 'name': 'Entertainment', 'type': 'EXPENSE', 'color': '#A855F7', 'icon': 'movie', 'is_system': true},
      {'id': 'cat-exp-6', 'name': 'Healthcare', 'type': 'EXPENSE', 'color': '#EF4444', 'icon': 'medical_services', 'is_system': true},
    ];
  }

  static List<Map<String, dynamic>> _defaultTransactions() {
    final now = DateTime.now();
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');

    return [
      {
        'id': 'tx-init-1',
        'user_id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
        'category_id': 'cat-inc-1',
        'amount': '85000.00',
        'type': 'INCOME',
        'description': 'Monthly Salary',
        'transaction_date': '$y-$m-01',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'category': {'id': 'cat-inc-1', 'name': 'Salary', 'type': 'INCOME', 'color': '#10B981', 'icon': 'payments', 'is_system': true},
      },
      {
        'id': 'tx-init-2',
        'user_id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
        'category_id': 'cat-exp-1',
        'amount': '3500.00',
        'type': 'EXPENSE',
        'description': 'Supermarket Groceries',
        'transaction_date': '$y-$m-02',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'category': {'id': 'cat-exp-1', 'name': 'Food & Groceries', 'type': 'EXPENSE', 'color': '#F59E0B', 'icon': 'restaurant', 'is_system': true},
      },
      {
        'id': 'tx-init-3',
        'user_id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
        'category_id': 'cat-exp-2',
        'amount': '4200.00',
        'type': 'EXPENSE',
        'description': 'Electricity & Fiber Internet',
        'transaction_date': '$y-$m-03',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'category': {'id': 'cat-exp-2', 'name': 'Bills & Utilities', 'type': 'EXPENSE', 'color': '#F97316', 'icon': 'receipt_long', 'is_system': true},
      },
      {
        'id': 'tx-init-4',
        'user_id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
        'category_id': 'cat-exp-3',
        'amount': '2800.00',
        'type': 'EXPENSE',
        'description': 'Clothing & Shoes',
        'transaction_date': '$y-$m-04',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'category': {'id': 'cat-exp-3', 'name': 'Shopping', 'type': 'EXPENSE', 'color': '#EC4899', 'icon': 'shopping_bag', 'is_system': true},
      },
    ];
  }

  static List<Map<String, dynamic>> _defaultBudgets() {
    final now = DateTime.now();
    return [
      {
        'id': 'bg-init-1',
        'user_id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
        'category_id': 'cat-exp-1',
        'amount': '10000.00',
        'month': now.month,
        'year': now.year,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'category': {'id': 'cat-exp-1', 'name': 'Food & Groceries', 'type': 'EXPENSE', 'color': '#F59E0B', 'icon': 'restaurant', 'is_system': true},
      },
      {
        'id': 'bg-init-2',
        'user_id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
        'category_id': 'cat-exp-3',
        'amount': '5000.00',
        'month': now.month,
        'year': now.year,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'category': {'id': 'cat-exp-3', 'name': 'Shopping', 'type': 'EXPENSE', 'color': '#EC4899', 'icon': 'shopping_bag', 'is_system': true},
      },
      {
        'id': 'bg-init-3',
        'user_id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
        'category_id': 'cat-exp-2',
        'amount': '6000.00',
        'month': now.month,
        'year': now.year,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'category': {'id': 'cat-exp-2', 'name': 'Bills & Utilities', 'type': 'EXPENSE', 'color': '#F97316', 'icon': 'receipt_long', 'is_system': true},
      },
    ];
  }
}
