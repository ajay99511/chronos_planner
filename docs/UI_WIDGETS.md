# UI Layer - Widgets Documentation

## Files
- `lib/ui/widgets/task_card.dart`
- `lib/ui/widgets/add_task_sheet.dart`
- `lib/ui/widgets/glass_container.dart`
- `lib/ui/widgets/focus_hud.dart`
- `lib/ui/widgets/work_plan_detail_dialog.dart`

---

## task_card.dart

### Purpose
Displays a single scheduled task with interactive gestures (swipe, long-press).

### Dependencies
- **Imports**: theme, `Task` model
- **Dependents**: `schedule_view.dart`

### Props

| Prop | Type | Purpose |
|------|------|---------|
| `task` | `Task` | Task data |
| `onToggle` | `VoidCallback` | Toggle completion |
| `onDelete` | `VoidCallback` | Delete task |
| `onEdit` | `VoidCallback?` | Edit task (optional) |
| `onDuplicate` | `VoidCallback?` | Duplicate task (optional) |

### Visual Structure

```
┌─────────────────────────────────────────┐
│ █ │ Title                  ⚡ Priority  │
│   │ 09:00 - 10:00  💪 HIGH  💼 WORK    │
│   │ Description (optional)              │
└─────────────────────────────────────────┘
```

### Color Mapping

#### Type Colors
```dart
Color _getTypeColor(TaskType type) {
  switch (type) {
    case TaskType.work:     return AppColors.work;      // Blue
    case TaskType.personal: return AppColors.personal;  // Purple
    case TaskType.health:   return AppColors.health;    // Green
    case TaskType.leisure:  return AppColors.leisure;   // Orange
  }
}
```

#### Priority Icons
```dart
IconData _getPriorityIcon(TaskPriority p) {
  switch (p) {
    case TaskPriority.low:    return Icons.keyboard_arrow_down;
    case TaskPriority.medium: return Icons.horizontal_rule;
    case TaskPriority.high:   return Icons.keyboard_arrow_up;
  }
}
```

#### Energy Icons
```dart
IconData _getEnergyIcon(TaskEnergyLevel e) {
  switch (e) {
    case TaskEnergyLevel.low:    return Icons.battery_charging_full;
    case TaskEnergyLevel.medium: return Icons.bolt;
    case TaskEnergyLevel.high:   return Icons.flash_on;
  }
}
```

### Interactive Features

#### Dismissible (Swipe to Delete)
```dart
Dismissible(
  key: Key(task.id),
  direction: DismissDirection.endToStart,
  onDismissed: (_) => onDelete(),
  background: Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 24),
    decoration: BoxDecoration(
      color: Colors.red.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Icon(Icons.delete, color: Colors.red),
  ),
  child: ...
)
```
- **Direction**: Right-to-left only
- **Background**: Red delete indicator

#### Long Press Context Menu
```dart
void _showContextMenu(BuildContext context, Offset position) {
  showMenu<String>(
    context: context,
    position: RelativeRect.fromRect(
      position & const Size(1, 1),
      Offset.zero & overlay.size,
    ),
    color: AppColors.surface,
    items: [
      PopupMenuItem(value: 'edit', child: Row(...Icon(Icons.edit)...)),
      PopupMenuItem(value: 'duplicate', child: Row(...Icon(Icons.copy)...)),
      PopupMenuItem(value: 'delete', child: Row(...Icon(Icons.delete)...)),
    ],
  ).then((value) {
    if (value == 'edit') onEdit?.call();
    if (value == 'duplicate') onDuplicate?.call();
    if (value == 'delete') onDelete();
  });
}
```
- **Trigger**: Long press
- **Position**: At touch location
- **Actions**: Edit, Duplicate, Delete

### Visual States

#### Completed
- Opacity: 0.5
- Strikethrough title
- Grey type indicator
- Check circle icon

#### Active
- Full opacity
- Colored type indicator with glow
- Energy/cost pills visible

