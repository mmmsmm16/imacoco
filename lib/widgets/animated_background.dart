import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 背景にゆっくり動くパーティクル（光の玉）を表示するウィジェット。
///
/// 画面全体にリッチな空気感を与えます。
class AnimatedBackground extends StatefulWidget {
  final List<Color> colors;

  const AnimatedBackground({
    super.key,
    required this.colors,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_BackgroundParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30), // 非常にゆっくり
    )..repeat();

    _initializeParticles();
  }

  void _initializeParticles() {
    for (int i = 0; i < 15; i++) {
      _particles.add(_BackgroundParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 100 + _random.nextDouble() * 200, // 大きなぼんやりした玉
        speedX: (_random.nextDouble() - 0.5) * 0.0005,
        speedY: (_random.nextDouble() - 0.5) * 0.0005,
        opacity: 0.1 + _random.nextDouble() * 0.2,
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
    // グラデーションのベース色
    final baseColor = widget.colors.isNotEmpty ? widget.colors.first : Colors.grey;
    final accentColor = widget.colors.length > 1 ? widget.colors[1] : Colors.white;

    return Stack(
      children: [
        // ベースのグラデーション（HomeScreen側でもあるが、ここでも重ねて深みを出す）
        Container(color: Colors.transparent),

        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            _updateParticles();
            return CustomPaint(
              painter: _ParticlePainter(
                particles: _particles,
                baseColor: baseColor,
                accentColor: accentColor,
              ),
              size: Size.infinite,
            );
          },
        ),

        // 全体に薄いノイズテクスチャを載せるとさらにエモくなるが、
        // 画像アセットが必要になるため今回はスキップし、
        // 代わりに非常に薄いホワイトオーバーレイで調整。
        Container(
          color: Colors.white.withOpacity(0.05),
        ),
      ],
    );
  }

  void _updateParticles() {
    for (var p in _particles) {
      p.x += p.speedX;
      p.y += p.speedY;

      // 画面外に出たら反対側から戻す（ループ）
      if (p.x < -0.2) p.x = 1.2;
      if (p.x > 1.2) p.x = -0.2;
      if (p.y < -0.2) p.y = 1.2;
      if (p.y > 1.2) p.y = -0.2;
    }
  }
}

class _BackgroundParticle {
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  double opacity;

  _BackgroundParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_BackgroundParticle> particles;
  final Color baseColor;
  final Color accentColor;

  _ParticlePainter({
    required this.particles,
    required this.baseColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = accentColor.withOpacity(p.opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60); // 強いぼかし

      final offset = Offset(p.x * size.width, p.y * size.height);
      canvas.drawCircle(offset, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
