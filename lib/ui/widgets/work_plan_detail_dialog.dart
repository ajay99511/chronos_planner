import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chronosky/core/theme/app_theme.dart';
import 'package:chronosky/data/models/plan_template_model.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/providers/schedule_state_provider.dart';
import 'package:chronosky/ui/widgets/add_task_sheet.dart';
import 'package:chronosky/ui/widgets/neo_button.dart';

class WorkPlanDetailDialog extends StatefulWidget {
  final PlanTemplate template;

  const WorkPlanDetailDialog({super.key, required this.template});

  @override
  State<WorkPlanDetailDialog> createState() => _WorkPlanDetailDialogState();
}

class _WorkPlanDetailDialogState extends State<WorkPlanDetailDialog> {
  late Set<int> _selectedDays;
  late String _currentName;
  late String _currentDesc;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _currentName = widget.template.name;
    _currentDesc = widget.template.description;
    _selectedDays = Set.from(widget.template.activeDays);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleStateProvider>(context);
    final tmpl = provider.templates.firstWhere(
      (t) => t.id == widget.template.id,
      orElse: () => widget.template,
    );

    return Dialog(
      backgroundColor: AppColors.background,
      insetPadding: EdgeInsets.symmetric(
        horizontal:
            AppResponsive.isCompact(context) ? AppSpacing.sm : AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          children: [
            _buildHeader(context, provider, tmpl),
            Expanded(child: _buildTaskList(context, provider, tmpl)),
            _buildActionFooter(context, provider, tmpl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ScheduleStateProvider provider,
    PlanTemplate tmpl,
  ) {
    return Container(
      padding: EdgeInsets.all(
        AppResponsive.isCompact(context) ? AppSpacing.md : AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient:
            LinearGradient(colors: [AppColors.neonBlue, AppColors.neonPurple]),
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _currentName,
                  style: AppTextStyles.heading3
                      .copyWith(color: Colors.white, fontSize: 20),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => _editPlanInfo(context, provider),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          if (_currentDesc.isNotEmpty)
            Text(
              _currentDesc,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    ScheduleStateProvider provider,
    PlanTemplate tmpl,
  ) {
    if (tmpl.tasks.isEmpty) {
      return Center(
        child: Text(
          'No tasks yet',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tmpl.tasks.length,
      itemBuilder: (context, index) {
        final task = tmpl.tasks[index];
        return Card(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              '${task.startTime} - ${task.endTime}',
              style: AppTextStyles.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  onPressed: () => _editTask(context, provider, task),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_rounded,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  onPressed: () =>
                      provider.removeTaskFromTemplate(tmpl.id, task.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionFooter(
    BuildContext context,
    ScheduleStateProvider provider,
    PlanTemplate tmpl,
  ) {
    return Container(
      padding: EdgeInsets.all(
        AppResponsive.isCompact(context) ? AppSpacing.md : AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(AppRadius.xxl)),
      ),
      child: Column(
        children: [
          NeoButton(
            isSecondary: true,
            height: 40,
            onPressed: () => _addTask(context, provider, tmpl.id),
            child: const Text('ADD TASK', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(height: 16),
          const Text(
            'SELECT DAYS FOR PLAN',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(7, (i) {
              final isSelected = _selectedDays.contains(i);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(
                    () => isSelected
                        ? _selectedDays.remove(i)
                        : _selectedDays.add(i),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.neonBlue
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _dayLabels[i],
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 340;
              final hasSelectedDays = _selectedDays.isNotEmpty;
              final thisWeek = NeoButton(
                isSecondary: true,
                onPressed: hasSelectedDays
                    ? () {
                        provider.applyTemplateToDays(
                          tmpl,
                          _selectedDays.toList(),
                        );
                        Navigator.pop(context);
                      }
                    : null,
                child: const Text(
                  'APPLY THIS WEEK',
                  style: TextStyle(fontSize: 10),
                ),
              );
              final everyWeek = NeoButton(
                onPressed: hasSelectedDays
                    ? () {
                        provider.setTemplateRecurring(
                          tmpl.id,
                          _selectedDays.toList(),
                        );
                        Navigator.pop(context);
                      }
                    : null,
                child: const Text(
                  'REPEAT WEEKLY',
                  style: TextStyle(fontSize: 10),
                ),
              );
              if (stack) {
                return Column(
                  children: [
                    thisWeek,
                    const SizedBox(height: AppSpacing.sm),
                    everyWeek,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: thisWeek),
                  const SizedBox(width: 8),
                  Expanded(child: everyWeek),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              provider.removeTemplate(tmpl.id);
              Navigator.pop(context);
            },
            child: const Text(
              'DELETE PLAN',
              style: TextStyle(color: Colors.redAccent, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  void _editPlanInfo(BuildContext context, ScheduleStateProvider provider) {
    final nameCtrl = TextEditingController(text: _currentName);
    final descCtrl = TextEditingController(text: _currentDesc);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
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
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addTask(
    BuildContext context,
    ScheduleStateProvider provider,
    String templateId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        showDateControls: false,
        submitLabel: 'ADD TO PLAN',
        onAdd: (task, _) => provider.addTaskToTemplate(templateId, task),
      ),
    );
  }

  void _editTask(
    BuildContext context,
    ScheduleStateProvider provider,
    TemplateTask task,
  ) {
    final domainTask = Task(
      id: task.id,
      title: task.title,
      startTime: task.startTime,
      endTime: task.endTime,
      type: task.type,
      priority: task.priority,
      energyLevel: task.energyLevel,
      estimatedCost: task.estimatedCost,
      description: task.description,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        editingTask: domainTask,
        showDateControls: false,
        submitLabel: 'SAVE PLAN TASK',
        onAdd: (_, __) {},
        onUpdate: (updated) =>
            provider.updateTaskInTemplate(widget.template.id, task.id, updated),
      ),
    );
  }
}
