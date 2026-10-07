import 'package:flutter/material.dart';

/// Breakpoints (logical pixels) used across the app.
class AppBreakpoints {
  /// Phones (portrait and most landscape phones).
  static const double compact = 600;

  /// Tablets portrait / large landscape phones.
  static const double medium = 840;

  /// Tablets landscape / desktop / wide screens.
  /// Anything wider uses centered, max-width content.
  static const double expandedMaxContentWidth = 1100;
  static const double formMaxWidth = 480;
  static const double listMaxWidth = 700;
}

/// Responsive helpers: grid columns, centered max-width content,
/// adaptive padding, and fractional hero sizing.
///
/// These guarantee no horizontal overflow on small phones
/// and a clean, centered layout on tablets and wide screens.
class Responsive {
  /// Grid columns for the food grid: 2 (phones) → 3 (tablets)
  /// → 4 (wide screens).
  static int columnsForWidth(double width) {
    if (width >= AppBreakpoints.medium) return 4;
    if (width >= AppBreakpoints.compact) return 3;
    return 2;
  }

  /// Horizontal page padding: 20 on phones, 24 on bigger screens.
  static double pagePadding(double width) =>
      width >= AppBreakpoints.compact ? 24 : 20;

  /// Center content with a max width so tablets/wide screens
  /// don't stretch full-bleed.
  static Widget centered(
    Widget child, {
    double maxWidth = AppBreakpoints.listMaxWidth,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  /// Hero image height as a fraction of screen height,
  /// clamped so it never overflows short/landscape screens
  /// and never dominates tall ones.
  static double heroHeight(
    BuildContext context, {
    double fraction = 0.32,
    double min = 180,
    double max = 320,
  }) {
    final h = MediaQuery.sizeOf(context).height * fraction;
    return h.clamp(min, max).toDouble();
  }

  /// True on narrow phones (<360dp) where rows must compress
  /// (shorter labels, stacked actions).
  static bool isNarrow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;
}
