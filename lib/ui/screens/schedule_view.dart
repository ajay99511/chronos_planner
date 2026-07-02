import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:chronosky/core/theme/app_theme.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/data/models/plan_template_model.dart';
import 'package:chronosky/ui/widgets/add_task_sheet.dart';
import 'package:chronosky/ui/widgets/glass_container.dart';
import 'package:chronosky/ui/widgets/task_card.dart';
import 'package:chronosky/ui/widgets/task_detail_panel.dart';
import 'package:chronosky/providers/schedule_state_provider.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  TaskCardViewMode _currentViewMode = TaskCardViewMode.card;
  Task? _selectedTask;

  void _toggleViewMode() {
    setState(() {
      _currentViewMode = _currentViewMode == TaskCardViewMode.card
          ? TaskCardViewMode.list
          : TaskCardViewMode.card;
    });
  }

  void _openTaskDetail(Task task) {
    if (MediaQuery.sizeOf(context).width < 800) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          height: MediaQuery.sizeOf(context).height * 0.85,
          margin: const EdgeInsets.only(top: 24),
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: TaskDetailPanel(
            task: task,
            isCompleted: task.completed,
            onToggle: () {
              context.read<ScheduleStateProvider>().updateTask(
                    task.id,
                    task.copyWith(completed: !task.completed),
                  );
              Navigator.pop(context);
            },
            onEdit: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddTaskSheet(
                  editingTask: task,
                  showDateControls: false,
                  onAdd: (_, __) {},
                  onUpdate: (updatedTask) => _updateTaskWithOverlapCheck(
                    context.read<ScheduleStateProvider>(),
                    task.id,
                    updatedTask,
                  ),
                ),
              );
            },
            onDelete: () {
              context.read<ScheduleStateProvider>().deleteTask(task.id);
              Navigator.pop(context);
            },
            onClose: () => Navigator.pop(context),
          ),
        ),
      ).then((_) {
        // Clear selection if they somehow interacted with both UI elements
        if (_selectedTask != null) _closeTaskDetail();
      });
    } else {
      setState(() {
        _selectedTask = task;
      });
    }
  }

  void _closeTaskDetail() {
    setState(() {
      _selectedTask = null;
    });
  }

  /// Adds a task and, if it collides with existing tasks on that day, surfaces
  /// a non-blocking warning so the user can spot accidental double-booking.
  void _addTaskWithOverlapCheck(
    ScheduleStateProvider provider,
    Task task,
    DateTime date,
  ) {
    final overlaps = provider.overlappingTasks(task, date);
    provider.addTask(task, date);
    if (overlaps.isNotEmpty && mounted) {
      final first = overlaps.first;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceLight,
          content: Text(
            overlaps.length == 1
                ? 'Heads up: overlaps with "${first.title}" (${first.startTime}–${first.endTime})'
                : 'Heads up: overlaps with ${overlaps.length} other tasks',
          ),
        ),
      );
    }
  }

  /// Mirrors the add-path overlap warning for edits, excluding the task's own
  /// previous slot so it never flags against itself.
  void _updateTaskWithOverlapCheck(
    ScheduleStateProvider provider,
    String taskId,
    Task updatedTask,
  ) {
    final overlaps = provider.overlappingTasks(
      updatedTask,
      provider.selectedDay.date,
      excludeId: taskId,
    );
    provider.updateTask(taskId, updatedTask);
    if (overlaps.isNotEmpty && mounted) {
      final first = overlaps.first;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceLight,
          content: Text(
            overlaps.length == 1
                ? 'Heads up: overlaps with "${first.title}" (${first.startTime}–${first.endTime})'
                : 'Heads up: overlaps with ${overlaps.length} other tasks',
          ),
        ),
      );
    }
  }

  void _addTaskToDatesWithOverlapCheck(
    ScheduleStateProvider provider,
    Task task,
    List<DateTime> dates,
  ) {
    if (dates.isEmpty) return;

    var overlapCount = 0;
    Task? firstOverlap;

    for (var i = 0; i < dates.length; i++) {
      final datedTask = i == 0 ? task : task.copyWith(id: const Uuid().v4());
      final overlaps = provider.overlappingTasks(datedTask, dates[i]);
      overlapCount += overlaps.length;
      firstOverlap ??= overlaps.isNotEmpty ? overlaps.first : null;
      provider.addTask(datedTask, dates[i]);
    }

    if (!mounted) return;

    final overlapText = overlapCount == 0
        ? ''
        : '; $overlapCount overlap${overlapCount == 1 ? '' : 's'} found'
            '${firstOverlap == null ? '' : ' including "${firstOverlap.title}"'}';

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceLight,
        content: Text(
          'Added "${task.title}" to ${dates.length} days$overlapText',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleStateProvider>(context);

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.neonBlue),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: provider.loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final dayPlan = provider.selectedDay;
    final sortedTasks = provider.getSortedTasks(dayPlan);

    return Stack(
      children: [
        // Ambient Background Glows
        Positioned(
          top: -100,
          right: -50,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonPurple.withValues(alpha: 0.15),
              ),
            ),
          ),
        ),
        Positioned(
          top: 100,
          left: -100,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonBlue.withValues(alpha: 0.15),
              ),
            ),
          ),
        ),

        Column(
          children: [
            const SizedBox(height: 10),

            // ── Day Selector (Adaptive Width) ──
            SizedBox(
              height: 90,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  final narrowItemWidth =
                      (constraints.maxWidth - 32 - (8 * 4)) / 5.5;
                  final itemWidth =
                      isWide ? 70.0 : narrowItemWidth.clamp(45.0, 70.0);

                  Widget buildDayCard(int index) {
                    final day = provider.weekPlan[index];
                    final isSelected = index == provider.selectedDayIndex;
                    final hasTasks = day.tasks.isNotEmpty;
                    final completedCount =
                        day.tasks.where((t) => t.completed).length;
                    final progress =
                        hasTasks ? completedCount / day.tasks.length : 0.0;

                    return Semantics(
                      button: true,
                      selected: isSelected,
                      label:
                          '${day.dayOfWeek}, ${day.dateStr}, $completedCount of ${day.tasks.length} tasks completed',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => provider.selectDay(index),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          focusColor:
                              AppColors.neonBlue.withValues(alpha: 0.15),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            width: itemWidth,
                            margin: EdgeInsets.only(right: index == 6 ? 0 : 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.neonBlue,
                                        Color(0xFF6366F1),
                                      ],
                                    )
                                  : null,
                              color: isSelected ? null : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : AppColors.glassBorder,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.neonBlue
                                            .withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  day.dayOfWeek.substring(0, 3).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  day.dateStr.split(' ').length > 1
                                      ? day.dateStr.split(' ')[1]
                                      : day.dateStr,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (isSelected && hasTasks)
                                  SizedBox(
                                    width: 24,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: Colors.black26,
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                        minHeight: 3,
                                      ),
                                    ),
                                  )
                                else if (!isSelected && hasTasks)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: AppColors.neonPurple,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                else
                                  const SizedBox(height: 5),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  if (isWide) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:
                          List.generate(7, (index) => buildDayCard(index)),
                    );
                  } else {
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: 7,
                      itemBuilder: (context, index) => buildDayCard(index),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Header Area ─────────────────────────
            Padding(
              padding: AppResponsive.horizontalPadding(context),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 520;
                  final titleBlock = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayPlan.dayOfWeek.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: AppColors.neonBlue.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayPlan.dateStr,
                        style: TextStyle(
                          fontSize: isCompact ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  );
                  final toolbar = _ScheduleToolbar(
                    provider: provider,
                    currentViewMode: _currentViewMode,
                    onToggleViewMode: _toggleViewMode,
                    onSearch: () => _showWeekSearch(provider),
                    onAddTask: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => AddTaskSheet(
                          defaultDate: dayPlan.date,
                          availableDates:
                              provider.weekPlan.map((day) => day.date).toList(),
                          onAdd: (t, d) => _addTaskWithOverlapCheck(
                            provider,
                            t,
                            d,
                          ),
                          onAddToDates: (t, dates) =>
                              _addTaskToDatesWithOverlapCheck(
                            provider,
                            t,
                            dates,
                          ),
                        ),
                      );
                    },
                    onSaveTemplate: () =>
                        _showSaveTemplateDialog(context, provider),
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleBlock,
                        const SizedBox(height: AppSpacing.md),
                        toolbar,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: titleBlock),
                      const SizedBox(width: AppSpacing.md),
                      toolbar,
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ── Task List ──
            Expanded(
              child: Stack(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity.abs() < 300) return;
                      final current = provider.selectedDayIndex;
                      if (velocity < 0 &&
                          current < provider.weekPlan.length - 1) {
                        provider.selectDay(current + 1);
                      } else if (velocity > 0 && current > 0) {
                        provider.selectDay(current - 1);
                      }
                    },
                    child: sortedTasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface
                                        .withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_outlined,
                                    size: 48,
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No plans for ${dayPlan.dayOfWeek}',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 800;

                              Widget buildTaskCard(int index) {
                                final task = sortedTasks[index];
                                return TaskCard(
                                  task: task,
                                  viewMode: _currentViewMode,
                                  onToggle: () => provider.updateTask(
                                    task.id,
                                    task.copyWith(
                                      completed: !task.completed,
                                    ),
                                  ),
                                  onDelete: () {
                                    provider.deleteTask(task.id);
                                    ScaffoldMessenger.of(context)
                                        .clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Deleted "${task.title}"'),
                                        action: SnackBarAction(
                                          label: 'UNDO',
                                          textColor: AppColors.neonBlue,
                                          onPressed: () => provider.undo(),
                                        ),
                                      ),
                                    );
                                  },
                                  onEdit: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => AddTaskSheet(
                                        editingTask: task,
                                        showDateControls: false,
                                        onAdd: (_, __) {},
                                        onUpdate: (updatedTask) =>
                                            _updateTaskWithOverlapCheck(
                                          provider,
                                          task.id,
                                          updatedTask,
                                        ),
                                      ),
                                    );
                                  },
                                  onDuplicate: () {
                                    final duplicate = task.copyWith(
                                      id: const Uuid().v4(),
                                      completed: false,
                                    );
                                    provider.addTask(duplicate);
                                  },
                                  onTap: () => _openTaskDetail(task),
                                );
                              }

                              if (isWide &&
                                  _currentViewMode == TaskCardViewMode.card) {
                                return SingleChildScrollView(
                                  padding: EdgeInsets.fromLTRB(
                                    AppResponsive.pagePadding(context),
                                    0,
                                    AppResponsive.pagePadding(context),
                                    100,
                                  ),
                                  physics: const BouncingScrollPhysics(),
                                  child: Wrap(
                                    spacing: 16,
                                    runSpacing:
                                        0, // TaskCard already has bottom margin
                                    children: List.generate(sortedTasks.length,
                                        (index) {
                                      final cols =
                                          constraints.maxWidth >= 1200 ? 3 : 2;
                                      final horizontalPadding =
                                          AppResponsive.pagePadding(context) *
                                              2;
                                      final cardWidth = (constraints.maxWidth -
                                              horizontalPadding -
                                              (16 * (cols - 1))) /
                                          cols;
                                      return SizedBox(
                                        width: cardWidth -
                                            1, // Subtract 1 pixel to prevent rounding errors causing wrap
                                        child: buildTaskCard(index),
                                      );
                                    }),
                                  ),
                                );
                              } else {
                                return ListView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    AppResponsive.pagePadding(context),
                                    0,
                                    AppResponsive.pagePadding(context),
                                    100,
                                  ),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: sortedTasks.length,
                                  itemBuilder: (context, index) =>
                                      buildTaskCard(index),
                                );
                              }
                            },
                          ),
                  ),

                  // Task Detail Panel
                  if (_selectedTask != null) ...[
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _closeTaskDetail,
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: SizedBox(
                        width: math
                            .min(
                              420,
                              MediaQuery.sizeOf(context).width * 0.88,
                            )
                            .toDouble(),
                        child: TaskDetailPanel(
                          task: _selectedTask!,
                          isCompleted: _selectedTask!.completed,
                          onToggle: () {
                            provider.updateTask(
                              _selectedTask!.id,
                              _selectedTask!.copyWith(
                                completed: !_selectedTask!.completed,
                              ),
                            );
                            _closeTaskDetail();
                          },
                          onEdit: () {
                            final editingTask = _selectedTask!;
                            _closeTaskDetail();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => AddTaskSheet(
                                editingTask: editingTask,
                                showDateControls: false,
                                onAdd: (_, __) {},
                                onUpdate: (updatedTask) =>
                                    _updateTaskWithOverlapCheck(
                                  provider,
                                  editingTask.id,
                                  updatedTask,
                                ),
                              ),
                            );
                          },
                          onDelete: () {
                            provider.deleteTask(_selectedTask!.id);
                            _closeTaskDetail();
                          },
                          onClose: _closeTaskDetail,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showWeekSearch(ScheduleStateProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => _WeekSearchDialog(
        provider: provider,
        onSelect: (dayIndex, task) {
          Navigator.pop(ctx);
          provider.selectDay(dayIndex);
          _openTaskDetail(task);
        },
      ),
    );
  }

  void _showSaveTemplateDialog(
    BuildContext context,
    ScheduleStateProvider provider,
  ) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Save Day as Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Template Name'),
              autofocus: true,
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              final currentTasks = provider.selectedDay.tasks;
              final templateId = const Uuid().v4();

              final template = PlanTemplate(
                id: templateId,
                name: name,
                description: descCtrl.text.trim(),
                tasks: currentTasks
                    .map(
                      (t) => TemplateTask(
                        id: const Uuid().v4(),
                        templateId: templateId,
                        title: t.title,
                        startTime: t.startTime,
                        endTime: t.endTime,
                        type: t.type,
                        priority: t.priority,
                        energyLevel: t.energyLevel,
                        estimatedCost: t.estimatedCost,
                        description: t.description,
                      ),
                    )
                    .toList(),
              );

              provider.addTemplate(template);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Template "$name" saved')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: color),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

/// Searches every task across the loaded week; selecting a result jumps to
/// that day and opens the task's detail view.
class _WeekSearchDialog extends StatefulWidget {
  final ScheduleStateProvider provider;
  final void Function(int dayIndex, Task task) onSelect;

  const _WeekSearchDialog({required this.provider, required this.onSelect});

  @override
  State<_WeekSearchDialog> createState() => _WeekSearchDialogState();
}

class _WeekSearchDialogState extends State<_WeekSearchDialog> {
  String _query = '';

  List<(int, Task)> get _matches {
    if (_query.isEmpty) return const [];
    final q = _query.toLowerCase();
    final results = <(int, Task)>[];
    for (var i = 0; i < widget.provider.weekPlan.length; i++) {
      for (final task in widget.provider.weekPlan[i].tasks) {
        if (task.title.toLowerCase().contains(q) ||
            task.description.toLowerCase().contains(q)) {
          results.add((i, task));
        }
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v.trim()),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search this week\'s tasks…',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: _query.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'Type to search across all 7 days',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : matches.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: Text(
                              'No matching tasks',
                              style: TextStyle(color: Colors.white38),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: matches.length,
                            itemBuilder: (context, index) {
                              final (dayIdx, task) = matches[index];
                              final day = widget.provider.weekPlan[dayIdx];
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  task.completed
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: task.completed
                                      ? AppColors.neonBlue
                                      : Colors.white38,
                                ),
                                title: Text(
                                  task.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  '${day.dayOfWeek} · ${task.startTime}–${task.endTime}',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () => widget.onSelect(dayIdx, task),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleToolbar extends StatelessWidget {
  final ScheduleStateProvider provider;
  final TaskCardViewMode currentViewMode;
  final VoidCallback onToggleViewMode;
  final VoidCallback onAddTask;
  final VoidCallback onSaveTemplate;
  final VoidCallback onSearch;

  const _ScheduleToolbar({
    required this.provider,
    required this.currentViewMode,
    required this.onToggleViewMode,
    required this.onAddTask,
    required this.onSaveTemplate,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (provider.canUndo)
              _ActionButton(
                icon: Icons.undo,
                color: AppColors.neonBlue,
                onTap: () {
                  provider.undo();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Action undone'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Undo',
              ),
            if (provider.canUndo) const SizedBox(width: 4),
            _ActionButton(
              icon: Icons.search_rounded,
              color: AppColors.neonCyan,
              onTap: onSearch,
              tooltip: 'Search This Week',
            ),
            const SizedBox(width: 4),
            _ActionButton(
              icon: provider.sortOrder == SortOrder.asc
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: AppColors.neonCyan,
              onTap: provider.toggleSortOrder,
              tooltip: provider.sortOrder == SortOrder.asc
                  ? 'Sorted: Earliest First'
                  : 'Sorted: Latest First',
            ),
            const SizedBox(width: 4),
            _ActionButton(
              icon: Icons.save_outlined,
              color: AppColors.neonPurple,
              onTap: onSaveTemplate,
              tooltip: 'Save Template',
            ),
            const SizedBox(width: 4),
            _ActionButton(
              icon: currentViewMode == TaskCardViewMode.card
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
              color: AppColors.neonPurple,
              onTap: onToggleViewMode,
              tooltip: currentViewMode == TaskCardViewMode.card
                  ? 'Switch to List View'
                  : 'Switch to Card View',
            ),
            const SizedBox(width: 4),
            Container(
              width: 1,
              height: 24,
              color: Colors.white10,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            Tooltip(
              message: 'Add Task',
              child: TextButton.icon(
                onPressed: onAddTask,
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text(
                  'ADD TASK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.neonBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
