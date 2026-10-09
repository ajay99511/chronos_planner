# 🤝 Contributing to Chronos Planner

Thank you for considering contributing to Chronos Planner! This document provides guidelines and instructions for contributing to the project.

By taking part you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

**If you read only one section, read [Pull Request
Process](#-pull-request-process).** The checks this project enforces are
stricter than Flutter's defaults in two ways that will otherwise waste your
time: `flutter analyze` must be run with `--fatal-infos --fatal-warnings`, and
`dart format` must *not* be run at all.

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

### 4. Run the checks CI will run

These are the exact gates in
[`.github/workflows/ci.yaml`](.github/workflows/ci.yaml). Running the short
version of any of them locally will pass while CI fails.

```bash
# Tests. Note the count before and after -- a change that adds behaviour
# should add a test that fails without it.
flutter test

# Analysis. The FLAGS MATTER: this project treats infos and warnings as
# errors, and a bare `flutter analyze` will not tell you so.
flutter analyze --fatal-infos --fatal-warnings

# Only if you touched lib/data/local/tables.dart or anything else with a
# generated *.g.dart. CI fails if regeneration produces a diff, and a stale
# .g.dart is invisible until runtime -- it surfaces as a missing column.
dart run build_runner build --delete-conflicting-outputs

# Android is the primary target, so this is part of the normal loop for any
# change under lib/ or android/.
flutter build apk --debug
```

> ### Do not run `dart format` on this repository
>
> `analysis_options.yaml` enables `require_trailing_commas`, which the
> formatter actively undoes. Running it produces a diff that then fails
> `flutter analyze --fatal-infos`, and it will touch dozens of files you did
> not intend to change. Match the surrounding style by hand instead. (If you
> want this fixed properly, the lint and the formatter have to be reconciled
> across the whole tree in one commit -- that is a welcome contribution, but
> it is its own PR.)

### Run the app

```bash
# Android -- the primary platform. Use a real device or an emulator; alarm
# and notification behaviour cannot be judged any other way.
flutter run -d android

# Windows and Linux are supported but secondary. Custom alarm sounds do not
# play there; see docs/decisions/0009.
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
// 1. Dart SDK
import 'dart:async';

// 2. Flutter and third-party packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 3. This package, by absolute `package:chronosky/...` path. Preferred over
//    relative paths for anything outside the current directory: it survives
//    a file being moved.
import 'package:chronosky/core/theme/app_theme.dart';

// 4. Relative, for close neighbours only
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

**These are targets, not gates.** CI measures coverage and uploads `lcov.info`
as an artifact, but nothing fails on a percentage — a number is easy to satisfy
without testing anything that matters. What is actually required of a PR is
narrower and harder to fake: new behaviour needs a test that **fails without
the change**.

| Component | Minimum Coverage |
|-----------|-----------------|
| Models | 90% |
| Providers | 80% |
| Repositories | 80% |
| Widgets | 60% |
| Screens | 40% |

---

## 🐛 Reporting Bugs

Open a [bug report](../../issues/new?template=bug_report.yml). The form asks
for the things that usually decide the bug, so please fill them in rather than
describing the problem in prose alone:

- **Platform and OS version.** For Android the API level matters: alarm,
  notification and exact-alarm behaviour all differ across 31, 32, 33 and 34+.
- **Whether the app was open, backgrounded or killed**, for anything involving
  an alarm or a timer.
- **Notification permission and battery optimisation state.** A great many
  "the alarm did not go off" reports are one of these two.

Before you file, check [`docs/decisions/`](docs/decisions/). A few limitations
are deliberate and already recorded with the reasoning — a custom alarm sound
not playing on Windows, for instance.

**Never report a security vulnerability in a public issue.** Use
[private reporting](../../security/advisories/new); see [SECURITY.md](SECURITY.md).

---

## 💡 Feature Requests

Open a [feature request](../../issues/new?template=feature_request.yml).

The most useful thing you can write is the **problem**, not the feature. A
clearly described problem often has a cheaper solution than the one that comes
to mind first, and this project prefers the cheaper one.

Two things weigh heavily in whether a request is taken up:

- **Which platform it is for.** Android is the primary target
  ([ADR 0010](docs/decisions/0010-android-first-os-level-alarms.md)). A
  desktop-only request is still welcome, but is weighed against that.
- **What it costs permanently.** A new dependency, a new OS permission, a
  schema migration or network access are all one-way doors to some degree. Say
  up front if your proposal needs one; it does not disqualify the request, it
  just changes the conversation.

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

### The description writes itself

**There is no template to copy from this file.** GitHub fills the description
box from [`.github/pull_request_template.md`](.github/pull_request_template.md)
automatically when you open a pull request. Work through it and delete the
sections that do not apply.

Two of its headings do most of the work and are worth reading before you start,
not after:

- **"What is NOT verified."** Required, and the single most useful line in a
  review here. Android's alarm behaviour cannot be proven by a unit test, and a
  PR that quietly implies otherwise costs more to review than one that says
  plainly what was not exercised.
- **"Risk and reversibility."** A one-way door — a published `applicationId`, a
  destructive migration, a stored data format — cannot be undone by reverting
  the commit. Saying so out loud is how it gets the attention it needs.

If you use `gh pr create`, pass `--body-file .github/pull_request_template.md`
or omit `--body` entirely; `--body "..."` silently bypasses the template.

### Before you open it

- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean
- [ ] `flutter test` passes, and new behaviour has a test that **fails without
      the change** — a test written against already-working code proves nothing
- [ ] `dart run build_runner build --delete-conflicting-outputs` leaves no diff
- [ ] `flutter build apk --debug` succeeds
- [ ] You did **not** run `dart format` (see above)
- [ ] An ADR exists for any decision that is expensive to reverse
- [ ] `CHANGELOG.md` has an entry under `Unreleased` for anything user-visible
- [ ] The branch is up to date with `master`

### Decision records

If your change commits the project to something that is awkward to undo, add a
record in [`docs/decisions/`](docs/decisions/) and link it from the PR. The
format and, more importantly, the reason the format insists on recording the
*losing* options are in
[`docs/decisions/README.md`](docs/decisions/README.md).

Things that have warranted one so far: adding a dependency, requesting an OS
permission, choosing a persistence layer, deciding *not* to build something and
leaving a seam instead.

An ADR can be opened as `Open` — a question recorded without an answer is far
more useful than an answer nobody wrote down.

### Touching the database

`lib/data/local/` is the one place where a mistake cannot be fixed by the next
release, because the user's rows are already gone. If you change the schema:

1. Bump `schemaVersion` and add a migration step for the new version.
2. Add a migration test that runs the **whole chain**, not just your step. An
   upgrade from v1 has to arrive at the same place as an upgrade from v9.
3. Guard anything that reads a column against that column not existing yet.
   Several migration steps run against older shapes of the table, and a
   `tableExists` / column guard is the existing convention for this.
4. Quarantine rows rather than deleting them
   ([ADR 0005](docs/decisions/0005-quarantine-not-delete-in-migrations.md)).
5. If you add a `CHECK` constraint, use the **table-level** `customConstraints`
   getter with the SQL written as an inline literal. Drift's generator reads the
   source AST, so a `const` reference or a helper's return value produces *no
   constraint at all* — and it will generate, analyse and run cleanly while
   enforcing nothing.

### Review process

1. **Automated checks** — CI runs analyze, tests and the codegen-drift check.
2. **Code review** — paths listed in [`.github/CODEOWNERS`](.github/CODEOWNERS)
   request the owner's review automatically. Note that it is a *request*: it
   only becomes a blocking requirement if branch protection on `master` is
   configured to require review from code owners, and GitHub never requests a
   review from the author of the PR.
3. **Feedback** — address the comments, or say why you disagree. Both are fine.
4. **Merge.**

---

## 🌍 Localization

**The app ships one locale, and there is no `lib/l10n/` directory.** That is
deliberate, not an oversight — see
[ADR 0007](docs/decisions/0007-i18n-seam-without-localisation.md).

What exists instead is a *seam*: [`lib/ui/strings.dart`](lib/ui/strings.dart)
holds the messages where English grammar would otherwise be compiled into the
widget tree — pluralisation, counts spliced into a sentence, text assembled
from fragments. Those are the ones that are expensive to retrofit and, worse,
invisible: they read as ordinary string interpolation. Fixed single-token labels
("Cancel", "Save") stay at their call sites, because moving them later is a
mechanical find-and-replace against that same class.

So:

- **Adding user-facing text that carries grammar?** Put it in `AppStrings`.
- **Adding a fixed label?** Leave it at the call site.
- **Never** concatenate or interpolate translated fragments. It is wrong in most
  languages and it hides the fact that it is wrong.

If you want to add a second locale properly, that is a welcome contribution and
a real one: every message in `AppStrings` becomes an ARB entry with a proper
`plural` clause, and the call sites do not change. Open an issue first so the
scope can be agreed — it touches tooling, not just strings.

---

## 📞 Getting Help

- **How something works:** [`docs/`](docs/), starting with
  [`docs/README.md`](docs/README.md).
- **Why something works that way:** [`docs/decisions/`](docs/decisions/). This
  is usually the faster answer, and several apparent bugs are recorded there as
  deliberate limitations.
- **A question, or something that fits neither issue form:**
  [open a blank issue](../../issues/new). They are enabled on purpose.
- **A security vulnerability:** never in a public issue — use
  [private reporting](../../security/advisories/new). See
  [SECURITY.md](SECURITY.md).

---

## 🏆 Recognition

Contributors appear in the repository's contributors graph, and significant
contributions are credited in [`CHANGELOG.md`](CHANGELOG.md) under the release
that carries them.

---

## 📄 License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).

---

Thank you for contributing to Chronos Planner! 🎉

Every contribution, no matter how small, makes a difference.
