import 'package:cloud_firestore/cloud_firestore.dart';

/// 部屋のステータス
enum RoomStatus {
  waiting,  // ゲスト待ち
  ready,    // ゲスト参加済み、開始待ち
  running,  // ゲーム進行中
  finished, // ゲーム終了
}

/// プレイヤー結果
class PlayerResult {
  final int reactionMs;  // 反応時間（ミリ秒）
  final bool foul;       // お手付きフラグ

  PlayerResult({
    required this.reactionMs,
    required this.foul,
  });

  Map<String, dynamic> toMap() {
    return {
      'reactionMs': reactionMs,
      'foul': foul,
    };
  }

  factory PlayerResult.fromMap(Map<String, dynamic> map) {
    return PlayerResult(
      reactionMs: map['reactionMs'] as int? ?? 0,
      foul: map['foul'] as bool? ?? false,
    );
  }
}

/// 対戦部屋データ
class DuelRoom {
  final String roomId;
  final String joinCode;
  final String mode;
  final String hostUid;
  final String guestUid;
  final RoomStatus status;
  final int? seed;
  final Map<String, dynamic>? eventPlan;
  final PlayerResult? hostResult;
  final PlayerResult? guestResult;
  final DateTime createdAt;

  DuelRoom({
    required this.roomId,
    required this.joinCode,
    required this.mode,
    required this.hostUid,
    required this.guestUid,
    required this.status,
    this.seed,
    this.eventPlan,
    this.hostResult,
    this.guestResult,
    required this.createdAt,
  });

  /// Firestoreドキュメントから変換
  factory DuelRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return DuelRoom(
      roomId: doc.id,
      joinCode: data['joinCode'] as String? ?? '',
      mode: data['mode'] as String? ?? '',
      hostUid: data['hostUid'] as String? ?? '',
      guestUid: data['guestUid'] as String? ?? '',
      status: _parseStatus(data['status'] as String?),
      seed: data['seed'] as int?,
      eventPlan: data['eventPlan'] as Map<String, dynamic>?,
      hostResult: data['results']?['host'] != null
          ? PlayerResult.fromMap(data['results']['host'] as Map<String, dynamic>)
          : null,
      guestResult: data['results']?['guest'] != null
          ? PlayerResult.fromMap(data['results']['guest'] as Map<String, dynamic>)
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestoreマップに変換
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'joinCode': joinCode,
      'mode': mode,
      'hostUid': hostUid,
      'guestUid': guestUid,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (seed != null) map['seed'] = seed;
    if (eventPlan != null) map['eventPlan'] = eventPlan;

    if (hostResult != null || guestResult != null) {
      map['results'] = <String, dynamic>{};
      if (hostResult != null) map['results']['host'] = hostResult!.toMap();
      if (guestResult != null) map['results']['guest'] = guestResult!.toMap();
    }

    return map;
  }

  /// ステータス文字列からenumに変換
  static RoomStatus _parseStatus(String? status) {
    switch (status) {
      case 'waiting':
        return RoomStatus.waiting;
      case 'ready':
        return RoomStatus.ready;
      case 'running':
        return RoomStatus.running;
      case 'finished':
        return RoomStatus.finished;
      default:
        return RoomStatus.waiting;
    }
  }

  /// ゲストが参加済みかどうか
  bool get hasGuest => guestUid.isNotEmpty;

  /// 両プレイヤーの結果が揃ったか
  bool get hasBothResults => hostResult != null && guestResult != null;
}
