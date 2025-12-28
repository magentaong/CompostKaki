import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Simple floating "+X XP" animation
class XPFloatingAnimation extends StatefulWidget {
  final int xpAmount;
  final bool isLevelUp;

  const XPFloatingAnimation({
    super.key,
    required this.xpAmount,
    this.isLevelUp = false,
  });

  @override
  State<XPFloatingAnimation> createState() => _XPFloatingAnimationState();
}

class _XPFloatingAnimationState extends State<XPFloatingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: -100.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Positioned(
            bottom: 100 + _slideAnimation.value,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isLevelUp
                          ? AppTheme.primaryGreen
                          : (widget.xpAmount < 0 
                              ? Colors.red.shade700 
                              : Colors.black87),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: widget.xpAmount < 0
                              ? Colors.red.withOpacity(0.5)
                              : AppTheme.primaryGreen.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isLevelUp) ...[
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'LEVEL UP! ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        Icon(
                          widget.xpAmount < 0 ? Icons.remove_circle : Icons.workspace_premium,
                          color: widget.xpAmount < 0 ? Colors.white : Colors.amber,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.xpAmount >= 0 
                              ? '+${widget.xpAmount} XP'
                              : '-${widget.xpAmount.abs()} XP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Helper function to show floating XP animation
void showXPFloatingAnimation(
  BuildContext context, {
  required int xpAmount,
  bool isLevelUp = false,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        XPFloatingAnimation(
          xpAmount: xpAmount,
          isLevelUp: isLevelUp,
        ),
      ],
    ),
  );

  overlay.insert(overlayEntry);

  // Auto-remove after animation
  Future.delayed(const Duration(milliseconds: 2100), () {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  });
}

