import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/duel_room.dart';
import '../utils/event_plan_generator.dart';
import 'firebase_service.dart';

/// 2人対戦のFirestore操作を管理するサービス
class DuelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  /// 6桁の部屋コードを生成（A-Z0-9）
  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// 部屋を作成（ホスト）
  /// 
  /// 戻り値: 作成された部屋のroomId
  Future<String> createRoom(String mode) async {
    if (kDebugMode) {
      debugPrint('🚀 [createRoom] START: mode=$mode');
    }

    // Step 1: Auth UID取得
    final hostUid = _firebaseService.getUid();
    if (kDebugMode) {
      debugPrint('✅ [createRoom] Auth UID取得完了: uid=$hostUid');
    }
    
    // 最大10回まで重複チェック
    for (int attempt = 0; attempt < 10; attempt++) {
      // Step 2: joinCode生成
      final joinCode = _generateJoinCode();
      if (kDebugMode) {
        debugPrint('🔑 [createRoom] joinCode生成: $joinCode (試行${attempt + 1}/10)');
      }
      
      try {
        // Step 3: joinCodesの存在チェック
        if (kDebugMode) {
          debugPrint('🔍 [createRoom] joinCodesの存在チェック開始: $joinCode');
        }
        final joinCodeDoc = await _firestore
            .collection('joinCodes')
            .doc(joinCode)
            .get();

        if (joinCodeDoc.exists) {
          // 既に存在する場合は次の試行へ
          if (kDebugMode) {
            debugPrint('⚠️ [createRoom] joinCode重複: $joinCode (試行${attempt + 1}/10)');
          }
          continue;
        }
        if (kDebugMode) {
          debugPrint('✅ [createRoom] joinCode使用可能: $joinCode');
        }

        // Step 4: rooms docの作成とbatch開始
        final roomRef = _firestore.collection('rooms').doc();
        final roomId = roomRef.id;
        if (kDebugMode) {
          debugPrint('📝 [createRoom] rooms doc作成開始: roomId=$roomId');
        }

        // WriteBatchで同時書き込み（原子性確保）
        final batch = _firestore.batch();

        // rooms/{roomId} を作成
        batch.set(roomRef, {
          'joinCode': joinCode,
          'mode': mode,
          'hostUid': hostUid,
          'guestUid': '', // 空で開始
          'status': RoomStatus.waiting.name,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // joinCodes/{CODE} を作成
        batch.set(_firestore.collection('joinCodes').doc(joinCode), {
          'roomId': roomId,
          'hostUid': hostUid,
          'mode': mode,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) {
          debugPrint('💾 [createRoom] batch commit開始...');
        }
        await batch.commit();
        if (kDebugMode) {
          debugPrint('✅ [createRoom] batch commit完了');
        }

        if (kDebugMode) {
          debugPrint('🎉 [createRoom] 部屋作成成功: roomId=$roomId, joinCode=$joinCode');
        }

        return roomId;
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('❌ [createRoom] 部屋作成エラー (試行${attempt + 1}/10)');
          debugPrint('   エラー内容: $e');
          if (e is FirebaseException) {
            debugPrint('   Firebase code: ${e.code}');
            debugPrint('   Firebase message: ${e.message}');
          }
          debugPrint('   StackTrace: $stackTrace');
        }
        if (attempt == 9) rethrow;
      }
    }

    final error = '部屋コードの生成に失敗しました（10回試行）';
    if (kDebugMode) {
      debugPrint('❌ [createRoom] FAILED: $error');
    }
    throw Exception(error);
  }

  /// 部屋に参加（ゲスト）
  /// 
  /// トランザクションで guestUid が空なら自分のuidをセット
  /// 戻り値: 参加した部屋のroomId
  Future<String> joinRoom(String joinCode) async {
    final guestUid = _firebaseService.getUid();

    // joinCodes/{CODE} からroomIdを取得
    final joinCodeDoc = await _firestore
        .collection('joinCodes')
        .doc(joinCode.toUpperCase())
        .get();

    if (!joinCodeDoc.exists) {
      throw Exception('部屋が見つかりません');
    }

    final roomId = joinCodeDoc.data()?['roomId'] as String?;
    if (roomId == null || roomId.isEmpty) {
      throw Exception('部屋IDが無効です');
    }

    // トランザクションで満室チェック + guestUid設定
    try {
      await _firestore.runTransaction((transaction) async {
        final roomRef = _firestore.collection('rooms').doc(roomId);
        final roomSnapshot = await transaction.get(roomRef);

        if (!roomSnapshot.exists) {
          throw Exception('部屋が存在しません');
        }

        final currentGuestUid = roomSnapshot.data()?['guestUid'] as String? ?? '';

        // 満室チェック
        if (currentGuestUid.isNotEmpty) {
          throw Exception('この部屋は既に満室です');
        }

        // 自分がホストの場合
        final hostUid = roomSnapshot.data()?['hostUid'] as String? ?? '';
        if (hostUid == guestUid) {
          throw Exception('自分が作成した部屋には参加できません');
        }

        // guestUidをセット、ステータスをreadyに
        transaction.update(roomRef, {
          'guestUid': guestUid,
          'status': RoomStatus.ready.name,
        });
      });

      if (kDebugMode) {
        debugPrint('✅ 部屋参加成功: roomId=$roomId');
      }

      return roomId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 部屋参加エラー: $e');
      }
      rethrow;
    }
  }

  /// 部屋をリアルタイム購読
  Stream<DuelRoom> watchRoom(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            throw Exception('部屋が削除されました');
          }
          return DuelRoom.fromFirestore(snapshot);
        });
  }

  /// ゲームを開始（ホストのみ）
  /// 
  /// seedを生成してeventPlanを作成、Firestoreに書き込み、statusをrunningに
  Future<void> startGame(String roomId) async {
    // Step 1: roomデータ取得
    final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
    if (!roomDoc.exists) {
      throw Exception('部屋が見つかりません: $roomId');
    }
    
    final roomData = roomDoc.data()!;
    final mode = roomData['mode'] as String;
    
    // Step 2: seed生成
    final seed = DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
    
    // Step 3: eventPlan生成
    final eventPlan = EventPlanGenerator.generate(mode, seed);
    
    if (kDebugMode) {
      debugPrint('⚡ [startGame] eventPlan生成完了: mode=$mode, seed=$seed');
      debugPrint('📝 eventPlan: $eventPlan');
    }

    // Step 4: Firestoreに保存
    await _firestore.collection('rooms').doc(roomId).update({
      'seed': seed,
      'eventPlan': eventPlan,
      'status': RoomStatus.running.name,
    });

    if (kDebugMode) {
      debugPrint('✅ ゲーム開始: roomId=$roomId, seed=$seed');
    }
  }

  /// 結果を書き込む
  /// 
  /// isHost: trueならhost結果、falseならguest結果
  Future<void> submitResult({
    required String roomId,
    required bool isHost,
    required int reactionMs,
    required bool foul,
    int? round1Time, // Boxingモード専用
    int? round2Time, // Boxingモード専用
    int? round3Time, // Boxingモード専用
  }) async {
    final resultKey = isHost ? 'results.host' : 'results.guest';

    final resultData = {
      'reactionMs': reactionMs,
      'foul': foul,
    };
    
    // Boxing詳細タイムを追加
    if (round1Time != null) resultData['round1Time'] = round1Time;
    if (round2Time != null) resultData['round2Time'] = round2Time;
    if (round3Time != null) resultData['round3Time'] = round3Time;

    await _firestore.collection('rooms').doc(roomId).update({
      resultKey: resultData,
    });

    if (kDebugMode) {
      debugPrint('✅ 結果送信: roomId=$roomId, isHost=$isHost, reactionMs=$reactionMs, foul=$foul');
    }
  }

  /// 部屋を削除（ホストのみ、キャンセル時）
  Future<void> deleteRoom(String roomId, String joinCode) async {
    final batch = _firestore.batch();

    batch.delete(_firestore.collection('rooms').doc(roomId));
    batch.delete(_firestore.collection('joinCodes').doc(joinCode));

    await batch.commit();

    if (kDebugMode) {
      debugPrint('✅ 部屋削除: roomId=$roomId, joinCode=$joinCode');
    }
  }

  /// ゲストが退出（status が waiting/ready の場合のみ）
  Future<void> leaveRoom(String roomId) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'guestUid': '',
        'status': RoomStatus.waiting.name,
      });

      if (kDebugMode) {
        debugPrint('✅ 退出成功: roomId=$roomId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 退出エラー: $e');
      }
      rethrow;
    }
  }

  /// ゲーム終了をマーク（両方の結果が揃った後、ホストが実行）
  Future<void> finishGame(String roomId) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'status': RoomStatus.finished.name,
    });

    if (kDebugMode) {
      debugPrint('✅ ゲーム終了: roomId=$roomId');
    }
  }
}
