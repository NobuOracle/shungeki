/// 称号の定義
class TitleDefinition {
  final String id;
  final String name;
  final String description;
  final TitleUnlockCondition unlock;

  TitleDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.unlock,
  });

  factory TitleDefinition.fromJson(Map<String, dynamic> json) {
    return TitleDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      unlock: TitleUnlockCondition.fromJson(json['unlock'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'unlock': unlock.toJson(),
    };
  }
}

/// 称号獲得条件
class TitleUnlockCondition {
  final String type; // "playCount", "bestMsAtMost", "bestMsExactly", etc.
  final String? mode; // "WESTERN", "BOXING", "WIZARD", "SAMURAI" (optional)
  final int? count; // プレイ回数、連勝数など (optional)
  final int? timeMs; // ベスト記録のミリ秒 (optional)
  final String? hhmm; // 特定時刻 "HH:MM" (optional)

  TitleUnlockCondition({
    required this.type,
    this.mode,
    this.count,
    this.timeMs,
    this.hhmm,
  });

  factory TitleUnlockCondition.fromJson(Map<String, dynamic> json) {
    return TitleUnlockCondition(
      type: json['type'] as String,
      mode: json['mode'] as String?,
      count: json['count'] as int?,
      timeMs: json['timeMs'] as int?,
      hhmm: json['hhmm'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'type': type,
    };
    if (mode != null) map['mode'] = mode;
    if (count != null) map['count'] = count;
    if (timeMs != null) map['timeMs'] = timeMs;
    if (hhmm != null) map['hhmm'] = hhmm;
    return map;
  }
}
