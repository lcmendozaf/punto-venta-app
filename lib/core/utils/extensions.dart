import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

extension FormatCurrency on double {
  String formatToCurrency([String? currencyCode]) {
    final code = (currencyCode ?? 'ARS').toUpperCase();

    late NumberFormat format;

    switch (code) {
      case 'USD':
        format = NumberFormat('#,##0.00', 'en_US');
        break;
      case 'ARS':
      default:
        format = NumberFormat('#,##0.00', 'es_AR');
        break;
    }

    return '\$ ${format.format(this)}';
  }
}

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }

  double? parseFormattedDouble() {
    if (this.isEmpty) return null;
    final cleaned = this.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double value = double.parse(digitsOnly) / 100;
    final formatter = NumberFormat('#,##0.00', 'es_AR');
    String newText = formatter.format(value);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
