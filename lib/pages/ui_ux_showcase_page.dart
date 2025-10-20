import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme.dart';

class UIUXShowcasePage extends StatefulWidget {
  const UIUXShowcasePage({super.key});

  @override
  State<UIUXShowcasePage> createState() => _UIUXShowcasePageState();
}

class _UIUXShowcasePageState extends State<UIUXShowcasePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Setup fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Setup slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                // Header with logo and back button
                Padding(
                  padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      Container(
                        decoration: AsteriaTheme.paperCardDecoration(),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: AsteriaTheme.primaryColor,
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Back',
                        ),
                      ),

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

                      // Placeholder for symmetry
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(
                          AsteriaTheme.spacingLarge,
                        ),
                        child: Column(
                          children: [
                            // Title
                            Container(
                              padding: const EdgeInsets.all(
                                AsteriaTheme.spacingXLarge,
                              ),
                              decoration: AsteriaTheme.elevatedPaperDecoration(
                                backgroundColor: AsteriaTheme.backgroundPrimary,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.palette_rounded,
                                    size: 60,
                                    color: AsteriaTheme.primaryColor,
                                  ),
                                  const SizedBox(
                                    height: AsteriaTheme.spacingMedium,
                                  ),
                                  Text(
                                    'UI/UX Showcase',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(
                                          color: AsteriaTheme.primaryColor,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(
                                    height: AsteriaTheme.spacingSmall,
                                  ),
                                  Text(
                                    'Experience the beautiful design system',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: AsteriaTheme.textSecondary,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AsteriaTheme.spacingXLarge),

                            // Design System Cards
                            _buildDesignSystemCard(
                              context,
                              'Color Palette',
                              'Warm, inviting colors that create a cozy atmosphere',
                              Icons.color_lens_rounded,
                              AsteriaTheme.primaryColor,
                              _buildColorPalette(),
                            ),

                            const SizedBox(height: AsteriaTheme.spacingLarge),

                            _buildDesignSystemCard(
                              context,
                              'Typography',
                              'Clean, readable fonts that enhance user experience',
                              Icons.text_fields_rounded,
                              AsteriaTheme.secondaryColor,
                              _buildTypographyShowcase(context),
                            ),

                            const SizedBox(height: AsteriaTheme.spacingLarge),

                            _buildDesignSystemCard(
                              context,
                              'Components',
                              'Interactive elements with smooth animations',
                              Icons.widgets_rounded,
                              AsteriaTheme.accentColor,
                              _buildComponentShowcase(context),
                            ),

                            const SizedBox(height: AsteriaTheme.spacingXLarge),

                            // Paper-inspired elements showcase
                            Container(
                              padding: const EdgeInsets.all(
                                AsteriaTheme.spacingXLarge,
                              ),
                              decoration: AsteriaTheme.paperCardDecoration(
                                backgroundColor:
                                    AsteriaTheme.backgroundSecondary,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.layers_rounded,
                                    size: 50,
                                    color: AsteriaTheme.primaryColor,
                                  ),
                                  const SizedBox(
                                    height: AsteriaTheme.spacingMedium,
                                  ),
                                  Text(
                                    'Paper-Inspired Design',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AsteriaTheme.primaryColor,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(
                                    height: AsteriaTheme.spacingSmall,
                                  ),
                                  Text(
                                    'Every element feels like it could be made of paper - with soft shadows, warm colors, and gentle animations that bring the interface to life.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AsteriaTheme.textSecondary,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AsteriaTheme.spacingXXLarge),
                          ],
                        ),
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

  Widget _buildDesignSystemCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    Widget content,
  ) {
    return Container(
      decoration: AsteriaTheme.paperCardDecoration(
        backgroundColor: AsteriaTheme.backgroundPrimary,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AsteriaTheme.radiusLarge),
                topRight: Radius.circular(AsteriaTheme.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: AsteriaTheme.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: color),
                      ),
                      const SizedBox(height: AsteriaTheme.spacingXSmall),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AsteriaTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(AsteriaTheme.spacingLarge),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette() {
    final colors = [
      {'name': 'Primary', 'color': AsteriaTheme.primaryColor},
      {'name': 'Secondary', 'color': AsteriaTheme.secondaryColor},
      {'name': 'Accent', 'color': AsteriaTheme.accentColor},
      {'name': 'Success', 'color': AsteriaTheme.successColor},
      {'name': 'Warning', 'color': AsteriaTheme.warningColor},
      {'name': 'Error', 'color': AsteriaTheme.errorColor},
    ];

    return Wrap(
      spacing: AsteriaTheme.spacingMedium,
      runSpacing: AsteriaTheme.spacingMedium,
      children: colors.map((colorData) {
        return Container(
          padding: const EdgeInsets.all(AsteriaTheme.spacingMedium),
          decoration: AsteriaTheme.paperCardDecoration(
            backgroundColor: colorData['color'] as Color,
            elevation: AsteriaTheme.elevationMedium,
          ),
          child: Column(
            children: [
              Text(
                colorData['name'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypographyShowcase(BuildContext context) {
    return Column(
      children: [
        _buildTypographyExample(
          context,
          'Display Large',
          'The quick brown fox jumps over the lazy dog',
          Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: AsteriaTheme.spacingMedium),
        _buildTypographyExample(
          context,
          'Headline Medium',
          'Beautiful typography enhances readability',
          Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AsteriaTheme.spacingMedium),
        _buildTypographyExample(
          context,
          'Body Large',
          'This is how body text looks in our design system',
          Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildTypographyExample(
    BuildContext context,
    String label,
    String text,
    TextStyle? style,
  ) {
    return Container(
      padding: const EdgeInsets.all(AsteriaTheme.spacingMedium),
      decoration: AsteriaTheme.paperCardDecoration(
        backgroundColor: AsteriaTheme.backgroundSecondary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AsteriaTheme.textTertiary),
          ),
          const SizedBox(height: AsteriaTheme.spacingXSmall),
          Text(text, style: style),
        ],
      ),
    );
  }

  Widget _buildComponentShowcase(BuildContext context) {
    return Column(
      children: [
        // Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Primary Button'),
              ),
            ),
            const SizedBox(width: AsteriaTheme.spacingMedium),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Outlined Button'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AsteriaTheme.spacingMedium),

        // Text Button
        TextButton(onPressed: () {}, child: const Text('Text Button')),
        const SizedBox(height: AsteriaTheme.spacingMedium),

        // Chips
        Wrap(
          spacing: AsteriaTheme.spacingSmall,
          children: [
            Chip(
              label: const Text('Design'),
              backgroundColor: AsteriaTheme.primaryLight,
            ),
            Chip(
              label: const Text('UI/UX'),
              backgroundColor: AsteriaTheme.secondaryLight,
            ),
            Chip(
              label: const Text('Flutter'),
              backgroundColor: AsteriaTheme.accentLight,
            ),
          ],
        ),
      ],
    );
  }
}
