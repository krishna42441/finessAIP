import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Utility class for handling display-related optimizations
class DisplayUtils {
  /// The default animation duration for standard animations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 200);
  
  /// The animation duration for micro-animations (very quick transitions)
  static const Duration microAnimationDuration = Duration(milliseconds: 100);
  
  /// The animation duration for macro-animations (longer, more elaborate animations)
  static const Duration macroAnimationDuration = Duration(milliseconds: 300);
  
  /// The animation curve for standard animations
  static const Curve defaultAnimationCurve = Curves.easeOutCubic;
  
  /// The animation curve for bouncy animations
  static const Curve bouncyAnimationCurve = Curves.easeOutBack;
  
  /// The animation curve for precise animations
  static const Curve preciseAnimationCurve = Curves.fastOutSlowIn;
  
  /// Get the current refresh rate of the device
  static double get refreshRate {
    // Default to 60Hz if we can't determine the actual refresh rate
    return 60.0;
  }
  
  /// Check if the device has a high refresh rate display (> 60Hz)
  static bool get isHighRefreshRateDisplay {
    // For now, we'll assume standard 60Hz displays
    // In a real app, you would use platform-specific code to detect this
    return false;
  }
  
  /// Get the optimal animation duration based on the device's refresh rate
  static Duration getOptimalAnimationDuration(Duration baseDuration) {
    // For now, just return the base duration
    // In a real implementation, this would adjust based on refresh rate
    return baseDuration;
  }
  
  /// Configure the app for optimal performance on high refresh rate displays
  static void optimizeForHighRefreshRate() {
    // Set preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
  }
  
  /// Create an optimized animation controller for high refresh rate displays
  static AnimationController createOptimizedAnimationController({
    required TickerProvider vsync,
    required Duration duration,
    Duration? reverseDuration,
  }) {
    return AnimationController(
      vsync: vsync,
      duration: duration,
      reverseDuration: reverseDuration,
    );
  }
  
  /// Create a smooth page transition for high refresh rate displays
  static PageRouteBuilder createSmoothPageRoute({
    required Widget Function(BuildContext, Animation<double>, Animation<double>) pageBuilder,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: pageBuilder,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}

/// A widget that optimizes animations for high refresh rate displays
class OptimizedAnimatedContainer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final BoxDecoration decoration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry? alignment;
  final double? width;
  final double? height;
  
  const OptimizedAnimatedContainer({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeOutCubic,
    required this.decoration,
    this.padding,
    this.margin,
    this.alignment,
    this.width,
    this.height,
  }) : super(key: key);
  
  @override
  State<OptimizedAnimatedContainer> createState() => _OptimizedAnimatedContainerState();
}

class _OptimizedAnimatedContainerState extends State<OptimizedAnimatedContainer> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: widget.duration,
      curve: widget.curve,
      decoration: widget.decoration,
      padding: widget.padding,
      margin: widget.margin,
      alignment: widget.alignment,
      width: widget.width,
      height: widget.height,
      child: widget.child,
    );
  }
}

/// A widget that optimizes transitions for high refresh rate displays
class OptimizedAnimatedSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve switchInCurve;
  final Curve switchOutCurve;
  final AnimatedSwitcherTransitionBuilder transitionBuilder;
  
  const OptimizedAnimatedSwitcher({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.switchInCurve = Curves.easeOutCubic,
    this.switchOutCurve = Curves.easeInCubic,
    this.transitionBuilder = AnimatedSwitcher.defaultTransitionBuilder,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      transitionBuilder: transitionBuilder,
      child: child,
    );
  }
}