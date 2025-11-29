import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback用
import 'package:provider/provider.dart';
import '../models/user_status.dart';
import '../providers/status_provider.dart';
import '../widgets/floating_bubbles.dart';
import '../widgets/friend_card.dart';

/// アプリのメイン画面（ホーム画面）。
///
/// 自分のステータス更新セクションと、友達のステータスリストセクションを表示します。
/// 画面全体の背景色は選択されたステータスに応じて変化します。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final statusProvider = context.watch<StatusProvider>();
    final currentUser = statusProvider.currentUser;

    // 背景グラデーションの取得（ユーザー未ロード時はデフォルト）
    final bgColors = currentUser?.status.type.backgroundColors ??
        UserStatusType.unknown.backgroundColors;

    // テキスト色の判定
    final isLight = currentUser?.status.type.isLightBackground ?? false;
    final textColor = isLight ? Colors.black87 : Colors.white;
    final subTextColor = isLight ? Colors.black54 : Colors.white70;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Imacoco',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ステータス変更エリア（浮遊バブルUI）
              Expanded(
                flex: 4, // 画面の4割くらいを浮遊エリアに
                child: currentUser == null
                    ? const Center(child: CircularProgressIndicator())
                    : FloatingStatusBubbles(
                        currentStatus: currentUser.status.type,
                        currentCustomEmoji: currentUser.status.customEmoji,
                        onStatusSelected: (type, customEmoji) {
                          statusProvider.updateStatus(type, customEmoji: customEmoji);
                        },
                      ),
              ),

              const SizedBox(height: 8),

              // 友達リストのヘッダー
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Icon(Icons.grid_view_rounded, color: subTextColor.withOpacity(0.8), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'FRIENDS',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: subTextColor.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 友達リスト（下半分） - グリッド表示に変更
              Expanded(
                flex: 5, // 画面の5割くらいをリストに
                child: _FriendGridSection(
                  subTextColor: subTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 友達（他ユーザー）のステータスをグリッド表示するセクション。
class _FriendGridSection extends StatelessWidget {
  final Color subTextColor;

  const _FriendGridSection({required this.subTextColor});

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<StatusProvider>().friends;

    // ソート処理
    final sortedFriends = List.of(friends);
    sortedFriends.sort((a, b) {
      final aIsUnknown = a.status.isExpired || a.status.type == UserStatusType.unknown;
      final bIsUnknown = b.status.isExpired || b.status.type == UserStatusType.unknown;

      if (aIsUnknown && !bIsUnknown) return 1;
      if (!aIsUnknown && bIsUnknown) return -1;
      return b.status.updatedAt.compareTo(a.status.updatedAt);
    });

    if (sortedFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nights_stay_outlined, size: 48, color: subTextColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No friends active...', style: TextStyle(color: subTextColor.withOpacity(0.5))),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2列
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85, // 縦長カード
      ),
      itemCount: sortedFriends.length,
      itemBuilder: (context, index) {
        final friend = sortedFriends[index];
        return FriendCard(user: friend);
      },
    );
  }
}
