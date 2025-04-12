import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final String name;
  final int stock;
  final int price;
  final int sold;
  final String userId;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.stock,
    required this.price,
    required this.sold,
    required this.userId,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      stock: json['stock'],
      price: json['price'],
      sold: json['sold'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stock': stock,
      'price': price,
      'sold': sold,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Product copyWith({
    int? id,
    String? name,
    int? stock,
    int? price,
    int? sold,
    String? userId,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      stock: stock ?? this.stock,
      price: price ?? this.price,
      sold: sold ?? this.sold,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, stock, price, sold, userId, createdAt];
} 