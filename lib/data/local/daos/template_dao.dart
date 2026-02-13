import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'template_dao.g.dart';

@DriftAccessor(tables: [PlanTemplates, TemplateTasks])
class TemplateDao extends DatabaseAccessor<AppDatabase>
    with _$TemplateDaoMixin {
  TemplateDao(super.db);

  // ── Templates ──

  /// Get all templates.
  Future<List<PlanTemplate>> getAllTemplates() {
    return select(planTemplates).get();
  }

  /// Watch all templates (reactive).
  Stream<List<PlanTemplate>> watchAllTemplates() {
    return select(planTemplates).watch();
  }

  /// Insert a template.
  Future<void> insertTemplate(PlanTemplatesCompanion tmpl) {
    return into(planTemplates).insert(tmpl);
  }

  /// Update a template's metadata.
  Future<void> updateTemplate(
      String templateId, PlanTemplatesCompanion updates) {
    return (update(planTemplates)..where((t) => t.id.equals(templateId)))
        .write(updates);
  }

  /// Delete a template and its tasks.
  Future<void> deleteTemplate(String templateId) async {
    await (delete(templateTasks)..where((t) => t.templateId.equals(templateId)))
        .go();
    await (delete(planTemplates)..where((t) => t.id.equals(templateId))).go();
  }

  // ── Template Tasks ──

  /// Get all tasks for a template.
  Future<List<TemplateTask>> getTasksForTemplate(String templateId) {
    return (select(templateTasks)
          ..where((t) => t.templateId.equals(templateId))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
  }

  /// Insert a task into a template.
  Future<void> insertTemplateTask(TemplateTasksCompanion task) {
    return into(templateTasks).insert(task);
  }

  /// Insert multiple template tasks.
  Future<void> insertTemplateTasks(List<TemplateTasksCompanion> taskList) {
    return batch((b) => b.insertAll(templateTasks, taskList));
  }

  /// Update a template task.
  Future<void> updateTemplateTask(
      String taskId, TemplateTasksCompanion updates) {
    return (update(templateTasks)..where((t) => t.id.equals(taskId)))
        .write(updates);
  }

  /// Delete a template task.
  Future<int> deleteTemplateTask(String taskId) {
    return (delete(templateTasks)..where((t) => t.id.equals(taskId))).go();
  }
}
