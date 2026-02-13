import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/task_model.dart';

class AddTaskSheet extends StatefulWidget {
  final Function(Task) onAdd;
  final Function(Task)? onUpdate;
  final Task? editingTask;

  const AddTaskSheet({
    super.key,
    required this.onAdd,
    this.onUpdate,
    this.editingTask,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _startTime = "09:00";
  String _endTime = "10:00";
  TaskType _selectedType = TaskType.work;
  TaskPriority _selectedPriority = TaskPriority.medium;
  String? _timeError;

  bool get _isEditing => widget.editingTask != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.editingTask!;
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description;
      _startTime = t.startTime;
      _endTime = t.endTime;
      _selectedType = t.type;
      _selectedPriority = t.priority;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = TimeOfDay(
      hour: int.parse(
          isStart ? _startTime.split(':')[0] : _endTime.split(':')[0]),
      minute: int.parse(
          isStart ? _startTime.split(':')[1] : _endTime.split(':')[1]),
    );

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _startTime = formatted;
        } else {
          _endTime = formatted;
        }
        _validateTime();
      });
    }
  }

  void _validateTime() {
    try {
      final s = _startTime.split(':').map(int.parse).toList();
      final e = _endTime.split(':').map(int.parse).toList();
      final startMin = s[0] * 60 + s[1];
      final endMin = e[0] * 60 + e[1];
      if (endMin <= startMin) {
        _timeError = 'End time must be after start time';
      } else {
        _timeError = null;
      }
    } catch (_) {
      _timeError = 'Invalid time format';
    }
  }

  Color _getPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return AppColors.health;
      case TaskPriority.medium:
        return AppColors.leisure;
      case TaskPriority.high:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 24,
        left: 24,
        right: 24,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? "Edit Task" : "New Task",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleCtrl,
              autofocus: !_isEditing,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                hintText: "What needs to be done?",
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: Colors.white10),

            // Description field
            TextField(
              controller: _descCtrl,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: "Add a description (optional)",
                hintStyle: TextStyle(color: Colors.white12),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),

            // Time pickers
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: _timeError != null
                            ? Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.5))
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("START",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_startTime,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: _timeError != null
                            ? Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.5))
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("END",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_endTime,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_timeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_timeError!,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),

            const SizedBox(height: 16),

            // Category chips
            const Text("CATEGORY",
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TaskType.values.map((type) {
                  final isSelected = _selectedType == type;
                  Color color;
                  switch (type) {
                    case TaskType.work:
                      color = AppColors.work;
                      break;
                    case TaskType.personal:
                      color = AppColors.personal;
                      break;
                    case TaskType.health:
                      color = AppColors.health;
                      break;
                    case TaskType.leisure:
                      color = AppColors.leisure;
                      break;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        type.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey),
                      ),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _selectedType = type),
                      selectedColor: color,
                      backgroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.white10)),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Priority selector
            const Text("PRIORITY",
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: TaskPriority.values.map((p) {
                final isSelected = _selectedPriority == p;
                final color = _getPriorityColor(p);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      p.toString().split('.').last.toUpperCase(),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey),
                    ),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedPriority = p),
                    selectedColor: color,
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.white10)),
                    showCheckmark: false,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Submit button
            ElevatedButton(
              onPressed: () {
                if (_titleCtrl.text.isEmpty) return;
                _validateTime();
                if (_timeError != null) {
                  setState(() {});
                  return;
                }

                if (_isEditing) {
                  final updated = widget.editingTask!.copyWith(
                    title: _titleCtrl.text,
                    startTime: _startTime,
                    endTime: _endTime,
                    type: _selectedType,
                    priority: _selectedPriority,
                    description: _descCtrl.text,
                  );
                  widget.onUpdate?.call(updated);
                } else {
                  widget.onAdd(Task(
                    id: const Uuid().v4(),
                    title: _titleCtrl.text,
                    startTime: _startTime,
                    endTime: _endTime,
                    type: _selectedType,
                    priority: _selectedPriority,
                    description: _descCtrl.text,
                  ));
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                shadowColor: AppColors.neonBlue.withValues(alpha: 0.4),
                elevation: 8,
              ),
              child: Text(
                _isEditing ? "Save Changes" : "Create Task",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
