import '../models/plan_template_model.dart';
import '../models/task_model.dart';

/// Abstract interface for work plan template operations.
abstract class TemplateRepository {
  /// Get all saved templates.
  Future<List<PlanTemplate>> getAllTemplates();

  /// Add a new template.
  Future<void> addTemplate(PlanTemplate template);

  /// Update template metadata (name, description).
  Future<void> updateTemplate(String templateId,
      {String? name, String? description});

  /// Delete a template and all its tasks.
  Future<void> deleteTemplate(String templateId);

  /// Add a task to a template.
  Future<void> addTaskToTemplate(String templateId, Task task);

  /// Update a task inside a template.
  Future<void> updateTaskInTemplate(
      String templateId, String taskId, Task updatedTask);

  /// Remove a task from a template.
  Future<void> removeTaskFromTemplate(String templateId, String taskId);
}
