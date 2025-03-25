import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool translucent;

  const CustomNavBar({
    super.key, 
    required this.currentIndex, 
    required this.onTap,
    this.translucent = true,
  });

  @override
  Widget build(BuildContext context) {
    return _buildNavBar(context);
  }

  Widget _buildNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: translucent 
            ? Colors.black.withOpacity(0.2) 
            : AppTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: translucent
          ? ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: _buildNavContent(context),
              ),
            )
          : _buildNavContent(context),
    );
  }

  Widget _buildNavContent(BuildContext context) {
    final navItems = [
      (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: "Home"),
      (icon: Icons.fitness_center_outlined, activeIcon: Icons.fitness_center, label: "Workout"),
      (icon: Icons.restaurant_outlined, activeIcon: Icons.restaurant, label: "Nutrition"),
      (icon: Icons.trending_up_outlined, activeIcon: Icons.trending_up, label: "Progress"),
    ];
    
    return Stack(
      alignment: Alignment.center,
      children: [
        NavigationBar(
          selectedIndex: currentIndex == 4 ? 0 : currentIndex,
          onDestinationSelected: (index) {
            if (index >= navItems.length) return;
            onTap(index);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: navItems.map((item) => 
            NavigationDestination(
              icon: Icon(item.icon, color: Colors.white70),
              selectedIcon: Icon(item.activeIcon, color: AppTheme.primaryColor),
              label: item.label,
            )
          ).toList(),
        ),
        Positioned(
          top: 5,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(
                '/chat',
                arguments: context,
              );
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentIndex == 4 
                    ? AppTheme.primaryColor 
                    : AppTheme.backgroundColor,
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  'assets/icons/gemini.png',
                  width: 28,
                  height: 28,
                  color: currentIndex == 4 ? Colors.white : AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 