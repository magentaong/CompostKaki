import 'package:flutter/material.dart';

/// A badge widget that displays a count on top of a child widget
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final bool showZero;
  final Color? badgeColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;

  const NotificationBadge({
    super.key,
    required this.child,
    required this.count,
    this.showZero = false,
    this.badgeColor,
    this.textColor,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBadgeColor = badgeColor ?? theme.colorScheme.error;
    final effectiveTextColor = textColor ?? Colors.white;
    final effectiveFontSize = fontSize ?? 10.0;

    if (count <= 0 && !showZero) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0 || showZero)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: effectiveBadgeColor,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    color: effectiveTextColor,
                    fontSize: effectiveFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

