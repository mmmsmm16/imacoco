import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_models;
import '../models/user_status.dart';

class FirebaseService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _usersRef => 
      _firestore.collection('users');

  // Sign in anonymously
  Future<app_models.User> signIn() async {
    UserCredential credential;
    if (_auth.currentUser != null) {
      // Already signed in
      credential = await _auth.signInAnonymously(); // Refreshes session if needed, or just returns user
    } else {
      credential = await _auth.signInAnonymously();
    }
    
    final user = credential.user!;
    
    // Check if user doc exists, if not create initial
    var docSnap = await _usersRef.doc(user.uid).get();
    if (!docSnap.exists) {
      final initialData = {
        'name': 'ゲスト ${user.uid.substring(0, 4)}', // Simple random name
        'statusType': UserStatusType.unknown.index,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _usersRef.doc(user.uid).set(initialData);
      
      // Fetch again to get the data with the correct timestamp if needed, 
      // or simply construct the model from local initialData.
      // For simplicity in mock tests where serverTimestamp might behavior differently,
      // we can fetch again or pass local map.
      docSnap = await _usersRef.doc(user.uid).get();
    }

    // Convert to local model
    return _userFromDoc(user.uid, docSnap.data());
  }

  // Stream of all users (friends)
  Stream<List<app_models.User>> getUsersStream() {
    return _usersRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Skip current user? (Optional, but for MVP showing everyone is fine)
        return _userFromDoc(doc.id, doc.data());
      }).toList();
    });
  }

  // Update status
  Future<void> updateStatus(UserStatusType type) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _usersRef.doc(uid).update({
      'statusType': type.index,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update name (Optional helper)
  Future<void> updateName(String name) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _usersRef.doc(uid).update({'name': name});
  }

  app_models.User _userFromDoc(String uid, Map<String, dynamic>? data) {
    if (data == null) {
      return app_models.User(
        id: uid, 
        name: 'Unknown', 
        status: UserStatus.unknown(),
      );
    }

    final statusIndex = data['statusType'] as int? ?? 0;
    final timestamp = data['updatedAt'] as Timestamp?;
    final updatedAt = timestamp?.toDate() ?? DateTime.now();

    return app_models.User(
      id: uid,
      name: data['name'] as String? ?? 'No Name',
      status: UserStatus(
        type: UserStatusType.values[statusIndex],
        updatedAt: updatedAt,
      ),
    );
  }
}
