import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/schedule_provider.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/glass_container.dart';
import '../widgets/task_card.dart';

class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.neonBlue),
      );
    }

    final dayPlan = provider.selectedDay;
    final sortedTasks = dayPlan.tasks;

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
            // Day Selector
            SizedBox(
              height: 110,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                scrollDirection: Axis.horizontal,
                itemCount: provider.weekPlan.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final day = provider.weekPlan[index];
                  final isSelected = index == provider.selectedDayIndex;
                  final hasTasks = day.tasks.isNotEmpty;
                  final completedCount =
                      day.tasks.where((t) => t.completed).length;
                  final progress =
                      hasTasks ? completedCount / day.tasks.length : 0.0;

                  return GestureDetector(
                    onTap: () => provider.selectDay(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: 75,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.neonBlue, Color(0xFF6366F1)],
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.surface.withValues(alpha: 0.8),
                                  AppColors.surface.withValues(alpha: 0.5),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : AppColors.glassBorder,
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color: AppColors.neonBlue
                                        .withValues(alpha: 0.5),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8)),
                                BoxShadow(
                                    color: AppColors.neonBlue
                                        .withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2)),
                              ]
                            : [],
                      ),
                      child: Stack(
                        children: [
                          if (!isSelected && hasTasks)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                      color: AppColors.neonPurple,
                                      shape: BoxShape.circle),
                                ),
                              ),
                            ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  day.dayOfWeek,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  day.dateStr.split(' ')[1],
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected && hasTasks)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(24)),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.black12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  minHeight: 4,
                                ),
                              ),
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Header Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayPlan.dayOfWeek.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: AppColors.neonBlue.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayPlan.dateStr,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  // Action Toolbar
                  GlassContainer(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Undo button (visible when undo stack is not empty)
                        if (provider.canUndo)
                          _ActionButton(
                            icon: Icons.undo,
                            color: AppColors.neonBlue,
                            onTap: () {
                              final didUndo = provider.undo();
                              if (didUndo) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Action undone"),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            tooltip: 'Undo',
                          ),
                        if (provider.canUndo) const SizedBox(width: 4),
                        _ActionButton(
                          icon: Icons.save_outlined,
                          color: AppColors.neonPurple,
                          onTap: () =>
                              _showSaveTemplateDialog(context, provider),
                          tooltip: 'Save Template',
                        ),
                        const SizedBox(width: 4),
                        _ActionButton(
                          icon: Icons.delete_outline,
                          color: Colors.redAccent.shade200,
                          onTap: () => _confirmClearDay(context, provider),
                          tooltip: 'Clear Day',
                        ),
                        Container(
                            width: 1,
                            height: 24,
                            color: Colors.white10,
                            margin: const EdgeInsets.symmetric(horizontal: 8)),
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => AddTaskSheet(
                                  onAdd: (t) => provider.addTask(t)),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.neonBlue,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.neonBlue
                                        .withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Task List
            Expanded(
              child: sortedTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.calendar_today_outlined,
                                size: 48,
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          const SizedBox(height: 24),
                          Text("No plans for ${dayPlan.dayOfWeek}",
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 16)),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Go to WorkPlans to apply a template!")),
                              );
                            },
                            icon: const Icon(Icons.layers_outlined, size: 16),
                            label: const Text("Browse Templates"),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.neonBlue),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      physics: const BouncingScrollPhysics(),
                      itemCount: sortedTasks.length,
                      itemBuilder: (context, index) {
                        final task = sortedTasks[index];
                        return TaskCard(
                          task: task,
                          onToggle: () => provider.toggleTaskComplete(task.id),
                          onDelete: () {
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
                                duration: const Duration(seconds: 4),
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
                                onAdd: (_) {},
                                onUpdate: (updatedTask) =>
                                    provider.updateTask(task.id, updatedTask),
                              ),
                            );
                          },
                          onDuplicate: () {
                            final duplicate = task.copyWith(
                              id: const Uuid().v4(),
                              completed: false,
                            );
                            provider.addTask(duplicate);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Duplicated "${task.title}"')),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmClearDay(BuildContext context, ScheduleProvider provider) {
    if (provider.selectedDay.tasks.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Clear All Tasks?",
            style: TextStyle(color: Colors.white)),
        content: Text(
          "This will remove all ${provider.selectedDay.tasks.length} tasks from ${provider.selectedDay.dayOfWeek}. You can undo this action.",
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              provider.clearDay();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Day cleared"),
                  action: SnackBarAction(
                    label: 'UNDO',
                    textColor: AppColors.neonBlue,
                    onPressed: () => provider.undo(),
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            child: const Text("Clear", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSaveTemplateDialog(
      BuildContext context, ScheduleProvider provider) {
    if (provider.selectedDay.tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Cannot save an empty day as a template.")));
      return;
    }

    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Save as Template",
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Template Name",
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Description",
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                provider.saveCurrentDayAsTemplate(nameCtrl.text, descCtrl.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Template saved successfully!")));
              }
            },
            child: const Text("Save",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
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

  const _ActionButton(
      {required this.icon,
      required this.color,
      required this.onTap,
      required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: color),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
