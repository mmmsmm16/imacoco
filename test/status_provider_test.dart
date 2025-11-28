import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:imacoco/providers/status_provider.dart';
import 'package:imacoco/repositories/status_repository.dart';
import 'package:imacoco/models/user.dart';
import 'package:imacoco/models/user_status.dart';
import 'dart:async';

// Mockクラスの生成にはbuild_runnerが必要だが、
// ここでは簡易的に手動Mockを作成するか、Mockitoの基本的な機能を使う。
// generateMocksアノテーションは使わず、extends Mockで実装する。

class MockStatusRepository extends Mock implements StatusRepository {
  @override
  Stream<List<User>> get friendsStream => Stream.value([]);

  @override
  Future<User> getCurrentUser() async {
    return User(
      id: 'test_uid',
      name: 'Test User',
      status: UserStatus.unknown(),
    );
  }

  @override
  Future<List<User>> getFriends() async {
    return [];
  }

  @override
  Future<void> updateMyStatus(UserStatusType type) async {
    return;
  }
}

void main() {
  group('StatusProvider Tests', () {
    late StatusProvider provider;
    late MockStatusRepository mockRepository;

    setUp(() {
      mockRepository = MockStatusRepository();
      provider = StatusProvider(mockRepository);
    });

    test('Initial status should be loaded', () async {
      // 非同期初期化を待つ（providerのコンストラクタで呼ばれるが完了を待てないため）
      // _loadInitialDataの完了を待つ必要があるが、privateなので
      // 少し待機するか、状態変化を監視する。
      await Future.delayed(Duration(milliseconds: 100));

      expect(provider.currentUser?.id, 'test_uid');
      expect(provider.currentUser?.status.type, UserStatusType.unknown);
    });

    test('Update status changes current user status', () async {
      await Future.delayed(Duration(milliseconds: 100));

      await provider.updateStatus(UserStatusType.eating);

      expect(provider.currentUser?.status.type, UserStatusType.eating);
    });

    test('Status expires correctly (logic check)', () {
      final now = DateTime.now();
      final oldStatus = UserStatus(
        type: UserStatusType.awake,
        updatedAt: now.subtract(Duration(hours: 1, minutes: 1)),
      );

      expect(oldStatus.isExpired, true);

      final newStatus = UserStatus(
        type: UserStatusType.awake,
        updatedAt: now.subtract(Duration(minutes: 59)),
      );

      expect(newStatus.isExpired, false);
    });
  });
}
