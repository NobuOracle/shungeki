import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import 'western_screen.dart';
import 'boxing_screen.dart';
import 'wizard_screen.dart';
import 'samurai_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  bool _isReady = false;

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameStateProvider>(context);
    final modeName = _getModeName(gameState.currentMode);
    final modeColor = _getModeColor(gameState.currentMode);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD8C9B4), Color(0xFFE6D4BC), Color(0xFFC5AE8E)],
          ),
        ),
        child: Stack(
          children: [
            // ヴィンテージ紙テクスチャ
            Positioned.fill(
              child: CustomPaint(painter: _VintagePaperPainter()),
            ),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // モード名（大きなカード風）
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 32,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFE6D4BC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: modeColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          modeName,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: modeColor,
                            letterSpacing: 3,
                            fontFamily: 'serif',
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                offset: Offset(2, 2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 2,
                          width: 80,
                          color: modeColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'SOLO MODE',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF5C4A3A),
                            letterSpacing: 2,
                            fontFamily: 'serif',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // モードアイコン（中央）
                  Container(
                    width: 150,
                    height: 150,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE6D4BC),
                      border: Border.all(color: modeColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      _getModeIconPath(gameState.currentMode),
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ルール説明文（モードアイコンの下）
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFFE6D4BC).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: modeColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _getModeDescription(gameState.currentMode),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Color(0xFF3D2E1F),
                        fontFamily: 'serif',
                      ),
                    ),
                  ),

                  const Spacer(),

                  // READY / START MATCHボタン（2段階）
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: GestureDetector(
                      onTap: () {
                        if (!_isReady) {
                          setState(() {
                            _isReady = true;
                          });
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  _getGameScreen(gameState.currentMode),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Color(0xFF3D2E1F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isReady ? modeColor : Color(0xFF8B6F47),
                            width: _isReady ? 4 : 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // 木目テクスチャ
                            Positioned.fill(
                              child: CustomPaint(painter: _WoodGrainPainter()),
                            ),
                            Center(
                              child: Text(
                                _isReady ? 'START MATCH' : 'READY',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: _isReady
                                      ? modeColor.withValues(alpha: 0.9)
                                      : Color(0xFFE6D4BC),
                                  letterSpacing: 4,
                                  fontFamily: 'serif',
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      offset: Offset(2, 2),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 戻るボタン
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'BACK TO HOME',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF5C4A3A),
                        letterSpacing: 2,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getModeName(GameMode mode) {
    switch (mode) {
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

  Color _getModeColor(GameMode mode) {
    switch (mode) {
      case GameMode.western:
        return Color(0xFF8B6F47);
      case GameMode.boxing:
        return Color(0xFFDC143C);
      case GameMode.wizard:
        return Color(0xFF4B0082);
      case GameMode.samurai:
        return Color(0xFF8B0000);
    }
  }

  String _getModeIconPath(GameMode mode) {
    switch (mode) {
      case GameMode.western:
        return 'assets/images/western_icon.png';
      case GameMode.boxing:
        return 'assets/images/boxing_icon.png';
      case GameMode.wizard:
        return 'assets/images/wizard_icon.png';
      case GameMode.samurai:
        return 'assets/images/samurai_icon.png';
    }
  }

  Widget _getGameScreen(GameMode mode) {
    // ソロモードではeventPlan: nullを渡し、各画面でローカル生成
    switch (mode) {
      case GameMode.western:
        return const WesternScreen(eventPlan: null);
      case GameMode.boxing:
        return const BoxingScreen(eventPlan: null);
      case GameMode.wizard:
        return const WizardScreen(eventPlan: null);
      case GameMode.samurai:
        return const SamuraiScreen(eventPlan: null);
    }
  }

  String _getModeDescription(GameMode mode) {
    switch (mode) {
      case GameMode.western:
        return 'あなたは西部のガンマン。今、早撃ち勝負が始まります。\n「Shoot!」が表示されたら、すぐにボタンを押しましょう。';
      case GameMode.boxing:
        return 'あなたはラスベガスのボクサー。大一番のゴングが鳴りました。\n10個のボタンのうち、光ったものを素早くタップ！\n3回分の合計タイムを競います。';
      case GameMode.wizard:
        return 'あなたは中世の魔術師。ライバルと秘術を賭けて決闘中です。\n魔法陣に数字が現れたら、1から順にタップ。\n最後の数字までのタイムを競います。';
      case GameMode.samurai:
        return 'あなたは幕末のサムライ。刺客との立ち合いです。\n「今だ！」が表示されたら、スライダーを上にスワイプして抜刀！\nバーを一番上まで上げるタイムを競います。';
    }
  }
}

// ヴィンテージ紙テクスチャペインター
class _VintagePaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = Random(42);

    // 紙の繊維テクスチャ
    for (var i = 0; i < 100; i++) {
      paint.color = Color(0xFFB8967D).withValues(alpha: 0.05);
      final x = size.width * random.nextDouble();
      final y = size.height * random.nextDouble();
      canvas.drawCircle(Offset(x, y), 1.5, paint);
    }

    // 埃・シミ
    for (var i = 0; i < 30; i++) {
      paint.color = Color(0xFFC5AE8E).withValues(alpha: 0.1);
      final x = size.width * random.nextDouble();
      final y = size.height * random.nextDouble();
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 木目ペインター
class _WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF8B6F47).withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (var i = 0; i < 20; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 20),
        Offset(size.width, size.height * i / 20),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
