import 'dart:io';
import 'package:flutter/material.dart';

class ChatImagePreview extends StatelessWidget {
  const ChatImagePreview({
    super.key,
    required this.imagePath,
    required this.onClear,
  });

  final String imagePath;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
            child: Image.file(
              File(imagePath),
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.image_rounded),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'Imagen adjunta',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ),

          // Dismiss button
          IconButton(
            onPressed: onClear,
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            tooltip: 'Eliminar imagen',
          ),
        ],
      ),
    );
  }
}
