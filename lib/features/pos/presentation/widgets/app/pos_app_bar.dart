import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/auth/domain/entities/user.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_state.dart';
import 'package:punto_venta_app/core/widgets/dynamic_date_time.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cash_register/cash_register_cubit.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cash_register/cash_register_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/cash_register/open_cash_register_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/cash_register/close_cash_register_dialog.dart';

class PosAppBar extends StatelessWidget {
  final User? user;

  const PosAppBar({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                BlocBuilder<CashRegisterCubit, CashRegisterState>(
                  builder: (context, registerState) {
                    final isOpen = registerState is CashRegisterLoaded &&
                        registerState.status.isOpen;

                    return InkWell(
                      onTap: () {
                        if (isOpen) {
                          showCloseCashRegisterDialog(context);
                        } else {
                          showOpenCashRegisterDialog(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOpen ? Icons.lock_open : Icons.lock,
                              size: 16,
                              color: isOpen ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Cajero: ${user?.name ?? "Desconocido"}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: AppDimensions.paddingS),
                const Text('|', style: TextStyle(fontSize: 14)),
                const SizedBox(width: AppDimensions.paddingS),
                Text(
                  'ID: ${user?.id ?? "N/A"}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    if (state is ProductLoaded) {
                      return Text(
                        '# Lista: ${state.currentPriceList}',
                        style: const TextStyle(fontSize: 14),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(width: AppDimensions.paddingM),
                DynamicDateTime(
                  style: TextStyle(
                    fontSize: constraints.maxWidth > 600 ? 14 : 12,
                  ),
                ),
                // const SizedBox(width: AppDimensions.paddingM),
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user!.roleCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
