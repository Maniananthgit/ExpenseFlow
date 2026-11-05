import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(num amount, {String currency = 'INR'}) {
    final symbol = getSymbol(currency);
    final formatter = NumberFormat('#,##,##0.00');
    return '$symbol${formatter.format(amount)}';
  }

  static String formatCompact(num amount, {String currency = 'INR'}) {
    final symbol = getSymbol(currency);
    if (amount.abs() >= 10000000) {
      return '$symbol${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount.abs() >= 100000) {
      return '$symbol${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount.abs() >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }

  static String getSymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '$currency ';
    }
  }
}

