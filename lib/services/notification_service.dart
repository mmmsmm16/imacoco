import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';

/// ローカル通知を管理するサービスクラス。
///
/// シングルトンパターンで実装されており、通知の初期化、権限リクエスト、
/// スケジューリング、キャンセル機能を提供します。
class NotificationService {
  // シングルトンインスタンス
  static final NotificationService _instance = NotificationService._internal();

  /// シングルトンインスタンスを取得するファクトリコンストラクタ。
  factory NotificationService() => _instance;

  NotificationService._internal();

  /// ローカル通知プラグインのインスタンス
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 初期化済みかどうかのフラグ
  bool _isInitialized = false;

  /// 通知サービスを初期化します。
  ///
  /// タイムゾーンの初期化、プラットフォームごとの設定、通知タップ時のコールバック設定を行います。
  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    // Androidの設定
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOSの設定
    // 初期化時には権限をリクエストせず、後で明示的にリクエストする
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 通知タップ時の処理
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    _isInitialized = true;
  }

  /// 通知の権限をユーザーにリクエストします。
  ///
  /// Android 13以降およびiOSで必要です。
  Future<void> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Android 13以降の通知権限リクエスト
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  /// 登録されている全ての通知をキャンセルします。
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// ステータスリセットを促す通知を1時間後にスケジュールします。
  ///
  /// 既存の通知はキャンセルされ、新しいスケジュールが設定されます。
  Future<void> scheduleResetNotification() async {
    await cancelAllNotifications();

    // 1時間後の時刻を計算
    // tz.localを使用するとロケーション設定が必要になるため、UTCを使用する
    // 相対時間が重要であるためUTCでも問題ない
    final scheduledDate = tz.TZDateTime.now(tz.UTC).add(const Duration(hours: 1));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // ID
      'Imacoco', // タイトル
      'まだご飯中？今の状態を更新してね', // 本文
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'imacoco_status_channel', // チャンネルID
          'Status Updates', // チャンネル名
          channelDescription: 'Notifications for status updates',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint('Notification scheduled for $scheduledDate (UTC)');
  }
}
