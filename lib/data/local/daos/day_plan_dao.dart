import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'day_plan_dao.g.dart';

@DriftAccessor(tables: [DayPlans])
class DayPlanDao extends DatabaseAccessor<AppDatabase> with _$DayPlanDaoMixin {
  DayPlanDao(super.db);

  /// Get all day plans for a given week key (e.g. "2026-W07").
  Future<List<DayPlan>> getDayPlansForWeek(String weekKey) {
    return (select(dayPlans)
          ..where((d) => d.weekKey.equals(weekKey))
          ..orderBy([(d) => OrderingTerm.asc(d.date)]))
        .get();
  }

  /// Insert a single day plan.
  Future<void> insertDayPlan(DayPlansCompanion plan) {
    return into(dayPlans).insert(plan);
  }

  /// Insert all 7 day plans for a week.
  Future<void> insertDayPlans(List<DayPlansCompanion> plans) {
    return batch((b) => b.insertAll(dayPlans, plans));
  }

  /// Update a day plan.
  Future<void> updateDayPlan(String planId, DayPlansCompanion updates) {
    return (update(dayPlans)..where((d) => d.id.equals(planId))).write(updates);
  }

  /// Delete all day plans for a week.
  Future<int> deleteDayPlansForWeek(String weekKey) {
    return (delete(dayPlans)..where((d) => d.weekKey.equals(weekKey))).go();
  }

  /// Check if a week already exists.
  Future<bool> weekExists(String weekKey) async {
    final result = await (select(dayPlans)
          ..where((d) => d.weekKey.equals(weekKey))
          ..limit(1))
        .get();
    return result.isNotEmpty;
  }
}
