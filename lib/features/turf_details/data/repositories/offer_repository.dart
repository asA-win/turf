import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/features/turf_details/domain/models/offer.dart';

part 'offer_repository.g.dart';

class OfferRepository {
  final Dio _dio;

  OfferRepository(this._dio);

  Future<List<Offer>> getOffers({int? turfId}) async {
    final response = await _dio.get('/offers/', queryParameters: {
      if (turfId != null) 'turf_id': turfId,
    });
    return (response.data as List).map((e) => Offer.fromJson(e)).toList();
  }
}

@riverpod
OfferRepository offerRepository(Ref ref) {
  return OfferRepository(ref.watch(dioClientProvider));
}

@riverpod
Future<List<Offer>> fetchOffers(Ref ref, {int? turfId}) {
  return ref.watch(offerRepositoryProvider).getOffers(turfId: turfId);
}
