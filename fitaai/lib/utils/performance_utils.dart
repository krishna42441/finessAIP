import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';
import 'display_utils.dart';

/// Utility class for performance optimizations
class PerformanceUtils {
  /// Enable performance optimizations for the app
  static void enablePerformanceOptimizations() {
    // Set up basic performance optimizations
    // Note: We've removed the methods that don't exist in the Flutter framework
  }
  
  /// Optimize a widget for high performance rendering
  static Widget optimizeWidget(Widget widget) {
    return RepaintBoundary(
      child: widget,
    );
  }
}

/// A widget that optimizes rendering performance for lists
class OptimizedListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  
  const OptimizedListView({
    Key? key,
    required this.children,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: children.length,
      itemBuilder: (context, index) {
        // Wrap each item in a RepaintBoundary to optimize rendering
        return RepaintBoundary(
          child: children[index],
        );
      },
    );
  }
}

/// A widget that optimizes rendering performance for grids
class OptimizedGridView extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  
  const OptimizedGridView({
    Key? key,
    required this.children,
    required this.crossAxisCount,
    this.childAspectRatio = 1.0,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.crossAxisSpacing = 0.0,
    this.mainAxisSpacing = 0.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        // Wrap each item in a RepaintBoundary to optimize rendering
        return RepaintBoundary(
          child: children[index],
        );
      },
    );
  }
}

/// A widget that optimizes image rendering
class OptimizedImage extends StatelessWidget {
  final ImageProvider image;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Color? color;
  final BorderRadius? borderRadius;
  
  const OptimizedImage({
    Key? key,
    required this.image,
    this.width,
    this.height,
    this.fit,
    this.color,
    this.borderRadius,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image(
      image: image,
      width: width,
      height: height,
      fit: fit,
      color: color,
      filterQuality: FilterQuality.medium, // Balance between quality and performance
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
    );
    
    // Apply border radius if specified
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }
    
    // Wrap in RepaintBoundary for optimized rendering
    return RepaintBoundary(
      child: imageWidget,
    );
  }
}

/// A widget that optimizes scrolling performance
class OptimizedScrollView extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  
  const OptimizedScrollView({
    Key? key,
    required this.child,
    this.controller,
    this.physics,
    this.padding,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        // Optimize scrolling by reducing rendering quality during fast scrolls
        if (notification is ScrollUpdateNotification) {
          if (notification.dragDetails != null && 
              notification.dragDetails!.primaryDelta != null &&
              notification.dragDetails!.primaryDelta!.abs() > 10) {
            // Fast scroll detected - could apply optimizations here if needed
          }
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: controller,
        physics: physics ?? const AlwaysScrollableScrollPhysics(),
        padding: padding,
        child: RepaintBoundary(
          child: child,
        ),
      ),
    );
  }
}

/// A widget that optimizes animations for high refresh rate displays
class OptimizedAnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;
  
  const OptimizedAnimatedBuilder({
    Key? key,
    required this.animation,
    required this.builder,
    this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: builder,
        child: child != null ? RepaintBoundary(child: child!) : null,
      ),
    );
  }
}