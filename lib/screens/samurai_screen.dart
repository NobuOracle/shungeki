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
  double _sliderValue = 0.0; // 0.0（下）から 1.0（上）
  Timer? _signalTimer;
  final Random _random = Random();
  
  // セーフゾーン設定
  final double _visibleSafeZone = 0.20; // ユーザーに見せる緑のエリア（20%）
  final double _actualSafeZone = 0.25;  // 実際のセーフエリア（25%、バッファ含む）

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

  void _onSliderChange(double newValue) {
    if (!_isWaiting) return;
    if (_isFalseStart) return;
    
    setState(() {
      _sliderValue = newValue.clamp(0.0, 1.0);
    });

    // お手付きチェック（合図前にセーフゾーン超過）
    if (!_hasSignal && _sliderValue > _actualSafeZone) {
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

    // 完了チェック（合図後に98%以上到達）
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
          // サムライ背景画像を使用
          image: DecorationImage(
            image: AssetImage('assets/images/samurai_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          // 半透明の赤いオーバーレイ
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF8B0000).withValues(alpha: 0.3),
                Color(0xFF5C0000).withValues(alpha: 0.5),
                Color(0xFF3D0000).withValues(alpha: 0.6),
              ],
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
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // タイトル
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
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
                            color: _isFalseStart ? Colors.red.shade300 : Colors.white,
                            letterSpacing: 3,
                            fontFamily: 'serif',
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.8),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '合図を待て... (20% SAFE)',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              letterSpacing: 2,
                              fontFamily: 'serif',
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),

                      // 傾斜スライダー（15度左に傾ける - 左下から右上へ）
                      Transform.rotate(
                        angle: 15 * pi / 180, // 左に15度傾ける（時計回り）
                        child: _buildVerticalSlider(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 縦置きスライダー
  Widget _buildVerticalSlider() {
    const double sliderHeight = 400.0;
    const double sliderWidth = 100.0;
    
    return SizedBox(
      width: sliderWidth,
      height: sliderHeight,
      child: Container(
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
        child: GestureDetector(
          // 縦方向のドラッグを検出
          onVerticalDragStart: (details) {
            _updateSliderFromPosition(details.localPosition.dy, sliderHeight - 24);
          },
          onVerticalDragUpdate: (details) {
            _updateSliderFromPosition(details.localPosition.dy, sliderHeight - 24);
          },
          child: Stack(
            children: [
              // 鞘（背景トラック）
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF2E1F1F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              
              // セーフゾーン表示（20%、合図前のみ）
              if (!_hasSignal && !_isFalseStart)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: (sliderHeight - 24) * _visibleSafeZone,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                      border: Border(
                        top: BorderSide(
                          color: Colors.green.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              
              // 日本刀（進捗バー）- 下から上に伸びる
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: (sliderHeight - 24) * _sliderValue,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: _isFalseStart
                          ? [Colors.red.shade900, Colors.red.shade700]
                          : (_hasSignal
                              ? [Color(0xFFC0C0C0), Color(0xFFE8E8E8)]
                              : [Colors.green.shade700, Colors.green.shade500]),
                    ),
                    borderRadius: _sliderValue < 0.98
                        ? BorderRadius.vertical(bottom: Radius.circular(8))
                        : BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _hasSignal 
                            ? Colors.white.withValues(alpha: 0.6) 
                            : Colors.black.withValues(alpha: 0.3),
                        blurRadius: _hasSignal ? 15 : 5,
                        spreadRadius: _hasSignal ? 3 : 0,
                      ),
                    ],
                  ),
                ),
              ),
              
              // 進捗パーセント表示
              Positioned(
                top: 8,
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
        ),
      ),
    );
  }

  // タッチ位置からスライダー値を更新
  void _updateSliderFromPosition(double localY, double trackHeight) {
    // Y座標を0.0（上）から1.0（下）に正規化
    final normalizedY = (localY / trackHeight).clamp(0.0, 1.0);
    
    // スライダー値は下から上なので反転（0.0=下、1.0=上）
    final newValue = 1.0 - normalizedY;
    
    _onSliderChange(newValue);
  }
}
