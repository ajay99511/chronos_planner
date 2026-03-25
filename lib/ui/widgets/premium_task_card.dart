import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/task_model.dart';

/// Enhanced premium task card with multiple view modes.
///
/// Supports:
/// - Card View (default): Compact card with visual indicators
/// - List View: Detailed paragraph-style display
/// - Expanded View: Full details on tap
class PremiumTaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onTap;
  final ViewMode viewMode;

  const PremiumTaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
    this.onDuplicate,
    this.onTap,
    this.viewMode = ViewMode.card,
  });

  @override
  State<PremiumTaskCard> createState() => _PremiumTaskCardState();
}

enum ViewMode {
  /// Compact card view with visual indicators
  card,

  /// Detailed list view with paragraph-style information
  list,

  /// Minimal view for dense information display
  minimal,
}

class _PremiumTaskCardState extends State<PremiumTaskCard>
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
    switch (widget.viewMode) {
      case ViewMode.card:
        return _buildCardView();
      case ViewMode.list:
        return _buildListView();
      case ViewMode.minimal:
        return _buildMinimalView();
    }
  }

  Widget _buildCardView() {
    final color = _getTypeColor(widget.task.type);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: () =>
            _showContextMenu(context, MediaQuery.of(context).size.center(Offset.zero)),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: AppAnimDurations.normal,
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
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: _isHovered
                    ? color.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? color.withValues(alpha: 0.15)
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
                  child: Row(
                    children: [
                      // Animated Type Indicator Strip
                      AnimatedContainer(
                        duration: AppAnimDurations.normal,
                        width: 4,
                        height: 48,
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
                                    spreadRadius: 0.5,
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
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                        decorationColor:
                                            Colors.grey.withValues(alpha: 0.5),
                                        decorationThickness: 2,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Completion indicator
                                      AnimatedContainer(
                                        duration: AppAnimDurations.fast,
                                        child: widget.task.completed
                                            ? Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.health
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppRadius.pill),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.check_circle_rounded,
                                                      size: 14,
                                                      color: AppColors.health,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Done',
                                                      style: AppTextStyles.chip
                                                          .copyWith(
                                                        color: AppColors.health,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : const SizedBox(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  // Time pill
                                  _buildPill(
                                    icon: Icons.access_time_rounded,
                                    label:
                                        '${widget.task.startTime} - ${widget.task.endTime}',
                                    color: AppColors.neonCyan,
                                  ),

                                  // Energy pill
                                  _buildPill(
                                    icon: _getEnergyIcon(widget.task.energyLevel),
                                    label: widget.task.energyLevel
                                        .toString()
                                        .split('.')
                                        .last
                                        .toUpperCase(),
                                    color: _getEnergyColor(widget.task.energyLevel),
                                  ),

                                  // Category pill
                                  _buildPill(
                                    icon: _getTypeIcon(widget.task.type),
                                    label: widget.task.type
                                        .toString()
                                        .split('.')
                                        .last
                                        .toUpperCase(),
                                    color: color,
                                  ),

                                  // Cost pill (if applicable)
                                  if (widget.task.estimatedCost > 0)
                                    _buildPill(
                                      icon: Icons.attach_money_rounded,
                                      label:
                                          '\$${widget.task.estimatedCost.toStringAsFixed(0)}',
                                      color: AppColors.health,
                                    ),
                                ],
                              ),

                              // Description preview
                              if (widget.task.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  widget.task.description,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    height: 1.4,
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.8),
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
        ),
      ),
    );
  }

  Widget _buildListView() {
    final color = _getTypeColor(widget.task.type);
    final duration = _calculateDuration();

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: () =>
            _showContextMenu(context, MediaQuery.of(context).size.center(Offset.zero)),
        child: AnimatedContainer(
          duration: AppAnimDurations.normal,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: _isHovered
                  ? color.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? color.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.15),
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and status
              Row(
                children: [
                  // Completion checkbox
                  GestureDetector(
                    onTap: widget.onToggle,
                    child: AnimatedContainer(
                      duration: AppAnimDurations.fast,
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: widget.task.completed
                            ? AppColors.health.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.task.completed
                              ? AppColors.health
                              : Colors.white30,
                          width: 2,
                        ),
                      ),
                      child: widget.task.completed
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: AppColors.health,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Title and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.title,
                          style: AppTextStyles.heading3.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: widget.task.completed
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor:
                                Colors.grey.withValues(alpha: 0.5),
                          ),
                        ),
                        if (widget.task.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.task.description,
                            style: AppTextStyles.bodySmall.copyWith(
                              height: 1.5,
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Info grid
              Row(
                children: [
                  // Time info
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: AppColors.neonCyan,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Time',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.neonCyan,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.task.startTime} – ${widget.task.endTime}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Duration: $duration',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Type & Energy
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getTypeIcon(widget.task.type),
                                size: 14,
                                color: color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.task.type.toString().split('.').last.toUpperCase(),
                                style: AppTextStyles.label.copyWith(
                                  color: color,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                _getEnergyIcon(widget.task.energyLevel),
                                size: 12,
                                color: _getEnergyColor(widget.task.energyLevel),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.task.energyLevel.toString().split('.').last.toUpperCase(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                  color: _getEnergyColor(widget.task.energyLevel),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalView() {
    final color = _getTypeColor(widget.task.type);

    return InkWell(
      onTap: widget.onToggle,
      onLongPress: () =>
          _showContextMenu(context, MediaQuery.of(context).size.center(Offset.zero)),
      child: AnimatedContainer(
        duration: AppAnimDurations.fast,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _isHovered
                  ? color.withValues(alpha: 0.3)
                  : Colors.white10,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.task.completed
                    ? AppColors.health
                    : color,
                shape: BoxShape.circle,
                boxShadow: widget.task.completed
                    ? []
                    : [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
              ),
            ),
            const SizedBox(width: 12),

            // Title
            Expanded(
              child: Text(
                widget.task.title,
                style: AppTextStyles.body.copyWith(
                  decoration: widget.task.completed
                      ? TextDecoration.lineThrough
                      : null,
                  color: widget.task.completed
                      ? Colors.white30
                      : AppColors.textPrimary,
                ),
              ),
            ),

            // Time
            Text(
              '${widget.task.startTime} - ${widget.task.endTime}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.chip.copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    if (widget.onEdit == null && widget.onDuplicate == null) return;

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
        if (widget.onEdit != null)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_rounded, size: 18, color: AppColors.neonBlue),
                const SizedBox(width: 12),
                const Text('Edit', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        if (widget.onDuplicate != null)
          PopupMenuItem(
            value: 'duplicate',
            child: Row(
              children: [
                Icon(Icons.copy_rounded, size: 18, color: AppColors.neonPurple),
                const SizedBox(width: 12),
                const Text('Duplicate', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent),
              const SizedBox(width: 12),
              const Text('Delete', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') widget.onEdit?.call();
      if (value == 'duplicate') widget.onDuplicate?.call();
      if (value == 'delete') widget.onDelete();
    });
  }

  String _calculateDuration() {
    try {
      final start = _parseTime(widget.task.startTime);
      final end = _parseTime(widget.task.endTime);
      var diff = end - start;

      if (diff < 0) {
        // Overnight task
        diff += (24 * 60);
      }

      final hours = diff ~/ 60;
      final minutes = diff % 60;

      if (hours > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${minutes}m';
    } catch (e) {
      return '?';
    }
  }

  int _parseTime(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
