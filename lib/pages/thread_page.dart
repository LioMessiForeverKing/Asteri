import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/chat_service.dart';

class ThreadPage extends StatefulWidget {
  final String conversationId;
  final String title;
  const ThreadPage({super.key, required this.conversationId, required this.title});

  @override
  State<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  List<ChatMessage> _messages = const [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await ChatService.fetchMessages(widget.conversationId, limit: 100);
    if (!mounted) return;
    setState(() => _messages = m);
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if ((text.isEmpty && _selectedImageBytes == null) || _sending) return;
    setState(() => _sending = true);
    try {
      await ChatService.sendMessage(
        widget.conversationId,
        text: text.isEmpty ? null : text,
        imageBytes: _selectedImageBytes,
        imageFileName: _selectedImageFileName,
      );
      _input.clear();
      setState(() {
        _selectedImageBytes = null;
        _selectedImageFileName = null;
      });
      await _load();
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
  
  Uint8List? _selectedImageBytes;
  String? _selectedImageFileName;
  
  Future<void> _pickImage() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (file == null) return;
      
      final bytes = await file.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageFileName = file.name;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              reverse: true,
              padding: const EdgeInsets.symmetric(
                horizontal: AsteriaTheme.spacingLarge,
                vertical: AsteriaTheme.spacingLarge,
              ),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final hasImage = msg.imageUrl != null && msg.imageUrl!.isNotEmpty;
                final hasText = msg.content != null && msg.content!.isNotEmpty;
                
                // Get image URL (convert storage path if needed)
                String? imageUrl;
                if (hasImage) {
                  final imagePath = msg.imageUrl!;
                  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
                    imageUrl = imagePath;
                  } else {
                    imageUrl = ChatService.getPublicMessageImageUrl(imagePath);
                  }
                }
                
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: EdgeInsets.all(hasImage && !hasText ? 0 : 12),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF1F1F3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasImage)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image, size: 48),
                                );
                              },
                            ),
                          ),
                        if (hasText && hasImage) const SizedBox(height: 8),
                        if (hasText)
                          Text(
                            msg.content!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AsteriaTheme.spacingMedium),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedImageBytes != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      height: 120,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _selectedImageBytes!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              color: Colors.white,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                padding: const EdgeInsets.all(4),
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedImageBytes = null;
                                  _selectedImageFileName = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _sending ? null : _pickImage,
                        icon: const Icon(Icons.image_rounded),
                        tooltip: 'Add photo',
                      ),
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: _selectedImageBytes != null ? 'Add a caption...' : 'Message...',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _sending ? null : _send,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


