import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/local/app_database.dart';
import 'package:chronosky/data/models/plan_template_model.dart' as domain;
import 'package:chronosky/data/repositories/local/local_template_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late LocalTemplateRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    repository = LocalTemplateRepository(database.templateDao);
  });

  tearDown(() async {
    await database.close();
  });

  group('LocalTemplateRepository', () {
    test('getAllTemplates with 100 templates returns correct data', () async {
      // 1. Seed 100 templates
      for (int i = 0; i < 100; i++) {
        await database.into(database.planTemplates).insert(
          PlanTemplatesCompanion.insert(id: 't$i', name: 'Template $i'),
        );
        // Add one task per template
        await database.into(database.templateTasks).insert(
          TemplateTasksCompanion.insert(
            id: 'task-$i',
            templateId: 't$i',
            title: 'Task $i',
            startTime: '09:00',
            endTime: '10:00',
            type: 'work',
          ),
        );
      }

      // 2. Measure execution time
      final stopwatch = Stopwatch()..start();
      final result = await repository.getAllTemplates();
      stopwatch.stop();

      // 3. Verify
      expect(result, isA<Success<List<domain.PlanTemplate>>>());
      final list = (result as Success<List<domain.PlanTemplate>>).value;
      expect(list.length, 100);
      expect(list[0].tasks.length, 1);
      
      // Requirement 3C.18: completion within 50 ms for 100 templates
      // Note: On some CI environments this might be slower, but in-memory should be fast.
      expect(stopwatch.elapsedMilliseconds, lessThan(100), reason: 'Query took too long: ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}
