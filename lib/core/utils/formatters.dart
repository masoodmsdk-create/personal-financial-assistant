import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final Map<String, NumberFormat> _formatters = {};

  static NumberFormat _getFormatter(String currencyCode, String locale) {
    final key = '$currencyCode-$locale';
    return _formatters.putIfAbsent(key, () {
      return NumberFormat.currency(
        locale: locale,
        symbol: _getCurrencySymbol(currencyCode),
        decimalDigits: 2,
      );
    });
  }

  static String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currencyCode;
    }
  }

  static String format(
    double amount, {
    String currencyCode = 'INR',
    String locale = 'en_IN',
  }) {
    final formatter = _getFormatter(currencyCode, locale);
    return formatter.format(amount);
  }

  static String formatCompact(
    double amount, {
    String currencyCode = 'INR',
    String locale = 'en_IN',
  }) {
    final formatter = NumberFormat.compactCurrency(
      locale: locale,
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 1,
    );
    return formatter.format(amount);
  }

  static String formatWithSign(
    double amount, {
    String currencyCode = 'INR',
    String locale = 'en_IN',
  }) {
    final prefix = amount >= 0 ? '+' : '';
    return '$prefix${format(amount, currencyCode: currencyCode, locale: locale)}';
  }
}

class DateFormatter {
  static final Map<String, DateFormat> _formatters = {};

  static DateFormat _getFormatter(String pattern, String locale) {
    final key = '$pattern-$locale';
    return _formatters.putIfAbsent(key, () => DateFormat(pattern, locale));
  }

  static String format(
    DateTime date, {
    String pattern = 'dd MMM yyyy',
    String locale = 'en_IN',
  }) {
    return _getFormatter(pattern, locale).format(date);
  }

  static String formatShort(DateTime date, {String locale = 'en_IN'}) {
    return format(date, pattern: 'dd/MM/yyyy', locale: locale);
  }

  static String formatMonthYear(DateTime date, {String locale = 'en_IN'}) {
    return format(date, pattern: 'MMM yyyy', locale: locale);
  }

  static String formatTime(DateTime date, {String locale = 'en_IN'}) {
    return format(date, pattern: 'hh:mm a', locale: locale);
  }

  static String formatRelative(DateTime date, {String locale = 'en_IN'}) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
    return formatShort(date, locale: locale);
  }
}

class NumberFormatter {
  static String formatNumber(double value, {int decimalDigits = 2}) {
    return value.toStringAsFixed(decimalDigits);
  }

  static String formatPercentage(double value, {int decimalDigits = 1}) {
    return '${(value * 100).toStringAsFixed(decimalDigits)}%';
  }
}
