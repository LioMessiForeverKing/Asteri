import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with TickerProviderStateMixin {
  late Timer _timer;
  Duration _timeRemaining = Duration.zero;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Target date: November 6, 2025
  final DateTime _targetDate = DateTime(2025, 11, 6, 0, 0, 0);

  @override
  void initState() {
    super.initState();

    // Setup pulse animation for the timer
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);

    // Calculate initial time
    _updateTimeRemaining();

    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTimeRemaining();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    setState(() {
      _timeRemaining = _targetDate.difference(now);
    });
  }

  Future<void> _signOut() async {
    try {
      await AuthService.signOut();
      // Navigation handled by AuthGate
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign out failed: $e'),
          backgroundColor: AsteriaTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNegative = _timeRemaining.isNegative;
    final days = isNegative ? 0 : _timeRemaining.inDays;
    final hours = isNegative ? 0 : _timeRemaining.inHours.remainder(24);
    final minutes = isNegative ? 0 : _timeRemaining.inMinutes.remainder(60);
    final seconds = isNegative ? 0 : _timeRemaining.inSeconds.remainder(60);

    return Scaffold(
      body: Stack(
        children: [
          // Paper background
          Container(decoration: AsteriaTheme.gradientOverlayDecoration()),

          // Decorative elements
          Positioned(
            top: -50,
            right: -50,
            child: Opacity(
              opacity: 0.2,
              child: Container(
                width: 200,
                height: 200,
                decoration: AsteriaTheme.paperCardDecoration(
                  backgroundColor: AsteriaTheme.accentLight,
                  elevation: AsteriaTheme.elevationLow,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Opacity(
              opacity: 0.15,
              child: Container(
                width: 250,
                height: 250,
                decoration: AsteriaTheme.paperCardDecoration(
                  backgroundColor: AsteriaTheme.secondaryLight,
                  elevation: AsteriaTheme.elevationLow,
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header with logo and sign out
                Padding(
                  padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Container(
                        decoration: AsteriaTheme.paperCardDecoration(),
                        padding: const EdgeInsets.all(
                          AsteriaTheme.spacingSmall,
                        ),
                        child: SvgPicture.asset(
                          'assets/Logos/Asteri.svg',
                          width: 40,
                          height: 40,
                        ),
                      ),

                      // Sign out button
                      Container(
                        decoration: AsteriaTheme.paperCardDecoration(),
                        child: IconButton(
                          icon: const Icon(Icons.logout_rounded),
                          color: AsteriaTheme.primaryColor,
                          onPressed: _signOut,
                          tooltip: 'Sign Out',
                        ),
                      ),
                    ],
                  ),
                ),

                // Main timer content
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Title
                          Text(
                            'Countdown to',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: AsteriaTheme.textSecondary),
                          ),
                          const SizedBox(height: AsteriaTheme.spacingSmall),

                          Text(
                            'November 6th, 2025',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(color: AsteriaTheme.primaryColor),
                          ),

                          const SizedBox(height: AsteriaTheme.spacingXLarge),

                          // Timer display
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(
                                AsteriaTheme.spacingXLarge,
                              ),
                              decoration: AsteriaTheme.elevatedPaperDecoration(
                                backgroundColor: AsteriaTheme.backgroundPrimary,
                              ),
                              child: Column(
                                children: [
                                  if (isNegative)
                                    Text(
                                      'Event has passed!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: AsteriaTheme.errorColor,
                                          ),
                                    )
                                  else
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: AsteriaTheme.spacingSmall,
                                      runSpacing: AsteriaTheme.spacingSmall,
                                      children: [
                                        _TimeUnitCard(
                                          value: days,
                                          label: 'DAYS',
                                        ),
                                        _TimeUnitCard(
                                          value: hours,
                                          label: 'HOURS',
                                        ),
                                        _TimeUnitCard(
                                          value: minutes,
                                          label: 'MIN',
                                        ),
                                        _TimeUnitCard(
                                          value: seconds,
                                          label: 'SEC',
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: AsteriaTheme.spacingXLarge),

                          // Subtitle or description
                          Container(
                            padding: const EdgeInsets.all(
                              AsteriaTheme.spacingLarge,
                            ),
                            decoration: AsteriaTheme.paperCardDecoration(
                              backgroundColor: AsteriaTheme.backgroundSecondary,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 40,
                                  color: AsteriaTheme.accentColor,
                                ),
                                const SizedBox(
                                  height: AsteriaTheme.spacingMedium,
                                ),
                                Text(
                                  isNegative
                                      ? 'The countdown has ended!'
                                      : 'The countdown continues...',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AsteriaTheme.textPrimary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(
                                  height: AsteriaTheme.spacingSmall,
                                ),
                                Text(
                                  'Your watch history reveals your connections',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AsteriaTheme.textSecondary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeUnitCard extends StatelessWidget {
  final int value;
  final String label;

  const _TimeUnitCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 65, maxWidth: 85),
      padding: const EdgeInsets.symmetric(
        horizontal: AsteriaTheme.spacingSmall,
        vertical: AsteriaTheme.spacingMedium,
      ),
      decoration: AsteriaTheme.paperCardDecoration(
        backgroundColor: AsteriaTheme.backgroundSecondary,
        elevation: AsteriaTheme.elevationMedium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.toString().padLeft(2, '0'),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AsteriaTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AsteriaTheme.spacingXSmall),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AsteriaTheme.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
