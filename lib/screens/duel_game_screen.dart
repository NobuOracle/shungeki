import 'dart:async';
import 'package:flutter/material.dart';
import '../models/duel_room.dart';
import '../providers/game_state_provider.dart';
import '../services/audio_service.dart';
import '../services/duel_service.dart';
import 'western_screen.dart';
import 'boxing_screen.dart';
import 'wizard_screen.dart';
import 'samurai_screen.dart';
import 'duel_result_screen.dart';

/// ゲーム状態
enum GameState {
  countdown,  // 3秒カウントダウン中
  playing,    // ゲーム中（ダミー）
  finished,   // 終了、結果送信済み
}

/// 2人対戦ゲーム画面（最小実装）
/// 
/// 実際のゲームロジックは次ステップで統合
/// 現時点では3秒カウントダウン → ダミーゲーム → 結果送信のフロー
class DuelGameScreen extends StatefulWidget {
  final String roomId;
  final bool isHost;
  final GameMode mode;

  const DuelGameScreen({
    super.key,
    required this.roomId,
    required this.isHost,
    required this.mode,
  });

  @override
  State<DuelGameScreen> createState() => _DuelGameScreenState();
}

class _DuelGameScreenState extends State<DuelGameScreen> {
  final DuelService _duelService = DuelService();
  final AudioService _audioService = AudioService();

  StreamSubscription<DuelRoom>? _roomSubscription;
  DuelRoom? _currentRoom;

  GameState _gameState = GameState.countdown;
  int _countdown = 3;
  bool _hasSubmittedResult = false;

  @override
  void initState() {
    super.initState();
    _subscribeRoom();
    _startCountdown();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }

  /// 部屋を購読（seed/status確認）
  void _subscribeRoom() {
    _roomSubscription = _duelService.watchRoom(widget.roomId).listen(
      (room) {
        setState(() {
          _currentRoom = room;
        });

        // 両方の結果が揃ったらリザルト画面へ
        if (_hasSubmittedResult && room.hasBothResults) {
          _navigateToResult();
        }
      },
      onError: (error) {
        debugPrint('Room購読エラー: $error');
      },
    );
  }

  /// 3秒カウントダウン
  void _startCountdown() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        timer.cancel();
        setState(() {
          _gameState = GameState.playing;
        });
        // カウントダウン終了後、実際のゲーム画面へ遷移
        _navigateToGameMode();
      }
    });
  }

  /// 実際のゲームモード画面へ遷移
  void _navigateToGameMode() {
    if (_currentRoom == null || _currentRoom!.eventPlan == null) {
      debugPrint('⚠️ eventPlanがまだ利用できません。待機中...');
      return;
    }

    final eventPlan = _currentRoom!.eventPlan!;
    Widget gameScreen;

    switch (widget.mode) {
      case GameMode.western:
        gameScreen = WesternScreen(eventPlan: eventPlan);
        break;
      case GameMode.boxing:
        gameScreen = BoxingScreen(eventPlan: eventPlan);
        break;
      case GameMode.wizard:
        gameScreen = WizardScreen(eventPlan: eventPlan);
        break;
      case GameMode.samurai:
        gameScreen = SamuraiScreen(eventPlan: eventPlan);
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => gameScreen),
    );
  }
  Future<void> _finishDummyGame() async {
    _audioService.playUISelect();

    // ダミー結果（実際は反応時間を計測）
    final dummyReactionMs = 500 + (widget.isHost ? 100 : 200);
    final dummyFoul = false;

    try {
      await _duelService.submitResult(
        roomId: widget.roomId,
        isHost: widget.isHost,
        reactionMs: dummyReactionMs,
        foul: dummyFoul,
      );

      setState(() {
        _hasSubmittedResult = true;
        _gameState = GameState.finished;
      });

      // 相手の結果待ち（watchRoomで検知）
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('結果送信エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// リザルト画面へ遷移
  void _navigateToResult() {
    if (!mounted) return;

    _roomSubscription?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DuelResultScreen(
          roomId: widget.roomId,
          isHost: widget.isHost,
          room: _currentRoom!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_gameState) {
      case GameState.countdown:
        return _buildCountdown();
      case GameState.playing:
        return _buildDummyGame();
      case GameState.finished:
        return _buildWaitingForOpponent();
    }
  }

  /// カウントダウン表示
  Widget _buildCountdown() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _getModeString(),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3D2E1F),
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 48),
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Color(0xFF3D2E1F),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$_countdown',
              style: TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE6D4BC),
                fontFamily: 'serif',
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '準備してください！',
          style: TextStyle(
            fontSize: 20,
            color: Color(0xFF3D2E1F),
            fontFamily: 'serif',
          ),
        ),
      ],
    );
  }

  /// ダミーゲーム表示（実際は各モードのゲーム画面）
  Widget _buildDummyGame() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ゲーム中',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3D2E1F),
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'seed: ${_currentRoom?.seed ?? 0}',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF5C4A3A),
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 48),
          Text(
            '【ダミー実装】',
            style: TextStyle(
              fontSize: 20,
              color: Colors.red,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '実際のゲームロジックは次ステップで統合します',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF5C4A3A),
              fontFamily: 'serif',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _finishDummyGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3D2E1F),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(
              'ゲーム終了（ダミー）',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFFE6D4BC),
                fontFamily: 'serif',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 相手の結果待ち
  Widget _buildWaitingForOpponent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Color(0xFF3D2E1F)),
        const SizedBox(height: 24),
        Text(
          '相手の結果を待っています...',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF3D2E1F),
            fontFamily: 'serif',
          ),
        ),
      ],
    );
  }

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
}
