import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';

class PdvClientSelector extends StatelessWidget {
  final List<Client> clients;
  final bool isLoading;
  final Client? selectedClient;
  final String searchQuery;
  final ValueChanged<Client> onClientSelected;

  const PdvClientSelector({
    super.key,
    required this.clients,
    required this.isLoading,
    required this.selectedClient,
    required this.searchQuery,
    required this.onClientSelected,
  });

  static const double clientListHeight = 200;

  List<Client> _filterClients() {
    if (searchQuery.isEmpty) return clients;
    final query = searchQuery.toLowerCase();
    return clients.where((client) {
      return client.name.toLowerCase().contains(query) ||
          client.id.toString().contains(query) ||
          (client.document?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      height: clientListHeight,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (clients.isEmpty) {
      return const Center(
        child: Text(
          'No hay clientes disponibles',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final filteredClients = _filterClients();

    if (filteredClients.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron clientes',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredClients.length,
      itemBuilder: (context, index) {
        final client = filteredClients[index];
        final isSelected = selectedClient?.id == client.id;

        return PdvClientListTile(
          key: ValueKey(client.id),
          client: client,
          isSelected: isSelected,
          onTap: () => onClientSelected(client),
        );
      },
    );
  }
}

class PdvClientListTile extends StatelessWidget {
  final Client client;
  final bool isSelected;
  final VoidCallback onTap;

  const PdvClientListTile({
    super.key,
    required this.client,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isSelected ? AppColors.primary : Colors.grey.shade300,
        child: Icon(
          Icons.person,
          color: isSelected ? Colors.white : Colors.grey.shade600,
        ),
      ),
      title: Text(
        client.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      subtitle: Text(
        'ID: ${client.id}${client.document != null ? ' - ${client.document}' : ''}',
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}
