import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/typography.dart';

/// Navigation themes for bottom nav and shell rows.
abstract final class AppNavigationTheme {
  static BottomNavigationBarThemeData bottomNav() =>
      const BottomNavigationBarThemeData(
        backgroundColor: AppPalette.canvas,
        selectedItemColor: AppPalette.primary,
        unselectedItemColor: AppPalette.mute,
        selectedLabelStyle: TextStyle(fontSize: 0),
        unselectedLabelStyle: TextStyle(fontSize: 0),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      );

  static NavigationBarThemeData navigationBar() => NavigationBarThemeData(
        backgroundColor: AppPalette.canvas,
        indicatorColor: AppPalette.canvasSoft,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStatePropertyAll(
          const AppTypography().captionMonoSm,
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppPalette.primary,
              size: 22,
            );
          }
          return const IconThemeData(
            color: AppPalette.mute,
            size: 22,
          );
        }),
      );
}
