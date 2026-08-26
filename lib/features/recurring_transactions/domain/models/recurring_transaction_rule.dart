import 'package:personal_financial_assistant/core/models/entity.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class RecurringTransactionRule implements Entity {
  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  final TransactionType type;
  final String name;
  final double amount;
  final String categoryId;
  final String accountId;
  final RecurrenceFrequency frequency;
  final int interval;
  final int? dayOfMonth;
  final int? dayOfWeek;
  final DateTime startDate;
  final DateTime? endDate;
  final bool active;
  final DateTime? lastGeneratedDate;
  final DateTime nextOccurrence;
  final bool autoGenerate;
  final String? note;

  const RecurringTransactionRule({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.frequency,
    this.interval = 1,
    this.dayOfMonth,
    this.dayOfWeek,
    required this.startDate,
    this.endDate,
    this.active = true,
    this.lastGeneratedDate,
    required this.nextOccurrence,
    this.autoGenerate = true,
    this.note,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  /// Returns the effective day of month intended by the user.
  /// Defaults to `startDate.day` if `dayOfMonth` was not explicitly set.
  int? get effectiveDayOfMonth {
    if (dayOfMonth != null) return dayOfMonth;
    if (frequency == RecurrenceFrequency.monthly ||
        frequency == RecurrenceFrequency.quarterly ||
        frequency == RecurrenceFrequency.halfYearly ||
        frequency == RecurrenceFrequency.yearly) {
      return startDate.day;
    }
    return null;
  }

  /// Returns true if this rule has expired past its end date.
  bool get isExpired {
    if (endDate == null) return false;
    return nextOccurrence.isAfter(endDate!);
  }

  /// Returns true if this rule is currently due for transaction generation as of [date].
  bool isDue([DateTime? date]) {
    if (!active) return false;
    final asOf = date ?? DateTime.now();
    final today = DateTime(asOf.year, asOf.month, asOf.day, 23, 59, 59);
    if (nextOccurrence.isAfter(today)) return false;
    if (endDate != null && nextOccurrence.isAfter(endDate!)) return false;
    return true;
  }

  factory RecurringTransactionRule.fromJson(Map<String, dynamic> json) {
    return RecurringTransactionRule(
      id: json['id'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      type: TransactionTypeX.fromString(json['type'] as String),
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      accountId: json['accountId'] as String,
      frequency: RecurrenceFrequencyX.fromString(json['frequency'] as String),
      interval: (json['interval'] as num?)?.toInt() ?? 1,
      dayOfMonth: json['dayOfMonth'] as int?,
      dayOfWeek: json['dayOfWeek'] as int?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      active: json['active'] as bool? ?? true,
      lastGeneratedDate: json['lastGeneratedDate'] != null
          ? DateTime.parse(json['lastGeneratedDate'] as String)
          : null,
      nextOccurrence: DateTime.parse(json['nextOccurrence'] as String),
      autoGenerate: json['autoGenerate'] as bool? ?? true,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'type': type.value,
      'name': name,
      'amount': amount,
      'categoryId': categoryId,
      'accountId': accountId,
      'frequency': frequency.value,
      'interval': interval,
      'dayOfMonth': dayOfMonth,
      'dayOfWeek': dayOfWeek,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'active': active,
      'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
      'nextOccurrence': nextOccurrence.toIso8601String(),
      'autoGenerate': autoGenerate,
      'note': note,
    };
  }

  RecurringTransactionRule copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    TransactionType? type,
    String? name,
    double? amount,
    String? categoryId,
    String? accountId,
    RecurrenceFrequency? frequency,
    int? interval,
    int? dayOfMonth,
    int? dayOfWeek,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
    DateTime? lastGeneratedDate,
    DateTime? nextOccurrence,
    bool? autoGenerate,
    String? note,
  }) {
    return RecurringTransactionRule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      active: active ?? this.active,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      autoGenerate: autoGenerate ?? this.autoGenerate,
      note: note ?? this.note,
    );
  }

  String get frequencyDescription {
    final intvl = interval <= 1 ? '' : 'Every $interval ';
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return interval <= 1 ? 'Daily' : '${intvl}Days';
      case RecurrenceFrequency.weekly:
        final weekdayName = dayOfWeek != null
            ? _getWeekdayName(dayOfWeek!)
            : '';
        return interval <= 1
            ? (weekdayName.isNotEmpty ? 'Weekly on $weekdayName' : 'Weekly')
            : '${intvl}Weeks${weekdayName.isNotEmpty ? ' on $weekdayName' : ''}';
      case RecurrenceFrequency.monthly:
        final dayStr = dayOfMonth != null ? _getDaySuffix(dayOfMonth!) : '';
        return interval <= 1
            ? (dayStr.isNotEmpty ? 'Monthly on the $dayStr' : 'Monthly')
            : '${intvl}Months${dayStr.isNotEmpty ? ' on the $dayStr' : ''}';
      case RecurrenceFrequency.quarterly:
        return 'Quarterly (Every 3 Months)';
      case RecurrenceFrequency.halfYearly:
        return 'Half-Yearly (Every 6 Months)';
      case RecurrenceFrequency.yearly:
        return interval <= 1 ? 'Yearly' : '${intvl}Years';
      case RecurrenceFrequency.oneTime:
        return 'One-Time';
    }
  }

  static String _getWeekdayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (weekday >= 1 && weekday <= 7) return days[weekday - 1];
    return '';
  }

  static String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }
}
