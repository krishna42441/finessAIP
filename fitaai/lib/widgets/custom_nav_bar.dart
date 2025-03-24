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
    this.translucent = false,
  });

  @override
  Widget build(BuildContext context) {
    return _buildNavBar(context);
  }

  Widget _buildNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: translucent 
            ? Colors.black.withOpacity(0.5) 
            : AppTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: translucent
          ? ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: _buildNavContent(context),
              ),
            )
          : _buildNavContent(context),
    );
  }

  Widget _buildNavContent(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, 0, Icons.dashboard_outlined, Icons.dashboard, "Home"),
            _buildNavItem(context, 1, Icons.fitness_center_outlined, Icons.fitness_center, "Workout"),
            _buildNavItem(context, 2, Icons.restaurant_outlined, Icons.restaurant, "Nutrition"),
            _buildNavItem(context, 3, Icons.trending_up_outlined, Icons.trending_up, "Progress"),
            _buildNavItem(context, 4, Icons.chat_bubble_outline, Icons.chat_bubble, "Chat"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = currentIndex == index;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
} 