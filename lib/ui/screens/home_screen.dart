import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'analytics_view.dart';
import 'schedule_view.dart';
import 'work_plans_view.dart';

class ChronosHome extends StatefulWidget {
  const ChronosHome({super.key});

  @override
  State<ChronosHome> createState() => _ChronosHomeState();
}

class _ChronosHomeState extends State<ChronosHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ScheduleView(),
    WorkPlansView(),
    AnalyticsView(),
  ];

  @override
  Widget build(BuildContext context) {
    // Basic Responsive Check
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 250,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: Colors.white10)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_filled, color: AppColors.neonBlue),
                        SizedBox(width: 12),
                        Text("CHRONOS", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  _buildNavTile(0, Icons.calendar_today, "Schedule"),
                  _buildNavTile(1, Icons.layers_outlined, "WorkPlans"),
                  _buildNavTile(2, Icons.pie_chart_outline, "Analytics"),
                ],
              ),
            ),

          Expanded(
            child: SafeArea(
              child: _screens[_currentIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
              color: Color(0xCC0F172A),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              currentIndex: _currentIndex,
              onTap: (idx) => setState(() => _currentIndex = idx),
              selectedItemColor: AppColors.neonBlue,
              unselectedItemColor: Colors.grey,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Schedule"),
                BottomNavigationBarItem(icon: Icon(Icons.layers_outlined), label: "Plans"),
                BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: "Insights"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavTile(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.neonBlue : Colors.grey),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onTap: () => setState(() => _currentIndex = index),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: const Border(left: BorderSide(color: Colors.transparent, width: 4)),
    );
  }
}
