import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/models.dart';
import '../providers/game_provider.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameProvider>();
    final session = game.lastSession;
    if (session == null) return const Scaffold();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('結果'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MainStats(session: session),
              const SizedBox(height: 20),
              _OperationBreakdown(session: session),
              const SizedBox(height: 20),
              _SpeedStats(session: session),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        game.reset();
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.divider),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('ホーム', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        game.reset();
                        game.startGame();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) {
                            // Need to import GameScreen here
                            return const _GameRedirect();
                          }),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('もう一回', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameRedirect extends StatefulWidget {
  const _GameRedirect();

  @override
  State<_GameRedirect> createState() => _GameRedirectState();
}

class _GameRedirectState extends State<_GameRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) {
          // Inline import workaround
          return const _GameScreenProxy();
        }),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(backgroundColor: AppTheme.bg);
}

// Forward declare to avoid circular import
class _GameScreenProxy extends StatelessWidget {
  const _GameScreenProxy();

  @override
  Widget build(BuildContext context) {
    // We'll use a builder approach - this re-uses the route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/game');
    });
    return const Scaffold(backgroundColor: AppTheme.bg);
  }
}

class _MainStats extends StatelessWidget {
  final Session session;
  const _MainStats({required this.session});

  @override
  Widget build(BuildContext context) {
    final m = session.totalSec ~/ 60;
    final s = session.totalSec % 60;
    final timeStr = m > 0 ? '$m分${s}秒' : '${s}秒';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BigStat(label: '正解', value: '${session.correctProblems}', color: AppTheme.primary),
              _BigStat(label: '総問題', value: '${session.totalProblems}', color: AppTheme.textPrimary),
              _BigStat(
                label: '正答率',
                value: '${(session.accuracy * 100).toStringAsFixed(1)}%',
                color: AppTheme.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SmallStat(label: '経過時間', value: timeStr),
              _SmallStat(
                label: '10秒あたり正解',
                value: session.correctPer10Sec.toStringAsFixed(2),
              ),
              _SmallStat(
                label: '平均タイム/問',
                value: '${(session.avgMsPerProblem / 1000).toStringAsFixed(2)}秒',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _BigStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;
  const _SmallStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _OperationBreakdown extends StatelessWidget {
  final Session session;
  const _OperationBreakdown({required this.session});

  @override
  Widget build(BuildContext context) {
    final acc = session.operationAccuracy;
    if (acc.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('演算別正答率', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: Operation.values.map((op) {
              final rate = acc[op.dbName] ?? -1;
              if (rate < 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(op.symbol, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: rate,
                          backgroundColor: AppTheme.surface,
                          valueColor: AlwaysStoppedAnimation(
                            rate >= 0.9 ? AppTheme.primary : rate >= 0.7 ? Colors.orange : AppTheme.error,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${(rate * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SpeedStats extends StatelessWidget {
  final Session session;
  const _SpeedStats({required this.session});

  @override
  Widget build(BuildContext context) {
    final correctAttempts = session.attempts.where((a) => a.isCorrect).toList();
    if (correctAttempts.isEmpty) return const SizedBox.shrink();

    final sortedMs = correctAttempts.map((a) => a.elapsedMs).toList()..sort();
    final median = sortedMs[sortedMs.length ~/ 2];
    final best = sortedMs.first;
    final worst = sortedMs.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('速度詳細（正解のみ）', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SmallStat(label: 'ベスト', value: '${(best / 1000).toStringAsFixed(2)}秒'),
              _SmallStat(label: '中央値', value: '${(median / 1000).toStringAsFixed(2)}秒'),
              _SmallStat(label: '最遅', value: '${(worst / 1000).toStringAsFixed(2)}秒'),
            ],
          ),
        ),
      ],
    );
  }
}
