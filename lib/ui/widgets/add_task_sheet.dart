import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:chronosky/core/theme/app_theme.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/core/services/intelligence_service.dart';
import 'package:chronosky/providers/analytics_provider.dart';

enum _TaskDateMode { exactDate, weekdays }

class AddTaskSheet extends StatefulWidget {
  final Function(Task, DateTime) onAdd;
  final Function(Task, List<DateTime>)? onAddToDates;
  final Function(Task)? onUpdate;
  final Task? editingTask;
  final DateTime? defaultDate;
  final List<DateTime> availableDates;
  final bool showDateControls;
  final String? submitLabel;

  const AddTaskSheet({
    super.key,
    required this.onAdd,
    this.onAddToDates,
    this.onUpdate,
    this.editingTask,
    this.defaultDate,
    this.availableDates = const [],
    this.showDateControls = true,
    this.submitLabel,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _costCtrl = TextEditingController(text: '0.0');
  late DateTime _selectedDate;
  late _TaskDateMode _dateMode;
  late Set<int> _selectedWeekdays;
  String _startTime = '09:00';
  String _endTime = '10:00';
  TaskType _selectedType = TaskType.work;
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskEnergyLevel _selectedEnergy = TaskEnergyLevel.medium;
  String? _formError;

  final _intelService = IntelligenceService();

  bool get _isEditing => widget.editingTask != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.defaultDate ?? DateTime.now();
    _dateMode = _TaskDateMode.exactDate;
    _selectedWeekdays = {_weekdayIndex(_selectedDate)};

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

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _weekdayIndex(DateTime date) => date.weekday - 1;

  List<DateTime> get _availableDates {
    final dates = widget.availableDates.isNotEmpty
        ? widget.availableDates
        : List.generate(7, (i) => _selectedDate.add(Duration(days: i)));

    final unique = <String, DateTime>{};
    for (final date in dates) {
      final normalized = _dateOnly(date);
      unique['${normalized.year}-${normalized.month}-${normalized.day}'] =
          normalized;
    }

    final sorted = unique.values.toList()..sort((a, b) => a.compareTo(b));
    return sorted;
  }

  List<DateTime> get _selectedRepeatDates => _availableDates
      .where((date) => _selectedWeekdays.contains(_weekdayIndex(date)))
      .toList();

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
              if (widget.showDateControls && !_isEditing) ...[
                _buildDateOptions(),
                const SizedBox(height: 16),
              ],
              _buildTimePickers(),
              const SizedBox(height: 16),
              _buildCostField(),
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 16),
              _buildPrioritySelector(),
              const SizedBox(height: 16),
              _buildEnergySelector(),
              if (_formError != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formError!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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

  Widget _buildDateOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'SCHEDULE',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 360;
            final exact = _DateModeButton(
              label: 'Exact date',
              icon: Icons.event_rounded,
              selected: _dateMode == _TaskDateMode.exactDate,
              onTap: () => setState(() => _dateMode = _TaskDateMode.exactDate),
            );
            final weekdays = _DateModeButton(
              label: 'Weekdays',
              icon: Icons.date_range_rounded,
              selected: _dateMode == _TaskDateMode.weekdays,
              onTap: () => setState(() => _dateMode = _TaskDateMode.weekdays),
            );

            if (stack) {
              return Column(
                children: [
                  exact,
                  const SizedBox(height: AppSpacing.sm),
                  weekdays,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: exact),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: weekdays),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        if (_dateMode == _TaskDateMode.exactDate) _buildDatePicker(),
        if (_dateMode == _TaskDateMode.weekdays) _buildWeekdayPicker(),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (d != null) {
          setState(() {
            _selectedDate = d;
            _selectedWeekdays = {_weekdayIndex(d)};
          });
        }
      },
      child: _PickerRow(
        icon: Icons.calendar_today_rounded,
        label: 'DATE',
        value: DateFormat('EEE, MMM d').format(_selectedDate),
      ),
    );
  }

  Widget _buildWeekdayPicker() {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selectedDates = _selectedRepeatDates;
    final summary = selectedDates.isEmpty
        ? 'Choose at least one day'
        : selectedDates
            .map((date) => DateFormat('EEE, MMM d').format(date))
            .join(', ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickDayButton(
                label: 'Weekdays',
                onTap: () => setState(
                  () => _selectedWeekdays = {0, 1, 2, 3, 4},
                ),
              ),
              _QuickDayButton(
                label: 'Every day',
                onTap: () => setState(
                  () => _selectedWeekdays = {0, 1, 2, 3, 4, 5, 6},
                ),
              ),
              _QuickDayButton(
                label: 'Clear',
                onTap: () => setState(_selectedWeekdays.clear),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(7, (i) {
              final isSelected = _selectedWeekdays.contains(i);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(
                    () => isSelected
                        ? _selectedWeekdays.remove(i)
                        : _selectedWeekdays.add(i),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.neonBlue
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: TextStyle(
              color: selectedDates.isEmpty
                  ? Colors.redAccent
                  : AppColors.textSecondary,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickers() {
    return Column(
      children: [
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
        _formError = null;
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

  Widget _buildCostField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.attach_money_rounded,
            color: AppColors.health,
            size: 18,
          ),
          const SizedBox(width: 12),
          const Text(
            'EST. COST',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _costCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
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
        if (_titleCtrl.text.trim().isEmpty) {
          setState(() => _formError = 'Please enter a title.');
          return;
        }
        if (_startTime == _endTime) {
          setState(
            () =>
                _formError = 'End time must be different from the start time.',
          );
          return;
        }
        if (!_isEditing &&
            widget.showDateControls &&
            _dateMode == _TaskDateMode.weekdays &&
            _selectedRepeatDates.isEmpty) {
          setState(() => _formError = 'Please select at least one day.');
          return;
        }
        final estimatedCost = double.tryParse(_costCtrl.text.trim())
                ?.clamp(0.0, double.maxFinite) ??
            0.0;
        final t = Task(
          id: _isEditing ? widget.editingTask!.id : const Uuid().v4(),
          title: _titleCtrl.text,
          startTime: _startTime,
          endTime: _endTime,
          type: _selectedType,
          priority: _selectedPriority,
          energyLevel: _selectedEnergy,
          estimatedCost: estimatedCost,
          actualCost: _isEditing ? widget.editingTask!.actualCost : 0.0,
          description: _descCtrl.text,
          completed: _isEditing ? widget.editingTask!.completed : false,
        );
        if (_isEditing) {
          widget.onUpdate?.call(t);
        } else if (widget.showDateControls &&
            _dateMode == _TaskDateMode.weekdays) {
          final dates = _selectedRepeatDates;
          if (widget.onAddToDates != null) {
            widget.onAddToDates!(t, dates);
          } else {
            for (var i = 0; i < dates.length; i++) {
              final task = i == 0 ? t : t.copyWith(id: const Uuid().v4());
              widget.onAdd(task, dates[i]);
            }
          }
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
        widget.submitLabel ?? (_isEditing ? 'SAVE CHANGES' : 'CREATE TASK'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DateModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DateModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.neonBlue.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.neonBlue : Colors.white10,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickDayButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickDayButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.neonCyan,
        side: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.35)),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
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
