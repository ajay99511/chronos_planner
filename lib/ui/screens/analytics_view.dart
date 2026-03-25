import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/task_model.dart';
import '../../providers/schedule_provider.dart';
import '../widgets/glass_container.dart';
import '../../core/services/intelligence_service.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final _intelService = IntelligenceService();

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: AppAnimDurations.slow);
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _getPeakHourStr(Map<int, double> peaks) {
    if (peaks.isEmpty) return "N/A";
    var bestHour = -1;
    var maxScore = -1.0;
    peaks.forEach((hour, score) {
      if (score > maxScore) {
        maxScore = score;
        bestHour = hour;
      }
    });
    if (bestHour == -1 || maxScore == 0) return "N/A";
    final suffix = bestHour >= 12 ? "PM" : "AM";
    final displayHour = bestHour == 0 ? 12 : (bestHour > 12 ? bestHour - 12 : bestHour);
    return "$displayHour $suffix";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScheduleProvider>(context);
    final allHistory = provider.weekPlan.expand((d) => d.tasks).toList();
    final energyPeaks = _intelService.getEnergyPeaks(allHistory);
    
    // Calculate financial totals
    double totalEstimated = 0;
    for (var task in allHistory) {
      totalEstimated += task.estimatedCost;
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text("Weekly Insights", style: AppTextStyles.heading1),
          const SizedBox(height: 4),
          Text("Analytics based on your local schedule data.",
              style: AppTextStyles.subtitle),
          const SizedBox(height: AppSpacing.xl),

          // Key Metrics Row 1
          Row(
            children: [
              Expanded(child: _EfficiencyCard(efficiency: provider.efficiency)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.attach_money,
                            color: AppColors.health, size: 16),
                        const SizedBox(width: 8),
                        Text("EST. SPENDING", style: AppTextStyles.label),
                      ]),
                      const SizedBox(height: AppSpacing.sm),
                      Text("\$${totalEstimated.toInt()}",
                          style: AppTextStyles.heading2.copyWith(fontSize: 28)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Key Metrics Row 2
          Row(
            children: [
              Expanded(
                child: GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.bolt,
                            color: AppColors.leisure, size: 16),
                        const SizedBox(width: 8),
                        Text("FOCUS TIME", style: AppTextStyles.label),
                      ]),
                      const SizedBox(height: AppSpacing.sm),
                      Text("${provider.totalFocusHours.toStringAsFixed(1)}h",
                          style: AppTextStyles.heading2.copyWith(fontSize: 28)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.show_chart,
                            color: AppColors.neonCyan, size: 16),
                        const SizedBox(width: 8),
                        Text("PEAK HOUR", style: AppTextStyles.label),
                      ]),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _getPeakHourStr(energyPeaks),
                        style: AppTextStyles.heading2.copyWith(fontSize: 28),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Energy Peaks Chart
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.bolt, color: AppColors.neonPurple, size: 18),
                  const SizedBox(width: 8),
                  Text("ENERGY PEAKS (SUCCESS RATE)",
                      style: AppTextStyles.label.copyWith(color: Colors.white)),
                ]),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(24, (index) {
                      final score = energyPeaks[index] ?? 0.0;
                      final isPeak = score > 0 && score == (energyPeaks.values.isEmpty ? 0.0 : energyPeaks.values.reduce(max));
                      
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: score),
                              duration: const Duration(milliseconds: 1000),
                              builder: (context, value, _) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                height: (value * 80) + 2, // min height 2
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: isPeak 
                                      ? [AppColors.neonCyan, AppColors.neonBlue]
                                      : [AppColors.neonPurple.withValues(alpha: 0.8), AppColors.neonPurple.withValues(alpha: 0.2)],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: isPeak ? [BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.4), blurRadius: 4)] : [],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (index % 4 == 0)
                              Text("${index}h", style: const TextStyle(fontSize: 8, color: Colors.grey))
                            else
                              const SizedBox(height: 10),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Donut Chart + Distribution
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.pie_chart_outline,
                      color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Text("TIME DISTRIBUTION",
                      style: AppTextStyles.label.copyWith(color: Colors.white)),
                ]),
                const SizedBox(height: AppSpacing.lg),

                // Donut Chart
                Center(
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: CustomPaint(
                      painter: _DonutChartPainter(
                        distribution: provider.categoryDistribution,
                        total: provider.totalFocusHours,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${provider.totalFocusHours.toStringAsFixed(1)}h",
                              style: AppTextStyles.heading3,
                            ),
                            Text("Total", style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Bar breakdowns
                ...TaskType.values.map((type) {
                  final total = provider.totalFocusHours;
                  final hours = provider.categoryDistribution[type] ?? 0;
                  final percentage = total > 0 ? hours / total : 0.0;

                  Color color;
                  switch (type) {
                    case TaskType.work:
                      color = AppColors.work;
                      break;
                    case TaskType.personal:
                      color = AppColors.personal;
                      break;
                    case TaskType.health:
                      color = AppColors.health;
                      break;
                    case TaskType.leisure:
                      color = AppColors.leisure;
                      break;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  type.toString().split('.').last.toUpperCase(),
                                  style: AppTextStyles.label
                                      .copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                            Text(
                              "${hours.toStringAsFixed(1)}h (${(percentage * 100).toInt()}%)",
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: percentage),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: value,
                              backgroundColor: Colors.white10,
                              color: color,
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Daily Summary Cards
          const SizedBox(height: AppSpacing.xl),
          Text("DAILY BREAKDOWN",
              style: AppTextStyles.label.copyWith(color: Colors.white)),
          const SizedBox(height: AppSpacing.md),
          ...provider.weekPlan.map((day) {
            final completedCount = day.tasks.where((t) => t.completed).length;
            final totalCount = day.tasks.length;
            final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassContainer(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(day.dayOfWeek,
                          style: AppTextStyles.chip
                              .copyWith(color: Colors.white70)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.white10,
                            color: AppColors.neonBlue,
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text("$completedCount/$totalCount",
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Efficiency Card with animated progress ─────
class _EfficiencyCard extends StatelessWidget {
  final double efficiency;
  const _EfficiencyCard({required this.efficiency});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.analytics_outlined,
                color: AppColors.neonBlue, size: 16),
            const SizedBox(width: 8),
            Text("EFFICIENCY", style: AppTextStyles.label),
          ]),
          const SizedBox(height: AppSpacing.md),
          Text("${efficiency.toInt()}%",
              style: AppTextStyles.heading2.copyWith(fontSize: 32)),
          const SizedBox(height: AppSpacing.sm),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: efficiency / 100),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white10,
                color: AppColors.neonBlue,
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tasks Done Card ─────────────────────────────
class _TasksDoneCard extends StatelessWidget {
  final int completed;
  final int total;
  const _TasksDoneCard({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.health, size: 16),
            const SizedBox(width: 8),
            Text("TASKS DONE", style: AppTextStyles.label),
          ]),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text("$completed",
                  style: AppTextStyles.heading2.copyWith(fontSize: 32)),
              Text(" / $total",
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ─── Donut Chart Painter ────────────────────────
class _DonutChartPainter extends CustomPainter {
  final Map<TaskType, double> distribution;
  final double total;

  _DonutChartPainter({required this.distribution, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 16.0;
    final rect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    if (total <= 0) {
      // Draw empty ring
      final emptyPaint = Paint()
        ..color = Colors.white10
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius - strokeWidth / 2, emptyPaint);
      return;
    }

    double startAngle = -pi / 2;
    final typeColors = {
      TaskType.work: AppColors.work,
      TaskType.personal: AppColors.personal,
      TaskType.health: AppColors.health,
      TaskType.leisure: AppColors.leisure,
    };

    for (final type in TaskType.values) {
      final hours = distribution[type] ?? 0;
      if (hours <= 0) continue;

      final sweepAngle = (hours / total) * 2 * pi;
      final paint = Paint()
        ..color = typeColors[type]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle - 0.04, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return distribution != oldDelegate.distribution ||
        total != oldDelegate.total;
  }
}
