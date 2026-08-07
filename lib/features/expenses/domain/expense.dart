import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String paidById;
  final List<ExpenseSplit> splits;
  final DateTime date;
  final String? category;
  final bool isPayment;
  final bool isConfirmed;

  const Expense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.paidById,
    required this.splits,
    required this.date,
    this.category,
    this.isPayment = false,
    this.isConfirmed = true, // Regular expenses are confirmed by default
  });

  /// Deserialize from Firestore document data.
  factory Expense.fromJson(Map<String, dynamic> json, {required String id}) {
    return Expense(
      id: id,
      groupId: json['groupId'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paidById: json['paidById'] ?? '',
      splits: (json['splits'] as List<dynamic>? ?? [])
          .map((s) => ExpenseSplit.fromJson(s as Map<String, dynamic>))
          .toList(),
      date: json['date'] is Timestamp
          ? (json['date'] as Timestamp).toDate()
          : DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      category: json['category'],
      isPayment: json['isPayment'] ?? false,
      isConfirmed: json['isConfirmed'] ?? true,
    );
  }

  /// Serialize to Firestore-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'paidById': paidById,
      'splits': splits.map((s) => s.toJson()).toList(),
      'date': Timestamp.fromDate(date),
      'category': category,
      'isPayment': isPayment,
      'isConfirmed': isConfirmed,
    };
  }

  Expense copyWith({
    String? id,
    String? groupId,
    String? description,
    double? amount,
    String? paidById,
    List<ExpenseSplit>? splits,
    DateTime? date,
    String? category,
    bool? isPayment,
    bool? isConfirmed,
  }) {
    return Expense(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paidById: paidById ?? this.paidById,
      splits: splits ?? this.splits,
      date: date ?? this.date,
      category: category ?? this.category,
      isPayment: isPayment ?? this.isPayment,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Expense && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ExpenseSplit {
  final String userId;
  final double amount;
  final bool isSettled;

  const ExpenseSplit({
    required this.userId,
    required this.amount,
    this.isSettled = false,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      userId: json['userId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      isSettled: json['isSettled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'amount': amount, 'isSettled': isSettled};
  }

  ExpenseSplit copyWith({String? userId, double? amount, bool? isSettled}) {
    return ExpenseSplit(
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      isSettled: isSettled ?? this.isSettled,
    );
  }
}
