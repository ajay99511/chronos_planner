import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:chronosky/core/theme/app_theme.dart';
import 'package:chronosky/data/models/day_plan_model.dart';
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

  /// The provider this screen is listening to, so the listener can be removed
  /// again. Error reporting is driven from here rather than from build():
  /// showing a snackbar is a side effect, and build may run for reasons that
  /// have nothing to do with a state change -- a theme switch, a media query
  /// change, a hot reload.
  ScheduleStateProvider? _observed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<ScheduleStateProvider>();
    if (provider != _observed) {
      _observed?.removeListener(_onProviderChanged);
      _observed = provider..addListener(_onProviderChanged);
    }
  }

  @override
  void dispose() {
    _observed?.removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() {
    final provider = _observed;
    if (provider != null) _consumeTransientError(provider);
  }

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

  /// Shows a one-shot snackbar for any operation-level failure (e.g. a failed
  /// task write) without replacing the whole screen. The provider rolls back
  /// the optimistic change itself; this only surfaces the error to the user.
  void _consumeTransientError(ScheduleStateProvider provider) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final error = provider.takeTransientError();
      if (error == null) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surfaceLight,
          content: Text("Couldn't save that change. Please try again."),
        ),
      );
    });
  }

  /// Opens the add-task sheet for [dayPlan].
  void _openAddTaskSheet(ScheduleStateProvider provider, DayPlan dayPlan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        defaultDate: dayPlan.date,
        availableDates: provider.weekPlan.map((day) => day.date).toList(),
        onAdd: (t, d) => _addTaskWithOverlapCheck(provider, t, d),
        onAddToDates: (t, dates) =>
            _addTaskToDatesWithOverlapCheck(provider, t, dates),
      ),
    );
  }

  void _openEditTaskSheet(ScheduleStateProvider provider, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        editingTask: task,
        showDateControls: false,
        onAdd: (_, __) {},
        onUpdate: (updatedTask) =>
            _updateTaskWithOverlapCheck(provider, task.id, updatedTask),
      ),
    );
  }

  /// Deletes [task] and offers an undo, which is the only route back.
  void _deleteTaskWithUndo(ScheduleStateProvider provider, Task task) {
    provider.deleteTask(task.id);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${task.title}"'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.neonBlue,
          onPressed: () => provider.undo(),
        ),
      ),
    );
  }

  _TaskActions _taskActions(ScheduleStateProvider provider) => _TaskActions(
        onToggle: (task) => provider.updateTask(
          task.id,
          task.copyWith(completed: !task.completed),
        ),
        onDelete: (task) => _deleteTaskWithUndo(provider, task),
        onEdit: (task) => _openEditTaskSheet(provider, task),
        onDuplicate: (task) => provider.addTask(
          task.copyWith(id: const Uuid().v4(), completed: false),
        ),
        onTap: _openTaskDetail,
      );

  @override
  Widget build(BuildContext context) {
    // read, not watch: this method supplies callbacks and layout only. Each
    // section below subscribes to the slice of state it actually renders, so
    // a task toggle no longer rebuilds the whole screen.
    final provider = context.read<ScheduleStateProvider>();

    return Selector<ScheduleStateProvider, _ScheduleStatus>(
      selector: (_, p) => _ScheduleStatus(
        isLoading: p.isLoading,
        error: p.errorMessage,
      ),
      builder: (context, status, _) {
        if (status.isLoading) return const _ScheduleLoading();
        if (status.error != null) {
          return _ScheduleErrorView(
            message: status.error!,
            onRetry: provider.loadData,
          );
        }
        return _buildLoaded(context, provider);
      },
    );
  }

  Widget _buildLoaded(BuildContext context, ScheduleStateProvider provider) {
    return Stack(
      children: [
        // Static decoration: isolated so the expensive blur does not repaint
        // with the schedule above it.
        const RepaintBoundary(child: _AmbientGlowBackdrop()),
        Column(
          children: [
            const SizedBox(height: 10),
            Selector<ScheduleStateProvider, _DayStripData>(
              selector: (_, p) => _DayStripData(
                days: p.weekPlan,
                selectedIndex: p.selectedDayIndex,
              ),
              builder: (context, data, _) => _DaySelectorStrip(
                weekPlan: data.days,
                selectedIndex: data.selectedIndex,
                onSelect: provider.selectDay,
              ),
            ),
            const SizedBox(height: 16),
            _ScheduleHeader(
              provider: provider,
              currentViewMode: _currentViewMode,
              onToggleViewMode: _toggleViewMode,
              onSearch: () => _showWeekSearch(provider),
              // Resolved when tapped, not when built: the selected day can
              // change between the two.
              onAddTask: () =>
                  _openAddTaskSheet(provider, provider.selectedDay),
              onSaveTemplate: () => _showSaveTemplateDialog(context, provider),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Stack(
                children: [
                  Selector<ScheduleStateProvider, _TaskListData>(
                    // _currentViewMode is widget state, but it has to take
                    // part in the comparison: Selector returns its cached
                    // child when the selected value is unchanged, so a value
                    // only captured in the closure would stop propagating.
                    selector: (_, p) {
                      final day = p.selectedDay;
                      return _TaskListData(
                        tasks: p.getSortedTasks(day),
                        dayLabel: day.dayOfWeek,
                        viewMode: _currentViewMode,
                      );
                    },
                    builder: (context, data, _) => _TaskListArea(
                      tasks: data.tasks,
                      dayLabel: data.dayLabel,
                      viewMode: data.viewMode,
                      actions: _taskActions(provider),
                      onSwipe: (delta) {
                        final next = provider.selectedDayIndex + delta;
                        if (next >= 0 && next < provider.weekPlan.length) {
                          provider.selectDay(next);
                        }
                      },
                    ),
                  ),
                  if (_selectedTask != null)
                    _TaskDetailOverlay(
                      task: _selectedTask!,
                      onDismiss: _closeTaskDetail,
                      onToggle: () {
                        provider.updateTask(
                          _selectedTask!.id,
                          _selectedTask!
                              .copyWith(completed: !_selectedTask!.completed),
                        );
                        _closeTaskDetail();
                      },
                      onEdit: () {
                        final editingTask = _selectedTask!;
                        _closeTaskDetail();
                        _openEditTaskSheet(provider, editingTask);
                      },
                      onDelete: () {
                        provider.deleteTask(_selectedTask!.id);
                        _closeTaskDetail();
                      },
                    ),
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
      // These controllers outlive the builder closure, so they have to be
      // released when the route pops — otherwise every open of this dialog
      // leaks two ChangeNotifiers and their IME connections, which matters in
      // a desktop session designed to stay open for days.
    ).whenComplete(() {
      nameCtrl.dispose();
      descCtrl.dispose();
    });
  }
}

/// Loading/error slice of the schedule, so the status band rebuilds on its
/// own rather than dragging the whole screen with it.
@immutable
class _ScheduleStatus {
  const _ScheduleStatus({required this.isLoading, required this.error});

  final bool isLoading;
  final String? error;

  @override
  bool operator ==(Object other) =>
      other is _ScheduleStatus &&
      isLoading == other.isLoading &&
      error == other.error;

  @override
  int get hashCode => Object.hash(isLoading, error);
}

/// Day-strip inputs.
///
/// Equality is by content, not identity: ScheduleStateProvider assigns into
/// `_weekPlan` in place, so the list instance often stays the same across a
/// real change and an identity comparison would skip the rebuild.
@immutable
class _DayStripData {
  const _DayStripData({required this.days, required this.selectedIndex});

  final List<DayPlan> days;
  final int selectedIndex;

  @override
  bool operator ==(Object other) =>
      other is _DayStripData &&
      selectedIndex == other.selectedIndex &&
      listEquals(days, other.days);

  @override
  int get hashCode => Object.hash(selectedIndex, Object.hashAll(days));
}

/// Task-list inputs, including the widget-level view mode so a mode switch
/// invalidates the Selector's cached child.
@immutable
class _TaskListData {
  const _TaskListData({
    required this.tasks,
    required this.dayLabel,
    required this.viewMode,
  });

  final List<Task> tasks;
  final String dayLabel;
  final TaskCardViewMode viewMode;

  @override
  bool operator ==(Object other) =>
      other is _TaskListData &&
      dayLabel == other.dayLabel &&
      viewMode == other.viewMode &&
      listEquals(tasks, other.tasks);

  @override
  int get hashCode =>
      Object.hash(dayLabel, viewMode, Object.hashAll(tasks));
}

/// The five things a task card can do, grouped so [_TaskListArea] does not
/// need five separate callback parameters.
@immutable
class _TaskActions {
  const _TaskActions({
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onDuplicate,
    required this.onTap,
  });

  final void Function(Task task) onToggle;
  final void Function(Task task) onDelete;
  final void Function(Task task) onEdit;
  final void Function(Task task) onDuplicate;
  final void Function(Task task) onTap;
}

class _ScheduleLoading extends StatelessWidget {
  const _ScheduleLoading();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: AppColors.neonBlue),
      );
}

class _ScheduleErrorView extends StatelessWidget {
  const _ScheduleErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Ambient background glows. Depends on nothing, so a const instance lets
/// Flutter skip rebuilding it entirely.
class _AmbientGlowBackdrop extends StatelessWidget {
  const _AmbientGlowBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: -100, right: -50, child: _glow(AppColors.neonPurple)),
        Positioned(top: 100, left: -100, child: _glow(AppColors.neonBlue)),
      ],
    );
  }

  Widget _glow(Color color) => ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
          ),
        ),
      );
}

