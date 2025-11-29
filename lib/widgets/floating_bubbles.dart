import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/user_status.dart';
import '../providers/status_provider.dart';

/// 画面内を浮遊するステータスバブルを表示するウィジェット。
///
/// 複数のステータスアイコンがふわふわと有機的に移動し、
/// タップすることでステータスを更新できるUIを提供します。
/// カスタム絵文字の追加・削除機能もサポートします。
class FloatingStatusBubbles extends StatefulWidget {
  final UserStatusType currentStatus;
  final String? currentCustomEmoji;
  final Function(UserStatusType, String?) onStatusSelected;

  const FloatingStatusBubbles({
    super.key,
    required this.currentStatus,
    this.currentCustomEmoji,
    required this.onStatusSelected,
  });

  @override
  State<FloatingStatusBubbles> createState() => _FloatingStatusBubblesState();
}

class _FloatingStatusBubblesState extends State<FloatingStatusBubbles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_BubbleModel> _bubbles = [];
  final math.Random _random = math.Random();

  // バブルが画面外に行き過ぎないためのパディング率
  static const double _padding = 0.1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // よりゆっくりとした周期
    )..repeat();

    // 初期化は postFrameCallback で行い、Providerからデータを取得
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBubbles();
    });
  }

  @override
  void didUpdateWidget(FloatingStatusBubbles oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 依存データが変わった可能性があるため再同期
    _syncBubblesWithProvider();
  }

  /// Providerのデータに基づいてバブルリストを同期する
  void _syncBubblesWithProvider() {
    final provider = context.read<StatusProvider>();
    final defaultStatuses = UserStatus.selectableStatuses;
    final customEmojis = provider.customBubbles;
    final hiddenDefaultTypes = provider.hiddenDefaultTypes;

    final currentBubbleIds = _bubbles.map((b) => b.id).toSet();

    // 削除されたものを除去
    _bubbles.removeWhere((b) {
      if (b.isCustom) {
        return !customEmojis.contains(b.customEmoji);
      } else {
        // 非表示リストに入っているデフォルトバブルも除去
        return !defaultStatuses.contains(b.type) || hiddenDefaultTypes.contains(b.type);
      }
    });

    // 新しいものを追加（デフォルト）
    // 非表示リストに入っていないものだけを追加
    for (var type in defaultStatuses) {
      if (hiddenDefaultTypes.contains(type)) continue;

      final id = 'default_${type.index}';
      if (!currentBubbleIds.contains(id)) {
        _addBubble(type: type, id: id);
      }
    }

    // 新しいものを追加（カスタム）
    for (var emoji in customEmojis) {
      final id = 'custom_$emoji';
      if (!currentBubbleIds.contains(id)) {
        _addBubble(customEmoji: emoji, id: id, isCustom: true);
      }
    }
  }

  void _initializeBubbles() {
    _syncBubblesWithProvider();
    setState(() {});
  }

  void _addBubble({
    UserStatusType type = UserStatusType.unknown,
    String? customEmoji,
    required String id,
    bool isCustom = false
  }) {
    _bubbles.add(_BubbleModel(
      id: id,
      type: type,
      customEmoji: customEmoji,
      isCustom: isCustom,
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      // 有機的な動きのために速度と位相をランダム化
      dx: (_random.nextDouble() - 0.5) * 0.0015,
      dy: (_random.nextDouble() - 0.5) * 0.0015,
      size: 70.0 + _random.nextDouble() * 20.0,
      phaseX: _random.nextDouble() * 2 * math.pi,
      phaseY: _random.nextDouble() * 2 * math.pi,
      wobbleSpeed: 0.5 + _random.nextDouble(),
    ));
  }

  Future<void> _showAddBubbleDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Bubble', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter one emoji:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32),
              maxLength: 1, // 1文字制限（サロゲートペア対応が甘いが簡易実装）
              decoration: const InputDecoration(
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final provider = context.read<StatusProvider>();
      await provider.addCustomBubble(result);
      _syncBubblesWithProvider(); // UI更新
      setState(() {});
    }
  }

  Future<void> _showDeleteConfirmDialog(_BubbleModel bubble) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bubble?'),
        content: Text(bubble.displayEmoji),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = context.read<StatusProvider>();
      if (bubble.isCustom) {
        await provider.removeCustomBubble(bubble.customEmoji!);
      } else {
        await provider.hideDefaultBubble(bubble.type);
      }
      _syncBubblesWithProvider();
      setState(() {});
    }
  }

  Future<void> _showRestoreDialog() async {
     final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Bubbles?'),
        content: const Text('Restore all hidden default bubbles?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = context.read<StatusProvider>();
      await provider.restoreDefaultBubbles();
      _syncBubblesWithProvider();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // バブルレイヤー
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                _updatePositions(constraints.maxWidth, constraints.maxHeight);
                return Stack(
                  children: _bubbles.map((bubble) {
                    final isCurrent = bubble.isCustom
                        ? bubble.customEmoji == widget.currentCustomEmoji
                        : bubble.type == widget.currentStatus && widget.currentCustomEmoji == null;

                    return Positioned(
                      left: bubble.x * (constraints.maxWidth - bubble.size),
                      top: bubble.y * (constraints.maxHeight - bubble.size),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onStatusSelected(
                            bubble.isCustom ? UserStatusType.free : bubble.type,
                            bubble.isCustom ? bubble.customEmoji : null,
                          );
                        },
                        onLongPress: () {
                          HapticFeedback.heavyImpact();
                          _showDeleteConfirmDialog(bubble);
                        },
                        child: _GlassBubbleWidget(
                          emoji: bubble.displayEmoji,
                          color: bubble.isCustom ? Colors.pinkAccent : bubble.type.color,
                          size: bubble.size,
                          isCurrent: isCurrent,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // 追加ボタン（右下に配置）
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 復元ボタン（小さく表示、デフォルトバブルが隠されているときのみ表示すると良いが今回は常設またはロジック省略）
                  // UIが煩雑になるため、今回は長押しで「復元」機能を隠しコマンド的に実装するか、
                  // あるいは追加ダイアログの中に「Reset Defaults」を入れるのもあり。
                  // ここではシンプルにFABの上に小さなボタンを置く。
                  FloatingActionButton.small(
                    heroTag: 'restore_btn',
                    backgroundColor: Colors.white.withOpacity(0.3),
                    elevation: 0,
                    onPressed: _showRestoreDialog,
                    child: const Icon(Icons.refresh, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'add_btn',
                    mini: true,
                    backgroundColor: Colors.white.withOpacity(0.5),
                    elevation: 0,
                    onPressed: _showAddBubbleDialog,
                    child: const Icon(Icons.add, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _updatePositions(double width, double height) {
    for (var bubble in _bubbles) {
      // 有機的な動き（パーリンノイズ的アプローチの簡易版）
      // 時間経過とともに位相をずらす
      final t = _controller.value * 2 * math.pi;

      // 基本移動
      bubble.x += bubble.dx;
      bubble.y += bubble.dy;

      // ふわふわ（Wobble）
      // X軸: サイン波、Y軸: コサイン波で楕円軌道っぽさを混ぜる
      // 周期を個別に持たせることでバラバラな動きに
      bubble.x += math.sin(t * bubble.wobbleSpeed + bubble.phaseX) * 0.0008;
      bubble.y += math.cos(t * bubble.wobbleSpeed + bubble.phaseY) * 0.0008;

      // 境界チェック（跳ね返り）
      if (bubble.x <= 0 || bubble.x >= 1.0) {
        bubble.dx *= -1;
        bubble.x = bubble.x.clamp(0.0, 1.0);
      }
      if (bubble.y <= 0 || bubble.y >= 1.0) {
        bubble.dy *= -1;
        bubble.y = bubble.y.clamp(0.0, 1.0);
      }
    }
  }
}

/// 個々のバブルの状態を管理するモデルクラス
class _BubbleModel {
  final String id;
  final UserStatusType type;
  final String? customEmoji;
  final bool isCustom;

  double x;
  double y;
  double dx;
  double dy;
  final double size;

  // アニメーション用パラメータ
  final double phaseX;
  final double phaseY;
  final double wobbleSpeed;

  _BubbleModel({
    required this.id,
    required this.type,
    this.customEmoji,
    required this.isCustom,
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.size,
    required this.phaseX,
    required this.phaseY,
    required this.wobbleSpeed,
  });

  String get displayEmoji => isCustom ? customEmoji! : type.emoji;
}

/// グラスモーフィズム＆発光エフェクト付きバブル
class _GlassBubbleWidget extends StatelessWidget {
  final String emoji;
  final Color color;
  final double size;
  final bool isCurrent;

  const _GlassBubbleWidget({
    required this.emoji,
    required this.color,
    required this.size,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final displaySize = isCurrent ? size * 1.3 : size;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      width: displaySize,
      height: displaySize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 発光エフェクト（選択時のみ）
          if (isCurrent)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),

          // グラスモーフィズム本体
          ClipRRect(
            borderRadius: BorderRadius.circular(displaySize / 2),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isCurrent
                      ? color.withOpacity(0.3)
                      : Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent
                        ? Colors.white.withOpacity(0.8)
                        : Colors.white.withOpacity(0.3),
                    width: isCurrent ? 2 : 1,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.4),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: TextStyle(
                      fontSize: displaySize * 0.5,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
