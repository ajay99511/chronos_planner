import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:chronosky/core/theme/app_theme.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/core/services/intelligence_service.dart';
import 'package:chronosky/providers/analytics_provider.dart';

class AddTaskSheet extends StatefulWidget {
  final Function(Task, DateTime) onAdd;
  final Function(Task)? onUpdate;
  final Task? editingTask;
  final DateTime? defaultDate;

  const AddTaskSheet({
    super.key,
    required this.onAdd,
    this.onUpdate,
    this.editingTask,
    this.defaultDate,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _costCtrl = TextEditingController(text: '0.0');
  late DateTime _selectedDate;
  String _startTime = '09:00';
  String _endTime = '10:00';
  TaskType _selectedType = TaskType.work;
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskEnergyLevel _selectedEnergy = TaskEnergyLevel.medium;

  final _intelService = IntelligenceService();

  bool get _isEditing => widget.editingTask != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.defaultDate ?? DateTime.now();

    if (_isEditing) {
      final t = widget.editingTask!;
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description;
      _costCtrl.text = t.estimatedCost.toString();
      _startTime = t.startTime;
      _endTime = t.endTime;
      _selectedType = t.type;
      _selectedPriority = t.priority;
      _selectedEnergy = t.energyLevel;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  void _suggestOptimalTime() {
    final analytics = Provider.of<AnalyticsProvider>(context, listen: false);
    final peaks = analytics.energyPeaks;
    final suggestion = _intelService.recommendTime(_selectedEnergy, peaks);

    setState(() {
      _startTime = suggestion;
      final hour = int.parse(suggestion.split(':')[0]);
      _endTime = '${((hour + 1) % 24).toString().padLeft(2, '0')}:00';
    });
  }

  @override
  Widget build(BuildContext context) {
    final pagePadding = AppResponsive.pagePadding(context);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        padding: EdgeInsets.fromLTRB(
          pagePadding,
          AppSpacing.lg,
          pagePadding,
          AppSpacing.lg,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildTextFields(),
              const SizedBox(height: 16),
              _buildPickers(),
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 16),
              _buildPrioritySelector(),
              const SizedBox(height: 16),
              _buildEnergySelector(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _isEditing ? 'Edit Task' : 'New Task',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        TextField(
          controller: _titleCtrl,
          autofocus: !_isEditing,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: const InputDecoration(
            hintText: 'What needs to be done?',
            hintStyle: TextStyle(color: Colors.white24),
            border: InputBorder.none,
          ),
        ),
        const Divider(color: Colors.white10),
        TextField(
          controller: _descCtrl,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Add a description (optional)',
            hintStyle: TextStyle(color: Colors.white12),
            border: InputBorder.none,
          ),
        ),
        const Divider(color: Colors.white10),
      ],
    );
  }

  Widget _buildPickers() {
    // Simplifying pickers for brevity in this refactor call
    return Column(
      children: [
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (d != null) setState(() => _selectedDate = d);
          },
          child: _PickerRow(
            icon: Icons.calendar_today_rounded,
            label: 'DATE',
            value: DateFormat('EEE, MMM d').format(_selectedDate),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 340;
            final start = InkWell(
              onTap: () => _pickTime(true),
              child: _PickerRow(
                icon: Icons.access_time_rounded,
                label: 'START',
                value: _startTime,
              ),
            );
            final end = InkWell(
              onTap: () => _pickTime(false),
              child: _PickerRow(
                icon: Icons.access_time_filled_rounded,
                label: 'END',
                value: _endTime,
              ),
            );
            if (stack) {
              return Column(
                children: [
                  start,
                  const SizedBox(height: AppSpacing.sm),
                  end,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: start),
                const SizedBox(width: 12),
                Expanded(child: end),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (t != null) {
      setState(() {
        final f =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
        if (isStart) {
          _startTime = f;
        } else {
          _endTime = f;
        }
      });
    }
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CATEGORY',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TaskType.values
              .map(
                (type) => ChoiceChip(
                  label: Text(
                    type.name.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  selected: _selectedType == type,
                  onSelected: (_) => setState(() => _selectedType = type),
                  selectedColor: AppColors.neonBlue,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRIORITY',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TaskPriority.values
              .map(
                (p) => ChoiceChip(
                  label: Text(
                    p.name.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  selected: _selectedPriority == p,
                  onSelected: (_) => setState(() => _selectedPriority = p),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildEnergySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            const Text(
              'ENERGY LEVEL',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _suggestOptimalTime,
              child: const Text(
                'Suggest Optimal Time',
                style: TextStyle(fontSize: 10, color: AppColors.neonCyan),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: TaskEnergyLevel.values
              .map(
                (e) => ChoiceChip(
                  label: Text(
                    e.name.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  selected: _selectedEnergy == e,
                  onSelected: (_) => setState(() => _selectedEnergy = e),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () {
        if (_titleCtrl.text.isEmpty) return;
        final t = Task(
          id: _isEditing ? widget.editingTask!.id : const Uuid().v4(),
          title: _titleCtrl.text,
          startTime: _startTime,
          endTime: _endTime,
          type: _selectedType,
          priority: _selectedPriority,
          energyLevel: _selectedEnergy,
          description: _descCtrl.text,
          completed: _isEditing ? widget.editingTask!.completed : false,
        );
        if (_isEditing) {
          widget.onUpdate?.call(t);
        } else {
          widget.onAdd(t, _selectedDate);
        }
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.neonBlue,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        _isEditing ? 'SAVE CHANGES' : 'CREATE TASK',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.neonBlue, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
