import 'package:flutter/material.dart';
import 'package:punto_venta_app/features/support_chat/data/models/support_message_model.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/chat_bubble_image.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/chat_bubble_timestamp.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/chat_bubble_audio.dart';

class MessageBubbleReceiver extends StatelessWidget {
  const MessageBubbleReceiver({super.key, required this.message});

  final SupportMessageModel message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bubbleColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0);
    final textColor = isDark ? Colors.white : Colors.black87;
    final nameColor = theme.colorScheme.primary;
    final timeColor =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.45);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.sentByDisplayName != null &&
                  message.sentByDisplayName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.sentByDisplayName!,
                    style: TextStyle(
                      color: nameColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              if (message.hasMedia && message.isImageKind)
                ChatBubbleImage(
                  imageUrl: message.mediaThumbUrl ?? message.mediaUrl,
                  fullImageUrl: message.mediaUrl,
                  caption: message.mediaCaption,
                  overlay: (message.body == null || message.body!.isEmpty) &&
                          (message.mediaCaption == null || message.mediaCaption!.isEmpty)
                      ? ChatBubbleTimestamp(
                          sentAt: message.sentAt,
                          color: Colors.white.withValues(alpha: 0.9),
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
                    isOutbound: false,
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
                      color: textColor,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              if (!((message.hasMedia && message.isImageKind) &&
                  (message.body == null || message.body!.isEmpty) &&
                  (message.mediaCaption == null || message.mediaCaption!.isEmpty))) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: ChatBubbleTimestamp(
                    sentAt: message.sentAt,
                    color: timeColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
