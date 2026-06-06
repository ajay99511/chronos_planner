import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:chronosky/core/theme/app_theme.dart';
import 'package:chronosky/data/models/plan_template_model.dart';
import 'package:chronosky/providers/schedule_state_provider.dart';
import 'package:chronosky/ui/widgets/glass_container.dart';
import 'package:chronosky/ui/widgets/work_plan_detail_dialog.dart';
import 'package:chronosky/ui/widgets/neo_button.dart';

class WorkPlansView extends StatelessWidget {
  const WorkPlansView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleStateProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppResponsive.screenPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WorkPlans',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: AppResponsive.heading1Size(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Library of your perfect days.',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.fromLTRB(
              AppResponsive.pagePadding(context),
              0,
              AppResponsive.pagePadding(context),
              AppSpacing.xl,
            ),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: AppResponsive.isCompact(context) ? 480 : 360,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: AppResponsive.isCompact(context) ? 1.45 : 1.6,
            ),
            itemCount: provider.templates.length + 1,
            itemBuilder: (context, gridIndex) {
              if (gridIndex == 0) {
                return _buildCreateCard(context, provider);
              }

              final index = gridIndex - 1;
              final tmpl = provider.templates[index];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + (index * 50)),
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
                            child: Text(
                              tmpl.name,
                              style:
                                  AppTextStyles.heading3.copyWith(fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (tmpl.isRecurring)
                            const Icon(
                              Icons.repeat_rounded,
                              size: 14,
                              color: AppColors.neonBlue,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tmpl.tasks.length} tasks',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          tmpl.description,
                          style: AppTextStyles.bodySmall
                              .copyWith(fontSize: 12, height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: NeoButton(
                              height: 36,
                              isSecondary: true,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) =>
                                      WorkPlanDetailDialog(template: tmpl),
                                );
                              },
                              child: const Text(
                                'OPEN',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: NeoButton(
                              height: 36,
                              onPressed: () {
                                provider.applyTemplate(tmpl);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Plan applied to today'),
                                  ),
                                );
                              },
                              child: const Text(
                                'APPLY',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreateCard(
    BuildContext context,
    ScheduleStateProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.neonBlue, AppColors.neonPurple],
        ),
        borderRadius: BorderRadius.circular(AppResponsive.cardRadius(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(AppResponsive.cardRadius(context)),
          onTap: () => _showCreateTemplateDialog(context, provider),
          child: Padding(
            padding: EdgeInsets.all(
              AppResponsive.isCompact(context) ? AppSpacing.md : AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                Text(
                  'Create New Plan',
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: AppResponsive.isCompact(context) ? 18 : 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Build a reusable template',
                  style:
                      AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateTemplateDialog(
    BuildContext context,
    ScheduleStateProvider provider,
  ) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Create New WorkPlan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Plan Name'),
              autofocus: true,
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              final template = PlanTemplate(
                id: const Uuid().v4(),
                name: name,
                description: descCtrl.text.trim(),
                tasks: [],
              );

              provider.addTemplate(template);
              Navigator.pop(ctx);
              showDialog(
                context: context,
                builder: (_) => WorkPlanDetailDialog(template: template),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
