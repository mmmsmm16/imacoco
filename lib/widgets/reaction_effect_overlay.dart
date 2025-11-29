import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// タップ時にパーティクルエフェクトを表示するラッパーウィジェット。
///
/// 子ウィジェットをラップし、タップ操作を検知して絵文字やハートが飛び出すアニメーションを描画します。
/// 「いいね」の連打のような体験を提供します。
class ReactionEffectOverlay extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ReactionEffectOverlay({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<ReactionEffectOverlay> createState() => _ReactionEffectOverlayState();
}

class _ReactionEffectOverlayState extends State<ReactionEffectOverlay> with TickerProviderStateMixin {
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  // 若者向けのエモい・勢いのある絵文字セット
  static const List<String> _emojis = ['❤️', '🔥', '✨', '👍', '🥺', '🎉', '🫶', '尊い'];

  void _addParticle(Offset localPosition) {
    // 短い時間で消えるコントローラーを作成
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final particle = _Particle(
      id: DateTime.now().microsecondsSinceEpoch.toString() + _random.nextInt(1000).toString(),
      controller: controller,
      startPosition: localPosition,
      // ランダムな方向への拡散を追加（真上だけでなく少し左右に散らす）
      dx: (_random.nextDouble() - 0.5) * 40.0,
      angle: (_random.nextDouble() - 0.5) * 0.5,
      scale: 0.8 + _random.nextDouble() * 0.5,
      emoji: _emojis[_random.nextInt(_emojis.length)],
    );

    if (mounted) {
      setState(() {
        _particles.add(particle);
      });
    }

    controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _particles.removeWhere((p) => p.id == particle.id);
        });
      }
      controller.dispose();
    });
  }

  @override
  void dispose() {
    for (var p in _particles) {
      p.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 既存のタップイベントを邪魔しないよう、behaviorを調整する必要があるかもしれないが、
      // ここではカード全体のタップを検知したいのでopaqueでOK。
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        // 連打の気持ちよさのためのハプティクス
        HapticFeedback.selectionClick();
        _addParticle(details.localPosition);
        widget.onTap?.call();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          // パーティクルの描画
          ..._particles.map((p) => _buildParticle(p)),
        ],
      ),
    );
  }

  Widget _buildParticle(_Particle particle) {
    return AnimatedBuilder(
      animation: particle.controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(particle.controller.value);

        // 上に移動しながら、少し左右に流れる
        final dy = -150.0 * t;
        final dx = particle.dx * t;

        // フェードアウト
        final opacity = (1.0 - t).clamp(0.0, 1.0);

        // 少し拡大しながら消える
        final scale = particle.scale * (1.0 + t * 0.2);

        return Positioned(
          left: particle.startPosition.dx + dx - 12,
          top: particle.startPosition.dy + dy - 12,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: particle.angle,
              child: Transform.scale(
                scale: scale,
                child: Text(
                  particle.emoji,
                  style: const TextStyle(
                    fontSize: 28,
                    shadows: [
                      Shadow(
                        blurRadius: 4.0,
                        color: Colors.black26,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  final String id;
  final AnimationController controller;
  final Offset startPosition;
  final double dx; // X方向の移動量
  final double angle;
  final double scale;
  final String emoji;

  _Particle({
    required this.id,
    required this.controller,
    required this.startPosition,
    required this.dx,
    required this.angle,
    required this.scale,
    required this.emoji,
  });
}
