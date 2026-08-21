import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/pdv_config_repository.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_branches_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_pdv_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_vat_categories_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pdv_config/pdv_config_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pdv_config/pdv_config_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pdv_config/pdv_config_state.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import 'widgets/pdv_client_selector.dart';
import 'widgets/pdv_selected_client_status.dart';

Future<({int pdvId, int sucursalId})?> showPdvSettingsDialog(
    BuildContext context, bool isAdmin) async {
  return await showDialog<({int pdvId, int sucursalId})>(
    context: context,
    builder: (ctx) => BlocProvider(
      create: (_) => PdvConfigBloc(
        fetchPdvConfigUsecase: di.sl<FetchPdvConfigUsecase>(),
        fetchBranchesUsecase: di.sl<FetchBranchesUsecase>(),
        getVatCategoriesUsecase: di.sl<GetVatCategoriesUsecase>(),
        repository: di.sl<PdvConfigRepository>(),
      )..add(FetchPdvConfigEvent()),
      child: _PdvSettingsDialogContent(isAdmin),
    ),
  );
}

class _PdvSettingsDialogContent extends StatefulWidget {
  final bool isAdmin;
  const _PdvSettingsDialogContent(this.isAdmin);

  @override
  State<_PdvSettingsDialogContent> createState() =>
      _PdvSettingsDialogContentState();
}

