import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import 'result_screen.dart';

class WizardScreen extends StatefulWidget {
  const WizardScreen({super.key});

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  bool _isWaiting = false;
  bool _hasSignal = false;
  bool _isFalseStart = false;
  DateTime? _signalTime;
  int _currentStep = 1; // 現在タップすべき数字（1-5）
  Timer? _signalTimer;
  final Random _random = Random();
  
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
    final radius = 0.28;

    _starPositions = List.generate(5, (i) {
      // 五芒星: 上から開始、72度ずつ回転
      final angle = -pi / 2 + (2 * pi * i / 5);
      return Offset(
        centerX + radius * cos(angle),
        centerY + radius * sin(angle),
      );
    });
  }

  // 【重要】数字と座標をペアリングしてシャッフル
  void _createNumberPositionPairs() {
    // まず座標リストをシャッフル（これが重要！）
    final shuffledPositions = List<Offset>.from(_starPositions);
    shuffledPositions.shuffle(_random);
    
    // 数字（1-5）は固定順序で、シャッフルされた座標に配置
    _numberPositionPairs = List.generate(5, (i) {
      return {
        'number': i + 1,
        'position': shuffledPositions[i],
      };
    });
    
    if (kDebugMode) {
      print('=== Wizard Screen: 数字配置をシャッフルしました ===');
      for (var pair in _numberPositionPairs) {
        final pos = pair['position'] as Offset;
        print('  数字${pair['number']}: (${pos.dx.toStringAsFixed(2)}, ${pos.dy.toStringAsFixed(2)})');
      }
    }
  }

  void _startWaiting() {
    // 【重要】ゲーム開始時に毎回シャッフル
    _createNumberPositionPairs();
    
    setState(() {
      _isWaiting = true;
      _hasSignal = false;
      _isFalseStart = false;
      _signalTime = null;
      _currentStep = 1;
    });

    final delayMs = 2000 + _random.nextInt(3000);
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
      setState(() {
        _currentStep++;
      });

      // 全て完了
      if (_currentStep > 5 && _signalTime != null) {
        final completionTimeMs = DateTime.now().difference(_signalTime!).inMilliseconds;
        Future.delayed(const Duration(milliseconds: 300), () {
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ResultScreen()),
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
              Color(0xFF4B0082).withOpacity(0.8),
              Color(0xFF2E0854),
              Color(0xFF1A0033),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white70, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isFalseStart ? 'FALSE START!' : (_isWaiting ? (_hasSignal ? '1→2→3→4→5の順にタップ!' : '合図を待て...') : 'WIZARD'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
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
  }

  // 【重要】ランダム配置された数字ボタンを生成
  List<Widget> _buildNumberButtons() {
    return _numberPositionPairs.map((pair) {
      final number = pair['number'] as int;
      final position = pair['position'] as Offset;
      final bool isNext = number == _currentStep;
      final bool isCompleted = number < _currentStep;

      return Positioned(
        left: position.dx * 300 - 25,
        top: position.dy * 300 - 25,
        child: GestureDetector(
          onTap: () => _onNumberPress(number),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted 
                  ? Colors.green.withOpacity(0.6)
                  : (isNext && _hasSignal ? Colors.amber : Colors.purple.shade300),
              border: Border.all(
                color: Colors.white,
                width: isNext && _hasSignal ? 3 : 2,
              ),
              boxShadow: isNext && _hasSignal ? [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.6),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ] : [],
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
      ..color = Colors.purple.shade700.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

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

    // 五芒星を描画（頂点を線で結ぶ: 0→2→4→1→3→0）
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    path.lineTo(points[2].dx, points[2].dy);
    path.lineTo(points[4].dx, points[4].dy);
    path.lineTo(points[1].dx, points[1].dy);
    path.lineTo(points[3].dx, points[3].dy);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// デバッグモード判定
bool get kDebugMode {
  bool debugMode = false;
  assert(() {
    debugMode = true;
    return true;
  }());
  return debugMode;
}
