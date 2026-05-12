import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/models.dart';
import '../db/database_helper.dart';
import '../providers/profile_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Session> _sessions = [];
  Map<String, dynamic> _globalStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profileId = context.read<ProfileProvider>().activeProfileId;
    final sessions = await DbHelper().getSessions(profileId);
    final stats = await DbHelper().getProfileStats(profileId);
    setState(() {
      _sessions = sessions;
      _globalStats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('統計')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _sessions.isEmpty
              ? const Center(
                  child: Text('まだセッションがありません', style: TextStyle(color: AppTheme.textSecondary)),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.card,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _GlobalStats(stats: _globalStats),
                        const SizedBox(height: 24),
                        _SpeedChart(sessions: _sessions),
                        const SizedBox(height: 24),
                        _AccuracyChart(sessions: _sessions),
                        const SizedBox(height: 24),
                        _SessionHistory(sessions: _sessions),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _GlobalStats extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _GlobalStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalSec = stats['totalTimeSec'] as int? ?? 0;
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final timeStr = h > 0 ? '${h}時間${m}分' : '${m}分';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('累計', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(label: '総問題数', value: '${stats['totalProblems'] ?? 0}'),
              _Stat(label: 'セッション', value: '${stats['totalSessions'] ?? 0}'),
              _Stat(label: '総時間', value: timeStr),
              _Stat(
                label: 'ベスト\n10秒正解',
                value: ((stats['bestRate'] as double?) ?? 0).toStringAsFixed(1),
                color: AppTheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, this.color = AppTheme.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary), textAlign: TextAlign.center),
      ],
    );
  }
}

class _SpeedChart extends StatelessWidget {
  final List<Session> sessions;
  const _SpeedChart({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final data = sessions.reversed.take(30).toList();
    if (data.length < 2) return const SizedBox.shrink();

    final spots = data.asMap().entries.map((e) {
      final rate = e.value.correctPer10Sec;
      return FlSpot(e.key.toDouble(), rate);
    }).toList();

    return _ChartCard(
      title: '10秒あたり正解数（直近30回）',
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.transparent,
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.divider, strokeWidth: 1),
            getDrawingVerticalLine: (_) => const FlLine(color: AppTheme.divider, strokeWidth: 0.5),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  v.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primary.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccuracyChart extends StatelessWidget {
  final List<Session> sessions;
  const _AccuracyChart({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final data = sessions.reversed.take(30).toList();
    if (data.length < 2) return const SizedBox.shrink();

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.accuracy * 100);
    }).toList();

    return _ChartCard(
      title: '正答率（直近30回）',
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.transparent,
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.divider, strokeWidth: 1),
            getDrawingVerticalLine: (_) => const FlLine(color: AppTheme.divider, strokeWidth: 0.5),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}%',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blueAccent.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 10),
        Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
          decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12)),
          child: child,
        ),
      ],
    );
  }
}

class _SessionHistory extends StatelessWidget {
  final List<Session> sessions;
  const _SessionHistory({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('セッション履歴', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 10),
        ...sessions.take(20).map((s) => _SessionTile(session: s)),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Session session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('M/d HH:mm');
    final m = session.totalSec ~/ 60;
    final s = session.totalSec % 60;
    final timeStr = m > 0 ? '${m}分${s}秒' : '${s}秒';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fmt.format(session.startTime), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 2),
              Text(session.mode.label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: '${session.correctProblems}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primary),
                  ),
                  TextSpan(
                    text: '/${session.totalProblems}',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                ]),
              ),
              Text(
                '$timeStr  ${session.correctPer10Sec.toStringAsFixed(1)}/10秒',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
