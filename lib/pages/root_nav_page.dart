import 'package:flutter/material.dart';
import '../theme.dart';
import 'messages_page.dart';
import 'star_map_page.dart';
import 'profile_page.dart';

class RootNavPage extends StatefulWidget {
  const RootNavPage({super.key});

  @override
  State<RootNavPage> createState() => _RootNavPageState();
}

class _RootNavPageState extends State<RootNavPage> {
  int _currentIndex = 0;

  // Desired order: Home (Star Map), Messages, Profile
  final List<Widget> _pages = const [
    StarMapPage(),
    MessagesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(
            horizontal: AsteriaTheme.spacingMedium,
            vertical: AsteriaTheme.spacingSmall,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(
                context,
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
              ),
              _buildNavItem(
                context,
                index: 1,
                icon: Icons.chat_bubble_rounded,
                label: 'Messages',
              ),
              _buildNavItem(
                context,
                index: 2,
                icon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool selected = _currentIndex == index;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color selectedBg = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF1F1F3);
    final Color iconColor = selected
        ? (isDark ? Colors.white : AsteriaTheme.textPrimary)
        : AsteriaTheme.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Center(
          child: AnimatedContainer(
            duration: AsteriaTheme.animationMedium,
            curve: AsteriaTheme.curveElegant,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 26, color: iconColor),
          ),
        ),
      ),
    );
  }
}
