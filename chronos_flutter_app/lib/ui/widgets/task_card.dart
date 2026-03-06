import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/task_model.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
    this.onDuplicate,
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
        return Icons.work_outline;
      case TaskType.personal:
        return Icons.home_outlined;
      case TaskType.health:
        return Icons.favorite_outline;
      case TaskType.leisure:
        return Icons.coffee_outlined;
    }
  }

  IconData _getPriorityIcon(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return Icons.arrow_downward;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.arrow_upward;
    }
  }

  Color _getPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return AppColors.health;
      case TaskPriority.medium:
        return AppColors.leisure;
      case TaskPriority.high:
        return Colors.redAccent;
    }
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: AppColors.neonBlue),
              const SizedBox(width: 12),
              const Text('Edit', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        if (onDuplicate != null)
          PopupMenuItem(
            value: 'duplicate',
            child: Row(
              children: [
                Icon(Icons.copy_outlined,
                    size: 18, color: AppColors.neonPurple),
                const SizedBox(width: 12),
                const Text('Duplicate', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline,
                  size: 18, color: Colors.redAccent.shade200),
              const SizedBox(width: 12),
              const Text('Delete', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') onEdit?.call();
      if (value == 'duplicate') onDuplicate?.call();
      if (value == 'delete') onDelete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor(task.type);

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      child: GestureDetector(
        onLongPressStart: (details) =>
            _showContextMenu(context, details.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.surface.withValues(alpha: 0.9),
                AppColors.surface.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Type Indicator Strip
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: task.completed
                            ? Colors.grey.withValues(alpha: 0.3)
                            : color,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: task.completed
                            ? []
                            : [
                                BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 8)
                              ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: task.completed ? 0.5 : 1.0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      decoration: task.completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Priority indicator
                                    Icon(
                                      _getPriorityIcon(task.priority),
                                      size: 14,
                                      color: _getPriorityColor(task.priority),
                                    ),
                                    const SizedBox(width: 8),
                                    if (task.completed)
                                      const Icon(Icons.check_circle,
                                          size: 18, color: AppColors.health),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.access_time_filled,
                                    size: 12,
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.7)),
                                const SizedBox(width: 4),
                                Text(
                                  '${task.startTime} - ${task.endTime}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(_getTypeIcon(task.type),
                                          size: 10, color: color),
                                      const SizedBox(width: 4),
                                      Text(
                                        task.type
                                            .toString()
                                            .split('.')
                                            .last
                                            .toUpperCase(),
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: color),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (task.description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                task.description,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.8)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