/// Horizontal strip of day cards for the rolling window.
class _DaySelectorStrip extends StatelessWidget {
  const _DaySelectorStrip({
    required this.weekPlan,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<DayPlan> weekPlan;
  final int selectedIndex;
  final void Function(int index) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          final narrowItemWidth = (constraints.maxWidth - 32 - (8 * 4)) / 5.5;
          final itemWidth = isWide ? 70.0 : narrowItemWidth.clamp(45.0, 70.0);
          final lastIndex = weekPlan.length - 1;

          if (isWide) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < weekPlan.length; i++)
                  _DayCard(
                    day: weekPlan[i],
                    isSelected: i == selectedIndex,
                    width: itemWidth,
                    isLast: i == lastIndex,
                    onTap: () => onSelect(i),
                  ),
              ],
            );
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: weekPlan.length,
            itemBuilder: (context, index) => _DayCard(
              day: weekPlan[index],
              isSelected: index == selectedIndex,
              width: itemWidth,
              isLast: index == lastIndex,
              onTap: () => onSelect(index),
            ),
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.isSelected,
    required this.width,
    required this.isLast,
    required this.onTap,
  });

  final DayPlan day;
  final bool isSelected;
  final double width;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasTasks = day.tasks.isNotEmpty;
    final completedCount = day.tasks.where((t) => t.completed).length;
    final progress = hasTasks ? completedCount / day.tasks.length : 0.0;
    final shortDate = day.dateStr.split(' ').length > 1
        ? day.dateStr.split(' ')[1]
        : day.dateStr;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${day.dayOfWeek}, ${day.dateStr}, $completedCount of '
          '${day.tasks.length} tasks completed',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          focusColor: AppColors.neonBlue.withValues(alpha: 0.15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: width,
            margin: EdgeInsets.only(right: isLast ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.neonBlue, Color(0xFF6366F1)],
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
                        color: AppColors.neonBlue.withValues(alpha: 0.4),
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
                  shortDate,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
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
                        color: Colors.white.withValues(alpha: 0.8),
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
}

