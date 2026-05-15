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
  final int digits;          // 1 or 2
  final bool allowCarry;     // 加算: 繰り上がりあり
  final bool allowBorrow;    // 減算: 繰り下がりあり
  final bool allowRemainder; // 除算: 余りあり

  const DifficultySettings({
    this.digits = 1,
    this.allowCarry = false,
    this.allowBorrow = false,
    this.allowRemainder = false,
  });

  DifficultySettings copyWith({
    int? digits,
    bool? allowCarry,
    bool? allowBorrow,
    bool? allowRemainder,
  }) => DifficultySettings(
    digits: digits ?? this.digits,
    allowCarry: allowCarry ?? this.allowCarry,
    allowBorrow: allowBorrow ?? this.allowBorrow,
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
      case Operation.mul: return _mul(d, retry);
      case Operation.div: return _div(d, retry);
    }
  }

  static Problem _add(DifficultySettings d, int retry) {
    if (d.digits == 1) {
      if (d.allowCarry) {
        int a, b;
        do {
          a = _rng.nextInt(9) + 1;
          b = _rng.nextInt(9) + 1;
        } while (a + b < 10);
        return Problem(operation: Operation.add, a: a, b: b, answer: a + b);
      } else {
        final a = _rng.nextInt(8) + 1;
        final maxB = 9 - a;
        if (maxB < 1) return _add(d, retry + 1);
        final b = _rng.nextInt(maxB) + 1;
        return Problem(operation: Operation.add, a: a, b: b, answer: a + b);
      }
    } else {
      if (d.allowCarry) {
        final a = _rng.nextInt(90) + 10;
        final b = _rng.nextInt(90) + 10;
        return Problem(operation: Operation.add, a: a, b: b, answer: a + b);
      } else {
        for (int i = 0; i < 20; i++) {
          final a1 = _rng.nextInt(8) + 1;
          final a0 = _rng.nextInt(8) + 1;
          final b1Max = 9 - a1;
          final b0Max = 9 - a0;
          if (b1Max < 1 || b0Max < 1) continue;
          final b1 = _rng.nextInt(b1Max) + 1;
          final b0 = _rng.nextInt(b0Max) + 1;
          return Problem(operation: Operation.add, a: a1 * 10 + a0, b: b1 * 10 + b0, answer: (a1 + b1) * 10 + (a0 + b0));
        }
        return _add(d, retry + 1);
      }
    }
  }

  static Problem _sub(DifficultySettings d, int retry) {
    if (d.digits == 1) {
      if (d.allowBorrow) {
        final b = _rng.nextInt(9) + 1;
        final a = _rng.nextInt(9) + 10;
        return Problem(operation: Operation.sub, a: a, b: b, answer: a - b);
      } else {
        final a = _rng.nextInt(8) + 2;
        final b = _rng.nextInt(a - 1) + 1;
        return Problem(operation: Operation.sub, a: a, b: b, answer: a - b);
      }
    } else {
      if (d.allowBorrow) {
        final a = _rng.nextInt(80) + 20;
        final b = _rng.nextInt(a - 10) + 10;
        return Problem(operation: Operation.sub, a: a, b: b, answer: a - b);
      } else {
        for (int i = 0; i < 20; i++) {
          final a1 = _rng.nextInt(8) + 2;
          final a0 = _rng.nextInt(8) + 2;
          final b1 = _rng.nextInt(a1 - 1) + 1;
          final b0 = _rng.nextInt(a0 - 1) + 1;
          return Problem(operation: Operation.sub, a: a1 * 10 + a0, b: b1 * 10 + b0, answer: (a1 - b1) * 10 + (a0 - b0));
        }
        return _sub(d, retry + 1);
      }
    }
  }

  static Problem _mul(DifficultySettings d, int retry) {
    if (d.digits == 1) {
      final a = _rng.nextInt(9) + 1;
      final b = _rng.nextInt(9) + 1;
      return Problem(operation: Operation.mul, a: a, b: b, answer: a * b);
    } else {
      final a = _rng.nextInt(90) + 10;
      final b = _rng.nextInt(9) + 1;
      return Problem(operation: Operation.mul, a: a, b: b, answer: a * b);
    }
  }

  static Problem _div(DifficultySettings d, int retry) {
    if (d.digits == 1) {
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
    } else {
      if (d.allowRemainder) {
        final b = _rng.nextInt(9) + 1;
        final a = _rng.nextInt(90) + 10;
        final q = a ~/ b;
        if (q == 0) return _div(d, retry + 1);
        return Problem(operation: Operation.div, a: a, b: b, answer: q, remainder: a % b);
      } else {
        for (int i = 0; i < 20; i++) {
          final b = _rng.nextInt(9) + 1;
          final q = _rng.nextInt(9) + 1;
          final a = b * q;
          if (a >= 10 && a <= 99) {
            return Problem(operation: Operation.div, a: a, b: b, answer: q);
          }
        }
        return _div(d, retry + 1);
      }
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
