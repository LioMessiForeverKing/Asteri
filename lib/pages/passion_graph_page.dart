import 'package:flutter/material.dart';
import '../models/passion_graph.dart';
import '../widgets/passion_graph.dart';
import '../theme.dart';
import 'profile_setup_page.dart';

class PassionGraphPage extends StatelessWidget {
  final GraphSnapshot snapshot;

  const PassionGraphPage({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AsteriaTheme.backgroundPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            // Graph canvas
            Padding(
              padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
              child: Container(
                decoration: AsteriaTheme.cleanCardDecoration(),
                child: PassionGraph(snapshot: snapshot),
              ),
            ),

            // Bottom overlay with continue button
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
                child: Container(
                  decoration: AsteriaTheme.cleanCardDecoration(),
                  padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Continue to Star Map',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AsteriaTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AsteriaTheme.spacingLarge),
                      SizedBox(
                        width: 220,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondary) =>
                                    const ProfileSetupPage(),
                                transitionsBuilder:
                                    (context, animation, secondary, child) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                transitionDuration:
                                    AsteriaTheme.animationMedium,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AsteriaTheme.secondaryColor,
                            foregroundColor: AsteriaTheme.accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AsteriaTheme.radiusXLarge,
                              ),
                            ),
                          ),
                          child: const Text('Continue'),
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
    );
  }
}
