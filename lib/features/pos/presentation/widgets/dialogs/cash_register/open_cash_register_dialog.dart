import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cash_register/cash_register_cubit.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cash_register/cash_register_state.dart';

void showOpenCashRegisterDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => BlocProvider.value(
      value: context.read<CashRegisterCubit>(),
      child: const _OpenCashRegisterDialogContent(),
    ),
  );
}

class _OpenCashRegisterDialogContent extends StatelessWidget {
  const _OpenCashRegisterDialogContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CashRegisterCubit, CashRegisterState>(
      listener: (context, state) {
        if (state is CashRegisterLoaded && state.status.isOpen) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La caja se ha abierto correctamente.'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is CashRegisterError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al abrir la caja: ${state.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is CashRegisterLoading;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_open, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Apertura de Caja'),
            ],
          ),
          content: const Text(
            '¿Confirmas la apertura de la caja para iniciar la jornada laboral?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      context.read<CashRegisterCubit>().openRegister();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Confirmar Apertura'),
            ),
          ],
        );
      },
    );
  }
}
