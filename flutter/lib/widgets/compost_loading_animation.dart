import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A composting-themed loading animation widget
/// Shows animated leaves/compost particles falling and rotating
class CompostLoadingAnimation extends StatefulWidget {
  final String? message;
  final double size;

  const CompostLoadingAnimation({
    super.key,
    this.message,
    this.size = 120,
  });

  @override
  State<CompostLoadingAnimation> createState() => _CompostLoadingAnimationState();
}

class _CompostLoadingAnimationState extends State<CompostLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _fallController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fallAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Rotation animation for the main compost bin icon
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Falling particles animation
    _fallController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _fallAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fallController, curve: Curves.easeInOut),
    );

    // Pulse animation for breathing effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fallController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Main rotating compost bin icon
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Icon(
                            Icons.eco,
                            size: widget.size * 0.6,
                            color: AppTheme.primaryGreen,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              // Falling particles/leaves around the icon
              ...List.generate(6, (index) {
                return AnimatedBuilder(
                  animation: _fallAnimation,
                  builder: (context, child) {
                    final angle = (index * 60) * 3.14159 / 180;
                    final radius = widget.size * 0.4;
                    final offset = _fallAnimation.value * 20 - 10;
                    
                    final x = radius * (1 + _fallAnimation.value * 0.3) * 
                             (1 + 0.1 * (index % 2)) * 
                             (index % 2 == 0 ? 1 : -1);
                    final y = radius * (1 + _fallAnimation.value * 0.3) * 
                             (1 + 0.1 * (index % 3)) * 
                             (index % 3 == 0 ? 1 : -1) + offset;

                    return Positioned(
                      left: widget.size / 2 + x - 6,
                      top: widget.size / 2 + y - 6,
                      child: Transform.rotate(
                        angle: _fallAnimation.value * 2 * 3.14159 + angle,
                        child: Opacity(
                          opacity: 1 - (_fallAnimation.value * 0.5),
                          child: Icon(
                            Icons.eco,
                            size: 12,
                            color: AppTheme.primaryGreen.withOpacity(0.6),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 24),
          Text(
            widget.message!,
            style: TextStyle(
              color: AppTheme.textGray,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// A simpler version with just rotating leaves
class SimpleCompostLoader extends StatefulWidget {
  final String? message;
  final double size;

  const SimpleCompostLoader({
    super.key,
    this.message,
    this.size = 60,
  });

  @override
  State<SimpleCompostLoader> createState() => _SimpleCompostLoaderState();
}

class _SimpleCompostLoaderState extends State<SimpleCompostLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animation.value * 2 * 3.14159,
              child: Icon(
                Icons.eco,
                size: widget.size,
                color: AppTheme.primaryGreen,
              ),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: TextStyle(
              color: AppTheme.textGray,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