### Pills Display

```dart
// Energy pill
Container(
  decoration: BoxDecoration(
    color: _getEnergyColor(task.energyLevel).withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(6),
  ),
  child: Row(children: [Icon(...), Text("HIGH")]),
)

// Cost pill (if > 0)
if (task.estimatedCost > 0)
  Container(
    decoration: BoxDecoration(
      color: AppColors.health.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(children: [Icon(Icons.attach_money), Text("50")]),
  )

// Category pill
Container(
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(6),
  ),
  child: Row(children: [Icon(...), Text("WORK")]),
)
```

### Animation
```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeOutCubic,
  child: AnimatedOpacity(
    duration: const Duration(milliseconds: 300),
    opacity: task.completed ? 0.5 : 1.0,
    ...
  ),
)
```

### Risk Areas
- **Overlay Position**: Context menu may overflow on small screens
- **Key Stability**: Uses `task.id` (stable UUID)
- **Gesture Conflict**: Dismissible vs. tap may conflict

---

## add_task_sheet.dart

### Purpose
Modal bottom sheet for creating/editing scheduled tasks.

### Dependencies
- **Imports**: `intl`, `provider`, `uuid`, theme, models, services
- **Dependents**: `schedule_view.dart`, `work_plan_detail_dialog.dart`

### Props

| Prop | Type | Purpose |
|------|------|---------|
| `onAdd` | `Function(Task, DateTime)` | Create callback |
| `onUpdate` | `Function(Task)?` | Update callback |
| `editingTask` | `Task?` | Task being edited |
| `defaultDate` | `DateTime?` | Pre-selected date |

### State

```dart
class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _costCtrl = TextEditingController(text: "0.0");
  late DateTime _selectedDate;
  String _startTime = "09:00";
  String _endTime = "10:00";
  TaskType _selectedType = TaskType.work;
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskEnergyLevel _selectedEnergy = TaskEnergyLevel.medium;
  String? _timeError;
  
  final _intelService = IntelligenceService();
}
```

### Smart Time Suggestion

#### `_suggestOptimalTime()`
```dart
void _suggestOptimalTime() {
  final provider = Provider.of<ScheduleProvider>(context, listen: false);
  final allHistory = provider.weekPlan.expand((d) => d.tasks).toList();
  final peaks = _intelService.getEnergyPeaks(allHistory);
  final suggestion = _intelService.recommendTime(_selectedEnergy, peaks);

  setState(() {
    _startTime = suggestion;
    final hour = int.parse(suggestion.split(':')[0]);
    _endTime = "${((hour + 1) % 24).toString().padLeft(2, '0')}:00";
    _validateTime();
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("Optimal time for $_selectedEnergy energy: $suggestion"),
      backgroundColor: AppColors.neonBlue,
      duration: const Duration(seconds: 2),
    ),
  );
}
```

**Logic**:
1. Gather all tasks from week
2. Calculate peak hours via `IntelligenceService`
3. Recommend time based on energy level
4. Set start time, auto-calculate end time (+1 hour)

**Usage**: "Suggest Time" button next to energy selector

### Date Picker

#### `_pickDate()`
```dart
Future<void> _pickDate() async {
  final picked = await showDatePicker(
    context: context,
    initialDate: _selectedDate,
    firstDate: DateTime.now().subtract(const Duration(days: 365)),
    lastDate: DateTime.now().add(const Duration(days: 365)),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.neonBlue,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    setState(() => _selectedDate = picked);
  }
}
```
- **Range**: ±365 days from today
- **Theme**: Custom dark theme matching app

### Time Validation

