import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';

class SearchField extends StatefulWidget {
  final TextEditingController controller;
  final bool autofocus;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final Future<void> Function(String) onSubmitted;

  const SearchField({
    super.key,
    required this.controller,
    required this.autofocus,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSubmitted,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _requestFocus({bool retryAfterSnackBar = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();

      if (retryAfterSnackBar) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _focusNode.requestFocus();
        });
      }
    });
  }

  Future<void> _handleSubmitted(String value, bool isBarcodeMode) async {
    await widget.onSubmitted(value);
    if (!mounted) return;
    if (isBarcodeMode) {
      _requestFocus(retryAfterSnackBar: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UiBloc, UiState>(
      listenWhen: (previous, current) {
        if (previous is UiLoaded && current is UiLoaded) {
          return previous.isBarcodeSearchEnabled !=
              current.isBarcodeSearchEnabled;
        }
        return false;
      },
      listener: (context, state) {
        if (state is UiLoaded && state.isBarcodeSearchEnabled) {
          _requestFocus();
        }
      },
      builder: (context, state) {
        final uiState = state as UiLoaded;
        final isBarcodeMode = uiState.isBarcodeSearchEnabled;

        return SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeightm,
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus || isBarcodeMode,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),
              hintText: isBarcodeMode
                  ? AppStrings.searchBarCodeHint
                  : AppStrings.searchHint,
              prefixIcon: Icon(
                isBarcodeMode ? FontAwesomeIcons.barcode : Icons.search,
                color: AppColors.primary,
              ),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: AppColors.textSecondary),
                      onPressed: widget.onClearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusM),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusM),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusM),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
            ),
            onChanged: isBarcodeMode ? null : widget.onSearchChanged,
            onSubmitted: (value) => _handleSubmitted(value, isBarcodeMode),
          ),
        );
      },
    );
  }
}
