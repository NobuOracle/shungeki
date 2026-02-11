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

  PlayerProfile({
    required this.playerName,
    this.selectedTitleId,
    required this.unlockedTitleIds,
    required this.playCountByMode,
    required this.bestRecordsByMode,
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
    };
  }

  /// プロフィールコピー（一部変更用）
  PlayerProfile copyWith({
    String? playerName,
    String? Function()? selectedTitleId,
    List<String>? unlockedTitleIds,
    Map<String, int>? playCountByMode,
    Map<String, List<BestRecord>>? bestRecordsByMode,
  }) {
    return PlayerProfile(
      playerName: playerName ?? this.playerName,
      selectedTitleId: selectedTitleId != null ? selectedTitleId() : this.selectedTitleId,
      unlockedTitleIds: unlockedTitleIds ?? this.unlockedTitleIds,
      playCountByMode: playCountByMode ?? this.playCountByMode,
      bestRecordsByMode: bestRecordsByMode ?? this.bestRecordsByMode,
    );
  }
}