class _PdvSettingsDialogContentState extends State<_PdvSettingsDialogContent> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController _clientSearchController = TextEditingController();
  final TextEditingController _daysLimitController = TextEditingController();
  Timer? _searchDebounce;

  List<Branch> _branches = [];
  Branch? _selectedBranch;

  List<Client> _clients = [];
  bool _isClientsLoading = true;
  Client? _selectedClient;
  String _clientSearchQuery = '';
  String? _localError;
  PdvConfig? _pdvConfig;
  int? _creditNoteDaysLimit;

  @override
  void initState() {
    super.initState();

    final clientsState = context.read<ClientsBloc>().state;
    if (clientsState is ClientsLoaded) {
      _clients = clientsState.clients;
      _isClientsLoading = false;
    }
    context.read<ClientsBloc>().add(LoadClients());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _clientSearchController.dispose();
    _daysLimitController.dispose();
    super.dispose();
  }

  void _onClientsState(ClientsState state) {
    if (state is ClientsLoaded) {
      setState(() {
        _clients = state.clients;
        _isClientsLoading = false;
        _syncSelectedClientFromConfig();
      });
    } else if (state is ClientsLoading) {
      if (_clients.isEmpty) {
        setState(() => _isClientsLoading = true);
      }
    } else if (state is ClientsError) {
      setState(() => _isClientsLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _clientSearchQuery = value.toLowerCase());
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _clientSearchController.clear();
    setState(() => _clientSearchQuery = '');
  }

  void _updateControllersFromConfig(PdvConfig config, List<Branch> branches) {
    _branches = branches;
    _pdvConfig = config;

    if (config.branchId != null) {
      _selectedBranch = branches.firstWhere(
        (b) => b.id == config.branchId,
        orElse: () => branches.isNotEmpty ? branches.first : _selectedBranch!,
      );
    }

    _creditNoteDaysLimit = config.creditNoteDaysLimit;
    _daysLimitController.text = config.creditNoteDaysLimit?.toString() ?? '';

    _syncSelectedClientFromConfig();
  }

  void _syncSelectedClientFromConfig() {
    if (_pdvConfig?.pdvId == null || _clients.isEmpty) return;
    final matched = _clients.where((c) => c.id == _pdvConfig!.pdvId).toList();
    if (matched.isNotEmpty) {
      _selectedClient = matched.first;
    }
  }

  void _onBranchSelected(Branch? branch) {
    setState(() {
      _selectedBranch = branch;
    });
  }

  void _onClientSelected(Client? client) {
    setState(() {
      _selectedClient = client;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientsBloc, ClientsState>(
      listener: (context, state) => _onClientsState(state),
      child: BlocConsumer<PdvConfigBloc, PdvConfigState>(
        listener: (context, state) {
          if (state is PdvConfigLoaded) {
            setState(() {
              _updateControllersFromConfig(state.config, state.branches);
            });
          } else if (state is PdvConfigSaved) {
            context.read<ClientsBloc>().add(LoadDefaultClientEvent());
            Navigator.of(context).pop(
              (pdvId: state.config.pdvId, sucursalId: state.config.branchId),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Configuración del PDV guardada'),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is PdvConfigError) {
            setState(() => _localError = null);
          }
        },
        builder: (context, state) {
          final isConfigLoading =
              state is PdvConfigLoading || state is BranchesLoading;
          final canSave = !isConfigLoading && !_isClientsLoading;

          return AlertDialog(
            title: const Text('Configuración del PDV'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(
                        builder: (context) {
                          final String message;
                          final Color bgColor;
                          final Color borderColor;
                          final IconData icon;
                          final Color accentColor;

                          if (state is PdvConfigError || _localError != null) {
                            message = (state is PdvConfigError)
                                ? state.message
                                : _localError!;
                            bgColor = Colors.red.shade50;
                            borderColor = Colors.red.shade200;
                            icon = Icons.error_outline;
                            accentColor = Colors.red;
                          } else {
                            message = isConfigLoading
                                ? 'Cargando configuración...'
                                : 'Configura los datos de tu punto de venta';
                            bgColor = AppColors.primary.withValues(alpha: 0.1);
                            borderColor =
                                AppColors.primary.withValues(alpha: 0.2);
                            icon = Icons.info_outline;
                            accentColor = AppColors.primary;
                          }

                          return Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Icon(icon, size: 20, color: accentColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    message,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: accentColor.withValues(alpha: 0.9),
                                      fontWeight: (state is PdvConfigError ||
                                              _localError != null)
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      if (isConfigLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else ...[
                        DropdownButtonFormField<Branch>(
                          value: _selectedBranch,
                          decoration: const InputDecoration(
                            labelText: 'Seleccionar Sucursal',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                          items: _branches.map((branch) {
                            return DropdownMenuItem<Branch>(
                              value: branch,
                              child: Text('${branch.name} - Id: ${branch.id}'),
                            );
                          }).toList(),
                          onChanged: _onBranchSelected,
                          validator: (v) {
                            if (v == null) {
                              return 'Selecciona una sucursal';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Configuración de Notas de Crédito',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        TextFormField(
                          controller: _daysLimitController,
                          decoration: const InputDecoration(
                            labelText: 'Días límite para anulación',
                            hintText: 'Ej. 30',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                            helperText:
                                'Cantidad de días hacia atrás permitidos para anular',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return null;
                            }
                            final parsed = int.tryParse(v);
                            if (parsed == null || parsed < 0) {
                              return 'Ingresa un número entero positivo';
                            }
                            return null;
                          },
                          onChanged: (v) {
                            _creditNoteDaysLimit = int.tryParse(v);
                          },
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cliente Default',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.paddingM),
                            PdvSelectedClientStatus(
                              selectedClient: _selectedClient,
                              isAdmin: widget.isAdmin,
                            ),
                            if (widget.isAdmin) ...[
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _clientSearchController,
                                builder: (context, value, _) {
                                  return TextFormField(
                                    controller: _clientSearchController,
                                    decoration: InputDecoration(
                                      labelText: 'Buscar cliente',
                                      hintText: 'Nombre, ID o documento',
                                      prefixIcon: const Icon(Icons.search),
                                      border: const OutlineInputBorder(),
                                      suffixIcon: value.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: _clearSearch,
                                            )
                                          : null,
                                    ),
                                    onChanged: _onSearchChanged,
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              PdvClientSelector(
                                clients: _clients,
                                isLoading: _isClientsLoading,
                                selectedClient: _selectedClient,
                                searchQuery: _clientSearchQuery,
                                onClientSelected: _onClientSelected,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: canSave
                    ? () {
                        if (!formKey.currentState!.validate()) return;

                        if (_selectedClient == null) {
                          setState(() {
                            _localError =
                                'Debes seleccionar un cliente default';
                          });
                          return;
                        }

                        setState(() => _localError = null);

                        final pdvId = _selectedClient!.id;
                        final branchId = _selectedBranch!.id;

                        final newConfig =
                            (_pdvConfig ?? const PdvConfig()).copyWith(
                          pdvId: pdvId,
                          branchId: branchId,
                          branchNumber: _pdvConfig?.branchNumber ?? '',
                          creditNoteDaysLimit: _creditNoteDaysLimit,
                        );

                        context
                            .read<PdvConfigBloc>()
                            .add(SavePdvConfigEvent(newConfig));
                      }
                    : null,
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }
}
