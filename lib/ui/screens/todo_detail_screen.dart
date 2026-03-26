import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/todo_provider.dart';
import '../../data/local/app_database.dart';
import 'timer_view.dart';

/// Detail screen for viewing/editing Notes, Timers, and Lists.
///
/// Adapts its UI based on `todo.itemType`:
/// - **note**: Title + description editing (existing behavior)
/// - **timer**: Title + description + "Start Timer" button
/// - **list**: Title + description + interactive checklist
class TodoDetailScreen extends StatefulWidget {
  final TodoItem? todo;

  const TodoDetailScreen({super.key, this.todo});

  @override
  State<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  bool _isEditing = false;
  late bool _completed;

  // List checklist state
  List<Map<String, dynamic>> _checklist = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _descController =
        TextEditingController(text: widget.todo?.description ?? '');
    _completed = widget.todo?.completed ?? false;
    _isEditing = widget.todo == null;

    // Parse checklist for list items
    if (widget.todo != null && widget.todo!.itemType == 'list') {
      _parseChecklist();
    }
  }

  void _parseChecklist() {
    try {
      if (widget.todo!.checklistJson.isNotEmpty) {
        _checklist = List<Map<String, dynamic>>.from(
            jsonDecode(widget.todo!.checklistJson));
      }
    } catch (_) {
      _checklist = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    final provider = context.read<TodoProvider>();
    if (widget.todo == null) {
      provider.addNote(title, description: _descController.text.trim());
    } else {
      provider.updateTodoData(widget.todo!, title, _descController.text.trim());
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (widget.todo != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Delete Item', style: AppTextStyles.heading3),
          content: Text('Are you sure you want to delete this item?',
              style: AppTextStyles.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: AppTextStyles.button
                      .copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style:
                      AppTextStyles.button.copyWith(color: Colors.redAccent)),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        await context.read<TodoProvider>().deleteTodo(widget.todo!.id);
        if (mounted) Navigator.pop(context);
      }
    }
  }

  Future<void> _toggleChecklistItem(int index) async {
    setState(() {
      _checklist[index]['done'] = !(_checklist[index]['done'] ?? false);
    });
    // Persist
    if (widget.todo != null) {
      final updated = widget.todo!.copyWith(
        checklistJson: jsonEncode(_checklist),
      );
      await context.read<TodoProvider>().updateTodo(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemType = widget.todo?.itemType ?? 'note';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.todo != null && !_isEditing && itemType == 'note')
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white70),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (widget.todo != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _delete,
            ),
          if (_isEditing)
            TextButton(
              onPressed: _save,
              child: Text('Save',
                  style:
                      AppTextStyles.button.copyWith(color: AppColors.neonBlue)),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Completion toggle (for notes only)
              if (widget.todo != null && itemType == 'note') ...[
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.read<TodoProvider>().toggleTodo(widget.todo!);
                        setState(() => _completed = !_completed);
                      },
                      child: AnimatedContainer(
                        duration: AppAnimDurations.fast,
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _completed
                                ? AppColors.neonBlue
                                : Colors.white38,
                            width: 2,
                          ),
                          color: _completed
                              ? AppColors.neonBlue
                              : Colors.transparent,
                        ),
                        child: _completed
                            ? const Icon(Icons.check,
                                size: 18, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      _completed ? 'Completed' : 'Pending',
                      style: AppTextStyles.body.copyWith(
                        color: _completed
                            ? AppColors.neonBlue
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // Title
              if (_isEditing)
                TextField(
                  controller: _titleController,
                  style: AppTextStyles.heading1,
                  decoration: InputDecoration(
                    hintText: 'Title',
                    hintStyle:
                        AppTextStyles.heading1.copyWith(color: Colors.white24),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  autofocus: widget.todo == null,
                )
              else
                Text(
                  _titleController.text,
                  style: AppTextStyles.heading1.copyWith(
                    decoration: _completed ? TextDecoration.lineThrough : null,
                    color: _completed ? AppColors.textSecondary : Colors.white,
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),

              // Description
              if (_isEditing)
                TextField(
                  controller: _descController,
                  style: AppTextStyles.body.copyWith(fontSize: 16, height: 1.5),
                  decoration: InputDecoration(
                    hintText: 'Add description...',
                    hintStyle: AppTextStyles.body
                        .copyWith(color: Colors.white24, fontSize: 16),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                )
              else if (_descController.text.isNotEmpty)
                Text(
                  _descController.text,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.textSecondary,
                    decoration: _completed ? TextDecoration.lineThrough : null,
                  ),
                )
              else if (!_isEditing && widget.todo != null)
                Text(
                  'No description provided.',
                  style: AppTextStyles.body.copyWith(
                      color: Colors.white24, fontStyle: FontStyle.italic),
                ),

              // ── Timer-specific section ──
              if (itemType == 'timer' && widget.todo != null) ...[
                const SizedBox(height: AppSpacing.xl),
                const Divider(color: Colors.white10),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Icon(Icons.timer,
                        color: AppColors.neonCyan, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.todo!.durationMinutes} minutes',
                      style: AppTextStyles.heading3
                          .copyWith(color: AppColors.neonCyan, fontSize: 18),
                    ),
                  ],
                ),
                if (widget.todo!.audioFilePath.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(Icons.music_note,
                          color: AppColors.textSecondary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        widget.todo!.audioFilePath
                            .split('/')
                            .last
                            .split('\\')
                            .last,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                TimerView(timer: widget.todo!)),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: Text('Start Timer',
                        style: AppTextStyles.button),
                  ),
                ),
              ],

              // ── List-specific section ──
              if (itemType == 'list' && widget.todo != null) ...[
                const SizedBox(height: AppSpacing.xl),
                const Divider(color: Colors.white10),
                const SizedBox(height: AppSpacing.lg),
                Text('Checklist',
                    style: AppTextStyles.subtitle
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                if (_checklist.isEmpty)
                  Text('No items in this list.',
                      style: AppTextStyles.body
                          .copyWith(color: Colors.white24))
                else
                  ..._checklist.asMap().entries.map((entry) {
                    final item = entry.value;
                    final isDone = item['done'] == true;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => _toggleChecklistItem(entry.key),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: AppAnimDurations.fast,
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(4),
                                border: Border.all(
                                  color: isDone
                                      ? AppColors.health
                                      : Colors.white38,
                                  width: 2,
                                ),
                                color: isDone
                                    ? AppColors.health
                                    : Colors.transparent,
                              ),
                              child: isDone
                                  ? const Icon(Icons.check,
                                      size: 16,
                                      color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                item['text'] ?? '',
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 16,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isDone
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: _isEditing
          ? null
          : (widget.todo?.itemType == 'note'
              ? FloatingActionButton(
                  onPressed: () => setState(() => _isEditing = true),
                  backgroundColor: AppColors.surface,
                  child:
                      const Icon(Icons.edit, color: AppColors.neonBlue),
                )
              : null),
    );
  }
}
