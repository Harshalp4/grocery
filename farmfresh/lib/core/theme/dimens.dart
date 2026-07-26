import 'package:flutter/widgets.dart';

/// Spacing, radius and elevation constants — mirror the wireframe tokens
/// (`--radius`, `--radius-sm`, paddings) so layout rhythm stays consistent.
abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  /// Standard page padding used across screens.
  static const EdgeInsets page = EdgeInsets.all(lg);
}

abstract class AppRadius {
  static const double sm = 12; // --radius-sm
  static const double md = 18; // --radius
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}
