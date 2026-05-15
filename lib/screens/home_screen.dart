import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/models.dart';
import '../providers/game_provider.dart';
import '../providers/profile_provider.dart';
import 'game_screen.dart';
import 'stats_screen.dart';
import 'profiles_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final profileProv = context.watch<ProfileProvider>();
    final profile = profileProv.activeProfile;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Math Drill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilesScreen()),
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(profile?.emoji ?? '🧠', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    profile?.name ?? '',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ModeSelector(game: game),
              const SizedBox(height: 24),
              _ModeOptions(game: game),
              const SizedBox(height: 24),
              _DifficultySection(game: game),
              const Spacer(),
              _StartButton(game: game, profileId: profileProv.activeProfileId),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final GameProvider game;
  const _ModeSelector({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('モード', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 10),
        Row(
          children: GameMode.values.map((m) {
            final selected = game.mode == m;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: m != GameMode.values.last ? 8 : 0),
                child: GestureDetector(
                  onTap: () => game.setMode(m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : AppTheme.card,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      m.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.black : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ModeOptions extends StatelessWidget {
  final GameProvider game;
  const _ModeOptions({required this.game});

  @override
  Widget build(BuildContext context) {
    if (game.mode == GameMode.endless) {
      return const SizedBox.shrink();
    }

    if (game.mode == GameMode.timeAttack) {
      return _OptionChips<int>(
        label: '時間',
        options: const [30, 60, 180, 300, 600, 1800, 3600],
        selected: game.timeLimitSec,
        onSelect: game.setTimeLimitSec,
        labelOf: (v) => _formatTime(v),
        allowCustom: true,
        customLabel: 'カスタム',
        onCustom: () => _showTimeDialog(context, game),
      );
    }

    return _OptionChips<int>(
      label: '問題数',
      options: const [50, 100, 200, 500],
      selected: game.problemLimit,
      onSelect: game.setProblemLimit,
      labelOf: (v) => '$v問',
      allowCustom: true,
      customLabel: 'カスタム',
      onCustom: () => _showCountDialog(context, game),
    );
  }

  String _formatTime(int sec) {
    if (sec < 60) return '${sec}秒';
    if (sec < 3600) return '${sec ~/ 60}分';
    return '${sec ~/ 3600}時間';
  }

  void _showTimeDialog(BuildContext context, GameProvider game) {
    final controller = TextEditingController(text: '${game.timeLimitSec}');
    showDialog(
      context: context,
      builder: (ctx) => _InputDialog(
        title: '時間を入力（秒）',
        controller: controller,
        onConfirm: () {
          final v = int.tryParse(controller.text);
          if (v != null && v > 0) game.setTimeLimitSec(v);
        },
      ),
    );
  }

  void _showCountDialog(BuildContext context, GameProvider game) {
    final controller = TextEditingController(text: '${game.problemLimit}');
    showDialog(
      context: context,
      builder: (ctx) => _InputDialog(
        title: '問題数を入力',
        controller: controller,
        onConfirm: () {
          final v = int.tryParse(controller.text);
          if (v != null && v > 0) game.setProblemLimit(v);
        },
      ),
    );
  }
}

class _OptionChips<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final T selected;
  final Function(T) onSelect;
  final String Function(T) labelOf;
  final bool allowCustom;
  final String customLabel;
  final VoidCallback? onCustom;

  const _OptionChips({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.labelOf,
    this.allowCustom = false,
    this.customLabel = 'カスタム',
    this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...options.map((opt) {
              final sel = opt == selected;
              return GestureDetector(
                onTap: () => onSelect(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.primary : AppTheme.card,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    labelOf(opt),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: sel ? Colors.black : AppTheme.textPrimary,
                    ),
                  ),
                ),
              );
            }),
            if (allowCustom)
              GestureDetector(
                onTap: onCustom,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: const Text(
                    'カスタム',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _InputDialog extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final VoidCallback onConfirm;

  const _InputDialog({required this.title, required this.controller, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.card,
      title: Text(title, style: const TextStyle(fontSize: 16)),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: const InputDecoration(filled: true, fillColor: AppTheme.surface),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _StartButton extends StatelessWidget {
  final GameProvider game;
  final int profileId;
  const _StartButton({required this.game, required this.profileId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          game.setProfileId(profileId);
          game.startGame();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GameScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('スタート', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

// ─── Difficulty Section ───────────────────────────────────────────────────────

class _DifficultySection extends StatelessWidget {
  final GameProvider game;
  const _DifficultySection({required this.game});

  @override
  Widget build(BuildContext context) {
    final d = game.difficulty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('難易度', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              // 加算
              _OpRangeRow(
                symbol: '+',
                leftLabel: '左',
                rightLabel: '右',
                leftVal: d.addLeftMax,
                rightVal: d.addRightMax,
                leftMin: 1, leftMax: 99,
                rightMin: 1, rightMax: 99,
                onLeftChanged: (v) => game.setDifficulty(d.copyWith(addLeftMax: v)),
                onRightChanged: (v) => game.setDifficulty(d.copyWith(addRightMax: v)),
                hint: '答え最大 ${d.addLeftMax + d.addRightMax}',
              ),
              const Divider(color: AppTheme.divider, height: 20),
              // 減算
              _OpRangeRow(
                symbol: '−',
                leftLabel: '左',
                rightLabel: '右',
                leftVal: d.subLeftMax,
                rightVal: d.subRightMax,
                leftMin: 2, leftMax: 99,
                rightMin: 1, rightMax: 99,
                onLeftChanged: (v) => game.setDifficulty(d.copyWith(subLeftMax: v)),
                onRightChanged: (v) => game.setDifficulty(d.copyWith(subRightMax: v)),
                hint: '左 > 右 を保証',
              ),
              const Divider(color: AppTheme.divider, height: 20),
              // 乗算ラベル
              Row(
                children: [
                  _SymLabel('×'),
                  const SizedBox(width: 10),
                  const Text('1〜9 × 1〜9（固定）', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
              const Divider(color: AppTheme.divider, height: 20),
              // 除算
              Row(
                children: [
                  _SymLabel('÷'),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('1〜81 ÷ 1〜9（固定）', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                  const Text('余りあり', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(width: 8),
                  _Toggle(
                    value: d.allowRemainder,
                    onChanged: (v) => game.setDifficulty(d.copyWith(allowRemainder: v)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OpRangeRow extends StatelessWidget {
  final String symbol;
  final String leftLabel;
  final String rightLabel;
  final int leftVal;
  final int rightVal;
  final int leftMin;
  final int leftMax;
  final int rightMin;
  final int rightMax;
  final ValueChanged<int> onLeftChanged;
  final ValueChanged<int> onRightChanged;
  final String hint;

  const _OpRangeRow({
    required this.symbol,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftVal,
    required this.rightVal,
    required this.leftMin,
    required this.leftMax,
    required this.rightMin,
    required this.rightMax,
    required this.onLeftChanged,
    required this.onRightChanged,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SymLabel(symbol),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  _Stepper(
                    label: leftLabel,
                    value: leftVal,
                    min: leftMin,
                    max: leftMax,
                    onChanged: onLeftChanged,
                  ),
                  const SizedBox(width: 10),
                  const Text('max', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(width: 10),
                  _Stepper(
                    label: rightLabel,
                    value: rightVal,
                    min: rightMin,
                    max: rightMax,
                    onChanged: onRightChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(hint, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ),
      ],
    );
  }
}

class _SymLabel extends StatelessWidget {
  final String symbol;
  const _SymLabel(this.symbol);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(6)),
      alignment: Alignment.center,
      child: Text(symbol, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label:', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(width: 4),
        _StepBtn(
          icon: Icons.remove,
          enabled: value > min,
          onTap: () => onChanged((value - 1).clamp(min, max)),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 30,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()]),
          ),
        ),
        const SizedBox(width: 4),
        _StepBtn(
          icon: Icons.add,
          enabled: value < max,
          onTap: () => onChanged((value + 1).clamp(min, max)),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.surface : AppTheme.bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: enabled ? AppTheme.textPrimary : AppTheme.divider),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 46,
        height: 26,
        decoration: BoxDecoration(
          color: value ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 20,
            height: 20,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
