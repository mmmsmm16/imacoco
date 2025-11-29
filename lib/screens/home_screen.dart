import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback用
import 'package:provider/provider.dart';
import 'dart:math' as math; // アニメーション計算用
import '../models/user_status.dart';
import '../providers/status_provider.dart';

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
              // ステータス変更ヘッダー（インタラクティブメニュー）
              _InteractiveStatusHeader(textColor: textColor),

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

              // 友達リスト（expanded）
              Expanded(child: _FriendListSection(textColor: textColor, subTextColor: subTextColor)),
            ],
          ),
        ),
      ),
    );
  }
}

/// インタラクティブなステータス変更ヘッダー。
///
/// 通常時は現在のステータスのみを表示し、タップするとメニューが展開します。
class _InteractiveStatusHeader extends StatefulWidget {
  final Color textColor;

  const _InteractiveStatusHeader({required this.textColor});

  @override
  State<_InteractiveStatusHeader> createState() => _InteractiveStatusHeaderState();
}

class _InteractiveStatusHeaderState extends State<_InteractiveStatusHeader>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<void> _updateStatus(UserStatusType type) async {
    HapticFeedback.mediumImpact();
    final provider = context.read<StatusProvider>();

    // メニューを閉じる
    _toggleMenu();

    // ステータス更新
    await provider.updateStatus(type);
  }

  @override
  Widget build(BuildContext context) {
    // ステータスの変更を監視
    final statusProvider = context.watch<StatusProvider>();
    final currentUser = statusProvider.currentUser;

    // データ読み込み中はローディングを表示
    if (currentUser == null) {
      return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
    }

    final currentType = currentUser.status.type;

    return GestureDetector(
      onTap: _isExpanded ? _toggleMenu : null, // 展開中は背景タップで閉じる
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // メインのステータス表示（またはメニュー中心）
            SizedBox(
              height: 220, // メニュー展開用のスペース確保
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // 展開されるメニュー項目
                  ..._buildMenuItems(currentType),

                  // 中央の現在のステータス（トリガーボタン）
                  GestureDetector(
                    onTap: _toggleMenu,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isExpanded
                            ? Colors.white.withOpacity(0.9)
                            : currentType.color.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isExpanded
                              ? Colors.grey.withOpacity(0.5)
                              : currentType.color.withOpacity(0.8),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: currentType.color.withOpacity(0.4),
                            blurRadius: _isExpanded ? 30 : 20,
                            spreadRadius: _isExpanded ? 10 : 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _isExpanded ? '❌' : currentType.emoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ステータスラベル（メニュー展開時は非表示）
            AnimatedOpacity(
              opacity: _isExpanded ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  Text(
                    currentType.label,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.textColor,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'タップして変更',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(UserStatusType currentType) {
    // 選択肢
    final options = [
      UserStatusType.awake,
      UserStatusType.eating,
      UserStatusType.free,
      UserStatusType.busy,
      UserStatusType.gaming,
    ];

    const double radius = 90.0;
    // 5つのアイテムを円周上に配置 (-90度 = 上 からスタート)
    const double startAngle = -math.pi / 2;
    final double step = (2 * math.pi) / options.length;

    return List.generate(options.length, (index) {
      final type = options[index];
      final angle = startAngle + (step * index);

      return AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              radius * _expandAnimation.value * math.cos(angle),
              radius * _expandAnimation.value * math.sin(angle),
            ),
            child: Opacity(
              opacity: _expandAnimation.value,
              child: Transform.scale(
                scale: _expandAnimation.value,
                child: _MenuItemButton(
                  type: type,
                  isSelected: type == currentType,
                  onTap: () => _updateStatus(type),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

/// メニュー内の各ステータスボタン。
class _MenuItemButton extends StatelessWidget {
  final UserStatusType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuItemButton({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: type.color.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 2),
            Text(
              type.label,
              style: const TextStyle(fontSize: 8, color: Colors.black87, fontWeight: FontWeight.bold),
            ),
          ],
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
