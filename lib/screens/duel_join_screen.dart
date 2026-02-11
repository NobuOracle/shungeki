import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/duel_room.dart';
import '../providers/game_state_provider.dart';
import '../services/audio_service.dart';
import '../services/duel_service.dart';
import 'duel_game_screen.dart';

/// 画面状態
enum ScreenState {
  input,    // 入力画面（QR/手入力）
  joining,  // 参加処理中
  waiting,  // 参加成功、ゲーム開始待ち
}

/// ゲスト用の参加画面（QR読み取り・部屋番号入力・参加待ち）
class DuelJoinScreen extends StatefulWidget {
  const DuelJoinScreen({super.key});

  @override
  State<DuelJoinScreen> createState() => _DuelJoinScreenState();
}

class _DuelJoinScreenState extends State<DuelJoinScreen> {
  final DuelService _duelService = DuelService();
  final AudioService _audioService = AudioService();
  final TextEditingController _codeController = TextEditingController();

  ScreenState _screenState = ScreenState.input;
  
  String? _roomId;
  StreamSubscription<DuelRoom>? _roomSubscription;
  
  bool _isManualInput = false; // false=QR読み取り, true=手入力
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _roomSubscription?.cancel();
    super.dispose();
  }

  /// QRコードをスキャン
  void _onQRDetected(BarcodeCapture capture) {
    if (_screenState != ScreenState.input) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code != null && code.isNotEmpty) {
      _joinRoom(code.trim().toUpperCase());
    }
  }

  /// 手入力の部屋番号で参加
  void _joinByManualInput() {
    final code = _codeController.text.trim().toUpperCase();
    
    if (code.isEmpty) {
      _showError('部屋番号を入力してください');
      return;
    }

    if (code.length != 6) {
      _showError('部屋番号は6桁です');
      return;
    }

    _joinRoom(code);
  }

  /// 部屋に参加
  Future<void> _joinRoom(String joinCode) async {
    setState(() {
      _screenState = ScreenState.joining;
      _errorMessage = null;
    });

    try {
      // joinCodes/{CODE} → roomId取得 → トランザクションで参加
      final roomId = await _duelService.joinRoom(joinCode);
      
      setState(() {
        _roomId = roomId;
        _screenState = ScreenState.waiting;
      });

      // リアルタイム購読開始
      _roomSubscription = _duelService.watchRoom(roomId).listen(
        (room) {
          // status == running を検知したらゲーム画面へ遷移
          // room.modeを使用してホストのモードに同期
          if (room.status == RoomStatus.running && room.seed != null) {
            _navigateToGame(room);
          }
        },
        onError: (error) {
          _showError('エラーが発生しました: $error');
          setState(() {
            _screenState = ScreenState.input;
          });
        },
      );
    } catch (e) {
      _showError('参加失敗: $e');
      setState(() {
        _screenState = ScreenState.input;
      });
    }
  }

  /// ゲーム画面に遷移
  void _navigateToGame(DuelRoom room) {
    if (!mounted) return;

    _roomSubscription?.cancel();

    // room.modeを文字列からGameModeに変換
    GameMode gameMode;
    switch (room.mode.toUpperCase()) {
      case 'WESTERN':
        gameMode = GameMode.western;
        break;
      case 'BOXING':
        gameMode = GameMode.boxing;
        break;
      case 'WIZARD':
        gameMode = GameMode.wizard;
        break;
      case 'SAMURAI':
        gameMode = GameMode.samurai;
        break;
      default:
        gameMode = GameMode.western; // デフォルト
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DuelGameScreen(
          roomId: _roomId!,
          isHost: false,
          mode: gameMode,
        ),
      ),
    );
  }

  /// エラーメッセージ表示
  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// 退出（待機中キャンセル）
  Future<void> _leaveRoom() async {
    _audioService.playUISelect();

    if (_roomId != null && _screenState == ScreenState.waiting) {
      try {
        await _duelService.leaveRoom(_roomId!);
      } catch (e) {
        debugPrint('退出エラー: $e');
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_screenState) {
      case ScreenState.input:
        return _buildInputScreen();
      case ScreenState.joining:
        return _buildJoiningScreen();
      case ScreenState.waiting:
        return _buildWaitingScreen();
    }
  }

  /// 入力画面（QR読み取り or 手入力）
  Widget _buildInputScreen() {
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
          child: Column(
            children: [
              // ヘッダー
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Color(0xFF3D2E1F), size: 28),
                      onPressed: () {
                        _audioService.playUISelect();
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: Text(
                        'JOIN - 部屋に入る',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D2E1F),
                          fontFamily: 'serif',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // バランス用
                  ],
                ),
              ),

              // 切り替えタブ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        label: 'QR読み取り',
                        isSelected: !_isManualInput,
                        onTap: () {
                          _audioService.playUISelect();
                          setState(() {
                            _isManualInput = false;
                            _errorMessage = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTabButton(
                        label: '手入力',
                        isSelected: _isManualInput,
                        onTap: () {
                          _audioService.playUISelect();
                          setState(() {
                            _isManualInput = true;
                            _errorMessage = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // コンテンツ
              Expanded(
                child: _isManualInput ? _buildManualInputContent() : _buildQRScannerContent(),
              ),

              // エラーメッセージ
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.shade900,
                              fontFamily: 'serif',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// タブボタン
  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF3D2E1F) : Color(0xFFE6D4BC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(0xFF8B6F47),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Color(0xFFE6D4BC) : Color(0xFF3D2E1F),
            fontFamily: 'serif',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// QRスキャナーコンテンツ
  Widget _buildQRScannerContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'QRコードをカメラで読み取ってください',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF3D2E1F),
              fontFamily: 'serif',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF8B6F47), width: 3),
              ),
              clipBehavior: Clip.antiAlias,
              child: MobileScanner(
                onDetect: _onQRDetected,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 手入力コンテンツ
  Widget _buildManualInputContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            '6桁の部屋番号を入力してください',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF3D2E1F),
              fontFamily: 'serif',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFF8B6F47), width: 2),
            ),
            child: TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: '例: A7K3D9',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'monospace',
                ),
              ),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  return newValue.copyWith(text: newValue.text.toUpperCase());
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _joinByManualInput,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3D2E1F),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '参加する',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE6D4BC),
                  fontFamily: 'serif',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 参加処理中画面
  Widget _buildJoiningScreen() {
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
                  '部屋に参加中...',
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

  /// 待機画面（ゲーム開始待ち）
  Widget _buildWaitingScreen() {
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 参加成功アイコン
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    '参加成功！',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D2E1F),
                      fontFamily: 'serif',
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'ホストがゲームを開始するまでお待ちください',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5C4A3A),
                      fontFamily: 'serif',
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // ローディングインジケーター
                  CircularProgressIndicator(color: Color(0xFF3D2E1F)),

                  const SizedBox(height: 48),

                  // 退出ボタン
                  OutlinedButton(
                    onPressed: _leaveRoom,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      side: BorderSide(color: Color(0xFF8B6F47), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '退出',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
}
