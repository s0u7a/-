import 'dart:math';

enum Operation { add, sub, mul, div }

extension OperationExt on Operation {
  String get symbol {
    switch (this) {
      case Operation.add: return '+';
      case Operation.sub: return '−';
      case Operation.mul: return '×';
      case Operation.div: return '÷';
    }
  }
  String get label {
    switch (this) {
      case Operation.add: return '加算';
      case Operation.sub: return '減算';
      case Operation.mul: return '乗算';
      case Operation.div: return '除算';
    }
  }
  String get dbName => name;
  static Operation fromDb(String s) => Operation.values.firstWhere((e) => e.name == s);
}

// ─── Difficulty Settings ─────────────────────────────────────────────────────

class DifficultySettings {
  // 加算: a ∈ [1, addLeftMax], b ∈ [1, addRightMax]
  final int addLeftMax;
  final int addRightMax;

  // 減算: a ∈ [1, subLeftMax], b ∈ [1, subRightMax], a > b
  final int subLeftMax;
  final int subRightMax;

  // 乗算: 1×1 〜 9×9 固定
  // 除算
  final bool allowRemainder;

  const DifficultySettings({
    this.addLeftMax = 10,
    this.addRightMax = 9,
    this.subLeftMax = 20,
    this.subRightMax = 19,
    this.allowRemainder = false,
  });

  DifficultySettings copyWith({
    int? addLeftMax,
    int? addRightMax,
    int? subLeftMax,
    int? subRightMax,
    bool? allowRemainder,
  }) => DifficultySettings(
    addLeftMax: addLeftMax ?? this.addLeftMax,
    addRightMax: addRightMax ?? this.addRightMax,
    subLeftMax: subLeftMax ?? this.subLeftMax,
    subRightMax: subRightMax ?? this.subRightMax,
    allowRemainder: allowRemainder ?? this.allowRemainder,
  );
}

// ─── Problem ─────────────────────────────────────────────────────────────────

class Problem {
  final Operation operation;
  final int a;
  final int b;
  final int answer;
  final int? remainder;

  Problem({
    required this.operation,
    required this.a,
    required this.b,
    required this.answer,
    this.remainder,
  });

  String get expression => '$a ${operation.symbol} $b';

  int get maxAnswerDigits {
    final abs = answer.abs();
    if (abs >= 1000) return 4;
    if (abs >= 100) return 3;
    if (abs >= 10) return 2;
    return 1;
  }

  static final Random _rng = Random();

  static Problem generate([DifficultySettings? diff]) {
    diff ??= const DifficultySettings();
    final op = Operation.values[_rng.nextInt(4)];
    return _gen(op, diff, 0);
  }

  static Problem _gen(Operation op, DifficultySettings d, int retry) {
    if (retry > 60) return _gen(op, const DifficultySettings(), 0);
    switch (op) {
      case Operation.add: return _add(d, retry);
      case Operation.sub: return _sub(d, retry);
      case Operation.mul: return _mul();
      case Operation.div: return _div(d, retry);
    }
  }

  // ─── 加算 ──────────────────────────────────────────────────────────────────
  // a ∈ [1, addLeftMax], b ∈ [1, addRightMax]

  static Problem _add(DifficultySettings d, int retry) {
    final a = _rng.nextInt(d.addLeftMax) + 1;
    final b = _rng.nextInt(d.addRightMax) + 1;
    return Problem(operation: Operation.add, a: a, b: b, answer: a + b);
  }

  // ─── 減算 ──────────────────────────────────────────────────────────────────
  // a ∈ [2, subLeftMax], b ∈ [1, min(a-1, subRightMax)], a > b

  static Problem _sub(DifficultySettings d, int retry) {
    if (d.subLeftMax < 2 || d.subRightMax < 1) return _sub(const DifficultySettings(), retry);
    final a = _rng.nextInt(d.subLeftMax - 1) + 2; // 2 〜 subLeftMax
    final maxB = (a - 1).clamp(1, d.subRightMax);
    if (maxB < 1) return _sub(d, retry + 1);
    final b = _rng.nextInt(maxB) + 1;
    return Problem(operation: Operation.sub, a: a, b: b, answer: a - b);
  }

  // ─── 乗算 ──────────────────────────────────────────────────────────────────
  // 1×1 〜 9×9 固定

  static Problem _mul() {
    final a = _rng.nextInt(9) + 1;
    final b = _rng.nextInt(9) + 1;
    return Problem(operation: Operation.mul, a: a, b: b, answer: a * b);
  }

  // ─── 除算 ──────────────────────────────────────────────────────────────────
  // 余りなし: 九九の範囲（1〜81）
  // 余りあり: 被除数1〜81、除数1〜9

