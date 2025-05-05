import 'package:equatable/equatable.dart';

enum TransactionType { buy, sell }

enum TransactionStatus { pending, matched, mismatched }

class Transaction extends Equatable {
  final int id;
  final String sellerName;
  final String buyerName;
  final String type;
  final String product;
  final int quantity;
  final double pricePerUnit;
  final double totalAmount;
  final DateTime? createdAt;
  final String matched;
  final String createdBy;
  final String? counterpartCreatedBy;
  final int? counterpartId;

  const Transaction({
    required this.id,
    required this.sellerName,
    required this.buyerName,
    required this.type,
    required this.product,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalAmount,
    this.createdAt,
    required this.matched,
    required this.createdBy,
    this.counterpartCreatedBy,
    this.counterpartId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      sellerName: json['seller_name'] as String,
      buyerName: json['buyer_name'] as String,
      type: json['type'] as String,
      product: json['product'] as String,
      quantity: json['quantity'] as int,
      pricePerUnit: (json['price_per_unit'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      matched: json['matched'] as String,
      createdBy: json['created_by'] as String,
      counterpartCreatedBy: json['counterpart_created_by'] as String?,
      counterpartId: json['counterpart_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'seller_name': sellerName,
      'buyer_name': buyerName,
      'type': type,
      'product': product,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'total_amount': totalAmount,
      'matched': matched,
      'created_by': createdBy,
    } as Map<String, dynamic>;
    
    if (counterpartCreatedBy != null) {
      map['counterpart_created_by'] = counterpartCreatedBy as String;
    }
    
    if (counterpartId != null) {
      map['counterpart_id'] = counterpartId as int;
    }
    
    if (id != 0) {
      map['id'] = id;
    }
    
    return map;
  }

  Transaction copyWith({
    int? id,
    String? sellerName,
    String? buyerName,
    String? type,
    String? product,
    int? quantity,
    double? pricePerUnit,
    double? totalAmount,
    DateTime? createdAt,
    String? matched,
    String? createdBy,
    String? counterpartCreatedBy,
    int? counterpartId,
  }) {
    return Transaction(
      id: id ?? this.id,
      sellerName: sellerName ?? this.sellerName,
      buyerName: buyerName ?? this.buyerName,
      type: type ?? this.type,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      matched: matched ?? this.matched,
      createdBy: createdBy ?? this.createdBy,
      counterpartCreatedBy: counterpartCreatedBy ?? this.counterpartCreatedBy,
      counterpartId: counterpartId ?? this.counterpartId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    sellerName,
    buyerName,
    type,
    product,
    quantity,
    pricePerUnit,
    totalAmount,
    createdAt,
    matched,
    createdBy,
    counterpartCreatedBy,
    counterpartId,
  ];
} 