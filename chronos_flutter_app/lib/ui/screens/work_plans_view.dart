import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/plan_template_model.dart';
import '../../providers/schedule_provider.dart';
import '../widgets/glass_container.dart';
import '../widgets/work_plan_detail_dialog.dart';

class WorkPlansView extends StatelessWidget {
  const WorkPlansView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("WorkPlans", style: AppTextStyles.heading1),
              const SizedBox(height: 4),
              Text("Library of your perfect days.",
                  style: AppTextStyles.subtitle),
            ],
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
            childAspectRatio: 1.8,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            children: [
              // Create New Card
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xxl),
                  boxShadow:
                      AppShadows.neonGlow(AppColors.neonBlue, intensity: 0.3),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    onTap: () => _showCreateTemplateDialog(context, provider),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md)),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                          const Spacer(),
                          Text("Create New Plan",
                              style: AppTextStyles.heading3
                                  .copyWith(fontSize: 20)),
                          const SizedBox(height: 4),
                          Text("Build a reusable template",
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Existing Templates
              ...provider.templates.asMap().entries.map((entry) {
                final index = entry.key;
                final tmpl = entry.value;

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + (index * 80)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: GlassContainer(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => WorkPlanDetailDialog(template: tmpl),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(tmpl.name,
                                  style: AppTextStyles.heading3
                                      .copyWith(fontSize: 18),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm)),
                              child: Text(
                                  "${tmpl.tasks.length} task${tmpl.tasks.length == 1 ? '' : 's'}",
                                  style: AppTextStyles.bodySmall
                                      .copyWith(fontWeight: FontWeight.bold)),
                            ),
                            if (tmpl.isRecurring) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                    color: AppColors.neonBlue
                                        .withValues(alpha: 0.2),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.repeat,
                                        size: 10, color: AppColors.neonBlue),
                                    const SizedBox(width: 3),
                                    Text("Recurring",
                                        style: AppTextStyles.bodySmall.copyWith(
                                            fontSize: 10,
                                            color: AppColors.neonBlue,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(tmpl.description,
                            style: AppTextStyles.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) =>
                                        WorkPlanDetailDialog(template: tmpl),
                                  );
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm + 2),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.open_in_new,
                                          size: 14, color: AppColors.neonBlue),
                                      const SizedBox(width: 4),
                                      Text("Open",
                                          style: AppTextStyles.chip.copyWith(
                                              color: AppColors.neonBlue)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  final today = DateTime.now().weekday - 1;
                                  provider.applyTemplateToDays(tmpl, [today]);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Plan applied to today"),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.neonBlue
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm + 2),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_circle_outline,
                                          size: 14, color: AppColors.neonBlue),
                                      const SizedBox(width: 4),
                                      Text("Apply",
                                          style: AppTextStyles.chip.copyWith(
                                              color: AppColors.neonBlue)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _showCreateTemplateDialog(
      BuildContext context, ScheduleProvider provider) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl)),
        title: Text("Create New Plan", style: AppTextStyles.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Plan Name",
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: "e.g., Deep Work Wednesday",
                hintStyle: const TextStyle(color: Colors.white12),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Description",
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                final newTemplate = PlanTemplate(
                  id: const Uuid().v4(),
                  name: nameCtrl.text,
                  description: descCtrl.text,
                  tasks: [],
                );
                provider.addTemplate(newTemplate);
                Navigator.pop(ctx);
                // Immediately open the detail dialog so user can add tasks
                showDialog(
                  context: context,
                  builder: (_) => WorkPlanDetailDialog(template: newTemplate),
                );
              }
            },
            child: const Text("Create", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
