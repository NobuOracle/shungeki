import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../services/audio_service.dart';
import 'lobby_screen.dart';
import 'settings_dialog.dart';
import 'duel_host_screen.dart';
import 'duel_join_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  GameMode? _selectedMode;
  int _selectedPlayerCount = 2; // デフォルトは2人プレイ (1=シングル, 2=2人, 3=マルチ)
  final AudioService _audioService = AudioService();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // 古びた紙のグラデーション背景
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD8C9B4), // 古紙ベージュ
              Color(0xFFE6D4BC),
              Color(0xFFC5AE8E),
            ],
          ),
        ),
        child: CustomPaint(
          painter: _VintagePaperPainter(),
          child: SafeArea(
            child: Stack(
              children: [
                // メインコンテンツ（スクロール可能）
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80, bottom: 20), // 設定ボタンのスペースを確保
                    child: Column(
                      children: [
                        // タイトルロゴ（画像）
                        _buildTitleLogo(),
                        
                        const SizedBox(height: 20),
                        
                        // ゲームモード選択エリア（2x2グリッド）
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildGameModeSelector(screenWidth),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // プレイヤー人数選択エリア
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildPlayerCountSelector(),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // STARTボタン
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildStartButton(),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // JOINボタン（2人対戦用）
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildJoinButton(),
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
            
            // 設定ボタン（右上）
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  _audioService.playUISelect(); // UISelectSE
                  showDialog(
                    context: context,
                    builder: (context) => const SettingsDialog(),
                  );
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Color(0xFF3D2E1F),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(0xFF8B6F47),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.settings,
                    color: Color(0xFFE6D4BC),
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  // タイトルロゴ
  Widget _buildTitleLogo() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.all(16),
      child: Image.asset(
        'assets/images/TitleLogo.png',
        fit: BoxFit.contain,
      ),
    );
  }

  // ゲームモード選択エリア（2x2グリッド、レスポンシブ対応）
  Widget _buildGameModeSelector(double screenWidth) {
    // 画面幅に応じてカードサイズを調整
    final double cardWidth = (screenWidth - 56) / 2; // 両側20px + 中央16px = 56px
    final double cardHeight = cardWidth * 1.15; // アスペクト比を少し調整
    
    return Column(
      children: [
        // 1行目: WESTERN, BOXING
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: _buildModeCard(
                  mode: GameMode.western,
                  title: 'WESTERN',
                  iconPath: 'assets/images/western_icon.png',
                  color: Color(0xFF3D2E1F),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: _buildModeCard(
                  mode: GameMode.boxing,
                  title: 'BOXING',
                  iconPath: 'assets/images/boxing_icon.png',
                  color: Color(0xFF5C4A3A),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // 2行目: WIZARD, SAMURAI
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: _buildModeCard(
                  mode: GameMode.wizard,
                  title: 'WIZARD',
                  iconPath: 'assets/images/wizard_icon.png',
                  color: Color(0xFF8B6F47),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: _buildModeCard(
                  mode: GameMode.samurai,
                  title: 'SAMURAI',
                  iconPath: 'assets/images/samurai_icon.png',
                  color: Color(0xFF3D2E1F),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // モードカード（手配書風）
  Widget _buildModeCard({
    required GameMode mode,
    required String title,
    required String iconPath,
    required Color color,
  }) {
    final isSelected = _selectedMode == mode;
    
    return GestureDetector(
      onTap: () {
        _audioService.playUISelect(); // UISelectSE
        setState(() {
          _selectedMode = mode;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFE6D4BC), // 古びた紙色
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Color(0xFF8B6F47) : Color(0xFFB8967D),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 紙の汚れ・シミ
            Positioned.fill(
              child: CustomPaint(
                painter: _PaperStainsPainter(),
              ),
            ),
            
            // 錆びたピン（4隅）
            ..._buildRustyPins(),
            
            // コンテンツ
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // アイコン画像
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        iconPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // タイトル（動的フォントサイズ対応）
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 1.5,
                        fontFamily: 'serif',
                      ),
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

  // 錆びたピン（4隅）
  List<Widget> _buildRustyPins() {
    return [
      Positioned(
        top: 8,
        left: 8,
        child: _buildPin(),
      ),
      Positioned(
        top: 8,
        right: 8,
        child: _buildPin(),
      ),
      Positioned(
        bottom: 8,
        left: 8,
        child: _buildPin(),
      ),
      Positioned(
        bottom: 8,
        right: 8,
        child: _buildPin(),
      ),
    ];
  }

  Widget _buildPin() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF8B6F47),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 2,
            offset: Offset(1, 1),
          ),
        ],
      ),
    );
  }

  // STARTボタン（古びた木材風）
  Widget _buildStartButton() {
    final isEnabled = _selectedMode != null;
    
    return GestureDetector(
      onTap: isEnabled ? () {
        _audioService.playUISelect(); // UISelectSE
        if (_selectedMode != null) {
          // GameStateProviderにモードを設定
          Provider.of<GameStateProvider>(context, listen: false)
              .setMode(_selectedMode!);
              
          if (_selectedPlayerCount == 1) {
            // 1人プレイ → ソロゲーム開始
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LobbyScreen(),
              ),
            );
          } else if (_selectedPlayerCount == 2) {
            // 2人プレイ → 直接DuelHostScreenへ（ホストとして部屋作成）
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DuelHostScreen(mode: _selectedMode!),
              ),
            );
          } else {
            // マルチプレイ（3-6人）は未実装
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'マルチプレイヤーモードは今後実装予定です',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'serif',
                  ),
                ),
                backgroundColor: Color(0xFF3D2E1F),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } : null,
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: isEnabled ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ] : [],
        ),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/StartButton.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  // JOINボタン（2人対戦参加用）
  Widget _buildJoinButton() {
    return GestureDetector(
      onTap: () {
        _audioService.playUISelect();
        // モード選択不要、直接DuelJoinScreenへ
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DuelJoinScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/JoinButton.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  // プレイヤー人数選択UI
  Widget _buildPlayerCountSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFD8C9B4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF8B6F47),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1人プレイ
          _buildPlayerCountButton(
            playerCount: 1,
            imagePath: 'assets/images/single_player.png',
          ),
          
          // 2人プレイ
          _buildPlayerCountButton(
            playerCount: 2,
            imagePath: 'assets/images/two_player.png',
          ),
          
          // マルチプレイヤー
          _buildPlayerCountButton(
            playerCount: 3,
            imagePath: 'assets/images/multiplayer.png',
          ),
        ],
      ),
    );
  }

  // プレイヤー人数選択ボタン
  Widget _buildPlayerCountButton({
    required int playerCount,
    required String imagePath,
  }) {
    final isSelected = _selectedPlayerCount == playerCount;
    
    return GestureDetector(
      onTap: () {
        _audioService.playUISelect(); // UISelectSE
        setState(() {
          _selectedPlayerCount = playerCount;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Color(0xFF8B6F47) : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Color(0xFF8B6F47).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: Offset(0, 4),
              spreadRadius: 2,
            ),
          ] : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: ColorFiltered(
            colorFilter: isSelected
                ? ColorFilter.mode(
                    Colors.transparent,
                    BlendMode.multiply,
                  )
                : ColorFilter.matrix([
                    0.5, 0, 0, 0, 0.5 * 255, // 赤チャンネル
                    0, 0.5, 0, 0, 0.5 * 255, // 緑チャンネル
                    0, 0, 0.5, 0, 0.5 * 255, // 青チャンネル
                    0, 0, 0, 0.6, 0,         // アルファチャンネル
                  ]),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

// ヴィンテージ紙のテクスチャペインター
class _VintagePaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // 埃・砂埃のスポット
    final random = [0.1, 0.3, 0.5, 0.7, 0.9];
    for (var i = 0; i < 50; i++) {
      paint.color = Color(0xFFB8967D).withValues(alpha: 0.1);
      canvas.drawCircle(
        Offset(
          size.width * random[i % 5],
          size.height * random[(i * 2) % 5],
        ),
        2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 紙のシミペインター
class _PaperStainsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // ランダムなシミ
    paint.color = Color(0xFFC5AE8E).withValues(alpha: 0.2);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 15, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 20, paint);
    
    // 引っかき傷風の線
    paint.color = Color(0xFFB8967D).withValues(alpha: 0.15);
    paint.strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.5),
      Offset(size.width * 0.3, size.height * 0.6),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
