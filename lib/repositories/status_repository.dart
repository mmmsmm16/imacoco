import 'dart:async';
import '../models/user.dart';
import '../models/user_status.dart';
import '../services/firebase_service.dart';

/// ステータスに関するデータ操作を抽象化するリポジトリクラス。
///
/// UI層（ViewModel/Provider）とデータソース（FirebaseService）の橋渡しを行います。
/// データの取得元がFirebaseであるか、モックであるかなどの詳細を隠蔽します。
class StatusRepository {
  /// Firebaseサービスへの参照
  final FirebaseService _firebaseService;

  /// [StatusRepository] のコンストラクタ。
  ///
  /// Args:
  ///   firebaseService: 依存注入用のFirebaseServiceインスタンス（省略可）。
  StatusRepository({FirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? FirebaseService();

  /// 友達（全ユーザー）の更新を監視するストリームを取得します。
  ///
  /// Returns:
  ///   Userオブジェクトのリストを流すStream。
  Stream<List<User>> get friendsStream => _firebaseService.getUsersStream();

  /// 現在のログインユーザーを取得します。
  ///
  /// ログインしていない場合は、匿名認証を行ってユーザーを作成・取得します。
  ///
  /// Returns:
  ///   現在の User オブジェクト。
  Future<User> getCurrentUser() async {
    return await _firebaseService.signIn();
  }

  /// 友達リストの初期データを取得します。
  ///
  /// ストリームの最初の要素を取得することで実現しています。
  ///
  /// Returns:
  ///   Userオブジェクトのリスト。
  Future<List<User>> getFriends() async {
    // 初期ロードのために、ストリームの最初の要素を待機して返す
    return await _firebaseService.getUsersStream().first;
  }

  /// 自分のステータスを更新します。
  ///
  /// Args:
  ///   type: 新しいステータスの種類。
  Future<void> updateMyStatus(UserStatusType type) async {
    await _firebaseService.updateStatus(type);
  }

  /// リソースを解放します。
  ///
  /// 現状はFirebaseServiceがインスタンス管理を行っているため、特別な処理は不要です。
  void dispose() {
    // サービス側でインスタンスを管理しているため、現時点では破棄処理なし
  }
}
