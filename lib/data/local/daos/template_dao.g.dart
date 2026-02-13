// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_dao.dart';

// ignore_for_file: type=lint
mixin _$TemplateDaoMixin on DatabaseAccessor<AppDatabase> {
  $PlanTemplatesTable get planTemplates => attachedDatabase.planTemplates;
  $TemplateTasksTable get templateTasks => attachedDatabase.templateTasks;
  TemplateDaoManager get managers => TemplateDaoManager(this);
}

class TemplateDaoManager {
  final _$TemplateDaoMixin _db;
  TemplateDaoManager(this._db);
  $$PlanTemplatesTableTableManager get planTemplates =>
      $$PlanTemplatesTableTableManager(_db.attachedDatabase, _db.planTemplates);
  $$TemplateTasksTableTableManager get templateTasks =>
      $$TemplateTasksTableTableManager(_db.attachedDatabase, _db.templateTasks);
}
