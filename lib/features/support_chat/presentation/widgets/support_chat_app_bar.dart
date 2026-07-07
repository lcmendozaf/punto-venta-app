import 'package:flutter/material.dart';

class SupportChatAppBar extends StatelessWidget {
  final void Function(DragUpdateDetails) onDragUpdate;
  final VoidCallback onMinimize;

  const SupportChatAppBar({
    super.key,
    required this.onDragUpdate,
    required this.onMinimize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onPanUpdate: onDragUpdate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.7),
              child: Icon(
                Icons.support_agent_rounded,
                size: 18,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Soporte Técnico',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'En línea',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onMinimize,
              icon: Icon(
                Icons.minimize_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 20,
              ),
              tooltip: 'Minimizar',
            ),
          ],
        ),
      ),
    );
  }
}
