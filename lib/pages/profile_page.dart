import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/theme_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final interests = const [
      _Interest(name: 'Technology', emoji: '💻'),
      _Interest(name: 'Gaming', emoji: '🎮'),
      _Interest(name: 'Music', emoji: '🎵'),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AsteriaTheme.spacingLarge,
            vertical: AsteriaTheme.spacingLarge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar + badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const CircleAvatar(
                    radius: 56,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/200?img=1',
                    ),
                    backgroundColor: AsteriaTheme.accentColor,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AsteriaTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: AsteriaTheme.shadowDark,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: AsteriaTheme.accentColor,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AsteriaTheme.spacingMedium),
              Text('You', style: Theme.of(context).textTheme.titleLarge),

              const SizedBox(height: AsteriaTheme.spacingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _iconPill(
                    context,
                    icon: Icons.settings_rounded,
                    onPressed: () => _showSettingsDialog(context),
                  ),
                  const SizedBox(width: AsteriaTheme.spacingLarge),
                  _iconPill(
                    context,
                    icon: Icons.share_outlined,
                    onPressed: () {},
                  ),
                ],
              ),

              const SizedBox(height: AsteriaTheme.spacingLarge),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AsteriaTheme.spacingLarge,
                ),
                child: Text(
                  'Passionate about Technology and Gaming!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AsteriaTheme.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: AsteriaTheme.spacingLarge),
              const Divider(height: 1),
              const SizedBox(height: AsteriaTheme.spacingLarge),

              // Section header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'INTERESTS',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AsteriaTheme.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: AsteriaTheme.spacingMedium),

              SizedBox(
                height: 260,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: interests.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AsteriaTheme.spacingLarge),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AsteriaTheme.spacingLarge,
                  ),
                  itemBuilder: (context, i) {
                    final it = interests[i];
                    return _interestCard(context, it);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _iconPill(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AsteriaTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(AsteriaTheme.radiusLarge),
        boxShadow: const [
          BoxShadow(color: AsteriaTheme.shadowLight, blurRadius: 6),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AsteriaTheme.textPrimary),
        onPressed: onPressed,
      ),
    );
  }

  static Widget _interestCard(BuildContext context, _Interest interest) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(AsteriaTheme.spacingXLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(interest.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: AsteriaTheme.spacingXLarge),
          Text(
            interest.name,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AsteriaTheme.accentColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

void _showSettingsDialog(BuildContext context) {
  Color selectedColor = const Color(0xFF8E5BFF); // default purple
  bool darkMode = ThemeController.instance.mode == ThemeMode.dark;
  final TextEditingController nameCtrl = TextEditingController(text: 'You');

  final List<Color> palette = [
    const Color(0xFFE74C3C), // red
    const Color(0xFFF39C12), // orange
    const Color(0xFFF1C40F), // yellow
    const Color(0xFF2ECC71), // green
    const Color(0xFF3498DB), // blue
    const Color(0xFF8E5BFF), // purple
    const Color(0xFFE91E63), // pink
    const Color(0xFFF06292), // pink light
    const Color(0xFFF39C12), // orange alt
    const Color(0xFF8BC34A), // lime
    const Color(0xFF00BCD4), // cyan
    const Color(0xFF5B6BFF), // indigo
  ];

  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return Dialog(
            elevation: AsteriaTheme.elevationXHigh,
            insetPadding: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AsteriaTheme.radiusLarge),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AsteriaTheme.spacingXLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Settings',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: AsteriaTheme.spacingLarge),
                  Text(
                    'Profile Picture',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AsteriaTheme.spacingSmall),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/200?img=1',
                        ),
                        backgroundColor: AsteriaTheme.accentColor,
                      ),
                      const SizedBox(width: AsteriaTheme.spacingLarge),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Upload coming soon')),
                          );
                        },
                        icon: const Icon(Icons.upload_rounded),
                        label: const Text('Upload'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AsteriaTheme.backgroundSecondary,
                          foregroundColor: AsteriaTheme.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AsteriaTheme.radiusLarge,
                            ),
                            side: const BorderSide(
                              color: AsteriaTheme.textSecondary,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AsteriaTheme.spacingLarge),
                  Text('Name', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AsteriaTheme.spacingSmall),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AsteriaTheme.backgroundSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AsteriaTheme.radiusLarge,
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: AsteriaTheme.spacingLarge),
                  Text(
                    'Star Color',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AsteriaTheme.spacingSmall),
                  Wrap(
                    spacing: AsteriaTheme.spacingLarge,
                    runSpacing: AsteriaTheme.spacingLarge,
                    children: [
                      for (final color in palette)
                        GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: selectedColor == color
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AsteriaTheme.shadowMedium,
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: AsteriaTheme.spacingLarge),
                  Row(
                    children: [
                      const Icon(
                        Icons.wb_sunny_outlined,
                        color: AsteriaTheme.textSecondary,
                      ),
                      const SizedBox(width: AsteriaTheme.spacingSmall),
                      Text(
                        'Dark Mode',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Switch(
                        value: darkMode,
                        onChanged: (v) => setState(() {
                          darkMode = v;
                          ThemeController.instance.setMode(
                            v ? ThemeMode.dark : ThemeMode.light,
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _Interest {
  final String name;
  final String emoji;
  const _Interest({required this.name, required this.emoji});
}
