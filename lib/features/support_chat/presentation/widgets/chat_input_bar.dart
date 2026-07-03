import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.onPickImage,
    this.hasImage = false,
    this.enabled = true,
  });

  final ValueChanged<String> onSend;
  final VoidCallback onPickImage;
  final bool hasImage;
  final bool enabled;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;
  late final FocusNode _focusNode = FocusNode(
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent) {
        final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter;
        if (isEnter) {
          final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
          if (isShiftPressed) {
            return KeyEventResult.ignored;
          } else {
            _send();
            return KeyEventResult.handled;
          }
        }
      }
      return KeyEventResult.ignored;
    },
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty && !widget.hasImage) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canSend = (_hasText || widget.hasImage) && widget.enabled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attach image button
          IconButton(
            onPressed: widget.enabled ? widget.onPickImage : null,
            icon: Icon(
              Icons.attach_file_rounded,
              color: widget.enabled
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            tooltip: 'Adjuntar imagen',
          ),

          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Send button
          GestureDetector(
            onTap: canSend ? _send : null,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: canSend
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                color: canSend
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface.withValues(alpha: 0.26),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
