import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../services/audio_service.dart';
import '../utils/event_plan_generator.dart';
import '../widgets/layered_mode_background.dart';
import 'result_screen.dart';

// パンチの種類を定義
enum PunchType {
  leftJab,
  rightJab,
  leftStraight,
  rightStraight,
  leftHook,
  rightHook,
  leftUppercut,
  rightUppercut,
  leftBodyShot,
  rightBodyShot,
}

// パンチタイプの表示名を取得（2行表示用）
String getPunchLabel(PunchType type) {
  switch (type) {
    case PunchType.leftJab:
      return 'Left\nJab';
    case PunchType.rightJab:
      return 'Right\nJab';
    case PunchType.leftStraight:
      return 'Left\nStraight';
    case PunchType.rightStraight:
      return 'Right\nStraight';
    case PunchType.leftHook:
      return 'Left\nHook';
    case PunchType.rightHook:
      return 'Right\nHook';
    case PunchType.leftUppercut:
      return 'Left\nUppercut';
    case PunchType.rightUppercut:
      return 'Right\nUppercut';
    case PunchType.leftBodyShot:
      return 'Left\nBody Shot';
    case PunchType.rightBodyShot:
      return 'Right\nBody Shot';
  }
}

class BoxingScreen extends StatefulWidget {
  final Map<String, dynamic>? eventPlan;

  const BoxingScreen({super.key, this.eventPlan});

  @override
  State<BoxingScreen> createState() => _BoxingScreenState();
}

class _BoxingScreenState extends State<BoxingScreen> {
  bool _isWaiting = false;
  bool _hasSignal = false;
  bool _isFalseStart = false;
  bool _isKnockout = false; // 3回目のShot後の状態
  DateTime? _signalTime;
  Timer? _signalTimer;
  final AudioService _audioService = AudioService();

  // 3回連続早押し用の変数
  int _currentRound = 0; // 0: 未開始, 1: 第1ラウンド, 2: 第2ラウンド, 3: 第3ラウンド
  final List<int> _reactionTimes = []; // 各ラウンドの反応時間を記録
  PunchType? _correctPunch; // 現在の正解パンチ

  // eventPlanデータ
  List<Map<String, dynamic>>? _rounds;

  @override
  void initState() {
    super.initState();

    // eventPlanの初期化
    if (widget.eventPlan != null) {
      _rounds = List<Map<String, dynamic>>.from(
        widget.eventPlan!['rounds'] as List,
      );
    } else {
      // ローカル生成（1人モード）
      final seed = DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
      final localEventPlan = EventPlanGenerator.generateBoxing(seed);
      _rounds = List<Map<String, dynamic>>.from(
        localEventPlan['rounds'] as List,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioService.playBoxingReady(); // Boxing Ready SE
      _startNewRound();
    });
  }

  @override
  void dispose() {
    _signalTimer?.cancel();
    super.dispose();
  }

