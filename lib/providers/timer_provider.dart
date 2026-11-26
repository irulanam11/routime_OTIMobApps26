import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';

abstract class TimerNotificationService {
  Future<void> cancelTimerNotifications();

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  });
}

class LocalTimerNotificationService implements TimerNotificationService {
  @override
  Future<void> cancelTimerNotifications() {
    return NotificationService.cancelTimerNotifications();
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) {
    return NotificationService.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      payload: payload,
    );
  }
}

enum TimerMode { countdown, stopwatch, pomodoro }

enum PomodoroPhase { focus, shortBreak, longBreak, completed }

class TimerProvider extends ChangeNotifier {
  static const String _storageKey = 'routime_timer';

  final TimerNotificationService _notificationService;

  TimerProvider({TimerNotificationService? notificationService})
    : _notificationService =
          notificationService ?? LocalTimerNotificationService();

  Timer? _ticker;

  TimerMode? _mode;
  PomodoroPhase _phase = PomodoroPhase.focus;

  String? _habitId;

  bool _isRunning = false;

  // Countdown dan Pomodoro.
  int _remainingMs = 0;

  // Menyimpan durasi awal Countdown.
  int _countdownDurationMs = 0;

  // Stopwatch.
  int _elapsedMs = 0;

  // Timestamp ketika Timer dimulai atau dilanjutkan.
  int? _startedAtMs;

  // Pengaturan Pomodoro.
  int _focusMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  int _sessionsBeforeLongBreak = 4;
  int _completedFocusSessions = 0;

  // Getter.
  TimerMode? get mode => _mode;
  PomodoroPhase get phase => _phase;
  String? get habitId => _habitId;

  bool get isRunning => _isRunning;
  bool get hasTimer => _mode != null;

  int get focusMinutes => _focusMinutes;
  int get shortBreakMinutes => _shortBreakMinutes;
  int get longBreakMinutes => _longBreakMinutes;
  int get sessionsBeforeLongBreak => _sessionsBeforeLongBreak;
  int get completedFocusSessions => _completedFocusSessions;
  bool _canStartForHabit(String habitId) {
    if (_isRunning) return false;

    if (_mode != null && _habitId != habitId) {
      return false;
    }

    return true;
  }

  // Menjadwalkan notifikasi sesuai mode Timer.
  Future<void> _scheduleTimerNotifications() async {
    await _notificationService.cancelTimerNotifications();

    if (!_isRunning || _mode == null) return;

    final now = DateTime.now();

    // COUNTDOWN.
    if (_mode == TimerMode.countdown) {
      final remaining = remainingMs;

      if (remaining <= 0) return;

      await _notificationService.scheduleNotification(
        id: 1000,
        title: 'Timer Selesai!',
        body: 'Waktu untuk habit kamu sudah selesai.',
        scheduledTime: now.add(Duration(milliseconds: remaining)),
        payload: _habitId,
      );

      return;
    }

    // STOPWATCH tidak membutuhkan notifikasi selesai.
    if (_mode == TimerMode.stopwatch) return;

    // POMODORO.
    if (_mode == TimerMode.pomodoro) {
      var currentPhase = _phase;
      var completedSessions = _completedFocusSessions;
      var duration = remainingMs;
      var scheduledTime = now;

      var notificationIndex = 0;

      while (currentPhase != PomodoroPhase.completed &&
          notificationIndex < 400) {
        if (duration <= 0) break;

        scheduledTime = scheduledTime.add(Duration(milliseconds: duration));

        String title;
        String body;

        if (currentPhase == PomodoroPhase.focus) {
          completedSessions++;

          if (completedSessions >= _sessionsBeforeLongBreak) {
            currentPhase = PomodoroPhase.longBreak;
            duration = _longBreakMinutes * 60 * 1000;

            title = 'Waktu Fokus Selesai!';
            body = 'Saatnya istirahat panjang.';
          } else {
            currentPhase = PomodoroPhase.shortBreak;
            duration = _shortBreakMinutes * 60 * 1000;

            title = 'Waktu Fokus Selesai!';
            body = 'Saatnya istirahat sejenak.';
          }
        } else {
          if (currentPhase == PomodoroPhase.longBreak &&
              completedSessions >= _sessionsBeforeLongBreak) {
            currentPhase = PomodoroPhase.completed;

            title = 'Pomodoro Selesai!';
            body = 'Semua sesi Pomodoro berhasil diselesaikan.';
          } else {
            currentPhase = PomodoroPhase.focus;
            duration = _focusMinutes * 60 * 1000;

            title = 'Waktu Istirahat Selesai!';
            body = 'Saatnya kembali fokus.';
          }
        }

        await _notificationService.scheduleNotification(
          id: 1100 + notificationIndex,
          title: title,
          body: body,
          scheduledTime: scheduledTime,
          payload: _habitId,
        );

        notificationIndex++;
      }
    }
  }

