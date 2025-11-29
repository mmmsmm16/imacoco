import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/user_status.dart';
import 'reaction_effect_overlay.dart';

/// 友達のステータスを表示するグリッドアイテム（カード）。
///
/// グラスモーフィズムデザイン（すりガラス風）を採用し、
/// アバター、名前、ステータス、経過時間を表示します。
/// タップするとリアクションエフェクトが発生します。
class FriendCard extends StatelessWidget {
  final User user;

  const FriendCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final status = user.status;
    final isExpired = status.isExpired;
    final displayType = (isExpired || status.type == UserStatusType.unknown)
        ? UserStatusType.unknown
        : status.type;

    final isUnknown = displayType == UserStatusType.unknown;

    return ReactionEffectOverlay(
      onTap: () {
        // ここに将来的にプロフィール詳細への遷移などを実装可能
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), // 半透明の白
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.2), // 薄いボーダー
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // コンテンツ部分
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // アバターエリア
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isUnknown
                                    ? Colors.white.withOpacity(0.3)
                                    : displayType.color.withOpacity(0.8),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: isUnknown
                                  ? Colors.grey.withOpacity(0.3)
                                  : displayType.color.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              child: Text(
                                user.name.isNotEmpty ? user.name[0] : '?',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // ステータスアイコンバッジ
                          if (!isUnknown)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                displayType.emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 名前
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black12,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // 時間・状態ラベル (英語表記でスタイリッシュに)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isExpired
                              ? 'Expired'
                              : isUnknown
                                  ? 'Unknown'
                                  : _formatTime(status.updatedAt),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 若者向けに短縮した英語表記の時間を返す
  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.month}/${dt.day}';
  }
}
