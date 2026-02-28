import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/todo_provider.dart';
import '../../data/local/app_database.dart'; // for TodoItem

class TodoListView extends StatefulWidget {
  const TodoListView({super.key});

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  void _showAddEditTaskDialog(BuildContext context, {TodoItem? todo}) {
    final titleController = TextEditingController(text: todo?.title ?? '');
    final descController = TextEditingController(text: todo?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Text(todo == null ? 'New Task' : 'Edit Task',
              style: AppTextStyles.heading3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: AppTextStyles.bodySmall,
                  enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(AppRadius.sm)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.neonBlue),
                      borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: descController,
                style: AppTextStyles.body,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: AppTextStyles.bodySmall,
                  enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(AppRadius.sm)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.neonBlue),
                      borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: AppTextStyles.button
                      .copyWith(color: AppColors.textSecondary)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: AppGradients.primaryBlue,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isNotEmpty) {
                    final provider = context.read<TodoProvider>();
                    if (todo == null) {
                      provider.addTodo(title,
                          description: descController.text.trim());
                    } else {
                      provider.updateTodoData(
                          todo, title, descController.text.trim());
                    }
                    Navigator.pop(ctx);
                  }
                },
                child: Text('Save', style: AppTextStyles.button),
              ),
            ),
          ],
        );
      },
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
                    Text('Your persistent to-do list',
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
                    onPressed: () => _showAddEditTaskDialog(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<TodoProvider>(
              builder: (context, provider, child) {
                final todos = provider.todos;
                if (todos.isEmpty) {
                  return Center(
                    child: Text('No tasks yet. Add some!',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 16)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return _TodoTile(
                      todo: todo,
                      onToggle: () => provider.toggleTodo(todo),
                      onDelete: () => provider.deleteTodo(todo.id),
                      onEdit: () => _showAddEditTaskDialog(context, todo: todo),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TodoTile({
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        leading: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: AppAnimDurations.fast,
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: todo.completed ? AppColors.neonBlue : Colors.white38,
                width: 2,
              ),
              color: todo.completed ? AppColors.neonBlue : Colors.transparent,
            ),
            child: todo.completed
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          todo.title,
          style: AppTextStyles.body.copyWith(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
            color: todo.completed
                ? AppColors.textSecondary
                : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: todo.description.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  todo.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    decoration:
                        todo.completed ? TextDecoration.lineThrough : null,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: Colors.white54, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
