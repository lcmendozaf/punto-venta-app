import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/features/support_chat/presentation/bloc/support_chat_bloc.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/chat_image_preview.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/chat_input_bar.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/chat_message_list.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/phone_input_widget.dart';
import 'package:punto_venta_app/features/support_chat/presentation/widgets/support_chat_app_bar.dart';

class FloatingChatOverlay extends StatefulWidget {
  static final ValueNotifier<bool> isExpandedNotifier =
      ValueNotifier<bool>(false);

  const FloatingChatOverlay({super.key});

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
    FloatingChatOverlay.isExpandedNotifier.addListener(_handleNotifierChanged);
    _isExpanded = FloatingChatOverlay.isExpandedNotifier.value;
    if (_isExpanded) {
      context.read<SupportChatBloc>().add(const LoadMessages());
    }
  }

  @override
  void dispose() {
    FloatingChatOverlay.isExpandedNotifier
        .removeListener(_handleNotifierChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleNotifierChanged() {
    if (mounted) {
      final isExpanded = FloatingChatOverlay.isExpandedNotifier.value;
      if (isExpanded) {
        context.read<SupportChatBloc>().add(const LoadMessages());
      }
      setState(() {
        _isExpanded = isExpanded;
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
                    SupportChatAppBar(
                      onDragUpdate: (details) {
                        final screenSize = MediaQuery.of(context).size;
                        setState(() {
                          double newX = _panelPosition.dx + details.delta.dx;
                          double newY = _panelPosition.dy + details.delta.dy;

                          // Clamp to screen boundaries
                          newX = newX.clamp(
                              16.0, screenSize.width - _panelWidth - 16.0);
                          newY = newY.clamp(
                              16.0, screenSize.height - _panelHeight - 16.0);

                          _panelPosition = Offset(newX, newY);
                        });
                      },
                      onMinimize: () {
                        FloatingChatOverlay.isExpandedNotifier.value = false;
                      },
                    ),

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
                           final isDark =
                               Theme.of(context).brightness == Brightness.dark;

                           if (state.messagesState is MessagesNeedsPhoneNumber) {
                             return const PhoneInputWidget();
                           }

                           if (state.messagesState is MessagesError) {
                             final errorMsg = (state.messagesState as MessagesError).message;
                             return Container(
                               color: isDark ? AppColors.darkBackground : AppColors.background,
                               child: Center(
                                 child: Padding(
                                   padding: const EdgeInsets.all(24.0),
                                   child: Column(
                                     mainAxisAlignment: MainAxisAlignment.center,
                                     children: [
                                       const Icon(
                                         Icons.error_outline_rounded,
                                         color: Colors.redAccent,
                                         size: 40,
                                       ),
                                       const SizedBox(height: 12),
                                       Text(
                                         errorMsg,
                                         textAlign: TextAlign.center,
                                         style: TextStyle(
                                           color: isDark ? Colors.white70 : Colors.black87,
                                           fontSize: 13,
                                           height: 1.4,
                                         ),
                                       ),
                                       const SizedBox(height: 20),
                                       ElevatedButton(
                                         onPressed: () {
                                           context
                                               .read<SupportChatBloc>()
                                               .add(const LoadMessages());
                                         },
                                         style: ElevatedButton.styleFrom(
                                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                           shape: RoundedRectangleBorder(
                                             borderRadius: BorderRadius.circular(10),
                                           ),
                                         ),
                                         child: const Text('Reintentar'),
                                       ),
                                     ],
                                   ),
                                 ),
                               ),
                             );
                           }

                           final isLoading =
                               state.messagesState is MessagesLoading;
                           final isSending = state.sendState is SendSending;
                           final isChatReady = state.messagesState is MessagesLoaded;

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
                                 enabled: !isSending && isChatReady,
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
}
