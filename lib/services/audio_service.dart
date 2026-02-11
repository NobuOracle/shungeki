import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// ゲーム全体のSE（効果音）管理サービス
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _sePlayer = AudioPlayer();
  double _seVolume = 0.8;
  bool _isEnabled = true;

  /// SE音量を設定（0.0 - 1.0）
  void setVolume(double volume) {
    _seVolume = volume.clamp(0.0, 1.0);
    _sePlayer.setVolume(_seVolume);
  }

  /// SE有効/無効を切り替え
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// SE再生（ファイル名のみ指定）
  Future<void> playSE(String fileName) async {
    if (!_isEnabled || _seVolume == 0.0) return;

    try {
      await _sePlayer.stop();
      await _sePlayer.setVolume(_seVolume);
      await _sePlayer.play(AssetSource('sounds/$fileName'));
      
      if (kDebugMode) {
        debugPrint('🔊 SE再生: $fileName (音量: ${(_seVolume * 100).toInt()}%)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SE再生エラー ($fileName): $e');
      }
    }
  }

  /// UISelectSE.mp3を再生（全UI操作共通）
  Future<void> playUISelect() => playSE('UISelectSE.mp3');

  /// Western Ready SE
  Future<void> playWesternReady() => playSE('WesternReadySE.mp3');

  /// Western Shot SE
  Future<void> playWesternShot() => playSE('WesternShotSE.mp3');

  /// Boxing Ready SE
  Future<void> playBoxingReady() => playSE('BoxingReadySE.mp3');

  /// Boxing Shot SE（パンチ音）
  Future<void> playBoxingShot() => playSE('BoxingshotSE.mp3');

  /// Wizard Ready SE
  Future<void> playWizardReady() => playSE('WizardReadySE.mp3');

  /// Wizard Shot SE
  Future<void> playWizardShot() => playSE('WizardShotSE.mp3');

  /// Samurai Ready SE
  Future<void> playSamuraiReady() => playSE('SamuraiReadySE.mp3');

  /// Samurai Shot SE（抜刀音）
  Future<void> playSamuraiShot() => playSE('SamuraiShotSE.mp3');

  /// SE終了待機（指定ミリ秒待機してからリザルト画面遷移用）
  Future<void> waitForSEComplete([int delayMs = 500]) async {
    await Future.delayed(Duration(milliseconds: delayMs));
  }

  /// リソース解放
  void dispose() {
    _sePlayer.dispose();
  }
}
