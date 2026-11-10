import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:turf_app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: TurfApp()));

    // Verify that the app builds without crashing.
    expect(find.byType(TurfApp), findsOneWidget);

    // Pump timers to complete splash screen navigation
    await tester.pump(const Duration(seconds: 5));
  });
}

