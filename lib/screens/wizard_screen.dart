import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../services/audio_service.dart';
import '../utils/event_plan_generator.dart';
import '../widgets/layered_mode_background.dart';
import 'result_screen.dart';

class WizardScreen extends StatefulWidget {
  final Map<String, dynamic>? eventPlan;

  const WizardScreen({super.key, this.eventPlan});

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  bool _isWaiting = false;
  bool _hasSignal = false;
  bool _isFalseStart = false;
  bool _isSpellComplete = false; // 5個目のボタン押下後の状態
  DateTime? _signalTime;
  int _currentStep = 1; // 現在タップすべき数字（1-5）
  Timer? _signalTimer;
  final AudioService _audioService = AudioService();

  // 【重要】五芒星の5つの頂点座標
  List<Offset> _starPositions = [];

  // 【重要】数字と座標のペアリスト
  List<Map<String, dynamic>> _numberPositionPairs = [];

  @override
  void initState() {
    super.initState();
    _calculateStarPositions();
    _createNumberPositionPairs();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioService.playWizardReady(); // Wizard Ready SE
      _startWaiting();
    });
  }

  @override
  void dispose() {
    _signalTimer?.cancel();
    super.dispose();
  }

  // 五芒星の5つの頂点座標を計算
  void _calculateStarPositions() {
    final centerX = 0.5;
    final centerY = 0.45;

    // eventPlanからradiusScaleを取得（なければデフォルト1.0）
    double radiusScale = 1.0;
    if (widget.eventPlan != null) {
      radiusScale = (widget.eventPlan!['radiusScale'] as num).toDouble();
    }

    const baseRadius = 0.28; // 基準半径
    final radius = baseRadius * radiusScale; // スケールを適用

    debugPrint('⭐ [Wizard] _calculateStarPositions:');
    debugPrint('  baseRadius: $baseRadius');
    debugPrint('  radiusScale: $radiusScale');
    debugPrint('  applied radius: $radius');

    _starPositions = List.generate(5, (i) {
      // 五芒星: 上から開始、72度ずつ回転
      final angle = -pi / 2 + (2 * pi * i / 5);
      return Offset(
        centerX + radius * cos(angle),
        centerY + radius * sin(angle),
      );
    });
  }

  // 【重要】数字と座標をペアリング
  void _createNumberPositionPairs() {
    List<int> layout;

    if (widget.eventPlan != null) {
      // eventPlanからlayoutを取得
      layout = List<int>.from(widget.eventPlan!['layout'] as List);
    } else {
      // ローカル生成（1人モード）
      final seed = DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
      final localEventPlan = EventPlanGenerator.generateWizard(seed);
      layout = List<int>.from(localEventPlan['layout'] as List);
    }

    // layoutに従って数字を配置
    debugPrint('🔢 [Wizard] layout: $layout');
    _numberPositionPairs = List.generate(5, (i) {
      return {'number': layout[i], 'position': _starPositions[i]};
    });

    if (kDebugMode) {
      debugPrint('=== Wizard Screen: 数字配置 ===');
      for (var pair in _numberPositionPairs) {
        final pos = pair['position'] as Offset;
        debugPrint(
          '  数字${pair['number']}: (${pos.dx.toStringAsFixed(2)}, ${pos.dy.toStringAsFixed(2)})',
        );
      }
    }
  }

  void _startWaiting() {
    setState(() {
      _isWaiting = true;
      _hasSignal = false;
      _isFalseStart = false;
      _signalTime = null;
      _currentStep = 1;
    });

    // eventPlanからdrawAtMsを取得
    int delayMs;
    if (widget.eventPlan != null) {
      delayMs = widget.eventPlan!['drawAtMs'] as int;
    } else {
      // ローカル生成（1人モード）
      final seed = DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
      final localEventPlan = EventPlanGenerator.generateWizard(seed);
      delayMs = localEventPlan['drawAtMs'] as int;
    }

    debugPrint('⚡ [Wizard] タイミング設定: drawAtMs=$delayMs (${delayMs / 1000}秒)');

    _signalTimer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted && _isWaiting) {
        setState(() {
          _hasSignal = true;
          _signalTime = DateTime.now();
        });
      }
    });
  }

  void _onNumberPress(int number) {
    if (_isFalseStart) return;
    if (!_isWaiting) return;

    // 合図前
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

    // 正しい順序かチェック
    if (number == _currentStep) {
      // 5回目（最後）の押下時のみSEを再生
      if (_currentStep == 5) {
        _audioService.playWizardShot(); // Wizard Shot SE (5回目のみ)
      }

      setState(() {
        _currentStep++;
      });

      // 全て完了
      if (_currentStep > 5 && _signalTime != null) {
        final completionTimeMs = DateTime.now()
            .difference(_signalTime!)
            .inMilliseconds;

        // 5個目のボタン押下と同時に背景切り替え
        setState(() {
          _isSpellComplete = true;
        });

        // 2秒後にリザルト画面へ遷移
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _showResult(isFalseStart: false, reactionTimeMs: completionTimeMs);
          }
        });
      }
    }
  }

  void _showResult({required bool isFalseStart, int? reactionTimeMs}) {
    final gameState = Provider.of<GameStateProvider>(context, listen: false);

    if (isFalseStart) {
      gameState.setResult(reactionTimeMs: null, isWin: false);
    } else {
      gameState.setResult(reactionTimeMs: reactionTimeMs, isWin: true);
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
    if (_isSpellComplete) {
      frontAsset = 'assets/upload_files/upload_files/WizardModeEnemyDead.png';
    } else {
      frontAsset = 'assets/upload_files/upload_files/WizardModeEnemy.png';
    }

    return Scaffold(
      body: LayeredModeBackground(
        backAsset: 'assets/upload_files/upload_files/WizardModeBack.png',
        frontAsset: frontAsset,
        overlay: Container(
          // 半透明の紫色オーバーレイ（薄く調整）
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4B0082).withValues(alpha: 0.2), // 0.4 → 0.2
                Color(0xFF2E0854).withValues(alpha: 0.3), // 0.6 → 0.3
                Color(0xFF1A0033).withValues(alpha: 0.4), // 0.7 → 0.4
              ],
            ),
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // 状態表示
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isFalseStart ? Colors.red : Color(0xFF9370DB),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        _isFalseStart
                            ? 'FALSE START!'
                            : (_isWaiting
                                  ? (_hasSignal ? '1→2→3→4→5の順にタップ!' : '集中せよ……')
                                  : 'WIZARD'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _isFalseStart
                              ? Colors.red.shade300
                              : Colors.white,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // 五芒星とボタン
                    SizedBox(
                      width: 300,
                      height: 300,
                      child: Stack(
                        children: [
                          // 五芒星の線を描画
                          CustomPaint(
                            size: Size(300, 300),
                            painter: _StarPainter(),
                          ),

                          // 数字ボタン（ランダム配置）
                          // 【重要】早押しタイミング前は数字を隠す
                          ..._buildNumberButtons(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // ⚠️ この下の } がbuildメソッドの終わり。編集不可！
  }

  // 【重要】ランダム配置された数字ボタンを生成
  List<Widget> _buildNumberButtons() {
    return _numberPositionPairs.map((pair) {
      final number = pair['number'] as int;
      final position = pair['position'] as Offset;
      final bool isNext = number == _currentStep;
      final bool isCompleted = number < _currentStep;

      // 【新規追加】早押しタイミング前は数字を隠す
      final bool shouldShowNumber = _hasSignal;

      return Positioned(
        left: position.dx * 300 - 25,
        top: position.dy * 300 - 25,
        child: GestureDetector(
          onTapDown: (_) => _onNumberPress(number),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.6)
                  : (isNext && _hasSignal
                        ? Colors.amber
                        : Color(0xFF9370DB).withValues(alpha: 0.8)),
              border: Border.all(
                color: Colors.white,
                width: isNext && _hasSignal ? 3 : 2,
              ),
              boxShadow: isNext && _hasSignal
                  ? [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.8),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: shouldShowNumber
                  ? Text(
                      '$number',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    )
                  : Icon(
                      Icons.help_outline,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 28,
                    ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

// 五芒星描画ペインター
class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF9370DB).withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width * 0.5;
    final centerY = size.height * 0.45;
    final radius = size.width * 0.28;

    // 五芒星の頂点
    final points = List.generate(5, (i) {
      final angle = -pi / 2 + (2 * pi * i / 5);
      return Offset(
        centerX + radius * cos(angle),
        centerY + radius * sin(angle),
      );
    });

    // 五芒星を描画（各頂点を2つ飛ばしで結ぶ）
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (var i = 0; i < 5; i++) {
      final nextIndex = (i * 2) % 5;
      path.lineTo(points[nextIndex].dx, points[nextIndex].dy);
    }
    path.close();

    // 光輝エフェクトのために複数回描画
    canvas.drawPath(path, paint);

    // 内側に光輝を追加
    paint.strokeWidth = 1.5;
    paint.color = Colors.white.withValues(alpha: 0.3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
