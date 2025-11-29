import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/user_status.dart';
import '../repositories/status_repository.dart';
import '../services/notification_service.dart';

/// ユーザーの状態（ステータス）を管理するProviderクラス。
///
/// ユーザー自身のステータス更新、友達リストの同期、
/// およびステータスの自動リセット・通知スケジュールのロジックを担当します。
class StatusProvider extends ChangeNotifier {
  final StatusRepository _repository;
  final NotificationService _notificationService = NotificationService();
  
  User? _currentUser;
  List<User> _friends = [];
  Timer? _autoResetTimer;
  StreamSubscription? _friendsSubscription;

  // カスタムバブル機能用のリスト
  List<String> _customBubbles = [];
  // 非表示にしたデフォルトバブル（インデックスで保存）
  List<int> _hiddenDefaultBubbleIndices = [];

  static const String _prefsCustomBubblesKey = 'custom_bubbles';
  static const String _prefsHiddenDefaultsKey = 'hidden_default_bubbles';

  /// [StatusProvider] のコンストラクタ。
  ///
  /// Args:
  ///   repository: データ操作を行うリポジトリ。
  StatusProvider(this._repository) {
    _init();
  }

  /// 現在のログインユーザー。
  User? get currentUser => _currentUser;

  /// 友達（全ユーザー）のリスト。
  List<User> get friends => _friends;

  /// ローカル保存されたカスタムバブル（絵文字）のリスト
  List<String> get customBubbles => _customBubbles;

  /// 非表示になっているデフォルトバブルの種類のリスト
  List<UserStatusType> get hiddenDefaultTypes =>
    _hiddenDefaultBubbleIndices.map((i) => UserStatusType.values[i]).toList();

  /// 初期化処理。
  ///
  /// 通知サービスの初期化、友達リストの監視、初期データの読み込みを行います。
  void _init() async {
    // 通知サービスの初期化と権限リクエスト
    await _notificationService.init();
    await _notificationService.requestPermissions();

    // ローカルデータの読み込み
    await _loadLocalPreferences();

    // 友達リストの変更を監視
    _friendsSubscription = _repository.friendsStream.listen((friends) {
      _friends = friends;
      notifyListeners();
    });

    // 初期データのロード（自分の情報など）
    _loadInitialData();
  }

  /// カスタムバブルと非表示設定をSharedPreferencesから読み込みます。
  Future<void> _loadLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customBubbles = prefs.getStringList(_prefsCustomBubblesKey) ?? [];

      final hiddenIndices = prefs.getStringList(_prefsHiddenDefaultsKey);
      if (hiddenIndices != null) {
        _hiddenDefaultBubbleIndices = hiddenIndices.map((e) => int.parse(e)).toList();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local preferences: $e');
    }
  }

  /// カスタムバブルを追加します。
  Future<void> addCustomBubble(String emoji) async {
    if (_customBubbles.contains(emoji)) return;

    _customBubbles.add(emoji);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsCustomBubblesKey, _customBubbles);
  }

  /// カスタムバブルを削除します。
  Future<void> removeCustomBubble(String emoji) async {
    _customBubbles.remove(emoji);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsCustomBubblesKey, _customBubbles);
  }

  /// デフォルトバブルを非表示にします（削除扱い）。
  Future<void> hideDefaultBubble(UserStatusType type) async {
    if (_hiddenDefaultBubbleIndices.contains(type.index)) return;

    _hiddenDefaultBubbleIndices.add(type.index);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsHiddenDefaultsKey,
      _hiddenDefaultBubbleIndices.map((e) => e.toString()).toList(),
    );
  }

  /// 非表示にしたデフォルトバブルを全て元に戻します（オプション機能）。
  Future<void> restoreDefaultBubbles() async {
    _hiddenDefaultBubbleIndices.clear();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsHiddenDefaultsKey);
  }

  /// 初期データの読み込み。
  ///
  /// 自分自身のユーザー情報と友達リストの初期状態を取得します。
  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _repository.getCurrentUser(),
        _repository.getFriends(),
      ]);

      _currentUser = results[0] as User;
      _friends = results[1] as List<User>;

      notifyListeners();

      // 起動時にステータスの有効期限をチェック
      _checkAutoReset();
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      // エラー時の処理（再試行ロジックなど）はここに記述
    }
  }

  /// 自分のステータスを更新します。
  ///
  /// UIへの即時反映（Optimistic Update）、自動リセットタイマーの設定、
  /// 通知のスケジュール、リポジトリを通じたデータ保存を行います。
  ///
  /// Args:
  ///   type: 新しいステータスの種類。
  ///   customEmoji: カスタム絵文字（省略可）。
  Future<void> updateStatus(UserStatusType type, {String? customEmoji}) async {
    // 楽観的UI更新（サーバーレスポンスを待たずにUIを更新）
    final now = DateTime.now();
    _currentUser = _currentUser?.copyWith(
      status: UserStatus(
        type: type,
        updatedAt: now,
        customEmoji: customEmoji,
      ),
    );
    notifyListeners();

    // 自動リセットと通知の処理
    _handleAutoResetAndNotification(type);

    try {
      await _repository.updateMyStatus(type, customEmoji: customEmoji);
    } catch (e) {
      debugPrint('Error updating status: $e');
      // 必要であればエラー時に元の状態に戻す処理を追加
    }
  }

  /// 自動リセットタイマーと通知スケジュールの管理を行います。
  ///
  /// ステータスが「不明」の場合はタイマーと通知をキャンセルします。
  /// それ以外の場合は、通知をスケジュールし、タイマーをセットします。
  void _handleAutoResetAndNotification(UserStatusType type) {
    _autoResetTimer?.cancel();
    
    // ステータスが不明（リセット状態）なら、通知もキャンセル
    if (type == UserStatusType.unknown) {
      _notificationService.cancelAllNotifications();
      return;
    }

    // 1時間後のリセット通知をスケジュール
    _notificationService.scheduleResetNotification();

    // アプリ内での自動リセットタイマーを設定
    _autoResetTimer = Timer(UserStatus.expirationDuration, () {
      updateStatus(UserStatusType.unknown);
      debugPrint('Auto-reset triggered');
    });
  }

  /// 起動時にステータスの有効期限をチェックします。
  ///
  /// 既に期限切れの場合は「不明」に更新します。
  /// 期限が残っている場合は、残りの時間でタイマーを再設定します。
  void _checkAutoReset() {
    if (_currentUser == null) return;
    
    final status = _currentUser!.status;
    if (status.type == UserStatusType.unknown) return;

    if (status.isExpired) {
      // 期限切れならリセット
      updateStatus(UserStatusType.unknown);
    } else {
      // 残り時間を計算してタイマーを再開
      final remaining = status.expirationTime.difference(DateTime.now());
      _autoResetTimer?.cancel();
      _autoResetTimer = Timer(remaining, () {
        updateStatus(UserStatusType.unknown);
      });
      // 注: ここでは通知の再スケジュールは行っていません。
      // アプリが終了していてもOS側でスケジュールされた通知は有効なためです。
      // 厳密に整合性を取るなら再スケジュールしても良いでしょう。
    }
  }

  @override
  void dispose() {
    _autoResetTimer?.cancel();
    _friendsSubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
