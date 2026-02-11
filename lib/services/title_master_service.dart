import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/title_definition.dart';

/// 称号マスターサービス
/// assets/titles.json から称号定義を読み込む
class TitleMasterService {
  static final TitleMasterService _instance = TitleMasterService._internal();
  factory TitleMasterService() => _instance;
  TitleMasterService._internal();

  List<TitleDefinition>? _titles;

  /// 称号マスタを読み込む
  Future<void> loadTitles() async {
    if (_titles != null) return; // 既に読み込み済み

    try {
      final String jsonString = await rootBundle.loadString('assets/titles.json');
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

  /// プレイ回数から獲得可能な称号をチェック
  /// 
  /// [playCountByMode] 各モードのプレイ回数
  /// [unlockedTitleIds] 既に獲得済みの称号ID
  /// 
  /// 返り値: 新たに獲得した称号のリスト
  List<TitleDefinition> checkUnlockableTitles({
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
        final requiredCount = title.unlock.count;
        final currentCount = playCountByMode[mode] ?? 0;
        
        if (currentCount >= requiredCount) {
          newlyUnlocked.add(title);
        }
      }
    }
    
    return newlyUnlocked;
  }
}
