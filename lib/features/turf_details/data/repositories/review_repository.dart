import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/features/turf_details/domain/models/review.dart';

part 'review_repository.g.dart';

class ReviewRepository {
  final Dio _dio;

  ReviewRepository(this._dio);

  Future<List<Review>> getTurfReviews(int turfId) async {
    final response = await _dio.get('/reviews/$turfId');
    return (response.data as List).map((e) => Review.fromJson(e)).toList();
  }

  Future<Review> createReview(int turfId, int rating, String comment) async {
    final response = await _dio.post('/reviews/', data: {
      'turf_id': turfId,
      'rating': rating,
      'comment': comment,
    });
    return Review.fromJson(response.data);
  }
}

@riverpod
ReviewRepository reviewRepository(Ref ref) {
  return ReviewRepository(ref.watch(dioClientProvider));
}

@riverpod
Future<List<Review>> fetchTurfReviews(Ref ref, int turfId) {
  return ref.watch(reviewRepositoryProvider).getTurfReviews(turfId);
}
