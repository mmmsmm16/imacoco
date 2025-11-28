import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_status.dart';
import '../providers/status_provider.dart';

/// アプリのメイン画面（ホーム画面）。
///
/// 自分のステータス更新セクションと、友達のステータスリストセクションを表示します。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Imacoco'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent, // AppBarを透明にしてコンテンツと一体化
      ),
      extendBodyBehindAppBar: true, // コンテンツをAppBarの裏まで拡張
      body: Container(
        // 全体的な背景グラデーション
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _MyStatusSection(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.people_outline, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'みんなの様子',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Expanded(child: _FriendListSection()),
            ],
          ),
        ),
      ),
    );
  }
}

/// 自分のステータスを表示・更新するセクション。
class _MyStatusSection extends StatelessWidget {
  const _MyStatusSection();

  @override
  Widget build(BuildContext context) {
    final statusProvider = context.watch<StatusProvider>();
    final currentUser = statusProvider.currentUser;

    if (currentUser == null) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            '今の気分は？',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 16),
          // 現在のステータス表示（大きく強調）
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
            decoration: BoxDecoration(
              color: currentUser.status.type.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: currentUser.status.type.color.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: currentUser.status.type.color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  currentUser.status.type.emoji,
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 8),
                Text(
                  currentUser.status.type.label,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // ステータス選択ボタンのリスト
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _StatusButton(type: UserStatusType.awake),
              _StatusButton(type: UserStatusType.eating),
              _StatusButton(type: UserStatusType.free),
              _StatusButton(type: UserStatusType.busy),
              _StatusButton(type: UserStatusType.gaming),
            ],
          ),
        ],
      ),
    );
  }
}

/// ステータス更新用のボタンウィジェット。
class _StatusButton extends StatelessWidget {
  final UserStatusType type;

  const _StatusButton({required this.type});

  @override
  Widget build(BuildContext context) {
    final statusProvider = context.read<StatusProvider>();
    final isSelected = statusProvider.currentUser?.status.type == type;
    final color = type.color;

    return InkWell(
      onTap: () => statusProvider.updateStatus(type),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.8) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 2),
            Text(
              type.label,
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? Colors.black87 : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 友達（他ユーザー）のステータスリストを表示するセクション。
class _FriendListSection extends StatelessWidget {
  const _FriendListSection();

  @override
  Widget build(BuildContext context) {
    final friends = context.watch<StatusProvider>().friends;

    // ソート処理（アクティブな順、不明は最後）
    // NOTE: 表示用の一時的なリストを作成し、元のリストには影響を与えない
    final sortedFriends = List.of(friends);
    sortedFriends.sort((a, b) {
      // 1. 不明/期限切れかどうかで比較
      final aIsUnknown = a.status.isExpired || a.status.type == UserStatusType.unknown;
      final bIsUnknown = b.status.isExpired || b.status.type == UserStatusType.unknown;

      if (aIsUnknown && !bIsUnknown) return 1; // aが不明なら後ろへ
      if (!aIsUnknown && bIsUnknown) return -1; // bが不明なら後ろへ

      // 2. 更新日時で比較（新しい順）
      return b.status.updatedAt.compareTo(a.status.updatedAt);
    });

    if (sortedFriends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nights_stay_outlined, size: 48, color: Colors.white24),
            SizedBox(height: 16),
            Text('まだ誰もいません', style: TextStyle(color: Colors.white38)),
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
            gradient: LinearGradient(
              colors: [
                isUnknown ? Colors.white.withOpacity(0.05) : statusColor.withOpacity(0.2),
                isUnknown ? Colors.white.withOpacity(0.02) : statusColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isUnknown ? Colors.white10 : statusColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isUnknown ? Colors.white10 : statusColor.withOpacity(0.8),
              foregroundColor: Colors.white,
              child: Text(friend.name.isNotEmpty ? friend.name[0] : '?'),
            ),
            title: Text(
              friend.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isUnknown ? Colors.white54 : Colors.white,
              ),
            ),
            subtitle: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: isUnknown ? Colors.white24 : statusColor.withOpacity(0.7)
                ),
                const SizedBox(width: 4),
                Text(
                  isExpired ? '不明' : _formatTime(friend.status.updatedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnknown ? Colors.white24 : Colors.white70,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isUnknown ? Colors.transparent : Colors.black26,
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
