import 'package:flutter/material.dart';

/// ユーザーの現在の状態を表す列挙型。
///
/// - [unknown]: 不明（初期状態または期限切れ）
/// - [awake]: 起きた（活動開始）
/// - [eating]: ご飯（食事中）
/// - [free]: 暇（連絡歓迎）
/// - [busy]: 集中（連絡不可）
/// - [gaming]: ゲーム（プレイ中）
enum UserStatusType {
  unknown,
  awake,
  eating,
  free,
  busy,
  gaming,
}

/// [UserStatusType] に対する拡張メソッド。
///
/// 表示用の絵文字、ラベル、テーマカラーを取得する機能を提供します。
extension UserStatusTypeExtension on UserStatusType {
  /// ステータスに対応する絵文字を取得します。
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

  /// ステータスに対応する日本語ラベルを取得します。
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

  /// ステータスに対応するテーマカラーを取得します。
  /// UIでの背景色やアクセントカラーとして使用します。
  Color get color {
    switch (this) {
      case UserStatusType.awake:
        return Colors.orangeAccent;
      case UserStatusType.eating:
        return Colors.lightGreen;
      case UserStatusType.free:
        return Colors.lightBlueAccent;
      case UserStatusType.busy:
        return Colors.redAccent;
      case UserStatusType.gaming:
        return Colors.purpleAccent;
      case UserStatusType.unknown:
      default:
        return Colors.grey;
    }
  }
}

/// ユーザーのステータス情報を保持するクラス。
///
/// ステータスの種類と更新日時を管理します。
/// また、ステータスの有効期限に関するロジックも提供します。
class UserStatus {
  /// ステータスの種類
  final UserStatusType type;

  /// ステータスが更新された日時
  final DateTime updatedAt;

  /// ステータスの有効期限（1時間）
  static const Duration expirationDuration = Duration(hours: 1);

  /// [UserStatus] のコンストラクタ。
  ///
  /// Args:
  ///   type: ステータスの種類。
  ///   updatedAt: 更新日時。
  const UserStatus({
    required this.type,
    required this.updatedAt,
  });

  /// 「不明」状態のインスタンスを作成するファクトリメソッド。
  ///
  /// 現在時刻を更新日時として設定します。
  ///
  /// Returns:
  ///   UserStatusType.unknown な UserStatus インスタンス。
  factory UserStatus.unknown() {
    return UserStatus(
      type: UserStatusType.unknown,
      updatedAt: DateTime.now(),
    );
  }

  /// 現在のインスタンスをコピーし、指定されたフィールドのみを更新した新しいインスタンスを返します。
  ///
  /// Args:
  ///   type: 新しいステータスの種類（省略時は現在の値）。
  ///   updatedAt: 新しい更新日時（省略時は現在の値）。
  ///
  /// Returns:
  ///   新しい UserStatus インスタンス。
  UserStatus copyWith({
    UserStatusType? type,
    DateTime? updatedAt,
  }) {
    return UserStatus(
      type: type ?? this.type,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// ステータスが有効期限切れかどうかを判定します。
  ///
  /// ステータスが `unknown` の場合は常に false を返します。
  /// 更新日時から [expirationDuration] 以上経過している場合に true を返します。
  ///
  /// Returns:
  ///   有効期限切れであれば true、そうでなければ false。
  bool get isExpired {
    if (type == UserStatusType.unknown) return false;
    return DateTime.now().difference(updatedAt) >= expirationDuration;
  }

  /// 有効期限が切れる時刻を取得します。
  ///
  /// Returns:
  ///   更新日時 + 有効期限 の DateTime。
  DateTime get expirationTime => updatedAt.add(expirationDuration);
}
