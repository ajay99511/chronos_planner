# 🤝 Contributing to Chronos Planner

Thank you for considering contributing to Chronos Planner! This document provides guidelines and instructions for contributing to the project.

---

## 🌟 How to Contribute

### Types of Contributions We Welcome

| Type | Description | Examples |
|------|-------------|----------|
| **🐛 Bug Reports** | Report bugs you encounter | Crash reports, UI glitches, logic errors |
| **💡 Feature Requests** | Suggest new features | New integrations, UI improvements |
| **📝 Documentation** | Improve docs | Typos, clarifications, examples |
| **🔧 Code Contributions** | Fix bugs or add features | Bug fixes, new features, refactoring |
| **🎨 Design** | UI/UX improvements | Better layouts, animations, themes |
| **🧪 Testing** | Add or improve tests | Unit tests, integration tests |
| **🌍 Localization** | Translate the app | Adding support for new languages |

---

## 🚀 Quick Start for Contributors

### 1. Fork the Repository

```bash
# Click "Fork" on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/chronos_planner.git
cd chronos_planner
```

### 2. Create a Branch

```bash
# Always branch from master
git checkout master
git pull origin master

# Create feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/issue-123
```

### 3. Make Your Changes

Follow the [Development Guide](docs/GETTING_STARTED.md#development-workflow) for setup instructions.

### 4. Test Your Changes

```bash
# Run all tests
flutter test

# Run linter
flutter analyze

# Run the app manually
flutter run -d windows
```

### 5. Commit Your Changes

```bash
# Stage changes
git add .

# Commit with conventional commit message
git commit -m "feat: add your feature description"
```

### 6. Push and Create Pull Request

```bash
# Push to your fork
git push origin feature/your-feature-name

# Go to GitHub and create a Pull Request
```

---

## 📝 Coding Guidelines

### Dart Style Guide

Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide:

```dart
// ✅ DO: Use lowerCamelCase for variables and functions
var itemCount = 0;
void calculateTotal() { }

// ✅ DO: Use PascalCase for classes and enums
class TaskCard { }
enum TaskType { work, personal }

// ✅ DO: Use UPPERCASE for constants
const int maxItems = 100;

// ✅ DO: Use trailing commas for better formatting
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(8),
  ), // ← trailing comma
);

// ❌ DON'T: Use var for type annotations when clarity matters
final task = Task(id: '1', title: 'Test'); // ✅ OK
final Task task = Task(id: '1', title: 'Test'); // ✅ More explicit

// ❌ DON'T: Use unnecessary parentheses
if (condition) { } // ✅
if ((condition)) { } // ❌
```

### File Organization

```dart
// 1. Dart imports
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 2. Flutter imports
import 'package:chronosky/core/theme/app_theme.dart';

// 3. Relative imports
import '../../providers/schedule_provider.dart';
import '../widgets/task_card.dart';

// 4. Part directive (for Drift/codegen)
part 'your_file.g.dart';

// 5. Your code
class YourClass { }
```

### Documentation Comments

Use Dartdoc comments for public APIs:

```dart
/// Calculates an efficiency score (0-100) based on completed tasks.
///
/// ## Parameters
/// - [tasks]: List of tasks to analyze
///
/// ## Returns
/// Efficiency percentage (0.0 to 100.0)
///
/// ## Example
/// ```dart
/// final score = calculateEfficiency(tasks);
/// print('Efficiency: ${score.toStringAsFixed(1)}%');
/// ```
double calculateEfficiency(List<Task> tasks) {
  if (tasks.isEmpty) return 0.0;
  final completed = tasks.where((t) => t.completed).length;
  return (completed / tasks.length) * 100;
}
```

---

## 🏷️ Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

### Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat: add energy-level suggestions` |
| `fix` | Bug fix | `fix: resolve crash in analytics view` |
| `docs` | Documentation | `docs: update README installation steps` |
| `style` | Formatting | `style: fix indentation in task_card.dart` |
| `refactor` | Code restructuring | `refactor: extract validation logic to service` |
| `test` | Tests | `test: add unit tests for Task model` |
| `chore` | Maintenance | `chore: update dependencies to latest` |
| `perf` | Performance | `perf: optimize database queries` |
| `ui` | UI changes | `ui: improve task card animations` |

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Examples

```bash
# Simple commit
git commit -m "feat: add Pomodoro timer widget"

# With scope
git commit -m "feat(analytics): add peak hour heatmap visualization"

# With body
git commit -m "fix(schedule): resolve undo crash

- Fixed null pointer in undo stack
- Added null checks for deleted tasks
- Updated tests to cover edge case

Closes #142"
```

---

## 🧪 Testing Guidelines

### Writing Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chronosky/data/models/task_model.dart';

void main() {
  group('Task Model', () {
    // Group related tests

    test('copyWith creates new instance', () {
      // Arrange
      final task = Task(
        id: 'test-id',
        title: 'Original',
        startTime: '09:00',
        endTime: '10:00',
        type: TaskType.work,
      );

      // Act
      final updated = task.copyWith(title: 'Updated');

      // Assert
      expect(updated.title, 'Updated');
      expect(updated.id, 'test-id'); // Unchanged
    });

    test('fromJson handles missing optional fields', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 'test-id',
        'title': 'Test',
        'startTime': '09:00',
        'endTime': '10:00',
        'type': 'TaskType.work',
        // Missing optional fields
      };

      // Act
      final task = Task.fromJson(json);

      // Assert
      expect(task.energyLevel, TaskEnergyLevel.medium); // Default
      expect(task.estimatedCost, 0.0); // Default
    });
  });
}
```

### Test Coverage Goals

| Component | Minimum Coverage |
|-----------|-----------------|
| Models | 90% |
| Providers | 80% |
| Repositories | 80% |
| Widgets | 60% |
| Screens | 40% |

---

## 🐛 Reporting Bugs

### Bug Report Template

```markdown
### Describe the Bug
A clear and concise description of what the bug is.

