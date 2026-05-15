import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../db/database_helper.dart';

enum GameState { idle, playing, finished }

class GameProvider extends ChangeNotifier {
  // Config
  GameMode _mode = GameMode.timeAttack;
  int _timeLimitSec = 60;
  int _problemLimit = 100;
  int _profileId = 1;
  DifficultySettings _difficulty = const DifficultySettings();

  GameState _gameState = GameState.idle;
  Problem? _currentProblem;
  String _inputBuffer = '';
  bool _flashError = false;

  // Session data
  final List<ProblemAttempt> _attempts = [];
  int _correctCount = 0;
  int _elapsedSec = 0;
  DateTime? _sessionStart;
  DateTime? _problemStart;
  Timer? _timer;

  // Realtime stats for display
  int _recentCorrect = 0; // correct in last 10 seconds
  final List<int> _recentTimestamps = []; // unix ms of recent correct answers

  // Results
  Session? _lastSession;

  // ─── Getters ────────────────────────────────────────────────────────────

  GameMode get mode => _mode;
  int get timeLimitSec => _timeLimitSec;
  int get problemLimit => _problemLimit;
  GameState get gameState => _gameState;
  Problem? get currentProblem => _currentProblem;
  String get inputBuffer => _inputBuffer;
  bool get flashError => _flashError;
  int get correctCount => _correctCount;
  int get totalAttempts => _attempts.length;
  int get elapsedSec => _elapsedSec;
  int get remainingSec => (_timeLimitSec - _elapsedSec).clamp(0, _timeLimitSec);
  Session? get lastSession => _lastSession;
  int get profileId => _profileId;

  double get accuracy => totalAttempts == 0 ? 0 : _correctCount / totalAttempts;
  double get correctPer10Sec {
    final now = DateTime.now().millisecondsSinceEpoch;
    _recentTimestamps.removeWhere((t) => now - t > 10000);
    return _recentTimestamps.length.toDouble();
  }

  int get remainingProblems => (_problemLimit - _attempts.length).clamp(0, _problemLimit);

  // ─── Config ─────────────────────────────────────────────────────────────

  void setMode(GameMode m) { _mode = m; notifyListeners(); }
  void setTimeLimitSec(int s) { _timeLimitSec = s; notifyListeners(); }
  void setProblemLimit(int n) { _problemLimit = n; notifyListeners(); }
  void setProfileId(int id) { _profileId = id; }
  void setDifficulty(DifficultySettings d) { _difficulty = d; notifyListeners(); }
  DifficultySettings get difficulty => _difficulty;

  // ─── Game Control ───────────────────────────────────────────────────────

  void startGame() {
    _attempts.clear();
    _correctCount = 0;
    _elapsedSec = 0;
    _inputBuffer = '';
    _flashError = false;
    _recentTimestamps.clear();
    _sessionStart = DateTime.now();
    _gameState = GameState.playing;
    _nextProblem();
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_mode == GameMode.timeAttack) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedSec++;
        if (_elapsedSec >= _timeLimitSec) {
          _finishGame();
        } else {
          notifyListeners();
        }
      });
    } else {
      // Just track elapsed time for stats
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedSec++;
        notifyListeners();
      });
    }
  }

  void _nextProblem() {
    _currentProblem = Problem.generate(_difficulty);
    _inputBuffer = '';
    _problemStart = DateTime.now();
  }

  void inputDigit(int digit) {
    if (_gameState != GameState.playing) return;
    if (_inputBuffer.length >= 2) return; // max 2 digits

    _inputBuffer += digit.toString();
    _checkAnswer();
    notifyListeners();
  }

  void backspace() {
    if (_gameState != GameState.playing) return;
    if (_inputBuffer.isNotEmpty) {
      _inputBuffer = _inputBuffer.substring(0, _inputBuffer.length - 1);
      notifyListeners();
    }
  }

  void _checkAnswer() {
    final problem = _currentProblem!;
    final input = int.tryParse(_inputBuffer);
    if (input == null) return;

    final maxDigits = problem.answer >= 10 ? 2 : 1;

    if (input == problem.answer) {
      // Correct
      final elapsed = DateTime.now().difference(_problemStart!).inMilliseconds;
      _attempts.add(ProblemAttempt(
        operation: problem.operation,
        a: problem.a,
        b: problem.b,
        correctAnswer: problem.answer,
        userAnswer: input,
        elapsedMs: elapsed,
        isCorrect: true,
      ));
      _correctCount++;
      _recentTimestamps.add(DateTime.now().millisecondsSinceEpoch);

      if (_mode == GameMode.problemCount && _attempts.length >= _problemLimit) {
        _finishGame();
        return;
      }
      _nextProblem();
      notifyListeners();
    } else if (_inputBuffer.length >= maxDigits) {
      // Wrong and max digits reached
      final elapsed = DateTime.now().difference(_problemStart!).inMilliseconds;
      _attempts.add(ProblemAttempt(
        operation: problem.operation,
        a: problem.a,
        b: problem.b,
        correctAnswer: problem.answer,
        userAnswer: input,
        elapsedMs: elapsed,
        isCorrect: false,
      ));
      _triggerError();
    }
  }

  Future<void> _triggerError() async {
    _flashError = true;
    _inputBuffer = '';
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _flashError = false;
    notifyListeners();
  }

  void stopGame() {
    _finishGame();
  }

  Future<void> _finishGame() async {
    _timer?.cancel();
    _gameState = GameState.finished;

    final session = Session(
      profileId: _profileId,
      mode: _mode,
      timeLimitSec: _mode == GameMode.timeAttack ? _timeLimitSec : null,
      problemLimit: _mode == GameMode.problemCount ? _problemLimit : null,
      startTime: _sessionStart!,
      totalSec: _elapsedSec,
      totalProblems: _attempts.length,
      correctProblems: _correctCount,
      attempts: List.from(_attempts),
    );

    _lastSession = await DbHelper().insertSession(session);
    notifyListeners();
  }

  void reset() {
    _gameState = GameState.idle;
    _inputBuffer = '';
    _flashError = false;
    _attempts.clear();
    _correctCount = 0;
    _elapsedSec = 0;
    _recentTimestamps.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
