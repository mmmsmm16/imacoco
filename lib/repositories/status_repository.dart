import 'dart:async';
import '../models/user.dart';
import '../models/user_status.dart';
import '../services/firebase_service.dart';

class StatusRepository {
  final FirebaseService _firebaseService;

  StatusRepository({FirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? FirebaseService();

  Stream<List<User>> get friendsStream => _firebaseService.getUsersStream();

  Future<User> getCurrentUser() async {
    return await _firebaseService.signIn();
  }

  Future<List<User>> getFriends() async {
    // For initial load, we can just wait for the first element of the stream
    return await _firebaseService.getUsersStream().first;
  }

  Future<void> updateMyStatus(UserStatusType type) async {
    await _firebaseService.updateStatus(type);
  }

  void dispose() {
    // Nothing to dispose for now as service handles instances
  }
}
