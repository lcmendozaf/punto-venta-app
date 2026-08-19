import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_state.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_ticket_config_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/app/pos_app_bar.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_panel.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_log_item_widget.dart';
import 'package:punto_venta_app/core/widgets/scroll_bottom_extension.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/catalog/catalog_card.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/integrated_search_bar.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/category_tabs_section.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/product_grid_section.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cash_register/cash_register_cubit.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cash_register/cash_register_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cash_register/closed_register_view.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

class PosMainPage extends StatefulWidget {
  const PosMainPage({super.key});

  @override
  State<PosMainPage> createState() => _PosMainPageState();
}

class _PosMainPageState extends State<PosMainPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _catalogLogScrollController = ScrollController();
  int _lastLogLength = 0;

  @override
  void initState() {
    super.initState();

    context.read<PaymentMethodsBloc>().add(LoadPaymentMethods());
    context.read<ClientsBloc>().add(LoadDefaultClientEvent());

    if (context.read<CartBloc>().state is! CartLoaded) {
      context.read<CartBloc>().add(ClearCart());
    }

    _fetchAppConfig();
  }

  Future<void> _fetchAppConfig() async {
    try {
      final fetchAppConfigUsecase = di.sl<FetchTicketConfigUsecase>();
      await fetchAppConfigUsecase();
    } catch (e) {
      print('⚠️ No se pudo obtener configuración de sucursal: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _catalogLogScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientsBloc, ClientsState>(
      listenWhen: (previous, current) {
        if (previous is ClientsLoaded && current is ClientsLoaded) {
          return previous.selectedClient?.id != current.selectedClient?.id;
        }
        if (previous is! ClientsLoaded && current is ClientsLoaded) {
          return true;
        }
        return false;
      },
      listener: (context, state) {
        if (state is ClientsLoaded) {
          final priceListId = state.selectedClient?.listId;
          context
              .read<ProductBloc>()
              .add(LoadProducts(priceListId: priceListId));
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState is AuthAuthenticated ? authState.user : null;

          return Scaffold(
            resizeToAvoidBottomInset: true,
            body: Row(
              children: [
                // Catálogo de productos
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      PosAppBar(user: user),
                      // const ClientInfoBar(),
                      Expanded(
                        child:
                            BlocBuilder<CashRegisterCubit, CashRegisterState>(
                          builder: (context, registerState) {
                            if (registerState is CashRegisterLoading) {
                              final currentStatus =
                                  context.read<CashRegisterCubit>().currentStatus;
                              if (currentStatus == null) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                            }

                            final currentStatus = registerState is CashRegisterLoaded
                                ? registerState.status
                                : (registerState is CashRegisterError
                                    ? registerState.lastStatus
                                    : context
                                        .read<CashRegisterCubit>()
                                        .currentStatus);

                            final isRegisterOpen = currentStatus?.isOpen ?? false;

                            if (!isRegisterOpen) {
                              return const ClosedRegisterView();
                            }

                            return BlocBuilder<UiBloc, UiState>(
                              builder: (context, uiState) {
                                final isBarcodeMode = uiState is UiLoaded
                                    ? uiState.isBarcodeSearchEnabled
                                    : true;

                                return CatalogCard(
                                  // barra de búsqueda
                                  searchBar: IntegratedSearchBar(
                                    controller: _searchController,
                                    autofocus: false,
                                    onSearchChanged: (query) {
                                      setState(() {});
                                      context
                                          .read<ProductBloc>()
                                          .add(SearchProducts(query));
                                    },
                                    onClearSearch: () {
                                      _searchController.clear();
                                      context
                                          .read<ProductBloc>()
                                          .add(const SearchProducts(''));
                                      setState(() {});
                                    },
                                  ),
                                  // categorias (solo en modo manual)
                                  categoryTabs: isBarcodeMode
                                      ? const SizedBox.shrink()
                                      : CategoryTabsSection(
                                          onCategorySelected: (_) {},
                                          onClearSearch: () {
                                            _searchController.clear();
                                            context
                                                .read<ProductBloc>()
                                                .add(const SearchProducts(''));
                                          },
                                        ),
                                  // grilla de productos o logs del carrito
                                  productGrid: isBarcodeMode
                                      ? _buildCartLogsInCatalog()
                                      : ProductGridSection(
                                          onProductTap: (product, quantity,
                                              isDeleteMode) {
                                            if (isDeleteMode) {
                                              final cartBloc =
                                                  context.read<CartBloc>();
                                              final quantityInCart = cartBloc
                                                  .getProductQuantityInCart(
                                                      product.id.toString());

                                              if (quantityInCart >= quantity) {
                                                cartBloc.add(
                                                    RemoveQuantityFromCart(
                                                        product.id.toString(),
                                                        quantity));
                                              } else if (quantityInCart > 0) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Solo hay $quantityInCart unidades de ${product.name} en el carrito. No se puede eliminar $quantity.',
                                                    ),
                                                    duration: const Duration(
                                                        seconds: 2),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    backgroundColor:
                                                        AppColors.warning,
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        '${product.name} no está en el carrito'),
                                                    duration: const Duration(
                                                        seconds: 1),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    backgroundColor:
                                                        AppColors.info,
                                                  ),
                                                );
                                              }
                                            } else {
                                              if (product.price != null) {
                                                context.read<CartBloc>().add(
                                                    AddToCart(product,
                                                        quantity: quantity));
                                              }
                                            }
                                            context
                                                .read<UiBloc>()
                                                .add(ResetQuantity());
                                          },
                                        ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Panel de carrito
                const Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: 380,
                    child: CartPanel(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartLogsInCatalog() {
    return BlocConsumer<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartLoaded) {
          if (state.log.length != _lastLogLength) {
            _lastLogLength = state.log.length;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_catalogLogScrollController.hasClients) {
                _catalogLogScrollController.scrollToBottom();
              }
            });
          }
        } else {
          _lastLogLength = 0;
        }
      },
      builder: (context, state) {
        if (state is CartLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_catalogLogScrollController.hasClients &&
                state.log.isNotEmpty) {
              _catalogLogScrollController.scrollToBottom();
            }
          });

          if (state.log.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Escanea productos para agregarlos',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _catalogLogScrollController,
                    itemCount: state.log.length,
                    itemBuilder: (context, index) {
                      final entry = state.log[index];
                      return CartLogItemWidget(entry: entry);
                    },
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(
          child: Text('No hay items en el carrito'),
        );
      },
    );
  }
}
