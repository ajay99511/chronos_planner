import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_theme.dart';
import '../../data/local/app_database.dart';

/// Full-screen countdown timer view.
///
/// Shows a circular progress indicator with remaining time,
/// play/pause and reset controls. Plays selected audio on completion.
class TimerView extends StatefulWidget {
  final TodoItem timer;

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

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (_totalSeconds == 0) return 0;
    return 1.0 - (_remainingSeconds / _totalSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () {
            _ticker?.cancel();
            _audioPlayer.stop();
            Navigator.pop(context);
          },
        ),
        title: Text(widget.timer.title,
            style: AppTextStyles.heading3.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Timer circle
              SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 8,
                        color: AppColors.surface,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    // Progress circle
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: _progress),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, _) {
                          return CircularProgressIndicator(
                            value: value,
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                            color: _isCompleted
                                ? AppColors.health
                                : AppColors.neonBlue,
                            backgroundColor: Colors.transparent,
                          );
                        },
                      ),
                    ),
                    // Time display
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(_remainingSeconds),
                          style: AppTextStyles.heading1.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 2,
                          ),
                        ),
                        if (_isCompleted)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Complete!',
                              style: AppTextStyles.subtitle
                                  .copyWith(color: AppColors.health),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Description
              if (widget.timer.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl),
                  child: Text(
                    widget.timer.description,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset
                  _ControlButton(
                    icon: Icons.replay,
                    label: 'Reset',
                    onTap: _resetTimer,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  // Play/Pause
                  GestureDetector(
                    onTap: _isCompleted
                        ? _resetTimer
                        : (_isRunning ? _pauseTimer : _startTimer),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryBlue,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.neonGlow(AppColors.neonBlue,
                            intensity: 0.3),
                      ),
                      child: Icon(
                        _isCompleted
                            ? Icons.replay
                            : (_isRunning
                                ? Icons.pause
                                : Icons.play_arrow),
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  // Stop audio (visible only when completed and audio playing)
                  _ControlButton(
                    icon: Icons.stop,
                    label: 'Stop',
                    onTap: () {
                      _audioPlayer.stop();
                    },
                    color: AppColors.textSecondary,
                  ),
                ],
              ),

              // Audio file info
              if (widget.timer.audioFilePath.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.music_note,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      widget.timer.audioFilePath.split('/').last.split('\\').last,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
