import 'user_status.dart';

/// アプリケーション内のユーザー情報を表現するモデルクラス。
///
/// ユーザーID、名前、現在のステータスを保持します。
class User {
  /// ユーザーの一意なID (Firebase AuthのUIDなど)
  final String id;

  /// ユーザーの表示名
  final String name;

  /// ユーザーの現在のステータス
  final UserStatus status;

  /// [User] のコンストラクタ。
  ///
  /// Args:
  ///   id: ユーザーID。
  ///   name: 表示名。
  ///   status: 現在のステータス。
  const User({
    required this.id,
    required this.name,
    required this.status,
  });

  /// 現在のインスタンスをコピーし、指定されたフィールドのみを更新した新しいインスタンスを返します。
  ///
  /// Args:
  ///   id: 新しいユーザーID（省略時は現在の値）。
  ///   name: 新しい名前（省略時は現在の値）。
  ///   status: 新しいステータス（省略時は現在の値）。
  ///
  /// Returns:
  ///   新しい User インスタンス。
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
