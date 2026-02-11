import 'dart:math';
import 'package:flutter/foundation.dart';

/// イベントプラン生成ユーティリティ
/// seedから決定的にゲーム展開を生成し、2人対戦で完全同期を実現
class EventPlanGenerator {
  /// Westernモードのイベントプラン生成
  /// 
  /// drawAtMs: 1.0秒〜15.0秒（0.1秒刻み）
  static Map<String, dynamic> generateWestern(int seed) {
    final rng = Random(seed);
    
    // 1.0秒〜15.0秒（0.1秒刻み）
    // 1000ms〜15000ms の範囲で100ms刻み
    final steps = (15000 - 1000) ~/ 100 + 1; // 141ステップ
    final randomStep = rng.nextInt(steps);
    final drawAtMs = 1000 + (randomStep * 100);
    
    if (kDebugMode) {
      debugPrint('🎯 [EventPlanGenerator.generateWestern] seed=$seed, drawAtMs=$drawAtMs (${drawAtMs / 1000}秒)');
    }
    
    return {
      'ver': 1,
      'mode': 'WESTERN',
      'drawAtMs': drawAtMs,
    };
  }
  
  /// Boxingモードのイベントプラン生成
  /// 
  /// 3ラウンド分、各ラウンドで：
  /// - buttonIndex: 0〜9（10択）
  /// - delayMs: 1.0秒〜5.0秒（0.1秒刻み）
  static Map<String, dynamic> generateBoxing(int seed) {
    final rng = Random(seed);
    final rounds = <Map<String, dynamic>>[];
    
    for (int i = 0; i < 3; i++) {
      // ボタンインデックス: 0〜9
      final buttonIndex = rng.nextInt(10);
      
      // 遅延: 1.0秒〜5.0秒（0.1秒刻み）
      // 1000ms〜5000ms の範囲で100ms刻み
      final steps = (5000 - 1000) ~/ 100 + 1; // 41ステップ
      final randomStep = rng.nextInt(steps);
      final delayMs = 1000 + (randomStep * 100);
      
      rounds.add({
        'buttonIndex': buttonIndex,
        'delayMs': delayMs,
      });
    }
    
    return {
      'ver': 1,
      'mode': 'BOXING',
      'rounds': rounds,
    };
  }
  
  /// Wizardモードのイベントプラン生成
  /// 
  /// - drawAtMs: 1.0秒〜10.0秒（0.1秒刻み）
  /// - layout: 数字1〜5の配置（5点の頂点に配置する順番の配列）
  /// - radiusScale: 五角形/星形のサイズ倍率（1.0〜2.0、0.05刻み）
  static Map<String, dynamic> generateWizard(int seed) {
    final rng = Random(seed);
    
    // drawAtMs: 1.0秒〜10.0秒（0.1秒刻み）
    final steps = (10000 - 1000) ~/ 100 + 1; // 91ステップ
    final randomStep = rng.nextInt(steps);
    final drawAtMs = 1000 + (randomStep * 100);
    
    // layout: 数字1〜5をシャッフル
    final layout = [1, 2, 3, 4, 5];
    // Fisher-Yates シャッフル（決定的）
    for (int i = layout.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = layout[i];
      layout[i] = layout[j];
      layout[j] = temp;
    }
    
    // radiusScale: 1.0〜2.0（0.05刻み）
    final scaleSteps = ((2.0 - 1.0) / 0.05).round() + 1; // 21ステップ
    final randomScaleStep = rng.nextInt(scaleSteps);
    final radiusScale = 1.0 + (randomScaleStep * 0.05);
    
    if (kDebugMode) {
      debugPrint('🎯 [EventPlanGenerator.generateWizard] seed=$seed');
      debugPrint('  drawAtMs: $drawAtMs (${drawAtMs / 1000}秒)');
      debugPrint('  layout: $layout');
      debugPrint('  radiusScale: $radiusScale');
    }
    
    return {
      'ver': 1,
      'mode': 'WIZARD',
      'drawAtMs': drawAtMs,
      'layout': layout,
      'radiusScale': radiusScale,
    };
  }
  
