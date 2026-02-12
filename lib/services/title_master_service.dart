import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/title_definition.dart';
import '../models/player_profile.dart';

/// 称号マスターサービス
/// assets/upload_files/titles.json から称号定義を読み込む
class TitleMasterService {
  static final TitleMasterService _instance = TitleMasterService._internal();
  factory TitleMasterService() => _instance;
  TitleMasterService._internal();

  List<TitleDefinition>? _titles;

  /// 称号マスタを読み込む
  Future<void> loadTitles() async {
    if (_titles != null) return; // 既に読み込み済み

    try {
      final String jsonString = await rootBundle.loadString('assets/upload_files/titles.json');
      final List<dynamic> jsonList = json.decode(jsonString) as List;
      
      _titles = jsonList
          .map((json) => TitleDefinition.fromJson(json as Map<String, dynamic>))
          .toList();
      
      debugPrint('✅ [TitleMasterService] 称号マスタ読み込み完了: ${_titles!.length}件');
    } catch (e) {
      debugPrint('❌ [TitleMasterService] 称号マスタ読み込みエラー: $e');
      _titles = []; // エラー時は空リスト
    }
  }

  /// 全称号取得
  List<TitleDefinition> getAllTitles() {
    return _titles ?? [];
  }

  /// IDで称号取得
  TitleDefinition? getTitleById(String id) {
    if (_titles == null) return null;
    try {
      return _titles!.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// プロフィールから獲得可能な称号をチェック
  /// 
  /// [profile] プレイヤープロフィール
  /// [lastGameResult] 最後のゲーム結果（オプション）
  /// 
  /// 返り値: 新たに獲得した称号のリスト
  List<TitleDefinition> checkUnlockableTitles({
    required PlayerProfile profile,
    Map<String, dynamic>? lastGameResult,
  }) {
    final newlyUnlocked = <TitleDefinition>[];
    
    for (final title in getAllTitles()) {
      // 既に獲得済みならスキップ
      if (profile.unlockedTitleIds.contains(title.id)) continue;
      
      // unlock typeに応じて判定
      if (_checkUnlockCondition(title, profile, lastGameResult)) {
        newlyUnlocked.add(title);
      }
    }
    
    return newlyUnlocked;
  }

  /// unlock条件をチェック
  bool _checkUnlockCondition(
    TitleDefinition title,
    PlayerProfile profile,
    Map<String, dynamic>? lastGameResult,
  ) {
    final unlock = title.unlock;
    
    switch (unlock.type) {
      case 'playCount':
        // モード別プレイ回数
        final mode = unlock.mode;
        if (mode == null) return false; // モード指定必須
        final requiredCount = unlock.count ?? 0;
        final currentCount = profile.playCountByMode[mode] ?? 0;
        return currentCount >= requiredCount;
        
      case 'bestMsAtMost':
        // ベスト記録が指定時間以下（モード別）
        final mode = unlock.mode;
        if (mode == null) return false; // モード指定必須
        final requiredTimeMs = unlock.timeMs ?? 0;
        final bestRecords = profile.bestRecordsByMode[mode] ?? [];
        if (bestRecords.isEmpty) return false;
        final bestTimeMs = bestRecords.first.timeMs;
        return bestTimeMs <= requiredTimeMs;
        
      case 'bestMsExactly':
        // ベスト記録が指定時間と一致（いずれかのモード）
        final requiredTimeMs = unlock.timeMs ?? 0;
        for (final records in profile.bestRecordsByMode.values) {
          if (records.isEmpty) continue;
          if (records.first.timeMs == requiredTimeMs) return true;
        }
        return false;
        
      case 'duelPlayCount':
        // 2人対戦の総プレイ回数
        final requiredCount = unlock.count ?? 0;
        final duelCount = profile.duelPlayCount;
        return duelCount >= requiredCount;
        
      case 'duelWinCount':
        // 2人対戦の総勝利数
        final requiredCount = unlock.count ?? 0;
        final winCount = profile.duelWinCount;
        return winCount >= requiredCount;
        
      case 'duelLossCount':
        // 2人対戦の総敗北数
        final requiredCount = unlock.count ?? 0;
        final lossCount = profile.duelLossCount;
        return lossCount >= requiredCount;
        
      case 'duelWinStreak':
        // 2人対戦の最大連勝数（モード別）
        final mode = unlock.mode;
        if (mode == null) return false; // モード指定必須
        final requiredCount = unlock.count ?? 0;
        final maxStreak = profile.maxWinStreakByMode[mode] ?? 0;
        return maxStreak >= requiredCount;
        
      case 'loginStreak':
        // 連続ログイン日数
        final requiredCount = unlock.count ?? 0;
        final currentStreak = profile.loginStreak;
        return currentStreak >= requiredCount;
        
      case 'playedAtTime':
        // 特定時刻にプレイ完了
        final requiredTime = unlock.hhmm ?? '';
        if (lastGameResult == null) return false;
        final completedAt = lastGameResult['completedAt'] as DateTime?;
        if (completedAt == null) return false;
        final timeStr = '${completedAt.hour.toString().padLeft(2, '0')}:${completedAt.minute.toString().padLeft(2, '0')}';
        return timeStr == requiredTime;
        
      case 'mutePlayCount':
        // 無音プレイ回数
        final requiredCount = unlock.count ?? 0;
        final muteCount = profile.mutePlayCount;
        return muteCount >= requiredCount;
        
      default:
        return false;
    }
  }

  /// プレイ回数から獲得可能な称号をチェック（後方互換用）
  /// 
  /// [playCountByMode] 各モードのプレイ回数
  /// [unlockedTitleIds] 既に獲得済みの称号ID
  /// 
  /// 返り値: 新たに獲得した称号のリスト
  @Deprecated('Use checkUnlockableTitles with PlayerProfile instead')
  List<TitleDefinition> checkUnlockableTitlesLegacy({
    required Map<String, int> playCountByMode,
    required List<String> unlockedTitleIds,
  }) {
    final newlyUnlocked = <TitleDefinition>[];
    
    for (final title in getAllTitles()) {
      // 既に獲得済みならスキップ
      if (unlockedTitleIds.contains(title.id)) continue;
      
      // プレイ回数チェック
      if (title.unlock.type == 'playCount') {
        final mode = title.unlock.mode;
        final requiredCount = title.unlock.count ?? 0;
        final currentCount = playCountByMode[mode] ?? 0;
        
        if (currentCount >= requiredCount) {
          newlyUnlocked.add(title);
        }
      }
    }
    
    return newlyUnlocked;
  }
}
