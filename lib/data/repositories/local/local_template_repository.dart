import 'package:drift/drift.dart';

import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/models/plan_template_model.dart' as domain;
import 'package:chronosky/data/models/task_model.dart' as domain;
import 'package:chronosky/data/local/app_database.dart';
import 'package:chronosky/data/local/daos/template_dao.dart';
import 'package:chronosky/data/repositories/template_repository.dart';

/// Drift-backed implementation of [TemplateRepository].
class LocalTemplateRepository implements TemplateRepository {
  final TemplateDao _templateDao;

  LocalTemplateRepository(this._templateDao);

  Future<Result<T>> _wrap<T>(Future<T> Function() action) async {
    try {
      final value = await action();
      return Success(value);
    } on DriftWrappedException catch (e) {
      return Failure(
          DatabaseFailure('Database operation failed', e.toString()),);
    } on Exception catch (e) {
      return Failure(UnknownFailure('Unexpected error', e.toString()));
    }
  }

  @override
  Future<Result<List<domain.PlanTemplate>>> getAllTemplates() async {
    return _wrap(() async {
      // 1. Fetch all templates
      final dbTemplates = await _templateDao.getAllTemplates();
      if (dbTemplates.isEmpty) return [];

      // 2. Fetch all template tasks in one query
      final allTasks =
          await _templateDao.db.select(_templateDao.templateTasks).get();

      // 3. Fetch all active days in one query
      final allActiveDays =
          await _templateDao.db.select(_templateDao.templateActiveDays).get();

      // 4. Group tasks and active days by template ID
      final tasksByTemplate = <String, List<domain.TemplateTask>>{};
      for (final t in allTasks) {
        tasksByTemplate
            .putIfAbsent(t.templateId, () => [])
            .add(_dbTemplateTaskToModel(t));
      }

      final daysByTemplate = <String, List<int>>{};
      for (final d in allActiveDays) {
        daysByTemplate.putIfAbsent(d.templateId, () => []).add(d.dayIndex);
      }

      // 5. Assemble domain models
      return dbTemplates.map((t) {
        return domain.PlanTemplate(
          id: t.id,
          name: t.name,
          description: t.description,
          tasks: tasksByTemplate[t.id] ?? [],
          activeDays: daysByTemplate[t.id] ?? [],
        );
      }).toList();
    });
  }

  @override
  Future<Result<void>> addTemplate(domain.PlanTemplate template) async {
    return _wrap(() async {
      await _templateDao.db.transaction(() async {
        await _templateDao.insertTemplate(
          PlanTemplatesCompanion(
            id: Value(template.id),
            name: Value(template.name),
            description: Value(template.description),
          ),
        );

        if (template.tasks.isNotEmpty) {
          await _templateDao.insertTemplateTasks(
            template.tasks
                .map((t) => _modelTaskToCompanion(t, template.id))
                .toList(),
          );
        }

        if (template.activeDays.isNotEmpty) {
          for (final day in template.activeDays) {
            await _templateDao.db.into(_templateDao.templateActiveDays).insert(
                  TemplateActiveDaysCompanion.insert(
                      templateId: template.id, dayIndex: day,),
                );
          }
        }
      });
    });
  }

