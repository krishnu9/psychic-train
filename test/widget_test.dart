
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/app.dart';

import 'package:gymapp/providers/providers.dart';

void main() {
  testWidgets('App starts and shows GymApp title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routinesProvider.overrideWith((ref) => Stream.value([])),
          exercisesProvider.overrideWith((ref) => Stream.value([])),
          workoutsThisWeekProvider.overrideWith((ref) => Stream.value(0)),
          totalWorkoutsProvider.overrideWith((ref) => Stream.value(0)),
          isAuthenticatedProvider.overrideWith((ref) => true),
        ],
        child: const GymApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('GymApp'), findsOneWidget);
  });
}
