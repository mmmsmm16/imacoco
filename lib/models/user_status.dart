enum UserStatusType {
  unknown,
  awake,
  eating,
  free,
  busy,
  gaming,
}

extension UserStatusTypeExtension on UserStatusType {
  String get emoji {
    switch (this) {
      case UserStatusType.awake:
        return '☀️';
      case UserStatusType.eating:
        return '🍚';
      case UserStatusType.free:
        return '🛌';
      case UserStatusType.busy:
        return '🚫';
      case UserStatusType.gaming:
        return '🎮';
      case UserStatusType.unknown:
      default:
        return '❓';
    }
  }

  String get label {
    switch (this) {
      case UserStatusType.awake:
        return '起きた';
      case UserStatusType.eating:
        return 'ご飯';
      case UserStatusType.free:
        return '暇';
      case UserStatusType.busy:
        return '集中';
      case UserStatusType.gaming:
        return 'ゲーム';
      case UserStatusType.unknown:
      default:
        return '不明';
    }
  }
}

class UserStatus {
  final UserStatusType type;
  final DateTime updatedAt;

  // ステータスの有効期限（1時間）
  static const Duration expirationDuration = Duration(hours: 1);

  const UserStatus({
    required this.type,
    required this.updatedAt,
  });

  factory UserStatus.unknown() {
    return UserStatus(
      type: UserStatusType.unknown,
      updatedAt: DateTime.now(),
    );
  }

  UserStatus copyWith({
    UserStatusType? type,
    DateTime? updatedAt,
  }) {
    return UserStatus(
      type: type ?? this.type,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// ステータスが有効期限切れかどうかを判定する
  bool get isExpired {
    if (type == UserStatusType.unknown) return false;
    return DateTime.now().difference(updatedAt) >= expirationDuration;
  }

  /// 有効期限が切れる時刻を取得
  DateTime get expirationTime => updatedAt.add(expirationDuration);
}
