import 'package:drift/drift.dart';

import '../../models/plan_template_model.dart' as model;
import '../../models/task_model.dart' as model;
import '../../local/app_database.dart';
import '../../local/daos/template_dao.dart';
import '../template_repository.dart';

/// Drift-backed implementation of [TemplateRepository].
class LocalTemplateRepository implements TemplateRepository {
  final TemplateDao _templateDao;

  LocalTemplateRepository(this._templateDao);

  @override
  Future<List<model.PlanTemplate>> getAllTemplates() async {
    final dbTemplates = await _templateDao.getAllTemplates();
    final result = <model.PlanTemplate>[];

    for (final t in dbTemplates) {
      final dbTasks = await _templateDao.getTasksForTemplate(t.id);
      result.add(model.PlanTemplate(
        id: t.id,
        name: t.name,
        description: t.description,
        tasks: dbTasks.map(_dbTemplateTaskToModel).toList(),
      ));
    }

    return result;
  }

  @override
  Future<void> addTemplate(model.PlanTemplate template) async {
    await _templateDao.insertTemplate(PlanTemplatesCompanion(
      id: Value(template.id),
      name: Value(template.name),
      description: Value(template.description),
    ));

    if (template.tasks.isNotEmpty) {
      await _templateDao.insertTemplateTasks(
        template.tasks
            .map((t) => _modelTaskToCompanion(t, template.id))
            .toList(),
      );
    }
  }

  @override
  Future<void> updateTemplate(String templateId,
      {String? name, String? description}) {
    final updates = PlanTemplatesCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      description:
          description != null ? Value(description) : const Value.absent(),
    );
    return _templateDao.updateTemplate(templateId, updates);
  }

  @override
  Future<void> deleteTemplate(String templateId) {
    return _templateDao.deleteTemplate(templateId);
  }

  @override
  Future<void> addTaskToTemplate(String templateId, model.Task task) {
    return _templateDao
        .insertTemplateTask(_modelTaskToCompanion(task, templateId));
  }

  @override
  Future<void> updateTaskInTemplate(
      String templateId, String taskId, model.Task updatedTask) {
    return _templateDao.updateTemplateTask(
      taskId,
      TemplateTasksCompanion(
        title: Value(updatedTask.title),
        description: Value(updatedTask.description),
        startTime: Value(updatedTask.startTime),
        endTime: Value(updatedTask.endTime),
        type: Value(updatedTask.type.name),
        priority: Value(updatedTask.priority.name),
      ),
    );
  }

  @override
  Future<void> removeTaskFromTemplate(String templateId, String taskId) {
    return _templateDao.deleteTemplateTask(taskId);
  }

  // ── Mappers ───────────────────────────────────

  model.Task _dbTemplateTaskToModel(TemplateTask dbTask) {
    return model.Task(
      id: dbTask.id,
      title: dbTask.title,
      description: dbTask.description,
      startTime: dbTask.startTime,
      endTime: dbTask.endTime,
      type: model.TaskType.values.firstWhere(
        (e) => e.name == dbTask.type,
        orElse: () => model.TaskType.work,
      ),
      priority: model.TaskPriority.values.firstWhere(
        (e) => e.name == dbTask.priority,
        orElse: () => model.TaskPriority.medium,
      ),
    );
  }

  TemplateTasksCompanion _modelTaskToCompanion(
      model.Task task, String templateId) {
    return TemplateTasksCompanion(
      id: Value(task.id),
      templateId: Value(templateId),
      title: Value(task.title),
      description: Value(task.description),
      startTime: Value(task.startTime),
      endTime: Value(task.endTime),
      type: Value(task.type.name),
      priority: Value(task.priority.name),
    );
  }
}
