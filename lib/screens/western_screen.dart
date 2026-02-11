import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../services/audio_service.dart';
import '../utils/event_plan_generator.dart';
import 'result_screen.dart';

class WesternScreen extends StatefulWidget {
  final Map<String, dynamic>? eventPlan;
  
  const WesternScreen({super.key, this.eventPlan});

  @override
  State<WesternScreen> createState() => _WesternScreenState();
}

class _WesternScreenState extends State<WesternScreen> with TickerProviderStateMixin {
  bool _isWaiting = false;
  bool _hasSignal = false;
  bool _isFalseStart = false;
  bool _isShot = false; // Shot後の状態
  DateTime? _signalTime;
  Timer? _signalTimer;
  final AudioService _audioService = AudioService();
  
  // コイン回転アニメーション
  late AnimationController _coinController;
  late Animation<double> _coinRotation;

  @override
  void initState() {
    super.initState();
    
    // コイン回転アニメーション初期化
    _coinController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _coinRotation = Tween<double>(begin: 0, end: 2 * pi).animate(_coinController);
    _coinController.repeat();
    
    // 画面表示後に自動開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioService.playWesternReady(); // Western Ready SE
      _startWaiting();
    });
  }

  @override
  void dispose() {
    _signalTimer?.cancel();
    _coinController.dispose();
    super.dispose();
  }

  void _startWaiting() {
    setState(() {
      _isWaiting = true;
      _hasSignal = false;
      _isFalseStart = false;
      _signalTime = null;
    });

    // eventPlanがあればそれを使用、なければローカル生成
    int delayMs;
    if (widget.eventPlan != null) {
      // eventPlanからdrawAtMsを取得
      delayMs = widget.eventPlan!['drawAtMs'] as int;
    } else {
      // ローカル生成（1人モード）
      final seed = DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
      final localEventPlan = EventPlanGenerator.generateWestern(seed);
      delayMs = localEventPlan['drawAtMs'] as int;
    }
    
    _signalTimer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted && _isWaiting) {
        setState(() {
          _hasSignal = true;
          _signalTime = DateTime.now();
        });
      }
    });
  }

  void _onShoot() {
    if (_isFalseStart) return;
    if (!_isWaiting) return;

    _audioService.playWesternShot(); // Western Shot SE

    // 合図前にタップ = お手付き
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

    // 合図後にタップ = 成功
    if (_signalTime != null) {
      final reactionTimeMs = DateTime.now().difference(_signalTime!).inMilliseconds;
      
      // Shot SE再生と同時に背景切り替え
      setState(() {
        _isShot = true;
      });
      
      // 2秒後にリザルト画面へ遷移
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _showResult(isFalseStart: false, reactionTimeMs: reactionTimeMs);
        }
      });
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
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              _isShot 
                ? 'assets/images/WesternModeBackDead.png'
                : 'assets/images/WesternModeBack.png'
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // 木目テクスチャオーバーレイ
            Positioned.fill(
              child: CustomPaint(
                painter: _WoodGrainPainter(),
              ),
            ),
            
            // 装飾星（4隅）
            ..._buildCornerStars(),
            
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
                            border: Border.all(color: Color(0xFF8B6F47), width: 2),
                          ),
                          child: Text(
                            _isFalseStart ? 'FALSE START!' : (_hasSignal ? 'DRAW!' : 'WAIT'),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: _isFalseStart ? Colors.red.shade300 : Color(0xFFE6D4BC),
                              letterSpacing: 4,
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

                        const SizedBox(height: 60),

                        // 中央エリア（待機中はコイン、合図後は銃アイコン）
                        SizedBox(
                          height: 120,
                          child: _isWaiting && !_hasSignal
                              ? _buildRotatingCoin()
                              : _buildGunIcon(),
                        ),

                        const SizedBox(height: 60),

                        // DRAWボタン
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // ボタン周りの装飾星（8個）
                            ..._buildButtonStars(),
                            
                            // メインボタン
                            GestureDetector(
                              onTap: _onShoot,
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: _isFalseStart
                                        ? [Colors.red.shade900, Colors.red.shade700]
                                        : (_hasSignal 
                                            ? [Color(0xFFE6D4BC), Color(0xFFD8C9B4)]
                                            : [Color(0xFF5C4A3A), Color(0xFF3D2E1F)]),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      blurRadius: 25,
                                      offset: Offset(0, 10),
                                      spreadRadius: 5,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 40,
                                      offset: Offset(0, 15),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Color(0xFF8B6F47),
                                    width: 4,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _isFalseStart
                                        ? 'FAILED'
                                        : (_hasSignal ? 'SHOOT!' : 'WAIT...'),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: _hasSignal && !_isFalseStart 
                                          ? Color(0xFF3D2E1F) 
                                          : Color(0xFFE6D4BC),
                                      letterSpacing: 3,
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
                            ),
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

  // 回転するゴールドコイン（待機中）
  Widget _buildRotatingCoin() {
    return AnimatedBuilder(
      animation: _coinRotation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(_coinRotation.value),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFFFFD700),
                  Color(0xFFFFA500),
                  Color(0xFFDAA520),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.star,
                color: Color(0xFF8B4513),
                size: 40,
              ),
            ),
          ),
        );
      },
    );
  }

  // 銃アイコン（合図後）
  Widget _buildGunIcon() {
    return Icon(
      Icons.gps_fixed,
      size: 80,
      color: Color(0xFFE6D4BC),
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.5),
          offset: Offset(3, 3),
          blurRadius: 5,
        ),
      ],
    );
  }

  // 4隅の装飾星
  List<Widget> _buildCornerStars() {
    return [
      Positioned(top: 40, left: 40, child: _buildStar(30)),
      Positioned(top: 40, right: 40, child: _buildStar(30)),
      Positioned(bottom: 40, left: 40, child: _buildStar(30)),
      Positioned(bottom: 40, right: 40, child: _buildStar(30)),
    ];
  }

  // ボタン周りの装飾星（8個）
  List<Widget> _buildButtonStars() {
    final radius = 140.0;
    return List.generate(8, (i) {
      final angle = (2 * pi * i / 8) - pi / 2;
      final x = radius * cos(angle);
      final y = radius * sin(angle);
      
      return Positioned(
        left: x,
        top: y,
        child: _buildStar(20),
      );
    });
  }

  Widget _buildStar(double size) {
    return Icon(
      Icons.star,
      size: size,
      color: Color(0xFFDAA520).withValues(alpha: 0.6),
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.3),
          offset: Offset(2, 2),
          blurRadius: 3,
        ),
      ],
    );
  }
}

// 木目テクスチャペインター
class _WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF3D2E1F).withValues(alpha: 0.1)
      ..strokeWidth = 1;

    // 水平木目線
    for (var i = 0; i < 30; i++) {
      paint.color = Color(0xFF3D2E1F).withValues(alpha: 0.05 + (i % 3) * 0.02);
      canvas.drawLine(
        Offset(0, size.height * i / 30),
        Offset(size.width, size.height * i / 30),
        paint,
      );
    }

    // ランダムな木目模様
    final random = Random(42);
    for (var i = 0; i < 20; i++) {
      paint.color = Color(0xFF3D2E1F).withValues(alpha: 0.03);
      final y = size.height * random.nextDouble();
      final startX = size.width * random.nextDouble() * 0.3;
      final endX = size.width * (0.7 + random.nextDouble() * 0.3);
      canvas.drawLine(
        Offset(startX, y),
        Offset(endX, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
