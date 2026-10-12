import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/seeds/default_plan_templates.dart';
import 'package:chronosky/data/models/plan_template_model.dart';
import 'package:chronosky/domain/clock_time.dart';
import 'package:flutter_test/flutter_test.dart';

/// The starter plans are data, and data that violates the invariants is
/// rejected at the point it is written — on a first launch, with nothing in
/// the UI to explain why the library came up empty. Cheaper to assert here.
void main() {
  group('defaultPlanTemplates', () {
    test('ships three plans', () {
      expect(defaultPlanTemplates().length, 3);
    });

    test('every task passes the same validation as user input', () {
      for (final template in defaultPlanTemplates()) {
        for (final task in template.tasks) {
          final result = TemplateTask.create(
            id: task.id,
            templateId: task.templateId,
            title: task.title,
            startTime: task.startTime,
            endTime: task.endTime,
            type: task.type,
            priority: task.priority,
            energyLevel: task.energyLevel,
            estimatedCost: task.estimatedCost,
            description: task.description,
          );
          expect(
            result,
            isA<Success<TemplateTask>>(),
            reason: '"${task.title}" in "${template.name}" is invalid',
          );
        }
      }
    });

    test('every task ends after it starts', () {
      for (final template in defaultPlanTemplates()) {
        for (final task in template.tasks) {
          final start = ClockTime.tryParse(task.startTime);
          final end = ClockTime.tryParse(task.endTime);
          expect(start, isNotNull);
          expect(end, isNotNull);
          expect(
            end!.minutesSinceMidnight,
            greaterThan(start!.minutesSinceMidnight),
            reason: '"${task.title}" in "${template.name}" ends before it '
                'starts',
          );
        }
      }
    });

    test('no task overlaps another in the same plan', () {
      for (final template in defaultPlanTemplates()) {
        final ranges = [
          for (final task in template.tasks)
            (task.title, TimeRange.tryParse(task.startTime, task.endTime)!),
        ];
        for (var i = 0; i < ranges.length; i++) {
          for (var j = i + 1; j < ranges.length; j++) {
            expect(
              ranges[i].$2.overlaps(ranges[j].$2),
              isFalse,
              reason: '"${ranges[i].$1}" overlaps "${ranges[j].$1}" in '
                  '"${template.name}"',
            );
          }
        }
      }
    });

    test('each task carries the id of the template that owns it', () {
      for (final template in defaultPlanTemplates()) {
        for (final task in template.tasks) {
          expect(task.templateId, template.id);
        }
      }
    });

    test('ids are unique across a call', () {
      final templates = defaultPlanTemplates();
      final ids = [
        for (final template in templates) ...[
          template.id,
          ...template.tasks.map((t) => t.id),
        ],
      ];
      expect(ids.toSet().length, ids.length);
    });

    test('no plan is recurring', () {
      // A recurring starter plan would write itself into the user's week on
      // first launch. See the file comment in default_plan_templates.dart.
      expect(
        defaultPlanTemplates().every((t) => t.activeDays.isEmpty),
        isTrue,
      );
    });
  });
}
