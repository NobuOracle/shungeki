import 'package:flutter/material.dart';

/// 2層背景構造のWidget
/// - 奥背景（Back）: 固定された背景画像、画面全体をカバー
/// - 手前背景（Front/Enemy）: 状態によって切り替わる敵キャラクター画像、中央配置
/// - オーバーレイ: グラデーションや木目テクスチャなどのオプション
/// - 子Widget: SafeAreaなど既存のUI要素をそのまま渡す
///
/// 重要: このWidgetは背景の組み立てのみを担当し、ゲームロジック/UI配置/演出には影響を与えない
class LayeredModeBackground extends StatelessWidget {
  /// 奥背景の画像パス（必須）
  final String backAsset;

  /// 手前背景（Enemy）の画像パス（必須）
  final String frontAsset;

  /// オプションのオーバーレイWidget（グラデーションや木目テクスチャなど）
  final Widget? overlay;

  /// 既存のUI要素（SafeAreaなど）
  final Widget child;

  const LayeredModeBackground({
    Key? key,
    required this.backAsset,
    required this.frontAsset,
    this.overlay,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 奥背景レイヤー: 画面全体をカバー
        Positioned.fill(child: Image.asset(backAsset, fit: BoxFit.cover)),
        // 手前背景レイヤー: 敵キャラクター、中央配置、タップを遮らない
        Center(
          child: IgnorePointer(
            ignoring: true,
            child: Image.asset(frontAsset, fit: BoxFit.contain),
          ),
        ),
        // オーバーレイレイヤー（オプション）
        if (overlay != null) overlay!,
        // 既存のUIレイヤー
        child,
      ],
    );
  }
}
