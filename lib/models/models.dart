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

class Problem {
  final Operation operation;
  final int a;
  final int b;
  final int answer;

  Problem({required this.operation, required this.a, required this.b, required this.answer});

  String get expression => '${a} ${operation.symbol} ${b}';

  static final Random _rng = Random();

  static Problem generate() {
    final op = Operation.values[_rng.nextInt(4)];
    return _generateFor(op);
  }

  static Problem _generateFor(Operation op) {
    switch (op) {
      case Operation.add:
        // a + b ≤ 9, a,b ∈ [1,9]
        final a = _rng.nextInt(8) + 1; // 1-8
        final maxB = 9 - a;
        if (maxB < 1) return _generateFor(op);
        final b = _rng.nextInt(maxB) + 1;
        return Problem(operation: op, a: a, b: b, answer: a + b);

      case Operation.sub:
        // a - b ≥ 1, no borrow, a,b ∈ [1,9]
        final a = _rng.nextInt(8) + 2; // 2-9
        final b = _rng.nextInt(a - 1) + 1; // 1 to a-1
        return Problem(operation: op, a: a, b: b, answer: a - b);

      case Operation.mul:
        // a,b ∈ [1,9]
        final a = _rng.nextInt(9) + 1;
        final b = _rng.nextInt(9) + 1;
        return Problem(operation: op, a: a, b: b, answer: a * b);

      case Operation.div:
        // quotient ∈ [1,9], divisor ∈ [1,9], dividend = quotient * divisor ≤ 81
        final quotient = _rng.nextInt(9) + 1;
        final divisor = _rng.nextInt(9) + 1;
        final dividend = quotient * divisor;
        return Problem(operation: op, a: dividend, b: divisor, answer: quotient);
    }
  }
}

// ─── Session ────────────────────────────────────────────────────────────────

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
  final int elapsedMs; // time from problem shown to answer submitted
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
  final int? timeLimitSec; // null for problem count / endless
  final int? problemLimit; // null for time / endless
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

// ─── Profile ────────────────────────────────────────────────────────────────

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
