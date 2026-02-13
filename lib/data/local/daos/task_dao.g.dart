// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_dao.dart';

// ignore_for_file: type=lint
mixin _$TaskDaoMixin on DatabaseAccessor<AppDatabase> {
  $DayPlansTable get dayPlans => attachedDatabase.dayPlans;
  $TasksTable get tasks => attachedDatabase.tasks;
  TaskDaoManager get managers => TaskDaoManager(this);
}

class TaskDaoManager {
  final _$TaskDaoMixin _db;
  TaskDaoManager(this._db);
  $$DayPlansTableTableManager get dayPlans =>
      $$DayPlansTableTableManager(_db.attachedDatabase, _db.dayPlans);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
}
