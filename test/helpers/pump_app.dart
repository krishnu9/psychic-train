import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps a widget in ProviderScope and material app for testing.
/// Automatically overrides [sharedPreferencesProvider] with an in-memory mock
/// so every test can read `useLbsProvider` without extra setup.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ...overrides,
        ],
        child: MaterialApp(
          home: Scaffold(body: widget),
        ),
      ),
    );
  }
}
