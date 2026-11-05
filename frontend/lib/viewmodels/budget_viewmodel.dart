import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../repositories/budget_repository.dart';

class BudgetViewModel extends ChangeNotifier {
  final BudgetRepository _repo = BudgetRepository();

  BudgetSummaryModel? _summary;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;
  String? _errorMessage;

  BudgetSummaryModel? get summary => _summary;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<BudgetModel> get exceededBudgets =>
      _summary?.budgets.where((b) => b.isExceeded).toList() ?? [];

  void setPeriod(int month, int year) {
    _selectedMonth = month;
    _selectedYear = year;
    fetchBudgets();
  }

  Future<void> fetchBudgets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _repo.getBudgets(
        month: _selectedMonth,
        year: _selectedYear,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBudget({
    required String categoryId,
    required double amount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.createBudget(
        categoryId: categoryId,
        amount: amount,
        month: _selectedMonth,
        year: _selectedYear,
      );
      await fetchBudgets();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBudget({
    required String id,
    double? amount,
    String? categoryId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.updateBudget(
        id: id,
        amount: amount,
        categoryId: categoryId,
        month: _selectedMonth,
        year: _selectedYear,
      );
      await fetchBudgets();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBudget(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.deleteBudget(id);
      await fetchBudgets();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

