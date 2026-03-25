# ⏱️ Chronos Planner

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-green)]()

**A futuristic time management application that transforms how you plan, track, and achieve your goals.**

[Features](#-features) • [Screenshots](#-screenshots) • [Quick Start](#-quick-start) • [Architecture](#-architecture) • [Documentation](#-documentation)

</div>

---

## 🌟 What is Chronos Planner?

Chronos Planner is a **desktop-first productivity application** built with Flutter that combines intelligent scheduling with beautiful, glassmorphic design. Unlike traditional todo apps, Chronos focuses on **time-blocking methodology** with energy-aware task scheduling and actionable productivity insights.

### Why Chronos?

| Traditional Apps | Chronos Planner |
|------------------|-----------------|
| Simple checklists | **Time-blocked schedules** |
| No context | **Energy-level matching** |
| Static lists | **Rolling 7-day planning** |
| Basic analytics | **Peak hour intelligence** |
| One-size-fits-all | **Recurring templates** |

---

## ✨ Features

### 📅 Smart Scheduling
- **Rolling Week View** — Always see the next 7 days starting from today
- **Time Blocking** — Assign specific time slots to tasks
- **Swipe Navigation** — Intuitive day-to-day navigation
- **Undo/Redo** — Mistake-friendly task management

### 🎯 Energy-Aware Intelligence
- **Energy Level Tracking** — Tag tasks as Low/Medium/High energy
- **Peak Hour Detection** — Automatically identifies your most productive hours
- **Smart Time Suggestions** — Recommends optimal scheduling based on historical performance
- **Efficiency Scoring** — Track completion rates and productivity trends

### 📋 Template System
- **Reusable Plans** — Create templates for recurring days (e.g., "Deep Work Friday")
- **Auto-Apply Scheduling** — Set templates to automatically apply on specific weekdays
- **Source Tracking** — Link scheduled tasks back to their template origin

### ✅ Todo Management
- **Standalone Tasks** — Manage todos separate from your calendar
- **Quick Capture** — Add tasks without time commitments
- **Progress Tracking** — Monitor completion status

### 📊 Analytics Dashboard
- **Efficiency Score** — Weekly completion percentage
- **Focus Time** — Total hours spent on scheduled tasks
- **Peak Hour Chart** — Visual heatmap of productive hours (24-hour display)
- **Category Distribution** — Time allocation across Work, Personal, Health, Leisure
- **Daily Progress** — Per-day completion rates

### 🎨 Desktop Experience
- **Focus Mode** — Compact floating window (320×200) with always-on-top
- **Glassmorphic UI** — Modern dark theme with neon accents
- **Responsive Layout** — Sidebar navigation (desktop) / Bottom nav (mobile)
- **Custom Window Management** — Optimized for Windows, Linux, macOS

---

## 📸 Screenshots

<div align="center">

| Schedule View | Analytics View |
|:---:|:---:|
| ![Schedule](docs/screenshots/schedule.png) | ![Analytics](docs/screenshots/analytics.png) |
| Rolling 7-day planner with task cards | Productivity insights and peak hour chart |

| Work Plans (Templates) | Focus Mode |
|:---:|:---:|
| ![Templates](docs/screenshots/templates.png) | ![Focus](docs/screenshots/focus.png) |
| Create and apply reusable day plans | Compact floating task widget |

</div>

> 🎨 **Design Language**: Dark mode with Material 3, Inter font, neon color accents (Blue `#4F46E5`, Purple `#A855F7`, Cyan `#06B6D4`)

---

## 🚀 Quick Start

### Prerequisites

Ensure you have the following installed:

```bash
# Flutter SDK (3.0+)
flutter --version

# Dart SDK (3.0+)
dart --version

# Desktop development
# Windows: Visual Studio 2022 with C++ desktop workload
# macOS: Xcode 14+
# Linux: GTK, Clang, CMake
```

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/chronos_planner.git
   cd chronos_planner
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Drift database code**
   ```bash
   dart run build_runner build
   ```

4. **Run the application**
   ```bash
   # Windows
   flutter run -d windows

   # macOS
   flutter run -d macos

   # Linux
   flutter run -d linux

   # Web (with WASM support)
   flutter run -d chrome --wasm
   ```

### Build for Production

```bash
# Windows executable
flutter build windows --release

# macOS app
flutter build macos --release

# Linux binary
flutter build linux --release

# Web deployment
flutter build web --wasm --release
```

---

## 🏗️ Architecture

Chronos follows a **clean layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────┐
│              UI Layer (Screens/Widgets)         │
│  home_screen, schedule_view, analytics_view...  │
├─────────────────────────────────────────────────┤
│         State Management (Providers)            │
│  ScheduleProvider, TodoProvider (ChangeNotifier)│
├─────────────────────────────────────────────────┤
│         Repository Pattern (Interfaces)         │
│  ScheduleRepository, TodoRepository, Template...│
├─────────────────────────────────────────────────┤
│      Data Layer (Local Implementations)         │
│  LocalScheduleRepository, LocalTodoRepository   │
├─────────────────────────────────────────────────┤
│           Database Access (Drift DAOs)          │
│  TaskDao, DayPlanDao, TemplateDao, TodoItemDao  │
├─────────────────────────────────────────────────┤
│              SQLite Database                    │
│         chronos_planner.sqlite                  │
└─────────────────────────────────────────────────┘
```

### Key Architectural Decisions

| Pattern | Purpose | Benefit |
|---------|---------|---------|
| **Repository** | Abstract data sources | Testable, swappable implementations |
| **Provider** | State management | Reactive UI updates, dependency injection |
| **Drift ORM** | Type-safe SQL | Compile-time query validation |
| **Rolling Week** | 7-day sliding window | Always relevant, no calendar navigation |
| **Template System** | Reusable day plans | Reduce repetitive scheduling |

---

## 📦 Tech Stack

### Core Technologies

| Technology | Version | Purpose |
|------------|---------|---------|
| [Flutter](https://flutter.dev) | 3.x | Cross-platform UI framework |
| [Dart](https://dart.dev) | 3.0+ | Programming language |
| [Drift](https://drift.simonbinder.eu) | 2.25.0 | Reactive SQLite ORM |
| [Provider](https://pub.dev/packages/provider) | 6.1.1 | State management |

### Key Packages

```yaml
dependencies:
  provider: ^6.1.1          # State management
  drift: ^2.25.0            # Database ORM
  sqlite3_flutter_libs      # SQLite bindings
  shared_preferences: ^2.2.2 # Legacy migration
  google_fonts: ^8.0.1      # Typography (Inter)
  uuid: ^4.3.3              # Unique ID generation
  intl: ^0.20.2             # Date/time formatting
  window_manager: ^0.5.1    # Desktop window control
  path_provider: ^2.1.0     # File system paths
  path: ^1.9.0              # Path manipulation
```

### Development Dependencies

```yaml
dev_dependencies:
  flutter_lints: ^6.0.0     # Linting rules
  drift_dev: ^2.25.0        # Drift code generation
  build_runner: ^2.4.0      # Code generation
  flutter_launcher_icons: ^0.14.3  # App icons
  flutter_test: sdk flutter # Testing framework
```

---

## 📚 Documentation

Comprehensive documentation is available in the [`docs/`](docs/) directory:

| Document | Description |
|----------|-------------|
| [Architecture](docs/ARCHITECTURE.md) | System overview, dependency flow, design decisions |
| [Core Layer](docs/CORE_LAYER.md) | Intelligence Service, Theme system |
| [Data Models](docs/DATA_MODELS.md) | Task, DayPlan, PlanTemplate domain models |
| [Database](docs/DATA_DATABASE.md) | Schema, DAOs, migrations |
| [Repositories](docs/DATA_REPOSITORIES.md) | Repository pattern, implementations |
| [Providers](docs/PROVIDERS.md) | State management, undo system, analytics |
| [Screens](docs/UI_SCREENS.md) | UI screens, navigation, interactions |
| [Widgets](docs/UI_WIDGETS.md) | Reusable components, glassmorphism |

---

## 🎯 Key Concepts

### Energy-Level Scheduling

Chronos introduces **energy-aware scheduling** to match tasks with your natural productivity rhythms:

```dart
enum TaskEnergyLevel { 
  low,    // Battery charging full - rest/recovery tasks
  medium, // Bolt - normal cognitive load
  high    // Flash on - deep work, creative tasks
}
```

The `IntelligenceService` analyzes your completion history to identify **peak hours** and recommends optimal scheduling:

```dart
// Example: High-energy tasks scheduled during peak success hours
final peaks = intelligenceService.getEnergyPeaks(taskHistory);
// Returns: {10: 0.85, 11: 0.90, 14: 0.65, ...}
// Recommendation: Schedule high-energy tasks at 11:00 (90% success rate)
```

### Rolling Week Model

Instead of traditional calendar navigation, Chronos uses a **rolling 7-day window**:

- **Auto-creates** missing days when loading
- **Week key format**: `YYYY-W##` (ISO week numbering)
- **Swipe gestures** to navigate days
- **Progress indicators** show completion status

### Template Recurring System

Create once, apply automatically:

```dart
// Set template to recur on Mon, Wed, Fri
template.activeDays = [0, 2, 4]; // 0=Monday

// Auto-apply logic:
// 1. Check if weekday matches activeDays
// 2. Verify sourceTemplateId doesn't already exist
// 3. Apply template tasks with new UUIDs
```

---

## 🛠️ Development

### Project Structure

```
lib/
├── core/
│   ├── services/
│   │   └── intelligence_service.dart    # Analytics & recommendations
│   └── theme/
│       └── app_theme.dart               # Design system
├── data/
│   ├── local/
│   │   ├── daos/                        # Drift DAOs
│   │   ├── app_database.dart            # Database setup
│   │   ├── tables.dart                  # Schema definitions
│   │   └── migration_helper.dart        # SP → Drift migration
│   ├── models/
│   │   ├── task_model.dart              # Task domain model
│   │   ├── day_plan_model.dart          # DayPlan aggregate
│   │   └── plan_template_model.dart     # Template model
│   └── repositories/
│       ├── local/                       # Local implementations
│       └── *.dart                       # Abstract interfaces
├── providers/
│   ├── schedule_provider.dart           # Schedule state management
│   └── todo_provider.dart               # Todo state management
└── ui/
    ├── screens/                         # App screens
    │   ├── home_screen.dart
    │   ├── schedule_view.dart
│   │   ├── work_plans_view.dart
│   │   ├── analytics_view.dart
│   │   ├── todo_list_view.dart
│   │   └── todo_detail_screen.dart
│   └── widgets/                         # Reusable components
│       ├── task_card.dart
│       ├── add_task_sheet.dart
│       ├── glass_container.dart
│       ├── focus_hud.dart
│       └── work_plan_detail_dialog.dart
```

### Running Code Generation

Drift requires code generation for type-safe queries:

```bash
# One-time build
dart run build_runner build

# Watch mode (auto-regenerate on changes)
dart run build_runner watch
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/providers/schedule_provider_test.dart

# Generate coverage
flutter test --coverage
```

---

## 🔮 Roadmap

### Coming Soon

- [ ] **Cloud Sync** — Optional cloud backup via Firebase/Supabase
- [ ] **Notifications** — Task reminders and daily planning prompts
- [ ] **Calendar Integration** — Import from Google Calendar, Outlook
- [ ] **Pomodoro Timer** — Built-in focus timer with break tracking
- [ ] **Export/Import** — JSON backup and restore
- [ ] **Themes** — Light mode + custom color schemes
- [ ] **Keyboard Shortcuts** — Power user productivity boosts
- [ ] **Widgets** — Home screen widgets (mobile)

### Under Consideration

- [ ] **AI Suggestions** — ML-based task duration estimation
- [ ] **Team Collaboration** — Shared plans for families/teams
- [ ] **Habit Tracking** — Recurring habit integration
- [ ] **Time Tracking** — Actual vs estimated time comparison

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Guidelines

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
- Add tests for new features
- Update documentation as needed
- Ensure `flutter analyze` passes with no warnings

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2026 Chronos Planner

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgments

- [Flutter Team](https://flutter.dev) for the amazing cross-platform framework
- [Drift](https://drift.simonbinder.eu) for the excellent SQLite ORM
- [Material Design 3](https://m3.material.io) for the design system
- [Google Fonts](https://fonts.google.com) for the Inter typeface

---

<div align="center">

**Made with ❤️ using Flutter**

[Report Bug](https://github.com/yourusername/chronos_planner/issues) • [Request Feature](https://github.com/yourusername/chronos_planner/issues) • [Discussions](https://github.com/yourusername/chronos_planner/discussions)

</div>
