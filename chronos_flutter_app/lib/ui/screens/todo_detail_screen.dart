import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/todo_provider.dart';
import '../../data/local/app_database.dart';

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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _descController =
        TextEditingController(text: widget.todo?.description ?? '');
    _completed = widget.todo?.completed ?? false;
    _isEditing = widget.todo == null;
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
      provider.addTodo(title, description: _descController.text.trim());
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
          title: Text('Delete Task', style: AppTextStyles.heading3),
          content: Text('Are you sure you want to delete this task?',
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

  @override
  Widget build(BuildContext context) {
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
              if (widget.todo != null) ...[
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
              if (_isEditing)
                TextField(
                  controller: _titleController,
                  style: AppTextStyles.heading1,
                  decoration: InputDecoration(
                    hintText: 'Task Title',
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
