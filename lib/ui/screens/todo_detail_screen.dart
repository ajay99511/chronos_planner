import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:chronosky/core/theme/app_theme.dart';
import 'package:chronosky/providers/todo_provider.dart';
import 'package:chronosky/data/models/todo_item_model.dart' as domain;
import 'package:chronosky/ui/screens/timer_view.dart';
import 'package:chronosky/ui/widgets/neo_button.dart';

class TodoDetailScreen extends StatefulWidget {
  final domain.TodoItem? todo;

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

  String? _audioFilePath;
  String? _audioFileName;
  List<domain.ChecklistItem> _checklist = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _descController =
        TextEditingController(text: widget.todo?.description ?? '');
    _durationController = TextEditingController(
      text: (widget.todo?.durationMinutes ?? 25).toString(),
    );
    _checklistEntryController = TextEditingController();
    _completed = widget.todo?.completed ?? false;
    _isEditing = widget.todo == null;
    _audioFilePath = widget.todo?.audioFilePath;
    if (_audioFilePath != null && _audioFilePath!.isNotEmpty) {
      _audioFileName = _audioFilePath?.split('/').last.split('\\').last;
    } else {
      _audioFileName = null;
    }
    _checklist = widget.todo?.checklist.toList() ?? [];
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
    if (title.isEmpty) return;

    final provider = context.read<TodoProvider>();
    final description = _descController.text.trim();

    if (widget.todo == null) {
      provider.addNote(title, description: description);
    } else {
      final updated = widget.todo!.copyWith(
        title: title,
        description: description,
        completed: _completed,
        durationMinutes: int.tryParse(_durationController.text) ?? 25,
        audioFilePath: _audioFilePath ?? '',
        checklist: _checklist,
      );
      provider.updateTodo(updated);
    }
    setState(() => _isEditing = false);
    if (widget.todo == null) Navigator.pop(context);
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.audio, allowMultiple: false);
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
        _checklist.add(domain.ChecklistItem(text: text));
        _checklistEntryController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemType = widget.todo?.itemType ?? domain.TodoItemType.note;

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
              icon: const Icon(Icons.edit_rounded, color: Colors.white70),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _save,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  color: AppColors.neonBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppResponsive.pagePadding(context),
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.todo != null &&
                itemType == domain.TodoItemType.note) ...[
              _buildCompletionToggle(),
              const SizedBox(height: 24),
            ],
            _isEditing
                ? TextField(
                    controller: _titleController,
                    style: AppTextStyles.heading1,
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  )
                : Text(
                    _titleController.text,
                    style: AppTextStyles.heading1.copyWith(
                      fontSize: AppResponsive.heading1Size(context),
                      decoration:
                          _completed ? TextDecoration.lineThrough : null,
                      color:
                          _completed ? AppColors.textSecondary : Colors.white,
                    ),
                  ),
            const SizedBox(height: 16),
            _isEditing
                ? TextField(
                    controller: _descController,
                    style: AppTextStyles.body.copyWith(color: Colors.white70),
                    decoration: const InputDecoration(
                      hintText: 'Add description...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  )
                : Text(
                    _descController.text,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white70,
                      decoration:
                          _completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
            if (itemType == domain.TodoItemType.timer) _buildTimerSection(),
            if (itemType == domain.TodoItemType.list) _buildChecklistSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionToggle() {
    return InkWell(
      onTap: () => setState(() => _completed = !_completed),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _completed ? AppColors.neonBlue : Colors.white38,
                width: 2,
              ),
              color: _completed ? AppColors.neonBlue : Colors.transparent,
            ),
            child: _completed
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            _completed ? 'COMPLETED' : 'PENDING',
            style: TextStyle(
              color: _completed ? AppColors.neonBlue : Colors.white38,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    if (_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            'DURATION (MINUTES)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white38,
            ),
          ),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          NeoButton(
            isSecondary: true,
            onPressed: _pickAudioFile,
            child: Text(_audioFileName ?? 'SELECT AUDIO'),
          ),
        ],
      );
    }
    return Column(
      children: [
        const SizedBox(height: 48),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            const Icon(
              Icons.timer_rounded,
              color: AppColors.neonBlue,
              size: 32,
            ),
            Text(
              '${_durationController.text} MIN',
              style: AppTextStyles.heading1.copyWith(
                fontSize: AppResponsive.heading1Size(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        NeoButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TimerView(timer: widget.todo!),
              ),
            );
          },
          child: const Text('START TIMER'),
        ),
      ],
    );
  }

  Widget _buildChecklistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          'CHECKLIST',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white38,
          ),
        ),
        const SizedBox(height: 16),
        ..._checklist
            .asMap()
            .entries
            .map((entry) => _buildChecklistItem(entry.key, entry.value)),
        if (_isEditing) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _checklistEntryController,
                  decoration: const InputDecoration(hintText: 'Add item...'),
                ),
              ),
              IconButton(
                onPressed: _addChecklistItem,
                icon: const Icon(Icons.add_rounded, color: AppColors.neonBlue),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildChecklistItem(int index, domain.ChecklistItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Checkbox(
            value: item.done,
            onChanged: _isEditing
                ? null
                : (val) {
                    setState(() {
                      _checklist[index] = item.copyWith(done: val ?? false);
                    });
                  },
            activeColor: AppColors.health,
          ),
          Expanded(
            child: Text(
              item.text,
              style: TextStyle(
                decoration: item.done ? TextDecoration.lineThrough : null,
                color: item.done ? Colors.white38 : Colors.white,
              ),
            ),
          ),
          if (_isEditing)
            IconButton(
              onPressed: () => setState(() => _checklist.removeAt(index)),
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.redAccent,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}
