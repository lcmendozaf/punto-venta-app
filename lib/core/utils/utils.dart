import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';

BorderSide getBorderSide(
    bool canRemoveQuantity, bool hasInsufficientQuantity, bool isInDeleteMode) {
  if (hasInsufficientQuantity) {
    return const BorderSide(color: AppColors.warning, width: 2);
  } else if (canRemoveQuantity) {
    return const BorderSide(color: AppColors.error, width: 2);
  } else if (isInDeleteMode) {
    return BorderSide(color: Colors.grey.shade400, width: 1);
  }
  return BorderSide.none;
}

Color getOverlayColor(bool canRemoveQuantity, bool hasInsufficientQuantity) {
  if (hasInsufficientQuantity) return AppColors.warning.withValues(alpha: 0.15);
  if (canRemoveQuantity) return AppColors.error.withValues(alpha: 0.15);
  return Colors.grey.withValues(alpha: 0.15);
}

IconData getOverlayIcon(bool canRemoveQuantity, bool hasInsufficientQuantity) {
  if (hasInsufficientQuantity) return Icons.warning;
  if (canRemoveQuantity) return Icons.remove_shopping_cart;
  return Icons.not_interested;
}

Color getOverlayIconColor(
    bool canRemoveQuantity, bool hasInsufficientQuantity) {
  if (hasInsufficientQuantity) return AppColors.warning;
  if (canRemoveQuantity) return AppColors.error;
  return Colors.grey.shade600;
}

double calculateAspectRatio(int crossAxisCount) {
  switch (crossAxisCount) {
    case 1:
      return 2.5;
    case 2:
      return 1.4;
    case 3:
      return 1.2;
    case 4:
      return 1.0;
    case 5:
      return 0.9;
    default:
      return 1.0;
  }
}

double calculateSpacing(int crossAxisCount) {
  if (crossAxisCount >= 5) return AppDimensions.paddingS;
  if (crossAxisCount >= 3) return AppDimensions.paddingM;
  return AppDimensions.paddingL;
}

int calculateCrossAxisCount(double width) {
  if (width > 1400) return 5;
  if (width > 1100) return 4;
  if (width > 800) return 3;
  if (width > 500) return 2;
  return 1;
}


String formatDate(String date, {String fromDateFormat='yyyy-MM-dd', String toDateFormat='dd/MM/yyyy'}) {
  try {
    final parsedDate = DateFormat(fromDateFormat).parse(date);
    return DateFormat(toDateFormat).format(parsedDate);
  } catch (e) {
    return date;
  }
}