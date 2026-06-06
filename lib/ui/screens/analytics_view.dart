import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chronosky/core/theme/app_theme.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/data/models/day_plan_model.dart';
import 'package:chronosky/providers/analytics_provider.dart';
import 'package:chronosky/providers/schedule_state_provider.dart';
import 'package:chronosky/ui/widgets/glass_container.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

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
    if (peaks.isEmpty) return 'N/A';
    var bestHour = -1;
    var maxScore = -1.0;
    peaks.forEach((hour, score) {
      if (score > maxScore) {
        maxScore = score;
        bestHour = hour;
      }
    });
    if (bestHour == -1 || maxScore <= 0) return 'N/A';
    final suffix = bestHour >= 12 ? 'PM' : 'AM';
    final displayHour =
        bestHour == 0 ? 12 : (bestHour > 12 ? bestHour - 12 : bestHour);
    return '$displayHour $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final analytics = Provider.of<AnalyticsProvider>(context);
    final schedule = Provider.of<ScheduleStateProvider>(context);
    final energyPeaks = analytics.energyPeaks;

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView(
        padding: AppResponsive.screenPadding(context),
        children: [
          Text(
            'Weekly Insights',
            style: AppTextStyles.heading1.copyWith(
              fontSize: AppResponsive.heading1Size(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Analytics based on your local schedule data.',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Key Metrics
          _ResponsiveCardGrid(
            children: [
              _EfficiencyCard(efficiency: analytics.efficiency),
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          color: AppColors.neonPurple,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text('FOCUS HOURS', style: AppTextStyles.label),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${analytics.totalFocusHours.toStringAsFixed(1)}h',
                      style: AppTextStyles.heading2.copyWith(
                        fontSize: AppResponsive.heading2Size(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          _ResponsiveCardGrid(
            children: [
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.show_chart_rounded,
                          color: AppColors.neonCyan,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text('PEAK HOUR', style: AppTextStyles.label),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _getPeakHourStr(energyPeaks),
                      style: AppTextStyles.heading2.copyWith(
                        fontSize: AppResponsive.heading2Size(context),
                      ),
                    ),
                  ],
                ),
              ),
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.assignment_turned_in_rounded,
                          color: AppColors.health,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text('TASKS DONE', style: AppTextStyles.label),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${analytics.completedTasks}/${analytics.totalTasks}',
                      style: AppTextStyles.heading2.copyWith(
                        fontSize: AppResponsive.heading2Size(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Energy Peaks Chart
          _buildEnergyChart(energyPeaks),

          const SizedBox(height: AppSpacing.xl),

          // Time Distribution
          _buildDistributionChart(analytics),

          const SizedBox(height: AppSpacing.xl),
          Text(
            'DAILY PROGRESS',
            style: AppTextStyles.label.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          ...schedule.weekPlan.map((day) => _DailyProgressBar(day: day)),
        ],
      ),
    );
  }

  Widget _buildEnergyChart(Map<int, double> energyPeaks) {
    final maxIntensity =
        energyPeaks.values.isEmpty ? 0.0 : energyPeaks.values.reduce(max);

    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flash_on_rounded,
                color: AppColors.neonPurple,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ENERGY INTENSITY (RELATIVE)',
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(24, (index) {
                final score = energyPeaks[index] ?? 0.0;
                final normalizedHeight =
                    maxIntensity > 0 ? (score / maxIntensity) * 80 : 0.0;
                final isPeak = score > 0 && score == maxIntensity;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: normalizedHeight),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, value, _) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: value + 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isPeak
                                  ? [AppColors.neonCyan, AppColors.neonBlue]
                                  : [
                                      AppColors.neonPurple
                                          .withValues(alpha: 0.8),
                                      AppColors.neonPurple
                                          .withValues(alpha: 0.2),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (index % 6 == 0)
                        Text(
                          '${index}h',
                          style:
                              const TextStyle(fontSize: 8, color: Colors.grey),
                        )
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
    );
  }

  Widget _buildDistributionChart(AnalyticsProvider analytics) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_rounded, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              Text(
                'TIME DISTRIBUTION',
                style: AppTextStyles.label.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: SizedBox(
              width: AppResponsive.isCompact(context) ? 140 : 160,
              height: AppResponsive.isCompact(context) ? 140 : 160,
              child: CustomPaint(
                painter: _DonutChartPainter(
                  distribution: analytics.categoryDistribution,
                  total: analytics.totalFocusHours,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${analytics.totalFocusHours.toStringAsFixed(1)}h',
                        style: AppTextStyles.heading3,
                      ),
                      Text('Total', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...TaskType.values.map((type) {
            final hours = analytics.categoryDistribution[type] ?? 0;
            final percentage = analytics.totalFocusHours > 0
                ? hours / analytics.totalFocusHours
                : 0.0;
            return _DistributionBar(
              type: type,
              hours: hours,
              percentage: percentage,
            );
          }),
        ],
      ),
    );
  }
}

class _EfficiencyCard extends StatelessWidget {
  final double efficiency;
  const _EfficiencyCard({required this.efficiency});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_rounded,
                color: AppColors.neonBlue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text('EFFICIENCY', style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${efficiency.toInt()}%',
            style: AppTextStyles.heading2.copyWith(
              fontSize: AppResponsive.isCompact(context) ? 28 : 32,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: efficiency / 100,
            backgroundColor: Colors.white10,
            color: AppColors.neonBlue,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveCardGrid extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveCardGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;
        final gap = AppSpacing.md;
        final itemWidth =
            isCompact ? constraints.maxWidth : (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final TaskType type;
  final double hours;
  final double percentage;

  const _DistributionBar({
    required this.type,
    required this.hours,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type.name.toUpperCase(),
                style: AppTextStyles.label.copyWith(fontSize: 10),
              ),
              Text(
                '${hours.toStringAsFixed(1)}h (${(percentage * 100).toInt()}%)',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.white10,
            color: color,
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}

class _DailyProgressBar extends StatelessWidget {
  final DayPlan day;
  const _DailyProgressBar({required this.day});

  @override
  Widget build(BuildContext context) {
    final completedCount = day.tasks.where((t) => t.completed).length;
    final totalCount = day.tasks.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                day.dayOfWeek.substring(0, 3),
                style: AppTextStyles.chip,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white10,
                color: AppColors.neonBlue,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Text('$completedCount/$totalCount', style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<TaskType, double> distribution;
  final double total;

  _DonutChartPainter({required this.distribution, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;
    final rect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    if (total <= 0) {
      canvas.drawCircle(
        center,
        radius - strokeWidth / 2,
        Paint()
          ..color = Colors.white10
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
      return;
    }

    double startAngle = -pi / 2;
    for (final type in TaskType.values) {
      final hours = distribution[type] ?? 0;
      if (hours <= 0) continue;
      final sweepAngle = (hours / total) * 2 * pi;
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle - 0.05,
        false,
        Paint()
          ..color = _getColor(type)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweepAngle;
    }
  }

  Color _getColor(TaskType type) {
    switch (type) {
      case TaskType.work:
        return AppColors.work;
      case TaskType.personal:
        return AppColors.personal;
      case TaskType.health:
        return AppColors.health;
      case TaskType.leisure:
        return AppColors.leisure;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}
