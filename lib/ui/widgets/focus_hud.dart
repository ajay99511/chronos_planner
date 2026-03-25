import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/schedule_provider.dart';
import '../../data/models/task_model.dart';
import 'dart:io';

class FocusHudWidget extends StatelessWidget {
  final VoidCallback onExit;

  const FocusHudWidget({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);
    final currentDay = provider.selectedDay;
    
    // Find the next uncompleted task
    Task? activeTask;
    try {
      activeTask = currentDay.tasks.firstWhere((t) => !t.completed);
    } catch (_) {}

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.95),
          border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt, color: AppColors.neonCyan, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "FOCUS MODE",
                      style: AppTextStyles.label.copyWith(color: AppColors.neonCyan),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: onExit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Spacer(),
            if (activeTask != null) ...[
              Text(
                activeTask.title,
                style: AppTextStyles.heading3.copyWith(fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${activeTask.startTime} - ${activeTask.endTime}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        provider.toggleTaskComplete(activeTask!.id);
                      },
                      child: const Text("Complete", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Center(
                child: Text("All caught up!", style: AppTextStyles.body),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
