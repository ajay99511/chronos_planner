import 'package:drift/drift.dart';

import 'package:chronosky/data/local/app_database.dart';
import 'package:chronosky/data/local/tables.dart';

part 'day_plan_dao.g.dart';

@DriftAccessor(tables: [DayPlans])
class DayPlanDao extends DatabaseAccessor<AppDatabase> with _$DayPlanDaoMixin {
  DayPlanDao(super.db);

  /// Get day plans starting from a specific date with a limit.
  Future<List<DayPlan>> getDayPlansFrom(DateTime date, int limit) {
    return (select(dayPlans)
          ..where((d) => d.date.isBiggerOrEqualValue(date))
          ..orderBy([(d) => OrderingTerm.asc(d.date)])
          ..limit(limit))
        .get();
  }

  /// Get the ID of a day plan for a specific date (if exists).
  Future<String?> getDayPlanId(DateTime date) async {
    final result = await (select(dayPlans)
          ..where((d) => d.date.equals(date))
          ..limit(1))
        .getSingleOrNull();
    return result?.id;
  }

  /// Insert a single day plan.
  ///
  /// Uses `INSERT OR IGNORE` so a concurrent insert for the same date never
  /// creates a duplicate (dates are unique as of schema v8); callers must
  /// re-resolve the id by date afterwards.
  Future<void> insertDayPlan(DayPlansCompanion plan) {
    return into(dayPlans).insert(plan, mode: InsertMode.insertOrIgnore);
  }

  /// Insert all 7 day plans for a week, skipping dates that already exist.
  Future<void> insertDayPlans(List<DayPlansCompanion> plans) {
    return batch(
      (b) => b.insertAll(dayPlans, plans, mode: InsertMode.insertOrIgnore),
    );
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
