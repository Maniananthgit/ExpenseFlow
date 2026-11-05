import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../repositories/report_repository.dart';

class ReportViewModel extends ChangeNotifier {
  final ReportRepository _repo = ReportRepository();

  MonthlyReportModel? _monthlyReport;
  YearlyReportModel? _yearlyReport;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isYearlyView = false;

  bool _isLoading = false;
  String? _errorMessage;

  MonthlyReportModel? get monthlyReport => _monthlyReport;
  YearlyReportModel? get yearlyReport => _yearlyReport;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  bool get isYearlyView => _isYearlyView;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void toggleViewMode(bool yearly) {
    _isYearlyView = yearly;
    fetchReport();
  }

  void setPeriod(int month, int year) {
    _selectedMonth = month;
    _selectedYear = year;
    fetchReport();
  }

  Future<void> fetchReport() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isYearlyView) {
        _yearlyReport = await _repo.getYearlyReport(_selectedYear);
      } else {
        _monthlyReport = await _repo.getMonthlyReport(_selectedMonth, _selectedYear);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> exportTransactionsCsv({String? startDate, String? endDate, String? type}) async {
    try {
      return await _repo.exportCsv(
        startDate: startDate,
        endDate: endDate,
        type: type,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}

