import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:chronosky/core/services/alarm_scheduler_service.dart';
import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/core/theme/app_theme.dart';
import 'package:chronosky/data/local/app_database.dart';
import 'package:chronosky/data/local/migration_helper.dart';
import 'package:chronosky/data/repositories/local/local_preference_repository.dart';
import 'package:chronosky/data/repositories/local/local_schedule_repository.dart';
import 'package:chronosky/data/repositories/local/local_template_repository.dart';
import 'package:chronosky/data/repositories/local/local_todo_repository.dart';
import 'package:chronosky/data/repositories/preference_repository.dart';
import 'package:chronosky/data/repositories/todo_repository.dart';
import 'package:chronosky/providers/schedule_state_provider.dart';
import 'package:chronosky/providers/analytics_provider.dart';
import 'package:chronosky/providers/todo_provider.dart';
import 'package:chronosky/ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Logger
  final logger = kDebugMode ? const ConsoleLogger() : const NoOpLogger();
  logger.info('App starting...');

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
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

  final scheduleStateProvider = ScheduleStateProvider(
    scheduleRepo: scheduleRepo,
    templateRepo: templateRepo,
    prefRepo: prefRepo,
    logger: logger,
  );

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    windowManager.addListener(_WindowHandler(scheduleStateProvider));
  }

  runApp(MyApp(
    scheduleStateProvider: scheduleStateProvider,
    scheduleRepo: scheduleRepo,
    todoRepo: todoRepo,
    prefRepo: prefRepo,
    logger: logger,
  ),);
}

class _WindowHandler extends WindowListener {
  final ScheduleStateProvider stateProvider;
  _WindowHandler(this.stateProvider);

  @override
  void onWindowClose() async {
    await stateProvider.flushState();
  }
}

class MyApp extends StatelessWidget {
  final ScheduleStateProvider scheduleStateProvider;
  final LocalScheduleRepository scheduleRepo;
  final TodoRepository todoRepo;
  final PreferenceRepository prefRepo;
  final Logger logger;

  const MyApp({
    super.key,
    required this.scheduleStateProvider,
    required this.scheduleRepo,
    required this.todoRepo,
    required this.prefRepo,
    required this.logger,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: scheduleStateProvider),
        ChangeNotifierProvider(
          create: (_) => AnalyticsProvider(scheduleStateProvider, scheduleRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => TodoProvider(todoRepo, prefRepo: prefRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => AlarmSchedulerService(todoRepo, logger),
          lazy: false, // Alarms must arm at startup, not on first UI access.
        ),
      ],
      child: MaterialApp(
        title: 'Chronos',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
        ],
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
