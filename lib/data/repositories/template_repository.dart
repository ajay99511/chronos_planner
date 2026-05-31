import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/models/plan_template_model.dart';

/// Abstract interface for work plan template operations.
abstract class TemplateRepository {
  /// Get all saved templates.
  Future<Result<List<PlanTemplate>>> getAllTemplates();

  /// Add a new template.
  Future<Result<void>> addTemplate(PlanTemplate template);

  /// Update template metadata (name, description).
  Future<Result<void>> updateTemplate(String templateId,
      {String? name, String? description,});

  /// Delete a template and all its tasks.
  Future<Result<void>> deleteTemplate(String templateId);

  /// Add a task to a template.
  Future<Result<void>> addTaskToTemplate(String templateId, TemplateTask task);

  /// Update a task inside a template.
  Future<Result<void>> updateTaskInTemplate(
      String templateId, String taskId, TemplateTask updatedTask,);

  /// Remove a task from a template.
  Future<Result<void>> removeTaskFromTemplate(String templateId, String taskId);

  /// Update the active recurring days for a template.
  Future<Result<void>> updateTemplateActiveDays(String templateId, List<int> days);

  /// Get all templates with recurring active days set.
  Future<Result<List<PlanTemplate>>> getRecurringTemplates();
}