#### `_validateTime()`
```dart
void _validateTime() {
  try {
    final s = _startTime.split(':').map(int.parse).toList();
    final e = _endTime.split(':').map(int.parse).toList();
    final startMin = s[0] * 60 + s[1];
    final endMin = e[0] * 60 + e[1];

    if (startMin == endMin) {
      _timeError = 'End time must differ from start time';
    } else {
      _timeError = null;
    }
  } catch (_) {
    _timeError = 'Invalid time format';
  }
}
```
- **Allows**: Overnight (22:00-01:00)
- **Rejects**: Identical times

### Form Sections

1. **Title**: Required, auto-focus
2. **Description**: Optional, 2 lines
3. **Date**: Picker with formatted display
4. **Time**: Start/End pickers with validation
5. **Category**: Horizontal scroll chips (Work/Personal/Health/Leisure)
6. **Priority**: 3 chips (Low/Medium/High)
7. **Energy**: 3 chips (Low/Medium/High) + "Suggest Time" button
8. **Estimated Cost**: Decimal input with $ prefix

### Submit Logic

```dart
void _submit() {
  if (_titleCtrl.text.isEmpty) return;
  _validateTime();
  if (_timeError != null) return;

  final cost = double.tryParse(_costCtrl.text) ?? 0.0;

  if (_isEditing) {
    final updated = widget.editingTask!.copyWith(
      title: _titleCtrl.text,
      startTime: _startTime,
      endTime: _endTime,
      type: _selectedType,
      priority: _selectedPriority,
      energyLevel: _selectedEnergy,
      estimatedCost: cost,
      description: _descCtrl.text,
    );
    widget.onUpdate?.call(updated);
  } else {
    widget.onAdd(
      Task(
        id: const Uuid().v4(),
        title: _titleCtrl.text,
        startTime: _startTime,
        endTime: _endTime,
        type: _selectedType,
        priority: _selectedPriority,
        energyLevel: _selectedEnergy,
        estimatedCost: cost,
        description: _descCtrl.text,
      ),
      _selectedDate,
    );
  }
  Navigator.pop(context);
}
```

### Risk Areas
- **Time Parsing**: Assumes "HH:mm" format
- **Cost Parsing**: Silent fallback to 0.0
- **Edit Mode**: `onAdd` unused but required prop

---

## glass_container.dart

### Purpose
Reusable glassmorphism container with backdrop blur and optional gradient border.

### Dependencies
- **Imports**: `dart:ui`, theme
- **Dependents**: Multiple screens and widgets

### Props

| Prop | Type | Purpose |
|------|------|---------|
| `child` | `Widget` | Content |
| `padding` | `EdgeInsetsGeometry?` | Inner padding |
| `onTap` | `VoidCallback?` | Tap handler |
| `color` | `Color?` | Override background |
| `borderGradientColors` | `List<Color>?` | Gradient border |
| `blurSigma` | `double` | Blur intensity (default 10) |

### Features

#### Backdrop Blur
```dart
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
  child: Container(
    decoration: BoxDecoration(
      color: widget.color ?? AppColors.glassFill,
      border: Border.all(color: AppColors.glassBorder),
      borderRadius: BorderRadius.circular(AppRadius.xl),
    ),
    ...
  ),
)
```

#### Scale Animation on Tap
```dart
void _onTapDown(TapDownDetails _) {
  if (widget.onTap != null) setState(() => _scale = 0.97);
}

void _onTapUp(TapUpDetails _) {
  setState(() => _scale = 1.0);
  widget.onTap?.call();
}

AnimatedScale(
  scale: _scale,
  duration: AppAnimDurations.fast,
  curve: Curves.easeOutCubic,
  child: ...
)
```
- **Scale**: 0.97 on press, 1.0 on release
- **Duration**: 150ms

#### Gradient Border (Optional)
```dart
foregroundDecoration: hasBorderGradient
    ? BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.transparent, width: 1.5),
      )
    : null,
child: hasBorderGradient
    ? CustomPaint(
        painter: _GradientBorderPainter(
          colors: widget.borderGradientColors!,
          radius: AppRadius.xl,
        ),
        child: widget.child,
      )
    : widget.child,
```

