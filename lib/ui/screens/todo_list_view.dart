import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/todo_provider.dart';
import '../../data/local/app_database.dart';
import 'todo_detail_screen.dart';
import 'timer_view.dart';
import '../widgets/new_item_sheet.dart';

class TodoListView extends StatefulWidget {
  const TodoListView({super.key});

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  int _selectedTab = 0; // 0 = Notes, 1 = Timers, 2 = Lists

  void _openNewItemSheet() {
    NewItemSheet.show(context, initialTab: _selectedTab);
  }

  void _openNote(TodoItem item) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TodoDetailScreen(todo: item),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut));
          return FadeTransition(opacity: fadeAnimation, child: child);
        },
      ),
    );
  }

  void _openTimer(TodoItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TimerView(timer: item)),
    );
  }

  void _openListDetail(TodoItem item) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TodoDetailScreen(todo: item),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut));
          return FadeTransition(opacity: fadeAnimation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tasks', style: AppTextStyles.heading1),
                    const SizedBox(height: 4),
                    Text('Your workspace canvas',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryBlue,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow:
                        AppShadows.neonGlow(AppColors.neonBlue, intensity: 0.3),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _openNewItemSheet,
                  ),
                ),
              ],
            ),
          ),

          // Tab selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _buildTabSelector(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Content
          Expanded(
            child: Consumer<TodoProvider>(
              builder: (context, provider, _) {
                switch (_selectedTab) {
                  case 0:
                    return _buildNotesList(provider.notes);
                  case 1:
                    return _buildTimersList(provider.timers);
                  case 2:
                    return _buildChecklistsList(provider.lists);
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    const tabs = [
      (icon: Icons.description_outlined, label: 'Notes'),
      (icon: Icons.timer_outlined, label: 'Timers'),
      (icon: Icons.checklist_outlined, label: 'Lists'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: AppAnimDurations.fast,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.surfaceLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabs[i].icon,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      tabs[i].label,
                      style: AppTextStyles.body.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Notes List ──
  Widget _buildNotesList(List<TodoItem> notes) {
    if (notes.isEmpty) {
      return _buildEmptyState(
          Icons.description_outlined, 'No notes found.\nCreate a new one!');
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.1,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _NoteCard(
          todo: note,
          onTap: () => _openNote(note),
          onToggle: () =>
              context.read<TodoProvider>().toggleTodo(note),
        );
      },
    );
  }

  // ── Timers List ──
  Widget _buildTimersList(List<TodoItem> timers) {
    if (timers.isEmpty) {
      return _buildEmptyState(
          Icons.timer_outlined, 'No timers found.\nCreate a new one!');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      itemCount: timers.length,
      itemBuilder: (context, index) {
        final timer = timers[index];
        return _TimerCard(
          timer: timer,
          onTap: () => _openTimer(timer),
          onDelete: () =>
              context.read<TodoProvider>().deleteTodo(timer.id),
        );
      },
    );
  }

  // ── Checklists (Lists) ──
  Widget _buildChecklistsList(List<TodoItem> lists) {
    if (lists.isEmpty) {
      return _buildEmptyState(
          Icons.checklist_outlined, 'No lists found.\nCreate a new one!');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        return _ListCard(
          listItem: list,
          onTap: () => _openListDetail(list),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.white24),
          const SizedBox(height: AppSpacing.md),
          Text(text,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 16)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Note Card (matches existing design)
// ─────────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _NoteCard({
    required this.todo,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    todo.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading3.copyWith(
                      decoration:
                          todo.completed ? TextDecoration.lineThrough : null,
                      color: todo.completed
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    margin: const EdgeInsets.only(left: AppSpacing.sm),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: todo.completed
                            ? AppColors.neonBlue
                            : Colors.white38,
                        width: 2,
                      ),
                      color: todo.completed
                          ? AppColors.neonBlue
                          : Colors.transparent,
                    ),
                    child: todo.completed
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),
            if (todo.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: Text(
                  todo.description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ] else ...[
              const Spacer(),
            ],
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'View detailed',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neonBlue.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Timer Card
// ─────────────────────────────────────────────────
class _TimerCard extends StatelessWidget {
  final TodoItem timer;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TimerCard({
    required this.timer,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Timer icon with glow
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppGradients.primaryBlue,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow:
                    AppShadows.neonGlow(AppColors.neonBlue, intensity: 0.15),
              ),
              child: const Icon(Icons.timer, color: Colors.white, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timer.title,
                      style: AppTextStyles.heading3.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${timer.durationMinutes} min',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.neonCyan)),
                      if (timer.audioFilePath.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.music_note,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            timer.audioFilePath.split('/').last.split('\\').last,
                            style: AppTextStyles.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Start button
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.neonBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                    color: AppColors.neonBlue.withValues(alpha: 0.3)),
              ),
              child: Text('Start',
                  style: AppTextStyles.chip.copyWith(color: AppColors.neonBlue)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// List Card
// ─────────────────────────────────────────────────
class _ListCard extends StatelessWidget {
  final TodoItem listItem;
  final VoidCallback onTap;

  const _ListCard({
    required this.listItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> checklist = [];
    if (listItem.checklistJson.isNotEmpty) {
      try {
        checklist =
            List<Map<String, dynamic>>.from(jsonDecode(listItem.checklistJson));
      } catch (_) {}
    }
    final doneCount = checklist.where((c) => c['done'] == true).length;
    final totalCount = checklist.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppGradients.purple,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.checklist,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(listItem.title,
                          style:
                              AppTextStyles.heading3.copyWith(fontSize: 16)),
                      if (totalCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$doneCount / $totalCount completed',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: doneCount == totalCount && totalCount > 0
                                  ? AppColors.health
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (checklist.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              // Show first 3 items preview
              ...checklist.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          item['done'] == true
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 16,
                          color: item['done'] == true
                              ? AppColors.health
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['text'] ?? '',
                            style: AppTextStyles.bodySmall.copyWith(
                              decoration: item['done'] == true
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item['done'] == true
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
              if (checklist.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '+${checklist.length - 3} more items',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.neonBlue),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
