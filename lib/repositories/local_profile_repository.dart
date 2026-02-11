import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_profile.dart';
import '../models/title_definition.dart';
import '../services/title_master_service.dart';
import '../services/bad_word_service.dart';

/// ローカルプロフィールリポジトリ（SharedPreferences）
class LocalProfileRepository {
  static const String _keyProfile = 'player_profile';

  final SharedPreferences _prefs;
  final TitleMasterService _titleMaster;
  final BadWordService _badWordService;

  LocalProfileRepository(this._prefs, this._titleMaster, this._badWordService);

  /// プロフィール読み込み
  Future<PlayerProfile> load() async {
    try {
      final String? jsonString = _prefs.getString(_keyProfile);
      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('📋 [LocalProfileRepository] プロフィール未保存、デフォルトを返す');
        return PlayerProfile.defaultProfile();
      }
      
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final profile = PlayerProfile.fromJson(json);
      debugPrint('✅ [LocalProfileRepository] プロフィール読み込み成功');
      debugPrint('📋 [LocalProfileRepository] 獲得済み称号: ${profile.unlockedTitleIds.length}件 - ${profile.unlockedTitleIds.join(", ")}');
      return profile;
    } catch (e) {
      debugPrint('❌ [LocalProfileRepository] プロフィール読み込みエラー: $e');
      return PlayerProfile.defaultProfile();
    }
  }

  /// プロフィール保存
  Future<void> save(PlayerProfile profile) async {
    try {
      final jsonString = jsonEncode(profile.toJson());
      await _prefs.setString(_keyProfile, jsonString);
      debugPrint('✅ [LocalProfileRepository] プロフィール保存完了');
      debugPrint('📋 [LocalProfileRepository] 保存した獲得済み称号: ${profile.unlockedTitleIds.length}件 - ${profile.unlockedTitleIds.join(", ")}');
    } catch (e) {
      debugPrint('❌ [LocalProfileRepository] プロフィール保存エラー: $e');
    }
  }

  /// プレイヤー名を検証・保存
  /// 
  /// 返り値: エラーメッセージ（成功時はnull）
  String? validateAndUpdatePlayerName(PlayerProfile current, String newName) {
    // 前後スペーストリム
    final trimmed = newName.trim();
    
    // 空文字チェック
    if (trimmed.isEmpty) {
      return 'プレイヤー名を入力してください';
    }
    
    // 最大文字数チェック
    if (trimmed.length > 20) {
      return 'プレイヤー名は20文字以内にしてください';
    }
    
    // 改行チェック
    if (trimmed.contains('\n') || trimmed.contains('\r')) {
      return 'プレイヤー名に改行を含めることはできません';
    }
    
    // 不適切ワードチェック（BadWordService使用）
    if (_badWordService.containsBadWord(trimmed)) {
      return '使用できない単語が含まれています';
    }
    
    return null; // 検証OK
  }

  /// プレイ回数を更新
  Future<PlayerProfile> incrementPlayCount(PlayerProfile current, String mode) async {
    final newCounts = Map<String, int>.from(current.playCountByMode);
    newCounts[mode] = (newCounts[mode] ?? 0) + 1;
    
    final updated = current.copyWith(playCountByMode: newCounts);
    await save(updated);
    
    debugPrint('📊 [LocalProfileRepository] プレイ回数更新: $mode → ${newCounts[mode]}');
    return updated;
  }

  /// 自己ベスト更新（TOP3維持）
  Future<PlayerProfile> updateBestRecord({
    required PlayerProfile current,
    required String mode,
    required int timeMs,
    required DateTime achievedAt,
  }) async {
    final records = List<BestRecord>.from(current.bestRecordsByMode[mode] ?? []);
    
    final newRecord = BestRecord(
      timeMs: timeMs,
      achievedAtEpochMs: achievedAt.millisecondsSinceEpoch,
    );
    
    // 同タイムが既に存在するか確認
    final existingSameTime = records.where((r) => r.timeMs == timeMs).toList();
    if (existingSameTime.isNotEmpty) {
      // 同タイムの場合、早い日時を優先
      final earliestAchieved = existingSameTime
          .map((r) => r.achievedAtEpochMs)
          .reduce((a, b) => a < b ? a : b);
      
      if (newRecord.achievedAtEpochMs >= earliestAchieved) {
        debugPrint('⏭️ [LocalProfileRepository] 同タイムで日時が遅いためスキップ');
        return current; // 更新しない
      } else {
        // 古い方を削除
        records.removeWhere((r) => r.timeMs == timeMs);
      }
    }
    
    // 新記録を追加
    records.add(newRecord);
    
    // タイムでソート（昇順）
    records.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    
    // TOP3のみ保持
    final top3 = records.take(3).toList();
    
    final newBestRecords = Map<String, List<BestRecord>>.from(current.bestRecordsByMode);
    newBestRecords[mode] = top3;
    
    final updated = current.copyWith(bestRecordsByMode: newBestRecords);
    await save(updated);
    
    debugPrint('🏆 [LocalProfileRepository] 自己ベスト更新: $mode → ${timeMs}ms');
    return updated;
  }

  /// 称号獲得チェック＆獲得
  /// 
  /// 返り値: 新たに獲得した称号のリスト
  Future<List<TitleDefinition>> checkAndUnlockTitles(PlayerProfile current) async {
    final newTitles = _titleMaster.checkUnlockableTitles(
      playCountByMode: current.playCountByMode,
      unlockedTitleIds: current.unlockedTitleIds,
    );
    
    if (newTitles.isEmpty) return [];
    
    // 獲得した称号IDを追加
    final newUnlockedIds = List<String>.from(current.unlockedTitleIds);
    for (final title in newTitles) {
      newUnlockedIds.add(title.id);
    }
    
    final updated = current.copyWith(unlockedTitleIds: newUnlockedIds);
    await save(updated);
    
    debugPrint('🎖️ [LocalProfileRepository] 称号獲得: ${newTitles.map((t) => t.name).join(", ")}');
    return newTitles;
  }
}
