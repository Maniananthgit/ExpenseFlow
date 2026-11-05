import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../repositories/category_repository.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryRepository _repo = CategoryRepository();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get incomeCategories => _categories.where((c) => c.type == 'INCOME').toList();
  List<CategoryModel> get expenseCategories => _categories.where((c) => c.type == 'EXPENSE').toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCategories({String? type}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _repo.getCategories(type: type);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory({
    required String name,
    required String type,
    String color = '#3B82F6',
    String icon = 'category',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newCat = await _repo.createCategory(
        name: name,
        type: type,
        color: color,
        icon: icon,
      );
      _categories.add(newCat);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory({
    required String id,
    String? name,
    String? color,
    String? icon,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repo.updateCategory(
        id: id,
        name: name,
        color: color,
        icon: icon,
      );
      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _categories[index] = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

