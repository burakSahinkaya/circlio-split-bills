import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  expense,
  payment,
  memberJoined,
  memberLeft,
}

class Activity {
  final String id;
  final String groupId;
  final ActivityType type;
  final String description;
  final double? amount;
  final String? userId;
  final String? userName;
  final DateTime date;
  final Map<String, dynamic>? metadata;

  const Activity({
    required this.id,
    required this.groupId,
    required this.type,
    required this.description,
    this.amount,
    this.userId,
    this.userName,
    required this.date,
    this.metadata,
  });

  factory Activity.fromJson(Map<String, dynamic> json, {required String id}) {
    return Activity(
      id: id,
      groupId: json['groupId'] ?? '',
      type: _parseActivityType(json['type']),
      description: json['description'] ?? '',
      amount: (json['amount'] as num?)?.toDouble(),
      userId: json['userId'],
      userName: json['userName'],
      date: json['date'] is Timestamp
          ? (json['date'] as Timestamp).toDate()
          : DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'type': type.name,
      'description': description,
      'amount': amount,
      'userId': userId,
      'userName': userName,
      'date': Timestamp.fromDate(date),
      'metadata': metadata,
    };
  }

  static ActivityType _parseActivityType(String? typeString) {
    switch (typeString) {
      case 'expense':
        return ActivityType.expense;
      case 'payment':
        return ActivityType.payment;
      case 'memberJoined':
        return ActivityType.memberJoined;
      case 'memberLeft':
        return ActivityType.memberLeft;
      default:
        return ActivityType.expense;
    }
  }

  Activity copyWith({
    String? id,
    String? groupId,
    ActivityType? type,
    String? description,
    double? amount,
    String? userId,
    String? userName,
    DateTime? date,
    Map<String, dynamic>? metadata,
  }) {
    return Activity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      type: type ?? this.type,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      date: date ?? this.date,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Activity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
