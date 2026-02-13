import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/task_model.dart';
import '../../providers/schedule_provider.dart';
import '../widgets/glass_container.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text("Weekly Insights", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        const Text("Analytics based on your local schedule data.", style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 32),

        // Key Metrics
        Row(
          children: [
            Expanded(
              child: GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.analytics_outlined, color: AppColors.neonBlue, size: 16),
                      SizedBox(width: 8),
                      Text("EFFICIENCY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ]),
                    SizedBox(height: 12),
                    Text("${provider.efficiency.toInt()}%", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: provider.efficiency / 100,
                      backgroundColor: Colors.white10,
                      color: AppColors.neonBlue,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.check_circle_outline, color: AppColors.health, size: 16),
                      SizedBox(width: 8),
                      Text("TASKS DONE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ]),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text("${provider.completedTasks}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(" / ${provider.totalTasks}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 14), // Alignment spacer
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.bolt, color: AppColors.leisure, size: 16),
                      SizedBox(width: 8),
                      Text("FOCUS TIME", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ]),
                    const SizedBox(height: 8),
                    Text("${provider.totalFocusHours.toStringAsFixed(1)}h", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.layers_outlined, color: AppColors.personal, size: 16),
                      SizedBox(width: 8),
                      Text("PLANS SAVED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ]),
                    const SizedBox(height: 8),
                    Text("${provider.templates.length}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Distribution Chart
        GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.pie_chart_outline, color: Colors.grey, size: 18),
                SizedBox(width: 8),
                Text("TIME DISTRIBUTION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ]),
              const SizedBox(height: 24),
              ...TaskType.values.map((type) {
                final total = provider.totalFocusHours;
                final hours = provider.categoryDistribution[type] ?? 0;
                final percentage = total > 0 ? hours / total : 0.0;

                Color color;
                switch(type) {
                  case TaskType.work: color = AppColors.work; break;
                  case TaskType.personal: color = AppColors.personal; break;
                  case TaskType.health: color = AppColors.health; break;
                  case TaskType.leisure: color = AppColors.leisure; break;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(type.toString().split('.').last.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text("${hours.toStringAsFixed(1)}h (${(percentage * 100).toInt()}%)", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.white10,
                          color: color,
                          minHeight: 8,
                        ),
                      )
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
