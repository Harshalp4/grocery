import 'package:flutter/material.dart';

/// Maps a category name to a Material icon. Kept in the presentation layer so
/// the domain [Category] entity stays free of Flutter types. Falls back to a
/// generic basket icon for unknown categories (e.g. new ones from the API).
IconData categoryIcon(String name) {
  switch (name) {
    case 'Rice':
      return Icons.rice_bowl_outlined;
    case 'Dal & Pulses':
      return Icons.grain;
    case 'Wheat & Flour':
      return Icons.grass;
    case 'Oils & Ghee':
      return Icons.water_drop_outlined;
    case 'Spices':
      return Icons.local_fire_department_outlined;
    case 'Millets':
      return Icons.eco_outlined;
    case 'Tea & Coffee':
      return Icons.coffee_outlined;
    case 'Sugar & Jaggery':
      return Icons.cake_outlined;
    default:
      return Icons.shopping_basket_outlined;
  }
}
