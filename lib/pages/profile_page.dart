import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme.dart';
import '../widgets/passion_graph.dart';
import '../models/passion_graph.dart';
import '../services/youtube_service.dart';
import '../services/openai_service.dart';
import 'dart:math' as math;
import '../services/theme_controller.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<({String name, String? avatarUrl, String starHex})> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return (name: 'You', avatarUrl: null, starHex: '#8E5BFF');
    final p = await ProfileService.getProfile(uid);
    if (p == null) return (name: 'You', avatarUrl: null, starHex: '#8E5BFF');
    final url = (p.avatarUrl == null || p.avatarUrl!.isEmpty)
        ? null
        : ProfileService.getPublicAvatarUrl(p.avatarUrl!);
    return (name: p.fullName, avatarUrl: url, starHex: p.starColor);
  }

  Color _parseHex(String hex) {
    var v = hex.trim();
    if (v.startsWith('#')) v = v.substring(1);
    if (v.length == 3) v = v.split('').map((c) => '$c$c').join();
    final intColor = int.tryParse(v, radix: 16) ?? 0x8E5BFF;
    return Color(0xFF000000 | intColor);
  }

  Future<GraphSnapshot> _loadGraph() async {
    final subs = await YouTubeService.fetchAllSubscriptions(pageSize: 50);
    final likes = await YouTubeService.fetchAllLikedVideos(
      pageSize: 50,
      maxItems: 100,
    );
    GraphSnapshot snapshot = await OpenAIService.summarizePassions(
      subscriptions: subs,
      likedVideos: likes,
    );
    return _dedupeGraph(snapshot);
  }

  GraphSnapshot _dedupeGraph(GraphSnapshot snapshot) {
    final Map<String, PassionNode> byLabel = <String, PassionNode>{};
    for (final node in snapshot.nodes) {
      final String key = node.label.trim().toLowerCase();
      final PassionNode? existing = byLabel[key];
      if (existing == null || node.weight > existing.weight) {
        byLabel[key] = node;
      }
    }
    // Keep strongest topics first and cap to a reasonable count for clarity
    final List<PassionNode> nodes = byLabel.values.toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
    if (nodes.length > 24) nodes.removeRange(24, nodes.length);
    final Set<String> validIds = nodes.map((n) => n.id).toSet();
    final List<GraphEdge> edges = snapshot.edges
        .where(
          (e) =>
              validIds.contains(e.sourceId) &&
              validIds.contains(e.targetId) &&
              e.sourceId != e.targetId,
        )
        .toList();
    // Seed a clean circular layout if nodes are unpositioned
    final int n = nodes.length;
    if (n > 0) {
      for (int i = 0; i < n; i++) {
        final double angle = (i / n) * 6.28318530718; // 2*pi
        final double radius = 120 + 40 * nodes[i].weight; // emphasize strong nodes
        nodes[i].x = radius * math.cos(angle);
        nodes[i].y = radius * math.sin(angle);
      }
    }
    return GraphSnapshot(nodes: nodes, edges: edges);
  }

  @override
  Widget build(BuildContext context) {
    // Interests list removed; we now show the interactive interest graph instead

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child:
            FutureBuilder<({String name, String? avatarUrl, String starHex})>(
              future: _load(),
              builder: (context, snap) {
                final name = snap.data?.name ?? 'You';
                final avatarUrl = snap.data?.avatarUrl;
                final starColor = _parseHex(snap.data?.starHex ?? '#8E5BFF');

                return SingleChildScrollView(
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
                          CircleAvatar(
                            radius: 56,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
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
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/Logos/star.svg',
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.contain,
                                  colorFilter: ColorFilter.mode(
                                    starColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AsteriaTheme.spacingMedium),
                      Text(name, style: Theme.of(context).textTheme.titleLarge),

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
                      Divider(
                        height: 1,
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: AsteriaTheme.spacingLarge),

                      // Interest Graph section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'YOUR INTEREST GRAPH',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ),

                      const SizedBox(height: AsteriaTheme.spacingMedium),

                      Container(
                        height: 360,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: FutureBuilder<GraphSnapshot>(
                            future: _loadGraph(),
                            builder: (context, graphSnap) {
                              if (graphSnap.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final snap = graphSnap.data;
                              if (snap == null || snap.nodes.isEmpty) {
                                return Center(
                                  child: Text(
                                    'We\'ll show your interest graph here',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                );
                              }
                              return PassionGraph(snapshot: snap);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AsteriaTheme.radiusLarge),
        boxShadow: const [
          BoxShadow(color: AsteriaTheme.shadowLight, blurRadius: 6),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
        onPressed: onPressed,
      ),
    );
  }

  // Old interests list UI removed
}

void _showSettingsDialog(BuildContext context) {
  Color selectedColor = const Color(0xFF8E5BFF);
  bool darkMode = ThemeController.instance.mode == ThemeMode.dark;
  final TextEditingController nameCtrl = TextEditingController(text: '');
  String? avatarUrl; // public URL for preview
  String? uploadedObjectPath; // storage object path after upload
  bool saving = false;

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
          Color parseHexLocal(String hex) {
            var v = hex.trim();
            if (v.startsWith('#')) v = v.substring(1);
            if (v.length == 3) v = v.split('').map((c) => '$c$c').join();
            final intColor = int.tryParse(v, radix: 16) ?? 0x8E5BFF;
            return Color(0xFF000000 | intColor);
          }

          String colorToHexLocal(Color c) {
            final r = ((c.r * 255.0).round() & 0xff);
            final g = ((c.g * 255.0).round() & 0xff);
            final b = ((c.b * 255.0).round() & 0xff);
            return '#'
                '${r.toRadixString(16).padLeft(2, '0').toUpperCase()}'
                '${g.toRadixString(16).padLeft(2, '0').toUpperCase()}'
                '${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';
          }

          // Lazy-load current profile once when dialog opens
          Future<void>.microtask(() async {
            if (nameCtrl.text.isNotEmpty) return; // already loaded
            final uid = Supabase.instance.client.auth.currentUser?.id;
            if (uid == null) return;
            final p = await ProfileService.getProfile(uid);
            if (p != null) {
              nameCtrl.text = p.fullName;
              selectedColor = parseHexLocal(p.starColor);
              if (p.avatarUrl != null && p.avatarUrl!.isNotEmpty) {
                avatarUrl = ProfileService.getPublicAvatarUrl(p.avatarUrl!);
              }
              setState(() {});
            }
          });

          return Dialog(
            elevation: AsteriaTheme.elevationXHigh,
            insetPadding: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AsteriaTheme.radiusLarge),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AsteriaTheme.spacingXLarge),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
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
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl!)
                                : null,
                            backgroundColor: AsteriaTheme.accentColor,
                            child: avatarUrl == null
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: AsteriaTheme.spacingLarge),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final file = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1024,
                                imageQuality: 85,
                              );
                              if (file == null) return;
                              final bytes = await file.readAsBytes();
                              final uid =
                                  Supabase.instance.client.auth.currentUser?.id;
                              if (uid == null) return;
                              setState(() => saving = true);
                              try {
                                final path =
                                    await ProfileService.uploadAvatarFromBytes(
                                      userId: uid,
                                      bytes: Uint8List.fromList(bytes),
                                    );
                                uploadedObjectPath = path;
                                avatarUrl = ProfileService.getPublicAvatarUrl(
                                  path,
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Avatar upload failed: $e'),
                                    ),
                                  );
                                }
                              } finally {
                                setState(() => saving = false);
                              }
                            },
                            icon: const Icon(Icons.upload_rounded),
                            label: const Text('Upload'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AsteriaTheme.radiusLarge,
                                ),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AsteriaTheme.spacingLarge),
                      Text(
                        'Name',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AsteriaTheme.spacingSmall),
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
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
                              onTap: () =>
                                  setState(() => selectedColor = color),
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
                          Icon(
                            Icons.wb_sunny_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
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

                      const SizedBox(height: AsteriaTheme.spacingLarge),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final uid = Supabase
                                      .instance
                                      .client
                                      .auth
                                      .currentUser
                                      ?.id;
                                  if (uid == null) return;
                                  setState(() => saving = true);
                                  try {
                                    await ProfileService.upsertProfile(
                                      userId: uid,
                                      fullName: nameCtrl.text.trim(),
                                      starColor: colorToHexLocal(selectedColor),
                                      avatarPath: uploadedObjectPath,
                                    );
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Save failed: ${e.toString()}',
                                          ),
                                        ),
                                      );
                                    }
                                  } finally {
                                    setState(() => saving = false);
                                  }
                                },
                          child: saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// Removed legacy _Interest model
