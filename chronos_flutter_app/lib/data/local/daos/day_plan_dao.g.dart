// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_plan_dao.dart';

// ignore_for_file: type=lint
mixin _$DayPlanDaoMixin on DatabaseAccessor<AppDatabase> {
  $DayPlansTable get dayPlans => attachedDatabase.dayPlans;
  DayPlanDaoManager get managers => DayPlanDaoManager(this);
}

class DayPlanDaoManager {
  final _$DayPlanDaoMixin _db;
  DayPlanDaoManager(this._db);
  $$DayPlansTableTableManager get dayPlans =>
      $$DayPlansTableTableManager(_db.attachedDatabase, _db.dayPlans);
}
