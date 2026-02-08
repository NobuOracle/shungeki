import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import 'result_screen.dart';

class SamuraiScreen extends StatefulWidget {
  const SamuraiScreen({super.key});

  @override
  State<SamuraiScreen> createState() => _SamuraiScreenState();
}

class _SamuraiScreenState extends State<SamuraiScreen> {
  bool _isWaiting = false;
  bool _hasSignal = false;
  bool _isFalseStart = false;
  DateTime? _signalTime;
  double _sliderValue = 0.0;
  Timer? _signalTimer;
  final Random _random = Random();
  final double safeZone = 0.25;

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
    setState(() {
      _isWaiting = true;
      _hasSignal = false;
      _isFalseStart = false;
      _signalTime = null;
      _sliderValue = 0.0;
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

  void _onSliderChange(double value) {
    if (!_isWaiting) return;
    
    setState(() {
      _sliderValue = value;
    });

    // お手付きチェック（合図前にセーフゾーン超過）
    if (!_hasSignal && _sliderValue > safeZone && !_isFalseStart) {
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

    // 完了チェック（合図後に98%到達）
    if (_hasSignal && _sliderValue >= 0.98 && _signalTime != null) {
      final completionTimeMs = DateTime.now().difference(_signalTime!).inMilliseconds;
      _showResult(isFalseStart: false, reactionTimeMs: completionTimeMs);
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
              Color(0xFF8B0000),
              Color(0xFF5C0000),
              Color(0xFF3D0000),
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
                            border: Border.all(color: Color(0xFF8B0000), width: 2),
                          ),
                          child: Text(
                            _isFalseStart 
                                ? 'FALSE START!' 
                                : (_hasSignal ? '抜刀!' : 'WAIT'),
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
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 説明テキスト
                        if (_isWaiting && !_hasSignal && !_isFalseStart)
                          Text(
                            '合図を待て... (25% SAFE)',
                            style: TextStyle(
                              fontSize: 20,
                              color: Color(0xFFE6D4BC),
                              letterSpacing: 2,
                              fontFamily: 'serif',
                            ),
                          ),

                        const SizedBox(height: 40),

                        // 縦置きスライダー
                        _buildVerticalSlider(),
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

  // 縦置きスライダー
  Widget _buildVerticalSlider() {
    return Container(
      width: 100,
      height: 400,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF3D2E1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF8B6F47),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 鞘（背景）
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF2E1F1F),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          // セーフゾーン表示（合図前のみ）
          if (!_hasSignal && !_isFalseStart)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 400 * safeZone,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ),
            ),
          
          // 日本刀（進捗表示）
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 400 * _sliderValue,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _isFalseStart
                      ? [Colors.red.shade900, Colors.red.shade700]
                      : (_hasSignal
                          ? [Color(0xFFE8E8E8), Color(0xFFC0C0C0)]
                          : [Colors.green.shade700, Colors.green.shade500]),
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: _hasSignal 
                        ? Colors.white.withValues(alpha: 0.5) 
                        : Colors.black.withValues(alpha: 0.3),
                    blurRadius: _hasSignal ? 15 : 5,
                    spreadRadius: _hasSignal ? 3 : 0,
                  ),
                ],
              ),
            ),
          ),
          
          // タッチエリア
          Positioned.fill(
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                // 上から下へのドラッグを検出
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                
                // Y座標から進捗を計算（上が0、下が1）
                final progress = (localPosition.dy / 400).clamp(0.0, 1.0);
                _onSliderChange(progress);
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          
          // 進捗パーセント表示
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${(_sliderValue * 100).round()}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _sliderValue > 0.5 
                      ? Color(0xFF3D2E1F) 
                      : Color(0xFFE6D4BC),
                  fontFamily: 'serif',
                  shadows: [
                    Shadow(
                      color: _sliderValue > 0.5 
                          ? Colors.white.withValues(alpha: 0.8) 
                          : Colors.black.withValues(alpha: 0.8),
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
