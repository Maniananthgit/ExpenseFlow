class ApiConstants {
  // Base API URL - easily configurable
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String me = '$baseUrl/auth/me';
  static const String changePassword = '$baseUrl/auth/change-password';
  static const String logout = '$baseUrl/auth/logout';

  // Transaction endpoints
  static const String transactions = '$baseUrl/transactions';

  // Category endpoints
  static const String categories = '$baseUrl/categories';

  // Budget endpoints
  static const String budgets = '$baseUrl/budgets';

  // Dashboard endpoints
  static const String dashboardSummary = '$baseUrl/dashboard/summary';
  static const String dashboardMonthly = '$baseUrl/dashboard/monthly';
  static const String dashboardCategoryBreakdown = '$baseUrl/dashboard/category-breakdown';

  // Reports endpoints
  static const String reportsMonthly = '$baseUrl/reports/monthly';
  static const String reportsYearly = '$baseUrl/reports/yearly';
  static const String reportsExport = '$baseUrl/reports/export';
}

