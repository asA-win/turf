import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';
import 'package:turf_app/features/booking/domain/models/booking.dart';
import 'package:turf_app/features/turf_details/domain/models/turf.dart';

part 'booking_repository.g.dart';

final List<Booking> demoSampleBookings = [
  Booking(
    id: 101,
    userId: 1,
    turfId: 1,
    slotId: 10,
    bookingDate: DateTime.now().add(const Duration(hours: 1)),
    totalPrice: 1500.0,
    status: 'confirmed',
    bookingType: 'full',
    turf: Turf(
      id: 1,
      name: 'Green Field Arena',
      location: 'Indiranagar, Bangalore',
      pricePerHour: 1000.0,
      imageUrl: 'https://images.unsplash.com/photo-1529900241452-4467c6ebc4ae?auto=format&fit=crop&w=600&q=80',
      sportTypes: 'Football, Cricket, Badminton',
      latitude: 12.9716,
      longitude: 77.5946,
    ),
  ),
  Booking(
    id: 102,
    userId: 1,
    turfId: 2,
    slotId: 11,
    bookingDate: DateTime.now().add(const Duration(days: 1)),
    totalPrice: 1800.0,
    status: 'confirmed',
    bookingType: 'full',
    turf: Turf(
      id: 2,
      name: 'Skyline Sports Turf',
      location: 'Koramangala, Bangalore',
      pricePerHour: 1200.0,
      imageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=600&q=80',
      sportTypes: 'Cricket, Football, Basketball',
      latitude: 12.9352,
      longitude: 77.6245,
    ),
  ),
];

class BookingRepository {
  final Dio _dio;

  BookingRepository(this._dio);

  Future<List<Booking>> getMyBookings() async {
    final response = await _dio.get('/bookings/my-bookings');
    return (response.data as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<Booking> createBooking(int turfId, int slotId) async {
    final response = await _dio.post('/bookings/', data: {
      'turf_id': turfId,
      'slot_id': slotId,
    });
    return Booking.fromJson(response.data);
  }

  Future<void> cancelBooking(int bookingId) async {
    await _dio.post('/bookings/$bookingId/cancel');
  }
}

@riverpod
BookingRepository bookingRepository(Ref ref) {
  return BookingRepository(ref.watch(dioClientProvider));
}

@riverpod
Future<List<Booking>> fetchMyBookings(Ref ref) async {
  try {
    final userProfile = await ref.watch(fetchUserProfileProvider.future);
    if (userProfile == null) return demoSampleBookings;

    final bookings = await ref.watch(bookingRepositoryProvider).getMyBookings();
    if (bookings.isEmpty) return demoSampleBookings;
    return bookings;
  } catch (e) {
    return demoSampleBookings;
  }
}