  // 新しいラウンドを開始
  void _startNewRound() {
    _currentRound++;

    // eventPlanからボタンと遅延を取得
    final roundData = _rounds![_currentRound - 1];
    final buttonIndex = roundData['buttonIndex'] as int;
    final delayMs = roundData['delayMs'] as int;

    // ボタンインデックスからPunchTypeを決定
    final allPunches = PunchType.values;
    _correctPunch = allPunches[buttonIndex];

    setState(() {
      _isWaiting = true;
      _hasSignal = false;
      _isFalseStart = false;
      _signalTime = null;
    });

    // eventPlanの遅延時間でシグナルを出す
    _signalTimer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted && _isWaiting) {
        setState(() {
          _hasSignal = true;
          _signalTime = DateTime.now();
        });
      }
    });
  }

  // ボタンが押された時の処理
  void _onPunchButtonPress(PunchType punch) {
    if (_isFalseStart) return;
    if (!_isWaiting) return;

    // 3回目のみFinal Shot SEを再生
    if (_currentRound >= 3 && punch == _correctPunch && _hasSignal) {
      _audioService.playBoxingFinalShot(); // Boxing Final Shot SE
    } else {
      _audioService.playBoxingShot(); // Boxing Shot SE
    }

    // 合図前にボタンを押した場合（フライング）
    if (!_hasSignal) {
      setState(() {
        _isFalseStart = true;
      });
      _signalTimer?.cancel();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showResult(isFalseStart: true);
        }
      });
      return;
    }

    // 合図後 - 正しいボタンが押されたか確認
    if (punch == _correctPunch && _signalTime != null) {
      final reactionTimeMs = DateTime.now()
          .difference(_signalTime!)
          .inMilliseconds;

      // 反応時間を記録
      _reactionTimes.add(reactionTimeMs);

      // 3回連続の判定
      if (_currentRound >= 3) {
        // 3回目のShot SE再生と同時に背景切り替え
        setState(() {
          _isKnockout = true;
        });

        // 2秒後にリザルト画面へ遷移
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _showResult(isFalseStart: false);
          }
        });
      } else {
        // 次のラウンドへ
        _signalTimer?.cancel();
        setState(() {
          _isWaiting = false;
        });

        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _startNewRound();
          }
        });
      }
    }
    // 間違ったボタンを押した場合は何もしない（押し続けることができる）
  }

  void _showResult({required bool isFalseStart}) {
    final gameState = Provider.of<GameStateProvider>(context, listen: false);

    if (isFalseStart) {
      gameState.setResult(reactionTimeMs: null, isWin: false);
    } else {
      // 3回の合計時間を計算
      final totalTime = _reactionTimes.reduce((a, b) => a + b);
      gameState.setBoxingResult(
        round1Time: _reactionTimes[0],
        round2Time: _reactionTimes[1],
        round3Time: _reactionTimes[2],
        totalTime: totalTime,
      );
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ResultScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ 重要: buildメソッドの閉じ括弧 } は編集しないこと！

    // 手前背景（Enemy）の状態判定
    String frontAsset;
    if (_isKnockout) {
      frontAsset = 'assets/upload_files/upload_files/BoxingModeEnemyDead.png';
    } else {
      frontAsset = 'assets/upload_files/upload_files/BoxingModeEnemy.png';
    }

    return Scaffold(
      body: LayeredModeBackground(
        backAsset: 'assets/upload_files/upload_files/BoxingModeBack.png',
        frontAsset: frontAsset,
        overlay: Container(
          // 半透明の赤いオーバーレイ
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFDC143C).withValues(alpha: 0.3),
                Color(0xFF8B0000).withValues(alpha: 0.5),
                Color(0xFF5C0000).withValues(alpha: 0.6),
              ],
            ),
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 閉じるボタン
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // メインコンテンツ
              Column(
                children: [
                  const SizedBox(height: 80), // 上部マージン
                  // 状態表示（上部に配置）
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isFalseStart ? Colors.red : Color(0xFFDC143C),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      _isFalseStart
                          ? 'FALSE START!'
                          : (_hasSignal ? 'HIT NOW!' : 'WAIT...'),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _isFalseStart
                            ? Colors.red.shade300
                            : Colors.white,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            offset: Offset(2, 2),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 10個のパンチボタン（ジグザグ配置）
                  Expanded(child: Center(child: _buildPunchButtons())),

                  // ラウンド表示（下部に配置）
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFDC143C), width: 2),
                      ),
                      child: Text(
                        'ROUND $_currentRound / 3',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    // ⚠️ この下の } がbuildメソッドの終わり。編集不可！
  }

  // 10個のパンチボタンを生成（ジグザグ配置）
  Widget _buildPunchButtons() {
    return Container(
      constraints: BoxConstraints(maxWidth: 500),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left側のパンチ（5つ、ジグザグ）
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircularPunchButton(PunchType.leftJab, offset: 0),
                _buildCircularPunchButton(PunchType.leftStraight, offset: 40),
                _buildCircularPunchButton(PunchType.leftHook, offset: 0),
                _buildCircularPunchButton(PunchType.leftUppercut, offset: 40),
                _buildCircularPunchButton(PunchType.leftBodyShot, offset: 0),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // Right側のパンチ（5つ、ジグザグ）
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircularPunchButton(PunchType.rightJab, offset: 40),
                _buildCircularPunchButton(PunchType.rightStraight, offset: 0),
                _buildCircularPunchButton(PunchType.rightHook, offset: 40),
                _buildCircularPunchButton(PunchType.rightUppercut, offset: 0),
                _buildCircularPunchButton(PunchType.rightBodyShot, offset: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 円形のパンチボタン（ジグザグ用のオフセット付き）
  Widget _buildCircularPunchButton(PunchType punch, {double offset = 0}) {
    final bool isCorrect = punch == _correctPunch;
    final bool shouldHighlight = _hasSignal && isCorrect && !_isFalseStart;

    return Padding(
      padding: EdgeInsets.only(left: offset, bottom: 10),
      child: GestureDetector(
        onTapDown: (_) => _onPunchButtonPress(punch),
        child: Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: shouldHighlight
                  ? [Color(0xFFFFD700), Color(0xFFFFA500)] // ゴールド
                  : [Color(0xFF2C2C2C), Color(0xFF1A1A1A)], // ダークグレー
            ),
            boxShadow: [
              BoxShadow(
                color: shouldHighlight
                    ? Color(0xFFFFD700).withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.5),
                blurRadius: shouldHighlight ? 20 : 8,
                offset: Offset(0, 4),
                spreadRadius: shouldHighlight ? 4 : 0,
              ),
            ],
            border: Border.all(
              color: shouldHighlight ? Color(0xFFFFD700) : Color(0xFF444444),
              width: shouldHighlight ? 3 : 2,
            ),
          ),
          child: Center(
            child: Text(
              getPunchLabel(punch),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: shouldHighlight ? Colors.black : Colors.white,
                letterSpacing: 0,
                height: 1.2,
                shadows: shouldHighlight
                    ? []
                    : [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
