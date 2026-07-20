import 'package:flutter/material.dart';

import '../../../../core/theme/theme_ext.dart';
import '../../../../core/widgets/bottom_sheet_shell.dart';

/// Delivery-area picker (matches the wireframe's location modal).
class LocationSheet extends StatelessWidget {
  const LocationSheet({super.key});

  static const _zones = <(IconData, String, String)>[
    (Icons.location_city, 'Mumbai', 'City & western suburbs'),
    (Icons.apartment, 'Navi Mumbai', 'Vashi to Panvel'),
    (Icons.home_outlined, 'Suburbs', 'Thane, Kalyan, Dombivli'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BottomSheetShell(
      title: 'Select delivery area',
      subtitle: 'We deliver across these zones',
      child: Column(
        children: [
          for (final z in _zones)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(z.$1, color: c.green),
              title: Text(z.$2,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(z.$3, style: TextStyle(color: c.muted)),
              onTap: () => Navigator.of(context).pop(z.$2),
            ),
        ],
      ),
    );
  }
}
