import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/user_status.dart';
import '../repositories/status_repository.dart';

class StatusProvider extends ChangeNotifier {
  final StatusRepository _repository;
  
  User? _currentUser;
  List<User> _friends = [];
  Timer? _autoResetTimer;
  StreamSubscription? _friendsSubscription;
  
  // Auto-reset duration (e.g., 1 hour)
  // Making it shorter for testing purposes if needed, but keeping requirement of 1h
  static const Duration _autoResetDuration = Duration(hours: 1);

  StatusProvider(this._repository) {
    _init();
  }

  User? get currentUser => _currentUser;
  List<User> get friends => _friends;

  void _init() {
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

    _startAutoResetTimer();

    try {
      await _repository.updateMyStatus(type);
    } catch (e) {
      // Revert on error (omitted for MVP)
      debugPrint('Error updating status: $e');
    }
  }

  void _startAutoResetTimer() {
    _autoResetTimer?.cancel();
    
    // If we are already unknown, don't start the timer
    if (_currentUser?.status.type == UserStatusType.unknown) return;

    _autoResetTimer = Timer(_autoResetDuration, () {
      updateStatus(UserStatusType.unknown);
      // Logic for local notification would trigger here
      debugPrint('Auto-reset triggered');
    });
  }

  void _checkAutoReset() {
    if (_currentUser == null) return;
    
    final status = _currentUser!.status;
    if (status.type == UserStatusType.unknown) return;

    final diff = DateTime.now().difference(status.updatedAt);
    if (diff >= _autoResetDuration) {
      updateStatus(UserStatusType.unknown);
    } else {
      // Resume timer for remaining time
      final remaining = _autoResetDuration - diff;
      _autoResetTimer?.cancel();
      _autoResetTimer = Timer(remaining, () {
        updateStatus(UserStatusType.unknown);
      });
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
