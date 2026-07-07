import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

class PhoneInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final void Function(PhoneNumber)? onChanged;
  final void Function(String)? onSaved;
  final bool isValid;

  const PhoneInput({
    super.key,
    required this.controller,
    this.label = 'Número de teléfono',
    required this.onChanged,
    this.onSaved,
    required this.isValid,
  });

  @override
  _PhoneInputState createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput> {
  String? errorText;

  void _validatePhoneNumber(PhoneNumber phone) {
    if (phone.number.length < 8) {
      setState(() {
        errorText = "El número debe tener al menos 8 dígitos.";
      });
      widget.onChanged?.call(phone);
    } else {
      setState(() {
        errorText = null;
      });
      widget.onChanged?.call(phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    return IntlPhoneField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: themeColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: themeColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: themeColor, width: 2),
        ),
        counterText: "",
        errorText: errorText,
      ),
      initialCountryCode: 'AR',
      disableLengthCheck: true,
      onChanged: _validatePhoneNumber,
      onSaved: (phone) {
        if (phone != null && phone.number.length >= 8) {
          widget.onSaved?.call(phone.completeNumber);
        }
      },
      showDropdownIcon: true,
      dropdownIcon: Icon(Icons.arrow_drop_down, color: themeColor),
    );
  }
}
