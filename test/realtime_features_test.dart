import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/features/parking/presentation/screens/parking_screen.dart';
import 'package:turf_app/features/admin/presentation/screens/live_booking_requests_screen.dart';
import 'package:turf_app/features/admin/presentation/screens/venue_calendar_screen.dart';
import 'package:turf_app/features/admin/presentation/screens/venue_earnings_screen.dart';
import 'package:turf_app/features/admin/presentation/screens/venue_reviews_screen.dart';
import 'package:turf_app/features/booking/presentation/screens/my_bookings_screen.dart';
import 'package:turf_app/features/chat/presentation/screens/in_app_messages_screen.dart';
import 'package:turf_app/features/home/presentation/screens/active_matches_screen.dart';
import 'package:turf_app/features/stocks/presentation/screens/stock_shares_screen.dart';
import 'package:turf_app/features/team/presentation/screens/team_dashboard_screen.dart';

class MockAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody.fromString('[]', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Dio createMockDio() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: null,
      receiveTimeout: null,
      sendTimeout: null,
    ),
  );
  dio.httpClientAdapter = MockAdapter();
  return dio;
}

void main() {
  testWidgets('ParkingScreen renders with IOT LIVE status badge', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioClientProvider.overrideWith((ref) => createMockDio()),
        ],
        child: const MaterialApp(
          home: ParkingScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Smart Parking'), findsOneWidget);
    expect(find.text('IOT LIVE'), findsOneWidget);
    expect(find.text('Reserve your slot in advance'), findsOneWidget);
    expect(find.text('Car'), findsOneWidget);
    expect(find.text('Bike'), findsOneWidget);
    expect(find.text('EV'), findsOneWidget);
  });

  testWidgets('LiveBookingRequestsScreen renders with LIVE SYNC and tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioClientProvider.overrideWith((ref) => createMockDio()),
        ],
        child: const MaterialApp(
          home: LiveBookingRequestsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Booking Requests'), findsOneWidget);
    expect(find.text('LIVE SYNC'), findsOneWidget);
    expect(find.textContaining('Pending'), findsOneWidget);
    expect(find.textContaining('Confirmed'), findsOneWidget);
    expect(find.textContaining('Declined'), findsOneWidget);
  });

  testWidgets('MyBookingsScreen renders with LIVE status badge and tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioClientProvider.overrideWith((ref) => createMockDio()),
        ],
        child: const MaterialApp(
          home: MyBookingsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('My Bookings'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Past'), findsOneWidget);
  });

  testWidgets('ActiveMatchesScreen renders with real-time sports filter and matches', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioClientProvider.overrideWith((ref) => createMockDio()),
        ],
        child: const MaterialApp(
          home: ActiveMatchesScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Active Matches'), findsOneWidget);
    expect(find.text('Football'), findsWidgets);
    expect(find.text('Cricket'), findsWidgets);
    expect(find.text('Turf Titans'), findsOneWidget);
  });

  testWidgets('StockSharesScreen renders with MARKET LIVE status badge', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioClientProvider.overrideWith((ref) => createMockDio()),
        ],
        child: const MaterialApp(
          home: StockSharesScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Turf Stock Shares'), findsOneWidget);
    expect(find.text('MARKET LIVE'), findsOneWidget);
  });

  testWidgets('TeamDashboardScreen renders with LIVE status badge', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioClientProvider.overrideWith((ref) => createMockDio()),
        ],
        child: const MaterialApp(
          home: TeamDashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Team Dashboard'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
  });

  testWidgets('VenueCalendarScreen renders with LIVE status badge', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioClientProvider.overrideWith((ref) => createMockDio()),
        ],
        child: const MaterialApp(
          home: VenueCalendarScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Venue Calendar'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
  });

  testWidgets('VenueEarningsScreen renders with LIVE status badge', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioClientProvider.overrideWith((ref) => createMockDio()),
        ],
        child: const MaterialApp(
          home: VenueEarningsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Earnings & Revenue'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
  });

  testWidgets('VenueReviewsScreen renders with LIVE status badge', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioClientProvider.overrideWith((ref) => createMockDio()),
        ],
        child: const MaterialApp(
          home: VenueReviewsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Venue Reviews'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
  });

  testWidgets('InAppMessagesScreen renders with LIVE status badge and chats', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioClientProvider.overrideWith((ref) => createMockDio()),
        ],
        child: const MaterialApp(
          home: InAppMessagesScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('Rahul Sharma'), findsOneWidget);
  });
}
