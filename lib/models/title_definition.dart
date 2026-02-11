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
  final String type; // "playCount" など
  final String mode; // "WESTERN", "BOXING", "WIZARD", "SAMURAI"
  final int count;

  TitleUnlockCondition({
    required this.type,
    required this.mode,
    required this.count,
  });

  factory TitleUnlockCondition.fromJson(Map<String, dynamic> json) {
    return TitleUnlockCondition(
      type: json['type'] as String,
      mode: json['mode'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'mode': mode,
      'count': count,
    };
  }
}
