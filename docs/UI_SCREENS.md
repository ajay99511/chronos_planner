# UI Layer - Screens Documentation

## Files
- `lib/ui/screens/home_screen.dart`
- `lib/ui/screens/schedule_view.dart`
- `lib/ui/screens/work_plans_view.dart`
- `lib/ui/screens/analytics_view.dart`
- `lib/ui/screens/todo_list_view.dart`
- `lib/ui/screens/todo_detail_screen.dart`

---

## home_screen.dart

### Purpose
Root navigation container with sidebar (desktop) or bottom nav (mobile). Manages screen switching and Focus Mode.

### Dependencies
- **Imports**: `window_manager`, theme, screens, `FocusHudWidget`
- **Dependents**: `main.dart` (entry point)

### State Management
```dart
class _ChronosHomeState extends State<ChronosHome> {
  int _currentIndex = 0;
  bool _isFocusMode = false;
  
  final List<Widget> _screens = const [
    ScheduleView(),
    WorkPlansView(),
    AnalyticsView(),
    TodoListView(),
  ];
}
```

### Navigation Structure

| Index | Screen | Icon | Label |
|-------|--------|------|-------|
| 0 | `ScheduleView` | calendar_today | Schedule |
| 1 | `WorkPlansView` | layers_outlined | Plans |
| 2 | `AnalyticsView` | pie_chart_outline | Insights |
| 3 | `TodoListView` | check_box_outlined | Tasks |

### Focus Mode

#### `_toggleFocusMode()`
```dart
Future<void> _toggleFocusMode() async {
  setState(() => _isFocusMode = !_isFocusMode);

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    if (_isFocusMode) {
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setSize(const Size(320, 200));
      await windowManager.setAlignment(Alignment.topRight);
    } else {
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setSize(const Size(1200, 800));
      await windowManager.center();
    }
  }
}
```

**Behavior**:
- **Normal Mode**: 1200x800 window, centered
- **Focus Mode**: 320x200 floating window, top-right corner, always on top
- **Platform**: Desktop only (Windows, macOS, Linux)

**UI Changes**:
- Normal: Shows full app with navigation
- Focus: Shows only `FocusHudWidget` (current task + complete button)

### Desktop Sidebar (`_DesktopSidebar`)

**Layout**:
- Width: 250px
- Branding: "CHRONOS" logo with icon
- Focus Mode button
- Navigation items with hover/active states
- Footer: Version info

**Interactive States**:
- Hover: Highlight background
- Active: Blue accent bar + highlighted background
- Animation: 150ms transition

### Mobile Bottom Navigation

**Features**:
- Glassmorphism effect (backdrop blur)
- 4 items matching desktop nav
- Fixed type (no shifting)

### Responsive Detection
```dart
final isDesktop = MediaQuery.of(context).size.width > 800;
```
- **Desktop**: > 800px → sidebar layout
- **Mobile**: ≤ 800px → bottom nav

### Animation
```dart
AnimatedSwitcher(
  duration: AppAnimDurations.normal,
  transitionBuilder: (child, animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  },
  child: KeyedSubtree(
    key: ValueKey(_currentIndex),
    child: _screens[_currentIndex],
  ),
)
```
- **Fade + Slide**: Subtle entrance animation
- **Key-based**: Triggers on index change

### Risk Areas
- **Platform Checks**: Hardcoded for Windows/macOS/Linux
- **Window Size**: Fixed dimensions (may not suit all screens)
- **State Loss**: Focus Mode toggle resets on navigation

---

## schedule_view.dart

### Purpose
Main schedule view showing 7-day rolling week with task management.

### Dependencies
- **Imports**: `provider`, theme, widgets, models
- **Dependents**: User interaction

### Layout Structure

```
┌─────────────────────────────────────┐
│  Day Selector (7 tabs)              │
├─────────────────────────────────────┤
│  Header: Day name + Action toolbar  │
├─────────────────────────────────────┤
│  Task List (scrollable)             │
│  - TaskCard items                   │
│  - Empty state                      │
└─────────────────────────────────────┘
```

### Day Selector

**Behavior**:
- Horizontal row of 7 day cards
- Tap to select day
- Shows progress indicator for selected day
- Dot indicator for days with tasks

**Visual States**:
- **Selected**: Gradient background, glow shadow
- **Unselected**: Surface color
- **Has tasks**: Purple dot

### Action Toolbar

| Action | Icon | Purpose |
|--------|------|---------|
| Undo | undo | Revert last delete/clear |
| Sort | arrow_up/down | Toggle time sort |
| Save Template | save_outlined | Save day as template |
| Focus Mode | bolt | Enter focus mode (mobile) |
| Clear Day | delete_outline | Remove all tasks |
| Add Task | add (FAB style) | Open add dialog |

### Task List

