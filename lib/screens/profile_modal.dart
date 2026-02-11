import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../models/title_definition.dart';
import '../services/audio_service.dart';

class ProfileModal extends StatefulWidget {
  const ProfileModal({super.key});

  @override
  State<ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<ProfileModal> {
  final TextEditingController _nameController = TextEditingController();
  final AudioService _audioService = AudioService();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final profileProvider = context.read<ProfileProvider>();
    _nameController.text = profileProvider.profile?.playerName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD8C9B4),
              Color(0xFFE6D4BC),
              Color(0xFFC5AE8E),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Color(0xFF8B6F47),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // タイトルバー
            Container(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xFF3D2E1F),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(17),
                  topRight: Radius.circular(17),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF8B6F47),
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'プロフィール',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6D4BC),
                      fontFamily: 'serif',
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Color(0xFFE6D4BC)),
                    onPressed: () {
                      _audioService.playUISelect();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),

            // コンテンツ
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Consumer<ProfileProvider>(
                  builder: (context, profileProvider, _) {
                    final profile = profileProvider.profile;
                    if (profile == null) {
                      return Center(child: CircularProgressIndicator());
                    }

                    // 選択中の称号を取得
                    TitleDefinition? selectedTitle;
                    if (profile.selectedTitleId != null) {
                      selectedTitle = profileProvider.titleMasterList
                          .where((t) => t.id == profile.selectedTitleId)
                          .firstOrNull;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // プレイヤー名入力
                        _buildNameInput(),

                        SizedBox(height: 20),

                        // 二つ名表示
                        _buildTitleDisplay(profile, selectedTitle),

                        SizedBox(height: 20),

                        // 称号一覧ボタン
                        _buildTitleListButton(profileProvider),

                        SizedBox(height: 20),

                        // 自己ベスト
                        _buildBestRecords(profile),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'プレイヤー名',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3D2E1F),
            fontFamily: 'serif',
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF3D2E1F),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF8B6F47), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF8B6F47), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF3D2E1F), width: 2),
            ),
            hintText: 'プレイヤー名を入力',
            errorText: _errorMessage,
          ),
          maxLength: 20,
        ),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: _saveName,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF3D2E1F),
            foregroundColor: Color(0xFFE6D4BC),
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Color(0xFF8B6F47), width: 2),
            ),
          ),
          child: Text(
            '保存',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleDisplay(dynamic profile, TitleDefinition? selectedTitle) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF3D2E1F).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF8B6F47), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '二つ名',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2E1F),
                  fontFamily: 'serif',
                ),
              ),
              if (selectedTitle != null)
                IconButton(
                  icon: Icon(Icons.close, size: 20),
                  color: Color(0xFF8B6F47),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  onPressed: () async {
                    _audioService.playUISelect();
                    final profileProvider = context.read<ProfileProvider>();
                    await profileProvider.updateSelectedTitle(null);
                  },
                  tooltip: '二つ名を外す',
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            selectedTitle?.name ?? '（なし）',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B6F47),
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleListButton(ProfileProvider profileProvider) {
    return ElevatedButton.icon(
      onPressed: () async {
        _audioService.playUISelect();
        await showDialog(
          context: context,
          builder: (context) => TitleListModal(
            profileProvider: profileProvider,
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF3D2E1F),
        foregroundColor: Color(0xFFE6D4BC),
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Color(0xFF8B6F47), width: 2),
        ),
      ),
      icon: Icon(Icons.emoji_events),
      label: Text(
        '称号一覧',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBestRecords(dynamic profile) {
    final Map<String, String> modeNames = {
      'WESTERN': 'ウェスタン',
      'BOXING': 'ボクシング',
      'WIZARD': 'ウィザード',
      'SAMURAI': 'サムライ',
    };

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF3D2E1F).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF8B6F47), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '自己ベスト',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3D2E1F),
              fontFamily: 'serif',
            ),
          ),
          SizedBox(height: 12),
          ...modeNames.entries.map((entry) {
            final mode = entry.key;
            final modeName = entry.value;
            final records = profile.bestRecordsByMode[mode] ?? [];
            final playCount = profile.playCountByMode[mode] ?? 0;
            final maxWinStreak = profile.maxWinStreakByMode[mode] ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        modeName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B6F47),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'プレイ回数: $playCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF3D2E1F).withValues(alpha: 0.7),
                            ),
                          ),
                          if (maxWinStreak > 0)
                            Text(
                              '最大連勝: $maxWinStreak',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8B6F47),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  if (records.isEmpty)
                    Text(
                      '記録なし',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF3D2E1F).withValues(alpha: 0.5),
                      ),
                    )
                  else
                    ...records.asMap().entries.map((entry) {
                      final index = entry.key;
                      final record = entry.value;
                      return Text(
                        '${index + 1}位: ${record.timeMs}ms',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF3D2E1F),
                          fontFamily: 'monospace',
                        ),
                      );
                    }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'プレイヤー名を入力してください';
      });
      return;
    }

    final profileProvider = context.read<ProfileProvider>();
    final error = await profileProvider.updatePlayerName(name);

    if (error == null) {
      _audioService.playUISelect();
      setState(() {
        _errorMessage = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('プレイヤー名を保存しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage = error;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// 称号一覧モーダル
class TitleListModal extends StatelessWidget {
  final ProfileProvider profileProvider;

  const TitleListModal({super.key, required this.profileProvider});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();
    final profile = profileProvider.profile!;
    final unlockedIds = profile.unlockedTitleIds;

    // デバッグログ
    debugPrint('📋 [TitleListModal] 獲得済み称号数: ${unlockedIds.length}');
    debugPrint('📋 [TitleListModal] 獲得済み称号ID: ${unlockedIds.join(", ")}');
    debugPrint('📋 [TitleListModal] 称号マスタ数: ${profileProvider.titleMasterList.length}');
    for (final title in profileProvider.titleMasterList) {
      final isUnlocked = unlockedIds.contains(title.id);
      debugPrint('  - ${title.id}: ${title.name} (獲得済み: $isUnlocked)');
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD8C9B4),
              Color(0xFFE6D4BC),
              Color(0xFFC5AE8E),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Color(0xFF8B6F47),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // タイトルバー
            Container(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xFF3D2E1F),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(17),
                  topRight: Radius.circular(17),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF8B6F47),
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '称号一覧',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE6D4BC),
                      fontFamily: 'serif',
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Color(0xFFE6D4BC)),
                    onPressed: () {
                      audioService.playUISelect();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),

            // 称号リスト
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(20),
                children: profileProvider.titleMasterList.map((title) {
                  final isUnlocked = unlockedIds.contains(title.id);
                  final isSelected = profile.selectedTitleId == title.id;

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? (isSelected
                              ? Color(0xFF8B6F47).withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.5))
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Color(0xFF8B6F47)
                            : Color(0xFF3D2E1F).withValues(alpha: 0.3),
                        width: isSelected ? 3 : 2,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        isUnlocked ? title.name : '？？？',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked
                              ? Color(0xFF3D2E1F)
                              : Colors.grey.shade600,
                          fontFamily: 'serif',
                        ),
                      ),
                      subtitle: Text(
                        isUnlocked ? title.description : '未解放',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnlocked
                              ? Color(0xFF3D2E1F).withValues(alpha: 0.7)
                              : Colors.grey.shade500,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle,
                              color: Color(0xFF8B6F47))
                          : null,
                      enabled: isUnlocked,
                      onTap: isUnlocked
                          ? () async {
                              audioService.playUISelect();
                              if (isSelected) {
                                // 選択解除
                                await profileProvider
                                    .updateSelectedTitle(null);
                              } else {
                                // 選択
                                await profileProvider
                                    .updateSelectedTitle(title.id);
                              }
                            }
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
