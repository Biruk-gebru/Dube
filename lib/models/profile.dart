import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  final String id;
  final String userId;
  final String username;
  final String email;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.userId,
    required this.username,
    required this.email,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? id,
    String? userId,
    String? username,
    String? email,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, username, email, createdAt];
} 