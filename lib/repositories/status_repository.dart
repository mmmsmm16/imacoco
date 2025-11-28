import 'dart:async';
import '../models/user.dart';
import '../models/user_status.dart';

class StatusRepository {
  // Mock data simulation
  final List<User> _mockFriends = [
    User(
      id: '1',
      name: 'Alice',
      status: UserStatus(
          type: UserStatusType.awake,
          updatedAt: DateTime.now().subtract(const Duration(minutes: 10))),
    ),
    User(
      id: '2',
      name: 'Bob',
      status: UserStatus(
          type: UserStatusType.busy,
          updatedAt: DateTime.now().subtract(const Duration(hours: 2))),
    ),
    User(
      id: '3',
      name: 'Charlie',
      status: UserStatus.unknown(),
    ),
  ];

  User _currentUser = User(
    id: 'me',
    name: '自分',
    status: UserStatus.unknown(),
  );

  final _friendsController = StreamController<List<User>>.broadcast();

  StatusRepository() {
    // Initial emit
    _emitFriends();
  }

  Stream<List<User>> get friendsStream => _friendsController.stream;

  Future<List<User>> getFriends() async {
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockFriends;
  }

  Future<User> getCurrentUser() async {
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentUser;
  }

  Future<void> updateMyStatus(UserStatusType type) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Network delay
    _currentUser = _currentUser.copyWith(
      status: UserStatus(
        type: type,
        updatedAt: DateTime.now(),
      ),
    );
    // In a real app, this would also push to the backend and the stream would update from backend events.
    // Here we just notify listeners if we were showing ourselves in the list (optional).
  }

  // Simulate receiving updates from friends
  void _emitFriends() {
    _friendsController.add(_mockFriends);
  }

  void dispose() {
    _friendsController.close();
  }
}
