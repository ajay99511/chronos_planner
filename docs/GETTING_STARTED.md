# 🚀 Getting Started with Chronos Planner

This guide will help you set up your development environment and start contributing to Chronos Planner.

---

## 📋 Prerequisites

### Required Software

| Software | Version | Purpose | Download |
|----------|---------|---------|----------|
| **Flutter SDK** | 3.0+ | UI Framework | [flutter.dev](https://docs.flutter.dev/get-started/install) |
| **Dart SDK** | 3.0+ | Language | Bundled with Flutter |
| **Git** | 2.x+ | Version Control | [git-scm.com](https://git-scm.com) |

### Platform-Specific Requirements

#### Windows
```bash
# Required: Visual Studio 2022 with "Desktop development with C++" workload
# Download: https://visualstudio.microsoft.com/downloads/

# In Visual Studio Installer, select:
✓ Desktop development with C++
✓ Windows 10 SDK (or later)
```

#### macOS
```bash
# Required: Xcode 14+
xcode-select --install

# Accept Xcode license
sudo xcodebuild -license accept
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
```

---

## 📥 Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/chronos_planner.git
cd chronos_planner
```

### Step 2: Verify Flutter Installation

```bash
# Check Flutter version (should be 3.0+)
flutter --version

# Run Flutter doctor to identify issues
flutter doctor

# Expected output:
# ✓ Flutter version
# ✓ Android toolchain (if developing for mobile)
# ✓ Xcode (macOS only)
# ✓ Chrome (if developing for web)
# ✓ Visual Studio (Windows only)
# ✓ Android Studio (optional)
```

### Step 3: Install Dependencies

```bash
flutter pub get
```

This downloads all packages defined in `pubspec.yaml`.

### Step 4: Generate Drift Database Code

Chronos uses Drift ORM which requires code generation:

```bash
# One-time build
dart run build_runner build

# Or use watch mode for development (auto-regenerates on changes)
dart run build_runner watch
```

**What this generates:**
- `*.g.dart` files with generated code
- Database accessors and type converters
- Query builders for type-safe SQL

### Step 5: Run the Application

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux

# Web (with WASM for better performance)
flutter run -d chrome --wasm

# Android (if testing on mobile)
flutter run -d android

# iOS (macOS only)
flutter run -d ios
```

---

## 🛠️ Development Workflow

### Hot Reload

Flutter supports hot reload for instant UI updates:

```bash
# While app is running, press:
r  # Hot reload
R  # Hot restart (full rebuild)
q  # Quit
```

### Debugging

```bash
# Run in debug mode (default)
flutter run -d windows

# Run with Dart DevTools
flutter run -d windows --devtools

# Open DevTools manually
flutter pub global activate devtools
flutter pub global run devtools
```

DevTools provides:
- Widget inspector
- Network profiler
- Performance timeline
- Memory view
- Logging

---

## 🧪 Testing

### Run All Tests

```bash
flutter test
```

### Run Specific Test

```bash
flutter test test/providers/schedule_provider_test.dart
```

### Run Tests with Coverage

```bash
flutter test --coverage

# View coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
start coverage/html/index.html  # Windows
xdg-open coverage/html/index.html  # Linux
```

### Test Structure

Tests are located in `test/` directory:

```
test/
├── models/
│   ├── task_model_test.dart
│   └── day_plan_model_test.dart
├── providers/
│   ├── schedule_provider_test.dart
│   └── todo_provider_test.dart
├── repositories/
│   ├── local_schedule_repository_test.dart
│   └── local_todo_repository_test.dart
└── widgets/
    ├── task_card_test.dart
    └── add_task_sheet_test.dart
```

### Writing Tests

Example test for `Task` model:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chronosky/data/models/task_model.dart';

void main() {
  group('Task Model', () {
    test('copyWith creates new instance with updated values', () {
      final task = Task(
        id: 'test-id',
        title: 'Original Task',
        startTime: '09:00',
        endTime: '10:00',
        type: TaskType.work,
      );

      final updated = task.copyWith(
        title: 'Updated Task',
        completed: true,
      );

      expect(updated.title, 'Updated Task');
      expect(updated.completed, true);
      expect(updated.id, 'test-id'); // Unchanged
    });

    test('toJson serializes correctly', () {
      final task = Task(
        id: 'test-id',
        title: 'Test',
        startTime: '09:00',
        endTime: '10:00',
        type: TaskType.work,
        priority: TaskPriority.high,
        energyLevel: TaskEnergyLevel.medium,
      );

      final json = task.toJson();

      expect(json['id'], 'test-id');
      expect(json['title'], 'Test');
      expect(json['priority'], 'TaskPriority.high');
    });
  });
}
```

---

## 📁 Project Structure

```
chronos_planner/
├── lib/                          # Source code
│   ├── core/                     # Core services & theme
│   │   ├── services/
│   │   │   └── intelligence_service.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   ├── data/                     # Data layer
│   │   ├── local/                # Drift database
│   │   │   ├── daos/
│   │   │   ├── app_database.dart
│   │   │   ├── tables.dart
│   │   │   └── migration_helper.dart
│   │   ├── models/               # Domain models
│   │   │   ├── task_model.dart
│   │   │   ├── day_plan_model.dart
│   │   │   └── plan_template_model.dart
│   │   └── repositories/         # Repository pattern
│   │       ├── local/
│   │       └── *.dart
│   ├── providers/                # State management
│   │   ├── schedule_provider.dart
│   │   └── todo_provider.dart
│   └── ui/                       # UI layer
│       ├── screens/
│       │   ├── home_screen.dart
│       │   ├── schedule_view.dart
│       │   ├── work_plans_view.dart
│       │   ├── analytics_view.dart
│       │   ├── todo_list_view.dart
│       │   └── todo_detail_screen.dart
│       └── widgets/
│           ├── task_card.dart
│           ├── add_task_sheet.dart
│           ├── glass_container.dart
│           ├── focus_hud.dart
│           └── work_plan_detail_dialog.dart
├── test/                         # Unit & widget tests
├── docs/                         # Documentation
├── assets/                       # Images, fonts, etc.
├── pubspec.yaml                  # Dependencies
└── analysis_options.yaml         # Linter rules
```

---

## 🔧 Common Development Tasks

### Adding a New Feature

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes** following the architecture patterns

3. **Run code generation** (if modifying Drift tables)
   ```bash
   dart run build_runner build
   ```

4. **Write tests** for new functionality

5. **Run linter**
   ```bash
   flutter analyze
   ```

6. **Commit changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

### Modifying the Database Schema

If you need to add/modify database tables:

1. **Edit `lib/data/local/tables.dart`**
   ```dart
   class Tasks extends Table {
     // Add new column
     TextColumn get newField => text().withDefault(const Constant(''))();
   }
   ```

2. **Increment schema version** in `app_database.dart`
   ```dart
   @override
   int get schemaVersion => 5; // Increment from 4 to 5
   ```

3. **Add migration logic**
   ```dart
   if (from < 5) {
     await customStatement("ALTER TABLE tasks ADD COLUMN new_field TEXT NOT NULL DEFAULT ''");
   }
   ```

4. **Run build_runner**
   ```bash
   dart run build_runner build
   ```

5. **Test migration** by running the app with existing data

### Adding a New Screen

1. **Create screen file** in `lib/ui/screens/`
   ```dart
   import 'package:flutter/material.dart';
   import '../../core/theme/app_theme.dart';

   class MyNewScreen extends StatelessWidget {
     const MyNewScreen({super.key});

     @override
     Widget build(BuildContext context) {
       return Scaffold(
         backgroundColor: AppColors.background,
         body: Center(
           child: Text('Hello', style: AppTextStyles.heading1),
         ),
       );
     }
   }
   ```

2. **Add to navigation** in `home_screen.dart`
   ```dart
   final List<Widget> _screens = const [
     ScheduleView(),
     WorkPlansView(),
     AnalyticsView(),
     TodoListView(),
     MyNewScreen(), // Add here
   ];
   ```

3. **Add navigation item** in sidebar/bottom nav

---

## 🐛 Troubleshooting

### Common Issues

#### "Build failed: Could not resolve package dependencies"

```bash
# Clean and reinstall dependencies
flutter clean
flutter pub get
dart run build_runner build
```

#### "Drift generated files out of date"

```bash
# Force rebuild
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

#### "Window manager not working on Windows"

Ensure you have the latest Visual Studio C++ redistributables:
```bash
# Download from Microsoft
https://aka.ms/vs/17/release/vc_redist.x64.exe
```

#### "Hot reload not working"

- Ensure you're in debug mode (not `--release`)
- Check for compilation errors in console
- Try hot restart (`R`) instead

#### "Tests failing with database errors"

Drift requires proper initialization in tests:
```dart
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
  });

  tearDown(() {
    db.close();
  });

  test('database operation', () async {
    // Your test here
  });
}
```

---

## 📚 Resources

### Official Documentation

- [Flutter Docs](https://docs.flutter.dev)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Drift Documentation](https://drift.simonbinder.eu)
- [Provider Package](https://pub.dev/packages/provider)

### Project Documentation

- [Architecture Overview](ARCHITECTURE.md)
- [Core Layer](CORE_LAYER.md)
- [Data Models](DATA_MODELS.md)
- [Database Schema](DATA_DATABASE.md)
- [Repositories](DATA_REPOSITORIES.md)
- [Providers](PROVIDERS.md)
- [UI Screens](UI_SCREENS.md)
- [UI Widgets](UI_WIDGETS.md)

### Community

- [Flutter Discord](https://discord.gg/rflutterdev)
- [Flutter Subreddit](https://reddit.com/r/FlutterDev)
- [Stack Overflow - Flutter Tag](https://stackoverflow.com/questions/tagged/flutter)

---

## ✅ Next Steps

Now that you're set up:

1. **Explore the codebase** - Start with `lib/main.dart`
2. **Run the app** - `flutter run -d windows` (or your platform)
3. **Make a small change** - Try modifying a color or text
4. **Read the docs** - Check out [ARCHITECTURE.md](ARCHITECTURE.md)
5. **Pick an issue** - Look for "good first issue" labels on GitHub

Happy coding! 🎉