/// Selected day's title block plus the toolbar, stacking on narrow widths.
class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({
    required this.provider,
    required this.currentViewMode,
    required this.onToggleViewMode,
    required this.onSearch,
    required this.onAddTask,
    required this.onSaveTemplate,
  });

  final ScheduleStateProvider provider;
  final TaskCardViewMode currentViewMode;
  final VoidCallback onToggleViewMode;
  final VoidCallback onSearch;
  final VoidCallback onAddTask;
  final VoidCallback onSaveTemplate;

  @override
  Widget build(BuildContext context) {
    // Watched rather than selected: the toolbar reflects sortOrder and
    // canUndo as well as the day, and a title plus a button row is cheap to
    // rebuild. The expensive sections above and below use Selectors instead.
    final dayPlan = context.watch<ScheduleStateProvider>().selectedDay;
    return Padding(
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
            currentViewMode: currentViewMode,
            onToggleViewMode: onToggleViewMode,
            onSearch: onSearch,
            onAddTask: onAddTask,
            onSaveTemplate: onSaveTemplate,
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
    );
  }
}

/// Task list for the selected day: a wrapped grid on wide card layouts, a
/// plain list otherwise, with an empty state and horizontal day swiping.
class _TaskListArea extends StatelessWidget {
  const _TaskListArea({
    required this.tasks,
    required this.dayLabel,
    required this.viewMode,
    required this.actions,
    required this.onSwipe,
  });

