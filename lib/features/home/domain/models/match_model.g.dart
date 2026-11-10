// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchModel _$MatchModelFromJson(Map<String, dynamic> json) => MatchModel(
  id: (json['id'] as num).toInt(),
  turfId: (json['turf_id'] as num).toInt(),
  teamAName: json['team_a_name'] as String,
  teamBName: json['team_b_name'] as String,
  teamAScore: (json['team_a_score'] as num).toInt(),
  teamBScore: (json['team_b_score'] as num).toInt(),
  status: json['status'] as String,
  sportType: json['sport_type'] as String,
  startTime: DateTime.parse(json['start_time'] as String),
  turf:
      json['turf'] == null
          ? null
          : Turf.fromJson(json['turf'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MatchModelToJson(MatchModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'turf_id': instance.turfId,
      'team_a_name': instance.teamAName,
      'team_b_name': instance.teamBName,
      'team_a_score': instance.teamAScore,
      'team_b_score': instance.teamBScore,
      'status': instance.status,
      'sport_type': instance.sportType,
      'start_time': instance.startTime.toIso8601String(),
      'turf': instance.turf,
    };
