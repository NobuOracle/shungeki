import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../services/audio_service.dart';
import '../utils/event_plan_generator.dart';
import '../widgets/layered_mode_background.dart';
import 'result_screen.dart';

class WesternScreen extends StatefulWidget {
  final Map<String, dynamic>? eventPlan;

  const WesternScreen({super.key, this.eventPlan});

  @override
  State<WesternScreen> createState() => _WesternScreenState();
}

class _WesternScreenState extends State<WesternScreen>
    with TickerProviderStateMixin {
  bool _isWaiting = false;
  bool _hasSignal = false;
  bool _isFalseStart = false;
  bool _isShot = false; // Shot後の状態
  DateTime? _signalTime;
  Timer? _signalTimer;
  final AudioService _audioService = AudioService();

  // フェイント関連
  final List<Map<String, dynamic>> _feints = [];
  final List<Timer> _feintTimers = [];
  bool _isFeintActive = false;

  // タンブルウィードアニメーション
  AnimationController? _tumbleweedController;
  Animation<double>? _tumbleweedPosition;

  @override
  void initState() {
    super.initState();

    // 画面表示後に自動開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioService.playWesternReady(); // Western Ready SE
      _startWaiting();
    });
  }

  @override
  void dispose() {
    _signalTimer?.cancel();
    for (final timer in _feintTimers) {
      timer.cancel();
    }
    _tumbleweedController?.dispose();
    super.dispose();
  }

  void _startWaiting() {
    setState(() {
      _isWaiting = true;
      _hasSignal = false;
      _isFalseStart = false;
      _signalTime = null;
      _feints.clear();
      _isFeintActive = false;
    });

    // eventPlanがあればそれを使用、なければローカル生成
    int delayMs;
    List<dynamic> feints = [];

    if (widget.eventPlan != null) {
      // eventPlanからdrawAtMsとfeintsを取得
      delayMs = widget.eventPlan!['drawAtMs'] as int;
      feints = (widget.eventPlan!['feints'] as List?) ?? [];
    } else {
      // ローカル生成（1人モード）
      final seed = DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
      final localEventPlan = EventPlanGenerator.generateWestern(seed);
      delayMs = localEventPlan['drawAtMs'] as int;
      feints = (localEventPlan['feints'] as List?) ?? [];
    }

    // フェイントタイマーをセット
    for (final feint in feints) {
      final atMs = feint['atMs'] as int;
      final durationSec = feint['durationSec'] as double;

      final timer = Timer(Duration(milliseconds: atMs), () {
        if (mounted && _isWaiting && !_hasSignal) {
          _showTumbleweed(durationSec);
        }
      });
      _feintTimers.add(timer);
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

  void _showTumbleweed(double durationSec) {
    setState(() {
      _isFeintActive = true;
    });

    // タンブルウィードアニメーション
    // 画像全体が画面外に出てから消えるように修正
    // width=480px なので、画面幅に対する比率を考慮
    _tumbleweedController = AnimationController(
      duration: Duration(milliseconds: (durationSec * 1000).toInt()),
      vsync: this,
    );
    // begin: 1.0 (画面右端) から end: -0.6 (画像全体が左に消える) へ
    // 480px / 一般的なスマホ幅(800px) ≈ 0.6 なので -0.6 に設定
    _tumbleweedPosition = Tween<double>(begin: 1.0, end: -0.6).animate(
      CurvedAnimation(parent: _tumbleweedController!, curve: Curves.linear),
    );

    _tumbleweedController!.forward();

    // アニメーション終了後にフェイント状態をクリア
    _tumbleweedController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isFeintActive = false;
          });
        }
        _tumbleweedController?.dispose();
        _tumbleweedController = null;
        _tumbleweedPosition = null;
      }
    });
  }

  void _onShoot() {
    if (_isFalseStart) return;
    if (!_isWaiting) return;
    if (_isShot) return; // 既にショット済みなら入力を無視

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
      final reactionTimeMs = DateTime.now()
          .difference(_signalTime!)
          .inMilliseconds;

      // Shot SE再生と同時に背景切り替え
      setState(() {
        _isShot = true;
        _isWaiting = false; // 入力を無効化
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
    // ⚠️ 重要: buildメソッドの閉じ括弧 } は編集しないこと！

    // 手前背景（Enemy）の状態判定
    String frontAsset;
    const double frontScale = 0.5; // 全ての人物画像を半分サイズに統一
    if (_isShot) {
      frontAsset = 'assets/upload_files/upload_files/WesternModeEnemyDead.png';
    } else {
      frontAsset = 'assets/upload_files/upload_files/WesternModeEnemy.png';
    }

    return Scaffold(
      body: LayeredModeBackground(
        backAsset: 'assets/upload_files/upload_files/WesternModeBack.png',
        frontAsset: frontAsset,
        frontScale: frontScale,
        overlay: Stack(
          children: [
            // 木目テクスチャオーバーレイ
            Positioned.fill(child: CustomPaint(painter: _WoodGrainPainter())),

            // 装飾星（4隅）
            ..._buildCornerStars(),
          ],
        ),
        child: SafeArea(
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

              // タンブルウィードアニメーション（最下部・ボタンより後ろ）
              if (_isFeintActive && _tumbleweedPosition != null)
                Positioned(
                  bottom: 0,
                  child: AnimatedBuilder(
                    animation: _tumbleweedPosition!,
                    builder: (context, child) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      return Transform.translate(
                        offset: Offset(
                          screenWidth * _tumbleweedPosition!.value,
                          0,
                        ),
                        child: child,
                      );
                    },
                    child: Transform.rotate(
                      angle: 0,
                      child: Image.asset(
                        'assets/images/upload_files/tumbleweed.png',
                        width: 480,
                        height: 480,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

              // メインコンテンツ
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // DRAWボタン
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // ボタン周りの装飾星（8個）
                        ..._buildButtonStars(),

                        // メインボタン
                        GestureDetector(
                          onTapDown: (_) => _onShoot(),
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: _isFalseStart
                                    ? [Colors.red.shade900, Colors.red.shade700]
                                    : (_hasSignal
                                          ? [
                                              Color(0xFFE6D4BC),
                                              Color(0xFFD8C9B4),
                                            ]
                                          : [
                                              Color(0xFF5C4A3A),
                                              Color(0xFF3D2E1F),
                                            ]),
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
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
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
                    // 下部SafeAreaマージン
                    const SizedBox(height: 30),
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

      return Positioned(left: x, top: y, child: _buildStar(20));
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
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
