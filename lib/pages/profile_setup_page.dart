import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../theme.dart';
import 'root_nav_page.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController _nameCtrl = TextEditingController();
  Color _selectedColor = const Color(0xFF8E5BFF);
  Uint8List? _avatarBytes;
  String? _avatarContentType;
  bool _saving = false;

  final List<Color> _palette = const [
    Color(0xFFE74C3C),
    Color(0xFFF39C12),
    Color(0xFFF1C40F),
    Color(0xFF2ECC71),
    Color(0xFF3498DB),
    Color(0xFF8E5BFF),
    Color(0xFFE91E63),
    Color(0xFFF06292),
    Color(0xFF8BC34A),
    Color(0xFF00BCD4),
    Color(0xFF5B6BFF),
  ];

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _nameCtrl.text =
        user?.userMetadata?['name'] ?? user?.email?.split('@').first ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _avatarBytes = bytes;
      _avatarContentType = _inferContentType(file.path, bytes);
    });
  }

  String _inferContentType(String path, Uint8List bytes) {
    // Lightweight inference; precise type chosen server-side if needed
    if (path.toLowerCase().endsWith('.png')) return 'image/png';
    if (path.toLowerCase().endsWith('.webp')) return 'image/webp';
    if (path.toLowerCase().endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  String _colorToHex(Color c) {
    final r = ((c.r * 255.0).round() & 0xff);
    final g = ((c.g * 255.0).round() & 0xff);
    final b = ((c.b * 255.0).round() & 0xff);
    return '#'
        '${r.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${g.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }

  bool get _isValid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _avatarBytes != null &&
      RegExp(
        r'^#(?:[0-9A-Fa-f]{3}){1,2}$',
      ).hasMatch(_colorToHex(_selectedColor));

  Future<void> _onSave() async {
    if (!_isValid || _saving) return;
    setState(() => _saving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      String? avatarPath;
      if (_avatarBytes != null) {
        avatarPath = await ProfileService.uploadAvatarFromBytes(
          userId: user.id,
          bytes: _avatarBytes!,
          contentType: _avatarContentType,
        );
      }
      await ProfileService.upsertProfile(
        userId: user.id,
        fullName: _nameCtrl.text.trim(),
        starColor: _colorToHex(_selectedColor),
        avatarPath: avatarPath,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootNavPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete your profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AsteriaTheme.spacingXLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile picture',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: _avatarBytes != null
                        ? MemoryImage(_avatarBytes!)
                        : null,
                    child: _avatarBytes == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text('Choose image'),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Text(
                'Display name',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                maxLength: 100,
                decoration: const InputDecoration(hintText: 'Your name'),
              ),

              const SizedBox(height: 8),
              Text(
                'Star color',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final color in _palette)
                    GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == color
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isValid && !_saving ? _onSave : null,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