  // Menghitung sisa waktu Countdown atau Pomodoro.
  int get remainingMs {
    if (_mode == TimerMode.stopwatch) return 0;

    if (_isRunning && _startedAtMs != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - _startedAtMs!;

      return (_remainingMs - elapsed).clamp(0, 1 << 62);
    }

    return _remainingMs;
  }

  int get countdownDurationMs => _countdownDurationMs;

  // Menghitung waktu Stopwatch.
  int get elapsedMs {
    if (_mode != TimerMode.stopwatch) return 0;

    if (_isRunning && _startedAtMs != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - _startedAtMs!;

      return _elapsedMs + elapsed;
    }

    return _elapsedMs;
  }

  // Mengubah milidetik menjadi format waktu.
  String formatDuration(int milliseconds) {
    final totalSeconds = milliseconds ~/ 1000;

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // Memuat Timer yang sebelumnya tersimpan.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null) return;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;

      _mode = data['mode'] == null
          ? null
          : TimerMode.values.byName(data['mode']);

      _phase = PomodoroPhase.values.byName(data['phase'] ?? 'focus');

      _habitId = data['habitId'];
      _isRunning = data['isRunning'] ?? false;

      _remainingMs = data['remainingMs'] ?? 0;

      _countdownDurationMs =
          data['countdownDurationMs'] ??
          (_mode == TimerMode.countdown ? _remainingMs : 0);

      _elapsedMs = data['elapsedMs'] ?? 0;
      _startedAtMs = data['startedAtMs'];

      _focusMinutes = data['focusMinutes'] ?? 25;
      _shortBreakMinutes = data['shortBreakMinutes'] ?? 5;
      _longBreakMinutes = data['longBreakMinutes'] ?? 15;

      _sessionsBeforeLongBreak = data['sessionsBeforeLongBreak'] ?? 4;

      _completedFocusSessions = data['completedFocusSessions'] ?? 0;

      _syncTime();

      if (_isRunning) {
        _startTicker();
        await _scheduleTimerNotifications();
      }

      notifyListeners();
    } catch (_) {
      await prefs.remove(_storageKey);
      _clearState();
      notifyListeners();
    }
  }

  // Memulai Countdown.
  Future<void> startCountdown({
    required String habitId,
    required int durationMinutes,
  }) async {
    if (!_canStartForHabit(habitId) || durationMinutes <= 0) {
      return;
    }

    _stopTicker();

    _mode = TimerMode.countdown;
    _habitId = habitId;
    _phase = PomodoroPhase.focus;

    _countdownDurationMs = durationMinutes * 60 * 1000;
    _remainingMs = _countdownDurationMs;
    _elapsedMs = 0;

    await _startRunning();
  }

  // Memulai Stopwatch.
  Future<void> startStopwatch({required String habitId}) async {
    if (!_canStartForHabit(habitId)) return;

    _stopTicker();

    _mode = TimerMode.stopwatch;
    _habitId = habitId;
    _phase = PomodoroPhase.focus;

    _countdownDurationMs = 0;
    _remainingMs = 0;
    _elapsedMs = 0;

    await _startRunning();
  }

  // Memulai Pomodoro.
  Future<void> startPomodoro({
    required String habitId,
    int focusMinutes = 25,
    int shortBreakMinutes = 5,
    int longBreakMinutes = 15,
    int sessionsBeforeLongBreak = 4,
  }) async {
    if (!_canStartForHabit(habitId) ||
        focusMinutes <= 0 ||
        shortBreakMinutes <= 0 ||
        longBreakMinutes <= 0 ||
        sessionsBeforeLongBreak <= 0) {
      return;
    }

    _stopTicker();

    _mode = TimerMode.pomodoro;
    _habitId = habitId;

    _countdownDurationMs = 0;

    _focusMinutes = focusMinutes;
    _shortBreakMinutes = shortBreakMinutes;
    _longBreakMinutes = longBreakMinutes;

    _sessionsBeforeLongBreak = sessionsBeforeLongBreak;

    _completedFocusSessions = 0;
    _phase = PomodoroPhase.focus;

    _remainingMs = _focusMinutes * 60 * 1000;
    _elapsedMs = 0;

    await _startRunning();
  }

  // Memulai atau melanjutkan Timer.
  Future<void> _startRunning() async {
    _isRunning = true;
    _startedAtMs = DateTime.now().millisecondsSinceEpoch;

    _startTicker();

    notifyListeners();

    await _save();
    await _scheduleTimerNotifications();
  }

  // Pause Timer.
  Future<void> pause() async {
    if (!_isRunning) return;

    _syncTime();

    final now = DateTime.now().millisecondsSinceEpoch;

    if (_isRunning && _startedAtMs != null) {
      final elapsed = now - _startedAtMs!;

      if (_mode == TimerMode.stopwatch) {
        _elapsedMs += elapsed;
      } else {
        _remainingMs = (_remainingMs - elapsed).clamp(0, 1 << 62);
      }
    }

    _isRunning = false;
    _startedAtMs = null;

    _stopTicker();

    await _notificationService.cancelTimerNotifications();
    await _save();

    notifyListeners();
  }

  // Resume Timer.
  Future<void> resume() async {
    if (_isRunning || _mode == null) return;

    if (_mode == TimerMode.countdown && _remainingMs <= 0) {
      return;
    }

    if (_mode == TimerMode.pomodoro && _phase == PomodoroPhase.completed) {
      return;
    }

    await _startRunning();
  }

  // Reset Timer.
  Future<void> reset() async {
    _stopTicker();

    await _notificationService.cancelTimerNotifications();

    if (_mode == TimerMode.countdown) {
      _remainingMs = _countdownDurationMs;
    } else if (_mode == TimerMode.stopwatch) {
      _elapsedMs = 0;
    } else if (_mode == TimerMode.pomodoro) {
      _phase = PomodoroPhase.focus;
      _remainingMs = _focusMinutes * 60 * 1000;
      _completedFocusSessions = 0;
    }

    _isRunning = false;
    _startedAtMs = null;

    await _save();

    notifyListeners();
  }

  // Menghentikan dan menghapus Timer.
  Future<void> clear() async {
    _stopTicker();

    await _notificationService.cancelTimerNotifications();

    _clearState();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);

    notifyListeners();
  }

  // Mengembalikan seluruh state Timer ke kondisi awal.
  void _clearState() {
    _mode = null;
    _phase = PomodoroPhase.focus;
    _habitId = null;

    _isRunning = false;

    _remainingMs = 0;
    _countdownDurationMs = 0;
    _elapsedMs = 0;

    _startedAtMs = null;

    _completedFocusSessions = 0;
  }

  // Memperbarui tampilan Timer setiap detik.
  void _startTicker() {
    _stopTicker();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncTime();
      notifyListeners();
    });
  }

  // Menghentikan ticker.
  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  // Memperbarui waktu berdasarkan timestamp.
  void _syncTime() {
    if (!_isRunning || _startedAtMs == null || _mode == null) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    // Stopwatch.
    if (_mode == TimerMode.stopwatch) {
      return;
    }

    // Countdown.
    if (_mode == TimerMode.countdown) {
      final elapsed = now - _startedAtMs!;

      if (elapsed >= _remainingMs) {
        _remainingMs = 0;
        _isRunning = false;
        _startedAtMs = null;

        _stopTicker();

        _save();
      }

      return;
    }

    // Pomodoro.
    if (_mode == TimerMode.pomodoro) {
      final wasRunning = _isRunning;
      final previousPhase = _phase;

      _syncPomodoro(now);

      if (previousPhase != _phase || (wasRunning && !_isRunning)) {
        _save();
      }
    }
  }

  // Menangani perpindahan sesi Pomodoro.
  void _syncPomodoro(int now) {
    var deadline = _startedAtMs! + _remainingMs;

    while (_isRunning && now >= deadline) {
      if (_phase == PomodoroPhase.focus) {
        _completedFocusSessions++;

        if (_completedFocusSessions >= _sessionsBeforeLongBreak) {
          _phase = PomodoroPhase.longBreak;
          _remainingMs = _longBreakMinutes * 60 * 1000;
        } else {
          _phase = PomodoroPhase.shortBreak;
          _remainingMs = _shortBreakMinutes * 60 * 1000;
        }
      } else if (_phase == PomodoroPhase.shortBreak ||
          _phase == PomodoroPhase.longBreak) {
        if (_completedFocusSessions >= _sessionsBeforeLongBreak) {
          _phase = PomodoroPhase.completed;
          _remainingMs = 0;
          _isRunning = false;
          _startedAtMs = null;

          _stopTicker();
          break;
        }

        _phase = PomodoroPhase.focus;
        _remainingMs = _focusMinutes * 60 * 1000;
      }

      deadline += _remainingMs;
      _startedAtMs = deadline - _remainingMs;
    }
  }

  // Menyimpan data Timer.
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      'mode': _mode?.name,
      'phase': _phase.name,
      'habitId': _habitId,
      'isRunning': _isRunning,
      'remainingMs': _remainingMs,
      'countdownDurationMs': _countdownDurationMs,
      'elapsedMs': _elapsedMs,
      'startedAtMs': _startedAtMs,
      'focusMinutes': _focusMinutes,
      'shortBreakMinutes': _shortBreakMinutes,
      'longBreakMinutes': _longBreakMinutes,
      'sessionsBeforeLongBreak': _sessionsBeforeLongBreak,
      'completedFocusSessions': _completedFocusSessions,
    };

    await prefs.setString(_storageKey, jsonEncode(data));
  }

  // Dipanggil ketika aplikasi kembali aktif.
  void refresh() {
    _syncTime();

    if (_isRunning) {
      _save();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
