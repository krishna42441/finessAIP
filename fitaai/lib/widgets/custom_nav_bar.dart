import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/motion_utils.dart';

/// A custom navigation bar following Material 3 Design Guidelines
/// https://m3.material.io/components/navigation-bar/overview
class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavBar({
    super.key, 
    required this.currentIndex, 
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildNavContent(context),
    );
  }

  Widget _buildNavContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final navItems = [
      (icon: Icons.home_outlined, activeIcon: Icons.home, label: "Home"),
      (icon: Icons.fitness_center_outlined, activeIcon: Icons.fitness_center, label: "Workout"),
      (icon: Icons.restaurant_outlined, activeIcon: Icons.restaurant, label: "Nutrition"),
      (icon: Icons.insights_outlined, activeIcon: Icons.insights, label: "Progress"),
    ];
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(navItems.length, (index) {
          // Skip the center position for the FAB
          if (index == navItems.length ~/ 2) {
            return _buildCentralButton(context);
          }
          
          // Adjust index to account for FAB
          final adjustedIndex = index > navItems.length ~/ 2 ? index - 1 : index;
          final item = navItems[adjustedIndex];
          final isActive = currentIndex == adjustedIndex;
          
          return _buildNavItem(
            context: context,
            icon: isActive ? item.activeIcon : item.icon,
            label: item.label,
            isActive: isActive,
            onTap: () => onTap(adjustedIndex),
          );
        }),
      ),
    );
  }
  
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: colorScheme.primary.withOpacity(0.1),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: MotionUtils.medium,
          curve: MotionUtils.emphasized,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon with scale effect
              AnimatedContainer(
                duration: MotionUtils.small,
                curve: MotionUtils.emphasized,
                height: 40,
                width: 40,
                decoration: isActive
                    ? BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      )
                    : null,
                child: Center(
                  child: AnimatedScale(
                    scale: isActive ? 1.0 : 0.9,
                    duration: MotionUtils.small,
                    curve: MotionUtils.emphasized,
                    child: AnimatedRotation(
                      turns: isActive ? 0.05 : 0.0, // Slight rotation for active items
                      duration: MotionUtils.small,
                      curve: MotionUtils.emphasized,
                      child: Icon(
                        icon,
                        color: isActive 
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Animated text with fade effect
              AnimatedDefaultTextStyle(
                duration: MotionUtils.small,
                curve: MotionUtils.emphasized,
                style: TextStyle(
                  color: isActive 
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCentralButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: () {
        // Capture the button's position for the container transform animation
        final RenderBox box = context.findRenderObject() as RenderBox;
        final Rect buttonRect = box.localToGlobal(Offset.zero) & box.size;
        
        Navigator.of(context).push(
          MotionUtils.createContainerTransform(
            context: context,
            page: const Scaffold(
              body: Center(
                child: Text('Chat Screen'),
              ),
            ),
            originRect: buttonRect,
            color: colorScheme.primaryContainer,
          ),
        );
      },
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.tertiary,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              Navigator.of(context).pushNamed(
                '/chat',
                arguments: context,
              );
            },
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.transparent,
            child: const Center(
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}