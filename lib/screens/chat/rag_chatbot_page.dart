import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:rive_animation/constants.dart';
import 'package:rive_animation/ml/rag_service.dart';

/// Available RAG models for selection
enum RagModel {
  llama2('LLAMA-2', 'llama-2'),
  gpt4('GPT-4', 'gpt-4'),
  huggingface('Hugging Face', 'huggingface');

  const RagModel(this.displayName, this.apiValue);
  final String displayName;
  final String apiValue;
}

class RagChatbotPage extends StatefulWidget {
  const RagChatbotPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<RagChatbotPage> createState() => _RagChatbotPageState();
}

class _RagChatbotPageState extends State<RagChatbotPage> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final RagService _ragService = RagService();

  PlatformFile? _pendingAttachment;
  RagModel _selectedModel = RagModel.llama2;
  bool _isProcessing = false;

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

  /// Pick a document/file to upload
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

  /// Main send function: handles document upload + prompt sending
  /// 
  /// Flow:
  /// 1. If document is attached, upload it first
  /// 2. Then send the prompt with selected model
  /// 3. Display responses in chat
  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingAttachment == null) return;
    if (_isProcessing) return;

    final attachment = _pendingAttachment;
    final prompt = text;
    final model = _selectedModel;

    // Add user message to chat
    setState(() {
      _messages.add(
        _ChatMessage(
          role: _ChatRole.user,
          text: prompt.isEmpty ? 'Uploading document...' : prompt,
          attachment: attachment,
        ),
      );
      _controller.clear();
      _pendingAttachment = null;
      _isProcessing = true;
    });
    unawaited(_scrollToBottom());

    try {
      // Step 1: Upload document if one is attached
      if (attachment != null) {
        await _uploadDocument(attachment);
      }

      // Step 2: Send prompt if provided
      if (prompt.isNotEmpty) {
        await _sendPrompt(prompt, model);
      } else if (attachment != null) {
        // If only document was uploaded, show success message
        if (mounted) {
          setState(() {
            _messages.add(
              _ChatMessage(
                role: _ChatRole.assistant,
                text: '✅ Document uploaded successfully! You can now ask questions about it.',
              ),
            );
            _isProcessing = false;
          });
          unawaited(_scrollToBottom());
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            role: _ChatRole.assistant,
            text: '❌ Error: $e',
            isError: true,
          ),
        );
        _isProcessing = false;
      });
      unawaited(_scrollToBottom());
    }
  }

  /// Upload document to FastAPI backend
  Future<void> _uploadDocument(PlatformFile file) async {
    // Show uploading message
    if (mounted) {
      setState(() {
        _messages.add(
          _ChatMessage(
            role: _ChatRole.assistant,
            text: '📤 Uploading document...',
            isLoading: true,
          ),
        );
      });
      unawaited(_scrollToBottom());
    }

    try {
      final result = await _ragService.uploadDocument(file);

      // Remove loading message
      if (mounted) {
        setState(() {
          if (_messages.isNotEmpty && _messages.last.isLoading) {
            _messages.removeLast();
          }
        });
      }

      // Show success (will be replaced by prompt response if prompt exists)
      if (mounted && _controller.text.trim().isEmpty) {
        setState(() {
          _messages.add(
            _ChatMessage(
              role: _ChatRole.assistant,
              text: '✅ Document uploaded and indexed successfully!',
            ),
          );
        });
        unawaited(_scrollToBottom());
      }
    } catch (e) {
      // Remove loading message
      if (mounted) {
        setState(() {
          if (_messages.isNotEmpty && _messages.last.isLoading) {
            _messages.removeLast();
          }
        });
      }
      throw Exception('Document upload failed: $e');
    }
  }

  /// Send prompt/question to FastAPI RAG endpoint
  Future<void> _sendPrompt(String prompt, RagModel model) async {
    // Show processing message
    if (mounted) {
      setState(() {
        // Remove any existing loading messages
        if (_messages.isNotEmpty && _messages.last.isLoading) {
          _messages.removeLast();
        }
        _messages.add(
          _ChatMessage(
            role: _ChatRole.assistant,
            text: '🤔 Processing with ${model.displayName}...',
            isLoading: true,
          ),
        );
      });
      unawaited(_scrollToBottom());
    }

    try {
      final result = await _ragService.askQuestion(
        prompt: prompt,
        model: model.apiValue,
      );

      // Remove loading message
      if (mounted) {
        setState(() {
          if (_messages.isNotEmpty && _messages.last.isLoading) {
            _messages.removeLast();
          }
        });
      }

      // Extract response from FastAPI result
      // Adjust these keys based on your FastAPI response structure
      final responseText = result['response'] as String? ??
          result['answer'] as String? ??
          result['message'] as String? ??
          result.toString();

      // Add assistant response to chat
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              role: _ChatRole.assistant,
              text: responseText,
            ),
          );
          _isProcessing = false;
        });
        unawaited(_scrollToBottom());
      }
    } catch (e) {
      // Remove loading message
      if (mounted) {
        setState(() {
          if (_messages.isNotEmpty && _messages.last.isLoading) {
            _messages.removeLast();
          }
        });
      }
      throw Exception('Failed to get response: $e');
    }
  }

  /// Reset RAG session
  Future<void> _resetSession() async {
    try {
      await _ragService.resetSession();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session reset successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                "RAG Chat",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reset Session',
                  onPressed: _resetSession,
                ),
              ],
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
                                        "Start chatting with RAG. Upload a document and ask questions about it. Select a model from the dropdown.",
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
                selectedModel: _selectedModel,
                isProcessing: _isProcessing,
                onModelChanged: (model) {
                  setState(() {
                    _selectedModel = model;
                  });
                },
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
  _ChatMessage({
    required this.role,
    required this.text,
    this.attachment,
    this.isLoading = false,
    this.isError = false,
  });

  final _ChatRole role;
  final String text;
  final PlatformFile? attachment;
  final bool isLoading;
  final bool isError;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  bool get _isUser => message.role == _ChatRole.user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bubbleColor = _isUser
        ? const Color(0xFF6792FF)
        : Colors.white.withAlpha(20);
    final borderColor = _isUser
        ? Colors.white.withAlpha(0)
        : Colors.white.withAlpha(31);
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
            _Avatar(label: message.role == _ChatRole.assistant ? "AI" : ""),
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
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: message.isError ? Colors.red.shade300 : textColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.attachment != null)
                      _AttachmentInlineView(file: message.attachment!),
                    if (message.isLoading)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Processing...'),
                        ],
                      )
                    else if (message.text.isNotEmpty)
                      SelectableText(
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

/// Enhanced Composer widget with model selection dropdown
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.pendingAttachment,
    required this.selectedModel,
    required this.isProcessing,
    required this.onModelChanged,
    required this.onPickAttachment,
    required this.onRemoveAttachment,
    required this.onSend,
  });

  final TextEditingController controller;
  final PlatformFile? pendingAttachment;
  final RagModel selectedModel;
  final bool isProcessing;
  final ValueChanged<RagModel> onModelChanged;
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
          // Model selection dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Model:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<RagModel>(
                      value: selectedModel,
                      isExpanded: true,
                      dropdownColor: backgroundColor2,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                      items: RagModel.values.map((model) {
                        return DropdownMenuItem<RagModel>(
                          value: model,
                          child: Text(model.displayName),
                        );
                      }).toList(),
                      onChanged: isProcessing
                          ? null
                          : (value) {
                            if (value != null) {
                              onModelChanged(value);
                            }
                          },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Attachment preview
          if (pendingAttachment != null) ...[
            _AttachmentPreviewRow(
              file: pendingAttachment!,
              onRemove: onRemoveAttachment,
            ),
            const SizedBox(height: 10),
          ],
          // Input row
          Row(
            children: [
              IconButton(
                onPressed: isProcessing ? null : onPickAttachment,
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
                  enabled: !isProcessing,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: isProcessing ? null : (_) => onSend(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message or question...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white54,
                    ),
                    filled: true,
                    fillColor: Colors.white.withAlpha(20),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: isProcessing ? null : onSend,
                icon: isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
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
