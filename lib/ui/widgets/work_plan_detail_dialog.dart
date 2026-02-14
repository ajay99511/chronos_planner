import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/plan_template_model.dart';
import '../../data/models/task_model.dart';
import '../../providers/schedule_provider.dart';
import 'add_task_sheet.dart';

/// Full-screen-style dialog that shows a WorkPlan's details.
/// The user can:
///  - View / edit plan name & description
///  - Add, edit, and delete tasks inside the plan
///  - Select one or more days of the week and apply the plan to them
///  - Delete the entire plan
class WorkPlanDetailDialog extends StatefulWidget {
  final PlanTemplate template;

  const WorkPlanDetailDialog({super.key, required this.template});

  @override
  State<WorkPlanDetailDialog> createState() => _WorkPlanDetailDialogState();
}

class _WorkPlanDetailDialogState extends State<WorkPlanDetailDialog> {
  final Set<int> _selectedDays = {};
  late String _currentName;
  late String _currentDesc;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _currentName = widget.template.name;
    _currentDesc = widget.template.description;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);

    // Re-read from provider so updates appear live
    final tmpl = provider.templates.firstWhere(
      (t) => t.id == widget.template.id,
      orElse: () => widget.template,
    );

    return Dialog(
      backgroundColor: AppColors.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xxl)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentName,
                            style: AppTextStyles.heading3
                                .copyWith(color: Colors.white)),
                        if (_currentDesc.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(_currentDesc,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.white70),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: Colors.white70, size: 20),
                    tooltip: 'Edit Plan Info',
                    onPressed: () => _editPlanInfo(context, provider),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Task List ───────────────────────────
            Expanded(
              child: tmpl.tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.playlist_add,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 12),
                          Text("No tasks yet", style: AppTextStyles.subtitle),
                          const SizedBox(height: 4),
                          Text("Tap + below to add tasks to this plan",
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: tmpl.tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final task = tmpl.tasks[index];
                        return _TemplatTaskTile(
                          task: task,
                          onEdit: () => _editTask(context, provider, task),
                          onDelete: () {
                            provider.removeTaskFromTemplate(tmpl.id, task.id);
                          },
                        );
                      },
                    ),
            ),

            // ── Add Task Button ─────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _addTask(context, provider, tmpl.id),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add Task"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neonBlue,
                    side: BorderSide(
                        color: AppColors.neonBlue.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),

            // ── Day Selector + Apply ────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("APPLY TO DAYS",
                      style:
                          AppTextStyles.label.copyWith(color: Colors.white70)),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(7, (i) {
                      final isSelected = _selectedDays.contains(i);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedDays.remove(i);
                              } else {
                                _selectedDays.add(i);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(right: i < 6 ? 6 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.neonBlue
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.neonBlue
                                    : Colors.white12,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _dayLabels[i],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _selectedDays.isEmpty || tmpl.tasks.isEmpty
                          ? null
                          : () {
                              provider.applyTemplateToDays(
                                  tmpl, _selectedDays.toList());
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Applied to ${_selectedDays.length} day${_selectedDays.length == 1 ? '' : 's'}",
                                  ),
                                ),
                              );
                            },
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(
                        _selectedDays.isEmpty
                            ? "Select Days to Apply"
                            : "Apply to ${_selectedDays.length} Day${_selectedDays.length == 1 ? '' : 's'}",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.surface,
                        disabledForegroundColor: Colors.white30,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Footer: Delete Plan ─────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.xxl)),
                        title: const Text("Delete Plan?",
                            style: TextStyle(color: Colors.white)),
                        content: Text(
                          "This will permanently remove \"${tmpl.name}\".",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Cancel")),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md)),
                            ),
                            onPressed: () {
                              provider.removeTemplate(tmpl.id);
                              Navigator.pop(ctx); // close confirm
                              Navigator.pop(context); // close detail
                            },
                            child: const Text("Delete",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.delete_outline,
                      size: 16, color: Colors.redAccent.shade200),
                  label: Text("Delete Plan",
                      style: TextStyle(color: Colors.redAccent.shade200)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────

  void _editPlanInfo(BuildContext context, ScheduleProvider provider) {
    final nameCtrl = TextEditingController(text: _currentName);
    final descCtrl = TextEditingController(text: _currentDesc);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl)),
        title: Text("Edit Plan Info", style: AppTextStyles.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(nameCtrl, "Plan Name"),
            const SizedBox(height: 12),
            _buildTextField(descCtrl, "Description"),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                provider.updateTemplate(
                  widget.template.id,
                  name: nameCtrl.text,
                  description: descCtrl.text,
                );
                setState(() {
                  _currentName = nameCtrl.text;
                  _currentDesc = descCtrl.text;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addTask(
      BuildContext context, ScheduleProvider provider, String templateId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        onAdd: (task, _) => provider.addTaskToTemplate(templateId, task),
      ),
    );
  }

  void _editTask(BuildContext context, ScheduleProvider provider, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        editingTask: task,
        onAdd: (_, __) {},
        onUpdate: (updated) =>
            provider.updateTaskInTemplate(widget.template.id, task.id, updated),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none),
      ),
    );
  }
}

// ─── Individual task tile inside the plan detail ───
class _TemplatTaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplatTaskTile({
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  Color _typeColor(TaskType t) {
    switch (t) {
      case TaskType.work:
        return AppColors.work;
      case TaskType.personal:
        return AppColors.personal;
      case TaskType.health:
        return AppColors.health;
      case TaskType.leisure:
        return AppColors.leisure;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _typeColor(task.type);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(task.title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        subtitle: Text(
          "${task.startTime} – ${task.endTime}  •  ${task.type.toString().split('.').last}",
          style: AppTextStyles.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppColors.neonBlue,
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.redAccent.shade200,
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