  @override
  Future<Result<void>> updateTemplate(
    String templateId, {
    String? name,
    String? description,
  }) {
    return _wrap(() async {
      final updates = PlanTemplatesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        description:
            description != null ? Value(description) : const Value.absent(),
      );
      await _templateDao.updateTemplate(templateId, updates);
    });
  }

  @override
  Future<Result<void>> deleteTemplate(String templateId) {
    return _wrap(() async {
      await _templateDao.deleteTemplate(templateId);
    });
  }

  @override
  Future<Result<void>> addTaskToTemplate(
      String templateId, domain.TemplateTask task,) {
    return _wrap(() async {
      await _templateDao
          .insertTemplateTask(_modelTaskToCompanion(task, templateId));
    });
  }

  @override
  Future<Result<void>> updateTaskInTemplate(
    String templateId,
    String taskId,
    domain.TemplateTask updatedTask,
  ) {
    return _wrap(() async {
      await _templateDao.updateTemplateTask(
        taskId,
        _modelTaskToCompanion(updatedTask, templateId),
      );
    });
  }

  @override
  Future<Result<void>> removeTaskFromTemplate(
      String templateId, String taskId,) {
    return _wrap(() async {
      await _templateDao.deleteTemplateTask(taskId);
    });
  }

  @override
  Future<Result<void>> updateTemplateActiveDays(
      String templateId, List<int> days,) {
    return _wrap(() async {
      await _templateDao.db.transaction(() async {
        // Delete old days
        await (_templateDao.db.delete(_templateDao.templateActiveDays)
              ..where((t) => t.templateId.equals(templateId)))
            .go();

        // Insert new days
        for (final day in days) {
          await _templateDao.db.into(_templateDao.templateActiveDays).insert(
                TemplateActiveDaysCompanion.insert(
                    templateId: templateId, dayIndex: day,),
              );
        }
      });
    });
  }

  @override
  Future<Result<List<domain.PlanTemplate>>> getRecurringTemplates() async {
    return _wrap(() async {
      final dbTemplates = await _templateDao.getRecurringTemplates();
      if (dbTemplates.isEmpty) return [];

      // Same logic as getAllTemplates but filtered by template DAO
      final templateIds = dbTemplates.map((t) => t.id).toList();

      final tasksQuery = _templateDao.db.select(_templateDao.templateTasks)
        ..where((t) => t.templateId.isIn(templateIds));
      final allTasks = await tasksQuery.get();

      final daysQuery = _templateDao.db.select(_templateDao.templateActiveDays)
        ..where((t) => t.templateId.isIn(templateIds));
      final allActiveDays = await daysQuery.get();

      final tasksByTemplate = <String, List<domain.TemplateTask>>{};
      for (final t in allTasks) {
        tasksByTemplate
            .putIfAbsent(t.templateId, () => [])
            .add(_dbTemplateTaskToModel(t));
      }

      final daysByTemplate = <String, List<int>>{};
      for (final d in allActiveDays) {
        daysByTemplate.putIfAbsent(d.templateId, () => []).add(d.dayIndex);
      }

      return dbTemplates.map((t) {
        return domain.PlanTemplate(
          id: t.id,
          name: t.name,
          description: t.description,
          tasks: tasksByTemplate[t.id] ?? [],
          activeDays: daysByTemplate[t.id] ?? [],
        );
      }).toList();
    });
  }

  // ── Mappers ───────────────────────────────────

  domain.TemplateTask _dbTemplateTaskToModel(TemplateTask dbTask) {
    return domain.TemplateTask(
      id: dbTask.id,
      templateId: dbTask.templateId,
      title: dbTask.title,
      description: dbTask.description,
      startTime: dbTask.startTime,
      endTime: dbTask.endTime,
      type: domain.TaskType.values.firstWhere(
        (e) => e.name == dbTask.type,
        orElse: () => domain.TaskType.work,
      ),
      priority: domain.TaskPriority.values.firstWhere(
        (e) => e.name == dbTask.priority,
        orElse: () => domain.TaskPriority.medium,
      ),
      energyLevel: domain.TaskEnergyLevel.values.firstWhere(
        (e) => e.name == dbTask.energyLevel,
        orElse: () => domain.TaskEnergyLevel.medium,
      ),
      estimatedCost: dbTask.estimatedCost,
    );
  }

  TemplateTasksCompanion _modelTaskToCompanion(
    domain.TemplateTask task,
    String templateId,
  ) {
    return TemplateTasksCompanion(
      id: Value(task.id),
      templateId: Value(templateId),
      title: Value(task.title),
      description: Value(task.description),
      startTime: Value(task.startTime),
      endTime: Value(task.endTime),
      type: Value(task.type.name),
      priority: Value(task.priority.name),
      energyLevel: Value(task.energyLevel.name),
      estimatedCost: Value(task.estimatedCost),
    );
  }
}
