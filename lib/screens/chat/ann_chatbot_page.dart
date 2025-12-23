import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:rive_animation/constants.dart';

class AnnChatbotPage extends StatefulWidget {
  const AnnChatbotPage({super.key, this.showAppBar = true});
  final bool showAppBar;

  @override
  State<AnnChatbotPage> createState() => _AnnChatbotPageState();
}

class _AnnChatbotPageState extends State<AnnChatbotPage> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  PlatformFile? _pendingAttachment;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToBottom() async {
    if (!_scrollController.hasClients) return;
    await Future.delayed(const Duration(milliseconds: 50));
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const [
        'png',
        'jpg',
        'jpeg',
        'webp',
        'gif',
        'pdf',
        'txt',
        'doc',
        'docx',
        'ppt',
        'pptx',
        'xls',
        'xlsx',
      ],
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _pendingAttachment = result.files.first;
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingAttachment == null) return;
    final attachment = _pendingAttachment;
    setState(() {
      _messages.add(
        _ChatMessage(
          role: _ChatRole.user,
          text: text,
          attachment: attachment,
        ),
      );
      _controller.clear();
      _pendingAttachment = null;
    });
    unawaited(_scrollToBottom());
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 500)).then((_) {
        if (!mounted) return;
        setState(() {
          _messages.add(
            _ChatMessage(
              role: _ChatRole.assistant,
              text: "ANN bot: I received your message.",
            ),
          );
        });
        unawaited(_scrollToBottom());
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: backgroundColor2,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: backgroundColor2,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              foregroundColor: Colors.white,
              title: Text(
                "ANN Chat",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(15),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(26),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 44,
                                      width: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(26),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.chat_bubble_outline,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        "Start chatting with ANN. You can also attach an image or document.",
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return _ChatBubble(message: msg);
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _Composer(
                controller: _controller,
                pendingAttachment: _pendingAttachment,
                onPickAttachment: _pickAttachment,
                onRemoveAttachment: () {
                  setState(() {
                    _pendingAttachment = null;
                  });
                },
                onSend: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ChatRole { user, assistant }

class _ChatMessage {
  _ChatMessage({required this.role, required this.text, this.attachment});
  final _ChatRole role;
  final String text;
  final PlatformFile? attachment;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final _ChatMessage message;
  bool get _isUser => message.role == _ChatRole.user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor =
        _isUser ? const Color(0xFF6792FF) : Colors.white.withAlpha(20);
    final borderColor =
        _isUser ? Colors.white.withAlpha(0) : Colors.white.withAlpha(31);
    final textColor = Colors.white;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(_isUser ? 18 : 6),
      bottomRight: Radius.circular(_isUser ? 6 : 18),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!_isUser) ...[
            _Avatar(
                label: message.role == _ChatRole.assistant ? "AI" : ""),
            const SizedBox(width: 10),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: radius,
                border: Border.all(color: borderColor),
              ),
              child: DefaultTextStyle(
                style: theme.textTheme.bodyMedium!.copyWith(color: textColor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.attachment != null)
                      _AttachmentInlineView(file: message.attachment!),
                    if (message.text.isNotEmpty)
                      Text(
                        message.text,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_isUser) ...[
            const SizedBox(width: 10),
            const _Avatar(label: "You"),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(36)),
      ),
      alignment: Alignment.center,
      child: Text(
        label.substring(0, label.length >= 2 ? 2 : label.length),
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.pendingAttachment,
    required this.onPickAttachment,
    required this.onRemoveAttachment,
    required this.onSend,
  });
  final TextEditingController controller;
  final PlatformFile? pendingAttachment;
  final VoidCallback onPickAttachment;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pendingAttachment != null) ...[
            _AttachmentPreviewRow(
              file: pendingAttachment!,
              onRemove: onRemoveAttachment,
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              IconButton(
                onPressed: onPickAttachment,
                icon: const Icon(Icons.attach_file),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withAlpha(26),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withAlpha(20),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onSend,
                icon: const Icon(Icons.send_rounded),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF6792FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentPreviewRow extends StatelessWidget {
  const _AttachmentPreviewRow({required this.file, required this.onRemove});
  final PlatformFile file;
  final VoidCallback onRemove;

  bool get _isImage {
    final ext = (file.extension ?? '').toLowerCase();
    return ext == 'png' ||
        ext == 'jpg' ||
        ext == 'jpeg' ||
        ext == 'webp' ||
        ext == 'gif';
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = file.bytes;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: Row(
        children: [
          if (_isImage && bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                bytes,
                height: 42,
                width: 42,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.insert_drive_file, color: Colors.white),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close),
            color: Colors.white70,
          ),
        ],
      ),
    );
  }
}

class _AttachmentInlineView extends StatelessWidget {
  const _AttachmentInlineView({required this.file});
  final PlatformFile file;

  bool get _isImage {
    final ext = (file.extension ?? '').toLowerCase();
    return ext == 'png' ||
        ext == 'jpg' ||
        ext == 'jpeg' ||
        ext == 'webp' ||
        ext == 'gif';
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = file.bytes;
    if (_isImage && bytes != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            bytes,
            height: 160,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}