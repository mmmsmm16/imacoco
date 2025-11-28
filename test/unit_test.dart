import 'package:flutter_test/flutter_test.dart';
import 'package:imacoco/models/user_status.dart';
import 'package:imacoco/repositories/status_repository.dart';
import 'package:imacoco/providers/status_provider.dart';

void main() {
  group('UserStatus', () {
    test('unknown status should have unknown type', () {
      final status = UserStatus.unknown();
      expect(status.type, UserStatusType.unknown);
    });

    test('emoji getter should return correct emoji', () {
      expect(UserStatusType.awake.emoji, '☀️');
      expect(UserStatusType.eating.emoji, '🍚');
    });
  });

  group('StatusProvider', () {
    late StatusRepository repository;
    late StatusProvider provider;

    setUp(() {
      repository = StatusRepository();
      provider = StatusProvider(repository);
    });

    test('initial state should be loaded from repository', () async {
      // Allow time for async load
      await Future.delayed(const Duration(milliseconds: 200));
      expect(provider.currentUser, isNotNull);
      expect(provider.friends, isNotEmpty);
    });

    test('updateStatus should update current user status', () async {
      await Future.delayed(const Duration(milliseconds: 200));
      await provider.updateStatus(UserStatusType.gaming);
      
      expect(provider.currentUser?.status.type, UserStatusType.gaming);
    });
  });
}
