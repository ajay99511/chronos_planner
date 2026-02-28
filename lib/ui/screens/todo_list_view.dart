import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/todo_provider.dart';
import '../../data/local/app_database.dart'; // for TodoItem
import 'todo_detail_screen.dart';

class TodoListView extends StatefulWidget {
  const TodoListView({super.key});

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  void _openTask(BuildContext context, {TodoItem? todo}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TodoDetailScreen(todo: todo),
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
                    onPressed: () => _openTask(context),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.layers_clear,
                            size: 48, color: Colors.white24),
                        const SizedBox(height: AppSpacing.md),
                        Text('Your canvas is empty.\nCreate a new task!',
                            textAlign: TextAlign.center,
                            style:
                                AppTextStyles.bodySmall.copyWith(fontSize: 16)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.1, // slightly wider than square
                  ),
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return _TodoCard(
                      todo: todo,
                      onTap: () => _openTask(context, todo: todo),
                      onToggle: () => provider.toggleTodo(todo),
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

class _TodoCard extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _TodoCard({
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
