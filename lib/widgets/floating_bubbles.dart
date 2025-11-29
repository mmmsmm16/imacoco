import 'dart:math' as math;
import 'dart:ui';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
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
  final Function(Color)? onBubbleDragColorChange; // 背景色変更用コールバック
  final VoidCallback? onBubbleDragEnd; // ドラッグ終了用コールバック

  const FloatingStatusBubbles({
    super.key,
    required this.currentStatus,
    this.currentCustomEmoji,
    required this.onStatusSelected,
    this.onBubbleDragColorChange,
    this.onBubbleDragEnd,
  });

  @override
  State<FloatingStatusBubbles> createState() => _FloatingStatusBubblesState();
}

class _FloatingStatusBubblesState extends State<FloatingStatusBubbles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_BubbleModel> _bubbles = [];
  final math.Random _random = math.Random();

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
    // 全体的にサイズを小さくする (50-70程度)
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
      size: 50.0 + _random.nextDouble() * 20.0,
      phaseX: _random.nextDouble() * 2 * math.pi,
      phaseY: _random.nextDouble() * 2 * math.pi,
      wobbleSpeed: 0.5 + _random.nextDouble(),
    ));
  }

  /// EmojiPickerを表示するモーダル
  Future<void> _showAddBubbleDialog() async {
    // キーボードが表示されるのを防ぐため、フォーカスを外す
    FocusScope.of(context).unfocus();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // ハンドルバー
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    Navigator.pop(context, emoji.emoji);
                  },
                  config: const Config(
                    // バージョン互換性のため最小限の設定にする
                    bgColor: Color(0xFFF2F2F2),
                    indicatorColor: Colors.blue,
                    iconColor: Colors.grey,
                    iconColorSelected: Colors.blue,
                    backspaceColor: Colors.blue,
                    skinToneDialogBgColor: Colors.white,
                    skinToneIndicatorColor: Colors.grey,
                    enableSkinTones: true,
                    showRecentsTab: true,
                    recentsLimit: 28,
                    // columns, height等はデフォルト値を使用、または親Widgetの制約に従う
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((emoji) async {
      if (emoji != null && emoji is String) {
        final provider = context.read<StatusProvider>();
        await provider.addCustomBubble(emoji);
        _syncBubblesWithProvider();
        setState(() {});
      }
    });
  }

  Future<void> _showDeleteConfirmDialog(_BubbleModel bubble) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bubble?'),
        content: Text(
          bubble.displayEmoji,
          style: const TextStyle(fontSize: 32),
          textAlign: TextAlign.center,
        ),
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

                    final bubbleColor = bubble.isCustom ? Colors.pinkAccent : bubble.type.color;

                    return Positioned(
                      left: bubble.x * (constraints.maxWidth - bubble.size),
                      top: bubble.y * (constraints.maxHeight - bubble.size),
                      child: _BouncingBubble(
                        // 背景色変化のロジックをタップ時にも入れる
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onStatusSelected(
                            bubble.isCustom ? UserStatusType.free : bubble.type,
                            bubble.isCustom ? bubble.customEmoji : null,
                          );
                          // タップ時も色を変更
                          widget.onBubbleDragColorChange?.call(bubbleColor);
                          widget.onBubbleDragEnd?.call(); // リセットも呼んで一瞬の変化にする
                        },
                        onLongPress: () {
                          HapticFeedback.heavyImpact();
                          _showDeleteConfirmDialog(bubble);
                        },
                        // ドラッグ（スワイプ）操作の実装
                        onPanUpdate: (details) {
                          // 指の動きに合わせて速度を更新（弾く動き）
                          // 画面サイズに対する相対速度に変換
                          // 係数を調整して「飛び」具合を調整
                          final sensitivity = 0.0001;
                          bubble.dx = details.delta.dx * sensitivity;
                          bubble.dy = details.delta.dy * sensitivity;

                          // ドラッグ中は背景色を変更
                          widget.onBubbleDragColorChange?.call(bubbleColor);
                        },
                        onPanEnd: (_) {
                          widget.onBubbleDragEnd?.call();
                        },
                        child: _GlassBubbleWidget(
                          emoji: bubble.displayEmoji,
                          color: bubbleColor,
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

      // 摩擦（減衰）を追加して、弾いた後に徐々に元の速度感に戻るようにする
      // ただし完全停止はさせず、漂う動きは残す
      bubble.dx *= 0.98; // 減衰
      bubble.dy *= 0.98; // 減衰

      // 最小速度（漂う動き）を確保するための加算
      // ふわふわ（Wobble）
      // 減衰した速度に加えて、自然な揺れを足す
      bubble.x += math.sin(t * bubble.wobbleSpeed + bubble.phaseX) * 0.0008;
      bubble.y += math.cos(t * bubble.wobbleSpeed + bubble.phaseY) * 0.0008;

      // 境界チェック（跳ね返り）
      if (bubble.x <= 0 || bubble.x >= 1.0) {
        bubble.dx *= -1; // 壁に当たったら反転
        bubble.x = bubble.x.clamp(0.0, 1.0);
      }
      if (bubble.y <= 0 || bubble.y >= 1.0) {
        bubble.dy *= -1; // 壁に当たったら反転
        bubble.y = bubble.y.clamp(0.0, 1.0);
      }
    }
  }
}

/// タップ時にボヨンと弾むアニメーションラッパー
/// ジェスチャー（タップ、長押し、ドラッグ）もここで管理
class _BouncingBubble extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;

  const _BouncingBubble({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onPanUpdate,
    this.onPanEnd,
  });

  @override
  State<_BouncingBubble> createState() => _BouncingBubbleState();
}

class _BouncingBubbleState extends State<_BouncingBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // タップダウンでアニメーション開始
      onTapDown: (_) => _controller.forward(from: 0),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      // ドラッグ（フリック）操作
      onPanUpdate: widget.onPanUpdate,
      onPanEnd: widget.onPanEnd,
      onPanCancel: () {
        widget.onPanEnd?.call(DragEndDetails(velocity: Velocity.zero));
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
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
