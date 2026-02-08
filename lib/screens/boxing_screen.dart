import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import 'result_screen.dart';

class BoxingScreen extends StatefulWidget {
  const BoxingScreen({super.key});

  @override
  State<BoxingScreen> createState() => _BoxingScreenState();
}

class _BoxingScreenState extends State<BoxingScreen> {
  bool _isWaiting = false;
  bool _hasSignal = false;
  bool _isFalseStart = false;
  DateTime? _signalTime;
  Timer? _signalTimer;
  final Random _random = Random();
  String _correctButton = 'left'; // 'left' or 'right'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startWaiting();
    });
  }

  @override
  void dispose() {
    _signalTimer?.cancel();
    super.dispose();
  }

  void _startWaiting() {
    // ランダムに正解ボタンを決定
    setState(() {
      _correctButton = _random.nextBool() ? 'left' : 'right';
      _isWaiting = true;
      _hasSignal = false;
      _isFalseStart = false;
      _signalTime = null;
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

  void _onButtonPress(String button) {
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

    // 合図後
    if (button == _correctButton && _signalTime != null) {
      final reactionTimeMs = DateTime.now().difference(_signalTime!).inMilliseconds;
      _showResult(isFalseStart: false, reactionTimeMs: reactionTimeMs);
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
              Color(0xFFDC143C),
              Color(0xFF8B0000),
              Color(0xFF5C0000),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ヴィンテージ紙テクスチャ
            Positioned.fill(
              child: CustomPaint(
                painter: _VintagePaperPainter(),
              ),
            ),
            
            SafeArea(
              child: Stack(
                children: [
                  // 閉じるボタン
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Color(0xFFE6D4BC), size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // メインコンテンツ
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // タイトル
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          decoration: BoxDecoration(
                            color: Color(0xFF3D2E1F).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFFDC143C), width: 2),
                          ),
                          child: Text(
                            _isFalseStart ? 'FALSE START!' : (_hasSignal ? '正しい拳を撃て!' : 'WAIT'),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: _isFalseStart ? Colors.red.shade300 : Color(0xFFE6D4BC),
                              letterSpacing: 3,
                              fontFamily: 'serif',
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  offset: Offset(3, 3),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 60),

                        // 説明テキスト
                        if (_isWaiting && !_hasSignal && !_isFalseStart)
                          Text(
                            '合図を待て...',
                            style: TextStyle(
                              fontSize: 20,
                              color: Color(0xFFE6D4BC),
                              letterSpacing: 2,
                              fontFamily: 'serif',
                            ),
                          ),

                        const SizedBox(height: 40),

                        // 左右ボタン
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildBoxingButton('left', 'LEFT'),
                            const SizedBox(width: 60),
                            _buildBoxingButton('right', 'RIGHT'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoxingButton(String button, String label) {
    final bool isCorrect = button == _correctButton;
    final bool shouldHighlight = _hasSignal && isCorrect && !_isFalseStart;

    return GestureDetector(
      onTap: () => _onButtonPress(button),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: shouldHighlight
                ? [Color(0xFFE6D4BC), Color(0xFFD8C9B4)]
                : [Color(0xFF5C4A3A), Color(0xFF3D2E1F)],
          ),
          boxShadow: [
            BoxShadow(
              color: shouldHighlight 
                  ? Color(0xFFDC143C).withValues(alpha: 0.6) 
                  : Colors.black.withValues(alpha: 0.5),
              blurRadius: shouldHighlight ? 30 : 20,
              offset: Offset(0, 8),
              spreadRadius: shouldHighlight ? 8 : 0,
            ),
          ],
          border: Border.all(
            color: shouldHighlight ? Color(0xFFDC143C) : Color(0xFF8B6F47),
            width: shouldHighlight ? 4 : 3,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: shouldHighlight ? Color(0xFF3D2E1F) : Color(0xFFE6D4BC),
              letterSpacing: 2,
              fontFamily: 'serif',
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: Offset(2, 2),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ヴィンテージ紙テクスチャペインター
class _VintagePaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = Random(42);
    
    // 紙の繊維テクスチャ
    for (var i = 0; i < 80; i++) {
      paint.color = Color(0xFFE6D4BC).withValues(alpha: 0.03);
      final x = size.width * random.nextDouble();
      final y = size.height * random.nextDouble();
      canvas.drawCircle(Offset(x, y), 1.5, paint);
    }
    
    // 埃・シミ
    for (var i = 0; i < 25; i++) {
      paint.color = Color(0xFFE6D4BC).withValues(alpha: 0.05);
      final x = size.width * random.nextDouble();
      final y = size.height * random.nextDouble();
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
