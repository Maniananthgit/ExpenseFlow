import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/report_model.dart';

class ReportRepository {
  Future<MonthlyReportModel> getMonthlyReport(int month, int year) async {
    final queryParams = {
      'month': month.toString(),
      'year': year.toString(),
    };
    final res = await ApiClient.get(ApiConstants.reportsMonthly, queryParams: queryParams);
    return MonthlyReportModel.fromJson(res);
  }

  Future<YearlyReportModel> getYearlyReport(int year) async {
    final queryParams = {
      'year': year.toString(),
    };
    final res = await ApiClient.get(ApiConstants.reportsYearly, queryParams: queryParams);
    return YearlyReportModel.fromJson(res);
  }

  Future<String> exportCsv({String? startDate, String? endDate, String? type}) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (type != null) queryParams['type'] = type;

    return await ApiClient.getRaw(ApiConstants.reportsExport, queryParams: queryParams);
  }
}

