import 'package:chronosky/core/services/intelligence_service.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = IntelligenceService();

  group('IntelligenceService', () {
    test('calculateEfficiency handles empty list', () {
      expect(service.calculateEfficiency([]), 0.0);
    });

    test('calculateEfficiency returns correct percentage', () {
      final tasks = [
        Task(id: '1', title: 'T1', startTime: '09:00', endTime: '10:00', type: TaskType.work, completed: true),
        Task(id: '2', title: 'T2', startTime: '10:00', endTime: '11:00', type: TaskType.work, completed: false),
      ];
      expect(service.calculateEfficiency(tasks), 50.0);
    });

    test('getEnergyPeaks calculates intensity correctly', () async {
      final history = [
        // 1 hour task, priority high, energy high -> weight 2.0
        Task(
          id: '1',
          title: 'H1',
          startTime: '08:00',
          endTime: '09:00',
          type: TaskType.work,
          priority: TaskPriority.high,
          energyLevel: TaskEnergyLevel.high,
          completed: true,
        ),
        // 30 min task, normal weight 1.0
        Task(
          id: '2',
          title: 'H2',
          startTime: '09:00',
          endTime: '09:30',
          type: TaskType.work,
          priority: TaskPriority.medium,
          energyLevel: TaskEnergyLevel.medium,
          completed: true,
        ),
      ];

      final peaks = await service.getEnergyPeaks(history);

      expect(peaks[8], 2.0); // 1.0 * 2.0 weight
      expect(peaks[9], 0.5); // 0.5 * 1.0 weight
      expect(peaks[10], 0.0);
    });

    test('getEnergyPeaks handles overnight tasks', () async {
      final history = [
        Task(
          id: '1',
          title: 'Night',
          startTime: '23:00',
          endTime: '01:00',
          type: TaskType.work,
          completed: true,
        ),
      ];

      final peaks = await service.getEnergyPeaks(history);

      expect(peaks[23], 1.0);
      expect(peaks[0], 1.0);
      expect(peaks[1], 0.0);
    });

    test('getEnergyPeaks ignores uncompleted tasks', () async {
      final history = [
        Task(
          id: '1',
          title: 'Skip',
          startTime: '09:00',
          endTime: '10:00',
          type: TaskType.work,
          completed: false,
        ),
      ];

      final peaks = await service.getEnergyPeaks(history);
      expect(peaks[9], 0.0);
    });
  });
}
