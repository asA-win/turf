import 'package:json_annotation/json_annotation.dart';
import 'package:turf_app/features/auth/domain/models/user_profile.dart';

part 'review.g.dart';

@JsonSerializable()
class Review {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'turf_id')
  final int turfId;
  final int rating;
  final String? comment;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final UserProfile user;

  Review({
    required this.id,
    required this.userId,
    required this.turfId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.user,
  });

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
  Map<String, dynamic> json() => _$ReviewToJson(this);
}
