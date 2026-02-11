import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/player_profile.dart';
import '../models/title_definition.dart';
import '../repositories/local_profile_repository.dart';
import '../services/title_master_service.dart';

/// プロフィールプロバイダー
/// 
/// プレイヤープロフィールの管理と称号システムを提供
class ProfileProvider with ChangeNotifier {
  final LocalProfileRepository _repo;
  final TitleMasterService _titleMaster;

  PlayerProfile? _profile;
  List<TitleDefinition> _titleMasterList = [];

  ProfileProvider({
    required LocalProfileRepository repo,
    required TitleMasterService titleMaster,
  })  : _repo = repo,
        _titleMaster = titleMaster;

  // ゲッター
  PlayerProfile? get profile => _profile;
  List<TitleDefinition> get titleMasterList => _titleMasterList;
  
  /// 獲得済み称号取得
  List<TitleDefinition> get unlockedTitles {
    if (_profile == null) return [];
    return _titleMasterList
        .where((t) => _profile!.unlockedTitleIds.contains(t.id))
        .toList();
  }
  
  /// 未獲得称号取得
  List<TitleDefinition> get lockedTitles {
    if (_profile == null) return [];
    return _titleMasterList
        .where((t) => !_profile!.unlockedTitleIds.contains(t.id))
        .toList();
  }
  
  /// 選択中の称号取得
  TitleDefinition? get selectedTitle {
    if (_profile?.selectedTitleId == null) return null;
    return _titleMaster.getTitleById(_profile!.selectedTitleId!);
  }

  /// 初期化
  /// 
  /// titles.jsonの読み込みとプロフィールの読み込みを行う
  Future<void> init() async {
    try {
      debugPrint('🔄 [ProfileProvider] 初期化開始');
      
      // 称号マスタ読み込み
      await _titleMaster.loadTitles();
      _titleMasterList = _titleMaster.getAllTitles();
      debugPrint('✅ [ProfileProvider] 称号マスタ: ${_titleMasterList.length}件');
      
      // プロフィール読み込み
      _profile = await _repo.load();
      debugPrint('✅ [ProfileProvider] プロフィール読み込み完了: ${_profile!.playerName}');
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [ProfileProvider] 初期化エラー: $e');
      _profile = PlayerProfile.defaultProfile();
      notifyListeners();
    }
  }

  /// プレイヤー名更新
  /// 
  /// 不適切ワードチェックあり
  /// 返り値: 成功時true、失敗時false（エラーメッセージは引数で受け取る）
  Future<String?> updatePlayerName(String name) async {
    if (_profile == null) return 'プロフィールが初期化されていません';

    // バリデーション
    final error = _repo.validateAndUpdatePlayerName(_profile!, name);
    if (error != null) {
      debugPrint('⚠️ [ProfileProvider] プレイヤー名更新失敗: $error');
      return error;
    }

    // 更新
    final trimmed = name.trim();
    _profile = _profile!.copyWith(playerName: trimmed);
    await _repo.save(_profile!);
    
    debugPrint('✅ [ProfileProvider] プレイヤー名更新: $trimmed');
    notifyListeners();
    return null; // 成功
  }

  /// 二つ名（選択中の称号）を更新
  /// 
  /// nullで解除
  Future<void> updateSelectedTitle(String? titleId) async {
    if (_profile == null) return;

    _profile = _profile!.copyWith(
      selectedTitleId: () => titleId,
    );
    await _repo.save(_profile!);
    
    final titleName = titleId != null 
        ? (_titleMaster.getTitleById(titleId)?.name ?? 'Unknown')
        : '(なし)';
    debugPrint('✅ [ProfileProvider] 二つ名更新: $titleName');
    notifyListeners();
  }

