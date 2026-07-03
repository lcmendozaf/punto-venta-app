import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/core/services/remote_config_service.dart';
import 'package:punto_venta_app/features/support_chat/presentation/bloc/support_chat_bloc.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/chat_image_preview.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/chat_input_bar.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/chat_message_list.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

class FloatingChatOverlay extends StatefulWidget {
  const FloatingChatOverlay({super.key});

  @override
  State<FloatingChatOverlay> createState() => _FloatingChatOverlayState();
}

class _FloatingChatOverlayState extends State<FloatingChatOverlay> {
  bool _isInitialized = false;
  bool _isActive = false;
  bool _isExpanded = false;

  Offset _bubblePosition = const Offset(-1, -1);
  final double _bubbleSize = 56.0;

  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkSupportChatActive();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkSupportChatActive() async {
    try {
      final authLocal = di.sl<AuthLocalDataSource>();
      final enterprise = await authLocal.getCachedEnterprise();
      final id = enterprise?.id ?? -1;
      final active = di.sl<RemoteConfigService>().isSupportChatActive(id);
      if (mounted) {
        setState(() {
          _isActive = active;
          _isInitialized = true;
        });
        if (active) {
          context.read<SupportChatBloc>().add(const LoadMessages());
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
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
    if (!_isInitialized || !_isActive) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;

    // Set initial position at bottom right if not set yet
    if (_bubblePosition.dx == -1 && _bubblePosition.dy == -1) {
      _bubblePosition = Offset(
        screenSize.width - _bubbleSize - 24,
        screenSize.height - _bubbleSize - 24,
      );
    }

    return Stack(
      children: [
        // Chat Panel
        if (_isExpanded)
          Positioned(
            right: 24,
            bottom: 24 + _bubbleSize + 12,
            width: 360,
            height: 500,
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              color: Theme.of(context).colorScheme.surface,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Header
                    _buildChatHeader(context),

                    // Message list
                    Expanded(
                      child: BlocConsumer<SupportChatBloc, SupportChatState>(
                        listenWhen: (prev, curr) => curr.sendState != prev.sendState,
                        listener: (context, state) {
                          state.sendState.maybeWhen(
                            error: (msg) => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            orElse: () {},
                          );
                        },
                        builder: (context, state) {
                          final isLoading = state.messagesState is MessagesLoading;
                          final isSending = state.sendState is SendSending;

                          return Column(
                            children: [
                              Expanded(
                                child: ChatMessageList(
                                  messages: state.messages,
                                  controller: _scrollController,
                                  isLoading: isLoading,
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

        // Draggable Floating Action Bubble
        Positioned(
          left: _bubblePosition.dx,
          top: _bubblePosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                double newX = _bubblePosition.dx + details.delta.dx;
                double newY = _bubblePosition.dy + details.delta.dy;

                // Clamp to screen boundaries
                newX = newX.clamp(16.0, screenSize.width - _bubbleSize - 16.0);
                newY = newY.clamp(16.0, screenSize.height - _bubbleSize - 16.0);

                _bubblePosition = Offset(newX, newY);
              });
            },
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Material(
              elevation: 8,
              shape: const CircleBorder(),
              color: Theme.of(context).colorScheme.primary,
              child: Container(
                width: _bubbleSize,
                height: _bubbleSize,
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isExpanded ? Icons.close_rounded : Icons.support_agent_rounded,
                    key: ValueKey<bool>(_isExpanded),
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primary,
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
                        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
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
              setState(() {
                _isExpanded = false;
              });
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
    );
  }
}
