import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/utils/enums.dart';
import 'package:punto_venta_app/features/support_chat/data/models/support_message_model.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/chat_bubble_image.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/chat_bubble_timestamp.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/chat_bubble_audio.dart';

class MessageBubbleSender extends StatelessWidget {
  const MessageBubbleSender({super.key, required this.message});

  final SupportMessageModel message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.hasMedia && message.isImageKind)
                ChatBubbleImage(
                  imageUrl: message.mediaThumbUrl ?? message.mediaUrl,
                  fullImageUrl: message.mediaUrl,
                  caption: message.mediaCaption,
                  overlay: (message.body == null || message.body!.isEmpty) &&
                          (message.mediaCaption == null || message.mediaCaption!.isEmpty)
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ChatBubbleTimestamp(
                              sentAt: message.sentAt,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 4),
                            _StatusIcon(
                              status: message.messageStatus,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ],
                        )
                      : null,
                ),
              if (message.hasMedia && message.isAudioKind)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ChatBubbleAudio(
                    audioUrl: message.mediaUrl,
                    fileName: message.mediaName,
                    fileSizeBytes: message.mediaSizeBytes,
                    isOutbound: true,
                  ),
                ),
              if ((message.body == null || message.body!.isEmpty) &&
                  (message.mediaCaption == null || message.mediaCaption!.isEmpty) &&
                  (!message.hasMedia || !message.isImageKind))
                const SizedBox.shrink()
              else if (message.body != null && message.body!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    top: (message.hasMedia && message.isImageKind) ? 6 : 0,
                  ),
                  child: Text(
                    message.body!,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              if (!((message.hasMedia && message.isImageKind) &&
                  (message.body == null || message.body!.isEmpty) &&
                  (message.mediaCaption == null || message.mediaCaption!.isEmpty))) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChatBubbleTimestamp(
                      sentAt: message.sentAt,
                      color: colorScheme.onPrimary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    _StatusIcon(status: message.messageStatus),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, this.color});

  final MessageStatus? status;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ??
        Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7);
    return switch (status) {
      MessageStatus.sending =>
        Icon(Icons.access_time_rounded, size: 13, color: defaultColor),
      MessageStatus.sent =>
        Icon(Icons.done_rounded, size: 13, color: defaultColor),
      MessageStatus.delivered ||
      MessageStatus.received =>
        Icon(Icons.done_all_rounded, size: 13, color: defaultColor),
      MessageStatus.read =>
        const Icon(Icons.done_all_rounded, size: 13, color: Color(0xFF34B7F1)),
      MessageStatus.error =>
        const Icon(Icons.error_outline_rounded, size: 13, color: Colors.red),
      null => const SizedBox.shrink(),
    };
  }
}