  /// Samuraiモードのイベントプラン生成
  /// 
  /// - drawAtMs: 3.0秒〜30.0秒（0.1秒刻み）
  /// - fakeoutCount: 0〜5
  /// - fakeouts: フェイント情報の配列
  static Map<String, dynamic> generateSamurai(int seed) {
    final rng = Random(seed);
    
    // フェイント文言プール
    const fakeoutTexts = [
      'まだだ！',
      '焦るな！',
      '今じゃない！',
      'あと少し！',
      '隙がない！',
      '我慢だ！',
      '肉じゃが！',
      'まだ待て！',
      '嫌な間合いだ！',
    ];
    
    // drawAtMs: 3.0秒〜30.0秒（0.1秒刻み）
    final steps = (30000 - 3000) ~/ 100 + 1; // 271ステップ
    final randomStep = rng.nextInt(steps);
    final drawAtMs = 3000 + (randomStep * 100);
    
    // fakeoutCount: 0〜5
    final fakeoutCount = rng.nextInt(6);
    
    final fakeouts = <Map<String, dynamic>>[];
    
    if (fakeoutCount > 0) {
      // フェイント時刻のリストを生成（重複を避ける）
      final usedTimes = <int>{};
      const minGapMs = 400; // 最低間隔400ms
      
      for (int i = 0; i < fakeoutCount; i++) {
        // 0〜drawAtMs未満（0.1秒刻み）
        // ただし、drawAtMsより400ms以上前に配置
        final maxTime = drawAtMs - minGapMs;
        if (maxTime <= 0) break; // 時間が足りない場合は終了
        
        final timeSteps = maxTime ~/ 100;
        if (timeSteps <= 0) break;
        
        int atMs;
        int attempts = 0;
        do {
          final randomTimeStep = rng.nextInt(timeSteps);
          atMs = randomTimeStep * 100;
          attempts++;
          
          // 他のフェイントと最低間隔を確保
          bool tooClose = false;
          for (final used in usedTimes) {
            if ((atMs - used).abs() < minGapMs) {
              tooClose = true;
              break;
            }
          }
          
          if (!tooClose) break;
          
          // 無限ループ防止
          if (attempts > 100) {
            atMs = -1; // スキップ
            break;
          }
        } while (true);
        
        if (atMs < 0) continue; // スキップ
        
        usedTimes.add(atMs);
        
        // ランダムにフェイント文言を選択
        final text = fakeoutTexts[rng.nextInt(fakeoutTexts.length)];
        
        fakeouts.add({
          'atMs': atMs,
          'text': text,
        });
      }
      
      // 時刻順にソート
      fakeouts.sort((a, b) => (a['atMs'] as int).compareTo(b['atMs'] as int));
    }
    
    if (kDebugMode) {
      debugPrint('🎯 [EventPlanGenerator.generateSamurai] seed=$seed');
      debugPrint('  drawAtMs: $drawAtMs (${drawAtMs / 1000}秒)');
      debugPrint('  fakeoutCount: ${fakeouts.length}');
      for (int i = 0; i < fakeouts.length; i++) {
        debugPrint('    fakeout[$i]: atMs=${fakeouts[i]['atMs']}, text="${fakeouts[i]['text']}"');
      }
    }
    
    return {
      'ver': 1,
      'mode': 'SAMURAI',
      'drawAtMs': drawAtMs,
      'fakeouts': fakeouts,
    };
  }
  
  /// モード別にイベントプランを生成
  static Map<String, dynamic> generate(String mode, int seed) {
    switch (mode.toUpperCase()) {
      case 'WESTERN':
        return generateWestern(seed);
      case 'BOXING':
        return generateBoxing(seed);
      case 'WIZARD':
        return generateWizard(seed);
      case 'SAMURAI':
        return generateSamurai(seed);
      default:
        throw ArgumentError('Unknown mode: $mode');
    }
  }
}
