import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final int id;
  final String name;
  final double amountOwed;
  final double amountPaid;
  final bool matched;
  final String? userId;  // The ID of the registered customer (if they are registered)
  final String ownerId; // The ID of the user who created/owns this customer relationship
  final bool isRegistered;

  const Customer({
    required this.id,
    required this.name,
    this.amountOwed = 0.0,
    this.amountPaid = 0.0,
    this.matched = false,
    this.userId,
    required this.ownerId,
    this.isRegistered = false,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      name: json['name'] as String,
      amountOwed: (json['amountowed'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amountpaid'] as num?)?.toDouble() ?? 0.0,
      matched: json['matched'] as bool? ?? false,
      userId: json['user_id'] as String?,
      ownerId: json['owner_id'] as String,
      isRegistered: json['is_registered'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amountowed': amountOwed,
      'amountpaid': amountPaid,
      'matched': matched,
      'user_id': userId,
      'owner_id': ownerId,
      'is_registered': isRegistered,
    };
  }

  Customer copyWith({
    int? id,
    String? name,
    double? amountOwed,
    double? amountPaid,
    bool? matched,
    String? userId,
    String? ownerId,
    bool? isRegistered,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      amountOwed: amountOwed ?? this.amountOwed,
      amountPaid: amountPaid ?? this.amountPaid,
      matched: matched ?? this.matched,
      userId: userId ?? this.userId,
      ownerId: ownerId ?? this.ownerId,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }

  @override
  List<Object?> get props => [id, name, amountOwed, amountPaid, matched, userId, ownerId, isRegistered];
} 