# Core Layer Documentation

## Files
- `lib/core/services/intelligence_service.dart`
- `lib/core/theme/app_theme.dart`

---

## intelligence_service.dart

### Purpose
Analytics and recommendation engine for productivity insights. Calculates efficiency scores, identifies peak hours, and suggests optimal task scheduling.

### Dependencies
- **Imports**: `task_model.dart`
- **Dependents**: `add_task_sheet.dart`, `analytics_view.dart`

### Key Functions

#### `calculateEfficiency(List<Task> tasks)`
- **Purpose**: Compute completion rate as percentage
- **Inputs**: List of Task objects
- **Outputs**: `double` (0-100)
- **Side Effects**: None (pure function)
- **Risk**: Returns 0.0 for empty lists (no error thrown)

#### `getEnergyPeaks(List<Task> history)`
- **Purpose**: Analyze historical tasks to find productive hours
- **Inputs**: List of completed/uncompleted tasks
- **Outputs**: `Map<int, double>` - hour (0-23) → success rate
- **Side Effects**: None
- **Risk**: Parses `startTime` string; assumes "HH:mm" format

#### `recommendTime(TaskEnergyLevel energy, Map<int, double> peaks)`
- **Purpose**: Suggest optimal time slot based on energy level
- **Inputs**: Energy level (low/medium/high), peak hours map
- **Outputs**: `String` - "HH:00" format
- **Logic**:
  - High energy → hour with highest success rate
  - Low energy → hour with lowest success rate (dip times)
  - Default → "09:00"
- **Side Effects**: None

#### `calculateTaskROI(Task task)`
- **Purpose**: Return on Investment = priority / cost
- **Inputs**: Task object
- **Outputs**: `double`
- **Risk**: Division by zero guarded (returns 1.0 if cost ≤ 0)

### Risk Areas
- **Tight Coupling**: Direct dependency on `Task` model structure
- **State**: Stateless service (no shared state concerns)
- **Critical Logic**: Peak hour calculation drives recommendations

---

## app_theme.dart

### Purpose
Centralized design system: colors, typography, spacing, shadows, animations. Single source of truth for visual consistency.

### Dependencies
- **Imports**: `flutter/material.dart`, `google_fonts`
- **Dependents**: Entire UI layer (all screens, widgets)

### Key Classes

#### `AppColors`
Static color palette:
- Backgrounds: `background`, `surface`, `surfaceLight`
- Accents: `neonBlue`, `neonPurple`, `neonCyan`
- Text: `textPrimary`, `textSecondary`
- Task types: `work`, `personal`, `health`, `leisure`
- Gradients: `gradientBlue`, `gradientPurple`, `gradientCyan`, `gradientSunrise`

#### `AppTextStyles`
Typography system using Google Fonts Inter:
- `heading1` (32px, bold)
- `heading2` (28px, bold)
- `heading3` (20px, bold)
- `subtitle` (14px, medium)
- `body` (14px, regular)
- `bodySmall` (12px, regular)
- `label` (10px, bold, letter-spacing 1.5)
- `chip` (12px, bold)
- `button` (16px, bold, white)

#### `AppSpacing`
Spacing scale (in pixels):
- `xs` (4), `sm` (8), `md` (16), `lg` (24), `xl` (32), `xxl` (48)

#### `AppRadius`
Border radius scale (in pixels):
- `sm` (8), `md` (12), `lg` (16), `xl` (20), `xxl` (24), `pill` (999)

#### `AppShadows`
Predefined shadow presets:
- `subtle`, `medium`, `elevated`
- `neonGlow(Color)` - customizable glow effect

#### `AppAnimDurations`
Animation timing constants:
- `fast` (150ms), `normal` (300ms), `slow` (500ms)
- `stagger` (50ms) - for staggered list animations

#### `AppGradients`
Reusable gradient presets:
- `primaryBlue`, `purple`, `surfaceCard`

### Risk Areas
- **Tight Coupling**: All UI components depend on this file
- **Changes Impact**: Any color/spacing change affects entire app
- **No Runtime Changes**: All values are compile-time constants

### Usage Pattern
```dart
// Always import and use theme constants
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    boxShadow: AppShadows.medium,
  ),
  padding: const EdgeInsets.all(AppSpacing.md),
)
```