  /// ゲーム終了処理
  /// 
  /// プレイ回数更新 → 自己ベスト更新 → 称号獲得判定
  /// 
  /// 返り値: 新たに獲得した称号のリスト
  Future<List<TitleDefinition>> onGameFinished({
    required String mode,
    required int timeMs,
    required DateTime achievedAt,
  }) async {
    if (_profile == null) return [];

    try {
      debugPrint('🎮 [ProfileProvider] ゲーム終了処理開始: mode=$mode, time=${timeMs}ms');
      
      // 1. プレイ回数更新
      _profile = await _repo.incrementPlayCount(_profile!, mode);
      
      // 2. 自己ベスト更新
      _profile = await _repo.updateBestRecord(
        current: _profile!,
        mode: mode,
        timeMs: timeMs,
        achievedAt: achievedAt,
      );
      
      // 3. 称号獲得判定
      final newTitles = await _repo.checkAndUnlockTitles(_profile!);
      
      if (newTitles.isNotEmpty) {
        debugPrint('🎖️ [ProfileProvider] 称号獲得: ${newTitles.map((t) => t.name).join(", ")}');
      }
      
      notifyListeners();
      return newTitles;
    } catch (e) {
      debugPrint('❌ [ProfileProvider] ゲーム終了処理エラー: $e');
      return [];
    }
  }

  /// プロフィールスナップショット取得（2人対戦用）
  /// 
  /// rooms/{roomId} に保存する用のデータ
  /// 
  /// 【重要】ゲスト参加時は2段階更新すること：
  /// 1. guestUid のみ update（参加専用許可）
  /// 2. 直後に guestProfile を update（この時点でisMemberになり通常updateで通る）
  Map<String, dynamic> getProfileSnapshot() {
    if (_profile == null) {
      return {
        'name': '名もなきガンマン',
        'titleId': null,
        'titleName': null,
        'titleCount': 0,
      };
    }

    final title = selectedTitle;
    return {
      'name': _profile!.playerName,
      'titleId': _profile!.selectedTitleId,
      'titleName': title?.name,
      'titleCount': _profile!.unlockedTitleIds.length,
    };
  }

  /// 2人対戦の勝敗処理（勝利）
  /// 
  /// 【注意】ソロプレイでは呼ばないこと
  Future<void> onDuelWin(String mode) async {
    if (_profile == null) return;

    try {
      final newCurrent = Map<String, int>.from(_profile!.currentWinStreakByMode);
      final newMax = Map<String, int>.from(_profile!.maxWinStreakByMode);

      // 現在の連勝数を+1
      final currentStreak = (newCurrent[mode] ?? 0) + 1;
      newCurrent[mode] = currentStreak;

      // 最大連勝数を更新
      final maxStreak = newMax[mode] ?? 0;
      if (currentStreak > maxStreak) {
        newMax[mode] = currentStreak;
        debugPrint('🏆 [ProfileProvider] 最大連勝記録更新: $mode → $currentStreak連勝');
      }

      _profile = _profile!.copyWith(
        currentWinStreakByMode: newCurrent,
        maxWinStreakByMode: newMax,
      );

      await _repo.save(_profile!);
      debugPrint('✅ [ProfileProvider] 連勝更新: $mode → $currentStreak連勝（最大: ${newMax[mode]}）');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [ProfileProvider] 連勝更新エラー: $e');
    }
  }

  /// 2人対戦の勝敗処理（敗北）
  /// 
  /// 【注意】ソロプレイでは呼ばないこと
  Future<void> onDuelLose(String mode) async {
    if (_profile == null) return;

    try {
      final newCurrent = Map<String, int>.from(_profile!.currentWinStreakByMode);

      // 連勝をリセット
      final previousStreak = newCurrent[mode] ?? 0;
      newCurrent[mode] = 0;

      _profile = _profile!.copyWith(currentWinStreakByMode: newCurrent);

      await _repo.save(_profile!);
      debugPrint('✅ [ProfileProvider] 連勝リセット: $mode（前回: $previousStreak連勝）');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [ProfileProvider] 連勝リセットエラー: $e');
    }
  }
}
