import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'package:chronosky/core/theme/app_theme.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();

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
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _ticker?.cancel();
        setState(() {
          _isRunning = false;
          _isCompleted = true;
        });
        _onTimerComplete();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pauseTimer() {
    _ticker?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _ticker?.cancel();
    _audioPlayer.stop();
    setState(() {
      _remainingSeconds = _totalSeconds;
      _isRunning = false;
      _isCompleted = false;
    });
  }

  Future<void> _onTimerComplete() async {
    final audioPath = widget.timer.audioFilePath;
    if (audioPath.isNotEmpty) {
      try {
        await _audioPlayer.setFilePath(audioPath);
        await _audioPlayer.play();
      } catch (e) {
        debugPrint('Error playing audio: $e');
      }
    }
  }

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
                      Text(
                        _formatTime(_remainingSeconds),
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: timeFontSize,
                          fontWeight: FontWeight.w200,
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
