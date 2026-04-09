import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'session_models.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(dioProvider));
});

class SessionRepository {
  final Dio _dio;
  SessionRepository(this._dio);

  Future<String> checkIn(String workoutDayId) async {
    final response = await _dio.post(ApiConstants.checkIn, data: {'workoutDayId': workoutDayId});
    return response.data['sessionId'] as String;
  }

  Future<int> recordSet(String sessionId, RecordSetRequest request) async {
    final response = await _dio.post(ApiConstants.recordSet(sessionId), data: request.toJson());
    return response.data['restTimeTakenSeconds'] as int? ?? 0;
  }

  Future<double> checkOut(String sessionId) async {
    final response = await _dio.put(ApiConstants.checkOut(sessionId));
    return (response.data['totalDurationMinutes'] as num).toDouble();
  }

  Future<ActiveSession?> getActiveSession() async {
    try {
      final response = await _dio.get(ApiConstants.activeSession);
      return ActiveSession.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<SessionHistory>> getHistory() async {
    final response = await _dio.get(ApiConstants.sessionHistory);
    return (response.data as List).map((e) => SessionHistory.fromJson(e)).toList();
  }

  Future<List<PreviousSet>> getExerciseHistory(String exerciseId) async {
    try {
      final response = await _dio.get(ApiConstants.exerciseHistory(exerciseId));
      if (response.data is Map && response.data['message'] != null) return [];
      return (response.data as List).map((e) => PreviousSet.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<PersonalRecord>> getPersonalRecords() async {
    final response = await _dio.get(ApiConstants.personalRecords);
    return (response.data as List).map((e) => PersonalRecord.fromJson(e)).toList();
  }
}
