import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_models;
import '../models/user_status.dart';

/// Firebase (Auth, Firestore) との直接的な通信を行うサービスクラス。
///
/// 認証、データベース操作の詳細をカプセル化します。
class FirebaseService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// [FirebaseService] のコンストラクタ。
  ///
  /// Args:
  ///   auth: FirebaseAuthインスタンス（テスト用）。
  ///   firestore: FirebaseFirestoreインスタンス（テスト用）。
  FirebaseService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// ユーザーコレクションへの参照を取得します。
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// 匿名サインインを行い、現在のユーザー情報を取得します。
  ///
  /// 既にサインイン済みの場合はそのセッションを利用します。
  /// ユーザーードキュメントがFirestoreに存在しない場合は新規作成します。
  ///
  /// Returns:
  ///   現在のユーザー情報を表す [app_models.User]。
  Future<app_models.User> signIn() async {
    UserCredential credential;
    if (_auth.currentUser != null) {
      // 既にサインイン済み
      credential = await _auth.signInAnonymously(); // 必要に応じてセッションをリフレッシュ、または現在のユーザーを返す
    } else {
      credential = await _auth.signInAnonymously();
    }

    final user = credential.user!;

    // ユーザードキュメントが存在するか確認し、なければ初期データを作成
    var docSnap = await _usersRef.doc(user.uid).get();
    if (!docSnap.exists) {
      final initialData = {
        'name': 'ゲスト ${user.uid.substring(0, 4)}', // 簡易的なランダム名
        'statusType': UserStatusType.unknown.index,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _usersRef.doc(user.uid).set(initialData);

      // 正しいタイムスタンプを含んだデータを再取得
      // (serverTimestampの挙動やモックテストでの整合性を保つため)
      docSnap = await _usersRef.doc(user.uid).get();
    }

    // ローカルモデルに変換して返す
    return _userFromDoc(user.uid, docSnap.data());
  }

  /// 全ユーザー（友達）のリストをリアルタイムで取得するストリームを提供します。
  ///
  /// Firestoreの変更を監視し、変更があるたびに新しいリストを流します。
  ///
  /// Returns:
  ///   [app_models.User] のリストのストリーム。
  Stream<List<app_models.User>> getUsersStream() {
    return _usersRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // 必要であればここで自分自身を除外するロジックを追加可能
        // MVPでは全員表示とする
        return _userFromDoc(doc.id, doc.data());
      }).toList();
    });
  }

  /// 自分のステータスを更新します。
  ///
  /// Firestore上のユーザードキュメントのステータスと更新日時を更新します。
  /// カスタム絵文字が指定された場合はそれも保存します。
  ///
  /// Args:
  ///   type: 新しいステータスの種類。
  ///   customEmoji: カスタム絵文字（省略可）。
  Future<void> updateStatus(UserStatusType type, {String? customEmoji}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final data = <String, dynamic>{
      'statusType': type.index,
      'updatedAt': FieldValue.serverTimestamp(),
      'customEmoji': customEmoji, // nullの場合フィールドを削除するかnullをセットするかは要件次第だが、null更新で消える挙動を期待
    };

    // null値はFirestoreのフィールド削除として扱うか、明示的にFieldValue.delete()を使うべき場合もあるが
    // ここでは上書き更新としてnull許容でセットする。
    // もし明示的に消したい場合はFieldValue.delete()を使う必要があるが、
    // 基本的に上書きでOK。customEmojiが指定されていない場合はnullで上書きして消す。

    await _usersRef.doc(uid).set(data, SetOptions(merge: true));
  }

  /// ユーザー名を更新します（オプション機能）。
  ///
  /// Args:
  ///   name: 新しいユーザー名。
  Future<void> updateName(String name) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _usersRef.doc(uid).update({'name': name});
  }

  /// Firestoreのドキュメントデータを [app_models.User] に変換するヘルパーメソッド。
  ///
  /// Args:
  ///   uid: ユーザーID。
  ///   data: Firestoreから取得したMapデータ。
  ///
  /// Returns:
  ///   変換された [app_models.User] オブジェクト。
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
    final customEmoji = data['customEmoji'] as String?;

    return app_models.User(
      id: uid,
      name: data['name'] as String? ?? 'No Name',
      status: UserStatus(
        type: UserStatusType.values[statusIndex],
        updatedAt: updatedAt,
        customEmoji: customEmoji,
      ),
    );
  }
}