  static Problem _div(DifficultySettings d, int retry) {
    if (d.allowRemainder) {
      final b = _rng.nextInt(9) + 1;
      final a = _rng.nextInt(81) + 1;
      final q = a ~/ b;
      if (q == 0) return _div(d, retry + 1);
      return Problem(operation: Operation.div, a: a, b: b, answer: q, remainder: a % b);
    } else {
      final q = _rng.nextInt(9) + 1;
      final b = _rng.nextInt(9) + 1;
      return Problem(operation: Operation.div, a: q * b, b: b, answer: q);
    }
  }
}

// ─── Session ─────────────────────────────────────────────────────────────────

enum GameMode { timeAttack, problemCount, endless }

extension GameModeExt on GameMode {
  String get label {
    switch (this) {
      case GameMode.timeAttack: return '時間モード';
      case GameMode.problemCount: return '問題数モード';
      case GameMode.endless: return 'エンドレス';
    }
  }
  String get dbName => name;
  static GameMode fromDb(String s) => GameMode.values.firstWhere((e) => e.name == s);
}

class ProblemAttempt {
  final Operation operation;
  final int a;
  final int b;
  final int correctAnswer;
  final int userAnswer;
  final int elapsedMs;
  final bool isCorrect;

  ProblemAttempt({
    required this.operation,
    required this.a,
    required this.b,
    required this.correctAnswer,
    required this.userAnswer,
    required this.elapsedMs,
    required this.isCorrect,
  });

  Map<String, dynamic> toMap(int sessionId) => {
        'session_id': sessionId,
        'operation': operation.dbName,
        'a': a,
        'b': b,
        'correct_answer': correctAnswer,
        'user_answer': userAnswer,
        'elapsed_ms': elapsedMs,
        'is_correct': isCorrect ? 1 : 0,
      };
}

class Session {
  int? id;
  final int profileId;
  final GameMode mode;
  final int? timeLimitSec;
  final int? problemLimit;
  final DateTime startTime;
  final int totalSec;
  final int totalProblems;
  final int correctProblems;
  final List<ProblemAttempt> attempts;

  Session({
    this.id,
    required this.profileId,
    required this.mode,
    this.timeLimitSec,
    this.problemLimit,
    required this.startTime,
    required this.totalSec,
    required this.totalProblems,
    required this.correctProblems,
    required this.attempts,
  });

  double get accuracy => totalProblems == 0 ? 0 : correctProblems / totalProblems;
  double get avgMsPerProblem => attempts.isEmpty
      ? 0
      : attempts.map((a) => a.elapsedMs).reduce((a, b) => a + b) / attempts.length;
  double get correctPer10Sec => totalSec == 0 ? 0 : correctProblems / totalSec * 10;

  Map<String, double> get operationAccuracy {
    final Map<String, List<ProblemAttempt>> byOp = {};
    for (final a in attempts) {
      byOp.putIfAbsent(a.operation.dbName, () => []).add(a);
    }
    return byOp.map((k, v) => MapEntry(
          k,
          v.isEmpty ? 0 : v.where((a) => a.isCorrect).length / v.length,
        ));
  }

  Map<String, dynamic> toMap() => {
        'profile_id': profileId,
        'mode': mode.dbName,
        'time_limit_sec': timeLimitSec,
        'problem_limit': problemLimit,
        'start_time': startTime.millisecondsSinceEpoch,
        'total_sec': totalSec,
        'total_problems': totalProblems,
        'correct_problems': correctProblems,
      };

  factory Session.fromMap(Map<String, dynamic> m, List<ProblemAttempt> attempts) => Session(
        id: m['id'] as int,
        profileId: m['profile_id'] as int,
        mode: GameModeExt.fromDb(m['mode'] as String),
        timeLimitSec: m['time_limit_sec'] as int?,
        problemLimit: m['problem_limit'] as int?,
        startTime: DateTime.fromMillisecondsSinceEpoch(m['start_time'] as int),
        totalSec: m['total_sec'] as int,
        totalProblems: m['total_problems'] as int,
        correctProblems: m['correct_problems'] as int,
        attempts: attempts,
      );
}

// ─── Profile ─────────────────────────────────────────────────────────────────

class Profile {
  int? id;
  final String name;
  final String emoji;

  Profile({this.id, required this.name, required this.emoji});

  Map<String, dynamic> toMap() => {'name': name, 'emoji': emoji};

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as int,
        name: m['name'] as String,
        emoji: m['emoji'] as String,
      );

  static const List<String> defaultEmojis = ['🧠', '⚡', '🎯', '🔥', '💪', '🌟', '🦊', '🐉'];
}
