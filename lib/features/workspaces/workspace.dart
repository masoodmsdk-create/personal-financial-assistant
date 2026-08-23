import 'package:personal_financial_assistant/core/models/entity.dart';

/// Represents an independent financial workspace context with user-provided purpose and priorities.
class Workspace implements Entity {
  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  final String name;
  final String purpose;
  final List<String> priorities;
  final bool isDefault;

  const Workspace({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.purpose,
    this.priorities = const [],
    this.isDefault = false,
  });

  /// Common workspace priorities users can select or customize.
  static const List<String> commonPriorities = [
    'Control spending',
    'Reduce debt',
    'Build emergency savings',
    'Save for a goal',
    'Understand cash flow',
    'Track property / rental profit',
    'Optimize investments',
  ];

  /// Creates a default personal workspace for a user.
  factory Workspace.createDefault(String userId) {
    final now = DateTime.now();
    return Workspace(
      id: 'ws_default_$userId',
      userId: userId,
      createdAt: now,
      updatedAt: now,
      name: 'Personal Finances',
      purpose: 'Manage daily personal income, living expenses, savings, and financial goals.',
      priorities: const [
        'Understand cash flow',
        'Control spending',
        'Build emergency savings',
      ],
      isDefault: true,
    );
  }

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      name: json['name'] as String? ?? 'Personal Finances',
      purpose: json['purpose'] as String? ?? '',
      priorities:
          (json['priorities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'name': name,
      'purpose': purpose,
      'priorities': priorities,
      'isDefault': isDefault,
    };
  }

  Workspace copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? purpose,
    List<String>? priorities,
    bool? isDefault,
  }) {
    return Workspace(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      purpose: purpose ?? this.purpose,
      priorities: priorities ?? this.priorities,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Workspace &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name == other.name &&
          purpose == other.purpose &&
          isDefault == other.isDefault;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      name.hashCode ^
      purpose.hashCode ^
      isDefault.hashCode;
}
