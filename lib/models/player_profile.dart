/// 自己ベスト記録
class BestRecord {
  final int timeMs;
  final int achievedAtEpochMs;

  BestRecord({
    required this.timeMs,
    required this.achievedAtEpochMs,
  });

  factory BestRecord.fromJson(Map<String, dynamic> json) {
    return BestRecord(
      timeMs: json['timeMs'] as int,
      achievedAtEpochMs: json['achievedAtEpochMs'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeMs': timeMs,
      'achievedAtEpochMs': achievedAtEpochMs,
    };
  }

  DateTime get achievedAt =>
      DateTime.fromMillisecondsSinceEpoch(achievedAtEpochMs);
}

/// プレイヤープロフィール
class PlayerProfile {
  final String playerName;
  final String? selectedTitleId;
  final List<String> unlockedTitleIds;
  final Map<String, int> playCountByMode;
  final Map<String, List<BestRecord>> bestRecordsByMode;
  final Map<String, int> maxWinStreakByMode; // 最大連勝数（2人対戦のみ）
  final Map<String, int> currentWinStreakByMode; // 現在の連勝数（2人対戦のみ）
  final int duelPlayCount; // 2人対戦の総プレイ回数
  final int loginStreak; // 連続ログイン日数

  PlayerProfile({
    required this.playerName,
    this.selectedTitleId,
    required this.unlockedTitleIds,
    required this.playCountByMode,
    required this.bestRecordsByMode,
    required this.maxWinStreakByMode,
    required this.currentWinStreakByMode,
    this.duelPlayCount = 0,
    this.loginStreak = 0,
  });

  /// デフォルトプロフィール
  factory PlayerProfile.defaultProfile() {
    return PlayerProfile(
      playerName: '名もなきガンマン',
      selectedTitleId: null,
      unlockedTitleIds: [],
      playCountByMode: {
        'WESTERN': 0,
        'BOXING': 0,
        'WIZARD': 0,
        'SAMURAI': 0,
      },
      bestRecordsByMode: {
        'WESTERN': [],
        'BOXING': [],
        'WIZARD': [],
        'SAMURAI': [],
      },
      maxWinStreakByMode: {
        'WESTERN': 0,
        'BOXING': 0,
        'WIZARD': 0,
        'SAMURAI': 0,
      },
      currentWinStreakByMode: {
        'WESTERN': 0,
        'BOXING': 0,
        'WIZARD': 0,
        'SAMURAI': 0,
      },
      duelPlayCount: 0,
      loginStreak: 0,
    );
  }

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    // bestRecordsByMode の復元
    final bestRecordsJson = json['bestRecordsByMode'] as Map<String, dynamic>? ?? {};
    final bestRecordsByMode = <String, List<BestRecord>>{};
    
    bestRecordsJson.forEach((mode, recordsList) {
      final records = (recordsList as List)
          .map((r) => BestRecord.fromJson(r as Map<String, dynamic>))
          .toList();
      bestRecordsByMode[mode] = records;
    });

    return PlayerProfile(
      playerName: json['playerName'] as String? ?? '名もなきガンマン',
      selectedTitleId: json['selectedTitleId'] as String?,
      unlockedTitleIds: List<String>.from(json['unlockedTitleIds'] as List? ?? []),
      playCountByMode: Map<String, int>.from(json['playCountByMode'] as Map? ?? {}),
      bestRecordsByMode: bestRecordsByMode,
      maxWinStreakByMode: Map<String, int>.from(json['maxWinStreakByMode'] as Map? ?? {}),
      currentWinStreakByMode: Map<String, int>.from(json['currentWinStreakByMode'] as Map? ?? {}),
      duelPlayCount: json['duelPlayCount'] as int? ?? 0,
      loginStreak: json['loginStreak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    // bestRecordsByMode の変換
    final bestRecordsJson = <String, dynamic>{};
    bestRecordsByMode.forEach((mode, records) {
      bestRecordsJson[mode] = records.map((r) => r.toJson()).toList();
    });

    return {
      'playerName': playerName,
      'selectedTitleId': selectedTitleId,
      'unlockedTitleIds': unlockedTitleIds,
      'playCountByMode': playCountByMode,
      'bestRecordsByMode': bestRecordsJson,
      'maxWinStreakByMode': maxWinStreakByMode,
      'currentWinStreakByMode': currentWinStreakByMode,
      'duelPlayCount': duelPlayCount,
      'loginStreak': loginStreak,
    };
  }

  /// プロフィールコピー（一部変更用）
  PlayerProfile copyWith({
    String? playerName,
    String? Function()? selectedTitleId,
    List<String>? unlockedTitleIds,
    Map<String, int>? playCountByMode,
    Map<String, List<BestRecord>>? bestRecordsByMode,
    Map<String, int>? maxWinStreakByMode,
    Map<String, int>? currentWinStreakByMode,
    int? duelPlayCount,
    int? loginStreak,
  }) {
    return PlayerProfile(
      playerName: playerName ?? this.playerName,
      selectedTitleId: selectedTitleId != null ? selectedTitleId() : this.selectedTitleId,
      unlockedTitleIds: unlockedTitleIds ?? this.unlockedTitleIds,
      playCountByMode: playCountByMode ?? this.playCountByMode,
      bestRecordsByMode: bestRecordsByMode ?? this.bestRecordsByMode,
      maxWinStreakByMode: maxWinStreakByMode ?? this.maxWinStreakByMode,
      currentWinStreakByMode: currentWinStreakByMode ?? this.currentWinStreakByMode,
      duelPlayCount: duelPlayCount ?? this.duelPlayCount,
      loginStreak: loginStreak ?? this.loginStreak,
    );
  }
}
