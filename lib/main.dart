import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'core/theme/app_theme.dart';
import 'data/local/app_database.dart';
import 'data/local/migration_helper.dart';
import 'data/repositories/local/local_preference_repository.dart';
import 'data/repositories/local/local_schedule_repository.dart';
import 'data/repositories/local/local_template_repository.dart';
import 'data/repositories/local/local_todo_repository.dart';
import 'data/repositories/preference_repository.dart';
import 'data/repositories/schedule_repository.dart';
import 'data/repositories/template_repository.dart';
import 'data/repositories/todo_repository.dart';
import 'providers/schedule_provider.dart';
import 'providers/todo_provider.dart';
import 'ui/screens/home_screen.dart';

/// Application entry point.
/// 
/// Initialization sequence:
/// 1. Ensure Flutter bindings are initialized
/// 2. Configure desktop window (Windows/Linux/macOS only)
/// 3. Initialize Drift database
/// 4. Run one-time migration from SharedPreferences
/// 5. Create repository instances with dependency injection
/// 6. Launch app with providers
/// 
/// Architecture:
/// - MultiProvider for state management (ScheduleProvider, TodoProvider)
/// - Repository pattern for data abstraction
/// - Theme based on AppColors (dark mode, neon accents)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // For a custom glass title bar later if desired, or normal
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize database & run one-time migration from SharedPreferences
  final db = AppDatabase.instance;
  await MigrationHelper.migrateIfNeeded(db);

  // Create local repositories
  final scheduleRepo = LocalScheduleRepository(db.dayPlanDao, db.taskDao);
  final templateRepo = LocalTemplateRepository(db.templateDao);
  final prefRepo = LocalPreferenceRepository(db.preferenceDao);
  final todoRepo = LocalTodoRepository(db.todoItemDao);

  runApp(MyApp(
    scheduleRepo: scheduleRepo,
    templateRepo: templateRepo,
    prefRepo: prefRepo,
    todoRepo: todoRepo,
  ));
}

/// Root application widget with dependency injection.
/// 
/// Injects repositories into providers via constructor:
/// - [ScheduleProvider]: Manages weekly schedule, templates, analytics
/// - [TodoProvider]: Manages standalone todo items
/// 
/// Theme configuration:
/// - Dark mode with Material 3
/// - Inter font family (Google Fonts)
/// - Custom color scheme from [AppColors]
/// 
/// Navigation:
/// - [ChronosHome] as root with internal tab navigation
class MyApp extends StatelessWidget {
  final ScheduleRepository scheduleRepo;
  final TemplateRepository templateRepo;
  final PreferenceRepository prefRepo;
  final TodoRepository todoRepo;

  const MyApp({
    super.key,
    required this.scheduleRepo,
    required this.templateRepo,
    required this.prefRepo,
    required this.todoRepo,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ScheduleProvider(
            scheduleRepo: scheduleRepo,
            templateRepo: templateRepo,
            prefRepo: prefRepo,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TodoProvider(todoRepo),
        ),
      ],
      child: MaterialApp(
        title: 'Chronos',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          colorScheme: const ColorScheme.dark(
            primary: AppColors.neonBlue,
            secondary: AppColors.neonPurple,
            surface: AppColors.surface,
          ),
        ),
        home: const ChronosHome(),
      ),
    );
  }
}
