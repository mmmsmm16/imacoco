import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_status.dart';

/// 画面内を浮遊するステータスバブルを表示するウィジェット。
///
/// 複数のステータスアイコンがふわふわとランダムに移動し、
/// タップすることでステータスを更新できるUIを提供します。
class FloatingStatusBubbles extends StatefulWidget {
  final UserStatusType currentStatus;
  final Function(UserStatusType) onStatusSelected;

  const FloatingStatusBubbles({
    super.key,
    required this.currentStatus,
    required this.onStatusSelected,
  });

  @override
  State<FloatingStatusBubbles> createState() => _FloatingStatusBubblesState();
}

class _FloatingStatusBubblesState extends State<FloatingStatusBubbles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_BubbleModel> _bubbles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // アニメーションの基本周期（実際はループ）
    )..repeat();

    // 初期化時にバブルを生成
    // レイアウト確定後に初期位置を決めるため、addPostFrameCallback等は使わず
    // ここではモデルのみ作成し、build内で制約に合わせて位置計算を行う方式を取る
    // ただし、位置の継続性を保つため、初期位置はランダム（0.0-1.0の相対座標）で持つ。
    _initializeBubbles();
  }

  void _initializeBubbles() {
    final statuses = UserStatus.selectableStatuses;

    for (var type in statuses) {
      _bubbles.add(_BubbleModel(
        type: type,
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        dx: (_random.nextDouble() - 0.5) * 0.002, // 速度X
        dy: (_random.nextDouble() - 0.5) * 0.002, // 速度Y
        size: 70.0 + _random.nextDouble() * 20.0, // ランダムなサイズ
        phase: _random.nextDouble() * 2 * math.pi, // ふわふわ揺れる位相
      ));
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
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            _updatePositions(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              children: _bubbles.map((bubble) {
                final isCurrent = bubble.type == widget.currentStatus;

                return Positioned(
                  left: bubble.x * (constraints.maxWidth - bubble.size),
                  top: bubble.y * (constraints.maxHeight - bubble.size),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onStatusSelected(bubble.type);
                    },
                    child: _BubbleWidget(
                      type: bubble.type,
                      size: bubble.size,
                      isCurrent: isCurrent,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  void _updatePositions(double width, double height) {
    for (var bubble in _bubbles) {
      // 基本的な等速直線運動
      bubble.x += bubble.dx;
      bubble.y += bubble.dy;

      // ふわふわした動き（サイン波を加算）
      bubble.x += math.sin(_controller.value * 2 * math.pi + bubble.phase) * 0.0005;
      bubble.y += math.cos(_controller.value * 2 * math.pi + bubble.phase) * 0.0005;

      // 壁での跳ね返り
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
  final UserStatusType type;
  double x; // 相対座標 (0.0 - 1.0)
  double y; // 相対座標 (0.0 - 1.0)
  double dx; // 速度X
  double dy; // 速度Y
  final double size;
  final double phase;

  _BubbleModel({
    required this.type,
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.size,
    required this.phase,
  });
}

/// バブルの表示ウィジェット
class _BubbleWidget extends StatelessWidget {
  final UserStatusType type;
  final double size;
  final bool isCurrent;

  const _BubbleWidget({
    required this.type,
    required this.size,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    // 現在のステータスは少し大きく、発光させる
    final displaySize = isCurrent ? size * 1.2 : size;
    final color = type.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: displaySize,
      height: displaySize,
      decoration: BoxDecoration(
        color: isCurrent
            ? color.withOpacity(0.8)
            : Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent ? Colors.white : Colors.white.withOpacity(0.5),
          width: isCurrent ? 3 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isCurrent ? 0.6 : 0.2),
            blurRadius: isCurrent ? 20 : 10,
            spreadRadius: isCurrent ? 5 : 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          type.emoji,
          style: TextStyle(
            fontSize: displaySize * 0.5,
          ),
        ),
      ),
    );
  }
}
