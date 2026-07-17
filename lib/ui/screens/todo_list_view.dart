import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  int _selectedTab = 0; // 0 = Notes, 1 = Timers, 2 = Alarms, 3 = Lists
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openNewItemSheet() {
    NewItemSheet.show(context, initialTab: _selectedTab);
  }

  List<domain.TodoItem> _filtered(List<domain.TodoItem> items) {
    if (_query.isEmpty) return items;
    final q = _query.toLowerCase();
    return items
        .where(
          (i) =>
              i.title.toLowerCase().contains(q) ||
              i.description.toLowerCase().contains(q) ||
              i.checklist.any((c) => c.text.toLowerCase().contains(q)),
        )
        .toList();
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
            padding: AppResponsive.screenPadding(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workspace',
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: AppResponsive.heading1Size(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Notes, Timers, Alarms, and Checklists',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
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
            padding: AppResponsive.horizontalPadding(context),
            child: _buildTabSelector(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: AppResponsive.horizontalPadding(context),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: const TextStyle(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search notes, timers, and lists…',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Colors.white38,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.white38,
                        ),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                isDense: true,
                filled: true,
                fillColor: AppColors.surface.withValues(alpha: 0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: const BorderSide(color: AppColors.neonBlue),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (context.watch<TodoProvider>().errorMessage != null)
            Padding(
              padding: AppResponsive.horizontalPadding(context),
              child: Text(
                context.watch<TodoProvider>().errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          Expanded(
            child: Consumer<TodoProvider>(
              builder: (context, provider, _) {
                switch (_selectedTab) {
                  case 0:
                    return _buildNotesList(_filtered(provider.notes));
                  case 1:
                    return _buildTimersList(_filtered(provider.timers));
                  case 2:
                    return _buildAlarmsList(
                      provider,
                      _filtered(provider.alarms),
                    );
                  case 3:
                    return _buildChecklistsList(_filtered(provider.lists));
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
      (icon: Icons.alarm_rounded, label: 'Alarms'),
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
            child: Semantics(
              button: true,
              selected: isSelected,
              label: '${tabs[i].label} tab',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedTab = i),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  focusColor: Colors.white.withValues(alpha: 0.08),
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
                        Icon(
                          tabs[i].icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tabs[i].label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNotesList(List<domain.TodoItem> notes) {
    // Hide the Create card while a search is active so results stand alone.
    final isSearching = _query.isNotEmpty;
    if (isSearching && notes.isEmpty) {
      return _buildEmptyState(Icons.search_off_rounded, 'No matches');
    }
    final extra = isSearching ? 0 : 1;
    return GridView.builder(
      padding: AppResponsive.screenPadding(context),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.2, // Slightly wider than square for better text fit
      ),
      itemCount: notes.length + extra,
      itemBuilder: (context, index) {
        if (!isSearching && index == 0) {
          return _buildCreateNoteCard();
        }
        final note = notes[index - extra];
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
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white,
                  size: 32,
                ),
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
      return _query.isNotEmpty
          ? _buildEmptyState(Icons.search_off_rounded, 'No matches')
          : _buildEmptyState(Icons.timer_outlined, 'No timers yet');
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppResponsive.pagePadding(context),
        0,
        AppResponsive.pagePadding(context),
        AppSpacing.xl,
      ),
      itemCount: timers.length,
      itemBuilder: (context, index) => _TimerCard(
        timer: timers[index],
        onTap: () => _openDetail(timers[index]),
      ),
    );
  }

  static const _alarmSortLabels = {
    AlarmSort.upcomingAsc: 'Upcoming (soonest first)',
    AlarmSort.upcomingDesc: 'Upcoming (latest first)',
    AlarmSort.addedDesc: 'Date added (newest first)',
    AlarmSort.addedAsc: 'Date added (oldest first)',
  };

  Widget _buildAlarmsList(TodoProvider provider, List<domain.TodoItem> alarms) {
    final sortBar = Padding(
      padding: EdgeInsets.fromLTRB(
        AppResponsive.pagePadding(context),
        0,
        AppResponsive.pagePadding(context),
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.sort_rounded, size: 16, color: Colors.white38),
          const SizedBox(width: 8),
          PopupMenuButton<AlarmSort>(
            initialValue: provider.alarmSort,
            color: AppColors.surface,
            tooltip: 'Sort alarms',
            onSelected: provider.setAlarmSort,
            itemBuilder: (context) => AlarmSort.values
                .map(
                  (s) => PopupMenuItem(
                    value: s,
                    child: Text(
                      _alarmSortLabels[s]!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                )
                .toList(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _alarmSortLabels[provider.alarmSort]!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Colors.white38,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (alarms.isEmpty) {
      return Column(
        children: [
          sortBar,
          Expanded(
            child: _query.isNotEmpty
                ? _buildEmptyState(Icons.search_off_rounded, 'No matches')
                : _buildEmptyState(Icons.alarm_outlined, 'No alarms yet'),
          ),
        ],
      );
    }

    return Column(
      children: [
        sortBar,
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              AppResponsive.pagePadding(context),
              0,
              AppResponsive.pagePadding(context),
              AppSpacing.xl,
            ),
            itemCount: alarms.length,
            itemBuilder: (context, index) => _AlarmCard(
              alarm: alarms[index],
              onToggle: (enabled) => provider.updateTodo(
                alarms[index].copyWith(enabled: enabled),
              ),
              onEditTime: () => _editAlarmTime(provider, alarms[index]),
              onDelete: () => provider.deleteTodo(alarms[index].id),
            ),
          ),
        ),
      ],
    );
  }

  /// Reschedules [alarm] via date + time pickers and re-arms it.
  Future<void> _editAlarmTime(
    TodoProvider provider,
    domain.TodoItem alarm,
  ) async {
    final now = DateTime.now();
    final current = alarm.scheduledAt ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: current.isAfter(now) ? current : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;

    final scheduledAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!scheduledAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm time must be in the future')),
      );
      return;
    }
    await provider.updateTodo(
      alarm.copyWith(scheduledAt: scheduledAt, enabled: true),
    );
  }

  Widget _buildChecklistsList(List<domain.TodoItem> lists) {
    if (lists.isEmpty) {
      return _query.isNotEmpty
          ? _buildEmptyState(Icons.search_off_rounded, 'No matches')
          : _buildEmptyState(Icons.checklist_outlined, 'No lists yet');
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppResponsive.pagePadding(context),
        0,
        AppResponsive.pagePadding(context),
        AppSpacing.xl,
      ),
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

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat.MMMd().format(time);
  }

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
            note.updatedAt.isAfter(note.createdAt)
                ? 'Edited ${_relativeTime(note.updatedAt)}'
                : 'Created ${_relativeTime(note.createdAt)}',
            style: AppTextStyles.label
                .copyWith(fontSize: 9, color: Colors.white24),
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
                  Text(
                    timer.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${timer.durationMinutes} minutes',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            NeoButton(
              height: 32,
              width: 80,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TimerView(timer: timer)),
              ),
              child: const Text('START', style: TextStyle(fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final domain.TodoItem alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEditTime;
  final VoidCallback onDelete;

  const _AlarmCard({
    required this.alarm,
    required this.onToggle,
    required this.onEditTime,
    required this.onDelete,
  });

  String _countdown(DateTime at) {
    final diff = at.difference(DateTime.now());
    if (diff.isNegative) return 'expired';
    if (diff.inMinutes < 1) return 'in less than a minute';
    if (diff.inHours < 1) return 'in ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'in ${diff.inHours}h ${diff.inMinutes % 60}m';
    return 'in ${diff.inDays}d ${diff.inHours % 24}h';
  }

  @override
  Widget build(BuildContext context) {
    final at = alarm.scheduledAt;
    final isExpired = at == null || !at.isAfter(DateTime.now());
    final active = alarm.enabled && !isExpired;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        onTap: onEditTime,
        child: Row(
          children: [
            Icon(
              Icons.alarm_rounded,
              color: active ? AppColors.neonBlue : Colors.white24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alarm.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: active ? Colors.white : Colors.white38,
                    ),
                  ),
                  if (at != null)
                    Text(
                      '${DateFormat('EEE, MMM d • HH:mm').format(at)}'
                      '${active ? ' • ${_countdown(at)}' : isExpired ? ' • expired' : ' • off'}',
                      style: AppTextStyles.bodySmall,
                    ),
                ],
              ),
            ),
            Switch(
              value: alarm.enabled,
              activeThumbColor: AppColors.neonBlue,
              onChanged: onToggle,
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Colors.white38,
              ),
              tooltip: 'Delete alarm',
              onPressed: onDelete,
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
                  Text(
                    list.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$done / ${list.checklist.length} items completed',
                    style: AppTextStyles.bodySmall,
                  ),
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
