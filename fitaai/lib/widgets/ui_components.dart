import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/motion_utils.dart';

/// A Material 3 stat card with a title, value, and optional icon
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback? onTap;
  final bool useGradient;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    this.icon,
    this.accentColor,
    this.onTap,
    this.useGradient = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = accentColor ?? colorScheme.primary;
    
    return AnimatedScale(
      scale: 1.0,
      duration: MotionUtils.medium,
      curve: MotionUtils.emphasized,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: useGradient ? null : colorScheme.surface,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withOpacity(0.1),
          splashFactory: InkRipple.splashFactory,
          highlightColor: Colors.transparent,
          child: Ink(
            decoration: useGradient
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.tertiary,
                      ],
                    ),
                  )
                : null,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: useGradient 
                            ? Colors.white.withOpacity(0.9) 
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (icon != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (useGradient ? Colors.white : color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          icon,
                          size: 22,
                          color: useGradient ? Colors.white : color,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  value,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: useGradient ? Colors.white : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A large value display with title and stat (Material 3)
class LargeStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Widget? chart;

  const LargeStatCard({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.chart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (chart != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: chart!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A horizontal stat list item with Material 3 styling
class StatListItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final bool showDivider;
  final VoidCallback? onTap;

  const StatListItem({
    Key? key,
    required this.title,
    required this.value,
    this.icon,
    this.iconColor,
    this.showDivider = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = iconColor ?? colorScheme.primary;
    
    return InkWell(
      onTap: onTap,
      splashColor: colorScheme.primary.withOpacity(0.1),
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.outlineVariant.withOpacity(0.5),
              indent: icon != null ? 58 : 12,
            ),
        ],
      ),
    );
  }
}

/// A Material 3 Action Chip
class ActionChipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isSelected;
  final Color? color;

  const ActionChipButton({
    Key? key,
    required this.label,
    required this.onTap,
    this.icon,
    this.isSelected = false,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipColor = color ?? colorScheme.primary;
    
    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: MotionUtils.small,
      curve: MotionUtils.emphasized,
      child: ActionChip(
        label: Text(label),
        avatar: icon != null ? Icon(icon, size: 18) : null,
        onPressed: onTap,
        tooltip: label,
        labelStyle: TextStyle(
          color: isSelected 
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        backgroundColor: isSelected 
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceVariant.withOpacity(0.5),
        side: BorderSide(
          color: isSelected 
              ? Colors.transparent
              : colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
        elevation: isSelected ? 1 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }
}

/// A card with a title and content (Material 3)
class TitleCard extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Color? headerColor;

  const TitleCard({
    Key? key,
    required this.title,
    required this.child,
    this.actions,
    this.headerColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: headerColor ?? colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (actions != null)
                  Row(
                    children: actions!,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// A Material 3 segmented button
class SegmentControl extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final Function(int) onSegmentTapped;

  const SegmentControl({
    Key? key,
    required this.segments,
    required this.selectedIndex,
    required this.onSegmentTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Create the segments data structure
    final List<ButtonSegment<int>> segmentWidgets = List.generate(
      segments.length,
      (index) => ButtonSegment<int>(
        value: index,
        label: Text(segments[index]),
      ),
    );
    
    return SegmentedButton<int>(
      segments: segmentWidgets,
      selected: {selectedIndex},
      onSelectionChanged: (Set<int> newSelection) {
        onSegmentTapped(newSelection.first);
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.secondaryContainer;
          }
          return null;
        }),
        foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.onSecondaryContainer;
          }
          return colorScheme.onSurface;
        }),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        side: MaterialStateProperty.all<BorderSide>(
          BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        visualDensity: VisualDensity.standard,
        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}

/// A Material 3 search field
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  
  const SearchField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    if (onChanged != null) {
                      onChanged!('');
                    }
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        ),
      ),
    );
  }
}

/// A Material 3 filter chip group
class FilterChipGroup extends StatelessWidget {
  final List<String> options;
  final List<int> selectedIndices;
  final Function(int, bool) onSelectionChanged;
  final List<IconData>? icons;
  
  const FilterChipGroup({
    Key? key,
    required this.options,
    required this.selectedIndices,
    required this.onSelectionChanged,
    this.icons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        options.length,
        (index) {
          final isSelected = selectedIndices.contains(index);
          return FilterChip(
            label: Text(options[index]),
            selected: isSelected,
            onSelected: (selected) {
              onSelectionChanged(index, selected);
            },
            avatar: icons != null && index < icons!.length
                ? Icon(icons![index], size: 18)
                : null,
            showCheckmark: true,
          );
        },
      ),
    );
  }
}

/// A colorful progress bar with label (Material 3)
class LinearProgressIndicatorWithLabel extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color? color;
  
  const LinearProgressIndicatorWithLabel({
    Key? key,
    required this.label,
    required this.value,
    required this.progress,
    this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final barColor = color ?? colorScheme.primary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

/// A Material 3 list item with leading icon and optional trailing value
class IconListItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final String? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;
  
  const IconListItem({
    Key? key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconBgColor = iconColor ?? colorScheme.primary;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBgColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconBgColor,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium)
          : null,
      trailing: trailing != null
          ? Text(
              trailing!,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            )
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

/// A Material 3 animated FAB (Floating Action Button)
class AnimatedFAB extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool extended;
  
  const AnimatedFAB({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.extended = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MotionUtils.medium,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
      child: extended
          ? FloatingActionButton.extended(
              key: const ValueKey('extended'),
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            )
          : FloatingActionButton(
              key: const ValueKey('regular'),
              onPressed: onPressed,
              child: Icon(icon),
            ),
    );
  }
}

/// A card for future scheduled items with Material 3 styling
class ScheduleCard extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final IconData icon;
  final VoidCallback? onTap;
  
  const ScheduleCard({
    Key? key,
    required this.title,
    required this.date,
    required this.time,
    required this.icon,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}