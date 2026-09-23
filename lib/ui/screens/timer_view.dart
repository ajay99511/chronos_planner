import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:chronosky/core/services/alarm_output.dart';
import 'package:chronosky/core/theme/app_theme.dart';
import 'package:chronosky/ui/strings.dart';
import 'package:chronosky/data/models/todo_item_model.dart' as domain;

class TimerView extends StatefulWidget {
  final domain.TodoItem timer;

  const TimerView({super.key, required this.timer});

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> {
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _ticker;
  bool _isRunning = false;
  bool _isCompleted = false;
  SoundFailure? _soundFailure;
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Wall-clock deadline for the running countdown. Deriving the remaining
  /// time from this (instead of decrementing per tick) keeps the timer
  /// accurate even if ticks are delayed or the app is suspended.
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.timer.durationMinutes * 60;
    _remainingSeconds = _totalSeconds;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _audioPlayer.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _startTimer() {
    _deadline = DateTime.now().add(Duration(seconds: _remainingSeconds));
    setState(() => _isRunning = true);
    // Keep the screen awake only while the countdown is running.
    WakelockPlus.enable();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final remaining = _deadline!.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        _ticker?.cancel();
        WakelockPlus.disable();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
          _isCompleted = true;
        });
        _onTimerComplete();
      } else if (remaining != _remainingSeconds) {
        setState(() => _remainingSeconds = remaining);
      }
    });
  }

  void _pauseTimer() {
    _ticker?.cancel();
    WakelockPlus.disable();
    final deadline = _deadline;
    setState(() {
      if (deadline != null) {
        _remainingSeconds = deadline
            .difference(DateTime.now())
            .inSeconds
            .clamp(0, _totalSeconds);
      }
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _ticker?.cancel();
    _audioPlayer.stop();
    WakelockPlus.disable();
    setState(() {
      _remainingSeconds = _totalSeconds;
      _isRunning = false;
      _isCompleted = false;
      _soundFailure = null;
    });
  }

  Future<void> _onTimerComplete() async {
    final audioPath = widget.timer.audioFilePath;
    if (audioPath.isEmpty) return;

    // just_audio declares android/ios/macos/web only, so on Windows and Linux
    // -- both targeted here -- this cannot work. Checked up front so the notice
    // is accurate rather than a generic failure.
    if (!audioSupportedOnThisPlatform) {
      if (mounted) setState(() => _soundFailure = SoundFailure.unsupportedPlatform);
      return;
    }
    if (!await File(audioPath).exists()) {
      if (mounted) setState(() => _soundFailure = SoundFailure.fileMissing);
      return;
    }
    try {
      await _audioPlayer.setFilePath(audioPath);
      await _audioPlayer.play();
    } catch (e) {
      // Previously a debugPrint: the timer finished in silence and the user had
      // no way to know the sound had failed rather than simply being quiet.
      if (mounted) setState(() => _soundFailure = SoundFailure.playbackFailed);
    }
  }

  String get _soundMessage => switch (_soundFailure) {
        SoundFailure.fileMissing =>
          "Sound couldn't be played — the file may have moved.",
        SoundFailure.unsupportedPlatform =>
          'Timer sound is not supported on this platform.',
        SoundFailure.playbackFailed => "Sound couldn't be played.",
        null => '',
      };

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        _totalSeconds > 0 ? 1.0 - (_remainingSeconds / _totalSeconds) : 0.0;
    final size = MediaQuery.sizeOf(context);
    final circleSize =
        (size.shortestSide - (AppResponsive.pagePadding(context) * 2))
            .clamp(220.0, 280.0);
    final timeFontSize = (circleSize * 0.23).clamp(48.0, 64.0);
    final primaryButtonSize = (circleSize * 0.28).clamp(68.0, 80.0);
    final controlGap =
        AppResponsive.isCompact(context) ? AppSpacing.lg : AppSpacing.xl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Close timer',
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.timer.title.toUpperCase(),
          style: const TextStyle(
            letterSpacing: 2,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: AppResponsive.screenPadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: circleSize,
                    height: circleSize,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      color:
                          _isCompleted ? AppColors.health : AppColors.neonBlue,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // A screen reader should hear the remaining time, not
                      // a digit-by-digit reading of "12:34".
                      Semantics(
                        liveRegion: _isRunning,
                        label: AppStrings.timeRemaining(_remainingSeconds),
                        excludeSemantics: true,
                        child: Text(
                          _formatTime(_remainingSeconds),
                          style: AppTextStyles.heading1.copyWith(
                            fontSize: timeFontSize,
                            fontWeight: FontWeight.w200,
                          ),
                        ),
                      ),
                      if (_isCompleted)
                        const Text(
                          'COMPLETE',
                          style: TextStyle(
                            color: AppColors.health,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      if (_soundFailure != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(
                            _soundMessage,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: Colors.orangeAccent),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: AppResponsive.isCompact(context) ? AppSpacing.xl : 64,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ControlButton(
                    icon: Icons.refresh_rounded,
                    onTap: _resetTimer,
                  ),
                  SizedBox(width: controlGap),
                  GestureDetector(
                    onTap: _isCompleted
                        ? _resetTimer
                        : (_isRunning ? _pauseTimer : _startTimer),
                    child: Container(
                      width: primaryButtonSize,
                      height: primaryButtonSize,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.neonBlue, AppColors.neonPurple],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonBlue.withValues(alpha: 0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: controlGap),
                  _ControlButton(
                    icon: Icons.stop_rounded,
                    onTap: () => _audioPlayer.stop(),
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

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Icon(icon, color: Colors.white70),
      ),
    );
  }
}
