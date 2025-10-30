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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Graph canvas
            Padding(
              padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
              child: PassionGraph(snapshot: snapshot),
            ),

            // Bottom overlay with continue button
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Continue to Star Map',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AsteriaTheme.spacingLarge),
                    SizedBox(
                      width: 260,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                            // Prepare top interests from snapshot
                            final nodes = List.of(snapshot.nodes);
                            nodes.sort((a, b) => b.weight.compareTo(a.weight));
                            final topInterests = nodes
                                .map((n) => n.label.trim())
                                .where((s) => s.isNotEmpty)
                                .toSet()
                                .take(20)
                                .toList();

                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondary) =>
                                    ProfileSetupPage(
                                      initialInterests: topInterests,
                                    ),
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
                            backgroundColor: AsteriaTheme.accentColor,
                            foregroundColor: Colors.black,
                            elevation: 0,
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
          ],
        ),
      ),
    );
  }
}
