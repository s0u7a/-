import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._();
  factory DbHelper() => _instance;
  DbHelper._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'math_drill.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            emoji TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER NOT NULL,
            mode TEXT NOT NULL,
            time_limit_sec INTEGER,
            problem_limit INTEGER,
            start_time INTEGER NOT NULL,
            total_sec INTEGER NOT NULL,
            total_problems INTEGER NOT NULL,
            correct_problems INTEGER NOT NULL,
            FOREIGN KEY (profile_id) REFERENCES profiles(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE attempts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            operation TEXT NOT NULL,
            a INTEGER NOT NULL,
            b INTEGER NOT NULL,
            correct_answer INTEGER NOT NULL,
            user_answer INTEGER NOT NULL,
            elapsed_ms INTEGER NOT NULL,
            is_correct INTEGER NOT NULL,
            FOREIGN KEY (session_id) REFERENCES sessions(id)
          )
        ''');
        // Default profile
        await db.insert('profiles', {'name': 'Player 1', 'emoji': '🧠'});
      },
    );
  }

  // ─── Profiles ──────────────────────────────────────────────────────────

  Future<List<Profile>> getProfiles() async {
    final d = await db;
    final rows = await d.query('profiles', orderBy: 'id ASC');
    return rows.map(Profile.fromMap).toList();
  }

  Future<Profile> insertProfile(Profile p) async {
    final d = await db;
    final id = await d.insert('profiles', p.toMap());
    return Profile(id: id, name: p.name, emoji: p.emoji);
  }

  Future<void> deleteProfile(int id) async {
    final d = await db;
    await d.delete('sessions', where: 'profile_id = ?', whereArgs: [id]);
    await d.delete('profiles', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateProfile(Profile p) async {
    final d = await db;
    await d.update('profiles', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  // ─── Sessions ──────────────────────────────────────────────────────────

  Future<Session> insertSession(Session session) async {
    final d = await db;
    final sessionId = await d.insert('sessions', session.toMap());

    final batch = d.batch();
    for (final attempt in session.attempts) {
      batch.insert('attempts', attempt.toMap(sessionId));
    }
    await batch.commit(noResult: true);

    return Session(
      id: sessionId,
      profileId: session.profileId,
      mode: session.mode,
      timeLimitSec: session.timeLimitSec,
      problemLimit: session.problemLimit,
      startTime: session.startTime,
      totalSec: session.totalSec,
      totalProblems: session.totalProblems,
      correctProblems: session.correctProblems,
      attempts: session.attempts,
    );
  }

  Future<List<Session>> getSessions(int profileId, {int limit = 100}) async {
    final d = await db;
    final rows = await d.query(
      'sessions',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'start_time DESC',
      limit: limit,
    );
    final sessions = <Session>[];
    for (final row in rows) {
      final id = row['id'] as int;
      final attemptRows = await d.query('attempts', where: 'session_id = ?', whereArgs: [id]);
      final attempts = attemptRows.map((r) => ProblemAttempt(
            operation: OperationExt.fromDb(r['operation'] as String),
            a: r['a'] as int,
            b: r['b'] as int,
            correctAnswer: r['correct_answer'] as int,
            userAnswer: r['user_answer'] as int,
            elapsedMs: r['elapsed_ms'] as int,
            isCorrect: (r['is_correct'] as int) == 1,
          )).toList();
      sessions.add(Session.fromMap(row, attempts));
    }
    return sessions;
  }

  Future<Map<String, dynamic>> getProfileStats(int profileId) async {
    final d = await db;
    final totalProblems = Sqflite.firstIntValue(
          await d.rawQuery('SELECT SUM(total_problems) FROM sessions WHERE profile_id = ?', [profileId]),
        ) ?? 0;
    final totalCorrect = Sqflite.firstIntValue(
          await d.rawQuery('SELECT SUM(correct_problems) FROM sessions WHERE profile_id = ?', [profileId]),
        ) ?? 0;
    final totalSessions = Sqflite.firstIntValue(
          await d.rawQuery('SELECT COUNT(*) FROM sessions WHERE profile_id = ?', [profileId]),
        ) ?? 0;
    final totalTimeSec = Sqflite.firstIntValue(
          await d.rawQuery('SELECT SUM(total_sec) FROM sessions WHERE profile_id = ?', [profileId]),
        ) ?? 0;

    // Best correct/10sec
    final bestRateRow = await d.rawQuery(
      'SELECT MAX(CAST(correct_problems AS REAL) / NULLIF(total_sec,0) * 10) FROM sessions WHERE profile_id = ?',
      [profileId],
    );
    final bestRate = (bestRateRow.first.values.first as double?) ?? 0.0;

    return {
      'totalProblems': totalProblems,
      'totalCorrect': totalCorrect,
      'totalSessions': totalSessions,
      'totalTimeSec': totalTimeSec,
      'bestRate': bestRate,
    };
  }
}
