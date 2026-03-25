# ✨ Chronos Planner - Features

A comprehensive guide to all features available in Chronos Planner, including planned enhancements and future roadmap.

---

## 📋 Table of Contents

- [Core Features](#-core-features)
- [Scheduling](#-scheduling)
- [Templates](#-templates)
- [Analytics](#-analytics)
- [Todo Management](#-todo-management)
- [Desktop Experience](#-desktop-experience)
- [Design System](#-design-system)
- [Coming Soon](#-coming-soon)
- [Roadmap](#-roadmap)
- [Under Consideration](#-under-consideration)

---

## 🎯 Core Features

### Time Blocking Methodology

Chronos is built on the **time-blocking** principle: instead of simple checklists, you schedule specific tasks at specific times.

**Benefits:**
- ✅ Better time awareness
- ✅ Realistic daily planning
- ✅ Reduced decision fatigue
- ✅ Improved focus

**How it Works:**
1. Create a task with a title
2. Assign a time range (e.g., 09:00 - 10:30)
3. Categorize by type (Work, Personal, Health, Leisure)
4. Set energy level (Low, Medium, High)
5. Track completion

---

## 📅 Scheduling

### Rolling Week View

**Status:** ✅ Available

Always see the next 7 days starting from today. No need to navigate calendars or select dates manually.

**Features:**
- Auto-creates missing days when loading
- Week key format: `YYYY-W##` (ISO week numbering)
- Progress indicators show completion status per day
- Dot indicators for days with tasks

**Navigation:**
- Tap day card to select
- Swipe left/right to change days
- Animated transitions between days

---

### Task Management

**Status:** ✅ Available

Full CRUD operations for scheduled tasks.

**Create Tasks:**
- Title (required)
- Description (optional)
- Time range (start/end)
- Category (Work/Personal/Health/Leisure)
- Priority (Low/Medium/High)
- Energy Level (Low/Medium/High)
- Estimated Cost (for budget tracking)

**Edit Tasks:**
- Long press for context menu
- Swipe to delete with undo
- Toggle completion status
- Duplicate tasks

**Task Properties:**

| Property | Type | Description |
|----------|------|-------------|
| Title | String | Task name (1-200 chars) |
| Description | String | Details (optional) |
| Start Time | String | "HH:mm" format |
| End Time | String | "HH:mm" format |
| Type | Enum | Work, Personal, Health, Leisure |
| Priority | Enum | Low, Medium, High |
| Energy Level | Enum | Low, Medium, High |
| Estimated Cost | Double | Planned cost (default 0.0) |
| Actual Cost | Double | Actual cost (default 0.0) |
| Completed | Boolean | Completion status |
| Source Template ID | String | Link to template (if applicable) |

---

### Sort & Filter

**Status:** ✅ Available

**Sorting Options:**
- Ascending (earliest first)
- Descending (latest first)
- Persistent across sessions

**Current Limitations:**
- No filtering by type/priority (planned)
- No custom sort orders (planned)

---

### Undo/Redo System

**Status:** ✅ Available (Limited)

**Supported Actions:**
- Undo task deletion (4-second window)
- Undo clear day (4-second window)

**How it Works:**
1. Action is performed (delete/clear)
2. SnackBar appears with "UNDO" button
3. Click UNDO within 4 seconds to restore
4. Action stack is cleared after timeout

**Limitations:**
- Not persisted across app restarts
- No redo functionality (yet)
- Limited to delete/clear actions

---

## 📋 Templates

### Work Plans (Template System)

**Status:** ✅ Available

Create reusable day plans and apply them to specific dates.

**Create Templates:**
1. Name your template (e.g., "Deep Work Friday")
2. Add description (optional)
3. Add tasks with time slots
4. Save for later use

**Template Properties:**

| Property | Type | Description |
|----------|------|-------------|
| ID | String | UUID v4 |
| Name | String | Template name (1-100 chars) |
| Description | String | Details (optional) |
| Tasks | List<Task> | Template tasks |
| Active Days | List<int> | Recurring schedule (0=Mon, 6=Sun) |
| Is Recurring | Computed | True if activeDays is not empty |

---

### Recurring Templates

**Status:** ✅ Available

Set templates to automatically apply on specific weekdays.

**How it Works:**
1. Create or edit a template
2. Select weekdays (Mon, Wed, Fri, etc.)
3. Choose "Every Week" to set recurring
4. Template auto-applies to matching days

**Example:**
```dart
// "Deep Work Friday" recurs every Friday
template.activeDays = [4]; // 4 = Friday (0=Monday)

// Auto-apply logic:
// 1. Check if current week has Friday
// 2. Verify template not already applied
// 3. Add template tasks with new UUIDs
// 4. Set sourceTemplateId for tracking
```

**Benefits:**
- ✅ Set up once, applies forever
- ✅ Skip manual weekly planning
- ✅ Consistent routines
- ✅ Source tracking links tasks to templates

---

### Apply Templates

**Status:** ✅ Available

**Apply Options:**
- **This Week** - Apply to selected days in current week only
- **Every Week** - Set as recurring (see above)

**Apply Flow:**
1. Open template detail dialog
2. Select target days (Mon, Tue, etc.)
3. Click "This Week" or "Every Week"
4. Tasks are added to selected days

**Conflict Resolution:**
- Tasks with same `sourceTemplateId` are skipped
- Prevents duplicate applications
- Manual edits preserve source tracking

---

## 📊 Analytics

### Weekly Insights

**Status:** ✅ Available

Track your productivity with actionable metrics.

**Key Metrics:**

| Metric | Description | Calculation |
|--------|-------------|-------------|
| **Efficiency Score** | Completion rate percentage | `completed / total × 100` |
| **Estimated Spending** | Total planned cost | Sum of `estimatedCost` for all tasks |
| **Focus Time** | Total hours scheduled | Sum of task durations |
| **Peak Hour** | Most productive hour | Hour with highest completion success rate |

---

### Energy Peaks Chart

**Status:** ✅ Available

Visual heatmap showing your productivity by hour of day.

**Features:**
- 24-hour display (0-23)
- Success rate per hour (0-100%)
- Peak hour highlighted in cyan
- Other hours in purple gradient
- Animated bar heights

**How it Works:**
1. Analyze all completed/uncompleted tasks
2. Group by start hour
3. Calculate success rate per hour
4. Display as bar chart

**Example:**
```
Hour 10: 85% success rate (████████░) ← Peak
Hour 14: 65% success rate (██████░░░)
Hour 16: 45% success rate (████░░░░░)
```

**Use Cases:**
- Schedule high-energy tasks during peak hours
- Avoid important meetings during dip times
- Understand your natural rhythms

---

### Category Distribution

**Status:** ✅ Available

See how you allocate time across life domains.

**Categories:**
- 🔵 Work
- 🟣 Personal
- 🟢 Health
- 🟠 Leisure

**Visualization:**
- Donut chart with color-coded segments
- Center label shows total hours
- Segments proportional to time spent

**Example:**
```
Work:     25 hours (55%)
Personal: 12 hours (26%)
Health:    5 hours (11%)
Leisure:   3 hours ( 8%)
Total:    45 hours
```

---

### Daily Progress

**Status:** ✅ Available

Per-day breakdown of task completion.

**Display:**
- List of 7 days
- Progress bar per day
- Completion count (e.g., "3/5")
- Day name (Mon, Tue, etc.)

**Use Cases:**
- Identify productive vs unproductive days
- Track consistency
- Spot patterns (e.g., low Friday completion)

---

## ✅ Todo Management

### Standalone Todos

**Status:** ✅ Available

Manage tasks that aren't tied to your calendar.

**Features:**
- Create todos without time slots
- Toggle completion status
- Add descriptions
- Organize in grid view
- Sort by creation date (newest first)

**Todo Properties:**

| Property | Type | Description |
|----------|------|-------------|
| ID | String | UUID v4 |
| Title | String | Task name (1-200 chars) |
| Description | String | Details (optional) |
| Completed | Boolean | Completion status |
| Created At | DateTime | Creation timestamp |

---

### Todo Detail Screen

**Status:** ✅ Available

Full-screen editor for todos.

**Actions:**
- Create new todo
- Edit existing todo
- Toggle completion
- Delete with confirmation
- Navigate back to list

**Validation:**
- Title required
- Empty title shows error message
- No auto-save (explicit save required)

---

## 🖥️ Desktop Experience

### Focus Mode

**Status:** ✅ Available (Desktop Only)

Compact floating window for maximum focus.

**Features:**
- 320×200 pixel window
- Always-on-top
- Positioned in top-right corner
- Shows current task only
- Quick complete button

**How to Use:**
1. Click "Focus Mode" button (bolt icon)
2. Window shrinks to compact size
3. See next uncompleted task
4. Click "Complete" to mark done
5. Next task appears automatically
6. Exit to return to full app

**Platform Support:**
- ✅ Windows
- ✅ macOS
- ✅ Linux
- ❌ Mobile (not applicable)
- ❌ Web (not applicable)

---

### Window Management

**Status:** ✅ Available

Custom window sizing and positioning.

**Normal Mode:**
- Size: 1200×800 pixels
- Position: Centered
- Title bar: Hidden (custom UI)

**Focus Mode:**
- Size: 320×200 pixels
- Position: Top-right corner
- Always on top: Enabled

**Implementation:**
```dart
import 'package:window_manager/window_manager.dart';

// Enter Focus Mode
await windowManager.setAlwaysOnTop(true);
await windowManager.setSize(const Size(320, 200));
await windowManager.setAlignment(Alignment.topRight);

// Exit Focus Mode
await windowManager.setAlwaysOnTop(false);
await windowManager.setSize(const Size(1200, 800));
await windowManager.center();
```

---

### Responsive Layout

**Status:** ✅ Available

Adapts to screen size automatically.

**Desktop (>800px):**
- Sidebar navigation (250px width)
- Branding + version footer
- Focus Mode button
- 4 main sections

**Mobile (≤800px):**
- Bottom navigation bar
- Glassmorphism effect
- 4 sections with icons + labels

**Sections:**
1. Schedule (calendar icon)
2. Work Plans (layers icon)
3. Analytics (pie chart icon)
4. Tasks (checkbox icon)

---

## 🎨 Design System

### Glassmorphic UI

**Status:** ✅ Available

Modern glassmorphism design language.

**Features:**
- Backdrop blur effects
- Semi-transparent surfaces
- Subtle borders
- Neon accent glows

**Components:**
- `GlassContainer` - Reusable glass card
- `TaskCard` - Task display with glass effect
- Bottom navigation with blur
- Dialog backgrounds

**Theme Constants:**
```dart
// Colors
AppColors.background    // #0F172A (dark blue)
AppColors.surface       // #1E293B (slate)
AppColors.neonBlue      // #4F46E5 (indigo)
AppColors.neonPurple    // #A855F7 (purple)
AppColors.neonCyan      // #06B6D4 (cyan)

// Typography (Google Fonts Inter)
AppTextStyles.heading1  // 32px, bold
AppTextStyles.heading2  // 28px, bold
AppTextStyles.heading3  // 20px, bold
AppTextStyles.body      // 14px, regular

// Spacing
AppSpacing.xs  // 4px
AppSpacing.sm  // 8px
AppSpacing.md  // 16px
AppSpacing.lg  // 24px
AppSpacing.xl  // 32px

// Border Radius
AppRadius.sm   // 8px
AppRadius.md   // 12px
AppRadius.lg   // 16px
AppRadius.xl   // 20px
```

---

### Animations

**Status:** ✅ Available

Smooth, purposeful animations.

**Durations:**
- Fast: 150ms (hover states, small transitions)
- Normal: 300ms (screen transitions, card animations)
- Slow: 500ms (fade-ins, complex animations)
- Stagger: 50ms (list item delays)

**Examples:**
- Screen fade + slide on navigation
- Task card completion animation
- Progress bar transitions
- Chart bar animations (1000ms)

---

## 🚀 Coming Soon

### Notifications
**Target:** Q2 2026

- Task reminders (5 min before)
- Daily planning prompt (morning)
- End-of-day review (evening)
- Customizable notification sounds

---

### Calendar Integration
**Target:** Q3 2026

- Google Calendar sync
- Outlook integration
- Import existing events
- Two-way sync (optional)

---

### Pomodoro Timer
**Target:** Q2 2026

- Built-in focus timer
- 25/5 minute cycles
- Break tracking
- Statistics per task

---

### Export/Import
**Target:** Q2 2026

- JSON backup
- Restore from backup
- Export to CSV
- Share templates

---

### Themes
**Target:** Q3 2026

- Light mode
- Custom color schemes
- Accent color picker
- Dark mode variations

---

### Keyboard Shortcuts
**Target:** Q3 2026

- `Ctrl+N` - New task
- `Ctrl+F` - Focus mode
- `Ctrl+S` - Save template
- `Ctrl+Z` - Undo
- `Ctrl+1-4` - Switch tabs

---

## 🛣️ Roadmap

### Version 1.1 (Q2 2026)
- [x] Energy-level scheduling
- [x] Peak hour analytics
- [ ] Notifications
- [ ] Pomodoro timer
- [ ] Export/Import

### Version 1.2 (Q3 2026)
- [ ] Calendar integration
- [ ] Light mode theme
- [ ] Keyboard shortcuts
- [ ] Home screen widgets (mobile)

### Version 1.3 (Q4 2026)
- [ ] Cloud sync (optional)
- [ ] Team collaboration
- [ ] Habit tracking
- [ ] Time tracking (actual vs estimated)

---

## 💡 Under Consideration

These features are being explored but not yet committed to the roadmap.

### AI-Powered Suggestions
- ML-based task duration estimation
- Smart scheduling recommendations
- Pattern recognition (e.g., "You always skip Monday morning tasks")

### Team Collaboration
- Shared plans for families
- Team task assignments
- Shared templates
- Collaboration analytics

### Habit Tracking
- Recurring habit integration
- Streak tracking
- Habit analytics
- Habit-template linking

### Advanced Analytics
- Weekly trends
- Monthly reports
- Goal tracking
- Productivity score (composite metric)

### Voice Input
- Voice-to-text for task creation
- Voice commands ("Add meeting at 3 PM")
- Hands-free operation

### Wearable Integration
- Smartwatch notifications
- Quick complete from watch
- Activity sync (health tasks)

---

## 📊 Feature Status Legend

| Status | Badge | Description |
|--------|-------|-------------|
| ✅ Available | Green | Fully implemented and tested |
| 🚧 In Progress | Yellow | Currently being developed |
| 📅 Planned | Blue | Committed to roadmap |
| 💡 Proposed | Purple | Under consideration |
| ❌ Deprecated | Red | Being phased out |

---

## 🙋 Feature Requests

Have an idea for a new feature? We'd love to hear it!

**Submit a Feature Request:**
1. Go to [GitHub Issues](https://github.com/yourusername/chronos_planner/issues)
2. Click "New Issue"
3. Select "Feature Request" template
4. Fill in details and submit

**What Makes a Great Feature Request:**
- Clear problem statement
- Proposed solution
- Use case examples
- Priority level
- Mockups or sketches (optional but helpful!)

---

## 📝 Version History

### Version 1.0.0 (March 2026)
**Initial Release**
- Rolling week scheduler
- Task management with energy levels
- Template system with recurring support
- Analytics dashboard with energy peaks
- Todo list management
- Focus Mode for desktop
- Glassmorphic dark theme

---

Thank you for using Chronos Planner! ⏱️

For technical details, see the [Documentation](docs/).
