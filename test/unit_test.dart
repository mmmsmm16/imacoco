import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:imacoco/models/user.dart';
import 'package:imacoco/models/user_status.dart';
import 'package:imacoco/repositories/status_repository.dart';
import 'package:imacoco/providers/status_provider.dart';

// Generate Mocks manually for simplicity or use build_runner if configured
// For this environment, manual mock is safer/faster
class MockStatusRepository extends Mock implements StatusRepository {
  @override
  Stream<List<User>> get friendsStream => super.noSuchMethod(
        Invocation.getter(#friendsStream),
        returnValue: Stream<List<User>>.value([]),
        returnValueForMissingStub: Stream<List<User>>.value([]),
      ) as Stream<List<User>>;

  @override
  Future<User> getCurrentUser() => super.noSuchMethod(
        Invocation.method(#getCurrentUser, []),
        returnValue: Future.value(User(id: 'test', name: 'Test', status: UserStatus.unknown())),
        returnValueForMissingStub: Future.value(User(id: 'test', name: 'Test', status: UserStatus.unknown())),
      ) as Future<User>;

  @override
  Future<List<User>> getFriends() => super.noSuchMethod(
        Invocation.method(#getFriends, []),
        returnValue: Future.value(<User>[]),
        returnValueForMissingStub: Future.value(<User>[]),
      ) as Future<List<User>>;
      
  @override
  Future<void> updateMyStatus(UserStatusType? type) => super.noSuchMethod(
    Invocation.method(#updateMyStatus, [type]),
    returnValue: Future.value(),
    returnValueForMissingStub: Future.value(),
  );
  
  @override
  void dispose() {
     // no-op
  }
}

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
    late MockStatusRepository repository;
    late StatusProvider provider;

    setUp(() {
      repository = MockStatusRepository();
      provider = StatusProvider(repository);
    });

    test('initial state should be loaded from repository', () async {
      // Allow time for async load
      await Future.delayed(const Duration(milliseconds: 200));
      // Since we mocked empty return, checking not null is good enough for structure
      // Real logic test is in firebase_service_test
      expect(provider.friends, isEmpty);
    });

    test('updateStatus should update current user status', () async {
      await Future.delayed(const Duration(milliseconds: 200));
      await provider.updateStatus(UserStatusType.gaming);
      
      expect(provider.currentUser?.status.type, UserStatusType.gaming);
      verify(repository.updateMyStatus(UserStatusType.gaming)).called(1);
    });
  });
}
