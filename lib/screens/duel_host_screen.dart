import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/duel_room.dart';
import '../providers/game_state_provider.dart';
import '../services/audio_service.dart';
import '../services/duel_service.dart';
import 'duel_game_screen.dart';

/// ホスト用の待機画面（部屋作成・ゲスト待ち・開始）
class DuelHostScreen extends StatefulWidget {
  final GameMode mode;

  const DuelHostScreen({super.key, required this.mode});

  @override
  State<DuelHostScreen> createState() => _DuelHostScreenState();
}

class _DuelHostScreenState extends State<DuelHostScreen> {
  final DuelService _duelService = DuelService();
  final AudioService _audioService = AudioService();

  String? _roomId;
  String? _joinCode;
  StreamSubscription<DuelRoom>? _roomSubscription;
  DuelRoom? _currentRoom;
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _createRoomWithTimeout();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }

  /// 部屋を作成（10秒タイムアウト）
  Future<void> _createRoomWithTimeout() async {
    if (kDebugMode) {
      debugPrint('🚀 [DuelHostScreen] _createRoomWithTimeout START');
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 10秒タイムアウト付きで部屋作成
      final roomId = await _duelService.createRoom(_getModeString()).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⏰ [DuelHostScreen] createRoom TIMEOUT (10秒)');
          }
          throw TimeoutException('部屋作成がタイムアウトしました（10秒）');
        },
      );
      
      if (kDebugMode) {
        debugPrint('✅ [DuelHostScreen] createRoom SUCCESS: roomId=$roomId');
      }

      if (!mounted) return;

      setState(() {
        _roomId = roomId;
      });

      // リアルタイム購読開始
      if (kDebugMode) {
        debugPrint('👁️ [DuelHostScreen] watchRoom START: roomId=$roomId');
      }
      _roomSubscription = _duelService.watchRoom(roomId).listen(
        (room) {
          if (kDebugMode) {
            debugPrint('📡 [DuelHostScreen] watchRoom UPDATE: status=${room.status.name}, hasGuest=${room.hasGuest}');
          }
          if (!mounted) return;
          setState(() {
            _currentRoom = room;
            _joinCode = room.joinCode;
            _isLoading = false;
          });
        },
        onError: (error, stackTrace) {
          if (kDebugMode) {
            debugPrint('❌ [DuelHostScreen] watchRoom ERROR: $error');
            debugPrint('   StackTrace: $stackTrace');
          }
          if (!mounted) return;
          setState(() {
            _errorMessage = 'エラーが発生しました: $error';
            _isLoading = false;
          });
        },
      );
    } on TimeoutException catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('⏰ [DuelHostScreen] TIMEOUT EXCEPTION: $e');
        debugPrint('   StackTrace: $stackTrace');
      }
      if (!mounted) return;
      setState(() {
        _errorMessage = 'タイムアウト: 部屋作成に10秒以上かかりました。\n\n原因の可能性:\n- Firebase Authの認証問題\n- Firestoreへの接続問題\n- ネットワーク制限';
        _isLoading = false;
      });
    } on FirebaseException catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('🔥 [DuelHostScreen] FIREBASE EXCEPTION');
        debugPrint('   code: ${e.code}');
        debugPrint('   message: ${e.message}');
        debugPrint('   StackTrace: $stackTrace');
      }
      if (!mounted) return;

      String errorMsg;
      if (e.code == 'permission-denied') {
        errorMsg = 'Firebaseアクセスが拒否されました。\n\nFirestoreルールが正しく設定されているか確認してください。';
      } else if (e.code == 'unavailable') {
        errorMsg = 'Firebaseに接続できません。\n\nインターネット接続を確認してください。';
      } else {
        errorMsg = 'Firebaseエラー: ${e.code}\n\n${e.message ?? ""}';
      }

      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [DuelHostScreen] UNKNOWN EXCEPTION: $e');
        debugPrint('   StackTrace: $stackTrace');
      }
      if (!mounted) return;
      setState(() {
        _errorMessage = '部屋の作成に失敗しました\n\nエラー: $e';
        _isLoading = false;
      });
    }
  }

  /// モード文字列を取得
  String _getModeString() {
    switch (widget.mode) {
      case GameMode.western:
        return 'WESTERN';
      case GameMode.boxing:
        return 'BOXING';
      case GameMode.wizard:
        return 'WIZARD';
      case GameMode.samurai:
        return 'SAMURAI';
    }
  }

  /// ゲームを開始（ホストのみ）
  Future<void> _startGame() async {
    if (_roomId == null) return;

    _audioService.playUISelect();

    try {
      // seedを生成してFirestoreに保存、status=runningに
      await _duelService.startGame(_roomId!);

      // DuelGameScreenに遷移
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DuelGameScreen(
              roomId: _roomId!,
              isHost: true,
              mode: widget.mode,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ゲーム開始エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 部屋をキャンセル（削除）
  Future<void> _cancelRoom() async {
    _audioService.playUISelect();

    if (_roomId != null && _joinCode != null) {
      try {
        // rooms と joinCodes を batch delete
        await _duelService.deleteRoom(_roomId!, _joinCode!);
      } catch (e) {
        debugPrint('部屋削除エラー: $e');
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // エラー画面
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    // ローディング画面
    if (_isLoading || _currentRoom == null) {
      return _buildLoadingScreen();
    }

    // メイン画面
    return _buildMainScreen();
  }

  /// エラー画面
  Widget _buildErrorScreen() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD8C9B4),
              Color(0xFFE6D4BC),
              Color(0xFFC5AE8E),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 24),
                  
                  // エラーメッセージ
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: Text(
                      _errorMessage ?? 'エラーが発生しました',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade900,
                        fontFamily: 'serif',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // RETRYボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _audioService.playUISelect();
                        _createRoomWithTimeout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3D2E1F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'RETRY',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE6D4BC),
                          letterSpacing: 2,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 戻るボタン
                  OutlinedButton(
                    onPressed: () {
                      _audioService.playUISelect();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      side: BorderSide(color: Color(0xFF8B6F47), width: 2),
                    ),
                    child: Text(
                      '戻る',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF3D2E1F),
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ローディング画面
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD8C9B4),
              Color(0xFFE6D4BC),
              Color(0xFFC5AE8E),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF3D2E1F)),
                const SizedBox(height: 24),
                Text(
                  '部屋を作成中...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF3D2E1F),
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// メイン画面
  Widget _buildMainScreen() {
    final hasGuest = _currentRoom!.hasGuest;
    final canStart = hasGuest && _currentRoom!.status == RoomStatus.ready;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD8C9B4),
              Color(0xFFE6D4BC),
              Color(0xFFC5AE8E),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // タイトル
                Text(
                  'HOST - ${_getModeString()} DUEL',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2E1F),
                    letterSpacing: 2,
                    fontFamily: 'serif',
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // 部屋番号
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFFE6D4BC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF8B6F47), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '部屋番号',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF5C4A3A),
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _joinCode ?? '---',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D2E1F),
                          letterSpacing: 8,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // QRコード
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF8B6F47), width: 3),
                  ),
                  child: QrImageView(
                    data: _joinCode ?? '',
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                // ステータス表示
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: hasGuest ? Color(0xFF2E7D32) : Color(0xFFE6D4BC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasGuest ? Color(0xFF1B5E20) : Color(0xFF8B6F47),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasGuest ? Icons.check_circle : Icons.hourglass_empty,
                        color: hasGuest ? Colors.white : Color(0xFF5C4A3A),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        hasGuest ? 'ゲストが参加しました！' : 'ゲスト参加待ち...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: hasGuest ? Colors.white : Color(0xFF3D2E1F),
                          fontFamily: 'serif',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // STARTボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canStart ? _startGame : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canStart ? Color(0xFF3D2E1F) : Color(0xFF8B6F47),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'START',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE6D4BC),
                        letterSpacing: 3,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // CANCELボタン
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _cancelRoom,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(color: Color(0xFF8B6F47), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D2E1F),
                        letterSpacing: 2,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