  final List<Task> tasks;
  final String dayLabel;
  final TaskCardViewMode viewMode;
  final _TaskActions actions;

  /// Called with -1 or 1 when the user swipes to an adjacent day.
  final void Function(int delta) onSwipe;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() < 300) return;
        onSwipe(velocity < 0 ? 1 : -1);
      },
      child: tasks.isEmpty ? _EmptyDay(dayLabel: dayLabel) : _buildList(),
    );
  }

  Widget _buildList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pagePadding = AppResponsive.pagePadding(context);
        final padding = EdgeInsets.fromLTRB(pagePadding, 0, pagePadding, 100);
        final isWide = constraints.maxWidth >= 800;

        if (isWide && viewMode == TaskCardViewMode.card) {
          final cols = constraints.maxWidth >= 1200 ? 3 : 2;
          final cardWidth =
              (constraints.maxWidth - pagePadding * 2 - (16 * (cols - 1))) /
                  cols;
          return SingleChildScrollView(
            padding: padding,
            physics: const BouncingScrollPhysics(),
            child: Wrap(
              spacing: 16,
              // TaskCard already carries a bottom margin.
              runSpacing: 0,
              children: [
                for (final task in tasks)
                  SizedBox(
                    // One pixel narrower, so rounding cannot force an extra
                    // wrap and drop a card onto its own row.
                    width: cardWidth - 1,
                    child: _card(task),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: padding,
          physics: const BouncingScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) => _card(tasks[index]),
        );
      },
    );
  }

  Widget _card(Task task) => TaskCard(
        task: task,
        viewMode: viewMode,
        onToggle: () => actions.onToggle(task),
        onDelete: () => actions.onDelete(task),
        onEdit: () => actions.onEdit(task),
        onDuplicate: () => actions.onDuplicate(task),
        onTap: () => actions.onTap(task),
      );
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.dayLabel});

  final String dayLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
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
            'No plans for $dayLabel',
            style: const TextStyle(color: Colors.white60, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/// Side panel shown over the schedule on wide layouts, with a tap-to-dismiss
/// scrim behind it.
class _TaskDetailOverlay extends StatelessWidget {
  const _TaskDetailOverlay({
    required this.task,
    required this.onDismiss,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onDismiss;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(
            width: math
                .min(420, MediaQuery.sizeOf(context).width * 0.88)
                .toDouble(),
            child: TaskDetailPanel(
              task: task,
              isCompleted: task.completed,
              onToggle: onToggle,
              onEdit: onEdit,
              onDelete: onDelete,
              onClose: onDismiss,
            ),
          ),
        ),
      ],
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
