import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/plan_template_model.dart';
import '../../providers/schedule_provider.dart';
import '../widgets/glass_container.dart';

class WorkPlansView extends StatelessWidget {
  const WorkPlansView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("WorkPlans", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("Library of your perfect days.", style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),

        Expanded(
          child: GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1, // Responsive Grid
            childAspectRatio: 1.8,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              // Create New Card
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppColors.neonBlue.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _showCreateTemplateDialog(context, provider),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                          const Spacer(),
                          const Text("Create New Plan", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text("Build a reusable template", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Existing Templates
              ...provider.templates.map((tmpl) => GlassContainer(
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: Text(tmpl.name, style: const TextStyle(color: Colors.white)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Apply this template to ${provider.selectedDay.dayOfWeek}?", style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text("${tmpl.tasks.length} tasks will be added.", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                        actions: [
                          TextButton(
                              onPressed: () {
                                // Delete confirmation could be here, but using icon for now
                                Navigator.pop(ctx);
                              },
                              child: const Text("Cancel")
                          ),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonBlue),
                              onPressed: () {
                                provider.applyTemplate(tmpl);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Template applied successfully")));
                              },
                              child: const Text("Apply")
                          ),
                        ],
                      )
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(tmpl.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                        Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                              child: Text("${tmpl.tasks.length}", style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            InkWell(
                              onTap: () => provider.removeTemplate(tmpl.id),
                              child: const Icon(Icons.delete_outline, size: 18, color: Colors.white30),
                            )
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(tmpl.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 14, color: AppColors.neonBlue),
                          SizedBox(width: 4),
                          Text("Use Plan", style: TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    )
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  void _showCreateTemplateDialog(BuildContext context, ScheduleProvider provider) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text("Create New Plan", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Plan Name",
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: "e.g., Deep Work Wednesday",
                  hintStyle: TextStyle(color: Colors.white12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Description",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonBlue),
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty) {
                    provider.addTemplate(PlanTemplate(
                        id: const Uuid().v4(),
                        name: nameCtrl.text,
                        description: descCtrl.text,
                        tasks: [] // Starts empty
                    ));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plan created! Add tasks to it from your schedule.")));
                  }
                },
                child: const Text("Create")
            ),
          ],
        )
    );
  }
}
