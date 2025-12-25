import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/xp_service.dart';
import '../services/bin_service.dart';

enum KakiState {
  idle,
  happy,
  worried,
  sleepy,
  celebrating,
  encouraging,
  surprised,
}

class KakiMascotWidget extends StatefulWidget {
  final List<Map<String, dynamic>> bins;
  final Map<String, dynamic>? xpStats;
  final VoidCallback? onTap;

  const KakiMascotWidget({
    super.key,
    required this.bins,
    this.xpStats,
    this.onTap,
  });

  @override
  State<KakiMascotWidget> createState() => _KakiMascotWidgetState();
}

class _KakiMascotWidgetState extends State<KakiMascotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;
  KakiState _currentState = KakiState.idle;
  String _currentMessage = '';
  bool _showMessage = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _updateStateAndMessage();
  }

  @override
  void didUpdateWidget(KakiMascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bins != widget.bins || oldWidget.xpStats != widget.xpStats) {
      _updateStateAndMessage();
    }
  }

  void _updateStateAndMessage() {
    final newState = _determineState();
    final newMessage = _getMessageForState(newState);

    if (newState != _currentState || newMessage != _currentMessage) {
      setState(() {
        _currentState = newState;
        _currentMessage = newMessage;
      });
    }
  }

  KakiState _determineState() {
    // Check for urgent bin issues
    final criticalBins = widget.bins.where((bin) {
      final status = bin['health_status'] as String?;
      return status == 'Critical';
    }).length;

    if (criticalBins > 0) {
      return KakiState.worried;
    }

    // Check for high level or achievements (levelUp is not in getUserStats, check level instead)
    if (widget.xpStats != null) {
      final currentLevel = widget.xpStats!['currentLevel'] as int? ?? 1;
      // Celebrate if recently leveled up (we'd need to track this separately)
      // For now, celebrate high levels
      if (currentLevel >= 5) {
        return KakiState.happy;
      }
    }

    // Check streak status
    if (widget.xpStats != null) {
      final streakDays = widget.xpStats!['streakDays'] as int? ?? 0;
      if (streakDays >= 7) {
        return KakiState.happy;
      }
    }

    // Check if bins need attention
    final needsAttentionBins = widget.bins.where((bin) {
      final status = bin['health_status'] as String?;
      return status == 'Needs Attention';
    }).length;

    if (needsAttentionBins > 0) {
      return KakiState.encouraging;
    }

    // Check last activity time (would need to be passed in)
    // For now, default to idle or happy based on bin count
    if (widget.bins.isEmpty) {
      return KakiState.encouraging;
    }

    return KakiState.idle;
  }

  String _getMessageForState(KakiState state) {
    switch (state) {
      case KakiState.worried:
        final criticalCount = widget.bins
            .where((bin) => bin['health_status'] == 'Critical')
            .length;
        if (criticalCount == 1) {
          return 'One of your bins needs urgent attention!';
        }
        return '$criticalCount bins need urgent attention!';

      case KakiState.celebrating:
        return '🎉 Level up! You\'re amazing!';

      case KakiState.happy:
        final streakDays = widget.xpStats?['streakDays'] as int? ?? 0;
        if (streakDays >= 7) {
          return '🔥 Amazing streak! Keep it up!';
        }
        return 'Great job composting! 🌱';

      case KakiState.encouraging:
        if (widget.bins.isEmpty) {
          return 'Ready to start composting? Add your first bin!';
        }
        final needsAttention = widget.bins
            .where((bin) => bin['health_status'] == 'Needs Attention')
            .length;
        if (needsAttention > 0) {
          return 'Some bins could use a check!';
        }
        return 'Keep up the great work! 💪';

      case KakiState.sleepy:
        return 'Haven\'t seen you in a while...';

      case KakiState.surprised:
        return 'Wow! Look at your progress!';

      case KakiState.idle:
      default:
        final hour = DateTime.now().hour;
        if (hour < 12) {
          return 'Good morning! Ready to compost?';
        } else if (hour < 18) {
          return 'Afternoon! How are your bins?';
        } else {
          return 'Evening! Time to check your compost!';
        }
    }
  }

  String _getImagePathForState(KakiState state) {
    switch (state) {
      case KakiState.happy:
        return 'assets/images/mascot/kaki_happy.png';
      case KakiState.worried:
        return 'assets/images/mascot/kaki_worried.png';
      case KakiState.sleepy:
        return 'assets/images/mascot/kaki_sleepy.png';
      case KakiState.celebrating:
        return 'assets/images/mascot/kaki_celebrating.png';
      case KakiState.encouraging:
        return 'assets/images/mascot/kaki_encouraging.png';
      case KakiState.surprised:
        return 'assets/images/mascot/kaki_surprised.png';
      case KakiState.idle:
      default:
        return 'assets/images/mascot/kaki_idle.png';
    }
  }

  void _handleTap() {
    setState(() {
      _showMessage = true;
    });

    // Hide message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showMessage = false;
        });
      }
    });

    widget.onTap?.call();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreenLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Kaki mascot image with animation
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_bounceAnimation.value),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.primaryGreenLight, // Match parent background
                    child: Image.asset(
                      _getImagePathForState(_currentState),
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to emoji if image not found
                        return _buildEmojiFallback();
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            // Message bubble
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Kaki',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.eco,
                        size: 16,
                        color: AppTheme.primaryGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showMessage
                        ? Text(
                            _currentMessage,
                            key: ValueKey(_currentMessage),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textGray,
                            ),
                          )
                        : Text(
                            _currentMessage,
                            key: ValueKey(_currentMessage),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textGray,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            // Tap indicator
            Icon(
              Icons.touch_app,
              size: 20,
              color: AppTheme.primaryGreen.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiFallback() {
    // Fallback emoji based on state
    String emoji = '🪱';
    switch (_currentState) {
      case KakiState.happy:
        emoji = '😊';
        break;
      case KakiState.worried:
        emoji = '😟';
        break;
      case KakiState.sleepy:
        emoji = '😴';
        break;
      case KakiState.celebrating:
        emoji = '🎉';
        break;
      case KakiState.encouraging:
        emoji = '👍';
        break;
      case KakiState.surprised:
        emoji = '😲';
        break;
      default:
        emoji = '🪱';
    }

    return Center(
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 60),
      ),
    );
  }
}

