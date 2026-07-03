import 'package:flutter/material.dart';
import 'package:punto_venta_app/features/support_chat/data/models/support_message_model.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/message_bubble_receiver.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/message_bubble_sender.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    super.key,
    required this.messages,
    this.controller,
    this.isLoading = false,
  });

  final List<SupportMessageModel> messages;
  final ScrollController? controller;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty) {
      return _EmptyChat();
    }

    return ListView.builder(
      controller: controller,
      reverse: true,
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final showDateSeparator = _shouldShowDateSeparator(index);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDateSeparator) _DateSeparator(sentAt: message.sentAt),
            message.isFromUser
                ? MessageBubbleSender(message: message)
                : MessageBubbleReceiver(message: message),
          ],
        );
      },
    );
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == messages.length - 1) return true;

    final current = messages[index].sentAt;
    final next = messages[index + 1].sentAt;

    if (current == null || next == null) return false;

    try {
      final d1 = DateTime.parse(current).toLocal();
      final d2 = DateTime.parse(next).toLocal();
      return d1.day != d2.day || d1.month != d2.month || d1.year != d2.year;
    } catch (_) {
      return false;
    }
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.sentAt});

  final String? sentAt;

  String _label() {
    if (sentAt == null) return '';
    try {
      final dt = DateTime.parse(sentAt!).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return 'Hoy';
      }
      final yesterday = now.subtract(const Duration(days: 1));
      if (dt.year == yesterday.year &&
          dt.month == yesterday.month &&
          dt.day == yesterday.day) {
        return 'Ayer';
      }
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _label();
    if (label.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 56, color: color),
          const SizedBox(height: 12),
          Text(
            'Sin mensajes aún',
            style: TextStyle(fontSize: 15, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            'Envía un mensaje para contactar con soporte',
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}
