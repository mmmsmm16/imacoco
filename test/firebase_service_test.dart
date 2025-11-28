import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:imacoco/models/user_status.dart';
import 'package:imacoco/services/firebase_service.dart';

void main() {
  group('FirebaseService', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;
    late FirebaseService service;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = FakeFirebaseFirestore();
      service = FirebaseService(auth: mockAuth, firestore: mockFirestore);
    });

    test('signIn creates a new user document if it does not exist', () async {
      final user = await service.signIn();
      
      expect(user.id, isNotEmpty);
      expect(user.name, contains('ゲスト')); // Checks default name generation
      
      // Verify in Firestore
      final snapshot = await mockFirestore.collection('users').doc(user.id).get();
      expect(snapshot.exists, true);
    });

    test('updateStatus updates the document in Firestore', () async {
      // Must sign in first to have a current user
      await service.signIn();
      final uid = mockAuth.currentUser!.uid;

      await service.updateStatus(UserStatusType.gaming);

      final snapshot = await mockFirestore.collection('users').doc(uid).get();
      expect(snapshot.data()?['statusType'], UserStatusType.gaming.index);
    });
  });
}
