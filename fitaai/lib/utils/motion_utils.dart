import 'package:flutter/material.dart';

/// Motion utilities following Material 3 motion guidelines
/// https://m3.material.io/styles/motion/overview
class MotionUtils {
  // Duration constants
  static const Duration micro = Duration(milliseconds: 50);
  static const Duration small = Duration(milliseconds: 100); 
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration large = Duration(milliseconds: 500);
  
  // Easing curves
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  
  static const Curve standard = Curves.easeOutCubic;
  static const Curve standardAccelerate = Cubic(0.3, 0.0, 1.0, 1.0);
  static const Curve standardDecelerate = Cubic(0.0, 0.0, 0.0, 1.0);
  
  /// Create a page transition that follows Material 3 container transform pattern
  static PageRouteBuilder createContainerTransform({
    required BuildContext context,
    required Widget page,
    required Rect originRect,
    Color? color,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color backgroundColor = color ?? colorScheme.surface;
    final Size screenSize = MediaQuery.of(context).size;
    
    return PageRouteBuilder(
      transitionDuration: large,
      reverseTransitionDuration: medium,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Use CurvedAnimation for the transitions
        final CurvedAnimation curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: emphasized,
          reverseCurve: emphasizedDecelerate,
        );
        
        // Animate the rectangle (from small to fullscreen)
        final Animation<double> rectAnimation = curvedAnimation;
        
        return Stack(
          children: [
            // Fade in the entire page
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: const Interval(0.2, 1.0),
              ),
              child: child,
            ),
            // Animate a colored box from the source position to full screen
            // Fix: Use AnimatedBuilder instead of PositionedTransition
            AnimatedBuilder(
              animation: rectAnimation,
              builder: (context, _) {
                // Calculate interpolated values between start rect and full screen
                final double left = lerpDouble(
                  originRect.left, 
                  0, 
                  rectAnimation.value
                );
                final double top = lerpDouble(
                  originRect.top, 
                  0, 
                  rectAnimation.value
                );
                final double width = lerpDouble(
                  originRect.width, 
                  screenSize.width, 
                  rectAnimation.value
                );
                final double height = lerpDouble(
                  originRect.height, 
                  screenSize.height, 
                  rectAnimation.value
                );
                
                return Positioned(
                  left: left,
                  top: top,
                  width: width,
                  height: height,
                  child: Material(
                    color: backgroundColor,
                    clipBehavior: Clip.antiAlias,
                    shape: const RoundedRectangleBorder(),
                    child: animation.value > 0.5 ? child : const SizedBox.shrink(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
  
  // Helper function to linearly interpolate between two doubles
  static double lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
  
  /// Create a shared axis transition (X axis)
  static PageRouteBuilder createSharedAxisX({
    required WidgetBuilder pageBuilder,
    bool forward = true,
  }) {
    return PageRouteBuilder(
      transitionDuration: medium,
      pageBuilder: (context, animation, secondaryAnimation) => pageBuilder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Shared X axis animation comes in from the right (forward) or left (backward)
        final offsetAnimation = Tween<Offset>(
          begin: Offset(forward ? 1.0 : -1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: emphasized,
        ));
        
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
        ));
        
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
    );
  }
  
  /// Create a shared axis transition (Y axis)
  static PageRouteBuilder createSharedAxisY({
    required WidgetBuilder pageBuilder,
    bool forward = true,
  }) {
    return PageRouteBuilder(
      transitionDuration: medium,
      pageBuilder: (context, animation, secondaryAnimation) => pageBuilder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Shared Y axis animation comes in from the bottom (forward) or top (backward)
        final offsetAnimation = Tween<Offset>(
          begin: Offset(0.0, forward ? 1.0 : -1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: emphasized,
        ));
        
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
        ));
        
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
    );
  }
  
  /// Create a fade through transition
  static PageRouteBuilder createFadeThrough({
    required WidgetBuilder pageBuilder,
  }) {
    return PageRouteBuilder(
      transitionDuration: medium,
      pageBuilder: (context, animation, secondaryAnimation) => pageBuilder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
          ),
          child: child,
        );
      },
    );
  }
  
  /// Create a fade scale transition for dialogs
  static Route<T> createFadeScale<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: small,
      reverseTransitionDuration: micro,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: emphasized,
        ));
        
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ));
        
        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }
  
  /// Staggered animations for list items
  static AnimationController createStaggeredController({
    required TickerProvider vsync,
    Duration? duration,
    required int itemCount,
  }) {
    return AnimationController(
      vsync: vsync,
      duration: duration ?? Duration(milliseconds: 400 + (itemCount * 50)),
    );
  }
  
  /// Get a staggered animation for a specific item in a list
  static Animation<double> getStaggeredAnimation({
    required AnimationController controller,
    required int index,
    required int itemCount,
    double startInterval = 0.1,
    double stepInterval = 0.05,
  }) {
    // Calculate the start time for this item (0.0 to 1.0)
    final startTime = startInterval + (index * stepInterval);
    final endTime = startTime + 0.4; // Each animation takes 40% of the total duration
    
    return CurvedAnimation(
      parent: controller,
      curve: Interval(
        startTime.clamp(0.0, 1.0),
        endTime.clamp(0.0, 1.0),
        curve: emphasized,
      ),
    );
  }
  
  /// Material state animations for interactive elements
  static MaterialStateProperty<MouseCursor> get adaptiveMouseCursor {
    return MaterialStateProperty.resolveWith<MouseCursor>((states) {
      if (states.contains(MaterialState.disabled)) {
        return SystemMouseCursors.forbidden;
      }
      if (states.contains(MaterialState.dragged)) {
        return SystemMouseCursors.grabbing;
      }
      return SystemMouseCursors.click;
    });
  }
}

/// Widget for staggered fade-in animations of list items
class StaggeredAnimationList extends StatefulWidget {
  final List<Widget> children;
  final Duration? duration;
  final Axis direction;
  final double offset;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  
  const StaggeredAnimationList({
    Key? key,
    required this.children,
    this.duration,
    this.direction = Axis.vertical,
    this.offset = 0.25,
    this.scrollController,
    this.shrinkWrap = false,
    this.padding,
  }) : super(key: key);

  @override
  State<StaggeredAnimationList> createState() => _StaggeredAnimationListState();
}

class _StaggeredAnimationListState extends State<StaggeredAnimationList> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = MotionUtils.createStaggeredController(
      vsync: this,
      duration: widget.duration,
      itemCount: widget.children.length,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      shrinkWrap: widget.shrinkWrap,
      itemCount: widget.children.length,
      padding: widget.padding,
      scrollDirection: widget.direction,
      itemBuilder: (context, index) {
        final animation = MotionUtils.getStaggeredAnimation(
          controller: _controller,
          index: index,
          itemCount: widget.children.length,
        );
        
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final offset = widget.direction == Axis.vertical
                ? Offset(0, 20 * (1 - animation.value))
                : Offset(20 * (1 - animation.value), 0);
                
            return FadeTransition(
              opacity: animation,
              child: Transform.translate(
                offset: offset,
                child: widget.children[index],
              ),
            );
          },
        );
      },
    );
  }
}

/// A widget that animates changes to its child
class AnimatedWidget extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Key? childKey;
  
  const AnimatedWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
    this.childKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.25),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: childKey ?? ValueKey<Widget>(child),
        child: child,
      ),
    );
  }
}