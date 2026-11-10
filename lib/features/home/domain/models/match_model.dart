import 'package:json_annotation/json_annotation.dart';
import 'package:turf_app/features/turf_details/domain/models/turf.dart';

part 'match_model.g.dart';

@JsonSerializable()
class MatchModel {
  final int id;
  @JsonKey(name: 'turf_id')
  final int turfId;
  @JsonKey(name: 'team_a_name')
  final String teamAName;
  @JsonKey(name: 'team_b_name')
  final String teamBName;
  @JsonKey(name: 'team_a_score')
  final int teamAScore;
  @JsonKey(name: 'team_b_score')
  final int teamBScore;
  final String status;
  @JsonKey(name: 'sport_type')
  final String sportType;
  @JsonKey(name: 'start_time')
  final DateTime startTime;
  final Turf? turf;

  MatchModel({
    required this.id,
    required this.turfId,
    required this.teamAName,
    required this.teamBName,
    required this.teamAScore,
    required this.teamBScore,
    required this.status,
    required this.sportType,
    required this.startTime,
    this.turf,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) => _$MatchModelFromJson(json);
  Map<String, dynamic> toJson() => _$MatchModelToJson(this);
}
