import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class XPCelebrationWidget extends StatefulWidget {
  final int xpGained;
  final bool isLevelUp;
  final List<String>? badgesEarned;
  final VoidCallback? onComplete;

  const XPCelebrationWidget({
    super.key,
    required this.xpGained,
    this.isLevelUp = false,
    this.badgesEarned,
    this.onComplete,
  });

  @override
  State<XPCelebrationWidget> createState() => _XPCelebrationWidgetState();
}

class _XPCelebrationWidgetState extends State<XPCelebrationWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: -50.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _mainController.forward();
    _particleController.repeat();

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Particle effects
                    ...List.generate(20, (index) => _buildParticle(index)),
                    
                    // Main content
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Level Up Badge
                          if (widget.isLevelUp) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.star,
                                color: AppTheme.primaryGreen,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'LEVEL UP!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          
                          // XP Gained
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.workspace_premium,
                                color: Colors.amber,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '+${widget.xpGained} XP',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                          
                          // Badges Earned
                          if (widget.badgesEarned != null &&
                              widget.badgesEarned!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Badge Unlocked!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textGray,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: widget.badgesEarned!.map((badgeId) {
                                final badgeInfo = _getBadgeInfo(badgeId);
                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: (badgeInfo['imagePath'] as String?) != null &&
                                          (badgeInfo['imagePath'] as String).isNotEmpty
                                      ? Image.asset(
                                          badgeInfo['imagePath'] as String,
                                          width: 32,
                                          height: 32,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            // Fallback to emoji if image not found
                                            return Text(
                                              badgeInfo['emoji'] as String,
                                              style: const TextStyle(fontSize: 24),
                                            );
                                          },
                                        )
                                      : Text(
                                          badgeInfo['emoji'] as String,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticle(int index) {
    final random = math.Random(index);
    final angle = random.nextDouble() * 2 * math.pi;
    final distance = 100.0 + random.nextDouble() * 50;
    
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = _particleController.value;
        final x = math.cos(angle) * distance * progress;
        final y = math.sin(angle) * distance * progress;
        final opacity = 1.0 - progress;
        final scale = 1.0 - progress * 0.5;

        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _getBadgeInfo(String badgeId) {
    const badgeMap = {
      'first_log': {
        'name': 'First Steps',
        'imagePath': 'assets/images/badges/badge_first_log.png',
        'emoji': '🌱',
      },
      'log_10': {
        'name': 'Dedicated Logger',
        'imagePath': 'assets/images/badges/badge_first_10.png', // Using existing file
        'emoji': '📝',
      },
      'log_50': {
        'name': 'On Fire',
        'imagePath': 'assets/images/badges/badge_first_50.png', // Using existing file
        'emoji': '🔥',
      },
      'log_100': {
        'name': 'Data Master',
        'imagePath': 'assets/images/badges/badge_log_100.png',
        'emoji': '📊',
      },
      'complete_1': {
        'name': 'Helper',
        'imagePath': 'assets/images/badges/badge_complete_1.png',
        'emoji': '✅',
      },
      'complete_5': {
        'name': 'Team Player',
        'imagePath': 'assets/images/badges/badge_complete_5.png',
        'emoji': '🤝',
      },
      'complete_10': {
        'name': 'Task Master',
        'imagePath': 'assets/images/badges/badge_complete_10.png',
        'emoji': '⭐',
      },
      'complete_25': {
        'name': 'Community Hero',
        'imagePath': 'assets/images/badges/badge_complete_25.png',
        'emoji': '🏅',
      },
      'streak_3': {
        'name': '3-Day Streak',
        'imagePath': 'assets/images/badges/badge_streak_3.png',
        'emoji': '🔥',
      },
      'streak_7': {
        'name': 'Week Warrior',
        'imagePath': 'assets/images/badges/badge_streak_7.png',
        'emoji': '💪',
      },
      'streak_30': {
        'name': 'Month Master',
        'imagePath': 'assets/images/badges/badge_streak_30.png',
        'emoji': '🌟',
      },
      'streak_100': {
        'name': 'Consistency King',
        'imagePath': 'assets/images/badges/badge_streak_100.png',
        'emoji': '👑',
      },
    };
    return badgeMap[badgeId] ??
        {'name': 'Badge', 'imagePath': '', 'emoji': '🏆'};
  }
}

// Helper function to show XP celebration overlay
void showXPCelebration(
  BuildContext context, {
  required int xpGained,
  bool isLevelUp = false,
  List<String>? badgesEarned,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;
  
  overlayEntry = OverlayEntry(
    builder: (context) => Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: XPCelebrationWidget(
            xpGained: xpGained,
            isLevelUp: isLevelUp,
            badgesEarned: badgesEarned,
            onComplete: () {
              overlayEntry.remove();
            },
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // Auto-remove after animation completes
  Future.delayed(const Duration(milliseconds: 2100), () {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  });
}

