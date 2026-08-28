import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/models/plan_template_model.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// The model invariants were previously enforced with `assert`, which the AOT
/// compiler strips from release builds — so a shipped app happily persisted an
/// empty title or a start time of "99:99". These factories use ordinary
/// conditionals, so they behave identically in debug and release. See C-2.
void main() {
  Result<Task> create({
    String title = 'Deep work',
    String startTime = '09:00',
    String endTime = '11:00',
    double estimatedCost = 0,
    double actualCost = 0,
  }) =>
      Task.create(
        id: 'task-1',
        title: title,
        startTime: startTime,
        endTime: endTime,
        type: TaskType.work,
        estimatedCost: estimatedCost,
        actualCost: actualCost,
      );

  String messageOf(Result<Object> result) =>
      (result as Failure).failure.message;

  group('Task.create', () {
    test('accepts a well-formed task', () {
      final result = create();

      expect(result, isA<Success<Task>>());
      expect((result as Success<Task>).value.title, 'Deep work');
    });

    test('rejects an empty title', () {
      final result = create(title: '');

      expect(result, isA<Failure<Task>>());
      expect((result as Failure).failure, isA<ValidationFailure>());
      expect(messageOf(result), contains('Title'));
    });

    test('rejects a title over 200 characters', () {
      expect(create(title: 'x' * 200), isA<Success<Task>>());
      expect(create(title: 'x' * 201), isA<Failure<Task>>());
    });

    test('rejects times outside 24-hour HH:mm', () {
      for (final bad in ['99:99', '9:00', '24:00', '12:60', '', 'noon']) {
        expect(
          create(startTime: bad),
          isA<Failure<Task>>(),
          reason: '"$bad" is not a valid start time',
        );
      }
    });

    test('accepts the boundaries of the clock', () {
      expect(create(startTime: '00:00', endTime: '23:59'), isA<Success<Task>>());
    });

    test('reports which field failed', () {
      expect(messageOf(create(endTime: '25:00')), contains('end time'));
      expect(messageOf(create(startTime: '25:00')), contains('start time'));
    });

    test('rejects negative and non-finite costs', () {
      expect(create(estimatedCost: -0.01), isA<Failure<Task>>());
      expect(create(actualCost: -1), isA<Failure<Task>>());
      expect(create(estimatedCost: double.infinity), isA<Failure<Task>>());
      expect(create(estimatedCost: double.nan), isA<Failure<Task>>());
    });

    test('accepts a zero cost', () {
      expect(create(estimatedCost: 0), isA<Success<Task>>());
    });
  });

  group('TemplateTask.create', () {
    Result<TemplateTask> template({
      String title = 'Stretch',
      String startTime = '07:00',
    }) =>
        TemplateTask.create(
          id: 'ttask-1',
          templateId: 'tmpl-1',
          title: title,
          startTime: startTime,
          endTime: '07:30',
          type: TaskType.health,
        );

    test('accepts a well-formed template task', () {
      expect(template(), isA<Success<TemplateTask>>());
    });

    test('rejects an empty title', () {
      expect(template(title: ''), isA<Failure<TemplateTask>>());
    });

    test('rejects a malformed time', () {
      expect(template(startTime: '7:00'), isA<Failure<TemplateTask>>());
    });
  });
}