### To Reproduce
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

### Expected Behavior
A clear and concise description of what you expected to happen.

### Screenshots
If applicable, add screenshots to help explain your problem.

### Environment
- OS: [e.g., Windows 11, macOS Sonoma]
- Flutter version: [e.g., 3.16.0]
- App version: [e.g., 1.0.0]

### Additional Context
Add any other context about the problem here.
```

### Where to Report

- **GitHub Issues**: https://github.com/yourusername/chronos_planner/issues
- **Discussions**: https://github.com/yourusername/chronos_planner/discussions (for questions)

---

## 💡 Feature Requests

### Feature Request Template

```markdown
### Problem Statement
Is your feature request related to a problem? A clear and concise description of what the problem is.

### Proposed Solution
A clear and concise description of what you want to happen.

### Alternatives Considered
A clear and concise description of any alternative solutions or features you've considered.

### Additional Context
Add any other context, mockups, or screenshots about the feature request here.

### Priority
[ ] Low - Nice to have
[ ] Medium - Would improve the experience
[ ] High - Critical for usability
```

---

## 🎨 UI/UX Contributions

### Design Principles

1. **Consistency** - Use existing design tokens from `app_theme.dart`
2. **Accessibility** - Ensure sufficient contrast ratios (WCAG AA)
3. **Responsiveness** - Test on different screen sizes
4. **Performance** - Avoid unnecessary animations or rebuilds

### Color Usage

```dart
// ✅ DO: Use theme constants
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    border: Border.all(color: AppColors.glassBorder),
  ),
)

// ❌ DON'T: Hardcode colors
Container(
  decoration: BoxDecoration(
    color: Color(0xFF1E293B), // ❌
  ),
)
```

### Spacing Usage

```dart
// ✅ DO: Use AppSpacing constants
Padding(
  padding: const EdgeInsets.all(AppSpacing.md),
  child: SizedBox(height: AppSpacing.sm),
)

// ❌ DON'T: Magic numbers
Padding(
  padding: const EdgeInsets.all(16), // ❌
)
```

---

## 📚 Documentation Contributions

### Documentation Standards

1. **Clarity** - Use simple, direct language
2. **Examples** - Include code examples where relevant
3. **Accuracy** - Keep docs in sync with code
4. **Completeness** - Document all public APIs

### Updating Documentation

```markdown
# Section Title

Brief description of what this section covers.

## Subsection

Details with examples:

```dart
// Code example
final task = Task(
  id: '123',
  title: 'Example',
);
```

### Key Points

- Bullet points for important notes
- Tables for comparisons
```

---

## 🔍 Pull Request Process

### PR Checklist

Before submitting your PR:

- [ ] Code follows style guidelines
- [ ] Tests are passing (`flutter test`)
- [ ] Linter passes (`flutter analyze`)
- [ ] Documentation is updated
- [ ] Commit messages follow convention
- [ ] Branch is up to date with master

### PR Template

```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update

## Testing
Describe tests performed:
- [ ] Unit tests added/updated
- [ ] Manual testing completed
- [ ] Tested on: Windows / macOS / Linux

## Screenshots (if applicable)
Add screenshots of UI changes.

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix/feature works
- [ ] New and existing tests pass locally
```

### Review Process

1. **Automated Checks** - CI runs tests and linter
2. **Code Review** - Maintainer reviews code quality
3. **Feedback** - Address any comments or requested changes
4. **Approval** - PR is approved and merged

---

## 🌍 Localization

### Adding a New Language

1. **Create localization file** in `lib/l10n/`
2. **Add translations** for all strings
3. **Update `l10n.yaml`** configuration
4. **Run generation**: `flutter gen-l10n`
5. **Test** the new language

Example:

```dart
// lib/l10n/app_en.arb
{
  "appTitle": "Chronos Planner",
  "scheduleView": "Schedule",
  "analyticsView": "Insights",
  "addTask": "Add Task",
  "deleteTask": "Delete Task"
}

// lib/l10n/app_es.arb
{
  "appTitle": "Planificador Chronos",
  "scheduleView": "Horario",
  "analyticsView": "Análisis",
  "addTask": "Agregar Tarea",
  "deleteTask": "Eliminar Tarea"
}
```

---

## 📞 Getting Help

- **Documentation**: Check [docs/](docs/) directory
- **Discussions**: https://github.com/yourusername/chronos_planner/discussions
- **Discord**: [Join our server](link) (if applicable)
- **Email**: your.email@example.com (if applicable)

---

## 🏆 Recognition

Contributors will be recognized in:

- [CONTRIBUTORS.md](CONTRIBUTORS.md) file
- Release notes for significant contributions
- GitHub Contributors graph

---

## 📄 License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).

---

Thank you for contributing to Chronos Planner! 🎉

Every contribution, no matter how small, makes a difference.
