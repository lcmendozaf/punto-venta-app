import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/features/support_chat/presentation/bloc/support_chat_bloc.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/chat_image_preview.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/chat_input_bar.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/chat_message_list.dart';

class FloatingChatOverlay extends StatefulWidget {
  final ValueNotifier<bool>? isExpandedNotifier;

  const FloatingChatOverlay({
    super.key,
    this.isExpandedNotifier,
  });

  @override
  State<FloatingChatOverlay> createState() => _FloatingChatOverlayState();
}

class _FloatingChatOverlayState extends State<FloatingChatOverlay> {
  bool _isExpanded = false;

  Offset _panelPosition = const Offset(-1, -1);
  final double _panelWidth = 360.0;
  final double _panelHeight = 500.0;

  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<SupportChatBloc>().add(const LoadMessages());
    widget.isExpandedNotifier?.addListener(_handleNotifierChanged);
    if (widget.isExpandedNotifier != null) {
      _isExpanded = widget.isExpandedNotifier!.value;
    }
  }

  @override
  void didUpdateWidget(covariant FloatingChatOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpandedNotifier != widget.isExpandedNotifier) {
      oldWidget.isExpandedNotifier?.removeListener(_handleNotifierChanged);
      widget.isExpandedNotifier?.addListener(_handleNotifierChanged);
      if (widget.isExpandedNotifier != null) {
        setState(() {
          _isExpanded = widget.isExpandedNotifier!.value;
        });
      }
    }
  }

  @override
  void dispose() {
    widget.isExpandedNotifier?.removeListener(_handleNotifierChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleNotifierChanged() {
    if (mounted && widget.isExpandedNotifier != null) {
      setState(() {
        _isExpanded = widget.isExpandedNotifier!.value;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    final result = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (result == null) return;
    if (!context.mounted) return;
    context.read<SupportChatBloc>().add(SetPendingImage(result.path));
  }

  void _sendMessage(BuildContext context, String text) {
    final bloc = context.read<SupportChatBloc>();
    bloc.add(SendMessage(
      text: text,
      imagePath: bloc.state.pendingImagePath,
    ));
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    if (_panelPosition.dx == -1 && _panelPosition.dy == -1) {
      _panelPosition = Offset(
        96.0,
        screenSize.height - _panelHeight - 24.0,
      );
    }

    return Stack(
      children: [
        // Chat Panel
        if (_isExpanded)
          Positioned(
            left: _panelPosition.dx,
            top: _panelPosition.dy,
            width: _panelWidth,
            height: _panelHeight,
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              color: Theme.of(context).colorScheme.surface,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Header (Draggable)
                    _buildChatHeader(context),

                    // Message list
                    Expanded(
                      child: BlocConsumer<SupportChatBloc, SupportChatState>(
                        listenWhen: (prev, curr) =>
                            curr.sendState != prev.sendState,
                        listener: (context, state) {
                          state.sendState.maybeWhen(
                            error: (msg) =>
                                ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                            ),
                            orElse: () {},
                          );
                        },
                        builder: (context, state) {
                          final isLoading =
                              state.messagesState is MessagesLoading;
                          final isSending = state.sendState is SendSending;

                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;

                          return Column(
                            children: [
                              Expanded(
                                child: Container(
                                  color: isDark
                                      ? AppColors.darkBackground
                                      : AppColors.background,
                                  child: ChatMessageList(
                                    messages: state.messages,
                                    controller: _scrollController,
                                    isLoading: isLoading,
                                  ),
                                ),
                              ),
                              if (state.pendingImagePath != null)
                                ChatImagePreview(
                                  imagePath: state.pendingImagePath!,
                                  onClear: () => context
                                      .read<SupportChatBloc>()
                                      .add(const ClearImagePreview()),
                                ),
                              ChatInputBar(
                                hasImage: state.pendingImagePath != null,
                                enabled: !isSending,
                                onPickImage: () => _pickImage(context),
                                onSend: (text) => _sendMessage(context, text),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onPanUpdate: (details) {
        final screenSize = MediaQuery.of(context).size;
        setState(() {
          double newX = _panelPosition.dx + details.delta.dx;
          double newY = _panelPosition.dy + details.delta.dy;

          // Clamp to screen boundaries
          newX = newX.clamp(16.0, screenSize.width - _panelWidth - 16.0);
          newY = newY.clamp(16.0, screenSize.height - _panelHeight - 16.0);

          _panelPosition = Offset(newX, newY);
        });
      },
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
              onPressed: () {
                if (widget.isExpandedNotifier != null) {
                  widget.isExpandedNotifier!.value = false;
                } else {
                  setState(() {
                    _isExpanded = false;
                  });
                }
              },
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
