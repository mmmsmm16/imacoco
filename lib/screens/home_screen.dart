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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _MyStatusSection(),
          const Divider(height: 32, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'みんなの様子',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          const Expanded(child: _FriendListSection()),
        ],
      ),
    );
  }
}

/// 自分のステータスを表示・更新するセクション。
class _MyStatusSection extends StatelessWidget {
  const _MyStatusSection();

  @override
  Widget build(BuildContext context) {
    // ステータスの変更を監視
    final statusProvider = context.watch<StatusProvider>();
    final currentUser = statusProvider.currentUser;

    // データ読み込み中はローディングを表示
    if (currentUser == null) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            '今の気分は？',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${currentUser.status.type.emoji} ${currentUser.status.type.label}',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 24),
          // ステータス選択ボタンのリスト
          Wrap(
            spacing: 16,
            runSpacing: 16,
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

    return InkWell(
      onTap: () => statusProvider.updateStatus(type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              type.label,
              style: const TextStyle(fontSize: 10, color: Colors.white),
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

    if (friends.isEmpty) {
      return const Center(child: Text('まだ誰もいません'));
    }

    return ListView.builder(
      itemCount: friends.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final friend = friends[index];
        // ステータスの有効期限チェック（モデルのロジックを使用）
        final isExpired = friend.status.isExpired;

        // 期限切れ、または明示的に「不明」の場合は「不明」として表示
        final displayStatusType = (isExpired || friend.status.type == UserStatusType.unknown)
            ? UserStatusType.unknown
            : friend.status.type;
        
        final isUnknown = displayStatusType == UserStatusType.unknown;

        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isUnknown ? Colors.grey : Theme.of(context).colorScheme.secondary,
              child: Text(friend.name.isNotEmpty ? friend.name[0] : '?'),
            ),
            title: Text(friend.name),
            subtitle: Text(
              isExpired ? '1時間以上前' : _formatTime(friend.status.updatedAt),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              displayStatusType.emoji,
              style: const TextStyle(fontSize: 32),
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