**Painter**:
```dart
class _GradientBorderPainter extends CustomPainter {
  final List<Color> colors;
  final double radius;

  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rrect, paint);
  }
}
```

### Usage Examples

```dart
// Simple glass card
GlassContainer(
  child: Text("Content"),
)

// Interactive with gradient border
GlassContainer(
  onTap: () => print("tapped"),
  borderGradientColors: AppColors.gradientBlue,
  child: Text("Interactive card"),
)

// Custom blur
GlassContainer(
  blurSigma: 20,
  child: Text("More blur"),
)
```

### Risk Areas
- **Performance**: BackdropFilter is expensive on low-end devices
- **Gradient Border**: Uses `CustomPaint` (may need repaint optimization)

---

## focus_hud.dart

### Purpose
Minimal floating widget for Focus Mode (desktop window overlay).

### Dependencies
- **Imports**: `provider`, theme, models
- **Dependents**: `home_screen.dart`

### Props

| Prop | Type | Purpose |
|------|------|---------|
| `onExit` | `VoidCallback` | Exit focus mode |

### Layout

```
┌─────────────────────────────┐
│ ⚡ FOCUS MODE          ✕    │
│                             │
│ Current Task Title          │
│ 09:00 - 12:00               │
│                             │
│ [Complete]                  │
└─────────────────────────────┘
```

### Task Selection Logic
```dart
Task? activeTask;
try {
  activeTask = currentDay.tasks.firstWhere((t) => !t.completed);
} catch (_) {}
```
- **Finds**: First uncompleted task
- **Empty**: Shows "All caught up!"

### Complete Action
```dart
ElevatedButton(
  onPressed: () {
    provider.toggleTaskComplete(activeTask!.id);
  },
  child: Text("Complete"),
)
```
- **Updates**: Provider state
- **Refreshes**: Next task appears

### Visual Style
- Background: `AppColors.background` with 0.95 alpha
- Border: `AppColors.neonBlue` glow
- Compact: Designed for 320x200 window

### Risk Areas
- **Single Task**: Only shows one task at a time
- **No Navigation**: Can't switch days in focus mode

---

## work_plan_detail_dialog.dart

### Purpose
Full-featured template editor with task management and recurring schedule setup.

### Dependencies
- **Imports**: `provider`, theme, models, `AddTaskSheet`
- **Dependents**: `work_plans_view.dart`

### Props

| Prop | Type | Purpose |
|------|------|---------|
| `template` | `PlanTemplate` | Template to display/edit |

### State
```dart
class _WorkPlanDetailDialogState extends State<WorkPlanDetailDialog> {
  final Set<int> _selectedDays = {};
  late String _currentName;
  late String _currentDesc;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
}
```

### Layout Sections

1. **Header**: Name, description, recurring badge, edit button
2. **Task List**: Editable list of template tasks
3. **Add Task Button**: Opens `AddTaskSheet`
4. **Day Selector**: 7 day chips for scheduling
5. **Apply Buttons**: "This Week" / "Every Week"
6. **Delete Plan**: Footer action

### Task Operations

#### Add Task
```dart
void _addTask(BuildContext context, ScheduleProvider provider, String templateId) {
  showModalBottomSheet(
    context: context,
    builder: (_) => AddTaskSheet(
      onAdd: (task, _) => provider.addTaskToTemplate(templateId, task),
    ),
  );
}
```

#### Edit Task
```dart
void _editTask(BuildContext context, ScheduleProvider provider, Task task) {
  showModalBottomSheet(
    context: context,
    builder: (_) => AddTaskSheet(
      editingTask: task,
      onUpdate: (updated) =>
          provider.updateTaskInTemplate(widget.template.id, task.id, updated),
    ),
  );
}
```

#### Delete Task
```dart
provider.removeTaskFromTemplate(tmpl.id, task.id);
```

### Recurring Schedule

