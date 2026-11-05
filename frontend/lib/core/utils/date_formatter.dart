import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDisplay(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatShort(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  static String formatApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatMonthYear(int month, int year) {
    final dt = DateTime(year, month);
    return DateFormat('MMMM yyyy').format(dt);
  }

  static DateTime parseApi(String dateStr) {
    return DateTime.parse(dateStr);
  }
}