**Features**:
- Swipe left to delete
- Long press for context menu (Edit/Duplicate/Delete)
- Swipe horizontal to change day
- Empty state with CTA

**Sorting**:
```dart
final sortedTasks = provider.getSortedTasks(dayPlan);
```
- Uses provider's `sortOrder` (asc/desc)

### Add Task Flow
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => AddTaskSheet(
    defaultDate: dayPlan.date,
    onAdd: (t, d) => provider.addTask(t, d),
  ),
);
```

### Edit Task Flow
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => AddTaskSheet(
    editingTask: task,
    onAdd: (_, __) {},
    onUpdate: (updated) => provider.updateTask(task.id, updated),
  ),
);
```

### Delete with Undo
```dart
provider.deleteTask(task.id);
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Deleted "${task.title}"'),
    action: SnackBarAction(
      label: 'UNDO',
      textColor: AppColors.neonBlue,
      onPressed: () => provider.undo(),
    ),
    duration: const Duration(seconds: 4),
  ),
);
```

### Save Template Dialog
```dart
void _showSaveTemplateDialog(BuildContext context, ScheduleProvider provider) {
  // Validate non-empty
  if (provider.selectedDay.tasks.isEmpty) return;
  
  // Show dialog with name/description fields
  // On save: provider.saveCurrentDayAsTemplate(name, desc)
}
```

### Clear Day Confirmation
```dart
void _confirmClearDay(BuildContext context, ScheduleProvider provider) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text("Clear All Tasks?"),
      content: Text("This will remove all ${provider.selectedDay.tasks.length} tasks"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            provider.clearDay();
            Navigator.pop(ctx);
            // Show undo snackbar
          },
          child: Text("Clear"),
        ),
      ],
    ),
  );
}
```

### Gesture Handling

#### Swipe to Change Day
```dart
GestureDetector(
  onHorizontalDragEnd: (details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 300) return; // ignore slow swipes
    
    final current = provider.selectedDayIndex;
    if (velocity < 0 && current < provider.weekPlan.length - 1) {
      provider.selectDay(current + 1); // swipe left → next
    } else if (velocity > 0 && current > 0) {
      provider.selectDay(current - 1); // swipe right → prev
    }
  },
  child: ListView(...),
)
```
- **Threshold**: 300 px/s velocity
- **Direction**: Swipe left = next day, swipe right = previous

### Risk Areas
- **Gesture Conflict**: Swipe may conflict with list scroll
- **Undo Timeout**: 4 seconds may be too short/long
- **Modal Bottom Sheet**: Not dismissible by backdrop tap (intentional)

---

## work_plans_view.dart

### Purpose
Template library for creating and managing reusable day plans.

### Dependencies
- **Imports**: `provider`, theme, widgets, models
- **Dependents**: User interaction

### Layout

```
┌─────────────────────────────────────┐
│  Header: "WorkPlans" + subtitle     │
├─────────────────────────────────────┤
│  Grid of Template Cards             │
│  ┌──────────┐ ┌──────────┐         │
│  │ Create + │ │ Template │         │
│  │          │ │   Card   │         │
│  └──────────┘ └──────────┘         │
└─────────────────────────────────────┘
```

### Create New Card
- **Position**: First in grid
- **Gradient**: Blue-purple
- **Action**: Opens create dialog

### Template Card

**Content**:
- Name + task count badge
- Description (2 lines max)
- "Recurring" badge if applicable
- Open button → detail dialog
- Apply button → apply to today

**Visual States**:
- **Recurring**: Blue badge with repeat icon
- **Stagger Animation**: Sequential fade-in

### Create Template Dialog
```dart
void _showCreateTemplateDialog(BuildContext context, ScheduleProvider provider) {
  // Show dialog with name/description fields
  // On create:
  final newTemplate = PlanTemplate(
    id: const Uuid().v4(),
    name: nameCtrl.text,
    description: descCtrl.text,
    tasks: [],
  );
  provider.addTemplate(newTemplate);
  // Immediately open detail dialog
}
```

### Apply to Today
```dart
final today = DateTime.now().weekday - 1;
provider.applyTemplateToDays(tmpl, [today]);
```
- **Index**: 0=Monday, 6=Sunday

### Grid Layout
```dart
GridView.count(
  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
  childAspectRatio: 1.8,
)
```
- **Desktop**: 3 columns
- **Mobile**: 1 column

### Risk Areas
- **Empty Template**: Created with no tasks; user must add via detail dialog
- **Apply Confirmation**: No confirmation before applying

---

## analytics_view.dart

### Purpose
Weekly productivity analytics and insights.

### Dependencies
- **Imports**: `provider`, theme, widgets, `IntelligenceService`
- **Dependents**: User viewing analytics

### Metrics Displayed

