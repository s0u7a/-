import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/models.dart';
import '../providers/game_provider.dart';
import '../widgets/numpad_widget.dart';
import 'results_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    if (game.gameState == GameState.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ResultsScreen()),
          );
        }
      });
    }

    return WillPopScope(
      onWillPop: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.card,
            title: const Text('終了しますか？'),
            content: const Text('現在のセッションは保存されません', style: TextStyle(color: AppTheme.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('続ける')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('終了', style: TextStyle(color: AppTheme.error)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          game.reset();
          return true;
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(game: game),
              const Divider(height: 1, color: AppTheme.divider),
              Expanded(
                child: _ProblemArea(game: game),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: NumpadWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final GameProvider game;
  const _TopBar({required this.game});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _StatChip(
            label: '正解',
            value: '${game.correctCount}',
            color: AppTheme.primary,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: '10秒',
            value: game.correctPer10Sec.toStringAsFixed(1),
            color: AppTheme.textPrimary,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: '正答率',
            value: '${(game.accuracy * 100).toStringAsFixed(0)}%',
            color: AppTheme.textPrimary,
          ),
          const Spacer(),
          _TimerWidget(game: game),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.card,
                  title: const Text('終了しますか？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('続ける')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('終了', style: TextStyle(color: AppTheme.error)),
                    ),
                  ],
                ),
              );
              if (confirm == true) game.stopGame();
            },
            child: const Icon(Icons.stop_rounded, color: AppTheme.textSecondary, size: 22),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _TimerWidget extends StatelessWidget {
  final GameProvider game;
  const _TimerWidget({required this.game});

  @override
  Widget build(BuildContext context) {
    String display;
    Color color = AppTheme.textPrimary;

    if (game.mode == GameMode.timeAttack) {
      final rem = game.remainingSec;
      final m = rem ~/ 60;
      final s = rem % 60;
      display = m > 0 ? '$m:${s.toString().padLeft(2, '0')}' : '${s}s';
      if (rem <= 10) color = AppTheme.error;
    } else if (game.mode == GameMode.problemCount) {
      display = '残${game.remainingProblems}問';
    } else {
      final e = game.elapsedSec;
      final m = e ~/ 60;
      final s = e % 60;
      display = m > 0 ? '$m:${s.toString().padLeft(2, '0')}' : '${s}s';
    }

    return Text(
      display,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _ProblemArea extends StatelessWidget {
  final GameProvider game;
  const _ProblemArea({required this.game});

  @override
  Widget build(BuildContext context) {
    final problem = game.currentProblem;
    if (problem == null) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Expression
        Text(
          problem.expression,
          style: const TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w300,
            color: AppTheme.textPrimary,
            letterSpacing: 4,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 8),
        const Text('=', style: TextStyle(fontSize: 36, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        // Answer display
        AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 140,
          height: 72,
          decoration: BoxDecoration(
            color: game.flashError ? AppTheme.error.withOpacity(0.15) : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: game.flashError ? AppTheme.error : AppTheme.divider,
              width: game.flashError ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            game.inputBuffer.isEmpty ? '_' : game.inputBuffer,
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w600,
              color: game.flashError ? AppTheme.error : AppTheme.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Problem counter
        Text(
          '${game.totalAttempts + 1}問目',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}
