import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turf_app/features/home/presentation/screens/scoreboard_setup_screen.dart';
import 'package:turf_app/features/home/presentation/screens/match_scoreboard_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('ScoreboardSetupScreen renders and allows adding members', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScoreboardSetupScreen(),
      ),
    );

    // Verify Title
    expect(find.text('Scoreboard Setup'), findsOneWidget);

    // Verify Teams
    expect(find.text('TEAM A'), findsOneWidget);
    expect(find.text('TEAM B'), findsOneWidget);

    // Verify Start Live Scoreboard button exists
    expect(find.text('Start Live Scoreboard'), findsOneWidget);

    // Verify Add Member buttons exist
    expect(find.text('Add'), findsNWidgets(2));
  });

  testWidgets('MatchScoreboardScreen renders Scoreboard, Squads, and Timeline tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MatchScoreboardScreen(
            initialConfig: {
              'sport': 'football',
              'turfName': 'Play Arena Bangalore',
              'teamA': 'Titans FC',
              'teamB': 'Warriors XI',
              'teamAMembers': [
                {'name': 'Leo Messi', 'role': 'Striker', 'number': '10', 'goals': 0},
              ],
              'teamBMembers': [
                {'name': 'Cristiano Ronaldo', 'role': 'Striker', 'number': '7', 'goals': 0},
              ],
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify team names appear
    expect(find.text('Titans FC'), findsWidgets);
    expect(find.text('Warriors XI'), findsWidgets);

    // Verify Squads tab is present
    expect(find.textContaining('Squads'), findsWidgets);

    // Tap Squads tab
    await tester.tap(find.textContaining('Squads').first);
    await tester.pumpAndSettle();

    // Verify squad members are displayed
    expect(find.text('Leo Messi'), findsOneWidget);
    expect(find.text('Cristiano Ronaldo'), findsOneWidget);
    expect(find.text('Add Member'), findsNWidgets(2));
  });
}
