import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
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
  late TextEditingController _durationController;
  late TextEditingController _checklistEntryController;
  bool _isEditing = false;
  late bool _completed;

  // Timer state
  String? _audioFilePath;
  String? _audioFileName;

  // List checklist state
  List<Map<String, dynamic>> _checklist = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _descController =
        TextEditingController(text: widget.todo?.description ?? '');
    _durationController = TextEditingController(
        text: (widget.todo?.durationMinutes ?? 25).toString());
    _checklistEntryController = TextEditingController();
    _completed = widget.todo?.completed ?? false;
    _isEditing = widget.todo == null;
    _audioFilePath = widget.todo?.audioFilePath;
    _audioFileName = _audioFilePath?.split('/').last.split('\\').last;

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
    _durationController.dispose();
    _checklistEntryController.dispose();
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
    final description = _descController.text.trim();

    if (widget.todo == null) {
      // For now, only handles Note creation from here, 
      // though NewItemSheet is the primary way.
      provider.addNote(title, description: description);
    } else {
      final itemType = widget.todo!.itemType;
      TodoItem updated = widget.todo!.copyWith(
        title: title,
        description: description,
      );

      if (itemType == 'timer') {
        final duration = int.tryParse(_durationController.text.trim()) ?? 25;
        updated = updated.copyWith(
          durationMinutes: duration,
          audioFilePath: _audioFilePath ?? '',
        );
      } else if (itemType == 'list') {
        updated = updated.copyWith(
          checklistJson: jsonEncode(_checklist),
        );
      }

      provider.updateTodo(updated);
    }
    setState(() => _isEditing = false);
    if (widget.todo == null) {
      Navigator.pop(context);
    }
  }

  Future<void> _pickAudioFile() async {
    // Re-using file picker logic from NewItemSheet would be ideal, 
    // but for now we'll implement it here for simplicity.
    // In a real app, this should be in a service.
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _audioFilePath = result.files.single.path;
          _audioFileName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _addChecklistItem() {
    final text = _checklistEntryController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _checklist.add({'text': text, 'done': false});
        _checklistEntryController.clear();
      });
    }
  }

  void _removeChecklistItem(int index) {
    setState(() {
      _checklist.removeAt(index);
    });
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
          if (widget.todo != null && !_isEditing)
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
                if (_isEditing) ...[
                  Text('Duration (minutes)', style: AppTextStyles.subtitle),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: Colors.white10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: TextField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.body,
                      decoration:
                          const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Background Audio', style: AppTextStyles.subtitle),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickAudioFile,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.music_note,
                                  size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text('Select Audio',
                                  style: AppTextStyles.body
                                      .copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _audioFileName ?? 'No file selected',
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_audioFilePath != null && _audioFilePath!.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: Colors.redAccent),
                          onPressed: () => setState(() {
                            _audioFilePath = '';
                            _audioFileName = null;
                          }),
                        ),
                    ],
                  ),
                ] else ...[
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
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TimerView(timer: widget.todo!)),
                        );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: Text('Start Timer', style: AppTextStyles.button),
                    ),
                  ),
                ],
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
                if (_isEditing) ...[
                  ..._checklist.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_box_outline_blank,
                              size: 20, color: Colors.white24),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(entry.value['text'] ?? '',
                                style: AppTextStyles.body),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.redAccent, size: 20),
                            onPressed: () => _removeChecklistItem(entry.key),
                          ),
                        ],
                      ),
                    );
                  }),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: Colors.white10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          child: TextField(
                            controller: _checklistEntryController,
                            style: AppTextStyles.body,
                            decoration: InputDecoration(
                              hintText: 'Add item...',
                              hintStyle: AppTextStyles.body
                                  .copyWith(color: Colors.white24),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _addChecklistItem(),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: AppColors.neonBlue),
                        onPressed: _addChecklistItem,
                      ),
                    ],
                  ),
                ] else ...[
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
                                        size: 16, color: Colors.white)
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
            ],
          ),
        ),
      ),
      floatingActionButton: _isEditing
          ? null
          : FloatingActionButton(
              onPressed: () => setState(() => _isEditing = true),
              backgroundColor: AppColors.surface,
              child: const Icon(Icons.edit, color: AppColors.neonBlue),
            ),
    );
  }
}
