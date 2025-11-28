import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/user_status.dart';
import '../repositories/status_repository.dart';
import '../services/notification_service.dart';

class StatusProvider extends ChangeNotifier {
  final StatusRepository _repository;
  final NotificationService _notificationService = NotificationService();
  
  User? _currentUser;
  List<User> _friends = [];
  Timer? _autoResetTimer;
  StreamSubscription? _friendsSubscription;

  StatusProvider(this._repository) {
    _init();
  }

  User? get currentUser => _currentUser;
  List<User> get friends => _friends;

  void _init() async {
    // Initialize notification service
    await _notificationService.init();
    await _notificationService.requestPermissions();

    _friendsSubscription = _repository.friendsStream.listen((friends) {
      _friends = friends;
      notifyListeners();
    });
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final results = await Future.wait([
      _repository.getCurrentUser(),
      _repository.getFriends(),
    ]);

    _currentUser = results[0] as User;
    _friends = results[1] as List<User>;

    notifyListeners();
    _checkAutoReset();
  }

  Future<void> updateStatus(UserStatusType type) async {
    // Optimistic update
    final now = DateTime.now();
    _currentUser = _currentUser?.copyWith(
      status: UserStatus(type: type, updatedAt: now),
    );
    notifyListeners();

    _handleAutoResetAndNotification(type);

    try {
      await _repository.updateMyStatus(type);
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  void _handleAutoResetAndNotification(UserStatusType type) {
    _autoResetTimer?.cancel();
    
    // If unknown (reset), cancel notifications
    if (type == UserStatusType.unknown) {
      _notificationService.cancelAllNotifications();
      return;
    }

    // Schedule local notification
    _notificationService.scheduleResetNotification();

    // Set internal timer for auto-reset
    _autoResetTimer = Timer(UserStatus.expirationDuration, () {
      updateStatus(UserStatusType.unknown);
      debugPrint('Auto-reset triggered');
    });
  }

  void _checkAutoReset() {
    if (_currentUser == null) return;
    
    final status = _currentUser!.status;
    if (status.type == UserStatusType.unknown) return;

    if (status.isExpired) {
      updateStatus(UserStatusType.unknown);
    } else {
      // Resume timer for remaining time
      final remaining = status.expirationTime.difference(DateTime.now());
      _autoResetTimer?.cancel();
      _autoResetTimer = Timer(remaining, () {
        updateStatus(UserStatusType.unknown);
      });
      // Note: We don't reschedule notification here as it should persist from app termination
      // unless we want to be precise about rescheduling it.
      // For MVP, assuming the OS handles the scheduled notification is fine.
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
