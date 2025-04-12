import 'package:equatable/equatable.dart';

enum TransactionType { buy, sell }

enum TransactionStatus { pending, matched, mismatched }

class Transaction extends Equatable {
  final String id;
  final String userId;
  final String customerName;
  final int productId;
  final String productName;
  final TransactionType type;
  final int quantity;
  final int price;
  final TransactionStatus status;
  final DateTime createdAt;
  final String? counterpartId;
  final String? counterpartCreatedBy;

  const Transaction({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.price,
    required this.status,
    required this.createdAt,
    this.counterpartId,
    this.counterpartCreatedBy,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'].toString(),
      userId: json['created_by'] as String,
      customerName: json['type'] == 'Buying' 
          ? json['seller_name'] as String 
          : json['buyer_name'] as String,
      productId: 0, // Not in the database schema
      productName: json['product'] as String,
      type: json['type'] == 'Buying' ? TransactionType.buy : TransactionType.sell,
      quantity: json['quantity'] as int,
      price: (json['price_per_unit'] as num).toInt(),
      status: _parseStatus(json['matched'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      counterpartId: json['counterpart_id']?.toString(),
      counterpartCreatedBy: json['counterpart_created_by'] as String?,
    );
  }

  static TransactionStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'matched':
        return TransactionStatus.matched;
      case 'mismatched':
        return TransactionStatus.mismatched;
      default:
        return TransactionStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_by': userId,
      'product': productName,
      'type': type == TransactionType.buy ? 'Buying' : 'Selling',
      'quantity': quantity,
      'price_per_unit': price,
      'matched': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'counterpart_id': counterpartId,
      'counterpart_created_by': counterpartCreatedBy,
    };
  }

  Transaction copyWith({
    String? id,
    String? userId,
    String? customerName,
    int? productId,
    String? productName,
    TransactionType? type,
    int? quantity,
    int? price,
    TransactionStatus? status,
    DateTime? createdAt,
    String? counterpartId,
    String? counterpartCreatedBy,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      counterpartId: counterpartId ?? this.counterpartId,
      counterpartCreatedBy: counterpartCreatedBy ?? this.counterpartCreatedBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        customerName,
        productId,
        productName,
        type,
        quantity,
        price,
        status,
        createdAt,
        counterpartId,
        counterpartCreatedBy,
      ];
} 