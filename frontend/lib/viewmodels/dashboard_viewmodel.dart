import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../repositories/dashboard_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final DashboardRepository _repo = DashboardRepository();

  DashboardSummaryModel? _summary;
  List<MonthlyTrendItemModel> _trends = [];
  DashboardCategoryBreakdownModel? _categoryBreakdown;

  bool _isLoading = false;
  String? _errorMessage;

  DashboardSummaryModel? get summary => _summary;
  List<MonthlyTrendItemModel> get trends => _trends;
  DashboardCategoryBreakdownModel? get categoryBreakdown => _categoryBreakdown;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardData({int? month, int? year}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final summaryFuture = _repo.getSummary(month: month, year: year);
      final trendsFuture = _repo.getMonthlyTrends(year: year);
      final breakdownFuture = _repo.getCategoryBreakdown(month: month, year: year);

      final results = await Future.wait([summaryFuture, trendsFuture, breakdownFuture]);

      _summary = results[0] as DashboardSummaryModel;
      _trends = results[1] as List<MonthlyTrendItemModel>;
      _categoryBreakdown = results[2] as DashboardCategoryBreakdownModel;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

