import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  Future<DashboardSummaryModel> getSummary({int? month, int? year}) async {
    final queryParams = <String, String>{};
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();

    final res = await ApiClient.get(ApiConstants.dashboardSummary, queryParams: queryParams);
    return DashboardSummaryModel.fromJson(res);
  }

  Future<List<MonthlyTrendItemModel>> getMonthlyTrends({int? year}) async {
    final queryParams = <String, String>{};
    if (year != null) queryParams['year'] = year.toString();

    final res = await ApiClient.get(ApiConstants.dashboardMonthly, queryParams: queryParams);
    return (res['trends'] as List).map((t) => MonthlyTrendItemModel.fromJson(t)).toList();
  }

  Future<DashboardCategoryBreakdownModel> getCategoryBreakdown({int? month, int? year}) async {
    final queryParams = <String, String>{};
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();

    final res = await ApiClient.get(ApiConstants.dashboardCategoryBreakdown, queryParams: queryParams);
    return DashboardCategoryBreakdownModel.fromJson(res);
  }
}

