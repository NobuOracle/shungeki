import 'package:flutter/material.dart';

/// 2層背景構造のWidget
/// - 奥背景（Back）: 固定された背景画像、画面全体をカバー
/// - 手前背景（Front/Enemy）: 状態によって切り替わる敵キャラクター画像
///   - サイズ: デフォルト 0.5倍（元の半分）
///   - 位置: 画像の下端を基準に、画面下端から上へ約300pxの位置
/// - オーバーレイ: グラデーションや木目テクスチャなどのオプション
/// - 子Widget: SafeAreaなど既存のUI要素をそのまま渡す
///
/// 重要: このWidgetは背景の組み立てのみを担当し、ゲームロジック/UI配置/演出には影響を与えない
class LayeredModeBackground extends StatelessWidget {
  /// 奥背景の画像パス（必須）
  final String backAsset;

  /// 手前背景（Enemy）の画像パス（必須）
  final String frontAsset;

  /// 手前背景のスケール（デフォルト: 0.5 = 元の半分のサイズ）
  final double frontScale;

  /// 手前背景の下端オフセット（デフォルト: 300.0 = 画面下端から上へ300px）
  final double frontBottomOffset;

  /// オプションのオーバーレイWidget（グラデーションや木目テクスチャなど）
  final Widget? overlay;

  /// 既存のUI要素（SafeAreaなど）
  final Widget child;

  const LayeredModeBackground({
    super.key,
    required this.backAsset,
    required this.frontAsset,
    this.frontScale = 0.5,
    this.frontBottomOffset = 300.0,
    this.overlay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 奥背景レイヤー: 画面全体をカバー（上下見切れなし）
        Positioned.fill(
          child: Image.asset(
            backAsset,
            fit: BoxFit.fill, // 画面全体に伸縮して上下見切れを防ぐ
          ),
        ),
        // 手前背景レイヤー: 敵キャラクター
        // - bottom anchor（画像の下端を基準）
        // - 画面下端から上へ frontBottomOffset px の位置
        // - frontScale 倍にスケール
        // - タップを遮らない
        Positioned(
          left: 0,
          right: 0,
          bottom: frontBottomOffset,
          child: IgnorePointer(
            ignoring: true,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Transform.scale(
                scale: frontScale,
                alignment: Alignment.bottomCenter,
                child: Image.asset(frontAsset, fit: BoxFit.contain),
              ),
            ),
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
