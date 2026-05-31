import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chronosky/core/theme/app_theme.dart';
import 'package:chronosky/providers/todo_provider.dart';
import 'package:chronosky/data/models/todo_item_model.dart' as domain;
import 'package:chronosky/ui/screens/todo_detail_screen.dart';
import 'package:chronosky/ui/screens/timer_view.dart';
import 'package:chronosky/ui/widgets/new_item_sheet.dart';
import 'package:chronosky/ui/widgets/glass_container.dart';
import 'package:chronosky/ui/widgets/neo_button.dart';

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

  void _openDetail(domain.TodoItem item) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TodoDetailScreen(todo: item),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
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
                    Text('Workspace', style: AppTextStyles.heading1),
                    const SizedBox(height: 4),
                    Text('Notes, Timers, and Checklists',
                        style: AppTextStyles.bodySmall,),
                  ],
                ),
                NeoButton(
                  width: 48,
                  height: 48,
                  onPressed: _openNewItemSheet,
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _buildTabSelector(),
          ),
          const SizedBox(height: AppSpacing.md),

          if (context.watch<TodoProvider>().errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(context.watch<TodoProvider>().errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),),
            ),

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
      (icon: Icons.description_rounded, label: 'Notes'),
      (icon: Icons.timer_rounded, label: 'Timers'),
      (icon: Icons.checklist_rounded, label: 'Lists'),
    ];

    return GlassContainer(
      padding: const EdgeInsets.all(4),
      borderRadius: AppRadius.pill,
      animateScale: false,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: AppAnimDurations.fast,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabs[i].icon,
                        size: 16,
                        color:
                            isSelected ? Colors.white : AppColors.textSecondary,),
                    const SizedBox(width: 8),
                    Text(
                      tabs[i].label,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
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

  Widget _buildNotesList(List<domain.TodoItem> notes) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.2, // Slightly wider than square for better text fit
      ),
      itemCount: notes.length + 1, // +1 for the Create card
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildCreateNoteCard();
        }
        final note = notes[index - 1];
        return _NoteCard(note: note, onTap: () => _openDetail(note));
      },
    );
  }

  Widget _buildCreateNoteCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.primaryBlue,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: () => NewItemSheet.show(context, initialTab: 0),
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    color: Colors.white, size: 32,),
                SizedBox(height: 12),
                Text(
                  'Capture Idea',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimersList(List<domain.TodoItem> timers) {
    if (timers.isEmpty) {
      return _buildEmptyState(Icons.timer_outlined, 'No timers yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: timers.length,
      itemBuilder: (context, index) =>
          _TimerCard(timer: timers[index], onTap: () => _openDetail(timers[index])),
    );
  }

  Widget _buildChecklistsList(List<domain.TodoItem> lists) {
    if (lists.isEmpty) {
      return _buildEmptyState(Icons.checklist_outlined, 'No lists yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: lists.length,
      itemBuilder: (context, index) =>
          _ListCard(list: lists[index], onTap: () => _openDetail(lists[index])),
    );
  }

  Widget _buildEmptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.white10),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(color: Colors.white30)),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final domain.TodoItem note;
  final VoidCallback onTap;
  const _NoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.title,
            style: AppTextStyles.heading3.copyWith(fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              note.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saved just now', // Simplified for now
            style: AppTextStyles.label.copyWith(fontSize: 9, color: Colors.white12),
          ),
        ],
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  final domain.TodoItem timer;
  final VoidCallback onTap;
  const _TimerCard({required this.timer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        onTap: onTap,
        child: Row(
          children: [
            const Icon(Icons.timer_rounded, color: AppColors.neonBlue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timer.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),),
                  Text('${timer.durationMinutes} minutes',
                      style: AppTextStyles.bodySmall,),
                ],
              ),
            ),
            NeoButton(
              height: 32,
              width: 80,
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TimerView(timer: timer)),),
              child: const Text('START', style: TextStyle(fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final domain.TodoItem list;
  final VoidCallback onTap;
  const _ListCard({required this.list, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = list.checklist.where((i) => i.done).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        onTap: onTap,
        child: Row(
          children: [
            const Icon(Icons.checklist_rounded, color: AppColors.neonPurple),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(list.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),),
                  Text('$done / ${list.checklist.length} items completed',
                      style: AppTextStyles.bodySmall,),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
