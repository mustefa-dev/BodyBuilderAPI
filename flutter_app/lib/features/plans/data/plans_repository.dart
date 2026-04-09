import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models.dart';

final plansRepositoryProvider = Provider<PlansRepository>((ref) {
  return PlansRepository(ref.watch(dioProvider));
});

class PlansRepository {
  final Dio _dio;
  PlansRepository(this._dio);

  Future<List<WorkoutPlan>> getPlans() async {
    final response = await _dio.get(ApiConstants.plans);
    return (response.data as List).map((e) => WorkoutPlan.fromJson(e)).toList();
  }

  Future<List<WorkoutDay>> getPlanDays(String planId) async {
    final response = await _dio.get(ApiConstants.planDays(planId));
    return (response.data as List).map((e) => WorkoutDay.fromJson(e)).toList();
  }

  Future<List<DayExercise>> getDayExercises(String dayId) async {
    final response = await _dio.get(ApiConstants.dayExercises(dayId));
    return (response.data as List).map((e) => DayExercise.fromJson(e)).toList();
  }
}
