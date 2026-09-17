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

/// Wired object graph, so the composition can be built and inspected without
/// mounting the app.
@immutable
class AppDependencies {
  const AppDependencies({
    required this.db,
    required this.logger,
    required this.scheduleRepo,
    required this.todoRepo,
    required this.prefRepo,
    required this.scheduleStateProvider,
  });

  final AppDatabase db;
  final Logger logger;
  final LocalScheduleRepository scheduleRepo;
  final TodoRepository todoRepo;
  final PreferenceRepository prefRepo;
  final ScheduleStateProvider scheduleStateProvider;
}

/// Opens the database, runs the one-time SharedPreferences migration and
/// wires the repositories and providers.
///
/// Separated from [main] so a test can build the same graph over an in-memory
/// database: previously main() reached for the AppDatabase singleton directly,
/// leaving startup and migration -- the riskiest path in the app -- with no
/// way to be exercised together.
@visibleForTesting
Future<AppDependencies> composeDependencies({
  AppDatabase? database,
  Logger? logger,
}) async {
  final resolvedLogger = logger ?? createLogger(debugMode: kDebugMode);
  final db = database ?? AppDatabase.instance;

  await MigrationHelper.migrateIfNeeded(db, resolvedLogger);

  final scheduleRepo = LocalScheduleRepository(db.dayPlanDao, db.taskDao);
  final templateRepo = LocalTemplateRepository(db.templateDao);
  final prefRepo = LocalPreferenceRepository(db.preferenceDao);
  final todoRepo = LocalTodoRepository(db.todoItemDao);

  return AppDependencies(
    db: db,
    logger: resolvedLogger,
    scheduleRepo: scheduleRepo,
    todoRepo: todoRepo,
    prefRepo: prefRepo,
    scheduleStateProvider: ScheduleStateProvider(
      scheduleRepo: scheduleRepo,
      templateRepo: templateRepo,
      prefRepo: prefRepo,
      logger: resolvedLogger,
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Logger
  final logger = createLogger(debugMode: kDebugMode);

  // Nothing may fail silently. Several write paths are fired from UI callbacks
  // without awaiting, so a throw that escapes a repository surfaces here and
  // nowhere else — previously it was discarded and the user was left looking
  // at an optimistic update that never persisted.
  FlutterError.onError = (details) {
    logger.error(
      'Uncaught framework error',
      details.exception,
      details.stack,
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error('Uncaught async error', error, stack);
    return true; // handled: reporting it is the recovery
  };

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
    // Intercept the close so pending state (recurring dismissals) is flushed
    // to disk before the process exits; the handler destroys the window once
    // the flush completes.
    await windowManager.setPreventClose(true);
  }

  final deps = await composeDependencies(logger: logger);

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    windowManager.addListener(
      _WindowHandler(deps.scheduleStateProvider, deps.db, logger),
    );
  }

  runApp(MyApp(
    scheduleStateProvider: deps.scheduleStateProvider,
    scheduleRepo: deps.scheduleRepo,
    todoRepo: deps.todoRepo,
    prefRepo: deps.prefRepo,
    logger: logger,
  ),);
}

class _WindowHandler extends WindowListener {
  final ScheduleStateProvider stateProvider;
  final AppDatabase db;
  final Logger logger;
  _WindowHandler(this.stateProvider, this.db, this.logger);

  @override
  void onWindowClose() async {
    // preventClose is enabled, so the window stays open until we explicitly
    // destroy it — giving the async flush time to finish.
    if (await windowManager.isPreventClose()) {
      try {
        await stateProvider.flushState();
        // Closing checkpoints the WAL. Without it even a clean exit left one
        // behind, to be recovered on the next launch.
        await db.close();
      } catch (e, stackTrace) {
        // Never block the close on a failed flush: the window must still go
        // away, and the error is worth a record rather than a hang.
        logger.error('Failed to flush state on window close', e, stackTrace);
      } finally {
        await windowManager.setPreventClose(false);
        await windowManager.destroy();
      }
    }
  }

  // Re-focusing the window is the desktop equivalent of an app "resume": if the
  // app was left open past midnight, advance the rolling week so recurring
  // templates repopulate the new day. No-ops when the date is unchanged.
  @override
  void onWindowFocus() {
    stateProvider.refreshIfDateChanged();
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
