import 'package:flutter/material.dart';

/// Border radius scale from DESIGN.md.
abstract final class AppRadii {
  static const double none = 0;
  static const double sm = 8;
  static const double pill = 9999;
  static const double full = 9999;

  static const BorderRadius noneRadius = BorderRadius.zero;
  static final BorderRadius smRadius = BorderRadius.circular(sm);
  static final BorderRadius pillRadius = BorderRadius.circular(pill);
  static final BorderRadius fullRadius = BorderRadius.circular(full);
}
