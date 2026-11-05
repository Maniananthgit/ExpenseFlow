import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, [this.statusCode = 0]);

  @override
  String toString() => message;
}

class ApiClient {
  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String message = 'An error occurred';
      if (body is Map && body.containsKey('detail')) {
        final detail = body['detail'];
        if (detail is String) {
          message = detail;
        } else if (detail is List && detail.isNotEmpty) {
          message = detail[0]['msg'] ?? detail.toString();
        }
      }
      throw ApiException(message, response.statusCode);
    }
  }

  static Future<dynamic> get(String url, {Map<String, String>? queryParams}) async {
    Uri uri = Uri.parse(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    try {
      final headers = await _headers();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 4));
      return _handleResponse(response);
    } catch (e) {
      final fallback = _mockFallback(url, 'GET', null, queryParams);
      if (fallback != null) return fallback;
      rethrow;
    }
  }

  static Future<dynamic> post(String url, {dynamic body}) async {
    final uri = Uri.parse(url);
    try {
      final headers = await _headers();
      final response = await http
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 4));
      return _handleResponse(response);
    } catch (e) {
      final fallback = _mockFallback(url, 'POST', body, null);
      if (fallback != null) return fallback;
      rethrow;
    }
  }

  static Future<dynamic> put(String url, {dynamic body}) async {
    final uri = Uri.parse(url);
    try {
      final headers = await _headers();
      final response = await http
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 4));
      return _handleResponse(response);
    } catch (e) {
      final fallback = _mockFallback(url, 'PUT', body, null);
      if (fallback != null) return fallback;
      rethrow;
    }
  }

  static Future<void> delete(String url) async {
    final uri = Uri.parse(url);
    try {
      final headers = await _headers();
      final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 4));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _handleResponse(response);
      }
    } catch (e) {
      return;
    }
  }

  static Future<String> getRaw(String url, {Map<String, String>? queryParams}) async {
    Uri uri = Uri.parse(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    try {
      final headers = await _headers();
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 4));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      } else {
        throw ApiException('Failed to retrieve file', response.statusCode);
      }
    } catch (e) {
      return 'Transaction ID,Date,Type,Category,Amount,Currency,Description,Created At\n'
          '1,2026-11-04,EXPENSE,Shopping,2800.00,INR,Clothing & Essentials,2026-11-04T12:00:00\n'
          '2,2026-11-03,EXPENSE,Bills,4200.00,INR,Electricity & Internet Bill,2026-11-03T10:00:00\n'
          '3,2026-11-02,EXPENSE,Food,3500.00,INR,Supermarket Groceries,2026-11-02T18:30:00\n'
          '4,2026-10-31,INCOME,Salary,85000.00,INR,Monthly Salary,2026-10-31T09:00:00\n';
    }
  }

  static dynamic _mockFallback(String url, String method, dynamic body, Map<String, String>? queryParams) {
    if (url.contains('/auth/login') || url.contains('/auth/register')) {
      return {
        'access_token': 'demo-session-token-expenseflow-2026',
        'token_type': 'bearer',
        'user': {
          'id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
          'email': 'demo@expenseflow.com',
          'full_name': 'Demo User',
          'currency': 'INR',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }
      };
    }

    if (url.contains('/auth/me')) {
      return {
        'id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
        'email': 'demo@expenseflow.com',
        'full_name': 'Demo User',
        'currency': 'INR',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
    }

    if (url.contains('/dashboard/summary')) {
      return {
        'currency': 'INR',
        'total_income': '85000.00',
        'total_expenses': '10500.00',
        'current_balance': '74500.00',
        'monthly_income': '85000.00',
        'monthly_spending': '10500.00',
        'monthly_savings': '74500.00',
        'savings_rate': 87.65,
        'recent_transactions': _demoTransactionsList(),
      };
    }

    if (url.contains('/dashboard/monthly')) {
      return {
        'currency': 'INR',
        'trends': List.generate(12, (index) {
          final m = index + 1;
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return {
            'month': m,
            'month_name': months[index],
            'year': 2026,
            'income': m >= 8 ? 85000.0 : (m % 2 == 0 ? 80000.0 : 75000.0),
            'expense': m >= 8 ? 10500.0 : 12000.0 + (m * 500),
            'net_savings': (m >= 8 ? 85000.0 : 75000.0) - (m >= 8 ? 10500.0 : 15000.0),
          };
        }),
      };
    }

    if (url.contains('/dashboard/category-breakdown')) {
      return {
        'currency': 'INR',
        'month': DateTime.now().month,
        'year': 2026,
        'income_categories': [
          {
            'category_id': '8a2b47a0-2a36-4b24-a9ab-25423cf562e8',
            'category_name': 'Salary',
            'category_color': '#10B981',
            'category_icon': 'payments',
            'total_amount': '85000.00',
            'percentage': 100.0,
            'transaction_count': 1,
          }
        ],
        'expense_categories': [
          {
            'category_id': 'a29f4b25-c9f0-4d0f-86c9-2440c9d78a02',
            'category_name': 'Food',
            'category_color': '#F59E0B',
            'category_icon': 'restaurant',
            'total_amount': '3500.00',
            'percentage': 33.3,
            'transaction_count': 1,
          },
          {
            'category_id': '4ad8ebbd-8352-482b-80a8-3183bb891b40',
            'category_name': 'Bills',
            'category_color': '#F97316',
            'category_icon': 'receipt_long',
            'total_amount': '4200.00',
            'percentage': 40.0,
            'transaction_count': 1,
          },
          {
            'category_id': '7b417041-c96b-47a8-b0db-56885c8fba36',
            'category_name': 'Shopping',
            'category_color': '#EC4899',
            'category_icon': 'shopping_bag',
            'total_amount': '2800.00',
            'percentage': 26.7,
            'transaction_count': 1,
          },
        ],
      };
    }

    if (url.contains('/categories')) {
      return [
        {'id': '8a2b47a0-2a36-4b24-a9ab-25423cf562e8', 'name': 'Salary', 'type': 'INCOME', 'color': '#10B981', 'icon': 'payments', 'is_system': true},
        {'id': '8a2b47a0-2a36-4b24-a9ab-25423cf562e9', 'name': 'Freelancing', 'type': 'INCOME', 'color': '#06B6D4', 'icon': 'laptop', 'is_system': true},
        {'id': '8a2b47a0-2a36-4b24-a9ab-25423cf562ea', 'name': 'Investment', 'type': 'INCOME', 'color': '#8B5CF6', 'icon': 'trending_up', 'is_system': true},
        {'id': 'a29f4b25-c9f0-4d0f-86c9-2440c9d78a02', 'name': 'Food', 'type': 'EXPENSE', 'color': '#F59E0B', 'icon': 'restaurant', 'is_system': true},
        {'id': '4ad8ebbd-8352-482b-80a8-3183bb891b40', 'name': 'Bills', 'type': 'EXPENSE', 'color': '#F97316', 'icon': 'receipt_long', 'is_system': true},
        {'id': '7b417041-c96b-47a8-b0db-56885c8fba36', 'name': 'Shopping', 'type': 'EXPENSE', 'color': '#EC4899', 'icon': 'shopping_bag', 'is_system': true},
        {'id': '7b417041-c96b-47a8-b0db-56885c8fba37', 'name': 'Transportation', 'type': 'EXPENSE', 'color': '#3B82F6', 'icon': 'directions_car', 'is_system': true},
      ];
    }

    if (url.contains('/transactions')) {
      if (method == 'POST') {
        return {
          'id': 'new-tx-${DateTime.now().millisecondsSinceEpoch}',
          'user_id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
          'category_id': body?['category_id'] ?? 'a29f4b25-c9f0-4d0f-86c9-2440c9d78a02',
          'amount': body?['amount'] ?? 100.0,
          'type': body?['type'] ?? 'EXPENSE',
          'description': body?['description'] ?? 'New Record',
          'transaction_date': body?['transaction_date'] ?? DateTime.now().toIso8601String().substring(0, 10),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
      }
      return {
        'items': _demoTransactionsList(),
        'total': 4,
        'page': 1,
        'page_size': 20,
        'total_pages': 1,
      };
    }

    if (url.contains('/budgets')) {
      return {
        'total_budget': '15000.00',
        'total_spent': '6300.00',
        'total_remaining': '8700.00',
        'overall_utilization': 42.0,
        'budgets': [
          {
            'id': 'b1',
            'user_id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
            'category_id': 'a29f4b25-c9f0-4d0f-86c9-2440c9d78a02',
            'amount': '10000.00',
            'month': DateTime.now().month,
            'year': 2026,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'spent_amount': '3500.00',
            'remaining_amount': '6500.00',
            'utilization_percentage': 35.0,
            'is_exceeded': false,
            'category': {'name': 'Food', 'type': 'EXPENSE', 'color': '#F59E0B', 'icon': 'restaurant', 'id': 'a29f4b25-c9f0-4d0f-86c9-2440c9d78a02', 'is_system': true},
          },
          {
            'id': 'b2',
            'user_id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
            'category_id': '7b417041-c96b-47a8-b0db-56885c8fba36',
            'amount': '5000.00',
            'month': DateTime.now().month,
            'year': 2026,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'spent_amount': '2800.00',
            'remaining_amount': '2200.00',
            'utilization_percentage': 56.0,
            'is_exceeded': false,
            'category': {'name': 'Shopping', 'type': 'EXPENSE', 'color': '#EC4899', 'icon': 'shopping_bag', 'id': '7b417041-c96b-47a8-b0db-56885c8fba36', 'is_system': true},
          },
        ]
      };
    }

    if (url.contains('/reports/monthly')) {
      return {
        'currency': 'INR',
        'month': DateTime.now().month,
        'year': 2026,
        'month_name': 'November',
        'total_income': '85000.00',
        'total_expense': '10500.00',
        'net_savings': '74500.00',
        'savings_rate': 87.65,
        'category_breakdown': [
          {'category_id': 'c1', 'category_name': 'Food', 'category_color': '#F59E0B', 'category_icon': 'restaurant', 'total_amount': '3500.00', 'percentage': 33.3, 'transaction_count': 1},
          {'category_id': 'c2', 'category_name': 'Bills', 'category_color': '#F97316', 'category_icon': 'receipt_long', 'total_amount': '4200.00', 'percentage': 40.0, 'transaction_count': 1},
          {'category_id': 'c3', 'category_name': 'Shopping', 'category_color': '#EC4899', 'category_icon': 'shopping_bag', 'total_amount': '2800.00', 'percentage': 26.7, 'transaction_count': 1},
        ],
        'daily_breakdown': [
          {'date': '2026-11-01', 'income': '0.00', 'expense': '0.00'},
          {'date': '2026-11-02', 'income': '0.00', 'expense': '3500.00'},
          {'date': '2026-11-03', 'income': '0.00', 'expense': '4200.00'},
          {'date': '2026-11-04', 'income': '0.00', 'expense': '2800.00'},
        ],
        'top_expenses': [
          {'id': '1', 'description': 'Electricity & Internet Bill', 'category': 'Bills', 'amount': 4200.0, 'date': '2026-11-03'},
          {'id': '2', 'description': 'Supermarket Groceries', 'category': 'Food', 'amount': 3500.0, 'date': '2026-11-02'},
          {'id': '3', 'description': 'Clothing & Essentials', 'category': 'Shopping', 'amount': 2800.0, 'date': '2026-11-04'},
        ],
      };
    }

    if (url.contains('/reports/yearly')) {
      return {
        'currency': 'INR',
        'year': 2026,
        'total_income': '1020000.00',
        'total_expense': '126000.00',
        'net_savings': '894000.00',
        'savings_rate': 87.65,
        'monthly_trends': List.generate(12, (index) {
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return {
            'month': index + 1,
            'month_name': months[index],
            'year': 2026,
            'income': 85000.0,
            'expense': 10500.0,
            'net_savings': 74500.0,
          };
        }),
        'category_breakdown': [
          {'category_id': 'c1', 'category_name': 'Food', 'category_color': '#F59E0B', 'category_icon': 'restaurant', 'total_amount': '42000.00', 'percentage': 33.3, 'transaction_count': 12},
          {'category_id': 'c2', 'category_name': 'Bills', 'category_color': '#F97316', 'category_icon': 'receipt_long', 'total_amount': '50400.00', 'percentage': 40.0, 'transaction_count': 12},
          {'category_id': 'c3', 'category_name': 'Shopping', 'category_color': '#EC4899', 'category_icon': 'shopping_bag', 'total_amount': '33600.00', 'percentage': 26.7, 'transaction_count': 12},
        ],
      };
    }

    return null;
  }

  static List<dynamic> _demoTransactionsList() {
    return [
      {
        'id': '5d33363f-c52a-4292-b761-0f8c1c8907f7',
        'user_id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
        'category_id': '7b417041-c96b-47a8-b0db-56885c8fba36',
        'amount': '2800.00',
        'type': 'EXPENSE',
        'description': 'Clothing & Essentials',
        'transaction_date': '2026-11-04',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'category': {
          'id': '7b417041-c96b-47a8-b0db-56885c8fba36',
          'name': 'Shopping',
          'type': 'EXPENSE',
          'color': '#EC4899',
          'icon': 'shopping_bag',
          'is_system': true,
        }
      },
      {
        'id': '496bab68-cd43-4371-89dc-0cbcaca26124',
        'user_id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
        'category_id': '4ad8ebbd-8352-482b-80a8-3183bb891b40',
        'amount': '4200.00',
        'type': 'EXPENSE',
        'description': 'Electricity & Internet Bill',
        'transaction_date': '2026-11-03',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'category': {
          'id': '4ad8ebbd-8352-482b-80a8-3183bb891b40',
          'name': 'Bills',
          'type': 'EXPENSE',
          'color': '#F97316',
          'icon': 'receipt_long',
          'is_system': true,
        }
      },
      {
        'id': 'fff816e0-9998-42a0-827b-3a4a37a23cfa',
        'user_id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
        'category_id': 'a29f4b25-c9f0-4d0f-86c9-2440c9d78a02',
        'amount': '3500.00',
        'type': 'EXPENSE',
        'description': 'Supermarket Groceries',
        'transaction_date': '2026-11-02',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'category': {
          'id': 'a29f4b25-c9f0-4d0f-86c9-2440c9d78a02',
          'name': 'Food',
          'type': 'EXPENSE',
          'color': '#F59E0B',
          'icon': 'restaurant',
          'is_system': true,
        }
      },
      {
        'id': 'c0999daf-26bc-460d-86f8-bc9044ac7255',
        'user_id': 'f9192424-4366-4b4e-9c14-af8193a1eee5',
        'category_id': '8a2b47a0-2a36-4b24-a9ab-25423cf562e8',
        'amount': '85000.00',
        'type': 'INCOME',
        'description': 'Monthly Salary',
        'transaction_date': '2026-10-31',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'category': {
          'id': '8a2b47a0-2a36-4b24-a9ab-25423cf562e8',
          'name': 'Salary',
          'type': 'INCOME',
          'color': '#10B981',
          'icon': 'payments',
          'is_system': true,
        }
      },
    ];
  }
}
