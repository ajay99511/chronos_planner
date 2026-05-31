import 'dart:math';
import 'package:chronosky/data/models/task_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task Model', () {
    test('Task JSON Round-Trip', () {
      // Feature: chronos-planner-tsd, Property 1: Task JSON Round-Trip
      final random = Random();
      final taskTypes = TaskType.values;
      final taskPriorities = TaskPriority.values;
      final taskEnergyLevels = TaskEnergyLevel.values;

      for (int i = 0; i < 100; i++) {
        final id = 'id-$i';
        final title = 'Task Title ${random.nextInt(1000)}' * (random.nextInt(3) + 1);
        final clampedTitle = title.length > 200 ? title.substring(0, 200) : title;
        
        final startHour = random.nextInt(24).toString().padLeft(2, '0');
        final startMin = random.nextInt(60).toString().padLeft(2, '0');
        final endHour = random.nextInt(24).toString().padLeft(2, '0');
        final endMin = random.nextInt(60).toString().padLeft(2, '0');
        
        final task = Task(
          id: id,
          title: clampedTitle,
          startTime: '$startHour:$startMin',
          endTime: '$endHour:$endMin',
          type: taskTypes[random.nextInt(taskTypes.length)],
          priority: taskPriorities[random.nextInt(taskPriorities.length)],
          energyLevel: taskEnergyLevels[random.nextInt(taskEnergyLevels.length)],
          estimatedCost: random.nextDouble() * 9999.0,
          actualCost: random.nextDouble() * 9999.0,
          description: 'Description $i',
          sourceTemplateId: 'template-$i',
          completed: random.nextBool(),
        );

        final json = task.toJson();
        final fromJson = Task.fromJson(json);

        expect(fromJson, equals(task), reason: 'Iteration $i failed');
      }
    });

    test('Task validation asserts', () {
      // Invalid title
      expect(() => Task(
        id: '1',
        title: '',
        startTime: '09:00',
        endTime: '10:00',
        type: TaskType.work,
      ), throwsA(isA<AssertionError>()),);

      // Title too long
      expect(() => Task(
        id: '1',
        title: 'a' * 201,
        startTime: '09:00',
        endTime: '10:00',
        type: TaskType.work,
      ), throwsA(isA<AssertionError>()),);

      // Invalid time format
      expect(() => Task(
        id: '1',
        title: 'Title',
        startTime: '9:00',
        endTime: '10:00',
        type: TaskType.work,
      ), throwsA(isA<AssertionError>()),);

      // Negative cost
      expect(() => Task(
        id: '1',
        title: 'Title',
        startTime: '09:00',
        endTime: '10:00',
        type: TaskType.work,
        estimatedCost: -1.0,
      ), throwsA(isA<AssertionError>()),);
    });
  });
}