| Metric | Calculation | Source |
|--------|-------------|--------|
| Efficiency | completed / total × 100 | Provider |
| Est. Spending | Sum of `estimatedCost` | Provider |
| Focus Time | Sum of durations | Provider |
| Peak Hour | Best success rate hour | IntelligenceService |

### Energy Peaks Chart

**Visualization**: 24-hour bar chart
- **X-axis**: Hours 0-23 (labels every 4 hours)
- **Y-axis**: Success rate (0-100%)
- **Peak Highlight**: Cyan gradient for best hour
- **Normal**: Purple gradient

**Data Source**:
```dart
final energyPeaks = _intelService.getEnergyPeaks(allHistory);
```

### Time Distribution Donut

**Segments**: Work, Personal, Health, Leisure
**Center Label**: Total hours

**Painter**: `_DonutChartPainter`
- Draws arc segments proportional to hours
- Gap between segments (0.04 radians)
- Empty state: grey ring

### Daily Breakdown

**List**: 7 day cards with progress bars
- **Progress**: completed / total tasks
- **Label**: Day name (Mon, Tue, etc.)
- **Count**: "3/5" format

### Animation
- **Fade In**: 500ms on mount
- **Bar Charts**: 1000ms tween animation
- **Progress**: 600-800ms staggered

### Risk Areas
- **Data Scope**: Only shows current week (not historical)
- **Peak Calculation**: Requires completed tasks; empty for new users
- **Overnight Tasks**: Duration calculation handles 22:00-01:00

---

## todo_list_view.dart

### Purpose
Grid view of standalone todo items (not connected to calendar).

### Dependencies
- **Imports**: `provider`, theme, models
- **Dependents**: `TodoDetailScreen`

### Layout

```
┌─────────────────────────────────────┐
│  Header: "Tasks" + Add button       │
├─────────────────────────────────────┤
│  Grid of Todo Cards                 │
│  ┌─────┐ ┌─────┐ ┌─────┐           │
│  │     │ │     │ │     │           │
│  └─────┘ └─────┘ └─────┘           │
└─────────────────────────────────────┘
```

### Empty State
- Icon: `layers_clear`
- Message: "Your canvas is empty. Create a new task!"

### Todo Card

**Content**:
- Title (2 lines max)
- Description (4 lines max, expandable)
- Completion checkbox (top-right)
- "View detailed" hint

**Interaction**:
- Tap card → open detail screen
- Tap checkbox → toggle completion
- Long press: none (open detail for edit)

### Grid Layout
```dart
GridView.builder(
  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 300,
    mainAxisSpacing: AppSpacing.md,
    crossAxisSpacing: AppSpacing.md,
    childAspectRatio: 1.1,
  ),
)
```
- **Responsive**: Wraps based on width
- **Card Size**: Max 300px wide

### Add Todo
```dart
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
```
- **Custom Route**: Fade transition
- **Parameter**: `todo` null for create, value for edit

### Risk Areas
- **No Bulk Actions**: Must edit individually
- **No Sorting**: Order by `createdAt` (newest first)

---

## todo_detail_screen.dart

### Purpose
Full-screen editor for creating/editing todo items.

### Dependencies
- **Imports**: `provider`, theme, models
- **Dependents**: `TodoListView`

### States

#### Create Mode
- `_isEditing = true` initially
- Empty title/description
- Save button visible
- No completion status

#### Edit Mode (existing todo)
- `_isEditing = false` initially
- Pre-filled title/description
- Completion toggle visible
- Edit/Delete buttons in app bar

### Actions

| Action | Condition | Behavior |
|--------|-----------|----------|
| Save | `_isEditing` | Create or update |
| Edit | `!_isEditing` | Enable editing |
| Delete | Existing todo | Show confirmation |
| Toggle Complete | Existing todo | Toggle status |

### Delete Confirmation
```dart
Future<void> _delete() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Delete Task'),
      content: Text('Are you sure?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete')),
      ],
    ),
  );
  
  if (confirm == true && mounted) {
    await context.read<TodoProvider>().deleteTodo(widget.todo!.id);
    if (mounted) Navigator.pop(context);
  }
}
```

### Save Validation
```dart
void _save() {
  final title = _titleController.text.trim();
  if (title.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Title cannot be empty')),
    );
    return;
  }
  // Proceed with save
}
```

### Risk Areas
- **No Cancel**: Editing discards on back button (no prompt)
- **Auto-save**: None; explicit save required

---

## Screen Navigation Map

```
home_screen.dart (root)
├── schedule_view.dart
│   └── AddTaskSheet (modal)
├── work_plans_view.dart
│   └── WorkPlanDetailDialog (dialog)
│       └── AddTaskSheet (modal)
├── analytics_view.dart (no children)
└── todo_list_view.dart
    └── todo_detail_screen.dart (push route)
```
