import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_app/features/auth/presentation/screens/onboarding1_screen.dart';
import 'package:turf_app/features/auth/presentation/screens/onboarding2_screen.dart';
import 'package:turf_app/features/auth/presentation/screens/onboarding3_screen.dart';

void main() {
  Widget createTestWidget(Widget child) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => child),
        GoRoute(path: '/login', builder: (context, state) => const Scaffold(body: Text('Login Screen'))),
        GoRoute(path: '/onboarding2', builder: (context, state) => const Scaffold(body: Text('Onboarding 2'))),
        GoRoute(path: '/onboarding3', builder: (context, state) => const Scaffold(body: Text('Onboarding 3'))),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  testWidgets('Onboarding 1 renders, hits test and taps Skip without assertions', (tester) async {
    // Set a realistic desktop / window screen size
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(const Onboarding1Screen()));
    await tester.pumpAndSettle();

    // Verify Title is present
    expect(find.textContaining('Find & Book'), findsOneWidget);

    // Verify Skip button exists and can be tapped without crashing
    final skipFinder = find.text('Skip');
    expect(skipFinder, findsOneWidget);
    await tester.tap(skipFinder);
    await tester.pumpAndSettle();

    // Verify navigated to Login
    expect(find.text('Login Screen'), findsOneWidget);
  });

  testWidgets('Onboarding 2 renders and taps Skip without assertions', (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(const Onboarding2Screen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Join Matches'), findsOneWidget);

    final skipFinder = find.text('Skip');
    expect(skipFinder, findsOneWidget);
    await tester.tap(skipFinder);
    await tester.pumpAndSettle();

    expect(find.text('Login Screen'), findsOneWidget);
  });

  testWidgets('Onboarding 3 renders and taps Get Started without assertions', (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(const Onboarding3Screen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Compete, Track'), findsOneWidget);

    final getStartedFinder = find.text('Get Started');
    expect(getStartedFinder, findsOneWidget);
    await tester.tap(getStartedFinder);
    await tester.pumpAndSettle();

    expect(find.text('Login Screen'), findsOneWidget);
  });
}
