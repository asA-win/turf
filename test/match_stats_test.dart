import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turf_app/features/stats/presentation/screens/match_stats_screen.dart';

void main() {
  testWidgets('MatchStatsScreen renders Cricket stats with Best Player, Top Scorer, and Most Wickets', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MatchStatsScreen(
          matchData: {
            'sport': 'Cricket',
            'turfName': 'Turf Nation Box Pitch',
            'teamA': 'Blaster XI',
            'teamB': 'Royal Chalks',
            'scoreDisplay': '88/4 vs 72/6',
            'result': '🏆 Blaster XI won by 16 runs',
            'mvp': 'Amit Sharma (54 runs, 2 wkts)',
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Sport
    expect(find.text('Match Statistics'), findsOneWidget);
    expect(find.textContaining('Cricket'), findsWidgets);
    expect(find.text('Blaster XI'), findsWidgets);
    expect(find.text('Royal Chalks'), findsWidgets);

    // Verify Best Player of the Match
    expect(find.textContaining('Best Player of the Match'), findsOneWidget);
    expect(find.text('Amit Sharma'), findsWidgets);

    // Verify Top Scorer
    expect(find.text('🏏 TOP RUN SCORER'), findsOneWidget);
    expect(find.text('HIGHEST RUNS'), findsOneWidget);

    // Verify Most Wickets Taken
    expect(find.text('🎯 MOST WICKETS TAKEN'), findsOneWidget);
    expect(find.text('BEST BOWLER'), findsOneWidget);
    expect(find.text('3 / 14'), findsOneWidget);

    // Verify Team Head-to-Head Comparison
    expect(find.text('Team Head-to-Head Comparison'), findsOneWidget);
    expect(find.text('Total Runs'), findsOneWidget);

    // Verify Player Performance Scorecard
    expect(find.text('Player Performance Scorecard'), findsOneWidget);
    expect(find.text('Runs'), findsOneWidget);
    expect(find.text('Balls'), findsOneWidget);
  });

  testWidgets('MatchStatsScreen adapts when switched to Football', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MatchStatsScreen(
          matchData: {
            'sport': 'Football',
            'turfName': 'Green Field Arena',
            'teamA': 'Turf Titans',
            'teamB': 'Kickers United',
            'scoreDisplay': '4 - 2',
            'result': '🏆 Turf Titans won 4-2',
            'mvp': 'Rahul Sharma (2 Goals)',
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Football specific headers and performers
    expect(find.textContaining('Football'), findsWidgets);
    expect(find.text('⚽ TOP SCORER'), findsOneWidget);
    expect(find.text('👟 MOST ASSISTS / PLAYMAKER'), findsOneWidget);
    expect(find.text('🧤 BEST GOALKEEPER / MOST SAVES'), findsOneWidget);
    expect(find.text('Possession'), findsOneWidget);
    expect(find.text('Shots on Target'), findsOneWidget);
  });
}
