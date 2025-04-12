import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final int id;
  final String name;
  final double amountOwed;
  final double amountPaid;
  final bool matched;
  final String userId;

  const Customer({
    required this.id,
    required this.name,
    required this.amountOwed,
    required this.amountPaid,
    required this.matched,
    required this.userId,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      name: json['name'] as String,
      amountOwed: (json['amountowed'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amountpaid'] as num?)?.toDouble() ?? 0.0,
      matched: json['matched'] as bool? ?? false,
      userId: json['user_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amountowed': amountOwed,
      'amountpaid': amountPaid,
      'matched': matched,
      'user_id': userId,
    };
  }

  Customer copyWith({
    int? id,
    String? name,
    double? amountOwed,
    double? amountPaid,
    bool? matched,
    String? userId,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      amountOwed: amountOwed ?? this.amountOwed,
      amountPaid: amountPaid ?? this.amountPaid,
      matched: matched ?? this.matched,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [id, name, amountOwed, amountPaid, matched, userId];
} 