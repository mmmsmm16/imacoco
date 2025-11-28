import 'user_status.dart';

class User {
  final String id;
  final String name;
  final UserStatus status;

  const User({
    required this.id,
    required this.name,
    required this.status,
  });

  User copyWith({
    String? id,
    String? name,
    UserStatus? status,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
    );
  }
}
