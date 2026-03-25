import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/task_model.dart';

/// Premium task detail panel widget.
///
/// Displays comprehensive task information in an elegant,
/// paragraph-style format with visual hierarchy.
///
/// Features:
/// - Full task description with formatting
/// - Visual timeline bar
/// - Metadata cards (energy, cost, priority)
/// - Quick actions (complete, edit, delete)
class TaskDetailPanel extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onClose;
  final bool isCompleted;

  const TaskDetailPanel({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onClose,
    this.isCompleted = false,
  });

  Color _getTypeColor(TaskType type) {
    switch (type) {
      case TaskType.work:
        return AppColors.work;
      case TaskType.personal:
        return AppColors.personal;
      case TaskType.health:
        return AppColors.health;
      case TaskType.leisure:
        return AppColors.leisure;
    }
  }

  IconData _getTypeIcon(TaskType type) {
    switch (type) {
      case TaskType.work:
        return Icons.work_outline_rounded;
      case TaskType.personal:
        return Icons.home_outlined;
      case TaskType.health:
        return Icons.favorite_outline_rounded;
      case TaskType.leisure:
        return Icons.coffee_outlined;
    }
  }

  String _getTypeLabel(TaskType type) {
    switch (type) {
      case TaskType.work:
        return 'Work';
      case TaskType.personal:
        return 'Personal';
      case TaskType.health:
        return 'Health & Wellness';
      case TaskType.leisure:
        return 'Leisure & Recreation';
    }
  }

  String _getEnergyLabel(TaskEnergyLevel level) {
    switch (level) {
      case TaskEnergyLevel.low:
        return 'Low Energy';
      case TaskEnergyLevel.medium:
        return 'Medium Energy';
      case TaskEnergyLevel.high:
        return 'High Energy';
    }
  }

  String _getPriorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low Priority';
      case TaskPriority.medium:
        return 'Medium Priority';
      case TaskPriority.high:
        return 'High Priority';
    }
  }

  IconData _getEnergyIcon(TaskEnergyLevel level) {
    switch (level) {
      case TaskEnergyLevel.low:
        return Icons.battery_charging_full_rounded;
      case TaskEnergyLevel.medium:
        return Icons.bolt_rounded;
      case TaskEnergyLevel.high:
        return Icons.flash_on_rounded;
    }
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Icons.keyboard_arrow_down_rounded;
      case TaskPriority.medium:
        return Icons.remove_rounded;
      case TaskPriority.high:
        return Icons.keyboard_arrow_up_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(task.type);
    final duration = _calculateDuration();

    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with gradient accent
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: task.completed
                    ? [Colors.grey.withValues(alpha: 0.3), Colors.grey.withValues(alpha: 0.1)]
                    : [typeColor, typeColor.withValues(alpha: 0.6)],
              ),
            ),
          ),

          // App bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Task Details',
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    _IconButton(
                      icon: Icons.close_rounded,
                      onTap: onClose,
                      tooltip: 'Close',
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _IconButton(
                      icon: isCompleted ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                      onTap: onToggle,
                      tooltip: isCompleted ? 'Mark as incomplete' : 'Mark as complete',
                      color: AppColors.health,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // Scrollable content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Task Title Card
                _buildTitleCard(typeColor),

                const SizedBox(height: AppSpacing.lg),

                // Timeline Visualization
                _buildTimelineCard(typeColor, duration),

                const SizedBox(height: AppSpacing.lg),

                // Description Section
                if (task.description.isNotEmpty)
                  _buildDescriptionCard(),

                const SizedBox(height: AppSpacing.lg),

                // Metadata Grid
                _buildMetadataGrid(typeColor),

                const SizedBox(height: AppSpacing.lg),

                // Additional Info
                _buildAdditionalInfoCard(),

                const SizedBox(height: AppSpacing.xl),

                // Action Buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleCard(Color typeColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeColor.withValues(alpha: 0.15),
            typeColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _getTypeIcon(task.type),
                  color: typeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTypeLabel(task.type),
                      style: AppTextStyles.label.copyWith(
                        color: typeColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (task.completed) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.health.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 12,
                              color: AppColors.health,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Completed',
                              style: AppTextStyles.chip.copyWith(
                                color: AppColors.health,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            task.title,
            style: AppTextStyles.heading2.copyWith(
              fontSize: 22,
              decoration: task.completed ? TextDecoration.lineThrough : null,
              decorationColor: Colors.grey.withValues(alpha: 0.5),
              decorationThickness: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(Color typeColor, String duration) {
    final endTime = _parseTime(task.endTime);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final taskEnd = todayStart.add(Duration(minutes: endTime));
    final isOverdue = taskEnd.isBefore(now) && !task.completed;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isOverdue
              ? Colors.redAccent.withValues(alpha: 0.3)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 18,
                color: isOverdue ? Colors.redAccent : AppColors.neonCyan,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Timeline',
                style: AppTextStyles.label.copyWith(
                  color: isOverdue ? Colors.redAccent : AppColors.neonCyan,
                ),
              ),
              if (isOverdue) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Overdue',
                    style: AppTextStyles.chip.copyWith(
                      color: Colors.redAccent,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Time',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: typeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.startTime,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white10,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End Time',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 14,
                          color: typeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.endTime,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: typeColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Duration: $duration',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes_rounded,
                size: 18,
                color: AppColors.neonPurple,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Description',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.neonPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            task.description,
            style: AppTextStyles.body.copyWith(
              height: 1.6,
              color: AppColors.textPrimary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataGrid(Color typeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Task Metadata',
          style: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildMetadataCard(
                icon: _getEnergyIcon(task.energyLevel),
                iconColor: _getEnergyColor(task.energyLevel),
                label: _getEnergyLabel(task.energyLevel),
                sublabel: 'Required energy',
                typeColor: _getEnergyColor(task.energyLevel),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildMetadataCard(
                icon: _getPriorityIcon(task.priority),
                iconColor: _getPriorityColor(task.priority),
                label: _getPriorityLabel(task.priority),
                sublabel: 'Importance level',
                typeColor: _getPriorityColor(task.priority),
              ),
            ),
          ],
        ),
        if (task.estimatedCost > 0) ...[
          const SizedBox(height: AppSpacing.md),
          _buildMetadataCard(
            icon: Icons.attach_money_rounded,
            iconColor: AppColors.health,
            label: '\$${task.estimatedCost.toStringAsFixed(2)}',
            sublabel: 'Estimated cost',
            typeColor: AppColors.health,
            isFullWidth: true,
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String sublabel,
    required Color typeColor,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeColor.withValues(alpha: 0.1),
            typeColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: typeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.neonBlue,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Additional Information',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.neonBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            icon: Icons.tag_rounded,
            label: 'Source',
            value: task.sourceTemplateId.isNotEmpty
                ? 'From Template'
                : 'Manual Entry',
            iconColor: AppColors.neonPurple,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            icon: task.completed
                ? Icons.check_circle_outline_rounded
                : Icons.radio_button_unchecked_rounded,
            label: 'Status',
            value: task.completed ? 'Completed' : 'Pending',
            iconColor: task.completed ? AppColors.health : AppColors.leisure,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            icon: Icons.edit_note_rounded,
            label: 'Last Modified',
            value: 'Just now',
            iconColor: AppColors.neonCyan,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          ':',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.neonBlue,
                  side: BorderSide(color: AppColors.neonBlue.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit Task'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _calculateDuration() {
    try {
      final start = _parseTime(task.startTime);
      final end = _parseTime(task.endTime);
      final diff = end - start;
      
      if (diff < 0) {
        // Overnight task
        final overnight = diff + (24 * 60);
        final hours = overnight ~/ 60;
        final minutes = overnight % 60;
        return '${hours}h ${minutes}m';
      }
      
      final hours = diff ~/ 60;
      final minutes = diff % 60;
      
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${minutes}m';
    } catch (e) {
      return 'Unknown';
    }
  }

  int _parseTime(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Color _getEnergyColor(TaskEnergyLevel level) {
    switch (level) {
      case TaskEnergyLevel.low:
        return AppColors.health;
      case TaskEnergyLevel.medium:
        return AppColors.leisure;
      case TaskEnergyLevel.high:
        return AppColors.neonPurple;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return AppColors.health;
      case TaskPriority.medium:
        return AppColors.leisure;
      case TaskPriority.high:
        return Colors.redAccent;
    }
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color? color;

  const _IconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: (color ?? AppColors.textSecondary).withValues(alpha: 0.1),
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
