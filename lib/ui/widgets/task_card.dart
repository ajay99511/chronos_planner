import 'package:flutter/material.dart';
import 'package:chronosky/core/theme/app_theme.dart';
import 'package:chronosky/data/models/task_model.dart';

enum TaskCardViewMode { card, list, minimal }

/// Refactored TaskCard with premium design and multi-view support.
class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onTap;
  final TaskCardViewMode viewMode;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
    this.onDuplicate,
    this.onTap,
    this.viewMode = TaskCardViewMode.card,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

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

  IconData _getEnergyIcon(TaskEnergyLevel e) {
    switch (e) {
      case TaskEnergyLevel.low:
        return Icons.battery_charging_full_rounded;
      case TaskEnergyLevel.medium:
        return Icons.bolt_rounded;
      case TaskEnergyLevel.high:
        return Icons.flash_on_rounded;
    }
  }

  Color _getEnergyColor(TaskEnergyLevel e) {
    switch (e) {
      case TaskEnergyLevel.low:
        return AppColors.health;
      case TaskEnergyLevel.medium:
        return AppColors.leisure;
      case TaskEnergyLevel.high:
        return AppColors.neonPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animController.reverse();
      },
      child: Dismissible(
        key: Key(widget.task.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => widget.onDelete(),
        background: _buildDismissBackground(),
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPressStart: (details) =>
              _showContextMenu(context, details.globalPosition),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (widget.viewMode) {
      case TaskCardViewMode.card:
        return _buildCardView();
      case TaskCardViewMode.list:
        return _buildListView();
      case TaskCardViewMode.minimal:
        return _buildMinimalView();
    }
  }

  Widget _buildCardView() {
    final color = _getTypeColor(widget.task.type);

    return AnimatedContainer(
      duration: AppAnimDurations.normal,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.surface.withValues(alpha: 0.95),
            AppColors.surface.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: _isHovered
              ? color.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: _isHovered
                ? color.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: _isHovered ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: widget.onToggle,
          child: Padding(
            padding: const EdgeInsets.all(16),
            // Use IntrinsicHeight to allow the left strip to fill the column's height
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Animated Type Indicator Strip - Now fills height
                  AnimatedContainer(
                    duration: AppAnimDurations.normal,
                    width: 4,
                    decoration: BoxDecoration(
                      color: widget.task.completed
                          ? Colors.grey.withValues(alpha: 0.3)
                          : color,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: widget.task.completed
                          ? []
                          : [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 12,
                              ),
                            ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: AnimatedOpacity(
                      duration: AppAnimDurations.normal,
                      opacity: widget.task.completed ? 0.5 : 1.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.task.title,
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: widget.task.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (widget.task.completed)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: AppColors.health,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildPill(
                                icon: Icons.access_time_rounded,
                                label: '${widget.task.startTime} - ${widget.task.endTime}',
                                color: AppColors.neonCyan,
                              ),
                              _buildPill(
                                icon: _getEnergyIcon(widget.task.energyLevel),
                                label: widget.task.energyLevel.name.toUpperCase(),
                                color: _getEnergyColor(widget.task.energyLevel),
                              ),
                              _buildPill(
                                icon: _getTypeIcon(widget.task.type),
                                label: widget.task.type.name.toUpperCase(),
                                color: color,
                              ),
                              if (widget.task.estimatedCost > 0)
                                _buildPill(
                                  icon: Icons.attach_money_rounded,
                                  label: widget.task.estimatedCost.toStringAsFixed(0),
                                  color: AppColors.health,
                                ),
                            ],
                          ),
                          if (widget.task.description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              widget.task.description,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary.withValues(alpha: 0.8),
                                fontSize: 13,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
    );
  }

  Widget _buildListView() {
    final color = _getTypeColor(widget.task.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        onTap: widget.onToggle,
        leading: Icon(
          widget.task.completed ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
          color: widget.task.completed ? AppColors.health : Colors.white24,
        ),
        title: Text(
          widget.task.title,
          style: TextStyle(
            decoration: widget.task.completed ? TextDecoration.lineThrough : null,
            color: widget.task.completed ? Colors.white30 : Colors.white,
          ),
        ),
        subtitle: Text(
          '${widget.task.startTime} - ${widget.task.endTime} • ${widget.task.type.name}',
          style: AppTextStyles.bodySmall,
        ),
        trailing: Icon(_getTypeIcon(widget.task.type), color: color.withValues(alpha: 0.5), size: 18),
      ),
    );
  }

  Widget _buildMinimalView() {
    final color = _getTypeColor(widget.task.type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.task.completed ? AppColors.health : color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.task.title,
              style: TextStyle(
                fontSize: 14,
                decoration: widget.task.completed ? TextDecoration.lineThrough : null,
                color: widget.task.completed ? Colors.white24 : Colors.white,
              ),
            ),
          ),
          Text(widget.task.startTime, style: AppTextStyles.label.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildPill({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.chip.copyWith(
              color: color, 
              fontSize: 11, 
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: const Icon(Icons.delete_rounded, color: Colors.red),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        if (widget.onEdit != null)
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
        if (widget.onDuplicate != null)
          const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
      ],
    ).then((value) {
      if (value == 'edit') widget.onEdit?.call();
      if (value == 'duplicate') widget.onDuplicate?.call();
      if (value == 'delete') widget.onDelete();
    });
  }
}
