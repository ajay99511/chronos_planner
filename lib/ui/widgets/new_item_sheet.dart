import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/todo_provider.dart';

/// Bottom sheet dialog for creating Notes, Timers, or Lists.
///
/// Displays a segmented tab bar (Note | Timer | List) and shows
/// the appropriate form inputs for each item type.
class NewItemSheet extends StatefulWidget {
  /// Which tab to open initially: 0 = Note, 1 = Timer, 2 = List
  final int initialTab;

  const NewItemSheet({super.key, this.initialTab = 0});

  static Future<void> show(BuildContext context, {int initialTab = 0}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewItemSheet(initialTab: initialTab),
    );
  }

  @override
  State<NewItemSheet> createState() => _NewItemSheetState();
}

class _NewItemSheetState extends State<NewItemSheet> {
  late int _selectedTab;

  // Shared
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // Timer
  final _durationController = TextEditingController(text: '25');
  String? _audioFilePath;
  String? _audioFileName;

  // List
  final List<String> _checklistItems = [];
  final _checklistController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _checklistController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
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
  }

  void _addChecklistItem() {
    final text = _checklistController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _checklistItems.add(text);
        _checklistController.clear();
      });
    }
  }

  void _removeChecklistItem(int index) {
    setState(() {
      _checklistItems.removeAt(index);
    });
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
    final desc = _descController.text.trim();

    switch (_selectedTab) {
      case 0: // Note
        provider.addNote(title, description: desc);
        break;
      case 1: // Timer
        final duration =
            int.tryParse(_durationController.text.trim()) ?? 25;
        provider.addTimer(
          title,
          description: desc,
          durationMinutes: duration,
          audioFilePath: _audioFilePath ?? '',
        );
        break;
      case 2: // List
        final checklistJson = jsonEncode(
          _checklistItems
              .map((text) => {'text': text, 'done': false})
              .toList(),
        );
        provider.addList(title,
            description: desc, checklistJson: checklistJson);
        break;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          border: Border(
            top: BorderSide(color: Colors.white10),
            left: BorderSide(color: Colors.white10),
            right: BorderSide(color: Colors.white10),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('New Item', style: AppTextStyles.heading3),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close,
                          color: Colors.white54, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Tab selector
                _buildTabSelector(),
                const SizedBox(height: AppSpacing.lg),

                // Title
                TextField(
                  controller: _titleController,
                  style: AppTextStyles.heading3
                      .copyWith(color: AppColors.textSecondary),
                  decoration: InputDecoration(
                    hintText: _tabHintTitle,
                    hintStyle: AppTextStyles.heading3
                        .copyWith(color: Colors.white24),
                    border: InputBorder.none,
                  ),
                  autofocus: true,
                ),

                // Description (for Timer & List)
                if (_selectedTab == 0)
                  TextField(
                    controller: _descController,
                    style: AppTextStyles.body.copyWith(height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'Write your note here...',
                      hintStyle: AppTextStyles.body
                          .copyWith(color: Colors.white24),
                      border: InputBorder.none,
                    ),
                    maxLines: 5,
                    minLines: 3,
                  )
                else
                  TextField(
                    controller: _descController,
                    style: AppTextStyles.body.copyWith(height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'Add description or context...',
                      hintStyle: AppTextStyles.body
                          .copyWith(color: Colors.white24),
                      border: InputBorder.none,
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),

                // Type-specific fields
                if (_selectedTab == 1) ..._buildTimerFields(),
                if (_selectedTab == 2) ..._buildListFields(),

                const SizedBox(height: AppSpacing.lg),

                // Save button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _save,
                    child: Text(
                      _saveLabel,
                      style: AppTextStyles.button
                          .copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _tabHintTitle {
    switch (_selectedTab) {
      case 0:
        return 'Note Title';
      case 1:
        return 'Focus Session Title';
      case 2:
        return 'List Title';
      default:
        return 'Title';
    }
  }

  String get _saveLabel {
    switch (_selectedTab) {
      case 0:
        return 'Save Note';
      case 1:
        return 'Save Timer';
      case 2:
        return 'Save List';
      default:
        return 'Save';
    }
  }

  Widget _buildTabSelector() {
    const tabs = [
      (icon: Icons.description_outlined, label: 'Note'),
      (icon: Icons.timer_outlined, label: 'Timer'),
      (icon: Icons.checklist_outlined, label: 'List'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: AnimatedContainer(
              duration: AppAnimDurations.fast,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surfaceLight : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tabs[i].icon,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    tabs[i].label,
                    style: AppTextStyles.body.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildTimerFields() {
    return [
      const Divider(color: Colors.white10, height: 32),
      Text('Duration (minutes)',
          style: AppTextStyles.subtitle),
      const SizedBox(height: AppSpacing.sm),
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: TextField(
          controller: _durationController,
          keyboardType: TextInputType.number,
          style: AppTextStyles.body,
          decoration: const InputDecoration(border: InputBorder.none),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text('Background Audio (Optional)',
          style: AppTextStyles.subtitle),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          GestureDetector(
            onTap: _pickAudioFile,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
                  Text('Select Local Audio',
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
        ],
      ),
    ];
  }

  List<Widget> _buildListFields() {
    return [
      const Divider(color: Colors.white10, height: 32),
      Text('Checklist Items', style: AppTextStyles.subtitle),
      const SizedBox(height: AppSpacing.sm),
      ..._checklistItems.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              const Icon(Icons.check_box_outline_blank,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(entry.value, style: AppTextStyles.body),
              ),
              GestureDetector(
                onTap: () => _removeChecklistItem(entry.key),
                child: const Icon(Icons.close,
                    size: 16, color: Colors.white38),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: _checklistController,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Add new item...',
                  hintStyle:
                      AppTextStyles.body.copyWith(color: Colors.white24),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _addChecklistItem(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: _addChecklistItem,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.add, color: Colors.white54, size: 20),
            ),
          ),
        ],
      ),
    ];
  }
}
