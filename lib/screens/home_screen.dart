import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback用
import 'package:provider/provider.dart';
import 'dart:math' as math; // アニメーション計算用
import '../models/user_status.dart';
import '../providers/status_provider.dart';
import '../widgets/floating_bubbles.dart';

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
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                        onStatusSelected: (type) {
                          statusProvider.updateStatus(type);
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // 友達リストのヘッダー
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.people_outline, color: subTextColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'みんなの様子',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: subTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 友達リスト（下半分）
              Expanded(
                flex: 5, // 画面の5割くらいをリストに
                child: _FriendListSection(
                  textColor: textColor,
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

/// 友達（他ユーザー）のステータスリストを表示するセクション。
class _FriendListSection extends StatelessWidget {
  final Color textColor;
  final Color subTextColor;

  const _FriendListSection({required this.textColor, required this.subTextColor});

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
            Text('まだ誰もいません', style: TextStyle(color: subTextColor.withOpacity(0.5))),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sortedFriends.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final friend = sortedFriends[index];
        final isExpired = friend.status.isExpired;

        final displayStatusType = (isExpired || friend.status.type == UserStatusType.unknown)
            ? UserStatusType.unknown
            : friend.status.type;
        
        final isUnknown = displayStatusType == UserStatusType.unknown;
        final statusColor = displayStatusType.color;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.1), // 半透明ベース
            border: Border.all(
              color: isUnknown ? Colors.grey.withOpacity(0.2) : statusColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isUnknown ? Colors.grey.withOpacity(0.5) : statusColor,
              foregroundColor: Colors.white,
              child: Text(friend.name.isNotEmpty ? friend.name[0] : '?'),
            ),
            title: Text(
              friend.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            subtitle: Text(
              isExpired ? '1時間以上前' : _formatTime(friend.status.updatedAt),
              style: TextStyle(
                fontSize: 12,
                color: subTextColor,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black12,
                shape: BoxShape.circle,
              ),
              child: Text(
                displayStatusType.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 更新日時を見やすい形式にフォーマットするヘルパーメソッド。
  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${dt.month}/${dt.day}';
  }
}