#### Day Selection
```dart
Row(
  children: List.generate(7, (i) {
    final isSelected = _selectedDays.contains(i);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDays.remove(i);
          } else {
            _selectedDays.add(i);
          }
        });
      },
      child: Text(_dayLabels[i]),
    );
  }),
)
```
- **Index**: 0=Monday, 6=Sunday
- **Multi-select**: Toggle on/off

#### Apply to This Week
```dart
ElevatedButton.icon(
  onPressed: _selectedDays.isEmpty || tmpl.tasks.isEmpty ? null : () {
    provider.applyTemplateToDays(tmpl, _selectedDays.toList());
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Applied to ${_selectedDays.length} day(s)")),
    );
  },
  icon: Icon(Icons.today),
  label: Text('This Week'),
)
```

#### Apply Every Week (Recurring)
```dart
ElevatedButton.icon(
  onPressed: _selectedDays.isEmpty || tmpl.tasks.isEmpty ? null : () {
    provider.setTemplateRecurring(tmpl.id, _selectedDays.toList());
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Recurring on ${_selectedDays.length} day(s)")),
    );
  },
  icon: Icon(Icons.repeat),
  label: Text('Every Week'),
)
```

#### Stop Recurring
```dart
if (tmpl.isRecurring)
  TextButton.icon(
    onPressed: () {
      provider.stopTemplateRecurring(tmpl.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recurring schedule stopped')),
      );
    },
    icon: Icon(Icons.stop_circle_outlined),
    label: Text('Stop Recurring'),
  )
```

### Edit Plan Info
```dart
void _editPlanInfo(BuildContext context, ScheduleProvider provider) {
  final nameCtrl = TextEditingController(text: _currentName);
  final descCtrl = TextEditingController(text: _currentDesc);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text("Edit Plan Info"),
      content: Column(children: [
        _buildTextField(nameCtrl, "Plan Name"),
        _buildTextField(descCtrl, "Description"),
      ]),
      actions: [
        ElevatedButton(
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
          child: Text("Save"),
        ),
      ],
    ),
  );
}
```

### Delete Plan Confirmation
```dart
showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text("Delete Plan?"),
    content: Text('This will permanently remove "${tmpl.name}".'),
    actions: [
      ElevatedButton(
        onPressed: () {
          provider.removeTemplate(tmpl.id);
          Navigator.pop(ctx); // close confirm
          Navigator.pop(context); // close detail
        },
        child: Text("Delete"),
      ),
    ],
  ),
);
```

### Task Tile (`_TemplatTaskTile`)

**Structure**:
```dart
Container(
  child: ListTile(
    leading: Container(width: 4, color: typeColor),
    title: Text(task.title),
    subtitle: Text("${task.startTime} – ${task.endTime} • ${task.type}"),
    trailing: Row(children: [
      IconButton(icon: Icon(Icons.edit_outlined), onPressed: onEdit),
      IconButton(icon: Icon(Icons.delete_outline), onPressed: onDelete),
    ]),
  ),
)
```

### Risk Areas
- **Live Updates**: Re-reads template from provider on each build
- **Day Index**: 0=Monday conversion may confuse users
- **Navigation**: Multiple `Navigator.pop()` calls can be confusing

---

## Widget Composition Map

```
home_screen.dart
├── _DesktopSidebar
│   └── _SidebarItem
└── FocusHudWidget

schedule_view.dart
├── TaskCard
├── AddTaskSheet (modal)
├── GlassContainer
└── _ActionButton

work_plans_view.dart
├── GlassContainer
└── WorkPlanDetailDialog (dialog)
    ├── _TemplatTaskTile
    └── AddTaskSheet (modal)

analytics_view.dart
├── GlassContainer
├── _EfficiencyCard
├── _TasksDoneCard
└── _DonutChartPainter

todo_list_view.dart
└── _TodoCard

todo_detail_screen.dart
    (standalone, no child widgets)
```
