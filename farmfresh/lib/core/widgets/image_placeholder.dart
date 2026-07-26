import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/theme_ext.dart';

/// Gradient "IMG" placeholder — stands in for product/hero imagery, exactly
/// like the wireframe's `.imgph` (green-soft → beige gradient, "IMG" tag).
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    this.label,
    this.height,
    this.borderRadius = AppRadius.smAll,
  });

  final String? label;
  final double? height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.greenSoft, c.beige],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                label!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Positioned(
            right: 8,
            bottom: 6,
            child: Text(
              'IMG',
              style: TextStyle(
                fontSize: 9,
                color: c.green.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
