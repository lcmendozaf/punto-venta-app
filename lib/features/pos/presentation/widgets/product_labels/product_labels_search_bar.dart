import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_state.dart';

class ProductLabelsSearchBar extends StatefulWidget {
  const ProductLabelsSearchBar({super.key});

  @override
  State<ProductLabelsSearchBar> createState() => _ProductLabelsSearchBarState();
}

class _ProductLabelsSearchBarState extends State<ProductLabelsSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductLabelsBloc, ProductLabelsState>(
      builder: (context, state) {
        final isLoaded = state is ProductLabelsLoaded;
        final categories = isLoaded ? state.categories : const <String>[];

        return Row(
          children: [
            Expanded(child: _buildSearchField(isLoaded)),
            const SizedBox(width: 16),
            SizedBox(
              width: 250,
              child: _buildCategoryDropdown(isLoaded, categories),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField(bool enabled) {
    return TextField(
      controller: _searchController,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: 'Buscar productos...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty && enabled
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  context
                      .read<ProductLabelsBloc>()
                      .add(const SearchProducts(''));
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        context.read<ProductLabelsBloc>().add(SearchProducts(value));
      },
    );
  }

  Widget _buildCategoryDropdown(bool enabled, List<String> categories) {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Categoría',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text(
            'Todas las categorías',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...categories.where((cat) => cat.isNotEmpty).map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(
              category,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ],
      onChanged: enabled
          ? (value) {
              setState(() {
                _selectedCategoryId = value;
              });
              if (value == null) {
                context.read<ProductLabelsBloc>().add(const LoadProducts());
              } else {
                context
                    .read<ProductLabelsBloc>()
                    .add(LoadProductsByCategory(value));
              }
            }
          : null,
    );
  }
}
