import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

class TransactionViewModel extends ChangeNotifier {
  final TransactionRepository _repo = TransactionRepository();

  List<TransactionModel> _transactions = [];
  int _total = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  String? _errorMessage;

  // Filter state
  String? _selectedType;
  String? _selectedCategoryId;
  String? _startDate;
  String? _endDate;
  String? _searchQuery;

  List<TransactionModel> get transactions => _transactions;
  int get total => _total;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get selectedType => _selectedType;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get startDate => _startDate;
  String? get endDate => _endDate;
  String? get searchQuery => _searchQuery;

  void setFilterType(String? type) {
    _selectedType = type;
    fetchTransactions(page: 1);
  }

  void setFilterCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    fetchTransactions(page: 1);
  }

  void setDateRange(String? start, String? end) {
    _startDate = start;
    _endDate = end;
    fetchTransactions(page: 1);
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    fetchTransactions(page: 1);
  }

  void resetFilters() {
    _selectedType = null;
    _selectedCategoryId = null;
    _startDate = null;
    _endDate = null;
    _searchQuery = null;
    fetchTransactions(page: 1);
  }

  Future<void> fetchTransactions({int page = 1, String? overrideType}) async {
    _isLoading = true;
    _errorMessage = null;
    _currentPage = page;
    notifyListeners();

    try {
      final res = await _repo.getTransactions(
        type: overrideType ?? _selectedType,
        categoryId: _selectedCategoryId,
        startDate: _startDate,
        endDate: _endDate,
        search: _searchQuery,
        page: page,
        pageSize: 20,
      );
      _transactions = res.items;
      _total = res.total;
      _totalPages = res.totalPages;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTransaction({
    required String categoryId,
    required double amount,
    required String type,
    String? description,
    required String transactionDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.createTransaction(
        categoryId: categoryId,
        amount: amount,
        type: type,
        description: description,
        transactionDate: transactionDate,
      );
      await fetchTransactions(page: 1);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransaction({
    required String id,
    String? categoryId,
    double? amount,
    String? type,
    String? description,
    String? transactionDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.updateTransaction(
        id: id,
        categoryId: categoryId,
        amount: amount,
        type: type,
        description: description,
        transactionDate: transactionDate,
      );
      await fetchTransactions(page: _currentPage);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.deleteTransaction(id);
      await fetchTransactions(page: _currentPage);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

